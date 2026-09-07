// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The local database.
///
/// Overridden in tests with an in-memory connection, which is why nothing
/// constructs `TerminoDatabase` directly.

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// The local database.
///
/// Overridden in tests with an in-memory connection, which is why nothing
/// constructs `TerminoDatabase` directly.

final class DatabaseProvider
    extends
        $FunctionalProvider<TerminoDatabase, TerminoDatabase, TerminoDatabase>
    with $Provider<TerminoDatabase> {
  /// The local database.
  ///
  /// Overridden in tests with an in-memory connection, which is why nothing
  /// constructs `TerminoDatabase` directly.
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<TerminoDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TerminoDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminoDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminoDatabase>(value),
    );
  }
}

String _$databaseHash() => r'239aefc12d7c022002ba456767007bd6d8f810c4';

/// The platform keystore. The only place a secret is ever written.

@ProviderFor(secretStore)
final secretStoreProvider = SecretStoreProvider._();

/// The platform keystore. The only place a secret is ever written.

final class SecretStoreProvider
    extends $FunctionalProvider<SecretStore, SecretStore, SecretStore>
    with $Provider<SecretStore> {
  /// The platform keystore. The only place a secret is ever written.
  SecretStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secretStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secretStoreHash();

  @$internal
  @override
  $ProviderElement<SecretStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SecretStore create(Ref ref) {
    return secretStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecretStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecretStore>(value),
    );
  }
}

String _$secretStoreHash() => r'80276027f8d465251c7112e2913ae87670577a1b';

/// Saved SSH connections.

@ProviderFor(sshHostRepository)
final sshHostRepositoryProvider = SshHostRepositoryProvider._();

/// Saved SSH connections.

final class SshHostRepositoryProvider
    extends
        $FunctionalProvider<
          SshHostRepository,
          SshHostRepository,
          SshHostRepository
        >
    with $Provider<SshHostRepository> {
  /// Saved SSH connections.
  SshHostRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshHostRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshHostRepositoryHash();

  @$internal
  @override
  $ProviderElement<SshHostRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SshHostRepository create(Ref ref) {
    return sshHostRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SshHostRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SshHostRepository>(value),
    );
  }
}

String _$sshHostRepositoryHash() => r'83c8513d10e1fb08481204c33569a3eadda1b467';

/// Trusted host keys.

@ProviderFor(knownHostsRepository)
final knownHostsRepositoryProvider = KnownHostsRepositoryProvider._();

/// Trusted host keys.

final class KnownHostsRepositoryProvider
    extends
        $FunctionalProvider<
          KnownHostsRepository,
          KnownHostsRepository,
          KnownHostsRepository
        >
    with $Provider<KnownHostsRepository> {
  /// Trusted host keys.
  KnownHostsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knownHostsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knownHostsRepositoryHash();

  @$internal
  @override
  $ProviderElement<KnownHostsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KnownHostsRepository create(Ref ref) {
    return knownHostsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KnownHostsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KnownHostsRepository>(value),
    );
  }
}

String _$knownHostsRepositoryHash() =>
    r'4d376aaf6397fd89f0146c181853197d44f5253b';

/// SSH key metadata.

@ProviderFor(sshIdentityRepository)
final sshIdentityRepositoryProvider = SshIdentityRepositoryProvider._();

/// SSH key metadata.

final class SshIdentityRepositoryProvider
    extends
        $FunctionalProvider<
          SshIdentityRepository,
          SshIdentityRepository,
          SshIdentityRepository
        >
    with $Provider<SshIdentityRepository> {
  /// SSH key metadata.
  SshIdentityRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshIdentityRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshIdentityRepositoryHash();

  @$internal
  @override
  $ProviderElement<SshIdentityRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SshIdentityRepository create(Ref ref) {
    return sshIdentityRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SshIdentityRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SshIdentityRepository>(value),
    );
  }
}

String _$sshIdentityRepositoryHash() =>
    r'4f974877fc06a45cd64f119391fabd8668edcd86';

/// Confirms the person holding the device before a protected key is used.
///
/// Refuses outright where the platform cannot ask — Linux, and the web. An
/// identity marked as needing a check must not become usable just because the
/// check is impossible.

@ProviderFor(biometricGate)
final biometricGateProvider = BiometricGateProvider._();

/// Confirms the person holding the device before a protected key is used.
///
/// Refuses outright where the platform cannot ask — Linux, and the web. An
/// identity marked as needing a check must not become usable just because the
/// check is impossible.

final class BiometricGateProvider
    extends $FunctionalProvider<BiometricGate, BiometricGate, BiometricGate>
    with $Provider<BiometricGate> {
  /// Confirms the person holding the device before a protected key is used.
  ///
  /// Refuses outright where the platform cannot ask — Linux, and the web. An
  /// identity marked as needing a check must not become usable just because the
  /// check is impossible.
  BiometricGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricGateHash();

  @$internal
  @override
  $ProviderElement<BiometricGate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BiometricGate create(Ref ref) {
    return biometricGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiometricGate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BiometricGate>(value),
    );
  }
}

String _$biometricGateHash() => r'27b821ce175befe079b66cb742c36b76899a2760';

/// Decides whether a host key may be trusted.

@ProviderFor(hostKeyVerifier)
final hostKeyVerifierProvider = HostKeyVerifierProvider._();

/// Decides whether a host key may be trusted.

final class HostKeyVerifierProvider
    extends
        $FunctionalProvider<HostKeyVerifier, HostKeyVerifier, HostKeyVerifier>
    with $Provider<HostKeyVerifier> {
  /// Decides whether a host key may be trusted.
  HostKeyVerifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostKeyVerifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostKeyVerifierHash();

  @$internal
  @override
  $ProviderElement<HostKeyVerifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HostKeyVerifier create(Ref ref) {
    return hostKeyVerifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HostKeyVerifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HostKeyVerifier>(value),
    );
  }
}

String _$hostKeyVerifierHash() => r'5d75b1d77369f17a1751fd33ddb095ce95013008';

/// Configured tunnels.

@ProviderFor(portForwardRepository)
final portForwardRepositoryProvider = PortForwardRepositoryProvider._();

/// Configured tunnels.

final class PortForwardRepositoryProvider
    extends
        $FunctionalProvider<
          PortForwardRepository,
          PortForwardRepository,
          PortForwardRepository
        >
    with $Provider<PortForwardRepository> {
  /// Configured tunnels.
  PortForwardRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portForwardRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portForwardRepositoryHash();

  @$internal
  @override
  $ProviderElement<PortForwardRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PortForwardRepository create(Ref ref) {
    return portForwardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortForwardRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortForwardRepository>(value),
    );
  }
}

String _$portForwardRepositoryHash() =>
    r'1d08be0aa5289d2118430ae0ab00cde905174611';

/// Saved commands.

@ProviderFor(snippetRepository)
final snippetRepositoryProvider = SnippetRepositoryProvider._();

/// Saved commands.

final class SnippetRepositoryProvider
    extends
        $FunctionalProvider<
          SnippetRepository,
          SnippetRepository,
          SnippetRepository
        >
    with $Provider<SnippetRepository> {
  /// Saved commands.
  SnippetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'snippetRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$snippetRepositoryHash();

  @$internal
  @override
  $ProviderElement<SnippetRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SnippetRepository create(Ref ref) {
    return snippetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SnippetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SnippetRepository>(value),
    );
  }
}

String _$snippetRepositoryHash() => r'c9c2d4c3322ee18631c9e4c61f01cbf79ec665c9';

/// The saved commands, as a live list.

@ProviderFor(snippets)
final snippetsProvider = SnippetsProvider._();

/// The saved commands, as a live list.

final class SnippetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Snippet>>,
          List<Snippet>,
          Stream<List<Snippet>>
        >
    with $FutureModifier<List<Snippet>>, $StreamProvider<List<Snippet>> {
  /// The saved commands, as a live list.
  SnippetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'snippetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$snippetsHash();

  @$internal
  @override
  $StreamProviderElement<List<Snippet>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Snippet>> create(Ref ref) {
    return snippets(ref);
  }
}

String _$snippetsHash() => r'a94405b264fc710e56eac075f5f5e2bdefa94ed7';

/// Reads and writes the user's settings.

@ProviderFor(settingsStore)
final settingsStoreProvider = SettingsStoreProvider._();

/// Reads and writes the user's settings.

final class SettingsStoreProvider
    extends $FunctionalProvider<SettingsStore, SettingsStore, SettingsStore>
    with $Provider<SettingsStore> {
  /// Reads and writes the user's settings.
  SettingsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsStoreHash();

  @$internal
  @override
  $ProviderElement<SettingsStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SettingsStore create(Ref ref) {
    return settingsStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsStore>(value),
    );
  }
}

String _$settingsStoreHash() => r'ee80fccec388d27db5af5bacfcd65714a940b79b';

/// Generates new SSH keys.

@ProviderFor(sshKeyGenerator)
final sshKeyGeneratorProvider = SshKeyGeneratorProvider._();

/// Generates new SSH keys.

final class SshKeyGeneratorProvider
    extends
        $FunctionalProvider<SshKeyGenerator, SshKeyGenerator, SshKeyGenerator>
    with $Provider<SshKeyGenerator> {
  /// Generates new SSH keys.
  SshKeyGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshKeyGeneratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshKeyGeneratorHash();

  @$internal
  @override
  $ProviderElement<SshKeyGenerator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SshKeyGenerator create(Ref ref) {
    return sshKeyGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SshKeyGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SshKeyGenerator>(value),
    );
  }
}

String _$sshKeyGeneratorHash() => r'7f9a35f8198d864c12075a3ffc7ac3665a19125f';

/// The saved connections, as a live list.

@ProviderFor(sshHosts)
final sshHostsProvider = SshHostsProvider._();

/// The saved connections, as a live list.

final class SshHostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SshHost>>,
          List<SshHost>,
          Stream<List<SshHost>>
        >
    with $FutureModifier<List<SshHost>>, $StreamProvider<List<SshHost>> {
  /// The saved connections, as a live list.
  SshHostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshHostsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshHostsHash();

  @$internal
  @override
  $StreamProviderElement<List<SshHost>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SshHost>> create(Ref ref) {
    return sshHosts(ref);
  }
}

String _$sshHostsHash() => r'048a6d37ef689f9cba40e7fadb042abdde9834b6';

/// The stored identities, as a live list.

@ProviderFor(sshIdentities)
final sshIdentitiesProvider = SshIdentitiesProvider._();

/// The stored identities, as a live list.

final class SshIdentitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SshIdentity>>,
          List<SshIdentity>,
          Stream<List<SshIdentity>>
        >
    with
        $FutureModifier<List<SshIdentity>>,
        $StreamProvider<List<SshIdentity>> {
  /// The stored identities, as a live list.
  SshIdentitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sshIdentitiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sshIdentitiesHash();

  @$internal
  @override
  $StreamProviderElement<List<SshIdentity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SshIdentity>> create(Ref ref) {
    return sshIdentities(ref);
  }
}

String _$sshIdentitiesHash() => r'9c5b85b563fc6c6b82aacc2de014d888d5fe08c5';
