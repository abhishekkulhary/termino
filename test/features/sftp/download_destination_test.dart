import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/sftp/application/download_destination.dart';

/// Where a download lands is a decision with three inputs — what was chosen
/// before, whether this platform can ask, and whether the remembered folder is
/// still there — and each of them has a way of going wrong quietly.
void main() {
  late List<String> remembered;
  late int timesAsked;

  setUp(() {
    remembered = [];
    timesAsked = 0;
  });

  DownloadDestination resolver({
    required bool canChoose,
    String? answer = '/Users/me/Downloads',
    Set<String> existing = const {'/Users/me/Downloads'},
  }) => DownloadDestination(
    canChoose: canChoose,
    appFolder: () async => '/app/documents',
    chooseFolder: () async {
      timesAsked++;
      return answer;
    },
    directoryExists: existing.contains,
    remember: (path) async => remembered.add(path),
  );

  group('on a platform that can ask', () {
    test('asks the first time and remembers the answer', () async {
      final destination = await resolver(canChoose: true).resolve(null);

      expect(destination, '/Users/me/Downloads');
      expect(timesAsked, 1);
      expect(remembered, ['/Users/me/Downloads']);
    });

    test('does not ask again once it has an answer', () async {
      // A picker that appears on every download is worse than no picker.
      final destination = await resolver(canChoose: true)
          .resolve('/Users/me/Downloads');

      expect(destination, '/Users/me/Downloads');
      expect(timesAsked, 0);
    });

    test('cancelling means no download, not a download elsewhere', () async {
      // Falling back to the app folder here would answer a question the user
      // just declined to answer, and put the file somewhere they would then
      // have to go looking for.
      final destination = await resolver(
        canChoose: true,
        answer: null,
      ).resolve(null);

      expect(destination, isNull);
      expect(remembered, isEmpty);
    });

    test('asks again when the remembered folder has gone', () async {
      // An external disk that is no longer mounted, or a folder since deleted.
      // Without this every download afterwards fails one at a time with a
      // filesystem error and no hint about the cause.
      final destination = await resolver(
        canChoose: true,
        // The disk is gone: nothing is there any more.
        existing: const {},
      ).resolve('/Volumes/Archive');

      expect(destination, '/Users/me/Downloads');
      expect(timesAsked, 1);
    });

    test('"Download to…" asks even when a folder is remembered', () async {
      final destination = await resolver(
        canChoose: true,
        answer: '/tmp/elsewhere',
      ).resolve('/Users/me/Downloads', alwaysAsk: true);

      expect(destination, '/tmp/elsewhere');
      expect(timesAsked, 1);
      expect(remembered, ['/tmp/elsewhere']);
    });

    test('an empty answer counts as a cancellation', () async {
      final destination = await resolver(
        canChoose: true,
        answer: '',
      ).resolve(null);

      expect(destination, isNull);
    });
  });

  group('on a platform that cannot ask', () {
    test('uses the app folder without asking', () async {
      final destination = await resolver(canChoose: false).resolve(null);

      expect(destination, '/app/documents');
      expect(timesAsked, 0);
    });

    test('never asks, even when told to always ask', () async {
      // The row that always asks is not shown there, but a caller must not be
      // able to summon a chooser the platform cannot show.
      final destination = await resolver(canChoose: false)
          .resolve(null, alwaysAsk: true);

      expect(destination, '/app/documents');
      expect(timesAsked, 0);
    });

    test('honours a folder set on some other device', () async {
      // Settings travel through a backup, so a phone can end up holding a
      // desktop's folder. It is used if it happens to exist, and quietly
      // ignored if not.
      final destination = await resolver(
        canChoose: false,
        existing: const {'/shared/files'},
      ).resolve('/shared/files');

      expect(destination, '/shared/files');
    });
  });
}
