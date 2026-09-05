import 'package:termino/domain/entities/known_host.dart';

/// Stores the host keys this app has accepted.
abstract class KnownHostsRepository {
  /// Every entry recorded for [host] on [port], across all key types.
  Future<List<KnownHost>> forHost({required String host, required int port});

  /// Every entry, for the settings screen.
  Future<List<KnownHost>> all();

  /// Records a newly trusted key.
  Future<void> add(KnownHost entry);

  /// Replaces the key of the same type for the same host.
  ///
  /// Separate from [add] because it is the dangerous one: it is only ever
  /// reached from the mismatch dialog, after the user has explicitly decided
  /// that the server really did change.
  Future<void> replace(KnownHost entry);

  /// Forgets every key recorded for [host] on [port].
  Future<void> remove({required String host, required int port});

  /// Adds many entries at once, skipping any that are already present.
  /// Returns how many were added. Used by the `~/.ssh/known_hosts` import.
  Future<int> addAll(Iterable<KnownHost> entries);
}
