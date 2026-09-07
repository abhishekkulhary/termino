import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:zmodem/zmodem.dart';

/// A file the far end is offering to send.
class IncomingFile {
  /// Creates a pending offer.
  const new({required this.name, required this.size});

  /// What the far end calls it. Treated as a name, never as a path — see
  /// [safeName].
  final String name;

  /// How big it says it is, in bytes. Zero when it did not say.
  final int size;

  /// The last path segment, with nothing that could escape a directory.
  ///
  /// The name comes from the far end, which can say anything: `../../.bashrc`
  /// is a perfectly legal ZModem filename and would otherwise be written
  /// exactly where it says.
  String get safeName {
    final base = name.split(RegExp(r'[/\\]')).last;
    final cleaned = base.replaceAll(RegExp(r'^\.+'), '').trim();
    return cleaned.isEmpty ? 'received' : cleaned;
  }
}

/// A file this device is offering to a remote `rz`.
class OutgoingFile {
  /// Creates an offer.
  const new({required this.info, required this.open});

  /// What the far end is told about it.
  final ZModemFileInfo info;

  /// Opens the bytes, from an offset the far end may ask to resume at.
  final Stream<Uint8List> Function(int offset) open;
}

/// Multiplexes ZModem over the terminal's byte stream.
///
/// `rz` and `sz` embed a file transfer inside the same stream the shell prints
/// to, announced by a short header. Something has to watch for that header,
/// divert the bytes while a transfer runs, and hand everything else to the
/// emulator.
///
/// Written here rather than using `xterm`'s `ZModemMux`, for one measured
/// reason: that multiplexer's header scan is `i < length - other.length`, so a
/// header is only found when at least one byte follows it in the same chunk.
/// `sz` announces itself and then waits for a reply, so its header is
/// routinely the last thing in a chunk — and a chunk that *is* the header is
/// never matched at all. Both cases were checked against the real package
/// before this was written, and both are covered by tests here.
///
/// The session's pipeline keeps its shape around this: bytes are still batched
/// and metered upstream, so the acknowledgement that gives this app its
/// backpressure still applies and a flood still pauses the socket.
class ZModemTransfers {
  /// Creates a multiplexer writing to the backend through [write].
  new({
    required this.write,
    required this.onIncoming,
    required this.onOutgoingRequested,
  });

  /// Writes bytes to the backend — keystrokes, and the protocol's own replies.
  final void Function(Uint8List bytes) write;

  /// Asked when the far end offers a file. Returning null skips it.
  ///
  /// A prompt rather than an automatic save: `sz` is the far end pushing a
  /// file onto this machine, and a host that has been tampered with must not
  /// be able to write to someone's disk because they had a shell open.
  final Future<StreamSink<List<int>>?> Function(IncomingFile file) onIncoming;

  /// Asked when the far end runs `rz`. An empty list ends it politely.
  final Future<List<OutgoingFile>> Function() onOutgoingRequested;

  /// Where decoded terminal text goes.
  void Function(String text)? onTerminalText;

  /// Called as a transfer progresses, for the UI.
  void Function(String name, int bytes)? onProgress;

  /// Called when a transfer session ends, however it ends.
  ///
  /// Without this the UI has no way to know: the protocol's own end is a frame
  /// on the wire, not something the terminal ever prints, so a progress
  /// indicator would sit at whatever the last byte count was, forever.
  void Function()? onFinished;

  /// A *chunked* decoder, deliberately.
  ///
  /// `Utf8Decoder.convert` is stateless: a multi-byte character split across
  /// two chunks decodes as two replacement glyphs, which is exactly what a
  /// terminal shows when this is got wrong. The chunked conversion carries the
  /// partial sequence across the boundary, which is what the session's own
  /// pipeline did before ZModem sat in the middle of it.
  late final ByteConversionSink _decoder = const Utf8Decoder(
    allowMalformed: true,
  ).startChunkedConversion(_TerminalTextSink(this));

  ZModemCore? _session;
  StreamSink<List<int>>? _receiving;
  String _receivingName = '';
  var _received = 0;
  Iterator<OutgoingFile>? _sending;

  /// What a sender and a receiver announce themselves with.
  static final senderInit = Uint8List.fromList('**\x18B00'.codeUnits);

  /// The receiver's equivalent, sent by `rz`.
  static final receiverInit = Uint8List.fromList('**\x18B01'.codeUnits);

  /// Whether a transfer is in progress.
  bool get isActive => _session != null;

  /// Feeds bytes that arrived from the backend.
  void addFromBackend(Uint8List chunk) {
    if (_session != null) {
      _pump(chunk);
      return;
    }

    final start = indexOfHeader(chunk);
    if (start == null) {
      _decoder.add(chunk);
      return;
    }

    if (start > 0) {
      _decoder.add(Uint8List.sublistView(chunk, 0, start));
    }
    // Plain bytes the protocol passes through go the same way, so a character
    // straddling the boundary between shell output and a transfer still
    // decodes.
    _session = ZModemCore(onPlainText: (byte) => _decoder.add([byte]));
    _pump(Uint8List.sublistView(chunk, start));
  }

  /// Sends [text] as if typed.
  ///
  /// Dropped while a transfer runs: a stray keystroke written into the middle
  /// of a ZModem frame corrupts it, and the shell is not listening anyway.
  void sendText(String text) {
    if (_session != null) return;
    write(Uint8List.fromList(utf8.encode(text)));
  }

  /// The protocol's abort sequence.
  ///
  /// Eight CAN bytes, then backspaces to wipe them from the far end's line
  /// buffer — exactly what pressing Ctrl+C at a stalled `sz` sends, and what
  /// every ZModem implementation looks for.
  static final cancelSequence = Uint8List.fromList([
    ...List.filled(8, 0x18),
    ...List.filled(10, 0x08),
  ]);

  /// Abandons a transfer in flight and tells the far end it is over.
  ///
  /// Without this a transfer that stalls — the far end killed, the link
  /// dropped mid-file — leaves the session diverting every keystroke into a
  /// protocol nobody is listening to, with no way back to the shell short of
  /// closing the tab.
  Future<void> abort() async {
    if (_session == null) return;
    write(cancelSequence);

    await _receiving?.close();
    _receiving = null;
    _session = null;
    _sending = null;
  }

  /// Releases everything and abandons any transfer in flight.
  Future<void> dispose() async {
    await _receiving?.close();
    _receiving = null;
    _session = null;
    _sending = null;
  }

  /// Where a ZModem header starts in [chunk], or null.
  ///
  /// Inclusive of the end of the buffer, which is the entire point.
  static int? indexOfHeader(Uint8List chunk) {
    final sender = _indexOf(chunk, senderInit);
    final receiver = _indexOf(chunk, receiverInit);
    if (sender == null) return receiver;
    if (receiver == null) return sender;
    return sender < receiver ? sender : receiver;
  }

  static int? _indexOf(Uint8List haystack, Uint8List needle) {
    if (needle.isEmpty || haystack.length < needle.length) return null;
    for (var i = 0; i <= haystack.length - needle.length; i++) {
      var matched = true;
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          matched = false;
          break;
        }
      }
      if (matched) return i;
    }
    return null;
  }

  void _pump(Uint8List chunk) {
    final session = _session;
    if (session == null) return;

    for (final event in session.receive(chunk)) {
      unawaited(_handle(event));
    }
    _flush();
  }

  Future<void> _handle(ZModemEvent event) async {
    if (_session == null) return;

    switch (event) {
      case ZFileOfferedEvent():
        await _offered(event);
      case ZFileDataEvent():
        _receiving?.add(event.data);
        _received += event.data.length;
        onProgress?.call(_receivingName, _received);
      case ZFileEndEvent():
        await _receiving?.close();
        _receiving = null;
      case ZSessionFinishedEvent():
        await _receiving?.close();
        _receiving = null;
        _session = null;
        _sending = null;
        onFinished?.call();
      case ZReadyToSendEvent():
        _sending ??= (await onOutgoingRequested()).iterator;
        _nextOutgoing();
      case ZFileAcceptedEvent():
        await _sendCurrent(event.offset);
      case ZFileSkippedEvent():
        _nextOutgoing();
    }
    _flush();
  }

  Future<void> _offered(ZFileOfferedEvent event) async {
    final file = IncomingFile(
      name: event.fileInfo.pathname,
      size: event.fileInfo.length ?? 0,
    );

    final sink = await onIncoming(file);
    if (sink == null) {
      _session?.skipFile();
      _flush();
      return;
    }

    _receiving = sink;
    _receivingName = file.safeName;
    _received = 0;
    _session?.acceptFile();
    _flush();
  }

  void _nextOutgoing() {
    final sending = _sending;
    if (sending == null || !sending.moveNext()) {
      _session?.finishSession();
      _flush();
      return;
    }
    _session?.offerFile(sending.current.info);
    _flush();
  }

  Future<void> _sendCurrent(int offset) async {
    final session = _session;
    final current = _sending?.current;
    if (session == null || current == null) return;

    var sent = 0;
    await for (final chunk in current.open(offset)) {
      session.sendFileData(chunk);
      sent += chunk.length;
      _flush();
      onProgress?.call(current.info.pathname, sent);
    }
    session.finishSending(offset + sent);
    _flush();
  }

  void _flush() {
    final session = _session;
    if (session == null || !session.hasDataToSend) return;
    write(correctHexTerminators(session.dataToSend()));
  }

  /// Puts the high bit back on the line feed that ends each hex header.
  ///
  /// ZMODEM hex headers are terminated by CR and LF, and the reference
  /// implementation (lrzsz, `zshhdr` in `zm.c`) sends them as `0x0d 0x8a` —
  /// a bare CR followed by an LF with the high bit set. The `zmodem` package
  /// writes `0x0d 0x0a`, which its own parser then refuses; feeding the
  /// package's sender output into the package's own receiver fails with
  /// `Expected 0x8a, got 0xa`, which was checked directly before this was
  /// written.
  ///
  /// Corrected here rather than left to the far end's tolerance. lrzsz does
  /// mask the high bit off when reading, so the uncorrected form may well be
  /// accepted — but "probably accepted by the implementation we could not test
  /// against" is not a thing to ship. Emitting exactly what the reference
  /// implementation emits is.
  ///
  /// A hex header is fixed-length: `**` ZDLE `B`, fourteen hex digits, then
  /// the terminator — so the bytes to correct are at a known offset and no
  /// scanning of file data is involved.
  static Uint8List correctHexTerminators(Uint8List data) {
    Uint8List? corrected;

    for (var i = 0; i + 19 < data.length; i++) {
      if (data[i] != 0x2a || data[i + 1] != 0x2a) continue;
      if (data[i + 2] != 0x18 || data[i + 3] != 0x42) continue;
      if (data[i + 18] != 0x0d || data[i + 19] != 0x0a) continue;

      corrected ??= Uint8List.fromList(data);
      corrected[i + 19] = 0x8a;
    }

    return corrected ?? data;
  }
}

/// Hands decoded text to the multiplexer's listener.
///
/// A `Sink<String>` rather than a callback because that is what a chunked
/// UTF-8 conversion writes into.
class _TerminalTextSink implements Sink<String> {
  const new(this._transfers);

  final ZModemTransfers _transfers;

  @override
  void add(String data) => _transfers.onTerminalText?.call(data);

  @override
  void close() {}
}
