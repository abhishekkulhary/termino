import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/domain/entities/snippet.dart';
import 'package:termino/features/snippets/application/snippet_service.dart';
import 'package:termino/shared/design/tokens.dart';

/// Offers the saved commands for a session, and sends the chosen one.
///
/// Reached from the terminal rather than from a screen of its own: a snippet is
/// something you want *while* you are in a session, and making the user
/// navigate away to find one defeats the purpose.
Future<void> showSnippetSheet(
  BuildContext context, {
  required String? hostId,
  required void Function(String text) onSend,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => _SnippetSheet(hostId: hostId, onSend: onSend),
);

class _SnippetSheet extends ConsumerWidget {
  const new({required this.hostId, required this.onSend});

  final String? hostId;
  final void Function(String text) onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippets = ref.watch(snippetsForHostProvider(hostId));
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(
                children: [
                  Text('Snippets', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        unawaited(_edit(context, ref, hostId: hostId)),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            if (snippets.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Text(
                  'Save the commands you never remember — the long journalctl '
                  'one, the docker invocation with six flags — and send them '
                  'with one tap.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: snippets.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _SnippetTile(
                    snippet: snippets[index],
                    onSend: () {
                      Navigator.of(context).pop();
                      onSend(snippets[index].payload);
                    },
                    onEdit: () => unawaited(
                      _edit(context, ref, existing: snippets[index]),
                    ),
                    onDelete: () => unawaited(
                      ref
                          .read(snippetServiceProvider)
                          .delete(snippets[index].id),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    Snippet? existing,
    String? hostId,
  }) async {
    final result = await showDialog<_SnippetDraft>(
      context: context,
      builder: (context) =>
          _SnippetEditor(existing: existing, hostId: hostId ?? this.hostId),
    );
    if (result == null) return;

    await ref
        .read(snippetServiceProvider)
        .save(
          name: result.name,
          body: result.body,
          hostId: result.scopeToHost ? (existing?.hostId ?? hostId) : null,
          runImmediately: result.runImmediately,
          existing: existing,
        );
  }
}

class _SnippetTile extends StatelessWidget {
  const new({
    required this.snippet,
    required this.onSend,
    required this.onEdit,
    required this.onDelete,
  });

  final Snippet snippet;
  final VoidCallback onSend;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onSend,
      title: Row(
        children: [
          Flexible(child: Text(snippet.name)),
          if (snippet.runImmediately) ...[
            const SizedBox(width: Spacing.sm),
            Tooltip(
              message: 'Runs immediately',
              child: Icon(
                Icons.play_arrow_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (snippet.hostId != null) ...[
            const SizedBox(width: Spacing.xs),
            Tooltip(
              message: 'Only for this host',
              child: Icon(
                Icons.dns_rounded,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        snippet.preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: Fonts.mono,
          fontFamilyFallback: Fonts.monoFallback,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: MenuAnchor(
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.edit_rounded, size: 18),
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.delete_outline_rounded, size: 18),
            onPressed: onDelete,
            child: const Text('Delete'),
          ),
        ],
        builder: (context, controller, _) => IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 18),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

/// What the editor collected.
class _SnippetDraft {
  const new({
    required this.name,
    required this.body,
    required this.runImmediately,
    required this.scopeToHost,
  });

  final String name;
  final String body;
  final bool runImmediately;
  final bool scopeToHost;
}

class _SnippetEditor extends StatefulWidget {
  const new({required this.existing, required this.hostId});

  final Snippet? existing;
  final String? hostId;

  @override
  State<_SnippetEditor> createState() => _SnippetEditorState();
}

class _SnippetEditorState extends State<_SnippetEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _body = TextEditingController(text: widget.existing?.body ?? '');
  late bool _runImmediately = widget.existing?.runImmediately ?? false;

  /// Whether this snippet is tied to the host the sheet was opened for.
  ///
  /// Off for a new one: a snippet saved for everywhere can be found from
  /// anywhere, while one quietly scoped to a host is invisible on the next
  /// machine and the user has no reason to suspect where it went. Editing an
  /// existing snippet keeps whatever it already had.
  late bool _scopeToHost = widget.existing?.hostId != null;

  @override
  void dispose() {
    _name.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New snippet' : 'Edit snippet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _body,
              minLines: 3,
              maxLines: 8,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(
                fontFamily: Fonts.mono,
                fontFamilyFallback: Fonts.monoFallback,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                labelText: 'Command',
                alignLabelWithHint: true,
              ),
            ),
            CheckboxListTile(
              value: _runImmediately,
              onChanged: (value) =>
                  setState(() => _runImmediately = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Run immediately'),
              subtitle: const Text(
                'Off means the command is typed but not sent, so you can read '
                'it first.',
              ),
            ),
            if (widget.hostId != null)
              CheckboxListTile(
                value: _scopeToHost,
                onChanged: (value) =>
                    setState(() => _scopeToHost = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Only for this host'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty || _body.text.isEmpty) return;
            Navigator.of(context).pop(
              _SnippetDraft(
                name: _name.text,
                body: _body.text,
                runImmediately: _runImmediately,
                scopeToHost: _scopeToHost,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
