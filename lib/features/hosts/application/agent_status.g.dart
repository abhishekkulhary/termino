// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Asks the agent what it is holding.

@ProviderFor(agentStatus)
final agentStatusProvider = AgentStatusProvider._();

/// Asks the agent what it is holding.

final class AgentStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<AgentStatus>,
          AgentStatus,
          FutureOr<AgentStatus>
        >
    with $FutureModifier<AgentStatus>, $FutureProvider<AgentStatus> {
  /// Asks the agent what it is holding.
  AgentStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agentStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agentStatusHash();

  @$internal
  @override
  $FutureProviderElement<AgentStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AgentStatus> create(Ref ref) {
    return agentStatus(ref);
  }
}

String _$agentStatusHash() => r'57c4a08a939dff578e76d2de4d97a11c2865e2c4';
