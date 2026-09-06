import 'package:flutter/material.dart';
import 'package:termino/features/terminal/application/key_bar_actions.dart';
import 'package:termino/features/terminal/application/sticky_modifiers.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:xterm/xterm.dart';

/// The key row shown above a soft keyboard on touch devices.
///
/// A phone keyboard has no Esc, no Tab, no Ctrl and no arrows, which makes a
/// shell close to unusable without this. Modifiers are sticky — tap Ctrl, then
/// C — and their state is visible, because a modifier you cannot see the state
/// of is worse than none at all.
class KeyAccessoryBar extends StatefulWidget {
  /// Creates a bar driving [terminal].
  const new({
    required this.terminal,
    required this.modifiers,
    super.key,
    this.extraActions = const [],
  });

  /// The terminal keys are sent to.
  final Terminal terminal;

  /// The sticky modifier state, shared with hardware keyboard handling.
  final StickyModifiers modifiers;

  /// A customisable extra row, appended to the primary one.
  final List<KeyBarAction> extraActions;

  @override
  State<KeyAccessoryBar> createState() => _KeyAccessoryBarState();
}

class _KeyAccessoryBarState extends State<KeyAccessoryBar> {
  var _expanded = false;

  void _handle(KeyBarAction action) {
    switch (action) {
      case ModifierAction(:final modifier):
        widget.modifiers.tap(modifier);
      case NamedKeyAction(:final key):
        widget.terminal.keyInput(
          key,
          ctrl: widget.modifiers.isActive(StickyModifier.ctrl),
          alt: widget.modifiers.isActive(StickyModifier.alt),
          shift: widget.modifiers.isActive(StickyModifier.shift),
        );
        widget.modifiers.consume();
      case TextAction(:final text):
        // A modifier plus a printable character is a control sequence, which
        // the terminal builds from a key rather than from text — `Ctrl+C` is
        // not the character 'c' with a flag on it.
        final key = _keyForCharacter(text);
        if (widget.modifiers.anyActive && key != null) {
          widget.terminal.keyInput(
            key,
            ctrl: widget.modifiers.isActive(StickyModifier.ctrl),
            alt: widget.modifiers.isActive(StickyModifier.alt),
            shift: widget.modifiers.isActive(StickyModifier.shift),
          );
        } else {
          widget.terminal.textInput(text);
        }
        widget.modifiers.consume();
    }
  }

  /// Maps a single printable character to the key that produces it, so that a
  /// sticky modifier can be applied to it.
  static TerminalKey? _keyForCharacter(String text) {
    if (text.length != 1) return null;
    final lower = text.toLowerCase();
    const letters = 'abcdefghijklmnopqrstuvwxyz';
    final index = letters.indexOf(lower);
    if (index < 0) return null;
    return TerminalKey.values.firstWhere(
      (key) => key.name == 'key${lower.toUpperCase()}',
      orElse: () => TerminalKey.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: widget.modifiers,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_expanded)
                _Row(
                  actions: const [
                    ...KeyBarLayout.functionKeys,
                    ...KeyBarLayout.navigation,
                  ],
                  onTap: _handle,
                  modifiers: widget.modifiers,
                ),
              Row(
                children: [
                  Expanded(
                    child: _Row(
                      actions: [
                        const ModifierAction(
                          modifier: StickyModifier.ctrl,
                          label: 'Ctrl',
                          tooltip: 'Control — tap once to arm, twice to lock',
                        ),
                        const ModifierAction(
                          modifier: StickyModifier.alt,
                          label: 'Alt',
                          tooltip: 'Alt — tap once to arm, twice to lock',
                        ),
                        ...KeyBarLayout.primary,
                        ...widget.extraActions,
                      ],
                      onTap: _handle,
                      modifiers: widget.modifiers,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                    ),
                    tooltip: _expanded ? 'Fewer keys' : 'More keys',
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const new({
    required this.actions,
    required this.onTap,
    required this.modifiers,
  });

  final List<KeyBarAction> actions;
  final ValueChanged<KeyBarAction> onTap;
  final StickyModifiers modifiers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.xs),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _KeyButton(
            action: action,
            state: action is ModifierAction
                ? modifiers.stateOf(action.modifier)
                : ModifierState.off,
            onTap: () => onTap(action),
          );
        },
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const new({required this.action, required this.state, required this.onTap});

  final KeyBarAction action;
  final ModifierState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final neon = NeonAccents.of(context);
    final accent = theme.colorScheme.primary;

    // A keycap, not a chip. These are the app's only real buttons on a phone —
    // the brief put touch input among the three things that decide whether
    // this is good software — and a modifier's state has to be readable at a
    // glance while typing, not squinted at.
    final (background, foreground, edge) = switch (state) {
      ModifierState.off => (
        theme.colorScheme.surfaceContainerHigh,
        theme.colorScheme.onSurface,
        neon.panelBorder,
      ),
      ModifierState.armed => (
        accent.withValues(alpha: 0.16),
        accent,
        accent.withValues(alpha: 0.55),
      ),
      ModifierState.locked => (accent, theme.colorScheme.onPrimary, accent),
    };

    return Semantics(
      button: true,
      label: action.tooltip ?? action.label,
      // Announces "armed"/"locked" so the state is not conveyed by colour
      // alone, which would leave it invisible to a screen reader.
      value: switch (state) {
        ModifierState.off => null,
        ModifierState.armed => 'armed',
        ModifierState.locked => 'locked',
      },
      child: Tooltip(
        message: action.tooltip ?? action.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: Radii.borderSm,
          child: InkWell(
            onTap: onTap,
            borderRadius: Radii.borderSm,
            child: AnimatedContainer(
              duration: Motion.fast,
              // 44 is the smallest target Apple and Google both consider
              // reliable for a fingertip, and these are pressed mid-sentence.
              constraints: const BoxConstraints(minWidth: 44, minHeight: 38),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              decoration: BoxDecoration(
                color: background,
                borderRadius: Radii.borderSm,
                border: Border.all(color: edge),
                boxShadow: state == ModifierState.off
                    ? null
                    : neon.glow(accent, blur: 10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontFamily: Fonts.mono,
                      fontFamilyFallback: Fonts.monoFallback,
                    ),
                  ),
                  if (state == ModifierState.locked) ...[
                    const SizedBox(width: Spacing.xxs),
                    Icon(Icons.lock_rounded, size: 11, color: foreground),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
