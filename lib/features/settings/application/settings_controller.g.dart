// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's settings.
///
/// Synchronous, with an explicit [load]. An async notifier looked like the
/// natural fit and was not: its `build` re-ran while writes were in flight and
/// raced the state assignments after them, so every other change was silently
/// discarded. Starting from the defaults and loading into them has no such
/// window, and costs one frame of default appearance at startup.

@ProviderFor(Settings)
final settingsProvider = SettingsProvider._();

/// The user's settings.
///
/// Synchronous, with an explicit [load]. An async notifier looked like the
/// natural fit and was not: its `build` re-ran while writes were in flight and
/// raced the state assignments after them, so every other change was silently
/// discarded. Starting from the defaults and loading into them has no such
/// window, and costs one frame of default appearance at startup.
final class SettingsProvider
    extends $NotifierProvider<Settings, TerminalSettings> {
  /// The user's settings.
  ///
  /// Synchronous, with an explicit [load]. An async notifier looked like the
  /// natural fit and was not: its `build` re-ran while writes were in flight and
  /// raced the state assignments after them, so every other change was silently
  /// discarded. Starting from the defaults and loading into them has no such
  /// window, and costs one frame of default appearance at startup.
  SettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsHash();

  @$internal
  @override
  Settings create() => Settings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminalSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminalSettings>(value),
    );
  }
}

String _$settingsHash() => r'36dd685b7773cc98cffcb367e4985c1c94f610a2';

/// The user's settings.
///
/// Synchronous, with an explicit [load]. An async notifier looked like the
/// natural fit and was not: its `build` re-ran while writes were in flight and
/// raced the state assignments after them, so every other change was silently
/// discarded. Starting from the defaults and loading into them has no such
/// window, and costs one frame of default appearance at startup.

abstract class _$Settings extends $Notifier<TerminalSettings> {
  TerminalSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TerminalSettings, TerminalSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TerminalSettings, TerminalSettings>,
              TerminalSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The settings as a plain value.

@ProviderFor(currentSettings)
final currentSettingsProvider = CurrentSettingsProvider._();

/// The settings as a plain value.

final class CurrentSettingsProvider
    extends
        $FunctionalProvider<
          TerminalSettings,
          TerminalSettings,
          TerminalSettings
        >
    with $Provider<TerminalSettings> {
  /// The settings as a plain value.
  CurrentSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSettingsHash();

  @$internal
  @override
  $ProviderElement<TerminalSettings> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TerminalSettings create(Ref ref) {
    return currentSettings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminalSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminalSettings>(value),
    );
  }
}

String _$currentSettingsHash() => r'027e697cea3c8e38c92438c5c87ef8ce43019237';

/// The palette to paint terminals with, honouring the user's choice and
/// falling back to one that matches the app theme.

@ProviderFor(activePalette)
final activePaletteProvider = ActivePaletteFamily._();

/// The palette to paint terminals with, honouring the user's choice and
/// falling back to one that matches the app theme.

final class ActivePaletteProvider
    extends
        $FunctionalProvider<TerminalPalette, TerminalPalette, TerminalPalette>
    with $Provider<TerminalPalette> {
  /// The palette to paint terminals with, honouring the user's choice and
  /// falling back to one that matches the app theme.
  ActivePaletteProvider._({
    required ActivePaletteFamily super.from,
    required Brightness super.argument,
  }) : super(
         retry: null,
         name: r'activePaletteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activePaletteHash();

  @override
  String toString() {
    return r'activePaletteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TerminalPalette> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TerminalPalette create(Ref ref) {
    final argument = this.argument as Brightness;
    return activePalette(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminalPalette value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminalPalette>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActivePaletteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activePaletteHash() => r'90ee505a68e0a69b153612ac1e760665c68dd805';

/// The palette to paint terminals with, honouring the user's choice and
/// falling back to one that matches the app theme.

final class ActivePaletteFamily extends $Family
    with $FunctionalFamilyOverride<TerminalPalette, Brightness> {
  ActivePaletteFamily._()
    : super(
        retry: null,
        name: r'activePaletteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The palette to paint terminals with, honouring the user's choice and
  /// falling back to one that matches the app theme.

  ActivePaletteProvider call(Brightness brightness) =>
      ActivePaletteProvider._(argument: brightness, from: this);

  @override
  String toString() => r'activePaletteProvider';
}
