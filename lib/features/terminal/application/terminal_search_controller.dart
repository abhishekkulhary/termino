import 'package:flutter/material.dart';
import 'package:termino/domain/terminal/scrollback_search.dart';
import 'package:xterm/xterm.dart';

/// Drives search over one terminal's scrollback, and paints the results.
///
/// `xterm` has no search, but it does have highlights and anchors, so this
/// bridges the two: [ScrollbackSearch] finds matches in the buffer text, and
/// each becomes a `TerminalHighlight` that follows its line as the buffer
/// scrolls. The current match is painted differently from the rest.
class TerminalSearchController extends ChangeNotifier {
  /// Creates a controller searching [terminal], highlighting through
  /// [controller].
  new({
    required this.terminal,
    required this.controller,
    required this.matchColor,
    required this.currentMatchColor,
  });

  /// The terminal whose buffer is searched.
  final Terminal terminal;

  /// The controller that owns the highlights.
  final TerminalController controller;

  /// Colour for matches other than the current one.
  final Color matchColor;

  /// Colour for the match the user is looking at.
  final Color currentMatchColor;

  final List<TerminalHighlight> _highlights = [];

  List<SearchMatch> _matches = const [];
  var _currentIndex = 0;
  String _query = '';
  SearchOptions _options = const SearchOptions();
  String? _error;

  /// Every match of the current query.
  List<SearchMatch> get matches => List.unmodifiable(_matches);

  /// Which match is current, zero-based. Meaningless when there are none.
  int get currentIndex => _currentIndex;

  /// The current query.
  String get query => _query;

  /// The current options.
  SearchOptions get options => _options;

  /// Why the query could not be run, if it could not.
  String? get error => _error;

  /// Whether a search is active.
  bool get isActive => _query.isNotEmpty;

  /// Runs [query] and highlights the results.
  void search(String query, {SearchOptions? options}) {
    _query = query;
    if (options != null) _options = options;

    if (query.isEmpty) {
      _reset();
      notifyListeners();
      return;
    }

    try {
      _matches = ScrollbackSearch.find(_readLines(), query, options: _options);
      _error = null;
    } on InvalidSearchPattern catch (failure) {
      // A half-typed regular expression is normal while someone is typing, so
      // the previous highlights are dropped and the problem is shown rather
      // than the search appearing to do nothing.
      _matches = const [];
      _error = failure.message;
    }

    _currentIndex = 0;
    _repaint();
    notifyListeners();
  }

  /// Re-runs the current query, after the buffer has changed.
  void refresh() {
    if (_query.isNotEmpty) search(_query);
  }

  /// Moves to the next match, wrapping around.
  void next() {
    if (_matches.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _matches.length;
    _repaint();
    notifyListeners();
  }

  /// Moves to the previous match, wrapping around.
  void previous() {
    if (_matches.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _matches.length) % _matches.length;
    _repaint();
    notifyListeners();
  }

  /// Ends the search and removes every highlight.
  void close() {
    _query = '';
    _error = null;
    _reset();
    notifyListeners();
  }

  List<SearchLine> _readLines() {
    final buffer = terminal.buffer;
    return [
      for (var y = 0; y < buffer.height; y++)
        (text: buffer.lines[y].getText(), wrapped: buffer.lines[y].isWrapped),
    ];
  }

  void _repaint() {
    // Only the highlights are dropped here. Clearing the matches too — which
    // an earlier version did — wiped the very results this is about to paint.
    _removeHighlights();

    final buffer = terminal.buffer;
    for (var i = 0; i < _matches.length; i++) {
      final match = _matches[i];
      // A match found before the buffer scrolled may now be out of range.
      if (match.startY >= buffer.height || match.endY >= buffer.height) {
        continue;
      }

      _highlights.add(
        controller.highlight(
          p1: buffer.createAnchor(match.startX, match.startY),
          // The anchor is exclusive at the far end, so the highlight covers
          // the last cell of the match.
          p2: buffer.createAnchor(match.endX + 1, match.endY),
          color: i == _currentIndex ? currentMatchColor : matchColor,
        ),
      );
    }
  }

  void _removeHighlights() {
    for (final highlight in _highlights) {
      highlight.dispose();
    }
    _highlights.clear();
  }

  void _reset() {
    _removeHighlights();
    _matches = const [];
    _currentIndex = 0;
  }

  @override
  void dispose() {
    _reset();
    super.dispose();
  }
}
