/// "The dock" — committed dimensions for the technician sign-in.
///
/// Only geometry lives here. Colour, type and elevation come from the app
/// theme (`ColorScheme`) and the design system's `Fx` scale, so the screen
/// inherits every future token change.
abstract final class SignInDims {
  /// Width at which the canvas gets desktop gutters and the statement grows.
  static const double wide = 900;

  /// Width at which the dock becomes one horizontal row.
  static const double bandRow = 1024;

  /// Width at which the dock stacks its fields.
  static const double stacked = 600;

  /// Below this viewport height the body scrolls instead of pinning the dock
  /// (keyboard-up and small landscape phones).
  static const double pinnedHeight = 640;

  /// Text scale at which the dock always stacks, whatever the width.
  static const double stackScale = 1.5;

  static const double gutterPhone = 20;
  static const double gutterWide = 64;
  static const double gutterTablet = 32;

  static const double stripPhone = 56;
  static const double stripWide = 72;

  static const double cellHeight = 52;
  static const double primaryHeight = 56;
  static const double cellRadius = 12;

  static const double primaryWidth = 300;

  static const double labelGap = 6;
  static const double errorMinHeight = 20;
  static const double metaMinHeight = 18;

  static const double canvasTopPhone = 40;
  static const double canvasTopWide = 64;
  static const double statementMaxPhone = 330;
  static const double statementMaxWide = 700;
  static const double taglineMaxPhone = 330;
  static const double taglineMaxWide = 460;

  static const double dockPadTop = 20;
  static const double dockPadBottom = 16;
  static const double dockPadTopWide = 56;
  static const double dockPadBottomWide = 44;

  static const double riseOffset = 12;
  static const Duration riseDuration = Duration(milliseconds: 240);
}
