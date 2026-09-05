import 'package:flutter/widgets.dart';

/// The three layout classes the app adapts to.
enum WindowSize {
  /// Phones, and any window narrower than 600. Bottom navigation.
  compact,

  /// Small tablets and split-screen windows, 600–1024. Navigation rail.
  medium,

  /// Tablets in landscape and desktop windows, wider than 1024. Sidebar.
  expanded;

  /// Whether this size can usefully show two panes side by side.
  bool get supportsSplitPanes => this != WindowSize.compact;

  /// Whether navigation should be a persistent sidebar rather than a rail.
  bool get prefersSidebar => this == WindowSize.expanded;
}

/// Where the layout classes change, in logical pixels.
///
/// These follow Material 3's window size classes so that the app behaves the
/// way the rest of the platform does.
abstract final class Breakpoints {
  /// Below this width the layout is [WindowSize.compact].
  static const medium = 600.0;

  /// At or above this width the layout is [WindowSize.expanded].
  static const expanded = 1024.0;

  /// Classifies [width].
  static WindowSize of(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= medium) return WindowSize.medium;
    return WindowSize.compact;
  }

  /// Classifies the nearest enclosing [MediaQuery].
  static WindowSize ofContext(BuildContext context) =>
      of(MediaQuery.sizeOf(context).width);
}
