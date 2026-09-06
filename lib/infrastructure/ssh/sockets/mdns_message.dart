/// The two mDNS messages this app needs: an address question, and the answers
/// that come back.
///
/// Written here rather than taken from a package because of how the query has
/// to be asked on Android. A library that binds the standard mDNS port, 5353,
/// ends up sharing it with Android's own responder through `SO_REUSEPORT`, and
/// the kernel then hands each arriving reply to one socket or the other. On a
/// real device that meant a name resolved roughly a third of the time — the
/// worst kind of bug, because "it worked when I tried it" is true.
///
/// A one-shot query from an ephemeral port, asking for a unicast reply, has
/// the port to itself. Measured on device: ten lookups out of ten, in 8-180ms.
///
/// mDNS is DNS on a multicast address, so this is ordinary DNS wire format
/// (RFC 1035) with the one addition from RFC 6762 noted at [_unicastReply].
library;

import 'dart:typed_data';

/// The multicast group mDNS queries go to.
const mdnsGroupIPv4 = '224.0.0.251';

/// The port they go to. Note that this is the *destination*: the socket
/// sending them deliberately binds to an ephemeral port instead.
const mdnsPort = 5353;

/// RFC 6762 §5.4: the top bit of the question's class asks the responder to
/// reply directly to us rather than to the whole multicast group. That is what
/// keeps the answer away from the system responder listening on 5353.
const _unicastReply = 0x8000;

const _classInternet = 1;
const _typeA = 1;

/// Encodes a question asking for the IPv4 address of [name].
Uint8List encodeAddressQuery(String name, {int transactionId = 0}) {
  final out = BytesBuilder()
    ..add(_uint16(transactionId))
    ..add(_uint16(0)) // Standard query, no flags set.
    ..add(_uint16(1)) // One question.
    ..add(_uint16(0)) // No answer, authority or additional records.
    ..add(_uint16(0))
    ..add(_uint16(0));

  for (final label in _labelsOf(name)) {
    final bytes = _asciiOf(label);
    out
      ..addByte(bytes.length)
      ..add(bytes);
  }
  out
    ..addByte(0)
    ..add(_uint16(_typeA))
    ..add(_uint16(_classInternet | _unicastReply));

  return out.toBytes();
}

/// The IPv4 addresses [message] gives for [name], as dotted quads.
///
/// Returns empty for a reply that is malformed, truncated, or about some other
/// host — a multicast group carries everyone's announcements, and a response
/// arriving while we are listening is not necessarily an answer to us.
List<String> decodeAddressesFor(Uint8List message, String name) {
  try {
    return _decode(message, _canonical(name));
  } on Object {
    // A stranger on the network decides what these bytes look like, so a
    // parse failure is an expected outcome rather than an error.
    return const [];
  }
}

List<String> _decode(Uint8List message, String wanted) {
  if (message.length < 12) return const [];

  final reader = _Reader(message)..offset = 4;
  final questions = reader.uint16();
  final records =
      reader.uint16() + reader.uint16() + reader.uint16(); // an + ns + ar

  for (var i = 0; i < questions; i++) {
    reader
      ..skipName()
      ..offset += 4; // type + class
  }

  final addresses = <String>[];
  for (var i = 0; i < records && reader.hasMore; i++) {
    final owner = reader.readName();
    final type = reader.uint16();
    reader
      ..offset +=
          2 // class, whose top bit is a cache-flush flag here
      ..offset += 4; // ttl
    final length = reader.uint16();
    final start = reader.offset;

    if (type == _typeA && length == 4 && _canonical(owner) == wanted) {
      addresses.add(message.sublist(start, start + 4).join('.'));
    }
    reader.offset = start + length;
  }

  return addresses;
}

/// Names are compared without their trailing dot and without regard to case,
/// which is how DNS defines equality.
String _canonical(String name) {
  final trimmed = name.endsWith('.')
      ? name.substring(0, name.length - 1)
      : name;
  return trimmed.toLowerCase();
}

List<String> _labelsOf(String name) =>
    _canonical(name).split('.').where((label) => label.isNotEmpty).toList();

List<int> _asciiOf(String label) => label.codeUnits;

List<int> _uint16(int value) => [(value >> 8) & 0xFF, value & 0xFF];

/// Walks a DNS message, following the compression pointers that let a name
/// refer back to one written earlier.
class _Reader {
  new(this.bytes);

  final Uint8List bytes;
  int offset = 0;

  bool get hasMore => offset < bytes.length;

  int uint8() => bytes[offset++];

  int uint16() {
    final value = (bytes[offset] << 8) | bytes[offset + 1];
    offset += 2;
    return value;
  }

  /// Advances past a name without decoding it.
  void skipName() {
    while (hasMore) {
      final length = uint8();
      if (length == 0) return;
      if (length & 0xC0 == 0xC0) {
        offset++; // The second half of the pointer.
        return;
      }
      offset += length;
    }
  }

  /// Reads a name, following pointers.
  ///
  /// A pointer may only ever point backwards, so requiring that is both
  /// correct and what stops a malicious message looping forever.
  String readName() {
    final labels = <String>[];
    var cursor = offset;
    var jumped = false;
    var limit = bytes.length;

    while (cursor < bytes.length) {
      final length = bytes[cursor];

      if (length == 0) {
        cursor++;
        break;
      }

      if (length & 0xC0 == 0xC0) {
        final target = ((length & 0x3F) << 8) | bytes[cursor + 1];
        if (target >= limit) throw const FormatException('forward pointer');
        limit = target;
        if (!jumped) {
          offset = cursor + 2;
          jumped = true;
        }
        cursor = target;
        continue;
      }

      labels.add(String.fromCharCodes(bytes, cursor + 1, cursor + 1 + length));
      cursor += length + 1;
    }

    if (!jumped) offset = cursor;
    return labels.join('.');
  }
}
