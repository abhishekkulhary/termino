import 'dart:async';

import 'package:flutter/material.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/application/throughput_meter.dart';
import 'package:termino/infrastructure/ssh/ssh_backend.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';

/// Maps a backend's lifecycle onto the light the user reads.
ConnectionHealth healthOf(BackendConnectionState state) => switch (state) {
  BackendConnectionState.connected => ConnectionHealth.online,
  BackendConnectionState.connecting => ConnectionHealth.busy,
  BackendConnectionState.error => ConnectionHealth.offline,
  BackendConnectionState.closed => ConnectionHealth.offline,
  BackendConnectionState.idle => ConnectionHealth.idle,
};

/// The one-line readout under a terminal: state, throughput, latency, size.
///
/// A terminal that is working and a terminal that has hung look identical, and
/// that is exactly when a user starts to worry — a build that went quiet, a
/// `tail -f` with nothing to say, a session the network dropped half an hour
/// ago. This answers all three without them having to type anything and find
/// out the hard way.
class SessionStatusBar extends StatefulWidget {
  /// Creates the status bar for [session].
  const new({required this.session, super.key});

  /// The session being reported on.
  final TerminalSession session;

  @override
  State<SessionStatusBar> createState() => _SessionStatusBarState();
}

class _SessionStatusBarState extends State<SessionStatusBar> {
  Timer? _ticker;
  Timer? _latencyTimer;
  Duration? _latency;

  /// Fast enough to read as live, slow enough that it is not a repaint loop.
  static const _tick = Duration(milliseconds: 500);

  /// Latency costs a round trip to the server, so it is sampled far less
  /// often than the rate, which costs nothing.
  static const _latencyInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_tick, (_) {
      if (mounted) setState(() {});
    });
    _latencyTimer = Timer.periodic(_latencyInterval, (_) => _sampleLatency());
    unawaited(_sampleLatency());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _latencyTimer?.cancel();
    super.dispose();
  }

  Future<void> _sampleLatency() async {
    final backend = widget.session.backend;
    if (backend is! SshBackend) return;
    final measured = await backend.measureLatency();
    if (mounted) setState(() => _latency = measured);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neon = NeonAccents.of(context);
    final session = widget.session;

    return ValueListenableBuilder<BackendConnectionState>(
      valueListenable: session.connectionState,
      builder: (context, state, _) {
        final health = healthOf(state);
        final rate = session.throughput.rate();

        return Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: neon.grid)),
          ),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.labelSmall ?? const TextStyle(),
            child: Row(
              children: [
                StatusDot(status: health, size: 7, label: _stateLabel(state)),
                const _Gap(),
                // The rate appears only while something is arriving. A
                // permanent "0 B/s" is a worse readout than none: it draws the
                // eye to a number that is almost always zero and says nothing.
                AnimatedOpacity(
                  duration: Motion.normal,
                  opacity: rate > 0 ? 1 : 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.south_rounded,
                        size: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(formatRate(rate)),
                    ],
                  ),
                ),
                const Spacer(),
                if (_latency case final latency?) ...[
                  Text(_latencyLabel(latency)),
                  const _Gap(),
                ],
                Text(formatBytes(session.throughput.totalBytes)),
                const _Gap(),
                Text(_size(session)),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _size(TerminalSession session) =>
      '${session.terminal.viewWidth}×${session.terminal.viewHeight}';

  static String _stateLabel(BackendConnectionState state) => switch (state) {
    BackendConnectionState.connected => 'connected',
    BackendConnectionState.connecting => 'connecting',
    BackendConnectionState.error => 'failed',
    BackendConnectionState.closed => 'closed',
    BackendConnectionState.idle => 'idle',
  };

  /// Sub-millisecond round trips happen on a loopback connection, and "0 ms"
  /// reads as broken rather than as fast.
  static String _latencyLabel(Duration latency) {
    final micros = latency.inMicroseconds;
    if (micros < 1000) return '<1 ms';
    return '${latency.inMilliseconds} ms';
  }
}

class _Gap extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const SizedBox(width: Spacing.lg);
}
