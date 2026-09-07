@Timeout(Duration(seconds: 120))
library;

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/auth/biometric_gate.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/entities/ssh_identity.dart';
import 'package:termino/domain/repositories/ssh_host_repository.dart';
import 'package:termino/domain/repositories/ssh_identity_repository.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/features/hosts/application/ssh_connector.dart';
import 'package:termino/features/hosts/application/ssh_prompt_service.dart';
import 'package:termino/features/hosts/presentation/host_key_dialogs.dart';
import 'package:termino/infrastructure/ssh/ssh_socket_factory.dart';

import '../../support/in_memory_known_hosts.dart';
import '../../support/test_database.dart';
import '../../support/test_sshd.dart';

/// The biometric gate was stored, badged on the Keys screen, and never asked
/// for. These pin the thing that matters: an identity marked as protected is
/// not usable unless the device holder is confirmed — and the check happens
/// before the private key is read, not after.
class _RecordingGate implements BiometricGate {
  new({required this.answer});

  final bool answer;
  int calls = 0;
  String? lastReason;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> confirm({required String reason}) async {
    calls++;
    lastReason = reason;
    return answer;
  }
}

/// Notices whether the private key was ever fetched.
class _WatchingSecrets extends InMemorySecretStore {
  final reads = <String>[];

  @override
  Future<String?> read(String key) {
    reads.add(key);
    return super.read(key);
  }
}

void main() {
  if (!TestSshd.isSupported) {
    test('needs a Unix host with sshd', () {
      markTestSkipped('sshd is unavailable on this platform');
    });
    return;
  }

  late TestSshd server;
  late _WatchingSecrets secrets;

  final identity = SshIdentity(
    id: 'k1',
    name: 'Protected key',
    keyType: SshKeyType.ed25519,
    publicKey: 'ssh-ed25519 AAAA',
    fingerprint: 'SHA256:test',
    createdAt: DateTime.utc(2026),
    requiresBiometrics: true,
  );

  setUp(() async {
    server = await TestSshd.start();
    secrets = _WatchingSecrets();
    await secrets.write(identity.secretRef, TestSshd.clientPrivateKey);
  });

  tearDown(() => server.stop());

  SshConnector connectorWith(BiometricGate gate, SshIdentity saved) {
    return SshConnector(
      hosts: _NoHosts(),
      identities: _OneIdentity(saved),
      secrets: secrets,
      verifier: HostKeyVerifier(InMemoryKnownHostsRepository()),
      prompts: _SilentPrompts(),
      biometrics: gate,
      knownHosts: InMemoryKnownHostsRepository(),
      socketFactory: connectTcpSocket,
    );
  }

  SshHost hostFor(SshIdentity saved) => SshHost(
    id: 'h1',
    label: 'Test server',
    hostname: '127.0.0.1',
    username: TestSshd.username,
    port: server.port,
    identityId: saved.id,
    authMethods: const [SshAuthMethod.publicKey],
  );

  test('a confirmed check lets the key authenticate', () async {
    final gate = _RecordingGate(answer: true);
    final connection = await connectorWith(
      gate,
      identity,
    ).open(hostFor(identity));
    addTearDown(connection.close);

    expect(gate.calls, 1);
    expect(gate.lastReason, contains('Protected key'));
    expect(connection.client.isClosed, isFalse);
  });

  test('a declined check refuses the key, and never reads it', () async {
    final gate = _RecordingGate(answer: false);

    await expectLater(
      connectorWith(gate, identity).open(hostFor(identity)),
      throwsA(isA<Object>()),
      reason: 'with its only method refused, the connection cannot succeed',
    );

    expect(gate.calls, 1);
    expect(
      secrets.reads,
      isNot(contains(identity.secretRef)),
      reason:
          'the check must happen before the key is read — a gate that runs '
          'once the private key is in memory protects nothing',
    );
  });

  test('an unprotected identity is never asked about', () async {
    final plain = identity.copyWith(requiresBiometrics: false);
    final gate = _RecordingGate(answer: true);

    final connection = await connectorWith(gate, plain).open(hostFor(plain));
    addTearDown(connection.close);

    expect(gate.calls, 0);
  });

  test('the default gate refuses rather than allows', () async {
    // Where the platform cannot ask — Linux, the web — a protected identity
    // must stay unusable rather than quietly becoming unprotected.
    const gate = UnavailableBiometricGate();

    expect(await gate.isAvailable, isFalse);
    expect(await gate.confirm(reason: 'anything'), isFalse);
  });
}

/// The connector only ever resolves jump hosts through this, and these tests
/// have none.
class _NoHosts implements SshHostRepository {
  @override
  Future<List<SshHost>> all() async => const [];

  @override
  Stream<List<SshHost>> watch() => const Stream.empty();

  @override
  Future<SshHost?> byId(String id) async => null;

  @override
  Future<void> save(SshHost host) async {}

  @override
  Future<void> markConnected(String id, DateTime at) async {}

  @override
  Future<void> delete(String id) async {}
}

class _OneIdentity implements SshIdentityRepository {
  new(this.identity);

  final SshIdentity identity;

  @override
  Future<List<SshIdentity>> all() async => [identity];

  @override
  Stream<List<SshIdentity>> watch() => Stream.value([identity]);

  @override
  Future<SshIdentity?> byId(String id) async =>
      id == identity.id ? identity : null;

  @override
  Future<void> save(SshIdentity identity) async {}

  @override
  Future<void> delete(String id) async {}
}

/// Declines everything it is asked. These tests are about the biometric gate,
/// and a password prompt appearing would mean the gate had been bypassed.
class _SilentPrompts implements SshPromptService {
  @override
  Future<bool> confirmHostKey(HostKeyCheck check) async => true;

  @override
  Future<HostKeyMismatchChoice> reportHostKeyMismatch(
    HostKeyCheck check,
  ) async => HostKeyMismatchChoice.cancel;

  @override
  Future<String?> requestPassword(SshHost host) async => null;

  @override
  Future<String?> requestPassphrase(SshIdentity identity) async => null;

  @override
  Future<List<String>?> requestUserInfo(
    SshHost host,
    SSHUserInfoRequest request,
  ) async => null;
}
