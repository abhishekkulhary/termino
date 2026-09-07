// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the ZModem prompts and progress for every session.
///
/// Deliberately a controller rather than dialogs raised from the multiplexer:
/// the multiplexer runs on bytes arriving from a socket, and code down there
/// has no business reaching for a `BuildContext`. It asks a question, this
/// holds the question, and the widget layer answers it.
///
/// Kept alive because a transfer outlives any one screen — the answer is
/// awaited by the protocol, and an auto-disposed notifier torn down while that
/// await is pending would hang the far end.

@ProviderFor(TransferController)
final transferControllerProvider = TransferControllerProvider._();

/// Owns the ZModem prompts and progress for every session.
///
/// Deliberately a controller rather than dialogs raised from the multiplexer:
/// the multiplexer runs on bytes arriving from a socket, and code down there
/// has no business reaching for a `BuildContext`. It asks a question, this
/// holds the question, and the widget layer answers it.
///
/// Kept alive because a transfer outlives any one screen — the answer is
/// awaited by the protocol, and an auto-disposed notifier torn down while that
/// await is pending would hang the far end.
final class TransferControllerProvider
    extends $NotifierProvider<TransferController, TransferState> {
  /// Owns the ZModem prompts and progress for every session.
  ///
  /// Deliberately a controller rather than dialogs raised from the multiplexer:
  /// the multiplexer runs on bytes arriving from a socket, and code down there
  /// has no business reaching for a `BuildContext`. It asks a question, this
  /// holds the question, and the widget layer answers it.
  ///
  /// Kept alive because a transfer outlives any one screen — the answer is
  /// awaited by the protocol, and an auto-disposed notifier torn down while that
  /// await is pending would hang the far end.
  TransferControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferControllerHash();

  @$internal
  @override
  TransferController create() => TransferController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransferState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransferState>(value),
    );
  }
}

String _$transferControllerHash() =>
    r'94f7a2a65a2815130493a303762d043efd01e433';

/// Owns the ZModem prompts and progress for every session.
///
/// Deliberately a controller rather than dialogs raised from the multiplexer:
/// the multiplexer runs on bytes arriving from a socket, and code down there
/// has no business reaching for a `BuildContext`. It asks a question, this
/// holds the question, and the widget layer answers it.
///
/// Kept alive because a transfer outlives any one screen — the answer is
/// awaited by the protocol, and an auto-disposed notifier torn down while that
/// await is pending would hang the far end.

abstract class _$TransferController extends $Notifier<TransferState> {
  TransferState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransferState, TransferState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransferState, TransferState>,
              TransferState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
