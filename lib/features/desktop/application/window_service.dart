import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:termino/app/providers.dart';
import 'package:termino/core/capabilities/platform_capabilities.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/infrastructure/storage/window_state_store.dart';
import 'package:window_manager/window_manager.dart';

part 'window_service.g.dart';

/// Remembers the window between runs, and refuses to make it useless.
///
/// `window_manager` had been a dependency since the scaffold with no call
/// site, and the `hasWindowManagement` capability existed only to describe it.
/// This is what both were for.
class WindowService with WidgetsBindingObserver {
  /// Creates a service over the given window-state store.
  new(this._store, {required this.enabled});

  /// Whether this platform has a window to manage at all.
  final bool enabled;

  final WindowStateStore _store;

  Timer? _save;

  /// The smallest window the app is usable in.
  ///
  /// An 80-column terminal at the default font is about 620 logical pixels
  /// wide plus the rail; below that the grid starts reflowing and the point of
  /// the app is gone.
  static const minimumSize = Size(720, 480);

  /// The size a first run opens at.
  static const defaultSize = Size(1100, 720);

  /// Applies the remembered window, before the first frame is shown.
  Future<void> restore() async {
    if (!enabled) return;

    try {
      await windowManager.ensureInitialized();
      await windowManager.setMinimumSize(minimumSize);

      final saved = await _store.read();
      final bounds = saved?.boundsWithin(await _displayArea());

      await windowManager.waitUntilReadyToShow(
        WindowOptions(
          size: bounds?.size ?? defaultSize,
          minimumSize: minimumSize,
          title: 'Termino',
          center: bounds == null,
        ),
        () async {
          if (bounds != null) {
            await windowManager.setBounds(bounds);
          }
          if (saved?.maximized ?? false) {
            await windowManager.maximize();
          }
          await windowManager.show();
        },
      );

      WidgetsBinding.instance.addObserver(this);
    } on Object catch (error, stackTrace) {
      // A window that opens at its default size is a far better outcome than
      // an app that does not open. Nothing here is worth failing a launch for.
      Loggers.session.warning('Window restore failed.', error, stackTrace);
    }
  }

  /// Stops listening. For tests and for shutdown.
  void dispose() {
    _save?.cancel();
    if (enabled) WidgetsBinding.instance.removeObserver(this);
  }

  /// Flutter's own notification that the window changed shape.
  ///
  /// Not `window_manager`'s `WindowListener`. That was the obvious choice and
  /// it does not work: the listener attaches without error and no resize,
  /// move or maximise event is ever delivered on macOS, so nothing was ever
  /// saved. `didChangeMetrics` is core Flutter, fires on every resize, and
  /// needs no plugin plumbing to be correct.
  @override
  void didChangeMetrics() => _scheduleSave();

  /// A window that was only moved, never resized, produces no metrics change —
  /// so the position is also captured when the app goes quiet, which is what
  /// happens on the way to being closed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _scheduleSave();
    }
  }

  /// Writes at most once a moment.
  ///
  /// A drag emits a move event per frame; writing each one would put a
  /// database write on every frame of a window drag.
  void _scheduleSave() {
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 400), () => unawaited(_write()));
  }

  Future<void> _write() async {
    try {
      final maximized = await windowManager.isMaximized();
      // The bounds of a maximised window are the screen, which is not where
      // the user would want it restored to. Keep the last unmaximised ones.
      if (maximized) {
        final saved = await _store.read();
        if (saved != null) {
          await _store.write(
            WindowState(bounds: saved.bounds, maximized: true),
          );
        }
        return;
      }
      await _store.write(WindowState(bounds: await windowManager.getBounds()));
    } on Object catch (error) {
      Loggers.session.warning('Window state could not be saved.', error);
    }
  }

  /// The union of every attached display, in logical pixels.
  Future<Rect> _displayArea() async {
    // `window_manager` reports the primary display; that is enough to catch
    // the case this guards against, which is a window remembered on a monitor
    // that is no longer there.
    final primary = await screenRetriever.getPrimaryDisplay();
    final size = primary.size;
    final position = primary.visiblePosition ?? Offset.zero;
    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }
}

/// The window service for this platform.
@Riverpod(keepAlive: true)
WindowService windowService(Ref ref) {
  final service = WindowService(
    WindowStateStore(ref.watch(databaseProvider)),
    enabled: ref.watch(platformCapabilitiesProvider).hasWindowManagement,
  );
  ref.onDispose(service.dispose);
  return service;
}
