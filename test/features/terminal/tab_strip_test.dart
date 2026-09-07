import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/terminal_screen.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// A tab strip has two jobs beyond listing tabs: showing which one is in
/// front, and being somewhere the one in front can actually be seen.
void main() {
  /// Opens [count] sessions, labelled so they can be told apart.
  Future<List<TerminalSession>> openSessions(
    ProviderContainer container,
    int count,
  ) async {
    final manager = container.read(sessionManagerProvider.notifier);
    return [
      for (var index = 0; index < count; index++)
        await manager.open(backend: MockBackend(), title: 'Session $index'),
    ];
  }

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

  testWidgets('a tab fills the strip, so its underline sits on the edge', (
    tester,
  ) async {
    // A horizontal `ListView` stretches its children to the full cross axis;
    // a `Row` lets them take their natural height and centres them. Swapping
    // one for the other turned the selected tab's fill into a short band
    // floating in the middle of the strip, with its 2px underline hanging in
    // mid-air instead of sitting on the bottom edge.
    final container = testContainer();
    addTearDown(container.dispose);
    await openSessions(container, 2);

    await pumpApp(
      tester,
      const Scaffold(body: TerminalScreen()),
      container: container,
    );

    final strip = tester.getRect(find.byKey(stripKey));
    final tab = tester.getRect(
      find
          .ancestor(
            of: find.text('Session 0'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

    expect(tab.top, strip.top, reason: 'the tab starts at the top');
    expect(
      strip.bottom - tab.bottom,
      lessThanOrEqualTo(1),
      reason: "nothing below the tab but the strip's own 1px border",
    );
  });
}
