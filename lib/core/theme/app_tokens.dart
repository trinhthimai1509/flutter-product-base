import 'package:flutter/widgets.dart';

/// Spacing scale (logical pixels). Use these instead of magic numbers.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radius scale.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}

/// Width breakpoints, following Material 3 window size classes.
enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize fromWidth(double width) {
    if (width < 600) return WindowSize.compact;
    if (width < 1024) return WindowSize.medium;
    return WindowSize.expanded;
  }
}

abstract final class AppLayout {
  /// Max width for reading/form content on large screens.
  static const double maxContentWidth = 720;
}
