/// Local geometry for the settings screen.
///
/// Divergence, flagged on purpose: the workshop kit's defaults are control
/// radius 10 / height 46, card radius 14 and chip radius 8
/// ([WorkshopTokens.standard]). This screen uses the requested rounded house
/// style — surfaces 16, controls 14 at 48 high, pills 999 at 28 high — so the
/// settings screen is slightly rounder than the rest of the admin shell.
/// Colours, type and spacing still come from [WorkshopTokens]; nothing here
/// introduces a second palette.
abstract final class SettingsGeometry {
  static const double surfaceRadius = 16;
  static const double controlRadius = 14;
  static const double pillRadius = 999;

  static const double controlHeight = 48;
  static const double pillHeight = 28;

  /// Wide enough for the record plate and the working column side by side.
  static const double twoColumnBreakpoint = 940;

  static const double recordWidth = 400;
  static const double columnGap = 32;
  static const double sectionGap = 16;

  /// Quick, quiet transitions; clamped by reduced-motion in the widgets.
  static const Duration settle = Duration(milliseconds: 160);
  static const Duration press = Duration(milliseconds: 120);
}
