import 'package:termino/domain/entities/known_host.dart';
import 'package:termino/domain/repositories/known_hosts_repository.dart';

/// A known-hosts store held in memory, for tests.
class InMemoryKnownHostsRepository implements KnownHostsRepository {
  /// Creates a store, optionally pre-populated.
  new([Iterable<KnownHost> initial = const []]) {
    entries.addAll(initial);
  }

  /// Everything currently stored.
  final List<KnownHost> entries = [];

  @override
  Future<List<KnownHost>> forHost({
    required String host,
    required int port,
  }) async => entries
      .where((entry) => entry.host == host && entry.port == port)
      .toList();

  @override
  Future<List<KnownHost>> all() async => List.of(entries);

  @override
  Future<void> add(KnownHost entry) async => entries.add(entry);

  @override
  Future<void> replace(KnownHost entry) async {
    entries.removeWhere((existing) => existing.describesSameKeyAs(entry));
    entries.add(entry);
  }

  @override
  Future<void> remove({required String host, required int port}) async {
    entries.removeWhere((entry) => entry.host == host && entry.port == port);
  }

  @override
  Future<int> addAll(Iterable<KnownHost> incoming) async {
    var added = 0;
    for (final entry in incoming) {
      final duplicate = entries.any(
        (existing) =>
            existing.describesSameKeyAs(entry) &&
            existing.fingerprint == entry.fingerprint,
      );
      if (duplicate) continue;
      entries.add(entry);
      added++;
    }
    return added;
  }
}
