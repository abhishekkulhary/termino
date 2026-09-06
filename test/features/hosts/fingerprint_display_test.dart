import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/ssh/host_key_verdict.dart';
import 'package:termino/features/hosts/presentation/host_key_dialogs.dart';

import '../../support/pump.dart';

/// The fingerprint is the whole security decision these dialogs ask about, so
/// how it is shown — and what gets copied — is worth pinning down.
void main() {
  const fingerprint = 'SHA256:9pTx0hLKq1n7bWvR3sZmCd8yQeUj4aXfP2kNvB6tGwo';

  group('groupFingerprint', () {
    test('keeps the algorithm prefix and groups the rest in fours', () {
      expect(
        groupFingerprint(fingerprint),
        'SHA256: 9pTx 0hLK q1n7 bWvR 3sZm Cd8y QeUj 4aXf P2kN vB6t Gwo',
      );
    });

    test('changes nothing but the spaces', () {
      expect(
        groupFingerprint(fingerprint).replaceAll(' ', ''),
        fingerprint.replaceAll(' ', ''),
        reason: 'grouping may not alter a single character of the value',
      );
    });

    test('handles a value with no prefix', () {
      expect(groupFingerprint('abcdefgh'), 'abcd efgh');
    });

    test('handles a length that is not a multiple of four', () {
      expect(groupFingerprint('abcde'), 'abcd e');
    });

    test('handles an empty value without throwing', () {
      expect(groupFingerprint(''), '');
    });
  });

  testWidgets('the clipboard gets the real fingerprint, ungrouped', (
    tester,
  ) async {
    // If the grouping ever leaked into the clipboard, someone pasting it
    // against a server's own output would see a mismatch that is not one —
    // and might reasonably conclude the host key had changed.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showTrustHostKeyDialog(
              context,
              const HostKeyCheck(
                verdict: HostKeyVerdict.unknown,
                host: 'build-01.example.com',
                port: 22,
                keyType: 'ssh-ed25519',
                fingerprint: fingerprint,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      animations: false,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('9pTx 0hLK'),
      findsOneWidget,
      reason: 'shown grouped, for comparing by eye',
    );

    await tester.tap(find.byTooltip('Copy fingerprint'));
    await tester.pumpAndSettle();

    expect(copied, fingerprint);
  });
}
