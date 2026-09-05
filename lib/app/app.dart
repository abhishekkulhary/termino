import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:termino/app/router.dart';
import 'package:termino/shared/design/app_theme.dart';

/// The root widget.
class TerminoApp extends StatefulWidget {
  /// Creates the app.
  ///
  /// A [router] may be supplied by tests that need to start at a specific
  /// location.
  const new({super.key, this.router});

  /// The router to use. Built by [buildRouter] when omitted.
  final GoRouter? router;

  @override
  State<TerminoApp> createState() => _TerminoAppState();
}

class _TerminoAppState extends State<TerminoApp> {
  late final GoRouter _router = widget.router ?? buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Termino',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // themeMode is left at its default of ThemeMode.system: Termino follows
      // the platform. An explicit in-app override arrives with the rest of the
      // settings in Phase 6.
      routerConfig: _router,
    );
  }
}
