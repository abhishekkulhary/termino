import 'package:freezed_annotation/freezed_annotation.dart';

part 'shell_profile.freezed.dart';
part 'shell_profile.g.dart';

/// A local shell that can be launched in a pseudo-terminal.
///
/// Profiles are how the app supports PowerShell, cmd, WSL and Git Bash on
/// Windows, or a login shell versus a bare one on Unix, without any of that
/// choice leaking into the backend. The backend takes a profile and runs it.
@freezed
abstract class ShellProfile with _$ShellProfile {
  /// Creates a profile.
  const factory({
    required String id,
    required String name,
    required String executable,
    @Default(<String>[]) List<String> arguments,

    /// Extra environment variables, merged over the inherited environment.
    ///
    /// Note that the PTY layer always sets `TERM` and `LANG` itself, since a
    /// terminal that does not announce its capabilities makes `vim` and `htop`
    /// misbehave in ways that are tedious to diagnose.
    @Default(<String, String>{}) Map<String, String> environment,

    /// Where the shell starts. Null means the user's home directory.
    String? workingDirectory,
  }) = _ShellProfile;

  const new _();

  /// Restores a profile from stored JSON.
  factory fromJson(Map<String, dynamic> json) => _$ShellProfileFromJson(json);

  /// The command line as a user would type it, for display in settings.
  String get commandLine =>
      [executable, ...arguments].map(_quoteIfNeeded).join(' ');

  static String _quoteIfNeeded(String part) =>
      part.contains(' ') ? '"$part"' : part;
}
