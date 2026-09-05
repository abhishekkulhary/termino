/// Whether the PTY plugin is compiled into this build. Always false on the
/// web, where `dart:ffi` does not exist.
const bool localShellCompiledIn = false;

/// The name of the type providing the PTY, for diagnostics and the about
/// screen.
String get localShellBackendName => 'unavailable';
