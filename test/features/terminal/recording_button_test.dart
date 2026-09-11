import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/terminal_session.dart';
import 'package:termino/features/terminal/presentation/recording_button.dart';
import 'package:termino/infrastructure/backends/mock_backend.dart';
import 'package:termino/infrastructure/terminal/output_batcher.dart';

import '../../support/pump.dart';

/// The recorder and both export formats were tested from the start; the
/// control that reaches them was not. Its own doc comment records that the
/// feature once existed with nothing to invoke it, which is the failure this
/// guards against coming back.
///
/// The tests stop at the format sheet. What follows it is `SharePlus`, a
/// platform channel that cannot run under the test binding — so the sheet is
/// both the last thing worth asserting and the last thing reachable.
void main() {
  /// A session whose backend emits [frames].
  ///
  /// Output has to arrive from the *backend* for the recorder to see it —
  /// writing to the terminal directly goes round the tap the recorder sits on
  /// — so a frame with a delay is how a test gets something recorded after
  /// the recording has started.
  Future<TerminalSession> sessionWith(List<MockOutputFrame> frames) async {
    final session = TerminalSession(
      id: 'recording',
      backend: MockBackend(frames: frames, closeWhenDrained: false),
      batcher: const TerminalOutputBatcher(window: Duration.zero),
    );
    await session.start();
    return session;
  }

  Future<void> pumpButton(WidgetTester tester, TerminalSession session) =>
      pumpApp(
        tester,
        Scaffold(
          body: Center(child: RecordingButton(session: session)),
        ),
        size: const Size(600, 400),
      );

  testWidgets('starts recording, and says so while it runs', (tester) async {
    final session = await sessionWith([MockOutputFrame.text('hello\r\n')]);
    addTearDown(session.dispose);

    await pumpButton(tester, session);
    expect(session.isRecording, isFalse);
    expect(find.byTooltip('Record this session'), findsOneWidget);

    await tester.tap(find.byTooltip('Record this session'));
    await tester.pumpAndSettle();

    expect(session.isRecording, isTrue);
    expect(
      find.byTooltip('Stop recording'),
      findsOneWidget,
      reason: 'the same control has to be the way back out',
    );
    expect(
      find.text('00:00'),
      findsOneWidget,
      reason: 'a running recording shows how long it has been running',
    );
  });

  testWidgets('stopping offers both export formats', (tester) async {
    final session = await sessionWith([
      MockOutputFrame.text('before recording\r\n'),
      // Arrives after the recording has started, so there is something in it.
      MockOutputFrame.text(
        'while recording\r\n',
        delay: const Duration(seconds: 2),
      ),
    ]);
    addTearDown(session.dispose);

    await pumpButton(tester, session);
    await tester.tap(find.byTooltip('Record this session'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 3));
    expect(session.recorder!.isEmpty, isFalse);

    await tester.tap(find.byTooltip('Stop recording'));
    await tester.pumpAndSettle();

    expect(session.isRecording, isFalse);
    expect(find.text('Plain text'), findsOneWidget);
    expect(find.text('asciicast'), findsOneWidget);

    // Dismissed rather than chosen: choosing one ends in SharePlus.
    await tester.tapAt(const Offset(300, 20));
    await tester.pumpAndSettle();
  });

  testWidgets('recording nothing says so instead of offering a file', (
    tester,
  ) async {
    final session = await sessionWith([
      MockOutputFrame.text('printed before recording\r\n'),
    ]);
    addTearDown(session.dispose);

    await pumpButton(tester, session);
    await tester.tap(find.byTooltip('Record this session'));
    await tester.pumpAndSettle();

    // Stopped without the program printing anything in between.
    await tester.tap(find.byTooltip('Stop recording'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing was recorded.'), findsOneWidget);
    expect(
      find.text('Plain text'),
      findsNothing,
      reason: 'an empty recording is not worth offering to export',
    );
  });
}
