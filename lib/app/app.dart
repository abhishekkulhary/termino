import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:termino/app/router.dart';
import 'package:termino/domain/entities/terminal_settings.dart';
import 'package:termino/features/onboarding/presentation/onboarding_screen.dart';
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

  static ThemeMode _themeMode(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(currentSettingsProvider);

    // Shown in place of the router rather than as a route, so a first-run user
    // cannot navigate past it and the rest of the app never has to wonder
    // whether onboarding has happened.
    if (!settings.onboardingComplete) {
      return MaterialApp(
        title: 'Termino',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _themeMode(settings.themeMode),
        home: const OnboardingScreen(),
      );
    }

    return MaterialApp.router(
      title: 'Termino',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode(settings.themeMode),
      routerConfig: _router,
    );
  }
}
