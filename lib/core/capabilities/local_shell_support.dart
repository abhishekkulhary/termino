/// Whether a local PTY-backed shell can be compiled into this build at all.
///
/// `flutter_pty` depends on `dart:ffi`, which does not exist on the web. A
/// plain import of it therefore breaks the web compile outright, so every
/// reference to the PTY plugin must sit behind this conditional export. The
/// web build resolves to the stub and never sees `dart:ffi`.
///
/// This answers the *compile-time* question only. Whether a local shell may
/// actually be spawned is a runtime question — iOS compiles `dart:ffi` fine but
/// forbids spawning arbitrary binaries — and belongs to `PlatformCapabilities`.
library;

export 'local_shell_support_stub.dart'
    if (dart.library.ffi) 'local_shell_support_ffi.dart';
