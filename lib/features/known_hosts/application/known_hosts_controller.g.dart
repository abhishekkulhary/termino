// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'known_hosts_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every host key this app has accepted, newest first.
///
/// A future rather than a stream because the repository has no watch and this
/// list changes only when the user does something to it — trusting a key,
/// forgetting one, running an import. Each of those invalidates it.

@ProviderFor(trustedHostKeys)
final trustedHostKeysProvider = TrustedHostKeysProvider._();

/// Every host key this app has accepted, newest first.
///
/// A future rather than a stream because the repository has no watch and this
/// list changes only when the user does something to it — trusting a key,
/// forgetting one, running an import. Each of those invalidates it.

final class TrustedHostKeysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KnownHost>>,
          List<KnownHost>,
          FutureOr<List<KnownHost>>
        >
    with $FutureModifier<List<KnownHost>>, $FutureProvider<List<KnownHost>> {
  /// Every host key this app has accepted, newest first.
  ///
  /// A future rather than a stream because the repository has no watch and this
  /// list changes only when the user does something to it — trusting a key,
  /// forgetting one, running an import. Each of those invalidates it.
  TrustedHostKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trustedHostKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trustedHostKeysHash();

  @$internal
  @override
  $FutureProviderElement<List<KnownHost>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KnownHost>> create(Ref ref) {
    return trustedHostKeys(ref);
  }
}

String _$trustedHostKeysHash() => r'd1f4fd77dd99ffe6e5b467865a6c0d7256d7aeef';

/// Forgets and imports trusted host keys.
///
/// Named apart from [trustedHostKeys] on purpose: a notifier class and a
/// function of the same name generate the same provider symbol.
///
/// Kept alive, which is not decoration. Auto-disposed, it is created by the
/// `ref.read` that starts a deletion and thrown away before the `await`
/// returns — so the `ref.invalidate` that refreshes the list afterwards throws
/// `UnmountedRefException`, the row is gone from the database and still on
/// screen, and nothing says why.

@ProviderFor(KnownHostsController)
final knownHostsControllerProvider = KnownHostsControllerProvider._();

/// Forgets and imports trusted host keys.
///
/// Named apart from [trustedHostKeys] on purpose: a notifier class and a
/// function of the same name generate the same provider symbol.
///
/// Kept alive, which is not decoration. Auto-disposed, it is created by the
/// `ref.read` that starts a deletion and thrown away before the `await`
/// returns — so the `ref.invalidate` that refreshes the list afterwards throws
/// `UnmountedRefException`, the row is gone from the database and still on
/// screen, and nothing says why.
final class KnownHostsControllerProvider
    extends $NotifierProvider<KnownHostsController, void> {
  /// Forgets and imports trusted host keys.
  ///
  /// Named apart from [trustedHostKeys] on purpose: a notifier class and a
  /// function of the same name generate the same provider symbol.
  ///
  /// Kept alive, which is not decoration. Auto-disposed, it is created by the
  /// `ref.read` that starts a deletion and thrown away before the `await`
  /// returns — so the `ref.invalidate` that refreshes the list afterwards throws
  /// `UnmountedRefException`, the row is gone from the database and still on
  /// screen, and nothing says why.
  KnownHostsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knownHostsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knownHostsControllerHash();

  @$internal
  @override
  KnownHostsController create() => KnownHostsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$knownHostsControllerHash() =>
    r'7f714a30eef399ebea3478a607c31810d38c54b8';

/// Forgets and imports trusted host keys.
///
/// Named apart from [trustedHostKeys] on purpose: a notifier class and a
/// function of the same name generate the same provider symbol.
///
/// Kept alive, which is not decoration. Auto-disposed, it is created by the
/// `ref.read` that starts a deletion and thrown away before the `await`
/// returns — so the `ref.invalidate` that refreshes the list afterwards throws
/// `UnmountedRefException`, the row is gone from the database and still on
/// screen, and nothing says why.

abstract class _$KnownHostsController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
