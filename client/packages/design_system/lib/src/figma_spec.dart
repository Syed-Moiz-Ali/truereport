import 'package:design_system/src/fonts.dart';
import 'package:flutter/material.dart';

/// Exact values transcribed from the Figma export JSON and the `@2x`
/// previews under `docs/ui/figma-export/`.
///
/// These constants are the fidelity target. The product token scale in
/// `tokens.dart` keeps the owner-approved accessibility deviations (minimum
/// 12 px text, 48 dp targets). Figma-exact gallery variants and the fidelity
/// harness read this file; product widgets read the theme tokens.
abstract final class FigmaColors {
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1B1F);
  static const inkStrong = Color(0xFF1B1B25);
  static const muted = Color(0xFF5E5D69);
  static const outline = Color(0xFF6C7A71);
  static const surface = Color(0xFFFFFFFF);
  static const container = Color(0xFFF4F3F8);
  static const surfaceHigh = Color(0xFFEEEDF3);
  static const surfaceHighest = Color(0xFFE9E7ED);
  static const divider = Color(0xFFEEEDF3);
  static const emerald = Color(0xFF10B981);
  static const emeraldPressed = Color(0xFF059669);
  static const deepGreen = Color(0xFF006C49);
  static const selected = Color(0xFFFED7AA);
  static const selectedShadow = Color(0x2EFB923C);
}

abstract final class FigmaType {
  static const String family = TrFonts.latin;

  static TextStyle get caption => _style(11, 14, FontWeight.w600, 0.44);
  static TextStyle get captionWide => _style(11, 14, FontWeight.w600, 0.55);
  static TextStyle get body => _style(13, 18, FontWeight.w400, 0);
  static TextStyle get labelMd => _style(12, 16, FontWeight.w600, 0.24);
  static TextStyle get labelBold => _style(12, 16, FontWeight.w700, 0.24);
  static TextStyle get labelLg => _style(14, 18, FontWeight.w700, -0.14);
  static TextStyle get bodyMd => _style(14, 20, FontWeight.w500, -0.07);
  static TextStyle get titleLg => _style(16, 22, FontWeight.w700, -0.16);
  static TextStyle get titleStrong => _style(16, 24, FontWeight.w600, -0.16);
  static TextStyle get headingMd => _style(18, 24, FontWeight.w700, -0.27);
  static TextStyle get headingLg => _style(22, 28, FontWeight.w700, -0.44);
  static TextStyle get displayXl => _style(26, 32, FontWeight.w800, -0.65);
  static TextStyle get display => _style(32, 38, FontWeight.w800, -0.8);

  static TextStyle _style(
    double size,
    double lineHeight,
    FontWeight weight,
    double tracking,
  ) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: const <String>[
        TrFonts.arabicDefault,
        TrFonts.arabicAlternative,
        TrFonts.cyrillicFallback,
        TrFonts.cjkFallback,
      ],
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: tracking,
    );
  }
}

abstract final class FigmaShadows {
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x04000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0B000000),
      offset: Offset(0, 14),
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];

  static const buttonSubtle = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  static const cta = <BoxShadow>[
    BoxShadow(
      color: Color(0x4D10B981),
      offset: Offset(0, 10),
      blurRadius: 25,
      spreadRadius: 0,
    ),
  ];

  static const selectedOption = <BoxShadow>[
    BoxShadow(
      color: Color(0x2EFB923C),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
}

abstract final class FigmaGeometry {
  static const double pillRadius = 999;
  static const double buttonWidth = 342;
  static const double buttonHeight = 56;
  static const double buttonIcon = 10.67;
  static const double buttonGap = 8;

  static const double cardWidth = 350;
  static const double cardHeight = 145;
  static const double cardRadius = 32;
  static const double cardPadding = 20;
  static const double cardGap = 16;
  static const double statusIconCircle = 36;
  static const double statusIcon = 16.67;
  static const double statusIconTextGap = 12;
  static const double statusPillHeight = 28;
  static const double statusPillDot = 8;
  static const double statusPillDotGap = 8;

  static const double selectorWidth = 350;
  static const double selectorLabelHeight = 14;
  static const double selectorLabelGap = 4;
  static const double selectorPillHeight = 52;
  static const double selectorPillPadding = 6;
  static const double selectorPillGap = 6;
  static const double selectorOptionHeight = 40;
  static const double selectorOptionPaddingH = 8;
  static const double selectorOptionPaddingV = 12;

  /// Placement of the Figma nodes inside their reference crops.
  static const double planeButtonStart = 24;
  static const double planeButtonTop = 32;
  static const double planeCardStart = 20;
  static const double planeCardTop = 20;
  static const double planeSelectorStart = 20;
  static const double planeSelectorTop = 12;
}

enum FigmaPrimaryButtonOption {
  figmaExact,
  pressedGreen,
  inkLabel,
  deepGreen,
}

@immutable
class FigmaPrimaryButtonSpec {
  const FigmaPrimaryButtonSpec({
    required this.option,
    required this.fill,
    required this.label,
    required this.fontSize,
    required this.fontWeight,
  });

  final FigmaPrimaryButtonOption option;
  final Color fill;
  final Color label;
  final double fontSize;
  final FontWeight fontWeight;

  static const figmaExact = FigmaPrimaryButtonSpec(
    option: FigmaPrimaryButtonOption.figmaExact,
    fill: FigmaColors.emerald,
    label: FigmaColors.white,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const pressedGreen = FigmaPrimaryButtonSpec(
    option: FigmaPrimaryButtonOption.pressedGreen,
    fill: FigmaColors.emeraldPressed,
    label: FigmaColors.white,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  static const inkLabel = FigmaPrimaryButtonSpec(
    option: FigmaPrimaryButtonOption.inkLabel,
    fill: FigmaColors.emerald,
    label: FigmaColors.ink,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const deepGreen = FigmaPrimaryButtonSpec(
    option: FigmaPrimaryButtonOption.deepGreen,
    fill: FigmaColors.deepGreen,
    label: FigmaColors.white,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const all = <FigmaPrimaryButtonSpec>[
    figmaExact,
    pressedGreen,
    inkLabel,
    deepGreen,
  ];

  String get title => switch (option) {
    FigmaPrimaryButtonOption.figmaExact => '1. Figma exact',
    FigmaPrimaryButtonOption.pressedGreen =>
      "2. Figma's pressed green, larger bold label",
    FigmaPrimaryButtonOption.inkLabel => '3. Ink label',
    FigmaPrimaryButtonOption.deepGreen => '4. Deep green',
  };

  TextStyle get textStyle => TextStyle(
    fontFamily: FigmaType.family,
    fontSize: fontSize,
    height: 18 / fontSize,
    fontWeight: fontWeight,
    letterSpacing: -0.14,
  );
}
