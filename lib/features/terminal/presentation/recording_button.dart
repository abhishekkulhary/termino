import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:termino/domain/terminal/session_recorder.dart';
import 'package:termino/features/terminal/application/recording_export.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';

/// Starts and stops recording the session, and hands over the result.
///
/// The recorder and both export formats were built and tested and then left
/// with nothing to reach them. This is that missing half.
///
/// Only output is recorded — never keystrokes. A recording is a file that gets
/// shared, and keystrokes routinely contain a password typed at a `sudo`
/// prompt. The sheet says so, because someone about to send a terminal
/// recording to a colleague should know exactly what is in it.
class RecordingButton extends StatefulWidget {
  /// Creates the control for [session].
  const new({required this.session, super.key});

  /// The session being recorded.
  final TerminalSession session;

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (widget.session.isRecording) {
      final recorder = widget.session.stopRecording();
      _ticker?.cancel();
      _ticker = null;
      setState(() {});

      if (recorder == null || recorder.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nothing was recorded.')));
        return;
      }
      unawaited(_offerExport(recorder));
      return;
    }

    widget.session.startRecording();
    // Redraws the elapsed time. Nothing else changes on a tick.
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
    setState(() {});
  }

  Future<void> _offerExport(SessionRecorder recorder) async {
    final chosen = await showModalBottomSheet<RecordingFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NeonSectionLabel('Save the recording'),
                  Text(
                    'Output only — what you typed was never recorded.',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            for (final format in RecordingFormat.values)
              ListTile(
                leading: Icon(
                  format == RecordingFormat.text
                      ? Icons.notes_rounded
                      : Icons.play_circle_outline_rounded,
                ),
                title: Text(format.label),
                subtitle: Text(format.detail),
                onTap: () => Navigator.of(context).pop(format),
              ),
            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );

    if (chosen == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await writeRecording(
        recorder,
        format: chosen,
        sessionTitle: widget.session.title.value,
      );
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('The recording could not be saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final neon = NeonAccents.of(context);
    final recording = widget.session.isRecording;
    final elapsed = widget.session.recorder?.duration ?? Duration.zero;

    if (!recording) {
      return NeonAction(
        icon: Icons.fiber_manual_record_outlined,
        tooltip: 'Record this session',
        onPressed: _toggle,
      );
    }

    return Tooltip(
      message: 'Stop recording',
      child: InkWell(
        onTap: _toggle,
        borderRadius: Radii.borderSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Not a StatusDot: that enum is about a connection, and
              // borrowing "offline" to mean "recording" would read as a
              // mistake to the next person in this file.
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: neon.offline,
                  shape: BoxShape.circle,
                  boxShadow: neon.glow(neon.offline, blur: 10, spread: 0),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                _clock(elapsed),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: neon.offline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _clock(Duration elapsed) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
