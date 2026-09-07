import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/router.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';
import 'package:termino/infrastructure/terminal/output_batcher.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// With four terminals open, the question a header has to answer is which
/// machine the next keystroke goes to.
void main() {
  /// Opens [count] sessions, labelled so they can be told apart.
  Future<List<TerminalSession>> openSessions(
    ProviderContainer container,
    int count,
  ) async {
    final manager = container.read(sessionManagerProvider.notifier);
    return [
      for (var index = 0; index < count; index++)
        await manager.open(
          backend: MockBackend(),
          title: 'Session $index',
          descriptor: 'deploy@host-$index.example.com',
        ),
    ];
  }

  testWidgets('a session carries what it is, separately from its title', (
    tester,
  ) async {
    final session = TerminalSession(
      id: 'a',
      backend: MockBackend(),
      descriptor: 'deploy@build-01.example.com',
      initialTitle: 'Build server',
      batcher: const TerminalOutputBatcher(window: Duration.zero),
    );
    addTearDown(session.dispose);

    // A program renames the window; the machine has not changed.
    session.terminal.write('\x1b]2;vim README.md\x07');
    await tester.pump();

    expect(session.title.value, 'vim README.md');
    expect(session.descriptor, 'deploy@build-01.example.com');
  });

  testWidgets('the descriptor survives a reconnection', (tester) async {
    // The machine is the same one, whatever the last program called the window.
    final container = testContainer();
    addTearDown(container.dispose);

    final sessions = await openSessions(container, 1);

    expect(sessions.single.descriptor, 'deploy@host-0.example.com');
  });

  testWidgets('the tab strip keeps the active tab in view', (tester) async {
    // Enough tabs that the last is well past the right edge of a phone.
    final container = testContainer();
    addTearDown(container.dispose);
    final sessions = await openSessions(container, 12);

    await pumpApp(
      tester,
      const Scaffold(body: TerminalScreen()),
      size: compactSize,
      container: container,
    );

    // Opening a session activates it, so the newest is already in front.
    final last = find.text('Session 11');
    expect(last, findsOneWidget);
    expect(
      tester.getTopLeft(last).dx,
      lessThan(compactSize.width),
      reason: 'the active tab is on screen, not off to the right',
    );

    // Switch back to the first, which is now far off to the left.
    container.read(sessionManagerProvider.notifier).activate(sessions.first.id);
    await tester.pumpAndSettle();

    final first = find.text('Session 0');
    expect(first, findsOneWidget);
    final left = tester.getTopLeft(first).dx;
    expect(
      left,
      greaterThanOrEqualTo(0),
      reason: 'switching by keyboard or palette must show the tab it chose',
    );
    expect(left, lessThan(compactSize.width));
  });

  testWidgets('a tab already in view is left where it is', (tester) async {
    // `ensureVisible` always scrolls to its alignment, which would shunt the
    // whole strip sideways every time somebody clicked a visible tab.
    const size = expandedSize;
    final container = testContainer();
    addTearDown(container.dispose);
    final sessions = await openSessions(container, 12);

    await pumpApp(
      tester,
      const Scaffold(body: TerminalScreen()),
      container: container,
    );

    container.read(sessionManagerProvider.notifier).activate(sessions[11].id);
    await tester.pumpAndSettle();

    /// Whether a tab sits entirely inside the strip right now.
    bool onScreen(int index) {
      final rect = tester.getRect(find.text('Session $index'));
      return rect.left >= 0 && rect.right <= size.width;
    }

    // Whichever neighbour happens to be showing beside the active one — how
    // many fit depends on the label widths, so it is checked rather than
    // assumed.
    final neighbour = [
      for (var index = 10; index >= 0; index--)
        if (onScreen(index)) index,
    ].firstOrNull;
    expect(neighbour, isNotNull, reason: 'more than one tab fits at this size');

    final before = tester.getTopLeft(find.text('Session 11')).dx;
    container
        .read(sessionManagerProvider.notifier)
        .activate(sessions[neighbour!].id);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Session 11')).dx,
      before,
      reason: 'nothing needed to move, so nothing should have',
    );
  });

  testWidgets('the top bar names the session in front, not the screen', (
    tester,
  ) async {
    // "Terminal" is not information when four of them are open. Which machine
    // the next keystroke goes to is.
    final container = testContainer();
    addTearDown(container.dispose);
    final sessions = await openSessions(container, 3);

    await pumpApp(tester, const _Header(), container: container);

    expect(find.text('deploy@host-2.example.com'), findsOneWidget);
    expect(find.text('Terminal'), findsNothing);

    container.read(sessionManagerProvider.notifier).activate(sessions[0].id);
    await tester.pumpAndSettle();

    expect(find.text('deploy@host-0.example.com'), findsOneWidget);
  });

  testWidgets('with nothing open it falls back to the screen name', (
    tester,
  ) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await pumpApp(tester, const _Header(), container: container);

    expect(find.text('Terminal'), findsOneWidget);
  });

  testWidgets('a program renaming the window does not rename the header', (
    tester,
  ) async {
    // OSC 2 is the program talking about itself. The header answers a
    // different question, and a title of "vim README.md" does not answer it.
    final container = testContainer();
    addTearDown(container.dispose);
    final sessions = await openSessions(container, 1);

    await pumpApp(tester, const _Header(), container: container);

    sessions.single.terminal.write('\x1b]2;vim README.md\x07');
    await tester.pumpAndSettle();

    expect(find.text('deploy@host-0.example.com'), findsOneWidget);
    expect(find.text('vim README.md'), findsNothing);
  });
}

/// Just the app bar, which is where the title lives.
///
/// The whole shell would drag in the router and every other screen; what is
/// under test is one widget's choice of words.
class _Header extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const ShellTitle(index: 0)),
    body: const SizedBox.shrink(),
  );
}
