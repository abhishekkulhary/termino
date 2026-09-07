import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/transfer_controller.dart';
import 'package:termino/features/terminal/application/zmodem_transfers.dart';
import 'package:termino/features/terminal/presentation/transfer_overlay.dart';
import 'package:termino/shared/design/tokens.dart';
import 'package:termino/shared/widgets/neon.dart';

import '../../support/pump.dart';
import '../../support/test_database.dart';

/// The prompt is the only thing standing between a machine on the other end of
/// a socket and this device's disk, so what it shows and which session it shows
/// it on both matter.
void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('termino-ui'));
  tearDown(() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  testWidgets('an offer names the file and says who is offering it', (
    tester,
  ) async {
    final container = testContainer();
    final controller = container.read(transferControllerProvider.notifier);

    await pumpApp(
      tester,
      const TransferOverlay(sessionId: 'session-1'),
      container: container,
    );

    // Nothing at all until there is something to say.
    expect(find.byType(NeonPanel), findsNothing);

    unawaited(
      controller.askToReceive(
        const IncomingFile(name: 'reports/q3.pdf', size: 2048),
        sessionId: 'session-1',
      ),
    );
    await tester.pumpAndSettle();

    // The safe name, not the path the far end sent.
    expect(find.text('q3.pdf'), findsOneWidget);
    expect(find.textContaining('2.0 KiB'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('a prompt for another session stays out of the way', (
    tester,
  ) async {
    final container = testContainer();
    final controller = container.read(transferControllerProvider.notifier);

    await pumpApp(
      tester,
      const TransferOverlay(sessionId: 'session-1'),
      container: container,
    );

    unawaited(
      controller.askToReceive(
        const IncomingFile(name: 'elsewhere.txt', size: 10),
        sessionId: 'session-2',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('elsewhere.txt'), findsNothing);
  });

  testWidgets('declining answers the protocol', (tester) async {
    final container = testContainer();
    final controller = container.read(transferControllerProvider.notifier);

    await pumpApp(
      tester,
      const TransferOverlay(sessionId: 'session-1'),
      container: container,
    );

    final answer = controller.askToReceive(
      const IncomingFile(name: 'notes.txt', size: 10),
      sessionId: 'session-1',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    expect(await answer, isNull);
    expect(find.text('notes.txt'), findsNothing);
  });

  testWidgets('saving shows progress and then where the file went', (
    tester,
  ) async {
    final container = testContainer();
    final controller = container.read(transferControllerProvider.notifier)
      ..destinationOverride = () async => directory;

    await pumpApp(
      tester,
      const TransferOverlay(sessionId: 'session-1'),
      container: container,
    );

    final answer = controller.askToReceive(
      const IncomingFile(name: 'notes.txt', size: 100),
      sessionId: 'session-1',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // The sink is deliberately not closed here: it was opened inside the test
    // binding's fake-async zone, so the close would never complete. What the
    // file ends up containing is asserted in transfer_controller_test.dart,
    // which runs on the real event loop.
    expect(await answer, isNotNull);

    controller.report('notes.txt', 50);
    await tester.pumpAndSettle();

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.5, 0.001));

    controller.finish();
    await tester.pumpAndSettle();

    // Where it went, because a received file nobody can find has not really
    // been received.
    expect(find.text('Saved notes.txt'), findsOneWidget);
    expect(find.textContaining(directory.path), findsOneWidget);
  });

  testWidgets('a size the far end never gave shows an indeterminate bar', (
    tester,
  ) async {
    final container = testContainer();
    final controller = container.read(transferControllerProvider.notifier)
      ..destinationOverride = () async => directory;

    await pumpApp(
      tester,
      const TransferOverlay(sessionId: 'session-1'),
      container: container,
    );

    final answer = controller.askToReceive(
      const IncomingFile(name: 'stream.bin', size: 0),
      sessionId: 'session-1',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    // Timed pumps rather than `pumpAndSettle`: an indeterminate progress bar
    // animates forever by design, so there is nothing here to settle to. That
    // is the very thing being asserted.
    await tester.pump();
    await tester.pump(Motion.normal);
    // The sink is deliberately not closed here: it was opened inside the test
    // binding's fake-async zone, so the close would never complete. What the
    // file ends up containing is asserted in transfer_controller_test.dart,
    // which runs on the real event loop.
    expect(await answer, isNotNull);

    controller.report('stream.bin', 4096);
    await tester.pump();

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, isNull, reason: 'zero of an unknown total is not 0%');
  });

  testWidgets('a failure is explained rather than swallowed', (tester) async {
    final container = testContainer();
    final controller = container.read(transferControllerProvider.notifier)
      ..destinationOverride = () async =>
          throw const FileSystemException('read-only');

    await pumpApp(
      tester,
      const TransferOverlay(sessionId: 'session-1'),
      container: container,
    );

    final answer = controller.askToReceive(
      const IncomingFile(name: 'notes.txt', size: 10),
      sessionId: 'session-1',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(await answer, isNull);
    expect(find.textContaining('Could not save the file'), findsOneWidget);
  });
}
