/// The only place a secret is ever written.
///
/// Backed by the platform keystore — Keychain on Apple platforms, the Android
/// Keystore, libsecret on Linux, DPAPI on Windows. Nothing here ever reaches
/// the drift database, preferences, a log line or a crash report; see
/// SECURITY.md.
abstract class SecretStore {
  /// Reads a secret, or null if it is not there.
  Future<String?> read(String key);

  /// Writes a secret, replacing any existing value.
  Future<void> write(String key, String value);

  /// Deletes a secret. Deleting a missing key is not an error.
  Future<void> delete(String key);

  /// Whether a secret exists, without reading it.
  ///
  /// Distinct from `read() != null` so that a caller can, for example, show
  /// "password saved" without decrypting anything or triggering a biometric
  /// prompt.
  Future<bool> contains(String key);
}
