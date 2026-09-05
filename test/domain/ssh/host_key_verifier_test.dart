import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';

import '../../support/in_memory_known_hosts.dart';

const _goodFingerprint = 'SHA256:hEW4I4kjBMvm75Uin7EwqLXt6pbjLb+ggqsfchUe5Fg';
const _otherFingerprint = 'SHA256:NFV/FuUthKjv9ldwWqTwEulct4bwxVABOncZTpkvmVU';

KnownHost known({
  String host = 'build-01',
  int port = 22,
  String keyType = 'ssh-ed25519',
  String fingerprint = _goodFingerprint,
}) => KnownHost(
  host: host,
  port: port,
  keyType: keyType,
  fingerprint: fingerprint,
  addedAt: DateTime(2026),
  source: KnownHostSource.trustOnFirstUse,
);

void main() {
  late InMemoryKnownHostsRepository repository;
  late HostKeyVerifier verifier;

  setUp(() {
    repository = InMemoryKnownHostsRepository();
    verifier = HostKeyVerifier(repository);
  });

  Future<HostKeyCheck> check({
    String host = 'build-01',
    int port = 22,
    String keyType = 'ssh-ed25519',
    String fingerprint = _goodFingerprint,
  }) => verifier.check(
    host: host,
    port: port,
    keyType: keyType,
    fingerprint: fingerprint,
  );

  group('unknown hosts', () {
    test('an unseen host is unknown, so the user is asked', () async {
      final result = await check();

      expect(result.verdict, HostKeyVerdict.unknown);
      expect(result.verdict.blocksConnection, isFalse);
      expect(result.verdict.isAutomaticallyTrusted, isFalse);
      expect(result.expected, isNull);
    });

    test('a different port is a different host', () async {
      await repository.add(known());

      expect((await check(port: 2222)).verdict, HostKeyVerdict.unknown);
    });

    test('a different hostname is a different host', () async {
      await repository.add(known());

      expect((await check(host: 'build-02')).verdict, HostKeyVerdict.unknown);
    });
  });

  group('trusted hosts', () {
    test('a matching key is trusted without asking', () async {
      await repository.add(known());

      final result = await check();

      expect(result.verdict, HostKeyVerdict.trusted);
      expect(result.verdict.isAutomaticallyTrusted, isTrue);
      expect(result.expected, isNotNull);
    });
  });

  group('mismatches', () {
    test('a changed key is a mismatch and blocks the connection', () async {
      await repository.add(known());

      final result = await check(fingerprint: _otherFingerprint);

      expect(result.verdict, HostKeyVerdict.mismatch);
      expect(result.verdict.blocksConnection, isTrue);
    });

    test('the dialog gets both fingerprints to show side by side', () async {
      await repository.add(known());

      final result = await check(fingerprint: _otherFingerprint);

      expect(result.fingerprint, _otherFingerprint);
      expect(result.expected!.fingerprint, _goodFingerprint);
    });

    test('a mismatch is never silently trusted', () async {
      await repository.add(known());
      final result = await check(fingerprint: _otherFingerprint);

      await expectLater(verifier.trust(result), throwsA(isA<StateError>()));
      expect(
        repository.entries.single.fingerprint,
        _goodFingerprint,
        reason: 'the stored key must be untouched after a refused trust',
      );
    });

    test('replacing a key is a separate, deliberate act', () async {
      await repository.add(known());

      await repository.replace(known(fingerprint: _otherFingerprint));

      expect(repository.entries, hasLength(1));
      expect(
        (await check(fingerprint: _otherFingerprint)).verdict,
        HostKeyVerdict.trusted,
      );
    });
  });

  group('new key types', () {
    test('a known host offering a new key type asks, and says so', () async {
      await repository.add(known());

      final result = await check(keyType: 'ssh-rsa');

      expect(result.verdict, HostKeyVerdict.newKeyType);
      expect(result.verdict.blocksConnection, isFalse);
      expect(result.otherKnownTypes, ['ssh-ed25519']);
    });

    test('a mismatch on one type is unaffected by another type', () async {
      await repository.add(known());
      await repository.add(
        known(keyType: 'ssh-rsa', fingerprint: _otherFingerprint),
      );

      // The ed25519 key still matches.
      expect((await check()).verdict, HostKeyVerdict.trusted);
      // The RSA key does not.
      expect(
        (await check(keyType: 'ssh-rsa')).verdict,
        HostKeyVerdict.mismatch,
      );
    });
  });

  group('trust', () {
    test('records an unknown key as trust-on-first-use', () async {
      final result = await check();

      final entry = await verifier.trust(result);

      expect(entry.source, KnownHostSource.trustOnFirstUse);
      expect(entry.fingerprint, _goodFingerprint);
      expect(repository.entries, hasLength(1));
      expect((await check()).verdict, HostKeyVerdict.trusted);
    });

    test('records a new key type alongside the existing one', () async {
      await repository.add(known());
      final result = await check(keyType: 'ssh-rsa');

      await verifier.trust(result);

      expect(repository.entries, hasLength(2));
      expect((await check(keyType: 'ssh-rsa')).verdict, HostKeyVerdict.trusted);
    });
  });

  group('display', () {
    test('target omits the default port and includes any other', () async {
      expect((await check()).target, 'build-01');
      expect((await check(port: 2222)).target, 'build-01:2222');
    });
  });
}
