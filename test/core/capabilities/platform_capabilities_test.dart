import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';

PlatformCapabilities detect(
  TargetPlatform platform, {
  bool isWeb = false,
  bool ptyCompiledIn = true,
}) => PlatformCapabilities.detect(
  platform: platform,
  isWeb: isWeb,
  ptyCompiledIn: ptyCompiledIn,
);

void main() {
  group('PlatformCapabilities.detect', () {
    test('desktop platforms can run a local shell', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.windows,
      ]) {
        final capabilities = detect(platform);
        expect(capabilities.canRunLocalShell, isTrue, reason: '$platform');
        expect(capabilities.localShellUnavailableReason, isNull);
        expect(capabilities.hasWindowManagement, isTrue);
        expect(capabilities.canReadUserSshConfig, isTrue);
      }
    });

    test('Android can run a sandboxed local shell but is not a desktop', () {
      final capabilities = detect(TargetPlatform.android);

      expect(capabilities.canRunLocalShell, isTrue);
      expect(capabilities.hasWindowManagement, isFalse);
      expect(
        capabilities.canReadUserSshConfig,
        isFalse,
        reason: 'there is no ~/.ssh to import from on Android',
      );
    });

    test('iOS cannot run a local shell, and says why', () {
      final capabilities = detect(TargetPlatform.iOS);

      expect(capabilities.canRunLocalShell, isFalse);
      expect(
        capabilities.localShellUnavailableReason,
        LocalShellUnavailableReason.platformForbids,
      );
      expect(
        capabilities.canUseSsh,
        isTrue,
        reason: 'SSH is unaffected by the restriction on spawning programs',
      );
    });

    test('the web cannot run a local shell, for a different reason', () {
      final capabilities = detect(TargetPlatform.macOS, isWeb: true);

      expect(capabilities.canRunLocalShell, isFalse);
      expect(
        capabilities.localShellUnavailableReason,
        LocalShellUnavailableReason.noProcessesInBrowser,
      );
      expect(capabilities.canUseBiometrics, isFalse);
      expect(capabilities.hasWindowManagement, isFalse);
    });

    test('a build without the PTY plugin cannot run a local shell', () {
      // Belt and braces: even on a platform that allows it, a build where
      // dart:ffi was unavailable has nothing to call.
      final capabilities = detect(TargetPlatform.linux, ptyCompiledIn: false);

      expect(capabilities.canRunLocalShell, isFalse);
      expect(capabilities.localShellUnavailableReason, isNotNull);
    });

    test(
      'biometrics are unavailable on Linux, where local_auth has no support',
      () {
        expect(detect(TargetPlatform.linux).canUseBiometrics, isFalse);
        expect(detect(TargetPlatform.macOS).canUseBiometrics, isTrue);
        expect(detect(TargetPlatform.android).canUseBiometrics, isTrue);
        expect(detect(TargetPlatform.iOS).canUseBiometrics, isTrue);
      },
    );

    test('SSH is possible everywhere', () {
      for (final platform in TargetPlatform.values) {
        expect(detect(platform).canUseSsh, isTrue, reason: '$platform');
      }
      expect(detect(TargetPlatform.macOS, isWeb: true).canUseSsh, isTrue);
    });

    test('capability sets compare by value', () {
      expect(detect(TargetPlatform.macOS), detect(TargetPlatform.macOS));
      expect(
        detect(TargetPlatform.macOS).hashCode,
        detect(TargetPlatform.macOS).hashCode,
      );
      expect(detect(TargetPlatform.macOS), isNot(detect(TargetPlatform.iOS)));
    });
  });

  group('LocalShellUnavailableReason', () {
    test('every reason has a usable explanation and short label', () {
      for (final reason in LocalShellUnavailableReason.values) {
        expect(reason.explanation, isNotEmpty);
        expect(reason.shortReason, isNotEmpty);
        expect(
          reason.explanation.length,
          greaterThan(reason.shortReason.length),
        );
      }
    });

    test('explanations mention what does still work', () {
      // The point of these strings is that the user is not left thinking the
      // app is broken, so each one has to point somewhere useful.
      for (final reason in LocalShellUnavailableReason.values) {
        expect(reason.explanation.toLowerCase(), contains('ssh'));
      }
    });
  });
}
