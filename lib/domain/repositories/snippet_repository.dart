import 'package:termino/domain/entities/snippet.dart';

/// Stores saved commands.
abstract class SnippetRepository {
  /// Every snippet, newest first.
  Future<List<Snippet>> all();

  /// Emits the full list whenever it changes.
  Stream<List<Snippet>> watch();

  /// Creates or updates a snippet.
  Future<void> save(Snippet snippet);

  /// Deletes a snippet.
  Future<void> delete(String id);
}
