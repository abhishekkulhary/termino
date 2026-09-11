import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/snippet.dart';
import 'package:termino/features/snippets/presentation/snippet_sheet.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// Snippets were tested at the model and storage layer and nowhere in the UI,
/// which left the sheet — the only way anyone reaches them — unheld. These
/// drive it the way a person does: open it, write one, send it, scope it.
void main() {
  /// Opens the sheet over a throwaway screen, as the terminal does.
  Future<List<String>> openSheet(
    WidgetTester tester,
    ProviderContainer container, {
    String? hostId,
  }) async {
    final sent = <String>[];

    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () =>
                  showSnippetSheet(context, hostId: hostId, onSend: sent.add),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      container: container,
      size: const Size(600, 800),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return sent;
  }

  /// Fills in the editor and saves.
  Future<void> writeSnippet(
    WidgetTester tester, {
    required String name,
    required String command,
  }) async {
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), name);
    await tester.enterText(find.widgetWithText(TextField, 'Command'), command);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty list explains what snippets are for', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await openSheet(tester, container);

    expect(find.text('Snippets'), findsOneWidget);
    expect(find.textContaining('never remember'), findsOneWidget);
  });

  testWidgets('writing one saves it and shows it', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await openSheet(tester, container);
    await writeSnippet(
      tester,
      name: 'Follow the log',
      command: 'journalctl -fu termino',
    );

    final saved = await container.read(snippetRepositoryProvider).all();
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Follow the log');
    expect(saved.single.body, 'journalctl -fu termino');

    expect(find.text('Follow the log'), findsOneWidget);
    expect(
      find.textContaining('never remember'),
      findsNothing,
      reason: 'the empty state goes once there is something to show',
    );
  });

  testWidgets('tapping one sends it to the terminal', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    final sent = await openSheet(tester, container);
    await writeSnippet(tester, name: 'List', command: 'ls -la');

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();

    expect(sent, ['ls -la']);
  });

  testWidgets('a snippet scoped to a host stays on that host', (tester) async {
    // A snippet with no host applies everywhere; one tied to a host should
    // appear only there. The sheet is opened for a different host here.
    final container = testContainer();
    addTearDown(container.dispose);

    await container
        .read(snippetRepositoryProvider)
        .save(
          Snippet(
            id: 's1',
            name: 'Only on build server',
            body: 'make release',
            createdAt: DateTime.utc(2026),
            hostId: 'build',
          ),
        );

    await openSheet(tester, container, hostId: 'other');

    expect(find.text('Only on build server'), findsNothing);
    expect(
      find.textContaining('never remember'),
      findsOneWidget,
      reason: 'from this host there are no snippets at all',
    );
  });

  testWidgets('and does appear on the host it belongs to', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await container
        .read(snippetRepositoryProvider)
        .save(
          Snippet(
            id: 's1',
            name: 'Only on build server',
            body: 'make release',
            createdAt: DateTime.utc(2026),
            hostId: 'build',
          ),
        );

    await openSheet(tester, container, hostId: 'build');

    expect(find.text('Only on build server'), findsOneWidget);
  });

  testWidgets('the host-scope box decides where a new snippet lands', (
    tester,
  ) async {
    // The box only appears when the sheet was opened for a host, and it starts
    // clear: a new snippet is saved for everywhere unless the user says
    // otherwise. (`_SnippetEditorState` says this twice and disagrees with
    // itself — the field initialiser scopes a new snippet, `initState` then
    // clears it. `initState` wins, and always has; this test pins the
    // behaviour people have actually had.)
    final container = testContainer();
    addTearDown(container.dispose);

    await openSheet(tester, container, hostId: 'build');
    await writeSnippet(tester, name: 'Uptime', command: 'uptime');

    var saved = await container.read(snippetRepositoryProvider).all();
    expect(saved.single.hostId, isNull, reason: 'the box was left clear');

    // Ticking it ties the next one to the host the sheet was opened for.
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Deploy');
    await tester.enterText(
      find.widgetWithText(TextField, 'Command'),
      'make deploy',
    );
    await tester.tap(find.text('Only for this host'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    saved = await container.read(snippetRepositoryProvider).all();
    expect(saved.firstWhere((s) => s.name == 'Deploy').hostId, 'build');
  });

  testWidgets('deleting one removes it for good', (tester) async {
    final container = testContainer();
    addTearDown(container.dispose);

    await openSheet(tester, container);
    await writeSnippet(
      tester,
      name: 'Follow the log',
      command: 'journalctl -f',
    );

    // Delete lives behind the row's overflow menu.
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await container.read(snippetRepositoryProvider).all(), isEmpty);
    expect(find.text('Follow the log'), findsNothing);
    expect(
      find.textContaining('never remember'),
      findsOneWidget,
      reason: 'the last snippet going takes the list back to empty',
    );
  });
}
