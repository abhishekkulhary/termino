// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sftp_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The host the file browser is showing, or null when none is chosen.

@ProviderFor(SelectedSftpHost)
final selectedSftpHostProvider = SelectedSftpHostProvider._();

/// The host the file browser is showing, or null when none is chosen.
final class SelectedSftpHostProvider
    extends $NotifierProvider<SelectedSftpHost, SshHost?> {
  /// The host the file browser is showing, or null when none is chosen.
  SelectedSftpHostProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSftpHostProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSftpHostHash();

  @$internal
  @override
  SelectedSftpHost create() => SelectedSftpHost();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SshHost? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SshHost?>(value),
    );
  }
}

String _$selectedSftpHostHash() => r'2efcd6596a63fdf5c88f3154fbc6da8e12f52497';

/// The host the file browser is showing, or null when none is chosen.

abstract class _$SelectedSftpHost extends $Notifier<SshHost?> {
  SshHost? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SshHost?, SshHost?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SshHost?, SshHost?>,
              SshHost?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// A live SFTP session for the selected host.
///
/// Kept alive across navigation so that browsing to the terminal and back does
/// not re-authenticate, and disposed when the host changes or the app shuts
/// down.

@ProviderFor(sftpSession)
final sftpSessionProvider = SftpSessionProvider._();

/// A live SFTP session for the selected host.
///
/// Kept alive across navigation so that browsing to the terminal and back does
/// not re-authenticate, and disposed when the host changes or the app shuts
/// down.

final class SftpSessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<SftpSession?>,
          SftpSession?,
          FutureOr<SftpSession?>
        >
    with $FutureModifier<SftpSession?>, $FutureProvider<SftpSession?> {
  /// A live SFTP session for the selected host.
  ///
  /// Kept alive across navigation so that browsing to the terminal and back does
  /// not re-authenticate, and disposed when the host changes or the app shuts
  /// down.
  SftpSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sftpSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sftpSessionHash();

  @$internal
  @override
  $FutureProviderElement<SftpSession?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SftpSession?> create(Ref ref) {
    return sftpSession(ref);
  }
}

String _$sftpSessionHash() => r'a5c37c2bd1885a9fa21e74039234f933f370629c';
