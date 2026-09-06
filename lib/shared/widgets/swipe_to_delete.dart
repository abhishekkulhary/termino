import 'package:flutter/material.dart';
import 'package:termino/shared/design/neon_accents.dart';
import 'package:termino/shared/design/tokens.dart';

/// Wraps a list row so it can be swiped away, after asking.
///
/// Swipe is a shortcut, never the only way: every row that has this also keeps
/// Delete in its menu. A gesture nobody discovers is not a feature, and a
/// destructive action reachable *only* by an accidental drag is worse than one.
///
/// The confirmation is not optional either. These rows sit in scrolling lists
/// that people flick through, and an accidental horizontal drag is exactly the
/// sort of thing that happens on a phone in one hand.
class SwipeToDelete extends StatelessWidget {
  /// Wraps [child], deleting it through [onDelete] once [confirm] agrees.
  const new({
    required this.itemKey,
    required this.confirm,
    required this.onDelete,
    required this.child,
    super.key,
    this.dense = false,
    this.label = 'Delete',
  });

  /// Identifies the row. Must be stable and unique within the list.
  final Key itemKey;

  /// Asks the user. Returning false leaves the row alone.
  final Future<bool> Function() confirm;

  /// Performs the deletion once confirmed.
  final Future<void> Function() onDelete;

  /// The row itself.
  final Widget child;

  /// Matches the row's own density, so the revealed panel lines up with it.
  final bool dense;

  /// What the revealed panel says.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: itemKey,
      // Trailing edge only. A leading swipe means something else in most
      // interfaces — archive, or pin — and claiming it for delete as well
      // would make a mis-swipe destructive in both directions.
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: _DeleteBackground(dense: dense, label: label),
      // A row swiped far enough is gone, not nudged. The default quarter of
      // the width is easy to reach by accident while scrolling.
      dismissThresholds: const {DismissDirection.endToStart: 0.45},
      confirmDismiss: (_) async {
        if (!await confirm()) return false;
        await onDelete();

        // Deliberately false, even though the deletion happened.
        //
        // These lists are fed by a database stream, so the row goes away when
        // the repository emits — a frame or two later, not synchronously.
        // `Dismissible` documents that the item it dismissed must be gone from
        // the list by the time it finishes collapsing, and with an async
        // source there is no way to promise that. Returning false keeps the
        // widget's own lifecycle out of it entirely: the row springs back into
        // a list that is already about to drop it.
        //
        // Worth saying plainly: I could not get the "dismissed Dismissible is
        // still part of the tree" assertion to fire either way here, so this
        // is avoiding a documented hazard rather than a reproduced one. The
        // cost is one animation; the alternative is a race with the database.
        return false;
      },
      child: child,
    );
  }
}

/// What is revealed behind a row being swiped away.
class _DeleteBackground extends StatelessWidget {
  const new({required this.dense, required this.label});

  final bool dense;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neon = NeonAccents.of(context);
    final danger = neon.offline;

    return Padding(
      // The same insets `NeonListCard` uses, so the panel revealed underneath
      // sits exactly where the row was rather than a few pixels outside it.
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: dense ? Spacing.xxs : Spacing.sm,
      ),
      child: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        decoration: BoxDecoration(
          color: danger.withValues(alpha: 0.14),
          borderRadius: Radii.borderMd,
          border: Border.all(color: danger.withValues(alpha: 0.55)),
          boxShadow: neon.glow(danger, blur: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(color: danger),
            ),
            const SizedBox(width: Spacing.sm),
            Icon(Icons.delete_outline_rounded, color: danger, size: 20),
          ],
        ),
      ),
    );
  }
}
