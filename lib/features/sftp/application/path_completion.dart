/// Where a path being typed splits: the directory to look in, and the fragment
/// being completed inside it.
typedef PathFragment = ({String directory, String prefix});

/// Completing a remote path as it is typed.
///
/// Kept apart from both the widget and the connection so the rules can be
/// tested directly. They are all edge cases — a bare `/`, a trailing slash, a
/// relative fragment, a name that is itself the prefix of another — and none of
/// them is worth discovering through a text field and a live server.
abstract final class PathCompletion {
  /// Splits [input] into the directory to list and the fragment being typed.
  ///
  /// [current] is where the browser is now, which is what a relative fragment
  /// completes against: typing `pro` in `/srv` looks in `/srv`.
  static PathFragment split(String input, {required String current}) {
    if (input.isEmpty) return (directory: current, prefix: '');

    final slash = input.lastIndexOf('/');
    if (slash < 0) return (directory: current, prefix: input);

    // Everything before the last slash names the directory; the root is the one
    // case where that leaves nothing, and the empty string is not a path.
    final directory = slash == 0 ? '/' : input.substring(0, slash);
    return (directory: directory, prefix: input.substring(slash + 1));
  }

  /// The names in [candidates] that [prefix] could grow into.
  ///
  /// Case-sensitive, because the servers this talks to are: offering `Desktop`
  /// for `desk` would complete to a path that does not exist.
  static List<String> matching(Iterable<String> candidates, String prefix) => [
    for (final name in candidates)
      if (name.startsWith(prefix)) name,
  ];

  /// The longest prefix every one of [names] begins with.
  ///
  /// What a shell fills in when Tab is ambiguous: as far as the answer is
  /// certain, and no further.
  static String commonPrefix(Iterable<String> names) {
    final list = names.toList();
    if (list.isEmpty) return '';

    var prefix = list.first;
    for (final name in list.skip(1)) {
      var length = 0;
      while (length < prefix.length &&
          length < name.length &&
          prefix[length] == name[length]) {
        length++;
      }
      prefix = prefix.substring(0, length);
      if (prefix.isEmpty) break;
    }
    return prefix;
  }

  /// What the field should read after Tab, given the directories that match.
  ///
  /// One match completes it and adds the separator, so the next Tab descends.
  /// Several fill in as far as they agree. None leaves the input alone, rather
  /// than deleting what somebody typed.
  static String complete(
    String input, {
    required List<String> names,
    required String current,
  }) {
    if (names.isEmpty) return input;

    final (:directory, :prefix) = split(input, current: current);
    final matches = matching(names, prefix);
    if (matches.isEmpty) return input;

    final completion = matches.length == 1
        ? '${matches.single}/'
        : commonPrefix(matches);

    // A relative fragment stays relative: rewriting `pro` as `/srv/projects`
    // would be correct and would also yank the cursor somewhere unexpected.
    if (!input.contains('/')) return completion;

    return join(directory, completion);
  }

  /// Joins a directory and a name with exactly one separator.
  static String join(String directory, String name) =>
      directory.endsWith('/') ? '$directory$name' : '$directory/$name';
}
