import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:termino/features/terminal/application/zmodem_transfers.dart';
import 'package:zmodem/zmodem.dart';

part 'transfer_controller.g.dart';

/// Something the transfer layer needs a person to answer before it can go on.
///
/// The protocol is waiting on the wire while one of these is unanswered, which
/// is why they are modelled as state rather than as a dialog somebody might
/// forget to show: whatever is on screen, exactly one question is outstanding
/// and it is visible here.
@immutable
sealed class TransferRequest {
  const new({required this.sessionId});

  /// Which session asked. A prompt from a background tab must not appear over
  /// the one in front as if it came from there.
  final String sessionId;
}

/// The far end is offering to send a file — it ran `sz`.
class IncomingRequest extends TransferRequest {
  /// Creates the offer.
  const new({required super.sessionId, required this.file});

  /// What it says it is sending.
  final IncomingFile file;
}

/// The far end is waiting to receive files — it ran `rz`.
class OutgoingRequest extends TransferRequest {
  /// Creates the request.
  const new({required super.sessionId});
}

/// A transfer in flight.
@immutable
class TransferProgress {
  /// Creates a progress report.
  const new({
    required this.name,
    required this.bytes,
    required this.total,
    required this.incoming,
    this.path,
  });

  /// The file's name, as it will appear on disk.
  final String name;

  /// How many bytes have moved.
  final int bytes;

  /// How many are expected, or zero when the far end did not say.
  final int total;

  /// True when the file is arriving, false when it is being sent.
  final bool incoming;

  /// Where a received file is being written, once that is known.
  final String? path;

  /// How far along, or null when the total is unknown — which is a real case
  /// and must show as an indeterminate bar rather than as zero.
  double? get fraction => total <= 0 ? null : (bytes / total).clamp(0.0, 1.0);

  /// A copy with [bytes] advanced.
  TransferProgress at(int value) => TransferProgress(
    name: name,
    bytes: value,
    total: total,
    incoming: incoming,
    path: path,
  );
}

/// What the transfer UI is showing.
@immutable
class TransferState {
  /// Creates a snapshot.
  const new({
    this.sessionId,
    this.request,
    this.progress,
    this.completed,
    this.error,
  });

  /// Which session this concerns.
  ///
  /// Carried on every state and not only on the question, so that a progress
  /// bar or a "saved to" line appears on the terminal the transfer belongs to
  /// rather than on whichever one happens to be in front.
  final String? sessionId;

  /// The unanswered question, if any.
  final TransferRequest? request;

  /// The transfer in flight, if any.
  final TransferProgress? progress;

  /// The last transfer that finished, kept so the UI can say where the file
  /// went. A received file nobody can find has not really been received.
  final TransferProgress? completed;

  /// Why the last transfer could not start.
  final String? error;

  /// Whether anything at all needs showing.
  bool get isIdle =>
      request == null && progress == null && completed == null && error == null;
}

/// Owns the ZModem prompts and progress for every session.
///
/// Deliberately a controller rather than dialogs raised from the multiplexer:
/// the multiplexer runs on bytes arriving from a socket, and code down there
/// has no business reaching for a `BuildContext`. It asks a question, this
/// holds the question, and the widget layer answers it.
///
/// Kept alive because a transfer outlives any one screen — the answer is
/// awaited by the protocol, and an auto-disposed notifier torn down while that
/// await is pending would hang the far end.
@Riverpod(keepAlive: true)
class TransferController extends _$TransferController {
  @override
  TransferState build() => const TransferState();

  String? _sessionId;
  Completer<StreamSink<List<int>>?>? _incoming;
  Completer<List<OutgoingFile>>? _outgoing;
  IOSink? _sink;

  /// Where received files are written. Injectable so tests never touch the
  /// real Downloads folder.
  @visibleForTesting
  Future<Directory> Function()? destinationOverride;

  /// Asks whether to accept [file], and resolves once someone answers.
  Future<StreamSink<List<int>>?> askToReceive(
    IncomingFile file, {
    required String sessionId,
  }) {
    // A second offer while one is unanswered means the far end moved on; the
    // stale question is declined rather than left to leak a completer.
    _incoming?.complete(null);

    final completer = Completer<StreamSink<List<int>>?>();
    _incoming = completer;
    _sessionId = sessionId;
    state = TransferState(
      sessionId: sessionId,
      request: IncomingRequest(sessionId: sessionId, file: file),
    );
    return completer.future;
  }

  /// Accepts the offer, opening a file to write it into.
  Future<void> accept() async {
    final request = state.request;
    if (request is! IncomingRequest) return;

    final completer = _incoming;
    _incoming = null;

    try {
      final directory = await (destinationOverride?.call() ?? _destination());
      final file = File(_freePath(directory, request.file.safeName));
      final sink = file.openWrite();
      _sink = sink;

      state = TransferState(
        sessionId: _sessionId,
        progress: TransferProgress(
          name: file.uri.pathSegments.last,
          bytes: 0,
          total: request.file.size,
          incoming: true,
          path: file.path,
        ),
      );
      completer?.complete(sink);
    } on Object catch (error) {
      // Declining is the only safe answer when there is nowhere to put it:
      // completing with a sink that cannot be written to would strand the
      // protocol mid-file.
      completer?.complete(null);
      state = TransferState(
        sessionId: _sessionId,
        error: 'Could not save the file: $error',
      );
    }
  }

  /// Declines the offer. The far end is told to skip the file.
  void decline() {
    _incoming?.complete(null);
    _incoming = null;
    state = const TransferState();
  }

  /// Asks which files to send, and resolves once someone answers.
  Future<List<OutgoingFile>> askToSend({required String sessionId}) {
    _outgoing?.complete(const []);

    final completer = Completer<List<OutgoingFile>>();
    _outgoing = completer;
    _sessionId = sessionId;
    state = TransferState(
      sessionId: sessionId,
      request: OutgoingRequest(sessionId: sessionId),
    );
    return completer.future;
  }

  /// Answers a send request with the files at [paths].
  ///
  /// An empty list — someone dismissed the picker — ends the transfer
  /// politely, which is what `rz` expects and is not an error.
  Future<void> send(List<String> paths) async {
    final completer = _outgoing;
    _outgoing = null;

    final files = <OutgoingFile>[];
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      files.add(
        OutgoingFile(
          info: ZModemFileInfo(
            pathname: file.uri.pathSegments.last,
            length: file.lengthSync(),
            modificationTime:
                file.lastModifiedSync().millisecondsSinceEpoch ~/ 1000,
          ),
          open: (offset) => file.openRead(offset).map(Uint8List.fromList),
        ),
      );
    }

    if (files.isEmpty) {
      completer?.complete(const []);
      state = const TransferState();
      return;
    }

    state = TransferState(
      sessionId: _sessionId,
      progress: TransferProgress(
        name: files.first.info.pathname,
        bytes: 0,
        total: files.first.info.length ?? 0,
        incoming: false,
      ),
    );
    completer?.complete(files);
  }

  /// Reports that [bytes] of [name] have moved.
  void report(String name, int bytes) {
    final progress = state.progress;
    if (progress == null) {
      state = TransferState(
        sessionId: _sessionId,
        progress: TransferProgress(
          name: name,
          bytes: bytes,
          total: 0,
          incoming: true,
        ),
      );
      return;
    }
    // The name changes when a multi-file transfer moves on to the next one, and
    // the total belongs to the file it came with.
    state = TransferState(
      sessionId: _sessionId,
      progress: progress.name == name
          ? progress.at(bytes)
          : TransferProgress(
              name: name,
              bytes: bytes,
              total: 0,
              incoming: progress.incoming,
            ),
    );
  }

  /// Reports that the transfer session ended.
  void finish() {
    _sink = null;
    final progress = state.progress;
    state = TransferState(sessionId: _sessionId, completed: progress);
  }

  /// Clears whatever the UI is showing.
  void dismiss() {
    _sessionId = null;
    state = const TransferState();
  }

  /// Abandons anything in flight, and removes a half-written file.
  ///
  /// Used both when someone cancels and when the session closes underneath a
  /// transfer. The partial file is deleted rather than left: a truncated
  /// download sitting in Downloads under the name of a real file is worse than
  /// no file at all, because nothing about it says it is incomplete.
  Future<void> abort() async {
    final progress = state.progress;

    _incoming?.complete(null);
    _incoming = null;
    _outgoing?.complete(const []);
    _outgoing = null;
    await _sink?.close();
    _sink = null;
    _sessionId = null;

    final path = progress?.path;
    if (progress != null && progress.incoming && path != null) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }

    state = const TransferState();
  }

  Future<Directory> _destination() async {
    Directory? downloads;
    try {
      // Only desktop has one; the mobile platforms throw rather than return
      // null, which is why this is wrapped rather than null-checked.
      downloads = await getDownloadsDirectory();
    } on Object {
      downloads = null;
    }

    final base = downloads ?? await getApplicationDocumentsDirectory();
    final directory = Directory('${base.path}/Termino');
    if (!directory.existsSync()) await directory.create(recursive: true);
    return directory;
  }

  /// A path in [directory] for [name] that does not overwrite anything.
  ///
  /// The far end chooses the name, so it will happily send `notes.txt` twice.
  /// Silently replacing a file someone already has is not acceptable from a
  /// remote machine.
  static String _freePath(Directory directory, String name) {
    var candidate = '${directory.path}/$name';
    if (!File(candidate).existsSync()) return candidate;

    final dot = name.lastIndexOf('.');
    final stem = dot > 0 ? name.substring(0, dot) : name;
    final extension = dot > 0 ? name.substring(dot) : '';

    for (var index = 2; index < 1000; index++) {
      candidate = '${directory.path}/$stem-$index$extension';
      if (!File(candidate).existsSync()) return candidate;
    }
    return '${directory.path}/$stem-${DateTime.now().microsecondsSinceEpoch}'
        '$extension';
  }
}
