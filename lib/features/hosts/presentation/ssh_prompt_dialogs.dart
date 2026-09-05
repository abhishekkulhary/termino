import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/shared/design/tokens.dart';

/// Asks for a single secret, obscured, returning null if the user cancels.
///
/// The value is handed straight to the caller and never stored here, logged, or
/// put in any widget that persists it.
Future<String?> showSecretPromptDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String label,
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      _SecretPromptDialog(title: title, message: message, label: label),
);

/// Answers a keyboard-interactive challenge — one field per prompt.
Future<List<String>?> showUserInfoDialog(
  BuildContext context, {
  required SshHost host,
  required SSHUserInfoRequest request,
}) => showDialog<List<String>>(
  context: context,
  builder: (context) => _UserInfoDialog(host: host, request: request),
);

class _SecretPromptDialog extends StatefulWidget {
  const new({required this.title, required this.message, required this.label});

  final String title;
  final String message;
  final String label;

  @override
  State<_SecretPromptDialog> createState() => _SecretPromptDialogState();
}

class _SecretPromptDialogState extends State<_SecretPromptDialog> {
  final _controller = TextEditingController();
  var _obscured = true;

  @override
  void dispose() {
    // Clearing before disposing means the value is not left sitting in a
    // detached controller waiting to be garbage collected.
    _controller
      ..clear()
      ..dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: Spacing.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _obscured,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.label,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 18,
                ),
                tooltip: _obscured ? 'Show' : 'Hide',
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}

class _UserInfoDialog extends StatefulWidget {
  const new({required this.host, required this.request});

  final SshHost host;
  final SSHUserInfoRequest request;

  @override
  State<_UserInfoDialog> createState() => _UserInfoDialogState();
}

class _UserInfoDialogState extends State<_UserInfoDialog> {
  late final List<TextEditingController> _controllers = [
    for (var i = 0; i < widget.request.prompts.length; i++)
      TextEditingController(),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..clear()
        ..dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = widget.request;

    return AlertDialog(
      title: Text(
        request.name.isNotEmpty ? request.name : 'Additional verification',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.instruction.isNotEmpty) ...[
              Text(request.instruction, style: theme.textTheme.bodyMedium),
              const SizedBox(height: Spacing.lg),
            ],
            for (var i = 0; i < request.prompts.length; i++) ...[
              if (i > 0) const SizedBox(height: Spacing.md),
              TextField(
                controller: _controllers[i],
                autofocus: i == 0,
                // The server decides whether an answer should be hidden, which
                // is how a one-time code stays visible but a password does not.
                obscureText: !request.prompts[i].echo,
                decoration: InputDecoration(
                  labelText: request.prompts[i].promptText.trim(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop([for (final c in _controllers) c.text]),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
