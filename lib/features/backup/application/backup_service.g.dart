// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Writes and reads backups.
///
/// Kept alive: a restore is a sequence of awaited writes, and an auto-disposed
/// controller is thrown away part-way through one.

@ProviderFor(BackupService)
final backupServiceProvider = BackupServiceProvider._();

/// Writes and reads backups.
///
/// Kept alive: a restore is a sequence of awaited writes, and an auto-disposed
/// controller is thrown away part-way through one.
final class BackupServiceProvider
    extends $NotifierProvider<BackupService, void> {
  /// Writes and reads backups.
  ///
  /// Kept alive: a restore is a sequence of awaited writes, and an auto-disposed
  /// controller is thrown away part-way through one.
  BackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupServiceHash();

  @$internal
  @override
  BackupService create() => BackupService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$backupServiceHash() => r'81a136702ea0a2595d8d47e337205fbf1d0fbda7';

/// Writes and reads backups.
///
/// Kept alive: a restore is a sequence of awaited writes, and an auto-disposed
/// controller is thrown away part-way through one.

abstract class _$BackupService extends $Notifier<void> {
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
