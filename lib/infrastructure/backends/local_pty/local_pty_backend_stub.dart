import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/domain/entities/shell_profile.dart';

/// Always throws: this build has no `dart:ffi`, so there is no PTY plugin.
///
/// Reaching this is a bug in the caller — `PlatformCapabilities` should have
/// prevented the attempt and shown an explanation. It throws a proper
/// [TerminalBackendFailure] rather than an assertion so that, if a gate is ever
/// missed, the user sees a sentence instead of a crash.
TerminalBackend createLocalPtyBackend({
  required ShellProfile profile,
  int columns = 80,
  int rows = 24,
}) {
  throw const TerminalBackendFailure(
    TerminalBackendFailureKind.unsupported,
    'A local shell is not available in a browser.',
  );
}

/// No shells can be discovered without an operating system to look at.
List<ShellProfile> discoverShellProfiles() => const [];

/// There is no default shell in a browser.
ShellProfile? defaultShellProfile() => null;
