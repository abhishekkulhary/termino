import 'package:freezed_annotation/freezed_annotation.dart';

part 'port_forward.freezed.dart';
part 'port_forward.g.dart';

/// Which direction a tunnel runs.
enum PortForwardKind {
  /// `-L`: a port here is forwarded to a host reachable from the server.
  local,

  /// `-R`: a port on the server is forwarded back to a host reachable here.
  remote,

  /// `-D`: a SOCKS proxy here, with connections made from the server.
  dynamic;

  /// The OpenSSH flag, which is what people recognise.
  String get flag => switch (this) {
    PortForwardKind.local => '-L',
    PortForwardKind.remote => '-R',
    PortForwardKind.dynamic => '-D',
  };

  /// A label for the UI.
  String get label => switch (this) {
    PortForwardKind.local => 'Local',
    PortForwardKind.remote => 'Remote',
    PortForwardKind.dynamic => 'Dynamic (SOCKS)',
  };

  /// Whether this kind needs a destination host and port.
  bool get needsDestination => this != PortForwardKind.dynamic;
}

/// Whether a tunnel is currently carrying traffic.
enum PortForwardStatus {
  /// Configured but not running.
  stopped,

  /// Being established.
  starting,

  /// Listening and forwarding.
  active,

  /// Stopped because something went wrong.
  failed;

  /// Whether the tunnel is doing anything.
  bool get isRunning =>
      this == PortForwardStatus.starting || this == PortForwardStatus.active;
}

/// A configured tunnel.
@freezed
abstract class PortForward with _$PortForward {
  /// Creates a tunnel definition.
  const factory({
    required String id,
    required String hostId,
    required PortForwardKind kind,

    /// The port that is listened on — here for local and dynamic, on the
    /// server for remote.
    required int listenPort,

    /// Where traffic is sent. Unused for a dynamic forward, which decides per
    /// connection from the SOCKS request.
    String? destinationHost,

    /// The port traffic is sent to.
    int? destinationPort,

    /// The address to bind. `127.0.0.1` keeps a local forward private to this
    /// machine, which is the right default — binding `0.0.0.0` exposes it to
    /// the whole network.
    @Default('127.0.0.1') String bindAddress,

    /// What the user calls it.
    String? label,
  }) = _PortForward;

  const new _();

  /// Restores a tunnel from stored JSON.
  factory fromJson(Map<String, dynamic> json) => _$PortForwardFromJson(json);

  /// The OpenSSH argument, as a user would type it.
  String get argument => switch (kind) {
    PortForwardKind.dynamic => '-D $bindAddress:$listenPort',
    _ =>
      '${kind.flag} $bindAddress:$listenPort:'
          '${destinationHost ?? ''}:${destinationPort ?? ''}',
  };

  /// A short description for the list.
  String get summary => switch (kind) {
    PortForwardKind.local =>
      'localhost:$listenPort → $destinationHost:$destinationPort',
    PortForwardKind.remote =>
      'server:$listenPort → $destinationHost:$destinationPort',
    PortForwardKind.dynamic => 'SOCKS proxy on localhost:$listenPort',
  };

  /// Whether this definition is complete enough to start.
  bool get isValid {
    if (listenPort < 1 || listenPort > 65535) return false;
    if (!kind.needsDestination) return true;
    final port = destinationPort;
    return (destinationHost?.isNotEmpty ?? false) &&
        port != null &&
        port >= 1 &&
        port <= 65535;
  }
}
