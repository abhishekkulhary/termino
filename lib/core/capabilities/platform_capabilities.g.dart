// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_capabilities.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The capabilities of the platform the app is running on.
///
/// Override this in tests and in the widget catalogue to render a platform you
/// are not running on.

@ProviderFor(platformCapabilities)
final platformCapabilitiesProvider = PlatformCapabilitiesProvider._();

/// The capabilities of the platform the app is running on.
///
/// Override this in tests and in the widget catalogue to render a platform you
/// are not running on.

final class PlatformCapabilitiesProvider
    extends
        $FunctionalProvider<
          PlatformCapabilities,
          PlatformCapabilities,
          PlatformCapabilities
        >
    with $Provider<PlatformCapabilities> {
  /// The capabilities of the platform the app is running on.
  ///
  /// Override this in tests and in the widget catalogue to render a platform you
  /// are not running on.
  PlatformCapabilitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformCapabilitiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformCapabilitiesHash();

  @$internal
  @override
  $ProviderElement<PlatformCapabilities> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlatformCapabilities create(Ref ref) {
    return platformCapabilities(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlatformCapabilities value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlatformCapabilities>(value),
    );
  }
}

String _$platformCapabilitiesHash() =>
    r'cf54ecd2f59281c7d20cec462bb89e294fe63fda';
