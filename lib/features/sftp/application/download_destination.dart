/// Where a download is written, and who decides.
///
/// Three rules, in order:
///
///  * a folder the user chose before, if it is still there;
///  * otherwise, on a platform with a folder picker, ask — and remember;
///  * otherwise the app's own documents folder, which on a phone is the only
///    answer that means anything.
///
/// The "still there" check is the part that is easy to leave out and expensive
/// to leave out. A remembered folder can be on an external disk that is no
/// longer mounted, or in a directory since deleted; without the check every
/// download after that fails, one at a time, with a filesystem error and no
/// hint about the cause.
class DownloadDestination {
  /// Creates a resolver.
  const new({
    required this.canChoose,
    required this.appFolder,
    required this.chooseFolder,
    required this.directoryExists,
    required this.remember,
  });

  /// Whether this platform can put a folder chooser in front of someone.
  final bool canChoose;

  /// The app's own documents folder, used where nothing else applies.
  final Future<String> Function() appFolder;

  /// Asks for a folder. Null means the user cancelled.
  final Future<String?> Function() chooseFolder;

  /// Whether a path is a directory that exists right now.
  final bool Function(String path) directoryExists;

  /// Stores a chosen folder for next time.
  final Future<void> Function(String path) remember;

  /// Resolves where to write, asking if it has to.
  ///
  /// Returns null only when the user was asked and cancelled — which is an
  /// answer, and means no download rather than a download somewhere arbitrary.
  Future<String?> resolve(String? configured, {bool alwaysAsk = false}) async {
    if (!alwaysAsk &&
        configured != null &&
        configured.isNotEmpty &&
        directoryExists(configured)) {
      return configured;
    }

    if (!canChoose) return await appFolder();

    final chosen = await chooseFolder();
    if (chosen == null || chosen.isEmpty) return null;

    await remember(chosen);
    return chosen;
  }
}
