import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/domain/ssh/known_hosts_file.dart';

/// Fixtures produced by real `ssh-keygen`, so the parser is checked against
/// what OpenSSH actually writes rather than against data shaped to fit it.
String fixture(String name) =>
    File('test/fixtures/keys/$name').readAsStringSync();

String publicKeyBlob(String name) => fixture('$name.pub').trim().split(' ')[1];

void main() {
  late String ed25519Key;
  late String rsaKey;

  setUpAll(() {
    ed25519Key = publicKeyBlob('ed25519_host');
    rsaKey = publicKeyBlob('rsa_host');
  });

  group('parse', () {
    test('reads every well-formed line of a real file', () {
      final entries = KnownHostsFile.parse(fixture('known_hosts'));

      // The fixture has five good lines plus two deliberately broken ones.
      expect(
        entries,
        hasLength(5),
        reason: 'malformed lines must be skipped, not fatal',
      );
    });

    test('matches the fingerprint ssh-keygen reports', () {
      // `ssh-keygen -lf` prints exactly this for the fixture key.
      final expected = Process.runSync('ssh-keygen', [
        '-lf',
        'test/fixtures/keys/ed25519_host.pub',
      ]).stdout.toString().split(' ')[1];

      final entries = KnownHostsFile.parse('build-01 ssh-ed25519 $ed25519Key');

      expect(entries.single.fingerprint, expected);
    });

    test('reads type, key and patterns', () {
      final entry = KnownHostsFile.parse('build-01 ssh-ed25519 $ed25519Key')
          .single;

      expect(entry.keyType, 'ssh-ed25519');
      expect(entry.publicKey, ed25519Key);
      expect(entry.patterns, ['build-01']);
      expect(entry.isHashed, isFalse);
    });

    test('reads a marker and a trailing comment', () {
      final entries = KnownHostsFile.parse(fixture('known_hosts'));
      final ca = entries.firstWhere((e) => e.marker != null);

      expect(ca.marker, '@cert-authority');
      expect(ca.comment, 'trailing comment here');
    });

    test('handles comma-separated patterns', () {
      final entry = KnownHostsFile.parse('build-01,10.0.0.5 ssh-rsa $rsaKey')
          .single;

      expect(entry.matchesHost('build-01', 22), isTrue);
      expect(entry.matchesHost('10.0.0.5', 22), isTrue);
    });
  });

  group('hashed entries', () {
    // Produced by `ssh-keygen -H`, which is the default on many distributions.
    late List<KnownHostsEntry> hashed;

    setUpAll(() {
      hashed = KnownHostsFile.parse(fixture('known_hosts_hashed'));
    });

    test('are recognised as hashed', () {
      expect(hashed, hasLength(2));
      expect(hashed.every((entry) => entry.isHashed), isTrue);
    });

    test('match the host they were hashed from', () {
      final ed = hashed.firstWhere((e) => e.keyType == 'ssh-ed25519');

      expect(
        ed.matchesHost('build-01', 22),
        isTrue,
        reason: 'HMAC-SHA1 of the hostname keyed by the salt must match',
      );
    });

    test('match a non-default port through its bracketed form', () {
      final rsa = hashed.firstWhere((e) => e.keyType == 'ssh-rsa');

      expect(rsa.matchesHost('build-02', 2222), isTrue);
    });

    test('do not match an unrelated host', () {
      for (final entry in hashed) {
        expect(entry.matchesHost('not-this-host', 22), isFalse);
      }
    });

    test('reveal no host names, which is the point of hashing', () {
      for (final entry in hashed) {
        expect(entry.literalHosts, isEmpty);
      }
    });
  });

  group('host matching', () {
    KnownHostsEntry entryFor(String hosts) =>
        KnownHostsFile.parse('$hosts ssh-ed25519 $ed25519Key').single;

    test('a bare name matches only the default port', () {
      expect(entryFor('build-01').matchesHost('build-01', 22), isTrue);
      expect(
        entryFor('build-01').matchesHost('build-01', 2222),
        isFalse,
        reason: 'OpenSSH writes [host]:port for non-default ports',
      );
    });

    test('a bracketed name matches its port only', () {
      expect(entryFor('[build-02]:2222').matchesHost('build-02', 2222), isTrue);
      expect(entryFor('[build-02]:2222').matchesHost('build-02', 22), isFalse);
    });

    test('matching is case-insensitive', () {
      expect(entryFor('Build-01').matchesHost('build-01', 22), isTrue);
    });

    test('wildcards behave like OpenSSH', () {
      expect(
        entryFor('*.example.com').matchesHost('a.example.com', 22),
        isTrue,
      );
      expect(entryFor('*.example.com').matchesHost('example.com', 22), isFalse);
      expect(entryFor('build-0?').matchesHost('build-01', 22), isTrue);
      expect(entryFor('build-0?').matchesHost('build-011', 22), isFalse);
    });

    test('a negated pattern excludes an otherwise matching host', () {
      final entry = entryFor('*.example.com,!secret.example.com');

      expect(entry.matchesHost('ok.example.com', 22), isTrue);
      expect(entry.matchesHost('secret.example.com', 22), isFalse);
    });

    test('an unrelated host never matches', () {
      expect(entryFor('build-01').matchesHost('build-02', 22), isFalse);
    });
  });

  group('conversion', () {
    test('produces a KnownHost marked as imported', () {
      final entry = KnownHostsFile.parse('h ssh-ed25519 $ed25519Key').single;

      final known = entry.toKnownHost(host: 'build-01', port: 2222);

      expect(known.host, 'build-01');
      expect(known.port, 2222);
      expect(known.keyType, 'ssh-ed25519');
      expect(known.fingerprint, entry.fingerprint);
      expect(known.publicKey, ed25519Key);
      expect(known.source, KnownHostSource.imported);
      expect(known.hostPort, '[build-01]:2222');
    });

    test('literalHosts omits wildcard patterns', () {
      expect(
        KnownHostsFile.parse('a,b,*.c ssh-ed25519 $ed25519Key')
            .single
            .literalHosts,
        ['a', 'b'],
      );
    });
  });

  group('fingerprintOf', () {
    test('is stable and padding-free', () {
      final blob = Uint8List.fromList(List.generate(64, (i) => i));

      final first = KnownHostsFile.fingerprintOf(blob);

      expect(first, KnownHostsFile.fingerprintOf(blob));
      expect(first, startsWith('SHA256:'));
      expect(first.contains('='), isFalse);
    });

    test('differs for different keys', () {
      expect(
        KnownHostsFile.fingerprintOf(base64.decode(ed25519Key)),
        isNot(KnownHostsFile.fingerprintOf(base64.decode(rsaKey))),
      );
    });
  });
}
