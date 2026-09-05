import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/shell_profile.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/hosts/application/ssh_connector.dart';
import 'package:termino/features/terminal/application/demo_backend.dart';
import 'package:termino/features/terminal/application/session_manager.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/infrastructure/backends/local_pty/local_pty_backend.dart';

part 'session_launcher.g.dart';

/// The local shells available on this machine.
///
/// Empty when the platform cannot run one at all, so callers do not need their
/// own platform checks — an empty list and a disabled control are the same
/// thing to the UI.
@Riverpod(keepAlive: true)
List<ShellProfile> shellProfiles(Ref ref) {
  final capabilities = ref.watch(platformCapabilitiesProvider);
  if (!capabilities.canRunLocalShell) return const [];
  return discoverShellProfiles();
}

/// Opens sessions. The one place that decides which backend a request needs.
@Riverpod(keepAlive: true)
class SessionLauncher extends _$SessionLauncher {
  @override
  void build() {}

  /// Opens a local shell running [profile], or the default shell when omitted.
  ///
  /// Throws [StateError] if the platform cannot run a local shell; callers are
  /// expected to have consulted [PlatformCapabilities] and disabled the
  /// control, and reaching here means a gate was missed.
  Future<TerminalSession> openLocalShell([ShellProfile? profile]) {
    final capabilities = ref.read(platformCapabilitiesProvider);
    if (!capabilities.canRunLocalShell) {
      throw StateError(
        'openLocalShell called on a platform that cannot run one: '
        '${capabilities.localShellUnavailableReason?.name}',
      );
    }

    final available = ref.read(shellProfilesProvider);
    final chosen = profile ?? (available.isEmpty ? null : available.first);
    if (chosen == null) {
      throw StateError('No shell profile is available on this machine.');
    }

    return ref
        .read(sessionManagerProvider.notifier)
        .open(
          backend: createLocalPtyBackend(profile: chosen),
          title: chosen.name,
        );
  }

  /// Opens an SSH session to [host].
  ///
  /// A failure to connect still produces a session, so the reason appears in
  /// the tab the user was expecting rather than as a toast over an empty
  /// screen. A refused host key is reported the same way.
  Future<TerminalSession> openSsh(SshHost host) async {
    final capabilities = ref.read(platformCapabilitiesProvider);
    if (!capabilities.canUseSsh) {
      throw StateError('openSsh called where SSH is unavailable');
    }

    final backend = await ref.read(sshConnectorProvider).connect(host);
    return await ref
        .read(sessionManagerProvider.notifier)
        .open(backend: backend, title: host.label);
  }

  /// Opens a session replaying the built-in demo transcript.
  ///
  /// Available everywhere, including platforms with no local shell, so that the
  /// terminal itself can always be seen and exercised.
  Future<TerminalSession> openDemo() {
    return ref
        .read(sessionManagerProvider.notifier)
        .open(backend: createDemoBackend(), title: 'Demo');
  }
}
