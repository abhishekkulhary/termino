import 'package:local_auth/local_auth.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/domain/auth/biometric_gate.dart';

/// The real gate, backed by the platform's own biometric prompt.
///
/// This was the missing half of a feature the app already claimed: an identity
/// could be marked as requiring a check, the Keys screen showed a badge saying
/// so, and nothing ever asked. A security control that is displayed and not
/// enforced is worse than one that does not exist, because it is believed.
class LocalAuthGate implements BiometricGate {
  /// Creates a gate over [auth], which tests replace.
  new([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> get isAvailable async {
    try {
      // `isDeviceSupported` is true for a device that can check biometrics
      // *or* fall back to a passcode, which is deliberately what is wanted:
      // the point is that someone proved they hold this device, not that they
      // used a fingerprint specifically. Requiring `canCheckBiometrics` here
      // would lock out a passcode-only device for no gain in assurance.
      return await _auth.isDeviceSupported();
    } on Object catch (error) {
      Loggers.session.warning('Biometric availability check failed.', error);
      return false;
    }
  }

  @override
  Future<bool> confirm({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // `biometricOnly` is left at its default of false on purpose: the
        // device passcode is accepted as a fallback, because refusing it
        // would lock someone out of their own key because a sensor is wet.
        // Survives the app going to the background mid-prompt, which is what
        // happens on iOS when Face ID takes over the screen.
        persistAcrossBackgrounding: true,
      );
    } on Object catch (error) {
      // Every failure is a refusal. Nothing here may be read as permission —
      // a plugin exception on an unconfigured device must not unlock a key.
      Loggers.session.warning('Biometric check failed.', error);
      return false;
    }
  }
}
