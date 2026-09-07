import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/infrastructure/ssh/agent/agent_protocol.dart';

/// The agent protocol is bytes on a socket, and the socket belongs to a process
/// holding somebody's private keys. Everything here is exercised against the
/// wire format rather than against a live agent, so it runs anywhere.
void main() {
  Uint8List string(List<int> value) => Uint8List.fromList([
    (value.length >> 24) & 0xff,
    (value.length >> 16) & 0xff,
    (value.length >> 8) & 0xff,
    value.length & 0xff,
    ...value,
  ]);

  /// A public key blob: the type name, then the key itself.
  Uint8List blobOf(String type) => Uint8List.fromList([
    ...string(utf8.encode(type)),
    ...string([1, 2, 3]),
  ]);

  Uint8List answer(int type, List<int> payload) {
    final length = payload.length + 1;
    return Uint8List.fromList([
      (length >> 24) & 0xff,
      (length >> 16) & 0xff,
      (length >> 8) & 0xff,
      length & 0xff,
      type,
      ...payload,
    ]);
  }

  group('asking for the key list', () {
    test('frames a request the way the protocol says', () {
      final message = AgentProtocol.requestIdentitiesMessage();
      expect(message, [0, 0, 0, 1, AgentProtocol.requestIdentities]);
    });

    test('reads back the keys and their comments', () {
      final message = answer(AgentProtocol.identitiesAnswer, [
        0, 0, 0, 2, //
        ...string(blobOf('ssh-ed25519')),
        ...string(utf8.encode('me@laptop')),
        ...string(blobOf('ssh-rsa')), ...string(utf8.encode('old key')),
      ]);

      final keys = AgentProtocol.decodeIdentities(message);

      expect(keys, hasLength(2));
      expect(keys.first.type, 'ssh-ed25519');
      expect(keys.first.comment, 'me@laptop');
      expect(keys.last.type, 'ssh-rsa');
    });

    test('an empty agent is an empty list, not an error', () {
      final message = answer(AgentProtocol.identitiesAnswer, [0, 0, 0, 0]);
      expect(AgentProtocol.decodeIdentities(message), isEmpty);
    });

    test('a claim of four billion keys fails rather than allocating', () {
      // The count is four bytes off a socket and is not a size to trust.
      final message = answer(AgentProtocol.identitiesAnswer, [
        0xff,
        0xff,
        0xff,
        0xff,
      ]);
      expect(
        () => AgentProtocol.decodeIdentities(message),
        throwsA(isA<AgentProtocolException>()),
      );
    });

    test('a truncated reply is reported, not read past', () {
      final message = answer(AgentProtocol.identitiesAnswer, [
        0, 0, 0, 1, //
        0, 0, 0, 40, 1, 2, 3,
      ]);
      expect(
        () => AgentProtocol.decodeIdentities(message),
        throwsA(isA<AgentProtocolException>()),
      );
    });

    test('a refusal is a message a person can read', () {
      final message = answer(AgentProtocol.failure, []);
      expect(
        () => AgentProtocol.decodeIdentities(message),
        throwsA(
          isA<AgentProtocolException>().having(
            (error) => error.message,
            'message',
            contains('refused'),
          ),
        ),
      );
    });
  });

  group('asking for a signature', () {
    test('sends the key, the data and the flags', () {
      final blob = blobOf('ssh-rsa');
      final data = Uint8List.fromList([9, 8, 7]);

      final message = AgentProtocol.signRequestMessage(
        blob,
        data,
        AgentProtocol.rsaSha2_512,
      );

      expect(message[4], AgentProtocol.signRequest);
      expect(message.sublist(message.length - 4), [0, 0, 0, 4]);
    });

    test('reads the signature back out', () {
      final signature = utf8.encode('signed');
      final message = answer(
        AgentProtocol.signResponse,
        string(signature).toList(),
      );

      expect(AgentProtocol.decodeSignature(message), signature);
    });

    test('a refusal names what was being asked for', () {
      final message = answer(AgentProtocol.failure, []);
      expect(
        () => AgentProtocol.decodeSignature(message),
        throwsA(
          isA<AgentProtocolException>().having(
            (error) => error.message,
            'message',
            contains('sign'),
          ),
        ),
      );
    });
  });

  group('choosing a signature algorithm', () {
    test('an RSA key asks for SHA-2, never SHA-1', () {
      // `ssh-rsa` names an SHA-1 signature, which OpenSSH 8.8 and later refuse
      // by default. The same key signs with SHA-2 when asked.
      final key = AgentKey(blob: blobOf('ssh-rsa'), comment: '');

      expect(key.algorithm, 'rsa-sha2-512');
      expect(key.signFlags, AgentProtocol.rsaSha2_512);
    });

    test('everything else asks for its own type with no flags', () {
      final key = AgentKey(blob: blobOf('ssh-ed25519'), comment: '');

      expect(key.algorithm, 'ssh-ed25519');
      expect(key.signFlags, 0);
    });

    test('a hardware-backed key is offered as it is', () {
      final key = AgentKey(
        blob: blobOf('sk-ssh-ed25519@openssh.com'),
        comment: 'yubikey',
      );

      expect(key.algorithm, 'sk-ssh-ed25519@openssh.com');
      expect(key.signFlags, 0);
    });
  });

  group('reading a frame off a socket', () {
    test('waits until the whole message has arrived', () {
      expect(AgentProtocol.frameLength(Uint8List.fromList([0, 0])), isNull);
      expect(
        AgentProtocol.frameLength(Uint8List.fromList([0, 0, 0, 5, 12, 0])),
        isNull,
      );
    });

    test('reports the length once it has', () {
      final message = answer(AgentProtocol.identitiesAnswer, [0, 0, 0, 0]);
      expect(AgentProtocol.frameLength(message), message.length);
    });
  });
}
