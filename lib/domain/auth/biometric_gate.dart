/// Asks the device to confirm the person holding it is the owner.
///
/// An interface in the domain so that the connection path can depend on the
/// idea without depending on `local_auth`, and so tests can refuse or allow
/// without a fingerprint reader.
abstract class BiometricGate {
  /// Whether this device can ask at all.
  ///
  /// False on a desktop without a sensor, on Linux, and on a phone with no
  /// enrolled biometric and no device passcode.
  Future<bool> get isAvailable;

  /// Asks, explaining why with [reason].
  ///
  /// Returns false when the user cancels, when the check fails, and when the
  /// device cannot ask. **False always means "do not proceed"** — there is no
  /// error case that should be read as permission.
  Future<bool> confirm({required String reason});
}

/// A gate that always says no.
///
/// The default wherever biometrics are unavailable. Refusing is the safe
/// direction: an identity marked as requiring a check must not become usable
/// merely because the check cannot be performed.
class UnavailableBiometricGate implements BiometricGate {
  /// Creates the gate.
  const new();

  @override
  Future<bool> get isAvailable async => false;

  @override
  Future<bool> confirm({required String reason}) async => false;
}
