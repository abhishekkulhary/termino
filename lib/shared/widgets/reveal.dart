import 'package:flutter/material.dart';
import 'package:termino/shared/design/tokens.dart';

/// Fades and lifts its child into place once, when it first appears.
///
/// Used for lists and empty states, where content arriving all at once reads
/// as a flash and content arriving in sequence reads as the app doing
/// something. The stagger is small on purpose: this is a tool people open
/// dozens of times a day, and an entrance they have to wait for is charming
/// exactly twice.
///
/// Honours the platform's reduce-motion setting, where it renders the finished
/// state immediately rather than a faster version of the animation. Someone who
/// has asked for no motion has usually asked because motion makes them unwell.
class Reveal extends StatefulWidget {
  /// Creates a reveal.
  const new({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.offset = 8,
  });

  /// Creates a reveal staggered by its position in a list.
  ///
  /// The delay is capped: on a list of forty hosts, the last one must not wait
  /// two seconds to exist.
  factory staggered({
    required int index,
    required Widget child,
    Key? key,
    Duration step = const Duration(milliseconds: 28),
    int maxSteps = 8,
  }) => Reveal(
    key: key,
    delay: step * (index > maxSteps ? maxSteps : index),
    child: child,
  );

  /// What to reveal.
  final Widget child;

  /// How long to wait before starting.
  final Duration delay;

  /// How far to lift, in logical pixels.
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      unawaitedForward();
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) unawaitedForward();
    });
  }

  void unawaitedForward() {
    // The future is deliberately dropped: nothing waits for an entrance to
    // finish, and the controller is disposed with the widget either way.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// A page transition that fades through rather than sliding in from the edge.
///
/// The default platform transition slides a whole screen sideways, which on a
/// near-black interface looks like a panel being dragged over another panel.
/// Fading through the background reads as one surface becoming another.
class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  /// Creates a route showing [builder]'s widget.
  new({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: Motion.slow,
        reverseTransitionDuration: Motion.normal,
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, secondary, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;

          final entering = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: entering,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(entering),
              child: child,
            ),
          );
        },
      );
}
