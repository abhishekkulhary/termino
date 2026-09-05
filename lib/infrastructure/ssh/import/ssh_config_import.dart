/// Reads the user's OpenSSH configuration from disk, where there is one.
///
/// Behind a conditional export because it needs `dart:io`, which the web build
/// does not have. `PlatformCapabilities.canReadUserSshConfig` says whether
/// calling it makes sense.
library;

export 'ssh_config_import_stub.dart'
    if (dart.library.io) 'ssh_config_import_io.dart';
