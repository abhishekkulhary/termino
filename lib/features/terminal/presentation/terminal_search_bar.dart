import 'package:flutter/material.dart';
import 'package:termino/domain/terminal/scrollback_search.dart';
import 'package:termino/features/terminal/application/terminal_search_controller.dart';
import 'package:termino/shared/design/tokens.dart';

/// The find bar shown above a terminal.
class TerminalSearchBar extends StatefulWidget {
  /// Creates a search bar driving [controller].
  const new({required this.controller, required this.onClose, super.key});

  /// The search being driven.
  final TerminalSearchController controller;

  /// Called when the user dismisses the bar.
  final VoidCallback onClose;

  @override
  State<TerminalSearchBar> createState() => _TerminalSearchBarState();
}

class _TerminalSearchBarState extends State<TerminalSearchBar> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  var _options = const SearchOptions();

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _run() => widget.controller.search(_field.text, options: _options);

  void _toggle({bool? regex, bool? caseSensitive, bool? wholeWord}) {
    setState(() {
      _options = SearchOptions(
        useRegex: regex ?? _options.useRegex,
        caseSensitive: caseSensitive ?? _options.caseSensitive,
        wholeWord: wholeWord ?? _options.wholeWord,
      );
    });
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final search = widget.controller;
        final total = search.matches.length;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _field,
                  focusNode: _focus,
                  autocorrect: false,
                  onChanged: (_) => _run(),
                  onSubmitted: (_) => search.next(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: Fonts.mono,
                    fontFamilyFallback: Fonts.monoFallback,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Find in scrollback',
                    border: InputBorder.none,
                    errorText: search.error,
                  ),
                ),
              ),
              _OptionToggle(
                label: '.*',
                tooltip: 'Regular expression',
                selected: _options.useRegex,
                onChanged: (value) => _toggle(regex: value),
              ),
              _OptionToggle(
                label: 'Aa',
                tooltip: 'Match case',
                selected: _options.caseSensitive,
                onChanged: (value) => _toggle(caseSensitive: value),
              ),
              _OptionToggle(
                label: 'W',
                tooltip: 'Whole word',
                selected: _options.wholeWord,
                onChanged: (value) => _toggle(wholeWord: value),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                total == 0
                    ? (search.isActive && search.error == null ? 'None' : '')
                    : '${search.currentIndex + 1}/$total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                tooltip: 'Previous match',
                onPressed: total == 0 ? null : search.previous,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                tooltip: 'Next match',
                onPressed: total == 0 ? null : search.next,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close search',
                onPressed: widget.onClose,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OptionToggle extends StatelessWidget {
  const new({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        toggled: selected,
        label: tooltip,
        child: InkWell(
          onTap: () => onChanged(!selected),
          borderRadius: Radii.borderSm,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: Radii.borderSm,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontFamily: Fonts.mono,
                fontFamilyFallback: Fonts.monoFallback,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
