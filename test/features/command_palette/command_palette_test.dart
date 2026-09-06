import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/snippet.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/hosts/presentation/hosts_screen.dart';
import 'package:termino/features/settings/application/settings_controller.dart';

import '../../support/test_database.dart';

/// The palette is the keyboard route to everything, so what it can find — and
/// what it deliberately cannot — is worth pinning down.
void main() {
  const capabilities = PlatformCapabilities(
    canRunLocalShell: false,
    localShellUnavailableReason: LocalShellUnavailableReason.platformForbids,
    canUseSsh: true,
    canUseBiometrics: false,
    hasWindowManagement: false,
    canReadUserSshConfig: false,
  );

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = testContainer(capabilities: capabilities);
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).completeOnboarding();

    await container
        .read(sshHostRepositoryProvider)
        .save(
          const SshHost(
            id: 'a',
            label: 'Build server',
            hostname: 'build-01.example.com',
            username: 'deploy',
          ),
        );
    await container
        .read(sshHostRepositoryProvider)
        .save(
          const SshHost(
            id: 'b',
            label: 'Raspberry Pi',
            hostname: 'pi.local',
            username: 'pi',
          ),
        );
    await container
        .read(snippetRepositoryProvider)
        .save(
          Snippet(
            id: 's',
            name: 'Tail the log',
            body: 'tail -f app.log',
            createdAt: DateTime.utc(2026),
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TerminoApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Command palette'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens from the top bar and lists what it can do', (
    tester,
  ) async {
    await pump(tester);
    await open(tester);

    expect(find.text('Connect, switch, browse…'), findsOneWidget);
    expect(find.text('Build server'), findsWidgets);
    expect(find.text('Raspberry Pi'), findsWidgets);
  });

  testWidgets('opens with the keyboard', (tester) async {
    await pump(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('Connect, switch, browse…'), findsOneWidget);
  });

  testWidgets('narrows to what was typed, out of order', (tester) async {
    await pump(tester);
    await open(tester);

    // Not a substring of anything: B-u-i-S-v appears in "Build server" in
    // order, and nowhere in "Raspberry Pi".
    await tester.enterText(find.byType(TextField).first, 'buisv');
    await tester.pumpAndSettle();

    expect(find.text('Build server'), findsWidgets);
    expect(find.text('Raspberry Pi'), findsNothing);
  });

  testWidgets('finds a host by its hostname, not only its label', (
    tester,
  ) async {
    await pump(tester);
    await open(tester);

    await tester.enterText(find.byType(TextField).first, 'pi.local');
    await tester.pumpAndSettle();

    expect(find.text('Raspberry Pi'), findsWidgets);
    expect(find.text('Build server'), findsNothing);
  });

  testWidgets('says so when nothing matches', (tester) async {
    await pump(tester);
    await open(tester);

    await tester.enterText(find.byType(TextField).first, 'zzzzzz');
    await tester.pumpAndSettle();

    expect(find.text('Nothing matches'), findsOneWidget);
  });

  testWidgets('escape closes it', (tester) async {
    await pump(tester);
    await open(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Connect, switch, browse…'), findsNothing);

    // Closing the palette disposes the providers it was watching, and drift
    // schedules a zero-duration timer when a query stream is cancelled. One
    // more frame lets it fire rather than leaving it pending at teardown.
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('choosing a destination navigates and closes', (tester) async {
    await pump(tester);
    await open(tester);

    await tester.enterText(find.byType(TextField).first, 'hosts');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hosts').last);
    await tester.pumpAndSettle();

    expect(find.text('Connect, switch, browse…'), findsNothing);
    expect(find.byType(HostsScreen), findsOneWidget);
  });

  testWidgets('offers no snippet when there is no session to send it to', (
    tester,
  ) async {
    // A snippet with nowhere to go is not a command; offering it and doing
    // nothing would be worse than not offering it.
    await pump(tester);
    await open(tester);

    await tester.enterText(find.byType(TextField).first, 'tail');
    await tester.pumpAndSettle();

    expect(find.text('Tail the log'), findsNothing);
    expect(find.text('Nothing matches'), findsOneWidget);
  });
}
