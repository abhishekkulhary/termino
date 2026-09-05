import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/shared/design/terminal_palette.dart';
import 'package:termino/shared/design/tokens.dart';

/// Appearance and behaviour settings.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.xxl),
      children: [
        const _SectionHeader('Appearance'),
        ListTile(
          title: const Text('App theme'),
          subtitle: Text(settings.themeMode.label),
          trailing: DropdownButton<AppThemeMode>(
            value: settings.themeMode,
            underline: const SizedBox.shrink(),
            items: [
              for (final mode in AppThemeMode.values)
                DropdownMenuItem(value: mode, child: Text(mode.label)),
            ],
            onChanged: (mode) =>
                mode == null ? null : unawaited(controller.setThemeMode(mode)),
          ),
        ),
        const _SectionHeader('Terminal palette'),
        _PaletteGrid(
          selectedId: settings.paletteId,
          onSelected: (id) => unawaited(controller.setPalette(id)),
        ),
        const _SectionHeader('Text'),
        _SliderTile(
          title: 'Font size',
          value: settings.fontSize,
          min: TerminalSettings.minFontSize,
          max: TerminalSettings.maxFontSize,
          format: (value) => '${value.round()} pt',
          onChanged: (value) => unawaited(controller.setFontSize(value)),
        ),
        _SliderTile(
          title: 'Line height',
          value: settings.lineHeight,
          min: 1,
          max: 2,
          format: (value) => value.toStringAsFixed(2),
          onChanged: (value) => unawaited(controller.setLineHeight(value)),
        ),
        const _SectionHeader('Cursor'),
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
        const _SectionHeader('Behaviour'),
        ListTile(
          title: const Text('Bell'),
          subtitle: Text(settings.bell.label),
          trailing: DropdownButton<BellBehaviour>(
            value: settings.bell,
            underline: const SizedBox.shrink(),
            items: [
              for (final bell in BellBehaviour.values)
                DropdownMenuItem(value: bell, child: Text(bell.label)),
            ],
            onChanged: (bell) =>
                bell == null ? null : unawaited(controller.setBell(bell)),
          ),
        ),
        ListTile(
          title: const Text('Scrollback'),
          subtitle: Text('${settings.scrollbackLines} lines'),
          trailing: DropdownButton<int>(
            value: settings.scrollbackLines,
            underline: const SizedBox.shrink(),
            items: [
              for (final lines in TerminalSettings.scrollbackOptions)
                DropdownMenuItem(value: lines, child: Text('$lines')),
            ],
            onChanged: (lines) => lines == null
                ? null
                : unawaited(controller.setScrollback(lines)),
          ),
        ),
        const Divider(height: Spacing.xxl),
        ListTile(
          leading: const Icon(Icons.restart_alt_rounded),
          title: const Text('Reset to defaults'),
          onTap: () => unawaited(controller.reset()),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xl,
        Spacing.lg,
        Spacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
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
