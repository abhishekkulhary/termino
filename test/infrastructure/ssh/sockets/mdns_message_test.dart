import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/infrastructure/ssh/sockets/mdns_message.dart';

/// Builds a response by hand, the way a responder on the network would.
Uint8List response({
  required List<({String name, List<int> address})> answers,
  String? question,
  bool compressAnswerName = false,
}) {
  final out = BytesBuilder()
    ..add([0, 0])
    ..add([0x84, 0x00]) // Authoritative answer.
    ..add([0, if (question == null) 0 else 1])
    ..add([0, answers.length])
    ..add([0, 0])
    ..add([0, 0]);

  var questionNameAt = 0;
  if (question != null) {
    questionNameAt = out.length;
    out
      ..add(name(question))
      ..add([0, 1])
      ..add([0, 1]);
  }

  for (final answer in answers) {
    if (compressAnswerName) {
      out.add([0xC0 | (questionNameAt >> 8), questionNameAt & 0xFF]);
    } else {
      out.add(name(answer.name));
    }
    out
      ..add([0, 1]) // A
      ..add([0x80, 1]) // IN, cache-flush bit set as responders do
      ..add([0, 0, 0, 120]) // TTL
      ..add([0, answer.address.length])
      ..add(answer.address);
  }

  return out.toBytes();
}

List<int> name(String value) {
  final out = <int>[];
  for (final label in value.split('.')) {
    out
      ..add(label.length)
      ..addAll(label.codeUnits);
  }
  return out..add(0);
}

void main() {
  group('encodeAddressQuery', () {
    test('asks one A question with the unicast-reply bit set', () {
      final packet = encodeAddressQuery('pi.local', transactionId: 0x1234);

      expect(packet.sublist(0, 2), [0x12, 0x34], reason: 'transaction id');
      expect(packet.sublist(2, 4), [0, 0], reason: 'a plain query');
      expect(packet.sublist(4, 6), [0, 1], reason: 'one question');
      expect(packet.sublist(6, 12), [0, 0, 0, 0, 0, 0], reason: 'no records');

      expect(packet.sublist(12, 15), [2, 0x70, 0x69], reason: '"pi"');
      expect(packet[15], 5, reason: '"local" is five bytes');
      expect(packet[21], 0, reason: 'the root label ends the name');
      expect(packet.sublist(22, 24), [0, 1], reason: 'type A');
      // Without the top bit the responder answers the whole multicast group,
      // where the platform's own responder is listening on the same port.
      expect(packet.sublist(24, 26), [0x80, 1], reason: 'unicast reply, IN');
    });

    test('a trailing dot makes no difference to the wire form', () {
      expect(encodeAddressQuery('pi.local.'), encodeAddressQuery('pi.local'));
    });
  });

  group('decodeAddressesFor', () {
    test('reads the address out of an answer', () {
      final packet = response(
        question: 'pi.local',
        answers: [
          (name: 'pi.local', address: [192, 168, 0, 206]),
        ],
      );
      expect(decodeAddressesFor(packet, 'pi.local'), ['192.168.0.206']);
    });

    test('follows a compression pointer back to the question', () {
      final packet = response(
        question: 'pi.local',
        answers: [
          (name: 'pi.local', address: [10, 0, 0, 4]),
        ],
        compressAnswerName: true,
      );
      expect(decodeAddressesFor(packet, 'pi.local'), ['10.0.0.4']);
    });

    test('matches names without regard to case or a trailing dot', () {
      final packet = response(
        answers: [
          (name: 'PI.Local', address: [10, 0, 0, 5]),
        ],
      );
      expect(decodeAddressesFor(packet, 'pi.local.'), ['10.0.0.5']);
    });

    test('ignores an answer about a different host', () {
      // The multicast group carries every machine's announcements, so a reply
      // arriving while we listen is not necessarily a reply to us.
      final packet = response(
        answers: [
          (name: 'printer.local', address: [10, 0, 0, 9]),
        ],
      );
      expect(decodeAddressesFor(packet, 'pi.local'), isEmpty);
    });

    test('returns every address a multi-homed host announces', () {
      final packet = response(
        answers: [
          (name: 'pi.local', address: [10, 0, 0, 4]),
          (name: 'printer.local', address: [10, 0, 0, 9]),
          (name: 'pi.local', address: [192, 168, 0, 4]),
        ],
      );
      expect(decodeAddressesFor(packet, 'pi.local'), [
        '10.0.0.4',
        '192.168.0.4',
      ]);
    });

    test('a truncated message yields nothing rather than throwing', () {
      final packet = response(
        question: 'pi.local',
        answers: [
          (name: 'pi.local', address: [10, 0, 0, 4]),
        ],
      );
      for (var length = 0; length < packet.length; length++) {
        expect(
          decodeAddressesFor(
            Uint8List.sublistView(packet, 0, length),
            'pi.local',
          ),
          isEmpty,
          reason: 'truncated to $length bytes',
        );
      }
    });

    test('a pointer loop terminates', () {
      // A pointer may only point backwards; one that does not is malformed,
      // and a stranger on the network is who decides what these bytes say.
      final packet = Uint8List.fromList([
        0, 0, 0x84, 0, 0, 0, 0, 1, 0, 0, 0, 0,
        0xC0, 12, // points at itself
        0, 1, 0x80, 1, 0, 0, 0, 120, 0, 4, 10, 0, 0, 4,
      ]);
      expect(decodeAddressesFor(packet, 'pi.local'), isEmpty);
    });
  });
}
