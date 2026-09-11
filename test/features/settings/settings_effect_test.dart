/// A setting that is stored and never read is worse than no setting: it tells
/// the user they have changed something. Two here were exactly that — the bell
/// was counted and ignored, and scrollback was written to the database and
/// never given to a terminal. These assert the effect, not the storage.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/settings/presentation/settings_screen.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/bell_effect.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';
import 'package:termino/shared/design/app_theme.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// Scrolls the settings list — the outermost one — until [target] is shown.
///
/// Named explicitly because the font preview contains a text field, and a text
/// field brings a `Scrollable` of its own: `scrollUntilVisible` picks the only
/// one it can find, and with two it picks neither.
Future<void> scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Brings the bell dropdown into view and opens it.
Future<void> openBellMenu(WidgetTester tester) async {
  await scrollTo(tester, find.text('Bell'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButton<BellBehaviour>));
  await tester.pumpAndSettle();
}

void main() {
  const desktop = PlatformCapabilities(
    canRunLocalShell: true,
    canUseSsh: true,
    canUseBiometrics: true,
    hasWindowManagement: true,
    canReadUserSshConfig: true,
  );

  const phone = PlatformCapabilities(
    canRunLocalShell: false,
    localShellUnavailableReason: LocalShellUnavailableReason.platformForbids,
    canUseSsh: true,
    canUseBiometrics: true,
    hasWindowManagement: false,
    canReadUserSshConfig: false,
    hasHaptics: true,
  );

  group('app theme', () {
    // Round-tripping through storage was tested; that the stored value ever
    // reached MaterialApp was not. The app sets themeMode on two separate
    // MaterialApps — the onboarding one and the router one — so a change to
    // either could leave the other permanently on the system theme.

    /// The theme mode the app is actually running under.
    ThemeMode shownMode(WidgetTester tester) {
      final app = tester.widgetList<MaterialApp>(find.byType(MaterialApp));
      return app.first.themeMode!;
    }

    Future<void> pumpAppWith(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      // The real tree, so the assertion is about the app rather than a
      // stand-in. Entrance animations off: Reveal schedules its delay with a
      // timer that no frame is waiting on, so the test would end holding one.
      withoutAnimations(tester);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TerminoApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final (mode, expected) in [
      (AppThemeMode.system, ThemeMode.system),
      (AppThemeMode.light, ThemeMode.light),
      (AppThemeMode.dark, ThemeMode.dark),
    ]) {
      testWidgets('$mode reaches the app', (tester) async {
        final container = testContainer(capabilities: desktop);
        addTearDown(container.dispose);

        final settings = container.read(settingsProvider.notifier);
        await settings.completeOnboarding();
        await settings.setThemeMode(mode);

        await pumpAppWith(tester, container);

        expect(shownMode(tester), expected);
      });
    }

    testWidgets('and reaches it on the first run too', (tester) async {
      // A first-run user gets the onboarding MaterialApp instead of the
      // router's, and it carries its own themeMode.
      final container = testContainer(capabilities: desktop);
      addTearDown(container.dispose);

      await container
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeMode.light);

      await pumpAppWith(tester, container);

      expect(
        container.read(currentSettingsProvider).onboardingComplete,
        isFalse,
        reason: 'this is the onboarding branch, not the router one',
      );
      expect(shownMode(tester), ThemeMode.light);
    });
  });

  group('scrollback', () {
    test('a new session is given the configured number of lines', () async {
      final container = testContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).setScrollback(500);
      final session = await container
          .read(sessionManagerProvider.notifier)
          .open(backend: MockBackend.text('hi'));
      addTearDown(
        () => container.read(sessionManagerProvider.notifier).closeAll(),
      );

      expect(session.terminal.maxLines, 500);
    });

    test('the default is used when nothing is chosen', () async {
      final container = testContainer();
      addTearDown(container.dispose);

      final session = await container
          .read(sessionManagerProvider.notifier)
          .open(backend: MockBackend.text('hi'));
      addTearDown(
        () => container.read(sessionManagerProvider.notifier).closeAll(),
      );

      expect(
        session.terminal.maxLines,
        const TerminalSettings().scrollbackLines,
      );
    });

    test('sessions already open keep the scrollback they were given', () async {
      // Shrinking a live terminal would throw away history someone is reading.
      final container = testContainer();
      addTearDown(container.dispose);

      final manager = container.read(sessionManagerProvider.notifier);
      final before = await manager.open(backend: MockBackend.text('hi'));
      addTearDown(manager.closeAll);

      await container.read(settingsProvider.notifier).setScrollback(500);

      expect(before.terminal.maxLines, isNot(500));
    });
  });

  group('bell', () {
    Future<void> pumpBell(
      WidgetTester tester,
      ProviderContainer container,
      TerminalSession session,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: BellEffect(
                session: session,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('flashing the screen actually paints a flash', (tester) async {
      final container = testContainer();
      addTearDown(container.dispose);
      await container
          .read(settingsProvider.notifier)
          .setBell(BellBehaviour.visual);

      final manager = container.read(sessionManagerProvider.notifier);
      final session = await manager.open(backend: MockBackend.text('hi'));
      addTearDown(manager.closeAll);

      await pumpBell(tester, container, session);
      expect(find.byKey(bellFlashKey), findsNothing, reason: 'nothing yet');

      session.terminal.onBell?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));

      expect(
        find.byKey(bellFlashKey),
        findsOneWidget,
        reason: 'the bell should have painted an overlay',
      );

      await tester.pumpAndSettle();
      expect(
        find.byKey(bellFlashKey),
        findsNothing,
        reason: 'and it should fade away again',
      );
    });

    testWidgets('ignoring the bell paints nothing', (tester) async {
      final container = testContainer();
      addTearDown(container.dispose);
      await container
          .read(settingsProvider.notifier)
          .setBell(BellBehaviour.none);

      final manager = container.read(sessionManagerProvider.notifier);
      final session = await manager.open(backend: MockBackend.text('hi'));
      addTearDown(manager.closeAll);

      await pumpBell(tester, container, session);
      session.terminal.onBell?.call();
      await tester.pump(const Duration(milliseconds: 40));

      expect(find.byKey(bellFlashKey), findsNothing);
    });

    testWidgets('vibrating asks the platform to vibrate', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String? ?? '');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final container = testContainer();
      addTearDown(container.dispose);
      await container
          .read(settingsProvider.notifier)
          .setBell(BellBehaviour.haptic);

      final manager = container.read(sessionManagerProvider.notifier);
      final session = await manager.open(backend: MockBackend.text('hi'));
      addTearDown(manager.closeAll);

      await pumpBell(tester, container, session);
      session.terminal.onBell?.call();
      await tester.pump();

      expect(calls, isNotEmpty);
      expect(find.byKey(bellFlashKey), findsNothing, reason: 'buzz, not flash');
    });
  });

  group('the settings screen', () {
    testWidgets('offers vibration only where there is a motor', (tester) async {
      await pumpApp(
        tester,
        const SettingsScreen(),
        container: testContainer(capabilities: desktop),
      );
      await openBellMenu(tester);

      expect(find.text('Flash the screen'), findsWidgets);
      expect(
        find.text('Vibrate'),
        findsNothing,
        reason: 'a desktop has nothing to vibrate',
      );
    });

    testWidgets('offers it on a device that has one', (tester) async {
      await pumpApp(
        tester,
        const SettingsScreen(),
        container: testContainer(capabilities: phone),
      );
      await openBellMenu(tester);

      expect(find.text('Vibrate'), findsWidgets);
    });

    testWidgets('reset asks first, and can be declined', (tester) async {
      final container = testContainer(capabilities: desktop);
      await container.read(settingsProvider.notifier).setFontSize(22);

      await pumpApp(tester, const SettingsScreen(), container: container);
      await scrollTo(tester, find.text('Reset to defaults'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset to defaults'));
      await tester.pumpAndSettle();
      expect(find.text('Reset settings?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        container.read(currentSettingsProvider).fontSize,
        22,
        reason: 'declining must change nothing',
      );
    });

    testWidgets('reset restores defaults but not the first run', (
      tester,
    ) async {
      final container = testContainer(capabilities: desktop);
      final controller = container.read(settingsProvider.notifier);
      await controller.completeOnboarding();
      await controller.setFontSize(22);
      await controller.setScrollback(500);

      await pumpApp(tester, const SettingsScreen(), container: container);
      await scrollTo(tester, find.text('Reset to defaults'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset to defaults'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      final settings = container.read(currentSettingsProvider);
      expect(settings.fontSize, const TerminalSettings().fontSize);
      expect(
        settings.scrollbackLines,
        const TerminalSettings().scrollbackLines,
      );
      expect(
        settings.onboardingComplete,
        isTrue,
        reason:
            'asking for a default font size must not send the user back '
            'through the first-run introduction',
      );
    });

    testWidgets('survives a stored value it does not offer', (tester) async {
      // `setScrollback` takes any integer, so a value from another version of
      // the app can reach this screen. A DropdownButton asserts when its value
      // is not among its items, and it took the whole screen down.
      final container = testContainer(capabilities: desktop);
      await container.read(settingsProvider.notifier).setScrollback(1234);

      await pumpApp(tester, const SettingsScreen(), container: container);
      await scrollTo(tester, find.text('Scrollback'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1234'), findsWidgets, reason: 'shown as it is stored');
    });

    testWidgets('survives a bell this platform cannot ring', (tester) async {
      // Vibration chosen on a phone, then the same settings opened on a
      // desktop, where the option is deliberately not offered.
      final container = testContainer(capabilities: desktop);
      await container
          .read(settingsProvider.notifier)
          .setBell(BellBehaviour.haptic);

      await pumpApp(tester, const SettingsScreen(), container: container);
      await scrollTo(tester, find.text('Bell'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Vibrate'), findsWidgets);
    });

    testWidgets('says when scrollback takes effect', (tester) async {
      await pumpApp(
        tester,
        const SettingsScreen(),
        container: testContainer(capabilities: desktop),
      );
      await scrollTo(tester, find.text('Scrollback'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('applies to new sessions'),
        findsOneWidget,
        reason: 'a setting that does not apply now has to say so',
      );
    });
  });
}
