import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/core/capabilities/local_shell_support.dart';

part 'platform_capabilities.g.dart';

/// Why a local shell is unavailable, in terms a user can act on.
enum LocalShellUnavailableReason {
  /// iOS and iPadOS do not permit an app to launch arbitrary programs.
  platformForbids,

  /// The web build has no process to attach a terminal to.
  noProcessesInBrowser;

  /// A sentence suitable for showing in the UI.
  String get explanation => switch (this) {
    LocalShellUnavailableReason.platformForbids =>
      'iOS does not allow apps to launch other programs, so a local shell is '
          'not possible here. SSH works normally — connect to a machine that '
          'has one.',
    LocalShellUnavailableReason.noProcessesInBrowser =>
      'A browser tab has no operating system to open a shell on. SSH works '
          'through a relay — see the documentation for how to run one.',
  };

  /// A short label for a disabled control.
  String get shortReason => switch (this) {
    LocalShellUnavailableReason.platformForbids => 'Not available on iOS',
    LocalShellUnavailableReason.noProcessesInBrowser =>
      'Not available in a browser',
  };
}

/// What this build, on this device, can actually do.
///
/// Every feature-gated widget consults this. There are deliberately **no**
/// `Platform.isX` checks scattered through the UI: the rules live here, in one
/// testable place, and can be overridden in tests to exercise a platform the
/// test is not running on.
///
/// Two different questions are kept apart, because conflating them is a bug:
/// whether the PTY plugin is *compiled into* this build (a compile-time fact
/// about `dart:ffi`, answered by `local_shell_support.dart`), and whether a
/// shell may actually be *spawned* (a runtime fact about the platform's rules,
/// answered here). iOS compiles `dart:ffi` perfectly well and still forbids
/// launching programs.
@immutable
class PlatformCapabilities {
  /// Creates a capability set explicitly. Used by tests.
  const new({
    required this.canRunLocalShell,
    required this.canUseSsh,
    required this.canUseBiometrics,
    required this.hasWindowManagement,
    required this.canReadUserSshConfig,
    this.needsRelay = false,
    this.localShellUnavailableReason,
  });

  /// Derives the capabilities of the current platform.
  factory detect({
    TargetPlatform? platform,
    bool isWeb = kIsWeb,
    bool ptyCompiledIn = localShellCompiledIn,
  }) {
    final target = platform ?? defaultTargetPlatform;

    // Browsers have no processes to attach to, and cannot open raw TCP
    // sockets. SSH is still possible through a WebSocket relay (Phase 7).
    if (isWeb) {
      return const PlatformCapabilities(
        canRunLocalShell: false,
        localShellUnavailableReason:
            LocalShellUnavailableReason.noProcessesInBrowser,
        // SSH itself runs in the browser; only the transport needs a relay.
        canUseSsh: true,
        // A browser cannot open a raw TCP socket, so SSH reaches a server
        // through a WebSocket relay. The protocol still runs here.
        needsRelay: true,
        canUseBiometrics: false,
        hasWindowManagement: false,
        canReadUserSshConfig: false,
      );
    }

    final isDesktop =
        target == TargetPlatform.macOS ||
        target == TargetPlatform.linux ||
        target == TargetPlatform.windows;

    // iOS and iPadOS forbid spawning arbitrary binaries. This is a rule of the
    // platform, not a limitation we can engineer around, and the app says so
    // plainly rather than offering a control that fails.
    final forbidden = target == TargetPlatform.iOS;
    final canRunLocalShell = ptyCompiledIn && !forbidden;

    return PlatformCapabilities(
      canRunLocalShell: canRunLocalShell,
      localShellUnavailableReason: canRunLocalShell
          ? null
          : LocalShellUnavailableReason.platformForbids,
      canUseSsh: true,
      // local_auth supports every target except Linux.
      canUseBiometrics: target != TargetPlatform.linux,
      hasWindowManagement: isDesktop,
      // Only a desktop has a ~/.ssh to import from.
      canReadUserSshConfig: isDesktop,
    );
  }

  /// Whether a PTY-backed local shell can be opened.
  final bool canRunLocalShell;

  /// Why not, when [canRunLocalShell] is false.
  final LocalShellUnavailableReason? localShellUnavailableReason;

  /// Whether SSH sessions are possible.
  final bool canUseSsh;

  /// Whether SSH must go through a WebSocket relay rather than a TCP socket.
  final bool needsRelay;

  /// Whether a biometric or device-credential gate can guard stored secrets.
  final bool canUseBiometrics;

  /// Whether the app manages its own window (desktop tabs, sizing, position).
  final bool hasWindowManagement;

  /// Whether `~/.ssh/config` and `~/.ssh/known_hosts` can be imported.
  final bool canReadUserSshConfig;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformCapabilities &&
          other.canRunLocalShell == canRunLocalShell &&
          other.localShellUnavailableReason == localShellUnavailableReason &&
          other.canUseSsh == canUseSsh &&
          other.needsRelay == needsRelay &&
          other.canUseBiometrics == canUseBiometrics &&
          other.hasWindowManagement == hasWindowManagement &&
          other.canReadUserSshConfig == canReadUserSshConfig;

  @override
  int get hashCode => Object.hash(
    canRunLocalShell,
    localShellUnavailableReason,
    canUseSsh,
    needsRelay,
    canUseBiometrics,
    hasWindowManagement,
    canReadUserSshConfig,
  );
}

/// The capabilities of the platform the app is running on.
///
/// Override this in tests and in the widget catalogue to render a platform you
/// are not running on.
@Riverpod(keepAlive: true)
PlatformCapabilities platformCapabilities(Ref ref) =>
    PlatformCapabilities.detect();
