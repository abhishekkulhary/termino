import 'dart:io';

import 'package:args/args.dart';
import 'package:termino_relay/allowlist.dart';
import 'package:termino_relay/relay.dart';

/// Starts the relay from the command line.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addMultiOption(
      'allow',
      abbr: 'a',
      help:
          'A destination to permit, as host or host:port. A bare host '
          'allows port 22 only. May be given more than once. Required.',
    )
    ..addOption('address', defaultsTo: '127.0.0.1', help: 'Address to bind.')
    ..addOption(
      'port',
      abbr: 'p',
      defaultsTo: '8022',
      help: 'Port to listen on.',
    )
    ..addOption(
      'token',
      help:
          'A shared secret clients must present as ?token=. Recommended '
          'whenever the relay is reachable from anywhere but this machine.',
    )
    ..addOption(
      'max-connections',
      defaultsTo: '64',
      help: 'Maximum simultaneous tunnels.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exit(64);
  }

  if (args.flag('help')) {
    stdout
      ..writeln('Termino relay — forwards a WebSocket to a TCP port.\n')
      ..writeln(parser.usage);
    return;
  }

  final Allowlist allowlist;
  try {
    allowlist = Allowlist.parse(args.multiOption('allow'));
  } on FormatException catch (error) {
    stderr.writeln('Invalid --allow entry: ${error.source}');
    exit(64);
  }

  if (allowlist.isEmpty) {
    stderr
      ..writeln('Refusing to start without --allow.')
      ..writeln()
      ..writeln(
        'A relay that accepts any destination is an open proxy: '
        'anyone who',
      )
      ..writeln(
        'learns its URL can reach anything this machine can reach, '
        'from this',
      )
      ..writeln("machine's address. Name the hosts you actually need:")
      ..writeln()
      ..writeln('  dart run bin/relay.dart --allow build-01.example.com');
    exit(64);
  }

  final relay = Relay(
    RelayConfig(
      allowlist: allowlist,
      address: args.option('address')!,
      port: int.parse(args.option('port')!),
      token: args.option('token'),
      maxConnections: int.parse(args.option('max-connections')!),
    ),
  );

  await relay.start();
  stdout
    ..writeln(
      'Termino relay listening on '
      '${args.option('address')}:${relay.boundPort}',
    )
    ..writeln('Allowing: $allowlist')
    ..writeln(
      args.option('token') == null
          ? 'No token required — bind to loopback or add --token.'
          : 'A token is required.',
    );

  await ProcessSignal.sigint.watch().first;
  await relay.stop();
}
