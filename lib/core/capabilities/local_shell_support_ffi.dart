import 'package:flutter_pty/flutter_pty.dart';

/// Whether the PTY plugin is compiled into this build. True on every target
/// that has `dart:ffi`, which is all of them except the web.
const bool localShellCompiledIn = true;

/// The name of the type providing the PTY, for diagnostics and the about
/// screen. Naming [Pty] here also keeps the plugin linked into the build.
String get localShellBackendName {
  const type = Pty;
  return '$type';
}
