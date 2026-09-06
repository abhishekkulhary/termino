import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/grid_backdrop.dart';

/// Creates or edits a saved SSH connection.
class HostEditorScreen extends ConsumerStatefulWidget {
  /// Edits [host], or creates a new one when it is null.
  const new({super.key, this.host});

  /// The connection being edited.
  final SshHost? host;

  @override
  ConsumerState<HostEditorScreen> createState() => _HostEditorScreenState();
}

class _HostEditorScreenState extends ConsumerState<HostEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _label = TextEditingController(text: widget.host?.label ?? '');
  late final _hostname = TextEditingController(
    text: widget.host?.hostname ?? '',
  );
  late final _username = TextEditingController(
    text: widget.host?.username ?? '',
  );
  late final _port = TextEditingController(text: '${widget.host?.port ?? 22}');
  late final _startupCommand = TextEditingController(
    text: widget.host?.startupCommand ?? '',
  );

  late String? _identityId = widget.host?.identityId;
  late String? _jumpHostId = widget.host?.jumpHostId;
  late int _keepAliveSeconds = widget.host?.keepAliveInterval.inSeconds ?? 30;
  late bool _forwardAgent = widget.host?.forwardAgent ?? false;

  @override
  void dispose() {
    for (final controller in [
      _label,
      _hostname,
      _username,
      _port,
      _startupCommand,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final navigator = Navigator.of(context);
    final host = SshHost(
      id: widget.host?.id ?? _newId(),
      label: _label.text.trim(),
      hostname: _hostname.text.trim(),
      username: _username.text.trim(),
      port: int.parse(_port.text.trim()),
      identityId: _identityId,
      jumpHostId: _jumpHostId,
      keepAliveInterval: Duration(seconds: _keepAliveSeconds),
      startupCommand: _startupCommand.text.trim().isEmpty
          ? null
          : _startupCommand.text.trim(),
      colorValue: widget.host?.colorValue,
      folder: widget.host?.folder,
      hasSavedPassword: widget.host?.hasSavedPassword ?? false,
      forwardAgent: _forwardAgent,
    );

    await ref.read(sshHostRepositoryProvider).save(host);
    navigator.pop();
  }

  static String _newId() =>
      'host-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';

  @override
  Widget build(BuildContext context) {
    final identities =
        ref.watch(sshIdentitiesProvider).value ?? const <SshIdentity>[];
    final hosts = ref.watch(sshHostsProvider).value ?? const <SshHost>[];
    final others = hosts
        .where((candidate) => candidate.id != widget.host?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.host == null ? 'New host' : 'Edit host'),
        actions: [
          TextButton(
            onPressed: () => unawaited(_save()),
            child: const Text('Save'),
          ),
          const SizedBox(width: Spacing.sm),
        ],
      ),
      // The same backdrop as every other screen. A pushed route sits outside
      // the app shell, so without this the editor is the one surface in the
      // app with nothing behind it.
      body: GridBackdrop(
        child: Form(
          key: _formKey,
          // Constrained, for the same reason settings is: a text field spanning
          // a desktop window is not easier to fill in, and a form reads as a
          // column.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(Spacing.lg),
                children: [
                  TextFormField(
                    controller: _label,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      helperText: 'What you call this machine',
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Give the connection a name'
                        : null,
                  ),
                  const SizedBox(height: Spacing.lg),
                  TextFormField(
                    controller: _hostname,
                    decoration: const InputDecoration(labelText: 'Host'),
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Enter a hostname or address'
                        : null,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _username,
                          decoration: const InputDecoration(labelText: 'User'),
                          autocorrect: false,
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Enter a username'
                              : null,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _port,
                          decoration: const InputDecoration(labelText: 'Port'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: _validatePort,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl),
                  const _SectionLabel('Authentication'),
                  const SizedBox(height: Spacing.sm),
                  DropdownButtonFormField<String?>(
                    initialValue: _identityId,
                    decoration: const InputDecoration(
                      labelText: 'Key',
                      helperText: 'Leave unset to use a password',
                    ),
                    items: [
                      const DropdownMenuItem(child: Text('None')),
                      for (final identity in identities)
                        DropdownMenuItem(
                          value: identity.id,
                          child: Text(
                            '${identity.name} (${identity.keyType.label})',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _identityId = value),
                  ),
                  const SizedBox(height: Spacing.lg),
                  SwitchListTile(
                    value: _forwardAgent,
                    onChanged: (value) => setState(() => _forwardAgent = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Forward this key'),
                    subtitle: const Text(
                      'Lets the remote host authenticate onward with this '
                      'key. The key never leaves this device, but anyone '
                      'with root there can use it while the session lasts.',
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  const _SectionLabel('Connection'),
                  const SizedBox(height: Spacing.sm),
                  DropdownButtonFormField<String?>(
                    initialValue: _jumpHostId,
                    decoration: const InputDecoration(
                      labelText: 'Jump host',
                      helperText:
                          'Tunnel through another saved host (ProxyJump)',
                    ),
                    items: [
                      const DropdownMenuItem(child: Text('Direct')),
                      for (final other in others)
                        DropdownMenuItem(
                          value: other.id,
                          child: Text(other.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _jumpHostId = value),
                  ),
                  const SizedBox(height: Spacing.lg),
                  DropdownButtonFormField<int>(
                    initialValue: _keepAliveSeconds,
                    decoration: const InputDecoration(labelText: 'Keepalive'),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Off')),
                      DropdownMenuItem(
                        value: 15,
                        child: Text('Every 15 seconds'),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: Text('Every 30 seconds'),
                      ),
                      DropdownMenuItem(value: 60, child: Text('Every minute')),
                    ],
                    onChanged: (value) =>
                        setState(() => _keepAliveSeconds = value ?? 30),
                  ),
                  const SizedBox(height: Spacing.lg),
                  TextFormField(
                    controller: _startupCommand,
                    decoration: const InputDecoration(
                      labelText: 'Startup command',
                      helperText: 'Run once the shell opens, e.g. tmux attach',
                    ),
                    autocorrect: false,
                  ),
                  const SizedBox(height: Spacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _validatePort(String? value) {
    final port = int.tryParse((value ?? '').trim());
    if (port == null) return 'Required';
    if (port < 1 || port > 65535) return '1–65535';
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
