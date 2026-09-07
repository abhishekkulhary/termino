import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/features/backup/application/backup_service.dart';
import 'package:termino/features/known_hosts/presentation/known_hosts_screen.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/settings/presentation/font_picker.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/terminal_palette.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';
import 'package:termino/shared/widgets/reveal.dart';

/// Appearance and behaviour settings.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final capabilities = ref.watch(platformCapabilitiesProvider);

    // A Scaffold of its own, as every other screen has. Without one the tiles
    // have no Material ancestor and the whole list fails to build the moment
    // it is shown anywhere but inside the app shell.
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Constrained and centred. A slider spanning a 1280-pixel window is not
      // more adjustable, only harder to aim at, and settings read as a column
      // whatever the window is doing.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.xxl,
            ),
            children: [
              _Group(
                label: 'Appearance',
                children: [
                  ListTile(
                    title: const Text('App theme'),
                    subtitle: Text(settings.themeMode.label),
                    trailing: DropdownButton<AppThemeMode>(
                      value: settings.themeMode,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final mode in AppThemeMode.values)
                          DropdownMenuItem(
                            value: mode,
                            child: Text(mode.label),
                          ),
                      ],
                      onChanged: (mode) => mode == null
                          ? null
                          : unawaited(controller.setThemeMode(mode)),
                    ),
                  ),
                ],
              ),
              _Group(
                label: 'Terminal palette',
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  _PaletteGrid(
                    selectedId: settings.paletteId,
                    onSelected: (id) => unawaited(controller.setPalette(id)),
                  ),
                ],
              ),
              _Group(
                label: 'Text',
                children: [
                  _FontFamilyTile(
                    family: settings.fontFamily,
                    onChanged: (family) =>
                        unawaited(controller.setFontFamily(family)),
                  ),
                  _SliderTile(
                    title: 'Font size',
                    value: settings.fontSize,
                    min: TerminalSettings.minFontSize,
                    max: TerminalSettings.maxFontSize,
                    format: (value) => '${value.round()} pt',
                    onChanged: (value) =>
                        unawaited(controller.setFontSize(value)),
                  ),
                  _SliderTile(
                    title: 'Line height',
                    value: settings.lineHeight,
                    min: 1,
                    max: 2,
                    format: (value) => value.toStringAsFixed(2),
                    onChanged: (value) =>
                        unawaited(controller.setLineHeight(value)),
                  ),
                ],
              ),
              _Group(
                label: 'Cursor',
                children: [
                  ListTile(
                    title: const Text('Shape'),
                    trailing: SegmentedButton<TerminalCursorShape>(
                      segments: [
                        for (final shape in TerminalCursorShape.values)
                          ButtonSegment(value: shape, label: Text(shape.label)),
                      ],
                      selected: {settings.cursorShape},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          unawaited(controller.setCursorShape(selection.first)),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Blink'),
                    value: settings.cursorBlinks,
                    onChanged: (value) =>
                        unawaited(controller.setCursorBlinks(blinks: value)),
                  ),
                ],
              ),
              _Group(
                label: 'Behaviour',
                children: [
                  ListTile(
                    title: const Text('Bell'),
                    subtitle: Text(settings.bell.label),
                    trailing: DropdownButton<BellBehaviour>(
                      value: settings.bell,
                      underline: const SizedBox.shrink(),
                      items: [
                        // Vibration is offered only where there is something
                        // to vibrate. On a desktop it would be a control that
                        // does nothing — which is what this whole setting used
                        // to be.
                        //
                        // The stored value is always listed, whatever it is. A
                        // DropdownButton asserts when its value is not among
                        // its items, so a preference carried over from a phone
                        // would otherwise take this screen down.
                        for (final bell in BellBehaviour.values)
                          if (bell != BellBehaviour.haptic ||
                              capabilities.hasHaptics ||
                              settings.bell == bell)
                            DropdownMenuItem(
                              value: bell,
                              child: Text(bell.label),
                            ),
                      ],
                      onChanged: (bell) => bell == null
                          ? null
                          : unawaited(controller.setBell(bell)),
                    ),
                  ),
                  ListTile(
                    title: const Text('Scrollback'),
                    subtitle: Text(
                      '${settings.scrollbackLines} lines — applies to new '
                      'sessions',
                    ),
                    trailing: DropdownButton<int>(
                      value: settings.scrollbackLines,
                      underline: const SizedBox.shrink(),
                      items: [
                        // The stored value is included even when it is not one
                        // of the offered sizes. `setScrollback` takes any
                        // integer, and a value from another version of the app
                        // must not crash this screen.
                        for (final lines in {
                          ...TerminalSettings.scrollbackOptions,
                          settings.scrollbackLines,
                        }.toList()..sort())
                          DropdownMenuItem(value: lines, child: Text('$lines')),
                      ],
                      onChanged: (lines) => lines == null
                          ? null
                          : unawaited(controller.setScrollback(lines)),
                    ),
                  ),
                ],
              ),
              if (capabilities.needsRelay)
                _Group(
                  label: 'Relay',
                  children: [
                    _RelayTile(
                      url: settings.relayUrl,
                      onChanged: (url) =>
                          unawaited(controller.setRelayUrl(url)),
                    ),
                  ],
                ),
              _Group(
                label: 'Security',
                children: [
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Trusted host keys'),
                    subtitle: const Text(
                      'Review and forget the keys you have accepted',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push<void>(
                      FadeThroughPageRoute(
                        builder: (_) => const KnownHostsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              _Group(
                label: 'Backup',
                children: [
                  ListTile(
                    leading: const Icon(Icons.ios_share_rounded),
                    title: const Text('Export'),
                    subtitle: const Text(
                      'Hosts, snippets and tunnels — never keys or passwords',
                    ),
                    onTap: () => unawaited(_export(context, ref)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_rounded),
                    title: const Text('Restore'),
                    subtitle: const Text(
                      'Adds to what is here; nothing is '
                      'removed',
                    ),
                    onTap: () => unawaited(_restore(context, ref)),
                  ),
                ],
              ),
              _Group(
                label: 'Everything else',
                children: [
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded),
                    title: const Text('Reset to defaults'),
                    subtitle: const Text(
                      'Appearance, text, cursor and behaviour',
                    ),
                    onTap: () => unawaited(_confirmReset(context, controller)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Writes a backup and hands it to the platform's share sheet.
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final contents = await ref.read(backupServiceProvider.notifier).export();
      final directory = await getTemporaryDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .split('.')
          .first
          .replaceAll(RegExp('[:-]'), '');
      final file = File('${directory.path}/termino-backup-$stamp.json');
      await file.writeAsString(contents, flush: true);

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('The backup could not be written.')),
      );
    }
  }

  /// Reads a backup the user picks and merges it in.
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await FilePicker.pickFiles();
      final path = picked.singleOrNull?.path;
      if (path == null) return;

      final summary = await ref
          .read(backupServiceProvider.notifier)
          .restore(await File(path).readAsString());

      messenger.showSnackBar(SnackBar(content: Text(summary.description)));
    } on FormatException catch (error) {
      // The one place a raw exception message is shown, because it is written
      // for this: "that file is not a Termino backup" says what to do next in
      // a way a generic sentence cannot.
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('That file could not be read.')),
      );
    }
  }

  /// Asks before undoing every preference at once.
  ///
  /// It was a single tap with no confirmation and no undo, sitting at the
  /// bottom of a list people scroll through.
  Future<void> _confirmReset(BuildContext context, Settings controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset settings?'),
        content: const Text(
          'Every preference goes back to its default. Saved hosts, keys and '
          'snippets are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await controller.reset();
  }
}

/// A labelled panel holding a few related controls.
///
/// The settings were a flat list of tiles running edge to edge, which on a
/// desktop window is a lot of nothing between a label and the control it
/// belongs to. Grouping them into panels gives each section an edge, and
/// matches how a host is drawn on the screen next door.
class _Group extends StatelessWidget {
  const new({
    required this.label,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final String label;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeonSectionLabel(label),
          NeonPanel(
            padding: padding,
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ],
      ),
    );
  }
}

/// Where the web build sends its SSH traffic.
///
/// Shown only in a browser, where there is no other way to reach a server.
class _RelayTile extends StatelessWidget {
  const new({required this.url, required this.onChanged});

  final String? url;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: url,
            autocorrect: false,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Relay address',
              hintText: 'wss://relay.example.com/ssh',
            ),
            onFieldSubmitted: onChanged,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'A browser cannot open a network connection directly, so SSH goes '
            'through a relay. The relay only forwards bytes: SSH runs here, so '
            'it carries ciphertext and cannot read your session, your password '
            'or your keys — and it cannot impersonate a server, because the '
            'host key is checked on this device.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Use wss:// rather than ws://. A browser will not let the app pin '
            'the relay certificate, so the connection relies on the ordinary '
            'certificate authorities.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Palette swatches, each showing the colours it actually paints with.
///
/// A list of names would make the user pick blind; the point of a palette is
/// what it looks like.
class _PaletteGrid extends StatelessWidget {
  const new({required this.selectedId, required this.onSelected});

  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Wrap(
        spacing: Spacing.md,
        runSpacing: Spacing.md,
        children: [
          _FollowThemeSwatch(
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          for (final palette in TerminalPalettes.all)
            _PaletteSwatch(
              palette: palette,
              selected: palette.id == selectedId,
              onTap: () => onSelected(palette.id),
            ),
        ],
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const new({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final TerminalPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = palette.theme;

    return Semantics(
      button: true,
      selected: selected,
      label: palette.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.borderMd,
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: Radii.borderMd,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                palette.name,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  for (final color in [
                    colors.red,
                    colors.green,
                    colors.yellow,
                    colors.blue,
                    colors.magenta,
                    colors.cyan,
                  ])
                    Expanded(child: Container(height: 10, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowThemeSwatch extends StatelessWidget {
  const new({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Follow the app theme',
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.borderMd,
        child: Container(
          width: 132,
          // No fixed height: the label wraps on a narrow phone, and a fixed
          // box overflowed by 40 pixels when it did.
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: Radii.borderMd,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Automatic',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.xxs),
              Text(
                'Follows the theme',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
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

class _SliderTile extends StatelessWidget {
  const new({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.format,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(title),
          const Spacer(),
          Text(format(value), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      subtitle: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }
}

/// Chooses the family the grid is drawn in, and shows the result.
///
/// The preview is the point. Flutter cannot tell whether a family is
/// installed, so a name that is not there falls back without complaint —
/// showing the choice rendered in itself is the only honest way to let someone
/// see that it did not take.
class _FontFamilyTile extends StatelessWidget {
  const new({required this.family, required this.onChanged});

  final String? family;
  final ValueChanged<String?> onChanged;

  static const _bundled = 'Termino Mono';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = MonospaceSuggestions.forPlatform();
    // The stored value is always offered, so a family typed in by hand — or
    // one carried over from another platform in a backup — does not vanish
    // from the control that holds it.
    final options = <String?>[
      null,
      ...{...suggestions, ?family},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: const Text('Font'),
          subtitle: Text(family ?? '$_bundled (bundled)'),
          trailing: DropdownButton<String?>(
            value: family,
            underline: const SizedBox.shrink(),
            items: [
              for (final option in options)
                DropdownMenuItem(
                  value: option,
                  child: Text(option ?? _bundled),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            0,
            Spacing.lg,
            Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: ValueKey('font-family-${family ?? ''}'),
                initialValue: family ?? '',
                decoration: const InputDecoration(
                  labelText: 'Or type a family installed on this device',
                  hintText: 'Fira Code',
                  isDense: true,
                ),
                onFieldSubmitted: onChanged,
              ),
              const SizedBox(height: Spacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  borderRadius: Radii.borderSm,
                  border: Border.all(
                    color: NeonAccents.of(context).panelBorder,
                  ),
                ),
                child: Text(
                  // Characters that differ most between monospace faces, plus
                  // the box drawing a prompt is full of.
                  'ILl1 O0o {}[]() =>!= ─│┌┐└┘',
                  style: TextStyle(
                    fontFamily: family ?? Fonts.mono,
                    fontFamilyFallback: family == null
                        ? Fonts.monoFallback
                        : [Fonts.mono, ...Fonts.monoFallback],
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
