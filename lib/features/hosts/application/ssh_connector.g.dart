// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssh_connector.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The connector for the current provider scope.

@ProviderFor(sshConnector)
final sshConnectorProvider = SshConnectorProvider._();

/// The connector for the current provider scope.

final class SshConnectorProvider
    extends $FunctionalProvider<SshConnector, SshConnector, SshConnector>
    with $Provider<SshConnector> {
  /// The connector for the current provider scope.
  SshConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshConnectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshConnectorHash();

  @$internal
  @override
  $ProviderElement<SshConnector> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SshConnector create(Ref ref) {
    return sshConnector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SshConnector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SshConnector>(value),
    );
  }
}

String _$sshConnectorHash() => r'2233d51539717acb027cdbf80963d4387f4a06c7';
