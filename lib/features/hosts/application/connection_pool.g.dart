// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_pool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's shared connections.
///
/// Kept alive for the life of the app: a connection outlives every screen that
/// uses it, which is the entire point of pooling it.

@ProviderFor(sshConnectionPool)
final sshConnectionPoolProvider = SshConnectionPoolProvider._();

/// The app's shared connections.
///
/// Kept alive for the life of the app: a connection outlives every screen that
/// uses it, which is the entire point of pooling it.

final class SshConnectionPoolProvider
    extends
        $FunctionalProvider<
          SshConnectionPool,
          SshConnectionPool,
          SshConnectionPool
        >
    with $Provider<SshConnectionPool> {
  /// The app's shared connections.
  ///
  /// Kept alive for the life of the app: a connection outlives every screen that
  /// uses it, which is the entire point of pooling it.
  SshConnectionPoolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshConnectionPoolProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshConnectionPoolHash();

  @$internal
  @override
  $ProviderElement<SshConnectionPool> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SshConnectionPool create(Ref ref) {
    return sshConnectionPool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SshConnectionPool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SshConnectionPool>(value),
    );
  }
}

String _$sshConnectionPoolHash() => r'5fc26b952fd1500f2a55349a2e6dde10631e054b';
