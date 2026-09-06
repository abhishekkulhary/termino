import 'package:freezed_annotation/freezed_annotation.dart';

part 'snippet.freezed.dart';
part 'snippet.g.dart';

/// A saved command the user can send with one tap.
///
/// The point is the commands nobody remembers: the long `journalctl`
/// incantation with the right unit and flags, or the `docker` invocation with
/// six arguments.
/// Typing those on a phone keyboard is the single most tedious thing about a
/// terminal on mobile.
@freezed
abstract class Snippet with _$Snippet {
  /// Creates a snippet.
  const factory({
    required String id,
    required String name,
    required String body,
    required DateTime createdAt,

    /// When set, this snippet only appears for that host.
    ///
    /// A command that is right on one machine is often wrong on another, and a
    /// list of everything you have ever saved is not a list anyone reads.
    String? hostId,

    /// Whether a newline is appended, running the command immediately.
    ///
    /// Off by default: sending text without running it lets the user read it
    /// before committing, which matters for anything destructive.
    @Default(false) bool runImmediately,
  }) = _Snippet;

  const new _();

  /// Restores a snippet from stored JSON.
  factory fromJson(Map<String, dynamic> json) => _$SnippetFromJson(json);

  /// What is actually sent to the terminal.
  String get payload => runImmediately ? '$body\n' : body;

  /// Whether this snippet is offered for [hostId].
  ///
  /// A snippet with no host is offered everywhere, including for local shells.
  bool appliesTo(String? host) => hostId == null || hostId == host;

  /// A one-line preview for the list, with newlines made visible.
  String get preview {
    final flattened = body.replaceAll('\n', ' ⏎ ').trim();
    return flattened.length <= 80
        ? flattened
        : '${flattened.substring(0, 79)}…';
  }
}
