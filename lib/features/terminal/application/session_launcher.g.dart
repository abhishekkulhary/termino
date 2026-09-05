// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_launcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The local shells available on this machine.
///
/// Empty when the platform cannot run one at all, so callers do not need their
/// own platform checks — an empty list and a disabled control are the same
/// thing to the UI.

@ProviderFor(shellProfiles)
final shellProfilesProvider = ShellProfilesProvider._();

/// The local shells available on this machine.
///
/// Empty when the platform cannot run one at all, so callers do not need their
/// own platform checks — an empty list and a disabled control are the same
/// thing to the UI.

final class ShellProfilesProvider
    extends
        $FunctionalProvider<
          List<ShellProfile>,
          List<ShellProfile>,
          List<ShellProfile>
        >
    with $Provider<List<ShellProfile>> {
  /// The local shells available on this machine.
  ///
  /// Empty when the platform cannot run one at all, so callers do not need their
  /// own platform checks — an empty list and a disabled control are the same
  /// thing to the UI.
  ShellProfilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shellProfilesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shellProfilesHash();

  @$internal
  @override
  $ProviderElement<List<ShellProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ShellProfile> create(Ref ref) {
    return shellProfiles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ShellProfile> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ShellProfile>>(value),
    );
  }
}

String _$shellProfilesHash() => r'658bdc755d17f41d9b64aefaf348e37e5e9903ad';

/// Opens sessions. The one place that decides which backend a request needs.

@ProviderFor(SessionLauncher)
final sessionLauncherProvider = SessionLauncherProvider._();

/// Opens sessions. The one place that decides which backend a request needs.
final class SessionLauncherProvider
    extends $NotifierProvider<SessionLauncher, void> {
  /// Opens sessions. The one place that decides which backend a request needs.
  SessionLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionLauncherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionLauncherHash();

  @$internal
  @override
  SessionLauncher create() => SessionLauncher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$sessionLauncherHash() => r'91cc8fd1fe25c9b289c8f692a874099bb74b197e';

/// Opens sessions. The one place that decides which backend a request needs.

abstract class _$SessionLauncher extends $Notifier<void> {
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
