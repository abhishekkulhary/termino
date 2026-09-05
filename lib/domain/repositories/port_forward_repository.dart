import 'package:termino/domain/entities/port_forward.dart';

/// Stores configured tunnels.
abstract class PortForwardRepository {
  /// Every tunnel.
  Future<List<PortForward>> all();

  /// Emits the full list whenever it changes.
  Stream<List<PortForward>> watch();

  /// Creates or updates a tunnel.
  Future<void> save(PortForward forward);

  /// Deletes a tunnel.
  Future<void> delete(String id);
}
