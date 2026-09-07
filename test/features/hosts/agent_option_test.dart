import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/entities/ssh_host.dart';
import 'package:termino/features/hosts/application/agent_status.dart';
import 'package:termino/features/hosts/presentation/host_editor_screen.dart';
import 'package:termino/infrastructure/ssh/agent/agent_protocol.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// Agent authentication fails in two ways that look exactly like a wrong
/// password: the agent holds no keys, or `SSH_AUTH_SOCK` is unset because the
/// app was started from a launcher rather than a shell. The editor is where a
/// person can still do something about either.
void main() {
  AgentKey key(String type, String comment) {
    Uint8List string(List<int> value) => Uint8List.fromList([
      (value.length >> 24) & 0xff,
      (value.length >> 16) & 0xff,
      (value.length >> 8) & 0xff,
      value.length & 0xff,
      ...value,
    ]);

    return AgentKey(
      blob: Uint8List.fromList([
        ...string(type.codeUnits),
        ...string([1, 2]),
      ]),
      comment: comment,
    );
  }

  /// A container on a platform that has an agent, with [status] as its answer.
  ProviderContainer containerWith(AgentStatus status) => testContainer(
    capabilities: PlatformCapabilities.detect(platform: TargetPlatform.macOS),
    agentStatus: status,
  );

  testWidgets('says how many keys the agent is holding', (tester) async {
    final container = containerWith(
      AgentStatus(
        supported: true,
        socketPath: '/tmp/agent.sock',
        keys: [key('ssh-ed25519', 'me@laptop')],
      ),
    );

    await pumpApp(tester, const HostEditorScreen(), container: container);

    expect(find.text('Use the system SSH agent'), findsOneWidget);
    expect(find.textContaining('1 key available'), findsOneWidget);
  });

  testWidgets('an agent with no keys says so, rather than nothing', (
    tester,
  ) async {
    final container = containerWith(const AgentStatus(supported: true));

    await pumpApp(tester, const HostEditorScreen(), container: container);

    expect(find.textContaining('holds no keys'), findsOneWidget);
  });

  testWidgets('an unset SSH_AUTH_SOCK explains itself', (tester) async {
    final container = containerWith(
      const AgentStatus(
        supported: true,
        problem: 'SSH_AUTH_SOCK is not set, so no agent can be found.',
      ),
    );

    await pumpApp(tester, const HostEditorScreen(), container: container);

    expect(find.textContaining('SSH_AUTH_SOCK'), findsOneWidget);
  });

  testWidgets('the option is absent where there is no agent to reach', (
    tester,
  ) async {
    // Windows speaks to its agent over a named pipe, which Dart cannot open,
    // and a phone has no agent at all. The control is not offered rather than
    // offered and broken.
    final container = testContainer(
      capabilities: PlatformCapabilities.detect(
        platform: TargetPlatform.windows,
      ),
    );

    await pumpApp(tester, const HostEditorScreen(), container: container);

    expect(find.text('Use the system SSH agent'), findsNothing);
  });

  testWidgets('turning it on names the agent among the host methods', (
    tester,
  ) async {
    final container = containerWith(
      AgentStatus(supported: true, keys: [key('ssh-ed25519', 'me@laptop')]),
    );

    await pumpApp(tester, const HostEditorScreen(), container: container);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Box');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Host'),
      'example.com',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'User'), 'me');
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = await container.read(sshHostRepositoryProvider).all();
    expect(saved.single.authMethods, contains(SshAuthMethod.agent));
  });
}
