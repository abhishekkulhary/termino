/// Turns a hostname into something this platform can actually connect to.
///
/// `multicast_dns` needs `dart:io`, which the web build does not have, and a
/// plain import would be a compile failure rather than a runtime one. The web
/// resolves nothing itself — it reaches hosts through a relay, and the relay
/// does the lookup — so its stub hands the name straight back.
library;

export 'hostname_resolver_stub.dart'
    if (dart.library.io) 'hostname_resolver_io.dart';
