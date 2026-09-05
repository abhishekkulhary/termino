// These tests step through a search one action at a time, asserting between
// the steps. Cascading them, as the lint suggests, would hide what is checked.
// ignore_for_file: cascade_invocations

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termino/domain/terminal/scrollback_search.dart';
import 'package:termino/features/terminal/application/terminal_search_controller.dart';
import 'package:xterm/xterm.dart';

void main() {
  late Terminal terminal;
  late TerminalController controller;
  late TerminalSearchController search;

  setUp(() {
    terminal = Terminal();
    controller = TerminalController();
    search = TerminalSearchController(
      terminal: terminal,
      controller: controller,
      matchColor: const Color(0xFF334455),
      currentMatchColor: const Color(0xFFFFCC00),
    );
  });

  tearDown(() {
    search.dispose();
    controller.dispose();
  });

  void write(String text) => terminal.write(text);

  test('finds nothing before a search runs', () {
    expect(search.matches, isEmpty);
    expect(search.isActive, isFalse);
  });

  test('finds matches in the buffer and highlights them', () {
    write('alpha\r\nbeta\r\nalpha\r\n');

    search.search('alpha');

    expect(search.matches, hasLength(2));
    expect(
      controller.highlights,
      hasLength(2),
      reason: 'every match paints a highlight',
    );
  });

  test('the current match is highlighted differently', () {
    write('one\r\none\r\n');

    search.search('one');

    final colors = controller.highlights.map((h) => h.color).toList();
    expect(colors.where((c) => c == const Color(0xFFFFCC00)), hasLength(1));
    expect(colors.where((c) => c == const Color(0xFF334455)), hasLength(1));
  });

  test('next and previous cycle through matches and wrap', () {
    write('x\r\nx\r\nx\r\n');
    search.search('x');
    expect(search.currentIndex, 0);

    search.next();
    expect(search.currentIndex, 1);
    search.next();
    expect(search.currentIndex, 2);
    search.next();
    expect(search.currentIndex, 0, reason: 'wraps to the start');

    search.previous();
    expect(search.currentIndex, 2, reason: 'wraps to the end');
  });

  test('navigating with no matches does nothing', () {
    search.search('nothing-here');

    search.next();
    search.previous();

    expect(search.currentIndex, 0);
  });

  test('an empty query clears the highlights', () {
    write('alpha\r\n');
    search.search('alpha');
    expect(controller.highlights, isNotEmpty);

    search.search('');

    expect(controller.highlights, isEmpty);
    expect(search.isActive, isFalse);
  });

  test('closing clears everything', () {
    write('alpha\r\n');
    search.search('alpha');

    search.close();

    expect(controller.highlights, isEmpty);
    expect(search.matches, isEmpty);
    expect(search.query, isEmpty);
  });

  test('an invalid regex reports an error and drops highlights', () {
    write('alpha\r\n');
    search.search('alpha');

    search.search('[unclosed', options: const SearchOptions(useRegex: true));

    expect(search.error, isNotNull);
    expect(search.matches, isEmpty);
    expect(
      controller.highlights,
      isEmpty,
      reason: 'stale highlights from the last valid query must not linger',
    );
  });

  test('a valid query clears a previous error', () {
    write('alpha\r\n');
    search.search('[unclosed', options: const SearchOptions(useRegex: true));
    expect(search.error, isNotNull);

    search.search('alpha', options: const SearchOptions());

    expect(search.error, isNull);
    expect(search.matches, hasLength(1));
  });

  test('regex search works against real terminal output', () {
    write('error 404\r\nerror 500\r\nok\r\n');

    search.search(r'error \d+', options: const SearchOptions(useRegex: true));

    expect(search.matches, hasLength(2));
  });

  test('refresh re-runs the query after new output', () {
    write('alpha\r\n');
    search.search('alpha');
    expect(search.matches, hasLength(1));

    write('alpha again\r\n');
    search.refresh();

    expect(search.matches, hasLength(2));
  });

  test('notifies listeners when results change', () {
    write('alpha\r\n');
    var notifications = 0;
    search.addListener(() => notifications++);

    search.search('alpha');

    expect(notifications, 1);
  });
}
