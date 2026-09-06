import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/shared/design/tokens.dart';

/// Identifies the flash overlay, so a test can tell it from the many
/// [ColoredBox]es Material builds on its own.
const bellFlashKey = Key('bell-flash');

/// Answers the terminal bell, according to the setting.
///
/// The bell was counted and then ignored: a program could ring it all day and
/// nothing happened, whichever of the three behaviours was chosen. Wrapping the
/// terminal is the natural place for the visual one, since a flash has to
/// happen over the grid rather than beside it.
///
/// Deliberately no audible option. A terminal that can make a noise is a
/// terminal that makes a noise in a meeting, and the platforms disagree about
/// what a system beep even is; a flash and a buzz cover what people actually
/// want from `\a`.
class BellEffect extends ConsumerStatefulWidget {
  /// Wraps [child], flashing it when [session] rings.
  const new({required this.session, required this.child, super.key});

  /// The session whose bell to answer.
  final TerminalSession session;

  /// The terminal to flash.
  final Widget child;

  @override
  ConsumerState<BellEffect> createState() => _BellEffectState();
}

class _BellEffectState extends ConsumerState<BellEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash =
      AnimationController(vsync: this, duration: Motion.slow)
        // Back to dismissed when the flash finishes, so the overlay leaves the
        // tree entirely rather than lingering as a fully transparent box over
        // the terminal for the rest of the session.
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _flash.reset();
        });

  var _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.session.bellCount.value;
    widget.session.bellCount.addListener(_onBell);
  }

  @override
  void didUpdateWidget(BellEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.bellCount.removeListener(_onBell);
      _lastCount = widget.session.bellCount.value;
      widget.session.bellCount.addListener(_onBell);
    }
  }

  @override
  void dispose() {
    widget.session.bellCount.removeListener(_onBell);
    _flash.dispose();
    super.dispose();
  }

  void _onBell() {
    final count = widget.session.bellCount.value;
    // A session can ring several times before a frame is drawn — `find` on a
    // large tree does it — and one flash for a burst is what a user wants.
    if (count <= _lastCount) return;
    _lastCount = count;

    switch (ref.read(currentSettingsProvider).bell) {
      case BellBehaviour.none:
        return;
      case BellBehaviour.visual:
        _flash
          ..reset()
          ..forward();
      case BellBehaviour.haptic:
        unawaited(HapticFeedback.mediumImpact());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Ignores pointers so a flash cannot swallow a click, and is skipped
        // entirely when idle so it costs nothing between rings.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _flash,
              builder: (context, _) {
                if (_flash.isDismissed) return const SizedBox.shrink();
                // Bright on, fading out: a flash that fades in is a glow.
                final strength = 1 - Curves.easeOut.transform(_flash.value);
                return ColoredBox(
                  key: bellFlashKey,
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.22 * strength),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
