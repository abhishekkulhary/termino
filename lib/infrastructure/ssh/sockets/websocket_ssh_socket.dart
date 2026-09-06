import 'dart:async';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// An [SSHSocket] that carries the SSH protocol over a WebSocket.
///
/// This is what makes the web build possible without a second backend, and
/// without trusting the relay. `dartssh2` runs the SSH protocol itself over
/// whatever socket it is given, so the browser only needs a different socket:
/// everything above it — key exchange, authentication, host key verification —
/// is unchanged and still happens on the user's device.
///
/// The consequence is the whole point. The relay carries ciphertext. It never
/// sees a password, a private key or a keystroke, and it cannot impersonate a
/// host, because the key it would have to forge is checked against a
/// `known_hosts` store the relay has no access to.
///
/// SSH is self-framing — every packet carries its own length — so WebSocket
/// message boundaries do not have to line up with packet boundaries, and
/// `dartssh2` already handles a banner or a packet split across reads.
class WebSocketSshSocket implements SSHSocket {
  /// Wraps an already-connected WebSocket channel.
  new(this._channel) {
    _incoming = _channel.stream
        .map(_toBytes)
        .where((chunk) => chunk.isNotEmpty)
        .listen(
          _received.add,
          onError: _received.addError,
          onDone: () {
            if (!_received.isClosed) unawaited(_received.close());
            if (!_done.isCompleted) _done.complete();
          },
        );

    // Outgoing bytes are forwarded rather than piped so that a caller closing
    // its sink does not close the channel out from under a read in flight.
    //
    // The guard is not belt and braces: a write can be queued before a close
    // and delivered after it, and adding to a closed WebSocket sink throws
    // "Cannot add event after closing" out of a stream callback, where nothing
    // is waiting to catch it.
    _outgoing.stream.listen((chunk) {
      if (_closed) return;
      _channel.sink.add(Uint8List.fromList(chunk));
    }, onDone: () => unawaited(close()));
  }

  /// Connects to [url] and wraps the result.
  ///
  /// The destination is passed in the query string because a browser cannot
  /// set headers on a WebSocket handshake — the one place where the web is
  /// genuinely more limited than the VM, rather than merely different.
  static Future<WebSocketSshSocket> connect(
    Uri url, {
    required String host,
    required int port,
    Duration? timeout,
  }) async {
    final target = url.replace(
      queryParameters: {...url.queryParameters, 'host': host, 'port': '$port'},
    );

    final channel = WebSocketChannel.connect(target);
    await channel.ready.timeout(
      timeout ?? const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'The relay at ${url.host} did not respond.',
        timeout,
      ),
    );
    return WebSocketSshSocket(channel);
  }

  final WebSocketChannel _channel;
  final _received = StreamController<Uint8List>();
  final _outgoing = StreamController<List<int>>();
  final _done = Completer<void>();
  late final StreamSubscription<Uint8List> _incoming;
  var _closed = false;

  @override
  Stream<Uint8List> get stream => _received.stream;

  @override
  StreamSink<List<int>> get sink => _outgoing.sink;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> close() async {
    if (!_closed) {
      _closed = true;
      await _channel.sink.close();
      await _incoming.cancel();
      if (!_received.isClosed) await _received.close();
      if (!_done.isCompleted) _done.complete();
    }
    await _done.future;
  }

  /// A WebSocket has no user-visible buffer to flush: the channel sends each
  /// message as it is added.
  @override
  Future<void> flush() async {}

  @override
  void destroy() {
    if (_closed) return;
    _closed = true;
    unawaited(_incoming.cancel());
    unawaited(_channel.sink.close());
    if (!_received.isClosed) unawaited(_received.close());
    if (!_done.isCompleted) _done.complete();
  }

  /// A WebSocket message is either binary or text. Only binary is expected —
  /// the relay sends nothing else — but a text frame is decoded rather than
  /// dropped, because silently discarding bytes would show up as a hung
  /// handshake with no explanation.
  static Uint8List _toBytes(Object? message) => switch (message) {
    final Uint8List bytes => bytes,
    final List<int> bytes => Uint8List.fromList(bytes),
    final String text => Uint8List.fromList(text.codeUnits),
    _ => Uint8List(0),
  };
}
