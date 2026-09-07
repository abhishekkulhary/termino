// A real `ssh-agent`, a real `sshd`, and a real authentication between them.
//
// The whole claim of agent support is that the private key never enters this
// process. That cannot be tested against a fake: a fake would be holding the
// key in the same process. So the test starts an agent, loads a fixture key
// into it, and authenticates a server that trusts only that key.
@Timeout(Duration(seconds: 120))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/domain/ssh/host_key_verifier.dart';
import 'package:termino/infrastructure/ssh/agent/agent_protocol.dart';
import 'package:termino/infrastructure/ssh/agent/ssh_agent.dart';
import 'package:termino/infrastructure/ssh/ssh_auth.dart';
import 'package:termino/infrastructure/ssh/ssh_backend.dart';

import '../../../support/in_memory_known_hosts.dart';
import '../../../support/test_agent.dart';
import '../../../support/test_sshd.dart';

void main() {
  if (!TestSshd.isSupported || !TestAgent.isSupported) {
    test('agent tests need a Unix host with sshd and ssh-agent', () {
      markTestSkipped('sshd or ssh-agent is unavailable on this platform');
    });
    return;
  }

  late TestAgent agent;
  late TestSshd server;

  setUp(() async {
    agent = await TestAgent.start([
      '${TestSshd.fixtures}/client_ed25519',
      '${TestSshd.fixtures}/client_rsa',
    ]);
    server = await TestSshd.start();
  });

  tearDown(() async {
    await server.stop();
    await agent.stop();
  });

  test('lists what the agent holds, without the keys themselves', () async {
    final keys = await SshAgent(agent.socketPath).identities();

    expect(keys, hasLength(2));
    expect(keys.map((key) => key.type), contains('ssh-ed25519'));
    expect(keys.map((key) => key.type), contains('ssh-rsa'));

    // The fingerprints are the ones `ssh-keygen -lf` prints for the same files.
    for (final key in keys) {
      expect(key.fingerprint, startsWith('SHA256:'));
    }
  });

  test('the fingerprints match what ssh-add reports', () async {
    // Checked against the agent's own account of itself, so a change in how
    // the blob is read shows up here rather than as a mysterious auth failure.
    final listed = await Process.run(
      'ssh-add',
      ['-l'],
      environment: {'SSH_AUTH_SOCK': agent.socketPath},
    );

    final keys = await SshAgent(agent.socketPath).identities();

    for (final key in keys) {
      expect('${listed.stdout}', contains(key.fingerprint));
    }
  });

  test('signs with a key it will not hand over', () async {
    final client = SshAgent(agent.socketPath);
    final keys = await client.identities();
    final ed25519 = keys.firstWhere((key) => key.type == 'ssh-ed25519');

    final signature = await client.sign(
      ed25519.blob,
      Uint8List.fromList(List<int>.generate(64, (index) => index)),
      ed25519.signFlags,
    );

    expect(signature, isNotEmpty);
    // The signature blob names its own algorithm.
    expect(SSHSignature.getType(signature), 'ssh-ed25519');
  });

  test('an RSA key signs with SHA-2, which modern servers require', () async {
    // `ssh-rsa` names an SHA-1 signature. OpenSSH 8.8 disabled those by
    // default, so asking for the key's own type is an authentication failure
    // against any current server.
    final client = SshAgent(agent.socketPath);
    final keys = await client.identities();
    final rsa = keys.firstWhere((key) => key.type == 'ssh-rsa');

    final signature = await client.sign(
      rsa.blob,
      Uint8List.fromList(List<int>.generate(64, (index) => index)),
      rsa.signFlags,
    );

    expect(SSHSignature.getType(signature), 'rsa-sha2-512');
  });

  test('authenticates a real server with a key it never sees', () async {
    // The server trusts client_ed25519.pub and nothing else, and this process
    // has no copy of the private half — only the agent does.
    final identities = await SshAgent(agent.socketPath).asIdentities();

    final backend = SshBackend(
      host: SshHost(
        id: 'agent-host',
        label: 'Test server',
        hostname: '127.0.0.1',
        username: TestSshd.username,
        port: server.port,
      ),
      verifier: HostKeyVerifier(InMemoryKnownHostsRepository()),
      onHostKeyPrompt: (check) async => true,
      prompts: SshAuthPrompts(identities: identities),
    );

    await backend.start();
    addTearDown(backend.close);

    expect(backend.state.name, 'connected');
  });

  test('no agent at the path is a message, not a crash', () async {
    const missing = SshAgent('/tmp/termino-no-such-agent.sock');

    await expectLater(
      missing.identities(),
      throwsA(
        isA<AgentProtocolException>().having(
          (error) => error.message,
          'message',
          contains('No agent is listening'),
        ),
      ),
    );
  });

  test('finds the agent through SSH_AUTH_SOCK', () async {
    // How the app finds it in practice. An app launched from Finder or a
    // launcher often has no such variable even though an agent is running,
    // which is why the absence is a message and not a crash.
    final found = SshAgent.fromEnvironment({'SSH_AUTH_SOCK': agent.socketPath});
    expect(found, isNotNull);
    expect(await found!.identities(), hasLength(2));

    expect(SshAgent.fromEnvironment(const {}), isNull);
    expect(SshAgent.fromEnvironment(const {'SSH_AUTH_SOCK': ''}), isNull);
  });
}
