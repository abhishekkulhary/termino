import 'dart:async';
import 'dart:typed_data';

/// Coalesces a backend's output into at most one terminal write per [window].
///
/// This is the single component that decides whether Termino stays smooth under
/// load. A process running `yes`, or `cat` on a large file, emits thousands of
/// small chunks a second. Writing each one straight into the terminal means
/// thousands of parser invocations and repaints per second, and the UI stops
/// keeping up long before the pipe does.
///
/// Two rules, whichever fires first:
///
/// * **Time** — bytes are held for up to [window] (8 ms by default, comfortably
///   inside one 60 Hz frame) and then emitted as a single chunk.
/// * **Size** — if [maxBufferedBytes] accumulates before the window expires,
///   they are emitted immediately, so a genuine burst is not delayed and memory
///   stays bounded.
///
/// Backpressure is preserved end to end: pausing the output pauses the source
/// subscription, so a flood slows the socket down rather than growing an
/// unbounded queue in memory. This is why a backend's output stream is
/// single-subscription — a broadcast stream cannot do this.
///
/// Ordering is never altered and no bytes are dropped; anything buffered when
/// the source completes is flushed before the output closes.
///
/// ## Buffer ownership
///
/// For speed this does not copy incoming chunks, so a source must not mutate a
/// buffer after emitting it. Both `dart:io` sockets and `dartssh2` allocate a
/// fresh buffer per event, as does `flutter_pty`.
class TerminalOutputBatcher
    extends StreamTransformerBase<Uint8List, Uint8List> {
  /// Creates a batcher with the given [window] and [maxBufferedBytes].
  const new({
    this.window = const Duration(milliseconds: 8),
    this.maxBufferedBytes = 64 * 1024,
  }) : assert(maxBufferedBytes > 0, 'maxBufferedBytes must be positive');

  /// How long bytes may be held before being emitted.
  final Duration window;

  /// The buffered size that forces an immediate emission.
  final int maxBufferedBytes;

  @override
  Stream<Uint8List> bind(Stream<Uint8List> stream) {
    // `copy: false` lets a single-chunk flush hand the original buffer straight
    // through with no memcpy, which is the common case under load.
    final buffer = BytesBuilder(copy: false);
    late final StreamController<Uint8List> controller;
    StreamSubscription<Uint8List>? subscription;
    Timer? timer;

    void cancelTimer() {
      timer?.cancel();
      timer = null;
    }

    void flush() {
      cancelTimer();
      if (buffer.isEmpty || controller.isClosed) return;
      controller.add(buffer.takeBytes());
    }

    void onData(Uint8List data) {
      if (data.isEmpty) return;
      buffer.add(data);

      if (buffer.length >= maxBufferedBytes) {
        flush();
        return;
      }
      // Started by the *first* chunk of a batch and not extended by later ones,
      // so a continuous stream still emits every `window` rather than starving.
      // While paused, the clock stops; onResume restarts it.
      if (timer == null && !controller.isPaused) {
        timer = Timer(window, flush);
      }
    }

    controller = StreamController<Uint8List>(
      onListen: () {
        subscription = stream.listen(
          onData,
          onError: controller.addError,
          onDone: () {
            flush();
            // Clear the handle before closing. Closing runs `onCancel`, and
            // cancelling a subscription from inside its own `onDone` is a
            // re-entrant call that can deadlock; the source is finished
            // anyway, so there is nothing left to cancel.
            subscription = null;
            unawaited(controller.close());
          },
        );
      },
      onPause: () {
        cancelTimer();
        subscription?.pause();
      },
      onResume: () {
        subscription?.resume();
        if (buffer.isNotEmpty && timer == null) {
          timer = Timer(window, flush);
        }
      },
      onCancel: () {
        cancelTimer();
        final pending = subscription?.cancel();
        subscription = null;
        return pending;
      },
    );

    return controller.stream;
  }
}
