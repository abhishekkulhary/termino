import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/port_forward.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/forwarding/application/forwarding_providers.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';
import 'package:termino/shared/widgets/reveal.dart';

/// The port forwarding manager.
class ForwardingScreen extends ConsumerWidget {
  /// Creates the forwarding screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final forwards = ref.watch(portForwardsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => unawaited(_edit(context, ref)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New tunnel'),
      ),
      body: Column(
        children: [
          if (!capabilities.canRunLocalShell)
            MaterialBanner(
              content: const Text(
                'Local and dynamic tunnels need a listening socket, which a '
                'browser cannot open. Remote tunnels work anywhere.',
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              actions: const [SizedBox.shrink()],
            ),
          Expanded(
            child: forwards.isEmpty
                ? const _Empty()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: Spacing.sm, bottom: 96),
                    itemCount: forwards.length,
                    itemBuilder: (context, index) => Reveal.staggered(
                      index: index,
                      child: _ForwardCard(
                        forward: forwards[index],
                        onEdit: () =>
                            unawaited(_edit(context, ref, forwards[index])),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    PortForward? existing,
  ]) async {
    final hosts = ref.read(sshHostsProvider).value ?? const <SshHost>[];
    if (hosts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a host under Hosts first.')),
      );
      return;
    }

    final result = await showDialog<PortForward>(
      context: context,
      builder: (context) => _ForwardEditor(hosts: hosts, existing: existing),
    );
    if (result == null) return;
    unawaited(ref.read(portForwardsProvider.notifier).save(result));
  }
}

class _Empty extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: Spacing.lg),
              Text('No tunnels', style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                'Forward a local port to a machine only the server can reach '
                '(-L), expose a local service to the server (-R), or run a '
                'SOCKS proxy through it (-D).',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForwardCard extends ConsumerWidget {
  const new({required this.forward, required this.onEdit});

  final PortForward forward;
  final VoidCallback onEdit;

  /// A tunnel's own states mapped onto the light every row uses.
  ConnectionHealth _health(PortForwardStatus status) => switch (status) {
    PortForwardStatus.active => ConnectionHealth.online,
    PortForwardStatus.starting => ConnectionHealth.busy,
    PortForwardStatus.failed => ConnectionHealth.offline,
    PortForwardStatus.stopped => ConnectionHealth.idle,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forwardStatusProvider(forward.id));
    final status = state?.status ?? PortForwardStatus.stopped;
    final running = status.isRunning;

    final connections = state?.connectionCount ?? 0;
    final meta =
        state?.error ??
        (status == PortForwardStatus.active
            ? '$connections connection${connections == 1 ? '' : 's'}'
            : status.name);

    return NeonListCard(
      icon: Icons.swap_horiz_rounded,
      status: _health(status),
      selected: status == PortForwardStatus.active,
      title: forward.label ?? forward.summary,
      subtitle: forward.argument,
      meta: meta,
      tags: [forward.kind.label],
      actions: [
        NeonAction(
          icon: running
              ? Icons.stop_circle_outlined
              : Icons.play_circle_outline_rounded,
          tooltip: running ? 'Stop' : 'Start',
          onPressed: () => unawaited(
            running
                ? ref.read(portForwardsProvider.notifier).stop(forward)
                : ref.read(portForwardsProvider.notifier).start(forward),
          ),
        ),
        MenuAnchor(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.edit_rounded, size: 18),
              onPressed: onEdit,
              child: const Text('Edit'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () => unawaited(
                Clipboard.setData(ClipboardData(text: forward.argument)),
              ),
              child: const Text('Copy argument'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.delete_outline_rounded, size: 18),
              onPressed: () => unawaited(
                ref.read(portForwardsProvider.notifier).remove(forward.id),
              ),
              child: const Text('Delete'),
            ),
          ],
          builder: (context, controller, _) => IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            tooltip: 'More',
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
        ),
      ],
    );
  }
}

class _ForwardEditor extends StatefulWidget {
  const new({required this.hosts, this.existing});

  final List<SshHost> hosts;
  final PortForward? existing;

  @override
  State<_ForwardEditor> createState() => _ForwardEditorState();
}

class _ForwardEditorState extends State<_ForwardEditor> {
  late String _hostId = widget.existing?.hostId ?? widget.hosts.first.id;
  late PortForwardKind _kind = widget.existing?.kind ?? PortForwardKind.local;
  late final _listenPort = TextEditingController(
    text: '${widget.existing?.listenPort ?? 8080}',
  );
  late final _destinationHost = TextEditingController(
    text: widget.existing?.destinationHost ?? 'localhost',
  );
  late final _destinationPort = TextEditingController(
    text: '${widget.existing?.destinationPort ?? 80}',
  );
  late final _label = TextEditingController(text: widget.existing?.label ?? '');

  @override
  void dispose() {
    for (final controller in [
      _listenPort,
      _destinationHost,
      _destinationPort,
      _label,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final forward = PortForward(
      id:
          widget.existing?.id ??
          'forward-${DateTime.now().microsecondsSinceEpoch}',
      hostId: _hostId,
      kind: _kind,
      listenPort: int.tryParse(_listenPort.text) ?? 0,
      destinationHost: _kind.needsDestination ? _destinationHost.text : null,
      destinationPort: _kind.needsDestination
          ? int.tryParse(_destinationPort.text)
          : null,
      label: _label.text.trim().isEmpty ? null : _label.text.trim(),
    );
    Navigator.of(context).pop(forward);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New tunnel' : 'Edit tunnel'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _hostId,
              decoration: const InputDecoration(labelText: 'Through host'),
              items: [
                for (final host in widget.hosts)
                  DropdownMenuItem(value: host.id, child: Text(host.label)),
              ],
              onChanged: (value) => setState(() => _hostId = value ?? _hostId),
            ),
            const SizedBox(height: Spacing.lg),
            SegmentedButton<PortForwardKind>(
              segments: const [
                ButtonSegment(value: PortForwardKind.local, label: Text('-L')),
                ButtonSegment(value: PortForwardKind.remote, label: Text('-R')),
                ButtonSegment(
                  value: PortForwardKind.dynamic,
                  label: Text('-D'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) =>
                  setState(() => _kind = selection.first),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              switch (_kind) {
                PortForwardKind.local =>
                  'Listen here and connect from the server — reach a machine '
                      'only it can see.',
                PortForwardKind.remote =>
                  'The server listens and connections come back here — expose '
                      'a local service to it.',
                PortForwardKind.dynamic =>
                  'A SOCKS proxy here, with every connection made from the '
                      'server.',
              },
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _listenPort,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: _kind == PortForwardKind.remote
                    ? 'Port on the server'
                    : 'Port on this device',
              ),
            ),
            if (_kind.needsDestination) ...[
              const SizedBox(height: Spacing.lg),
              TextField(
                controller: _destinationHost,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'To host'),
              ),
              const SizedBox(height: Spacing.lg),
              TextField(
                controller: _destinationPort,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'To port'),
              ),
            ],
            const SizedBox(height: Spacing.lg),
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Name (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
