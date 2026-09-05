// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forwarding_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The configured tunnels.
///
/// Held in memory for now. Persisting them alongside their host is a small
/// change to the drift schema and belongs with the rest of the settings work
/// in Phase 6.

@ProviderFor(PortForwards)
final portForwardsProvider = PortForwardsProvider._();

/// The configured tunnels.
///
/// Held in memory for now. Persisting them alongside their host is a small
/// change to the drift schema and belongs with the rest of the settings work
/// in Phase 6.
final class PortForwardsProvider
    extends $NotifierProvider<PortForwards, List<PortForward>> {
  /// The configured tunnels.
  ///
  /// Held in memory for now. Persisting them alongside their host is a small
  /// change to the drift schema and belongs with the rest of the settings work
  /// in Phase 6.
  PortForwardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portForwardsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portForwardsHash();

  @$internal
  @override
  PortForwards create() => PortForwards();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PortForward> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PortForward>>(value),
    );
  }
}

String _$portForwardsHash() => r'42a41c27a49304347860a0e8cfecaf5b90f20835';

/// The configured tunnels.
///
/// Held in memory for now. Persisting them alongside their host is a small
/// change to the drift schema and belongs with the rest of the settings work
/// in Phase 6.

abstract class _$PortForwards extends $Notifier<List<PortForward>> {
  List<PortForward> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<PortForward>, List<PortForward>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PortForward>, List<PortForward>>,
              List<PortForward>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The live state of one tunnel.

@ProviderFor(forwardStatus)
final forwardStatusProvider = ForwardStatusFamily._();

/// The live state of one tunnel.

final class ForwardStatusProvider
    extends $FunctionalProvider<ActiveForward?, ActiveForward?, ActiveForward?>
    with $Provider<ActiveForward?> {
  /// The live state of one tunnel.
  ForwardStatusProvider._({
    required ForwardStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'forwardStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$forwardStatusHash();

  @override
  String toString() {
    return r'forwardStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ActiveForward?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ActiveForward? create(Ref ref) {
    final argument = this.argument as String;
    return forwardStatus(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveForward? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveForward?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ForwardStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$forwardStatusHash() => r'31758ce51075154280c96395f0573d31021ae326';

/// The live state of one tunnel.

final class ForwardStatusFamily extends $Family
    with $FunctionalFamilyOverride<ActiveForward?, String> {
  ForwardStatusFamily._()
    : super(
        retry: null,
        name: r'forwardStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The live state of one tunnel.

  ForwardStatusProvider call(String id) =>
      ForwardStatusProvider._(argument: id, from: this);

  @override
  String toString() => r'forwardStatusProvider';
}

/// Runs tunnels, opening one connection per host as needed.

@ProviderFor(ForwardRunner)
final forwardRunnerProvider = ForwardRunnerProvider._();

/// Runs tunnels, opening one connection per host as needed.
final class ForwardRunnerProvider
    extends $NotifierProvider<ForwardRunner, Map<String, ActiveForward>> {
  /// Runs tunnels, opening one connection per host as needed.
  ForwardRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forwardRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forwardRunnerHash();

  @$internal
  @override
  ForwardRunner create() => ForwardRunner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, ActiveForward> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, ActiveForward>>(value),
    );
  }
}

String _$forwardRunnerHash() => r'310a1f58b14370fb4dab9ea0a186ec7631a267f7';

/// Runs tunnels, opening one connection per host as needed.

abstract class _$ForwardRunner extends $Notifier<Map<String, ActiveForward>> {
  Map<String, ActiveForward> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, ActiveForward>, Map<String, ActiveForward>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, ActiveForward>,
                Map<String, ActiveForward>
              >,
              Map<String, ActiveForward>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
