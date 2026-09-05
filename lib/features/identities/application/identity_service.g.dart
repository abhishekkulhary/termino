// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The identity service for the current scope.

@ProviderFor(identityService)
final identityServiceProvider = IdentityServiceProvider._();

/// The identity service for the current scope.

final class IdentityServiceProvider
    extends
        $FunctionalProvider<IdentityService, IdentityService, IdentityService>
    with $Provider<IdentityService> {
  /// The identity service for the current scope.
  IdentityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'identityServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$identityServiceHash();

  @$internal
  @override
  $ProviderElement<IdentityService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IdentityService create(Ref ref) {
    return identityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdentityService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdentityService>(value),
    );
  }
}

String _$identityServiceHash() => r'936933a0e3c3a55ce16558f479cd805f149101d1';
