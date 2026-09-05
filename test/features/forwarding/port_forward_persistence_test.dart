import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/port_forward.dart';
import 'package:termino/features/forwarding/application/forwarding_providers.dart';

import '../../support/test_database.dart';

const _local = PortForward(
  id: 'f1',
  hostId: 'h1',
  kind: PortForwardKind.local,
  listenPort: 8080,
  destinationHost: 'internal',
  destinationPort: 80,
  label: 'Internal web',
);

void main() {
  late ProviderContainer container;

  setUp(() => container = testContainer());
  tearDown(() => container.dispose());

  group('persistence', () {
    test('a saved tunnel survives a reload', () async {
      await container.read(portForwardRepositoryProvider).save(_local);

      final loaded = await container.read(portForwardRepositoryProvider).all();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'f1');
      expect(loaded.single.kind, PortForwardKind.local);
      expect(loaded.single.listenPort, 8080);
      expect(loaded.single.destinationHost, 'internal');
      expect(loaded.single.destinationPort, 80);
      expect(loaded.single.label, 'Internal web');
      expect(loaded.single.bindAddress, '127.0.0.1');
    });

    test('saving the same id updates rather than duplicating', () async {
      final repository = container.read(portForwardRepositoryProvider);
      await repository.save(_local);

      await repository.save(_local.copyWith(listenPort: 9090));

      final loaded = await repository.all();
      expect(loaded, hasLength(1), reason: 'this is an update, not an insert');
      expect(loaded.single.listenPort, 9090);
    });

    test('adding a second tunnel keeps the first', () async {
      // The earlier implementation cascaded onto a ternary, so adding one
      // tunnel also overwrote the last existing one.
      final repository = container.read(portForwardRepositoryProvider);
      await repository.save(_local);

      await repository.save(
        _local.copyWith(id: 'f2', listenPort: 9999, label: 'Second'),
      );

      final loaded = await repository.all();
      expect(loaded, hasLength(2));
      expect(loaded.map((f) => f.id), containsAll(['f1', 'f2']));
      expect(
        loaded.firstWhere((f) => f.id == 'f1').listenPort,
        8080,
        reason: 'the original must be untouched',
      );
    });

    test('deleting removes only that tunnel', () async {
      final repository = container.read(portForwardRepositoryProvider);
      await repository.save(_local);
      await repository.save(_local.copyWith(id: 'f2'));

      await repository.delete('f1');

      final loaded = await repository.all();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'f2');
    });

    test('a dynamic tunnel round-trips without a destination', () async {
      const dynamicForward = PortForward(
        id: 'd1',
        hostId: 'h1',
        kind: PortForwardKind.dynamic,
        listenPort: 1080,
      );
      await container.read(portForwardRepositoryProvider).save(dynamicForward);

      final loaded =
          (await container.read(portForwardRepositoryProvider).all()).single;

      expect(loaded.kind, PortForwardKind.dynamic);
      expect(loaded.destinationHost, isNull);
      expect(loaded.destinationPort, isNull);
      expect(loaded.isValid, isTrue);
    });
  });

  group('the notifier', () {
    test('loads what is stored', () async {
      await container.read(portForwardRepositoryProvider).save(_local);

      final notifier = container.read(portForwardsProvider.notifier);
      await notifier.save(_local.copyWith(id: 'f2'));

      expect(container.read(portForwardsProvider), hasLength(2));
    });

    test('removing drops it from state and storage', () async {
      final notifier = container.read(portForwardsProvider.notifier);
      await notifier.save(_local);
      expect(container.read(portForwardsProvider), hasLength(1));

      await notifier.remove(_local.id);

      expect(container.read(portForwardsProvider), isEmpty);
      expect(
        await container.read(portForwardRepositoryProvider).all(),
        isEmpty,
      );
    });
  });

  group('validation', () {
    test('a local tunnel needs a destination', () {
      expect(_local.isValid, isTrue);
      expect(
        _local.copyWith(destinationHost: null, destinationPort: null).isValid,
        isFalse,
      );
    });

    test('ports outside the valid range are refused', () {
      expect(_local.copyWith(listenPort: 0).isValid, isFalse);
      expect(_local.copyWith(listenPort: 70000).isValid, isFalse);
      expect(_local.copyWith(destinationPort: 0).isValid, isFalse);
    });

    test('the ssh argument reads the way a user would write it', () {
      expect(_local.argument, '-L 127.0.0.1:8080:internal:80');
      expect(
        _local.copyWith(kind: PortForwardKind.dynamic).argument,
        '-D 127.0.0.1:8080',
      );
    });
  });
}
