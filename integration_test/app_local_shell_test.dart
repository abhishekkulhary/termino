// End-to-end: the real app widget tree, driving a real shell through a real
// pseudo-terminal. Run with:
//
//     flutter test integration_test/app_local_shell_test.dart -d macos
@Timeout(Duration(seconds: 90))
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:termino/app/app.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/terminal/application/session_launcher.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/terminal_pane.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens a real local shell and runs a command', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // This exercises the app proper. The first-run introduction has its own
    // tests and would otherwise stand in front of the terminal.
    await container.read(settingsProvider.notifier).completeOnboarding();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TerminoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // This machine is a desktop, so a local shell must be on offer.
    final capabilities = container.read(platformCapabilitiesProvider);
    expect(capabilities.canRunLocalShell, isTrue);

    final profiles = container.read(shellProfilesProvider);
    expect(profiles, isNotEmpty, reason: 'no shell was discovered');

    final session = await container
        .read(sessionLauncherProvider.notifier)
        .openLocalShell();
    await tester.pumpAndSettle();

    expect(session.connectionState.value, BackendConnectionState.connected);
    expect(find.byType(TerminalPane), findsOneWidget);
    expect(container.read(sessionManagerProvider).sessions, hasLength(1));

    // Let the shell print its prompt, then run something and read the screen.
    await tester.pump(const Duration(seconds: 1));
    session.sendText('echo integration-marker\n');

    for (
      var i = 0;
      i < 40 && !_screen(session).contains('integration-marker');
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      _screen(session),
      contains('integration-marker'),
      reason: 'the command output never reached the terminal buffer',
    );

    await container.read(sessionManagerProvider.notifier).closeAll();
    await tester.pumpAndSettle();
    expect(container.read(sessionManagerProvider).isEmpty, isTrue);
  });
}

String _screen(TerminalSession session) => session.terminal.buffer.getText();
