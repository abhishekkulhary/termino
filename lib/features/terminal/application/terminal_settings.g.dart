// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// User-adjustable terminal appearance.
///
/// Font size lives here rather than in a widget because pinch-to-zoom on one
/// pane should change every pane: a terminal that is readable in one tab and
/// not another is a bug, not a feature. The full settings screen in Phase 6
/// persists these; for now they last as long as the app run.

@ProviderFor(TerminalFontSize)
final terminalFontSizeProvider = TerminalFontSizeProvider._();

/// User-adjustable terminal appearance.
///
/// Font size lives here rather than in a widget because pinch-to-zoom on one
/// pane should change every pane: a terminal that is readable in one tab and
/// not another is a bug, not a feature. The full settings screen in Phase 6
/// persists these; for now they last as long as the app run.
final class TerminalFontSizeProvider
    extends $NotifierProvider<TerminalFontSize, double> {
  /// User-adjustable terminal appearance.
  ///
  /// Font size lives here rather than in a widget because pinch-to-zoom on one
  /// pane should change every pane: a terminal that is readable in one tab and
  /// not another is a bug, not a feature. The full settings screen in Phase 6
  /// persists these; for now they last as long as the app run.
  TerminalFontSizeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'terminalFontSizeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$terminalFontSizeHash();

  @$internal
  @override
  TerminalFontSize create() => TerminalFontSize();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$terminalFontSizeHash() => r'02802668ec75dad2694f8e6efb9aa1c731333bb6';

/// User-adjustable terminal appearance.
///
/// Font size lives here rather than in a widget because pinch-to-zoom on one
/// pane should change every pane: a terminal that is readable in one tab and
/// not another is a bug, not a feature. The full settings screen in Phase 6
/// persists these; for now they last as long as the app run.

abstract class _$TerminalFontSize extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
