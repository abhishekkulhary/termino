// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socket_factory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How SSH reaches a server on this platform.
///
/// A direct TCP socket everywhere except the web, where browsers cannot open
/// one and the connection goes through a relay instead. Choosing here rather
/// than inside the backend is what keeps the web from needing a backend of its
/// own: the SSH protocol, and every security decision in it, is identical
/// either way.

@ProviderFor(sshSocketFactory)
final sshSocketFactoryProvider = SshSocketFactoryProvider._();

/// How SSH reaches a server on this platform.
///
/// A direct TCP socket everywhere except the web, where browsers cannot open
/// one and the connection goes through a relay instead. Choosing here rather
/// than inside the backend is what keeps the web from needing a backend of its
/// own: the SSH protocol, and every security decision in it, is identical
/// either way.

final class SshSocketFactoryProvider
    extends
        $FunctionalProvider<
          SshSocketFactory,
          SshSocketFactory,
          SshSocketFactory
        >
    with $Provider<SshSocketFactory> {
  /// How SSH reaches a server on this platform.
  ///
  /// A direct TCP socket everywhere except the web, where browsers cannot open
  /// one and the connection goes through a relay instead. Choosing here rather
  /// than inside the backend is what keeps the web from needing a backend of its
  /// own: the SSH protocol, and every security decision in it, is identical
  /// either way.
  SshSocketFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshSocketFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshSocketFactoryHash();

  @$internal
  @override
  $ProviderElement<SshSocketFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SshSocketFactory create(Ref ref) {
    return sshSocketFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SshSocketFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SshSocketFactory>(value),
    );
  }
}

String _$sshSocketFactoryHash() => r'958e9bb2e899d5e1b76285d89c83e93deed877cb';
