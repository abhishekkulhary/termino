import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/domain/ssh/ssh_config.dart';

/// A browser has no `~/.ssh` to read.
class SshConfigImporter {
  /// Creates an importer that finds nothing.
  ///
  /// Takes the same arguments as the `dart:io` implementation, because the two
  /// must be interchangeable: a signature that differs compiles on one target
  /// and fails on the other.
  // The parameter exists so both conditional-export variants have identical
  // signatures; there is simply nothing to do with it in a browser.
  // ignore: avoid_unused_constructor_parameters
  const new({String? homeDirectory});

  /// Always false: there is no home directory here.
  bool get isAvailable => false;

  /// Always empty.
  Future<List<SshConfigHost>> readConfig() async => const [];

  /// Always empty.
  Future<List<KnownHost>> readKnownHosts({
    required Iterable<({String host, int port})> hosts,
  }) async => const [];
}
