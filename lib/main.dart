import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termino/app/app.dart';
import 'package:termino/core/logging/app_logger.dart';
import 'package:termino/features/desktop/application/window_service.dart';

/// The app's redacting logger.
///
/// Attached here, which nothing did until now: `AppLogger` and its redaction
/// were written, tested, and never given a listener — so every warning the app
/// raised, including the ones added to explain a failure, went nowhere. A
/// diagnostic that is never printed is not a diagnostic.
final appLogger = AppLogger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.attach();

  // The container is built here rather than by a `ProviderScope` so the window
  // can be sized and placed before the first frame. Restoring it afterwards
  // means the app visibly jumps from its default size to the remembered one
  // every single launch.
  final container = ProviderContainer();
  await container.read(windowServiceProvider).restore();

  runApp(
    UncontrolledProviderScope(container: container, child: const TerminoApp()),
  );
}
