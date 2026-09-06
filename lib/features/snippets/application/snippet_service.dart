import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/snippet.dart';
import 'package:termino/domain/repositories/snippet_repository.dart';

part 'snippet_service.g.dart';

/// Creates, edits and deletes saved commands.
class SnippetService {
  /// Creates a service over the repository.
  const new(this._repository);

  final SnippetRepository _repository;

  /// Saves a new snippet, or updates [existing].
  Future<Snippet> save({
    required String name,
    required String body,
    String? hostId,
    bool runImmediately = false,
    Snippet? existing,
  }) async {
    final snippet = Snippet(
      id: existing?.id ?? _newId(),
      name: name.trim(),
      body: body,
      hostId: hostId,
      runImmediately: runImmediately,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    await _repository.save(snippet);
    return snippet;
  }

  /// Deletes a snippet.
  Future<void> delete(String id) => _repository.delete(id);

  static String _newId() =>
      'snippet-${DateTime.now().microsecondsSinceEpoch}'
      '-${Random().nextInt(999)}';
}

/// The snippet service for the current scope.
@Riverpod(keepAlive: true)
SnippetService snippetService(Ref ref) =>
    SnippetService(ref.watch(snippetRepositoryProvider));

/// The snippets offered for [hostId], most recent first.
///
/// A snippet with no host applies everywhere, including local shells; one tied
/// to a host appears only there.
@riverpod
List<Snippet> snippetsForHost(Ref ref, String? hostId) => [
  ...?ref
      .watch(snippetsProvider)
      .value
      ?.where((snippet) => snippet.appliesTo(hostId)),
];
