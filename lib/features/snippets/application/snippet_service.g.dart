// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snippet_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The snippet service for the current scope.

@ProviderFor(snippetService)
final snippetServiceProvider = SnippetServiceProvider._();

/// The snippet service for the current scope.

final class SnippetServiceProvider
    extends $FunctionalProvider<SnippetService, SnippetService, SnippetService>
    with $Provider<SnippetService> {
  /// The snippet service for the current scope.
  SnippetServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'snippetServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$snippetServiceHash();

  @$internal
  @override
  $ProviderElement<SnippetService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SnippetService create(Ref ref) {
    return snippetService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SnippetService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SnippetService>(value),
    );
  }
}

String _$snippetServiceHash() => r'e879e4ec3cb83ba55eeef03a0c1419ef7b53bc68';

/// The snippets offered for [hostId], most recent first.
///
/// A snippet with no host applies everywhere, including local shells; one tied
/// to a host appears only there.

@ProviderFor(snippetsForHost)
final snippetsForHostProvider = SnippetsForHostFamily._();

/// The snippets offered for [hostId], most recent first.
///
/// A snippet with no host applies everywhere, including local shells; one tied
/// to a host appears only there.

final class SnippetsForHostProvider
    extends $FunctionalProvider<List<Snippet>, List<Snippet>, List<Snippet>>
    with $Provider<List<Snippet>> {
  /// The snippets offered for [hostId], most recent first.
  ///
  /// A snippet with no host applies everywhere, including local shells; one tied
  /// to a host appears only there.
  SnippetsForHostProvider._({
    required SnippetsForHostFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'snippetsForHostProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$snippetsForHostHash();

  @override
  String toString() {
    return r'snippetsForHostProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Snippet>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Snippet> create(Ref ref) {
    final argument = this.argument as String?;
    return snippetsForHost(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Snippet> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Snippet>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SnippetsForHostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$snippetsForHostHash() => r'2af83ba3d7617c41cef28a86779d4d1984b68fef';

/// The snippets offered for [hostId], most recent first.
///
/// A snippet with no host applies everywhere, including local shells; one tied
/// to a host appears only there.

final class SnippetsForHostFamily extends $Family
    with $FunctionalFamilyOverride<List<Snippet>, String?> {
  SnippetsForHostFamily._()
    : super(
        retry: null,
        name: r'snippetsForHostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The snippets offered for [hostId], most recent first.
  ///
  /// A snippet with no host applies everywhere, including local shells; one tied
  /// to a host appears only there.

  SnippetsForHostProvider call(String? hostId) =>
      SnippetsForHostProvider._(argument: hostId, from: this);

  @override
  String toString() => r'snippetsForHostProvider';
}
