import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:termino/features/sftp/application/path_completion.dart';
import 'package:termino/features/sftp/application/sftp_session.dart';
import 'package:termino/shared/design/tokens.dart';

/// The current directory, and a way to type a different one.
///
/// Read-only until it is asked for: the path is a label most of the time, and
/// a text field that is always a text field invites a stray tap on a phone into
/// opening a keyboard over the listing.
///
/// Once editing, it behaves the way every other address bar does — Enter goes,
/// Escape puts it back, Tab completes — because a path field that invents its
/// own conventions is a path field people avoid.
class PathField extends StatefulWidget {
  /// Creates the field for [session].
  const new({required this.session, this.completions, super.key});

  /// The browser whose path this is.
  final SftpSession session;

  /// Asks what a partial path could be completed to. Defaults to asking the
  /// server through [session].
  ///
  /// Injected for the same reason the transfer runner takes its file access
  /// that way: a widget test cannot await a socket — the binding's fake-async
  /// zone never lets one finish — so without a seam here the only thing tying
  /// the Tab key to the completion would be reading the code.
  final Future<List<String>> Function(String input)? completions;

  @override
  State<PathField> createState() => PathFieldState();
}

/// Public so the toolbar's "go to path" button can start an edit.
class PathFieldState extends State<PathField> {
  final _controller = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);
  final _menu = MenuController();

  /// Ties the field and its suggestion menu together for hit-testing.
  ///
  /// The menu is in an overlay, so without a shared group a tap on a
  /// suggestion counts as a tap *outside* the field. Confirmed by watching the
  /// callback: ungrouped, choosing a suggestion fires `onTapOutside` first;
  /// grouped, it does not. `MenuAnchor` does not do this for you — its own
  /// dismissal group is its own.
  final _tapGroup = Object();

  var _editing = false;
  List<String> _suggestions = const [];

  /// Which suggestion the arrow keys are on, or null when none is.
  int? _highlighted;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Turns the label into a field, with the current path selected so that
  /// typing replaces it and the arrow keys do not.
  void beginEditing() {
    if (_editing) return;
    _controller
      ..text = widget.session.path
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.session.path.length,
      );
    setState(() {
      _editing = true;
      _suggestions = widget.session.recentPaths;
      _highlighted = null;
    });
    _focus.requestFocus();
    _showSuggestions();
  }

  /// Opens the suggestion menu once there is an anchor to hang it on.
  ///
  /// `beginEditing` is called before the rebuild that creates the `MenuAnchor`,
  /// and a controller with no anchor asserts rather than doing nothing.
  void _showSuggestions() {
    if (_suggestions.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing && !_menu.isOpen) _menu.open();
    });
  }

  void _cancel() {
    if (!_editing) return;
    if (_menu.isOpen) _menu.close();
    setState(() {
      _editing = false;
      _suggestions = const [];
      _highlighted = null;
    });
  }

  void _onFocusChanged() {
    // Losing focus means the user went somewhere else, which is a cancellation
    // rather than a submission: navigating on the way out would take them
    // somewhere they had stopped asking for.
    //
    // Not sufficient on its own — tapping empty space or a plain listing row
    // takes no focus, so the field would sit open — which is what the tap
    // region below is for.
    if (!_focus.hasFocus) _cancel();
  }

  Future<void> _submit(String value) async {
    final target = value.trim();
    _cancel();
    if (target.isEmpty) return;
    await widget.session.open(target);
  }

  Future<List<String>> _completions(String input) =>
      (widget.completions ?? widget.session.completionsFor)(input);

  /// Fills in as far as the answer is certain, and lists the rest.
  Future<void> _complete() async {
    final input = _controller.text;
    final names = await _completions(input);
    if (!mounted) return;

    final completed = PathCompletion.complete(
      input,
      names: names,
      current: widget.session.path,
    );
    if (completed != input) {
      _controller
        ..text = completed
        ..selection = TextSelection.collapsed(offset: completed.length);
    }

    await _refreshSuggestions();
  }

  /// What to offer under the field: matching directories, or — before anything
  /// has been typed — where this session has already been.
  Future<void> _refreshSuggestions() async {
    final input = _controller.text;
    final (:directory, :prefix) = PathCompletion.split(
      input,
      current: widget.session.path,
    );
    final names = await _completions(input);
    if (!mounted) return;

    final matches = PathCompletion.matching(names, prefix);
    setState(() {
      _suggestions = input.isEmpty
          ? widget.session.recentPaths
          : [for (final name in matches) PathCompletion.join(directory, name)];
      _highlighted = null;
    });
    _showSuggestions();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.tab:
        // Taken from the focus traversal deliberately: in a path field Tab
        // means "finish this name", and it is the one place in the app where
        // moving focus is the less useful thing it could do.
        unawaited(_complete());
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        _cancel();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        final chosen = _highlighted;
        unawaited(
          _submit(chosen == null ? _controller.text : _suggestions[chosen]),
        );
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _move(int delta) {
    if (_suggestions.isEmpty) return;
    final next = (_highlighted ?? -1) + delta;
    setState(() {
      _highlighted = next < 0
          ? null
          : next >= _suggestions.length
          ? _suggestions.length - 1
          : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      fontFamily: Fonts.mono,
      fontFamilyFallback: Fonts.monoFallback,
    );

    if (!_editing) {
      return InkWell(
        onTap: beginEditing,
        child: Tooltip(
          message: 'Go to a path',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text(
              widget.session.path,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      );
    }

    return MenuAnchor(
      controller: _menu,
      menuChildren: [
        for (final (index, suggestion) in _suggestions.indexed)
          TapRegion(
            groupId: _tapGroup,
            child: MenuItemButton(
              requestFocusOnHover: false,
              style: index == _highlighted
                  ? MenuItemButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                    )
                  : null,
              onPressed: () => unawaited(_submit(suggestion)),
              child: Text(suggestion, style: style),
            ),
          ),
      ],
      child: TapRegion(
        groupId: _tapGroup,
        // A tap anywhere else puts the path back. Clicking away from a field
        // means leaving it, and leaving it open over the listing is the thing
        // that reads as broken.
        onTapOutside: (_) => _cancel(),
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          style: style,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: '/path/to/somewhere',
          ),
          onChanged: (_) => unawaited(_refreshSuggestions()),
          onSubmitted: (value) => unawaited(_submit(value)),
        ),
      ),
    );
  }
}
