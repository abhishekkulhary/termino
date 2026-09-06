import 'package:flutter/material.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';

/// A surface with an edge and, when the theme has glow, a halo.
///
/// On a near-black canvas an unlit rectangle is invisible: there is no
/// shadow to separate it from the ground, because there is nothing for a
/// shadow to fall on. Depth here comes from a lit edge and a faint internal
/// gradient instead — which is also what makes the design read as light
/// rather than as paper.
class NeonPanel extends StatelessWidget {
  /// Creates a panel.
  const new({
    required this.child,
    super.key,
    this.accent,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.borderRadius = Radii.borderMd,
    this.selected = false,
    this.onTap,
  });

  /// The contents.
  final Widget child;

  /// Lights the edge in this colour. Defaults to the neutral panel border.
  final Color? accent;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Corner rounding.
  final BorderRadius borderRadius;

  /// Whether to draw the panel as the current selection: brighter edge, and
  /// the glow turned up.
  final bool selected;

  /// Makes the whole panel tappable, with press and hover feedback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neon = NeonAccents.of(context);
    final edge = accent ?? neon.panelBorder;

    final panel = AnimatedContainer(
      duration: Motion.normal,
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        gradient: neon.panelGradient,
        borderRadius: borderRadius,
        border: Border.all(
          color: selected ? edge : edge.withValues(alpha: 0.8),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected ? neon.glowStrong(edge) : neon.glow(edge, blur: 10),
      ),
      child: child,
    );

    if (onTap == null) return panel;

    return _Pressable(
      onTap: onTap!,
      borderRadius: borderRadius,
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: panel,
    );
  }
}

/// A small round light showing whether something is up, working, or down.
///
/// The pulse is not ornament: a session that is connecting and a session that
/// has stalled look identical as static dots, and motion is the cheapest way
/// to tell a user which one they are looking at.
class StatusDot extends StatefulWidget {
  /// Creates a status light.
  const new({required this.status, super.key, this.size = 8, this.label});

  /// What to show.
  final ConnectionHealth status;

  /// Diameter in logical pixels.
  final double size;

  /// Optional text beside the dot.
  final String? label;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

/// How a connection is doing, for [StatusDot].
enum ConnectionHealth {
  /// Connected and healthy.
  online,

  /// Connecting, reconnecting, or transferring.
  busy,

  /// Failed, refused, or unreachable.
  offline,

  /// Not attempted, or state unknown.
  idle,
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _syncAnimation();
  }

  /// Only the busy state animates. A steady green that breathes is noise in
  /// the corner of the eye all day.
  ///
  /// Stopped entirely under reduce-motion — which also keeps an endlessly
  /// repeating animation out of widget tests, where `pumpAndSettle` waits for
  /// the tree to go still and a pulse means it never does.
  void _syncAnimation() {
    final animate =
        widget.status == ConnectionHealth.busy &&
        !MediaQuery.disableAnimationsOf(context);

    if (animate) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color _colour(BuildContext context) {
    final neon = NeonAccents.of(context);
    return switch (widget.status) {
      ConnectionHealth.online => neon.online,
      ConnectionHealth.busy => neon.busy,
      ConnectionHealth.offline => neon.offline,
      ConnectionHealth.idle => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final neon = NeonAccents.of(context);
    final colour = _colour(context);

    final dot = AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = 0.45 + 0.55 * _pulse.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: colour.withValues(alpha: t),
            shape: BoxShape.circle,
            boxShadow: widget.status == ConnectionHealth.idle
                ? const []
                : neon.glow(colour, blur: widget.size * 1.6, spread: 0),
          ),
        );
      },
    );

    final label = widget.label;
    if (label == null) return dot;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: Spacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colour),
        ),
      ],
    );
  }
}

/// An uppercase, letter-spaced caption for a group of controls.
///
/// Small type carries a lot of this design's character, and a section label is
/// where it is most visible.
class NeonSectionLabel extends StatelessWidget {
  /// Creates a label.
  const new(this.text, {super.key, this.trailing});

  /// The caption. Rendered in upper case.
  final String text;

  /// Optional widget at the far end of the row.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.xs,
        right: Spacing.xs,
        bottom: Spacing.sm,
      ),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Divider(color: NeonAccents.of(context).grid, height: 1),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Spacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A compact action button that lights up on hover and press.
class NeonAction extends StatelessWidget {
  /// Creates an action.
  const new({
    required this.icon,
    required this.tooltip,
    super.key,
    this.onPressed,
    this.accent,
  });

  /// The glyph.
  final IconData icon;

  /// What it does, shown on hover and read aloud by screen readers.
  final String tooltip;

  /// Called when tapped. Null disables the control.
  final VoidCallback? onPressed;

  /// Overrides the accent colour.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = accent ?? theme.colorScheme.primary;
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: _Pressable(
        onTap: onPressed ?? () {},
        borderRadius: Radii.borderSm,
        splashColor: colour.withValues(alpha: 0.12),
        hoverBuilder: (context, child, {required hovered}) {
          final neon = NeonAccents.of(context);
          return AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              borderRadius: Radii.borderSm,
              color: hovered && enabled
                  ? colour.withValues(alpha: 0.10)
                  : Colors.transparent,
              border: Border.all(
                color: hovered && enabled
                    ? colour.withValues(alpha: 0.5)
                    : neon.panelBorder,
              ),
              boxShadow: hovered && enabled
                  ? neon.glow(colour, blur: 12)
                  : null,
            ),
            child: child,
          );
        },
        child: Icon(
          icon,
          size: 18,
          color: enabled ? colour : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Tap, hover and focus feedback without an [InkWell]'s Material ink, which
/// looks wrong over a glowing gradient.
class _Pressable extends StatefulWidget {
  const new({
    required this.onTap,
    required this.child,
    required this.borderRadius,
    required this.splashColor,
    this.hoverBuilder,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius borderRadius;
  final Color splashColor;
  final Widget Function(
    BuildContext context,
    Widget child, {
    required bool hovered,
  })?
  hoverBuilder;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final builder = widget.hoverBuilder;
    final content = builder == null
        ? widget.child
        : builder(context, widget.child, hovered: _hovered);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          // Barely perceptible, and the whole point: a control that moves
          // under the finger feels connected to it.
          scale: _pressed ? 0.985 : 1,
          duration: Motion.fast,
          child: content,
        ),
      ),
    );
  }
}

/// A small count worn on the corner of a navigation icon.
///
/// Shows what the app is doing while the user is looking somewhere else: two
/// transfers running, a session still connecting. Zero renders nothing at all
/// rather than a "0" — a badge exists to be noticed, and one that is always
/// there stops being noticed.
class NeonBadge extends StatelessWidget {
  /// Creates a badge showing [count].
  const new({required this.count, super.key, this.accent, this.pulse = false});

  /// How many. Zero draws nothing.
  final int count;

  /// The colour to draw it in. Defaults to the primary accent.
  final Color? accent;

  /// Whether to animate, for work still in progress.
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final neon = NeonAccents.of(context);
    final colour = accent ?? theme.colorScheme.primary;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 15),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: const BorderRadius.all(Radius.circular(7)),
        boxShadow: neon.glow(colour, blur: 8, spread: -1),
      ),
      child: Text(
        // A precise count above nine is not worth the width it costs.
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.surface,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: 0,
        ),
      ),
    );

    if (!pulse) return badge;
    return _Breathing(child: badge);
  }
}

/// A slow fade in and out, for something still in progress.
class _Breathing extends StatefulWidget {
  const new({required this.child});

  final Widget child;

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // See StatusDot: a repeating animation never lets a widget test settle,
    // and someone who asked for no motion asked for a reason.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
    child: widget.child,
  );
}
