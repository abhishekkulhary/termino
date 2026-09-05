/// Access to the local pseudo-terminal, where the platform has one.
///
/// `flutter_pty` depends on `dart:ffi`, which does not exist on the web, and
/// that is a *compile* failure rather than a runtime one — a plain import kills
/// the web build outright, no matter what guard sits in front of it. So every
/// reference goes through this conditional export, and the web build resolves
/// to a stub that never sees `dart:ffi`.
///
/// Compiling the plugin in is not the same as being allowed to use it: iOS has
/// `dart:ffi` and still forbids launching programs. `PlatformCapabilities`
/// answers that second question.
library;

export 'local_pty_backend_stub.dart'
    if (dart.library.ffi) 'local_pty_backend_ffi.dart';
