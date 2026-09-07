// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'window_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The window service for this platform.

@ProviderFor(windowService)
final windowServiceProvider = WindowServiceProvider._();

/// The window service for this platform.

final class WindowServiceProvider
    extends $FunctionalProvider<WindowService, WindowService, WindowService>
    with $Provider<WindowService> {
  /// The window service for this platform.
  WindowServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'windowServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$windowServiceHash();

  @$internal
  @override
  $ProviderElement<WindowService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WindowService create(Ref ref) {
    return windowService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WindowService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WindowService>(value),
    );
  }
}

String _$windowServiceHash() => r'a6bc8c71255ef311d78ec519ff57f4324afcf1bb';
