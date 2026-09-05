import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test();
  });

  SessionManager manager() => container.read(sessionManagerProvider.notifier);
  SessionsState read() => container.read(sessionManagerProvider);

  group('SessionManager', () {
    test('starts with no sessions', () {
      expect(read().isEmpty, isTrue);
      expect(read().active, isNull);
    });

    test('opening a session activates it and starts the backend', () async {
      final backend = MockBackend.text('hi');
      final session = await manager().open(backend: backend, title: 'One');

      expect(read().sessions, hasLength(1));
      expect(read().activeId, session.id);
      expect(read().active, same(session));
      expect(backend.state, BackendConnectionState.connected);
    });

    test('each session gets a distinct id', () async {
      final first = await manager().open(backend: MockBackend.text(''));
      final second = await manager().open(backend: MockBackend.text(''));

      expect(first.id, isNot(second.id));
      expect(read().sessions, hasLength(2));
    });

    test('opening a session that fails still produces a usable tab', () async {
      const failure = TerminalBackendFailure(
        TerminalBackendFailureKind.authentication,
        'Authentication failed.',
      );
      final session = await manager().open(
        backend: MockBackend.failing(failure),
        title: 'Broken',
      );

      expect(read().sessions, hasLength(1));
      expect(read().active, same(session));
      expect(session.connectionState.value, BackendConnectionState.error);
    });

    test('activate brings an existing session to the front', () async {
      final first = await manager().open(backend: MockBackend.text(''));
      await manager().open(backend: MockBackend.text(''));

      manager().activate(first.id);

      expect(read().activeId, first.id);
    });

    test('activating an unknown id does nothing', () async {
      final session = await manager().open(backend: MockBackend.text(''));

      manager().activate('nope');

      expect(read().activeId, session.id);
    });

    test('closing removes and disposes the session', () async {
      final backend = MockBackend.text('');
      final session = await manager().open(backend: backend);

      await manager().close(session.id);

      expect(read().isEmpty, isTrue);
      expect(read().activeId, isNull);
      expect(backend.state, BackendConnectionState.closed);
    });

    test('closing the active tab activates its left neighbour', () async {
      final first = await manager().open(backend: MockBackend.text(''));
      final second = await manager().open(backend: MockBackend.text(''));
      final third = await manager().open(backend: MockBackend.text(''));

      expect(read().activeId, third.id);
      await manager().close(third.id);
      expect(read().activeId, second.id);

      await manager().close(second.id);
      expect(read().activeId, first.id);
    });

    test('closing the first tab activates what is now first', () async {
      final first = await manager().open(backend: MockBackend.text(''));
      final second = await manager().open(backend: MockBackend.text(''));
      manager().activate(first.id);

      await manager().close(first.id);

      expect(read().activeId, second.id);
    });

    test('closing an inactive tab leaves the active one alone', () async {
      final first = await manager().open(backend: MockBackend.text(''));
      final second = await manager().open(backend: MockBackend.text(''));

      await manager().close(first.id);

      expect(read().activeId, second.id);
      expect(read().sessions, hasLength(1));
    });

    test('closing an unknown id does nothing', () async {
      await manager().open(backend: MockBackend.text(''));

      await manager().close('nope');

      expect(read().sessions, hasLength(1));
    });

    test('closeAll empties and disposes everything', () async {
      final backends = [MockBackend.text(''), MockBackend.text('')];
      for (final backend in backends) {
        await manager().open(backend: backend);
      }

      await manager().closeAll();

      expect(read().isEmpty, isTrue);
      for (final backend in backends) {
        expect(backend.state, BackendConnectionState.closed);
      }
    });

    test('splitting shows a second session beside the active one', () async {
      final first = await manager().open(backend: MockBackend.text(''));
      final second = await manager().open(backend: MockBackend.text(''));

      manager().splitWith(first.id);

      expect(read().isSplit, isTrue);
      expect(read().secondary, same(first));
      expect(
        read().activeId,
        second.id,
        reason: 'the active pane is unchanged',
      );
    });

    test('a session cannot be split against itself', () async {
      final session = await manager().open(backend: MockBackend.text(''));

      manager().splitWith(session.id);

      expect(
        read().isSplit,
        isFalse,
        reason: 'the same buffer twice is confusing, not useful',
      );
    });

    test('splitting with an unknown id does nothing', () async {
      await manager().open(backend: MockBackend.text(''));

      manager().splitWith('nope');

      expect(read().isSplit, isFalse);
    });

    test('unsplit returns to one pane without closing anything', () async {
      final first = await manager().open(backend: MockBackend.text(''));
      await manager().open(backend: MockBackend.text(''));
      manager().splitWith(first.id);

      manager().unsplit();

      expect(read().isSplit, isFalse);
      expect(read().sessions, hasLength(2), reason: 'nothing was closed');
    });

    test('activating the split session collapses the split', () async {
      final first = await manager().open(backend: MockBackend.text(''));
      await manager().open(backend: MockBackend.text(''));
      manager().splitWith(first.id);

      manager().activate(first.id);

      expect(read().activeId, first.id);
      expect(
        read().isSplit,
        isFalse,
        reason: 'it would otherwise appear in both panes at once',
      );
    });

    test('closing the split session clears the second pane', () async {
      final first = await manager().open(backend: MockBackend.text(''));
      await manager().open(backend: MockBackend.text(''));
      manager().splitWith(first.id);

      await manager().close(first.id);

      expect(read().isSplit, isFalse);
      expect(read().secondaryId, isNull);
    });

    test('disposing the container disposes open sessions', () async {
      final backend = MockBackend.text('');
      await manager().open(backend: backend);

      container.dispose();
      await pumpEventQueue();

      expect(backend.state, BackendConnectionState.closed);
    });
  });
}
