/// Tablet breakpoint and layout constants.
/// Min touch target ~48dp per plan.
class AppConstants {
  AppConstants._();

  /// Legacy tablet breakpoint (width in logical pixels).
  static const double tabletBreakpoint = 600;

  /// Responsive breakpoints.
  static const double phoneBreakpoint = 760;
  static const double tabletPortraitBreakpoint = 1024;
  static const double tabletLandscapeBreakpoint = 1024;
  static const double tabletUltraWideBreakpoint = 1366;

  /// Minimum touch target size (dp) for tablet comfort.
  static const double minTouchTarget = 56;

  /// Default padding for tablet screens.
  static const double screenPadding = 24;

  /// Shared layout tokens.
  static const double panelGap = 14;
  static const double sectionGap = 16;
  static const double denseGridMaxExtent = 210;
  static const double comfortableGridMaxExtent = 250;
  static const double stickyActionHeight = 64;
  static const double compactListRowHeight = 64;

  /// Grid cross-axis count for table cards on home (fallback).
  static const int tablesGridCrossCount = 3;

  /// Max width for a single table card so they don't stretch too much on large screens.
  static const double tableCardMaxWidth = 200;

  /// Preferred table card min width for grid.
  static const double tableCardMinWidth = 140;

  /// Padding around the table grid.
  static const double tablesGridPadding = 16;

  /// Spacing between table cards.
  static const double tablesGridSpacing = 16;

  // --- Masa kartı (tablet, pixel-perfect) ---
  static const double tableCardPadding = 12;
  static const double tableCardIconSize = 40;
  static const double tableCardSpacingAfterIcon = 8;
  static const double tableCardSpacingAfterTitle = 8;
  static const double tableCardSpacingBeforeAmount = 8;
  static const double tableCardBorderRadius = 16;
  static const double tableCardBadgeHeight = 28;
  static const double tableCardAmountFontSize = 20;
  static const double tableCardTitleFontSize = 17;
}
