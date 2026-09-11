import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/snippet.dart';
import 'package:termino/features/snippets/application/snippet_service.dart';

import '../../support/test_database.dart';

Snippet make({
  String id = 's1',
  String name = 'Tail logs',
  String body = 'journalctl -u app -f',
  String? hostId,
  bool runImmediately = false,
}) => Snippet(
  id: id,
  name: name,
  body: body,
  hostId: hostId,
  runImmediately: runImmediately,
  createdAt: DateTime(2026, 9, 6),
);

void main() {
  group('the model', () {
    test('sends the body as typed unless asked to run it', () {
      expect(make().payload, 'journalctl -u app -f');
      expect(
        make(runImmediately: true).payload,
        'journalctl -u app -f\n',
        reason: 'the newline is what runs it',
      );
    });

    test('a snippet with no host applies everywhere', () {
      expect(make().appliesTo(null), isTrue);
      expect(make().appliesTo('host-1'), isTrue);
    });

    test('a snippet tied to a host applies only there', () {
      final scoped = make(hostId: 'host-1');

      expect(scoped.appliesTo('host-1'), isTrue);
      expect(scoped.appliesTo('host-2'), isFalse);
      expect(
        scoped.appliesTo(null),
        isFalse,
        reason: 'a host-specific command has no business in a local shell',
      );
    });

    test('the preview makes newlines visible and truncates', () {
      expect(make(body: 'one\ntwo').preview, 'one ⏎ two');
      expect(make(body: 'x' * 200).preview.length, lessThanOrEqualTo(80));
      expect(make(body: 'x' * 200).preview, endsWith('…'));
    });

    test('round-trips through JSON', () {
      final snippet = make(hostId: 'host-1', runImmediately: true);

      expect(Snippet.fromJson(snippet.toJson()), snippet);
    });
  });

  group('storage', () {
    late ProviderContainer container;

    setUp(() => container = testContainer());
    tearDown(() => container.dispose());

    test('saves and reads back', () async {
      await container
          .read(snippetServiceProvider)
          .save(name: 'Disk usage', body: 'df -h');

      final stored = await container.read(snippetRepositoryProvider).all();
      expect(stored, hasLength(1));
      expect(stored.single.name, 'Disk usage');
      expect(stored.single.body, 'df -h');
      expect(stored.single.hostId, isNull);
      expect(stored.single.runImmediately, isFalse);
    });

    test('editing keeps the id and the creation time', () async {
      final service = container.read(snippetServiceProvider);
      final original = await service.save(name: 'One', body: 'a');

      await service.save(name: 'Two', body: 'b', existing: original);

      final stored = await container.read(snippetRepositoryProvider).all();
      expect(stored, hasLength(1), reason: 'editing is not a second snippet');
      expect(stored.single.id, original.id);
      // Compared to the second: drift stores a DateTime as a unix timestamp,
      // so sub-second precision does not survive a round trip. That is fine
      // for ordering, which is all createdAt is used for.
      expect(
        stored.single.createdAt.millisecondsSinceEpoch ~/ 1000,
        original.createdAt.millisecondsSinceEpoch ~/ 1000,
      );
      expect(stored.single.name, 'Two');
    });

    test('trims a padded name', () async {
      await container
          .read(snippetServiceProvider)
          .save(name: '  Padded  ', body: 'x');

      expect(
        (await container.read(snippetRepositoryProvider).all()).single.name,
        'Padded',
      );
    });

    test('deleting removes only that snippet', () async {
      final service = container.read(snippetServiceProvider);
      final first = await service.save(name: 'One', body: 'a');
      await service.save(name: 'Two', body: 'b');

      await service.delete(first.id);

      final stored = await container.read(snippetRepositoryProvider).all();
      expect(stored, hasLength(1));
      expect(stored.single.name, 'Two');
    });

    test('a host-scoped snippet keeps its host', () async {
      await container
          .read(snippetServiceProvider)
          .save(
            name: 'Restart',
            body: 'systemctl restart app',
            hostId: 'host-1',
            runImmediately: true,
          );

      final stored =
          (await container.read(snippetRepositoryProvider).all()).single;
      expect(stored.hostId, 'host-1');
      expect(stored.runImmediately, isTrue);
    });

    test('and can be given back to every host', () async {
      // Saving a column back to null has to actually clear it. The obvious
      // upsert quietly keeps the old value instead, which made scoping a
      // snippet to a host a decision you could not take back.
      final service = container.read(snippetServiceProvider);
      final scoped = await service.save(
        name: 'Restart',
        body: 'systemctl restart app',
        hostId: 'host-1',
      );

      await service.save(
        name: scoped.name,
        body: scoped.body,
        existing: scoped,
      );

      final stored =
          (await container.read(snippetRepositoryProvider).all()).single;
      expect(stored.hostId, isNull);
    });
  });
}
