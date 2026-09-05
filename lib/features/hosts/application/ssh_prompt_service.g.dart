// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ssh_prompt_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The prompt service in use. Overridden in tests.

@ProviderFor(sshPromptService)
final sshPromptServiceProvider = SshPromptServiceProvider._();

/// The prompt service in use. Overridden in tests.

final class SshPromptServiceProvider
    extends
        $FunctionalProvider<
          SshPromptService,
          SshPromptService,
          SshPromptService
        >
    with $Provider<SshPromptService> {
  /// The prompt service in use. Overridden in tests.
  SshPromptServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshPromptServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshPromptServiceHash();

  @$internal
  @override
  $ProviderElement<SshPromptService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SshPromptService create(Ref ref) {
    return sshPromptService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SshPromptService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SshPromptService>(value),
    );
  }
}

String _$sshPromptServiceHash() => r'aa4265ce17ba3f26fc6f6cb77c3779d7b11b3138';
