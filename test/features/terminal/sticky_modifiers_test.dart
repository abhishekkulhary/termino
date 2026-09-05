// These tests walk a state machine one step at a time, asserting between the
// steps. Cascading the calls, as the lint suggests, would merge the steps and
// hide exactly what is being checked.
// ignore_for_file: cascade_invocations

import 'package:flutter_test/flutter_test.dart';
import 'package:termino/features/terminal/application/sticky_modifiers.dart';

void main() {
  late StickyModifiers modifiers;

  setUp(() => modifiers = StickyModifiers());

  test('everything starts off', () {
    for (final modifier in StickyModifier.values) {
      expect(modifiers.stateOf(modifier), ModifierState.off);
      expect(modifiers.isActive(modifier), isFalse);
    }
    expect(modifiers.anyActive, isFalse);
  });

  test('one tap arms, two locks, three clears', () {
    modifiers.tap(StickyModifier.ctrl);
    expect(modifiers.stateOf(StickyModifier.ctrl), ModifierState.armed);

    modifiers.tap(StickyModifier.ctrl);
    expect(modifiers.stateOf(StickyModifier.ctrl), ModifierState.locked);

    modifiers.tap(StickyModifier.ctrl);
    expect(modifiers.stateOf(StickyModifier.ctrl), ModifierState.off);
  });

  test('an armed modifier applies to one key and is then released', () {
    modifiers.tap(StickyModifier.ctrl);
    expect(modifiers.isActive(StickyModifier.ctrl), isTrue);
    modifiers.consume();
    expect(
      modifiers.isActive(StickyModifier.ctrl),
      isFalse,
      reason: 'Ctrl+C must not leak into the next keystroke',
    );
  });

  test('a locked modifier survives key presses', () {
    modifiers
      ..tap(StickyModifier.ctrl)
      ..tap(StickyModifier.ctrl);

    modifiers
      ..consume()
      ..consume();

    expect(
      modifiers.stateOf(StickyModifier.ctrl),
      ModifierState.locked,
      reason: 'locking exists precisely so it survives',
    );
  });

  test('modifiers are independent', () {
    modifiers
      ..tap(StickyModifier.ctrl)
      ..tap(StickyModifier.alt)
      ..tap(StickyModifier.alt);

    expect(modifiers.stateOf(StickyModifier.ctrl), ModifierState.armed);
    expect(modifiers.stateOf(StickyModifier.alt), ModifierState.locked);
    expect(modifiers.stateOf(StickyModifier.shift), ModifierState.off);
  });

  test('consume releases armed modifiers but keeps locked ones', () {
    modifiers
      ..tap(StickyModifier.ctrl)
      ..tap(StickyModifier.alt)
      ..tap(StickyModifier.alt)
      ..consume();
    expect(modifiers.stateOf(StickyModifier.ctrl), ModifierState.off);
    expect(modifiers.stateOf(StickyModifier.alt), ModifierState.locked);
  });

  test('clear removes locks too', () {
    modifiers
      ..tap(StickyModifier.ctrl)
      ..tap(StickyModifier.ctrl)
      ..clear();

    expect(modifiers.anyActive, isFalse);
  });

  test('notifies listeners when something changes', () {
    var notifications = 0;
    modifiers.addListener(() => notifications++);

    modifiers.tap(StickyModifier.ctrl);
    expect(notifications, 1);
    modifiers.consume();
    expect(notifications, 2);
  });

  test('does not notify when nothing changed', () {
    var notifications = 0;
    modifiers.addListener(() => notifications++);

    modifiers
      ..consume()
      ..clear();

    expect(notifications, 0, reason: 'a no-op must not rebuild the bar');
  });

  test('set forces a state directly', () {
    modifiers.set(StickyModifier.shift, ModifierState.locked);

    expect(modifiers.stateOf(StickyModifier.shift), ModifierState.locked);
  });

  test('every modifier has a label', () {
    for (final modifier in StickyModifier.values) {
      expect(modifier.label, isNotEmpty);
    }
  });
}
