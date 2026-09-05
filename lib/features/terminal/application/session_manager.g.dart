// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns every open session: creation, activation, closing and disposal.
///
/// Sessions outlive the widgets showing them — switching tabs must not kill a
/// running command — so they are held here rather than in widget state, and
/// disposed deterministically when closed or when the app shuts down.

@ProviderFor(SessionManager)
final sessionManagerProvider = SessionManagerProvider._();

/// Owns every open session: creation, activation, closing and disposal.
///
/// Sessions outlive the widgets showing them — switching tabs must not kill a
/// running command — so they are held here rather than in widget state, and
/// disposed deterministically when closed or when the app shuts down.
final class SessionManagerProvider
    extends $NotifierProvider<SessionManager, SessionsState> {
  /// Owns every open session: creation, activation, closing and disposal.
  ///
  /// Sessions outlive the widgets showing them — switching tabs must not kill a
  /// running command — so they are held here rather than in widget state, and
  /// disposed deterministically when closed or when the app shuts down.
  SessionManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionManagerHash();

  @$internal
  @override
  SessionManager create() => SessionManager();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionsState>(value),
    );
  }
}

String _$sessionManagerHash() => r'8c9aa7665f6a15d02ff6db37ce2c2860e5f15926';

/// Owns every open session: creation, activation, closing and disposal.
///
/// Sessions outlive the widgets showing them — switching tabs must not kill a
/// running command — so they are held here rather than in widget state, and
/// disposed deterministically when closed or when the app shuts down.

abstract class _$SessionManager extends $Notifier<SessionsState> {
  SessionsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SessionsState, SessionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionsState, SessionsState>,
              SessionsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
