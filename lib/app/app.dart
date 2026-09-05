import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:termino/app/router.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/features/settings/application/settings_controller.dart';
import 'package:termino/shared/design/app_theme.dart';

/// The root widget.
class TerminoApp extends ConsumerStatefulWidget {
  /// Creates the app.
  ///
  /// A [router] may be supplied by tests that need to start at a specific
  /// location.
  const new({super.key, this.router});

  /// The router to use. Built by [buildRouter] when omitted.
  final GoRouter? router;

  @override
  ConsumerState<TerminoApp> createState() => _TerminoAppState();
}

class _TerminoAppState extends ConsumerState<TerminoApp> {
  late final GoRouter _router = widget.router ?? buildRouter();

  @override
  void initState() {
    super.initState();
    // Settings start at their defaults and load into them, so the first frame
    // never waits on storage.
    unawaited(ref.read(settingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Termino',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (ref.watch(currentSettingsProvider).themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      routerConfig: _router,
    );
  }
}
