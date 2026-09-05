import 'package:flutter_test/flutter_test.dart';
import 'package:termino/core/logging/redaction.dart';

/// A realistic OpenSSH private key body. Not a real key — the base64 is
/// nonsense — but shaped like one, which is what the pattern matches on.
const _privateKey = '''
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBQnotFakeKeyMaterialThatMustNeverAppearInALogAAAAAAAAAAAAA
-----END OPENSSH PRIVATE KEY-----''';

void main() {
  late Redactor redactor;

  setUp(() => redactor = Redactor());

  group('registered secrets', () {
    // This is the test SECURITY.md promises: a log line containing a known
    // secret comes out redacted.
    test('a registered password never survives a log line', () {
      const password = 'correct-horse-battery-staple';
      redactor.registerSecret(password);

      final line = redactor.redact(
        'Authenticating to build-01 as deploy with $password',
      );

      expect(line, isNot(contains(password)));
      expect(line, contains(Redactor.placeholder));
      expect(line, contains('build-01'), reason: 'context must survive');
    });

    test('a registered secret is removed everywhere it appears', () {
      redactor.registerSecret('s3cr3t-value');

      final line = redactor.redact('s3cr3t-value ... and again s3cr3t-value');

      expect(line, isNot(contains('s3cr3t-value')));
    });

    test('very short secrets are ignored, to keep logs usable', () {
      redactor.registerSecret('ab');

      expect(redactor.redact('about'), 'about');
    });

    test('a forgotten secret is no longer stripped', () {
      redactor
        ..registerSecret('temporary-passphrase')
        ..forgetSecret('temporary-passphrase');

      expect(redactor.redact('temporary-passphrase'), 'temporary-passphrase');
    });

    test('clear forgets everything', () {
      redactor
        ..registerSecret('one-secret-value')
        ..registerSecret('two-secret-value')
        ..clear();

      expect(redactor.redact('one-secret-value'), 'one-secret-value');
    });
  });

  group('private key material', () {
    test('a PEM private key is removed', () {
      final line = redactor.redact('Loaded identity:\n$_privateKey');

      expect(line, isNot(contains('FakeKeyMaterial')));
      expect(line, isNot(contains('b3BlbnNzaC1rZXktdjEA')));
      expect(line, contains(Redactor.placeholder));
    });

    test('a truncated PEM block is still removed', () {
      // A log cut off mid-key is still a leak.
      final truncated = _privateKey.split('\n').take(2).join('\n');

      final line = redactor.redact('key: $truncated');

      expect(line, isNot(contains('b3BlbnNzaC1rZXktdjEA')));
      expect(line, contains(Redactor.placeholder));
    });

    test('every PEM label is covered, not just OPENSSH', () {
      for (final label in [
        'RSA PRIVATE KEY',
        'EC PRIVATE KEY',
        'PRIVATE KEY',
        'ENCRYPTED PRIVATE KEY',
      ]) {
        final pem =
            '-----BEGIN $label-----\nAAAAsecretAAAA\n-----END $label-----';

        expect(
          redactor.redact(pem),
          isNot(contains('AAAAsecretAAAA')),
          reason: label,
        );
      }
    });
  });

  group('key-value credentials', () {
    test('common credential keys are redacted whatever the separator', () {
      const cases = [
        'password=hunter2',
        'password: hunter2',
        'passphrase = hunter2',
        '"secret": "hunter2"',
        'token=hunter2',
        'api_key: hunter2',
        'Authorization: hunter2',
      ];

      for (final input in cases) {
        final line = redactor.redact(input);
        expect(line, isNot(contains('hunter2')), reason: input);
        expect(line, contains(Redactor.placeholder), reason: input);
      }
    });

    test('matching is case-insensitive on the key', () {
      expect(redactor.redact('PASSWORD=hunter2'), isNot(contains('hunter2')));
      expect(
        redactor.redact('PassPhrase: hunter2'),
        isNot(contains('hunter2')),
      );
    });

    test('the key itself is kept so the line stays meaningful', () {
      expect(redactor.redact('password=hunter2'), contains('password'));
    });
  });

  group('credentials in URLs', () {
    test('a password inside a URL is removed', () {
      final line = redactor.redact('connecting to ssh://deploy:hunter2@host');

      expect(line, isNot(contains('hunter2')));
      expect(line, contains('deploy'));
      expect(line, contains('host'));
    });
  });

  group('public keys', () {
    test('an authorized_keys blob is redacted', () {
      final line = redactor.redact(
        'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBoguserkeyblobvaluehere user@mac',
      );

      expect(line, isNot(contains('AAAAC3NzaC1lZDI1NTE5AAAAIBoguserkeyblob')));
      expect(line, contains('ssh-ed25519'));
    });
  });

  group('ordinary text', () {
    test('is left alone', () {
      const line = 'Connected to build-01:22 as deploy in 240ms';

      expect(redactor.redact(line), line);
    });

    test('a fingerprint is not a secret and survives', () {
      const line = 'host key SHA256:SoUNE+BPf+7cdH6vUMw87+SlQY7mWYFpA8p8UsFq';

      expect(redactor.redact(line), contains('SHA256:'));
    });
  });
}
