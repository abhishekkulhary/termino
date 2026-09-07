import 'dart:typed_data';

import 'package:termino/domain/ssh/known_hosts_file.dart';

/// A public key an agent is holding.
///
/// The private half never leaves the agent; all this side ever sees is the
/// public blob, a comment, and — when it asks — a signature. That is the whole
/// point of using one.
class AgentKey {
  /// Creates a key listing.
  const new({required this.blob, required this.comment});

  /// The public key in SSH wire format, exactly as the agent sent it.
  final Uint8List blob;

  /// Whatever the agent calls it — usually the path it was loaded from.
  final String comment;

  /// The key type, read from the front of the blob (`ssh-ed25519`, `ssh-rsa`).
  ///
  /// A blob that does not begin with a readable type name is reported as
  /// `unknown` rather than throwing: the list of keys is something the UI
  /// shows, and one odd entry must not take the whole list down with it.
  String get type {
    try {
      final (name, _) = AgentProtocol.readString(blob, 0);
      return name.isEmpty ? 'unknown' : String.fromCharCodes(name);
    } on AgentProtocolException {
      return 'unknown';
    }
  }

  /// The signature algorithm to ask for when authenticating with this key.
  ///
  /// RSA is the exception: `ssh-rsa` names an SHA-1 signature, which OpenSSH
  /// 8.8 and later refuse by default. The agent will produce an SHA-2
  /// signature from the same key when asked, so that is what is asked for.
  String get algorithm => switch (type) {
    'ssh-rsa' => 'rsa-sha2-512',
    'ssh-rsa-cert-v01@openssh.com' => 'rsa-sha2-512-cert-v01@openssh.com',
    final other => other,
  };

  /// The flags to send with a signature request for this key.
  int get signFlags =>
      type.startsWith('ssh-rsa') ? AgentProtocol.rsaSha2_512 : 0;

  /// The OpenSSH-style `SHA256:...` fingerprint, for showing to a person.
  String get fingerprint => KnownHostsFile.fingerprintOf(blob);
}

/// Something the agent said that this code cannot act on.
class AgentProtocolException implements Exception {
  /// Creates a failure with [message].
  const new(this.message);

  /// What went wrong, in terms that can be shown to a user.
  final String message;

  @override
  String toString() => message;
}

/// The wire format of the SSH agent protocol (draft-miller-ssh-agent).
///
/// Split from the socket so it can be tested against captured bytes: an agent
/// is a live process holding a person's keys, and a codec that can only be
/// exercised by talking to one is a codec nobody tests.
///
/// Every message is a 32-bit big-endian length, a type byte, then the payload.
/// Strings inside are themselves length-prefixed.
abstract final class AgentProtocol {
  /// Ask the agent what it is holding.
  static const requestIdentities = 11;

  /// Its answer.
  static const identitiesAnswer = 12;

  /// Ask it to sign something.
  static const signRequest = 13;

  /// Its answer.
  static const signResponse = 14;

  /// A refusal. Carries no reason, by design of the protocol.
  static const failure = 5;

  /// Ask for an RSA signature over SHA-256 rather than SHA-1.
  static const rsaSha2_256 = 0x02;

  /// Ask for an RSA signature over SHA-512.
  static const rsaSha2_512 = 0x04;

  /// A framed message of [type] carrying [payload].
  static Uint8List frame(int type, [List<int> payload = const []]) {
    final length = payload.length + 1;
    final bytes = BytesBuilder()
      ..add([
        (length >> 24) & 0xff,
        (length >> 16) & 0xff,
        (length >> 8) & 0xff,
        length & 0xff,
      ])
      ..addByte(type)
      ..add(payload);
    return bytes.toBytes();
  }

  /// The message that asks for the list of keys.
  static Uint8List requestIdentitiesMessage() => frame(requestIdentities);

  /// The message that asks for a signature over [data] by the key [blob].
  static Uint8List signRequestMessage(
    Uint8List blob,
    Uint8List data,
    int flags,
  ) {
    final payload = BytesBuilder()
      ..add(_string(blob))
      ..add(_string(data))
      ..add([
        (flags >> 24) & 0xff,
        (flags >> 16) & 0xff,
        (flags >> 8) & 0xff,
        flags & 0xff,
      ]);
    return frame(signRequest, payload.toBytes());
  }

  /// How long the message at the front of [buffer] is, including its own
  /// four-byte length, or null when not all of it has arrived yet.
  static int? frameLength(Uint8List buffer) {
    if (buffer.length < 4) return null;
    final length = readUint32(buffer, 0);
    if (buffer.length < length + 4) return null;
    return length + 4;
  }

  /// The keys in an `SSH_AGENT_IDENTITIES_ANSWER`.
  ///
  /// [message] is one whole frame, length prefix included.
  static List<AgentKey> decodeIdentities(Uint8List message) {
    final body = _body(message, identitiesAnswer, 'list its keys');

    var offset = 0;
    final count = readUint32(body, offset);
    offset += 4;

    // A count is four bytes from a socket and is not trusted as a size: a
    // damaged or hostile answer claiming four billion keys must fail on the
    // next read rather than allocate.
    final keys = <AgentKey>[];
    for (var index = 0; index < count; index++) {
      final (blob, afterBlob) = readString(body, offset);
      final (comment, afterComment) = readString(body, afterBlob);
      offset = afterComment;
      keys.add(
        AgentKey(blob: blob, comment: String.fromCharCodes(comment).trim()),
      );
    }
    return keys;
  }

  /// The signature in an `SSH_AGENT_SIGN_RESPONSE`, in SSH wire format.
  static Uint8List decodeSignature(Uint8List message) {
    final body = _body(message, signResponse, 'sign with that key');
    final (signature, _) = readString(body, 0);
    return signature;
  }

  /// A big-endian 32-bit integer at [offset].
  static int readUint32(Uint8List bytes, int offset) {
    if (offset + 4 > bytes.length) {
      throw const AgentProtocolException('The agent sent a truncated reply.');
    }
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  /// A length-prefixed string at [offset], and where it ends.
  static (Uint8List, int) readString(Uint8List bytes, int offset) {
    final length = readUint32(bytes, offset);
    final start = offset + 4;
    if (start + length > bytes.length) {
      throw const AgentProtocolException('The agent sent a truncated reply.');
    }
    return (
      Uint8List.sublistView(bytes, start, start + length),
      start + length,
    );
  }

  static List<int> _string(Uint8List value) => [
    (value.length >> 24) & 0xff,
    (value.length >> 16) & 0xff,
    (value.length >> 8) & 0xff,
    value.length & 0xff,
    ...value,
  ];

  /// The payload of [message], having checked it is the reply that was wanted.
  static Uint8List _body(Uint8List message, int expected, String what) {
    if (message.length < 5) {
      throw const AgentProtocolException('The agent sent a truncated reply.');
    }

    final type = message[4];
    if (type == failure) {
      // The protocol carries no reason with a failure, so neither does this.
      throw AgentProtocolException('The agent refused to $what.');
    }
    if (type != expected) {
      throw AgentProtocolException(
        'The agent sent an unexpected reply (type $type).',
      );
    }
    return Uint8List.sublistView(message, 5);
  }
}
