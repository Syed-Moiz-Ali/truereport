// GENERATED FILE - DO NOT EDIT.
// Source: client/packages/design_system/tokens/tokens.json
// Regenerate: node tools/design_tokens/generate.mjs --write

import 'package:flutter/material.dart';

abstract final class TrColorLight {
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF7F6FB);
  static const Color surfaceContainer = Color(0xFFF4F3F8);
  static const Color surfaceHigh = Color(0xFFEEEDF3);
  static const Color surfaceHighest = Color(0xFFE9E7ED);
  static const Color onSurface = Color(0xFF1A1B1F);
  static const Color onSurfaceVariant = Color(0xFF5E5D69);
  static const Color outline = Color(0xFF6C7A71);
  static const Color outlineVariant = Color(0xFFDAD9DF);
  static const Color secondary = Color(0xFF3C4A42);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE3E1EF);
  static const Color onSecondaryContainer = Color(0xFF464651);
  static const Color error = Color(0xFFA3231F);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFBE9E7);
  static const Color onErrorContainer = Color(0xFF7F1D1D);
  static const Color focus = Color(0xFF0B63CE);
  static const Color overlay = Color(0x661A1B1F);
  static const Color scrim = Color(0x66000000);
  static const Color inverseSurface = Color(0xFF2F3034);
  static const Color onInverseSurface = Color(0xFFF1F0F5);
}

abstract final class TrColorDark {
  static const Color surface = Color(0xFF121114);
  static const Color surfaceLowest = Color(0xFF0C0B0E);
  static const Color surfaceLow = Color(0xFF1A191E);
  static const Color surfaceContainer = Color(0xFF232128);
  static const Color surfaceHigh = Color(0xFF2A282F);
  static const Color surfaceHighest = Color(0xFF323036);
  static const Color onSurface = Color(0xFFF1F0F5);
  static const Color onSurfaceVariant = Color(0xFFC7C5D3);
  static const Color outline = Color(0xFF9A98A6);
  static const Color outlineVariant = Color(0xFF4A4854);
  static const Color secondary = Color(0xFFC7C5D3);
  static const Color onSecondary = Color(0xFF1B1B25);
  static const Color secondaryContainer = Color(0xFF464651);
  static const Color onSecondaryContainer = Color(0xFFE3E1EF);
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  static const Color focus = Color(0xFF9CCBFF);
  static const Color overlay = Color(0x99000000);
  static const Color scrim = Color(0xB3000000);
  static const Color inverseSurface = Color(0xFFE9E7ED);
  static const Color onInverseSurface = Color(0xFF1A1B1F);
}

@immutable
class TrBrandColors {
  const TrBrandColors({
    required this.fill,
    required this.onFill,
    required this.ink,
    required this.container,
    required this.onContainer,
  });

  final Color fill;
  final Color onFill;
  final Color ink;
  final Color container;
  final Color onContainer;
}

abstract final class TrBrandLight {
  static const TrBrandColors emeraldFill = TrBrandColors(
    fill: Color(0xFF10B981),
    onFill: Color(0xFF1A1B1F),
    ink: Color(0xFF006C49),
    container: Color(0xFFD9FBE8),
    onContainer: Color(0xFF00422B),
  );

  static const TrBrandColors deepGreenFill = TrBrandColors(
    fill: Color(0xFF006C49),
    onFill: Color(0xFFFFFFFF),
    ink: Color(0xFF006C49),
    container: Color(0xFFD9FBE8),
    onContainer: Color(0xFF00422B),
  );
}

abstract final class TrBrandDark {
  static const TrBrandColors emeraldFill = TrBrandColors(
    fill: Color(0xFF4EDEA3),
    onFill: Color(0xFF002113),
    ink: Color(0xFF6FFBBE),
    container: Color(0xFF005236),
    onContainer: Color(0xFFB7F5D8),
  );

  static const TrBrandColors deepGreenFill = TrBrandColors(
    fill: Color(0xFF6FFBBE),
    onFill: Color(0xFF002113),
    ink: Color(0xFF6FFBBE),
    container: Color(0xFF005236),
    onContainer: Color(0xFFB7F5D8),
  );
}

@immutable
class TrStatusPair {
  const TrStatusPair({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}

abstract final class TrStatusLight {
  static const TrStatusPair neutral = TrStatusPair(
    foreground: Color(0xFF3F4A54),
    background: Color(0xFFEDF1F3),
  );

  static const TrStatusPair info = TrStatusPair(
    foreground: Color(0xFF1D5C8A),
    background: Color(0xFFE5F0F8),
  );

  static const TrStatusPair success = TrStatusPair(
    foreground: Color(0xFF1F6B45),
    background: Color(0xFFE6F3EC),
  );

  static const TrStatusPair warning = TrStatusPair(
    foreground: Color(0xFF8A5A00),
    background: Color(0xFFFFF4D6),
  );

  static const TrStatusPair danger = TrStatusPair(
    foreground: Color(0xFFA3231F),
    background: Color(0xFFFBE9E7),
  );

  static const TrStatusPair critical = TrStatusPair(
    foreground: Color(0xFF7F1D1D),
    background: Color(0xFFF7DADA),
  );
}

abstract final class TrStatusDark {
  static const TrStatusPair neutral = TrStatusPair(
    foreground: Color(0xFFC3D4DA),
    background: Color(0xFF26373C),
  );

  static const TrStatusPair info = TrStatusPair(
    foreground: Color(0xFFB7DCF7),
    background: Color(0xFF173247),
  );

  static const TrStatusPair success = TrStatusPair(
    foreground: Color(0xFFB5E8C9),
    background: Color(0xFF173D2B),
  );

  static const TrStatusPair warning = TrStatusPair(
    foreground: Color(0xFFFFDFA3),
    background: Color(0xFF463611),
  );

  static const TrStatusPair danger = TrStatusPair(
    foreground: Color(0xFFFFC4BD),
    background: Color(0xFF4A1F1C),
  );

  static const TrStatusPair critical = TrStatusPair(
    foreground: Color(0xFFFFD0D0),
    background: Color(0xFF551C1C),
  );
}

@immutable
class TrSeverityToken {
  const TrSeverityToken({required this.tone, required this.icon});

  final String tone;
  final IconData icon;
}

abstract final class TrSeverityMap {
  static const TrSeverityToken minor = TrSeverityToken(tone: 'neutral', icon: Icons.circle_outlined);
  static const TrSeverityToken moderate = TrSeverityToken(tone: 'warning', icon: Icons.warning_amber_rounded);
  static const TrSeverityToken major = TrSeverityToken(tone: 'danger', icon: Icons.error_outline);
  static const TrSeverityToken safetyCritical = TrSeverityToken(tone: 'critical', icon: Icons.dangerous_outlined);
}

@immutable
class TrInspectionResultToken {
  const TrInspectionResultToken({required this.tone, required this.icon});

  final String tone;
  final IconData icon;
}

abstract final class TrInspectionResultMap {
  static const TrInspectionResultToken noIssueObserved = TrInspectionResultToken(tone: 'neutral', icon: Icons.check_circle_outline);
  static const TrInspectionResultToken attentionRecommended = TrInspectionResultToken(tone: 'warning', icon: Icons.info_outline);
  static const TrInspectionResultToken defectFound = TrInspectionResultToken(tone: 'danger', icon: Icons.warning_amber_rounded);
  static const TrInspectionResultToken notChecked = TrInspectionResultToken(tone: 'neutral', icon: Icons.remove_circle_outline);
  static const TrInspectionResultToken notApplicable = TrInspectionResultToken(tone: 'neutral', icon: Icons.block);
  static const TrInspectionResultToken couldNotVerify = TrInspectionResultToken(tone: 'warning', icon: Icons.help_outline);
}

@immutable
class TrTypeStyleToken {
  const TrTypeStyleToken({
    required this.size,
    required this.lineHeight,
    required this.weight,
    required this.tracking,
  });

  final double size;
  final double lineHeight;
  final int weight;
  final double tracking;

  double get height => lineHeight / size;
}

abstract final class TrType {
  static const display = TrTypeStyleToken(size: 32, lineHeight: 38, weight: 800, tracking: -0.8);
  static const headlineXl = TrTypeStyleToken(size: 26, lineHeight: 32, weight: 800, tracking: -0.65);
  static const headlineLg = TrTypeStyleToken(size: 22, lineHeight: 28, weight: 700, tracking: -0.44);
  static const headlineMd = TrTypeStyleToken(size: 18, lineHeight: 24, weight: 700, tracking: -0.27);
  static const titleLg = TrTypeStyleToken(size: 16, lineHeight: 22, weight: 700, tracking: -0.16);
  static const bodyLg = TrTypeStyleToken(size: 16, lineHeight: 24, weight: 500, tracking: -0.16);
  static const bodyMd = TrTypeStyleToken(size: 14, lineHeight: 20, weight: 500, tracking: -0.07);
  static const bodySm = TrTypeStyleToken(size: 12, lineHeight: 18, weight: 400, tracking: 0);
  static const labelLg = TrTypeStyleToken(size: 14, lineHeight: 18, weight: 700, tracking: -0.14);
  static const labelMd = TrTypeStyleToken(size: 12, lineHeight: 16, weight: 600, tracking: 0.24);
  static const labelSm = TrTypeStyleToken(size: 12, lineHeight: 16, weight: 600, tracking: 0.3);
}

abstract final class TrTypeArabic {
  static const double tracking = 0;
  static const double bodyLineHeightMultiplier = 1.55;

  static const display = TrTypeStyleToken(size: 32, lineHeight: 38, weight: 800, tracking: 0);
  static const headlineXl = TrTypeStyleToken(size: 26, lineHeight: 32, weight: 800, tracking: 0);
  static const headlineLg = TrTypeStyleToken(size: 22, lineHeight: 28, weight: 700, tracking: 0);
  static const headlineMd = TrTypeStyleToken(size: 18, lineHeight: 24, weight: 700, tracking: 0);
  static const titleLg = TrTypeStyleToken(size: 16, lineHeight: 22, weight: 700, tracking: 0);
  static const bodyLg = TrTypeStyleToken(size: 16, lineHeight: 24.8, weight: 500, tracking: 0);
  static const bodyMd = TrTypeStyleToken(size: 14, lineHeight: 21.7, weight: 500, tracking: 0);
  static const bodySm = TrTypeStyleToken(size: 12, lineHeight: 18.6, weight: 400, tracking: 0);
  static const labelLg = TrTypeStyleToken(size: 14, lineHeight: 18, weight: 700, tracking: 0);
  static const labelMd = TrTypeStyleToken(size: 12, lineHeight: 16, weight: 600, tracking: 0);
  static const labelSm = TrTypeStyleToken(size: 12, lineHeight: 16, weight: 600, tracking: 0);
}

abstract final class TrFontFamilies {
  static const String latin = 'Plus Jakarta Sans';
  static const String arabicDefault = 'Noto Sans Arabic';
  static const String arabicAlternative = 'IBM Plex Sans Arabic';
  static const String cyrillicFallback = 'Noto Sans';
  static const String cjkFallback = 'Noto Sans SC';
}

abstract final class TrSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double micro = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double gutter = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;
}

abstract final class TrRadii {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double card = 24;
  static const double cardLarge = 32;
  static const double sheet = 48;
  static const double pill = 999;
}

abstract final class TrShadows {
  static const List<BoxShadow> card = <BoxShadow>[
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

  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 18),
      blurRadius: 50,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonSubtle = <BoxShadow>[
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

  static const List<BoxShadow> buttonEmerald = <BoxShadow>[
    BoxShadow(
      color: Color(0x4D10B981),
      offset: Offset(0, 10),
      blurRadius: 25,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonDeepGreen = <BoxShadow>[
    BoxShadow(
      color: Color(0x4D006C49),
      offset: Offset(0, 10),
      blurRadius: 25,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> focusLight = <BoxShadow>[
    BoxShadow(
      color: TrColorLight.focus,
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> focusDark = <BoxShadow>[
    BoxShadow(
      color: TrColorDark.focus,
      offset: Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 2,
    ),
  ];
}

abstract final class TrSizing {
  static const double targetMin = 48;
  static const double buttonHeight = 56;
  static const double technicianPrimaryHeight = 56;
  static const double inputHeight = 56;
  static const double navDockHeight = 64;
  static const double cardPadding = 24;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double focusRingWidth = 2;
  static const double focusRingOffset = 2;
  static const double borderWidth = 1.5;
  static const double dividerWidth = 1;
  static const double maxContentWidth = 1280;
}

abstract final class TrMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration reduced = Duration(milliseconds: 0);
  static const double pressScale = 0.98;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
}

abstract final class TrBreakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

