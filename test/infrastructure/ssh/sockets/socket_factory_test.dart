import 'package:flutter_test/flutter_test.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/domain/backends/terminal_backend.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/infrastructure/ssh/sockets/socket_factory_provider.dart';
import 'package:termino/infrastructure/ssh/ssh_socket_factory.dart';

import '../../../support/test_database.dart';

const _onTheWeb = PlatformCapabilities(
  canRunLocalShell: false,
  canUseSsh: true,
  needsRelay: true,
  canUseBiometrics: false,
  hasWindowManagement: false,
  canReadUserSshConfig: false,
);

const _onADesktop = PlatformCapabilities(
  canRunLocalShell: true,
  canUseSsh: true,
  canUseBiometrics: true,
  hasWindowManagement: true,
  canReadUserSshConfig: true,
);

void main() {
  test('a native build connects directly', () {
    final container = testContainer(capabilities: _onADesktop);
    addTearDown(container.dispose);

    expect(
      container.read(sshSocketFactoryProvider),
      same(connectTcpSocket),
      reason: 'no relay is involved anywhere but the web',
    );
  });

  test('the web build without a relay explains itself', () async {
    final container = testContainer(capabilities: _onTheWeb);
    addTearDown(container.dispose);

    final factory = container.read(sshSocketFactoryProvider);

    await expectLater(
      factory('example.com', 22),
      throwsA(
        isA<TerminalBackendFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              TerminalBackendFailureKind.unsupported,
            )
            .having(
              (failure) => failure.message,
              'message',
              contains('Set a relay address'),
            ),
      ),
    );
  });

  test('a relay address that is not a websocket URL is refused', () async {
    final container = testContainer(capabilities: _onTheWeb);
    addTearDown(container.dispose);
    await container
        .read(settingsProvider.notifier)
        .setRelayUrl('https://relay.example.com/ssh');

    await expectLater(
      container.read(sshSocketFactoryProvider)('example.com', 22),
      throwsA(
        isA<TerminalBackendFailure>().having(
          (failure) => failure.message,
          'message',
          contains('ws:// or wss://'),
        ),
      ),
    );
  });

  test('an unreachable relay fails as a network error, not a crash', () async {
    final container = testContainer(capabilities: _onTheWeb);
    addTearDown(container.dispose);
    await container
        .read(settingsProvider.notifier)
        .setRelayUrl('ws://127.0.0.1:1/ssh');

    await expectLater(
      container.read(sshSocketFactoryProvider)(
        'example.com',
        22,
        timeout: const Duration(seconds: 3),
      ),
      throwsA(
        isA<TerminalBackendFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              TerminalBackendFailureKind.network,
            )
            .having(
              (failure) => failure.message,
              'message',
              isNot(contains('Exception')),
            ),
      ),
    );
  });
}
