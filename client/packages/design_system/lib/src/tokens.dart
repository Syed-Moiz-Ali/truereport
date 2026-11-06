import 'package:design_system/src/generated/tokens.g.dart';
import 'package:design_system/src/reduce_motion.dart';
import 'package:flutter/material.dart';

enum StatusTone { neutral, info, success, warning, danger, critical }

enum AppColorStrategy { emeraldFill, deepGreenFill }

enum AppArabicFont { notoSansArabic, ibmPlexSansArabic }

enum AppSeverity { minor, moderate, major, safetyCritical }

enum InspectionResult {
  noIssueObserved,
  attentionRecommended,
  defectFound,
  notChecked,
  notApplicable,
  couldNotVerify,
}

extension AppSeverityTokens on AppSeverity {
  StatusTone get tone => switch (this) {
    AppSeverity.minor => StatusTone.neutral,
    AppSeverity.moderate => StatusTone.warning,
    AppSeverity.major => StatusTone.danger,
    AppSeverity.safetyCritical => StatusTone.critical,
  };

  IconData get icon => switch (this) {
    AppSeverity.minor => Icons.circle_outlined,
    AppSeverity.moderate => Icons.warning_amber_rounded,
    AppSeverity.major => Icons.error_outline,
    AppSeverity.safetyCritical => Icons.dangerous_outlined,
  };
}

extension InspectionResultTokens on InspectionResult {
  StatusTone get tone => switch (this) {
    InspectionResult.noIssueObserved => StatusTone.neutral,
    InspectionResult.attentionRecommended => StatusTone.warning,
    InspectionResult.defectFound => StatusTone.danger,
    InspectionResult.notChecked => StatusTone.neutral,
    InspectionResult.notApplicable => StatusTone.neutral,
    InspectionResult.couldNotVerify => StatusTone.warning,
  };

  IconData get icon => switch (this) {
    InspectionResult.noIssueObserved => Icons.check_circle_outline,
    InspectionResult.attentionRecommended => Icons.info_outline,
    InspectionResult.defectFound => Icons.warning_amber_rounded,
    InspectionResult.notChecked => Icons.remove_circle_outline,
    InspectionResult.notApplicable => Icons.block,
    InspectionResult.couldNotVerify => Icons.help_outline,
  };
}

@immutable
class AppSpacingTokens extends ThemeExtension<AppSpacingTokens> {
  const AppSpacingTokens({
    required this.xxs,
    required this.xs,
    required this.micro,
    required this.sm,
    required this.md,
    required this.lg,
    required this.gutter,
    required this.xl,
    required this.xxl,
    required this.xxxl,
    required this.huge,
    required this.massive,
  });

  static const standard = AppSpacingTokens(
    xxs: TrSpacing.xxs,
    xs: TrSpacing.xs,
    micro: TrSpacing.micro,
    sm: TrSpacing.sm,
    md: TrSpacing.md,
    lg: TrSpacing.lg,
    gutter: TrSpacing.gutter,
    xl: TrSpacing.xl,
    xxl: TrSpacing.xxl,
    xxxl: TrSpacing.xxxl,
    huge: TrSpacing.huge,
    massive: TrSpacing.massive,
  );

  final double xxs;
  final double xs;
  final double micro;
  final double sm;
  final double md;
  final double lg;
  final double gutter;
  final double xl;
  final double xxl;
  final double xxxl;
  final double huge;
  final double massive;

  @override
  AppSpacingTokens copyWith({
    double? xxs,
    double? xs,
    double? micro,
    double? sm,
    double? md,
    double? lg,
    double? gutter,
    double? xl,
    double? xxl,
    double? xxxl,
    double? huge,
    double? massive,
  }) {
    return AppSpacingTokens(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      micro: micro ?? this.micro,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      gutter: gutter ?? this.gutter,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
      huge: huge ?? this.huge,
      massive: massive ?? this.massive,
    );
  }

  @override
  AppSpacingTokens lerp(covariant AppSpacingTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return AppSpacingTokens(
      xxs: _lerp(xxs, other.xxs, t),
      xs: _lerp(xs, other.xs, t),
      micro: _lerp(micro, other.micro, t),
      sm: _lerp(sm, other.sm, t),
      md: _lerp(md, other.md, t),
      lg: _lerp(lg, other.lg, t),
      gutter: _lerp(gutter, other.gutter, t),
      xl: _lerp(xl, other.xl, t),
      xxl: _lerp(xxl, other.xxl, t),
      xxxl: _lerp(xxxl, other.xxxl, t),
      huge: _lerp(huge, other.huge, t),
      massive: _lerp(massive, other.massive, t),
    );
  }
}

@immutable
class AppRadiiTokens extends ThemeExtension<AppRadiiTokens> {
  const AppRadiiTokens({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.card,
    required this.cardLarge,
    required this.sheet,
    required this.pill,
  });

  static const standard = AppRadiiTokens(
    sm: TrRadii.sm,
    md: TrRadii.md,
    lg: TrRadii.lg,
    xl: TrRadii.xl,
    card: TrRadii.card,
    cardLarge: TrRadii.cardLarge,
    sheet: TrRadii.sheet,
    pill: TrRadii.pill,
  );

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double card;
  final double cardLarge;
  final double sheet;
  final double pill;

  @override
  AppRadiiTokens copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? card,
    double? cardLarge,
    double? sheet,
    double? pill,
  }) {
    return AppRadiiTokens(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      card: card ?? this.card,
      cardLarge: cardLarge ?? this.cardLarge,
      sheet: sheet ?? this.sheet,
      pill: pill ?? this.pill,
    );
  }

  @override
  AppRadiiTokens lerp(covariant AppRadiiTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return AppRadiiTokens(
      sm: _lerp(sm, other.sm, t),
      md: _lerp(md, other.md, t),
      lg: _lerp(lg, other.lg, t),
      xl: _lerp(xl, other.xl, t),
      card: _lerp(card, other.card, t),
      cardLarge: _lerp(cardLarge, other.cardLarge, t),
      sheet: _lerp(sheet, other.sheet, t),
      pill: _lerp(pill, other.pill, t),
    );
  }
}

@immutable
class AppShadowTokens extends ThemeExtension<AppShadowTokens> {
  const AppShadowTokens({
    required this.card,
    required this.floating,
    required this.button,
    required this.buttonSubtle,
    required this.focus,
    required this.focusRing,
  });

  final List<BoxShadow> card;
  final List<BoxShadow> floating;
  final List<BoxShadow> button;
  final List<BoxShadow> buttonSubtle;
  final BoxShadow focus;
  final List<BoxShadow> focusRing;

  @override
  AppShadowTokens copyWith({
    List<BoxShadow>? card,
    List<BoxShadow>? floating,
    List<BoxShadow>? button,
    List<BoxShadow>? buttonSubtle,
    BoxShadow? focus,
    List<BoxShadow>? focusRing,
  }) {
    return AppShadowTokens(
      card: card ?? this.card,
      floating: floating ?? this.floating,
      button: button ?? this.button,
      buttonSubtle: buttonSubtle ?? this.buttonSubtle,
      focus: focus ?? this.focus,
      focusRing: focusRing ?? this.focusRing,
    );
  }

  @override
  AppShadowTokens lerp(covariant AppShadowTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return AppShadowTokens(
      card: BoxShadow.lerpList(card, other.card, t) ?? card,
      floating: BoxShadow.lerpList(floating, other.floating, t) ?? floating,
      button: BoxShadow.lerpList(button, other.button, t) ?? button,
      buttonSubtle:
          BoxShadow.lerpList(buttonSubtle, other.buttonSubtle, t) ??
          buttonSubtle,
      focus: BoxShadow.lerp(focus, other.focus, t) ?? focus,
      focusRing: BoxShadow.lerpList(focusRing, other.focusRing, t) ?? focusRing,
    );
  }
}

@immutable
class AppSizingTokens extends ThemeExtension<AppSizingTokens> {
  const AppSizingTokens({
    required this.targetMin,
    required this.buttonHeight,
    required this.technicianPrimaryHeight,
    required this.inputHeight,
    required this.navDockHeight,
    required this.cardPadding,
    required this.iconSm,
    required this.iconMd,
    required this.iconLg,
    required this.iconXl,
    required this.focusRingWidth,
    required this.focusRingOffset,
    required this.borderWidth,
    required this.dividerWidth,
    required this.maxContentWidth,
    required this.heroHeight,
    required this.heroSilhouetteHeight,
    required this.jobCardMinHeight,
    required this.emptyArt,
    required this.authContentWidth,
  });

  static const standard = AppSizingTokens(
    targetMin: TrSizing.targetMin,
    buttonHeight: TrSizing.buttonHeight,
    technicianPrimaryHeight: TrSizing.technicianPrimaryHeight,
    inputHeight: TrSizing.inputHeight,
    navDockHeight: TrSizing.navDockHeight,
    cardPadding: TrSizing.cardPadding,
    iconSm: TrSizing.iconSm,
    iconMd: TrSizing.iconMd,
    iconLg: TrSizing.iconLg,
    iconXl: TrSizing.iconXl,
    focusRingWidth: TrSizing.focusRingWidth,
    focusRingOffset: TrSizing.focusRingOffset,
    borderWidth: TrSizing.borderWidth,
    dividerWidth: TrSizing.dividerWidth,
    maxContentWidth: TrSizing.maxContentWidth,
    heroHeight: TrSizing.heroHeight,
    heroSilhouetteHeight: TrSizing.heroSilhouetteHeight,
    jobCardMinHeight: TrSizing.jobCardMinHeight,
    emptyArt: TrSizing.emptyArt,
    authContentWidth: TrSizing.authContentWidth,
  );

  final double targetMin;
  final double buttonHeight;
  final double technicianPrimaryHeight;
  final double inputHeight;
  final double navDockHeight;
  final double cardPadding;
  final double iconSm;
  final double iconMd;
  final double iconLg;
  final double iconXl;
  final double focusRingWidth;
  final double focusRingOffset;
  final double borderWidth;
  final double dividerWidth;
  final double maxContentWidth;
  final double heroHeight;
  final double heroSilhouetteHeight;
  final double jobCardMinHeight;
  final double emptyArt;
  final double authContentWidth;

  @override
  AppSizingTokens copyWith({
    double? targetMin,
    double? buttonHeight,
    double? technicianPrimaryHeight,
    double? inputHeight,
    double? navDockHeight,
    double? cardPadding,
    double? iconSm,
    double? iconMd,
    double? iconLg,
    double? iconXl,
    double? focusRingWidth,
    double? focusRingOffset,
    double? borderWidth,
    double? dividerWidth,
    double? maxContentWidth,
    double? heroHeight,
    double? heroSilhouetteHeight,
    double? jobCardMinHeight,
    double? emptyArt,
    double? authContentWidth,
  }) {
    return AppSizingTokens(
      targetMin: targetMin ?? this.targetMin,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      technicianPrimaryHeight:
          technicianPrimaryHeight ?? this.technicianPrimaryHeight,
      inputHeight: inputHeight ?? this.inputHeight,
      navDockHeight: navDockHeight ?? this.navDockHeight,
      cardPadding: cardPadding ?? this.cardPadding,
      iconSm: iconSm ?? this.iconSm,
      iconMd: iconMd ?? this.iconMd,
      iconLg: iconLg ?? this.iconLg,
      iconXl: iconXl ?? this.iconXl,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      focusRingOffset: focusRingOffset ?? this.focusRingOffset,
      borderWidth: borderWidth ?? this.borderWidth,
      dividerWidth: dividerWidth ?? this.dividerWidth,
      maxContentWidth: maxContentWidth ?? this.maxContentWidth,
      heroHeight: heroHeight ?? this.heroHeight,
      heroSilhouetteHeight:
          heroSilhouetteHeight ?? this.heroSilhouetteHeight,
      jobCardMinHeight: jobCardMinHeight ?? this.jobCardMinHeight,
      emptyArt: emptyArt ?? this.emptyArt,
      authContentWidth: authContentWidth ?? this.authContentWidth,
    );
  }

  @override
  AppSizingTokens lerp(covariant AppSizingTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return AppSizingTokens(
      targetMin: _lerp(targetMin, other.targetMin, t),
      buttonHeight: _lerp(buttonHeight, other.buttonHeight, t),
      technicianPrimaryHeight: _lerp(
        technicianPrimaryHeight,
        other.technicianPrimaryHeight,
        t,
      ),
      inputHeight: _lerp(inputHeight, other.inputHeight, t),
      navDockHeight: _lerp(navDockHeight, other.navDockHeight, t),
      cardPadding: _lerp(cardPadding, other.cardPadding, t),
      iconSm: _lerp(iconSm, other.iconSm, t),
      iconMd: _lerp(iconMd, other.iconMd, t),
      iconLg: _lerp(iconLg, other.iconLg, t),
      iconXl: _lerp(iconXl, other.iconXl, t),
      focusRingWidth: _lerp(focusRingWidth, other.focusRingWidth, t),
      focusRingOffset: _lerp(focusRingOffset, other.focusRingOffset, t),
      borderWidth: _lerp(borderWidth, other.borderWidth, t),
      dividerWidth: _lerp(dividerWidth, other.dividerWidth, t),
      maxContentWidth: _lerp(maxContentWidth, other.maxContentWidth, t),
      heroHeight: _lerp(heroHeight, other.heroHeight, t),
      heroSilhouetteHeight: _lerp(
        heroSilhouetteHeight,
        other.heroSilhouetteHeight,
        t,
      ),
      jobCardMinHeight: _lerp(jobCardMinHeight, other.jobCardMinHeight, t),
      emptyArt: _lerp(emptyArt, other.emptyArt, t),
      authContentWidth: _lerp(authContentWidth, other.authContentWidth, t),
    );
  }
}

@immutable
class AppMotionTokens extends ThemeExtension<AppMotionTokens> {
  const AppMotionTokens({
    required this.fast,
    required this.normal,
    required this.slow,
    required this.pressScale,
    required this.enterCurve,
    required this.exitCurve,
  });

  static const standard = AppMotionTokens(
    fast: TrMotion.fast,
    normal: TrMotion.normal,
    slow: TrMotion.slow,
    pressScale: TrMotion.pressScale,
    enterCurve: TrMotion.enterCurve,
    exitCurve: TrMotion.exitCurve,
  );

  final Duration fast;
  final Duration normal;
  final Duration slow;
  final double pressScale;
  final Curve enterCurve;
  final Curve exitCurve;

  @override
  AppMotionTokens copyWith({
    Duration? fast,
    Duration? normal,
    Duration? slow,
    double? pressScale,
    Curve? enterCurve,
    Curve? exitCurve,
  }) {
    return AppMotionTokens(
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
      pressScale: pressScale ?? this.pressScale,
      enterCurve: enterCurve ?? this.enterCurve,
      exitCurve: exitCurve ?? this.exitCurve,
    );
  }

  @override
  AppMotionTokens lerp(covariant AppMotionTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return AppMotionTokens(
      fast: _lerpDuration(fast, other.fast, t),
      normal: _lerpDuration(normal, other.normal, t),
      slow: _lerpDuration(slow, other.slow, t),
      pressScale: _lerp(pressScale, other.pressScale, t),
      enterCurve: t < 0.5 ? enterCurve : other.enterCurve,
      exitCurve: t < 0.5 ? exitCurve : other.exitCurve,
    );
  }
}

@immutable
class StatusColorPair {
  const StatusColorPair({required this.foreground, required this.background});

  final Color foreground;
  final Color background;

  StatusColorPair lerp(covariant StatusColorPair? other, double t) {
    if (other == null) {
      return this;
    }
    return StatusColorPair(
      foreground: Color.lerp(foreground, other.foreground, t)!,
      background: Color.lerp(background, other.background, t)!,
    );
  }
}

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.neutral,
    required this.info,
    required this.success,
    required this.warning,
    required this.danger,
    required this.critical,
  });

  static final light = AppStatusColors(
    neutral: _pair(TrStatusLight.neutral),
    info: _pair(TrStatusLight.info),
    success: _pair(TrStatusLight.success),
    warning: _pair(TrStatusLight.warning),
    danger: _pair(TrStatusLight.danger),
    critical: _pair(TrStatusLight.critical),
  );

  static final dark = AppStatusColors(
    neutral: _pair(TrStatusDark.neutral),
    info: _pair(TrStatusDark.info),
    success: _pair(TrStatusDark.success),
    warning: _pair(TrStatusDark.warning),
    danger: _pair(TrStatusDark.danger),
    critical: _pair(TrStatusDark.critical),
  );

  final StatusColorPair neutral;
  final StatusColorPair info;
  final StatusColorPair success;
  final StatusColorPair warning;
  final StatusColorPair danger;
  final StatusColorPair critical;

  StatusColorPair forTone(StatusTone tone) => switch (tone) {
    StatusTone.neutral => neutral,
    StatusTone.info => info,
    StatusTone.success => success,
    StatusTone.warning => warning,
    StatusTone.danger => danger,
    StatusTone.critical => critical,
  };

  @override
  AppStatusColors copyWith({
    StatusColorPair? neutral,
    StatusColorPair? info,
    StatusColorPair? success,
    StatusColorPair? warning,
    StatusColorPair? danger,
    StatusColorPair? critical,
  }) {
    return AppStatusColors(
      neutral: neutral ?? this.neutral,
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      critical: critical ?? this.critical,
    );
  }

  @override
  AppStatusColors lerp(covariant AppStatusColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppStatusColors(
      neutral: neutral.lerp(other.neutral, t),
      info: info.lerp(other.info, t),
      success: success.lerp(other.success, t),
      warning: warning.lerp(other.warning, t),
      danger: danger.lerp(other.danger, t),
      critical: critical.lerp(other.critical, t),
    );
  }
}

@immutable
class AppSeverityColors extends ThemeExtension<AppSeverityColors> {
  const AppSeverityColors({
    required this.minor,
    required this.moderate,
    required this.major,
    required this.safetyCritical,
  });

  static final light = AppSeverityColors(
    minor: AppStatusColors.light.neutral,
    moderate: AppStatusColors.light.warning,
    major: AppStatusColors.light.danger,
    safetyCritical: AppStatusColors.light.critical,
  );

  static final dark = AppSeverityColors(
    minor: AppStatusColors.dark.neutral,
    moderate: AppStatusColors.dark.warning,
    major: AppStatusColors.dark.danger,
    safetyCritical: AppStatusColors.dark.critical,
  );

  final StatusColorPair minor;
  final StatusColorPair moderate;
  final StatusColorPair major;
  final StatusColorPair safetyCritical;

  StatusColorPair forSeverity(AppSeverity severity) => switch (severity) {
    AppSeverity.minor => minor,
    AppSeverity.moderate => moderate,
    AppSeverity.major => major,
    AppSeverity.safetyCritical => safetyCritical,
  };

  @override
  AppSeverityColors copyWith({
    StatusColorPair? minor,
    StatusColorPair? moderate,
    StatusColorPair? major,
    StatusColorPair? safetyCritical,
  }) {
    return AppSeverityColors(
      minor: minor ?? this.minor,
      moderate: moderate ?? this.moderate,
      major: major ?? this.major,
      safetyCritical: safetyCritical ?? this.safetyCritical,
    );
  }

  @override
  AppSeverityColors lerp(covariant AppSeverityColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppSeverityColors(
      minor: minor.lerp(other.minor, t),
      moderate: moderate.lerp(other.moderate, t),
      major: major.lerp(other.major, t),
      safetyCritical: safetyCritical.lerp(other.safetyCritical, t),
    );
  }
}

@immutable
class AppBrandColors extends ThemeExtension<AppBrandColors> {
  const AppBrandColors({
    required this.strategy,
    required this.fill,
    required this.onFill,
    required this.largeFill,
    required this.onLargeFill,
    required this.ink,
    required this.container,
    required this.onContainer,
  });

  final AppColorStrategy strategy;
  final Color fill;
  final Color onFill;
  final Color largeFill;
  final Color onLargeFill;
  final Color ink;
  final Color container;
  final Color onContainer;

  @override
  AppBrandColors copyWith({
    AppColorStrategy? strategy,
    Color? fill,
    Color? onFill,
    Color? largeFill,
    Color? onLargeFill,
    Color? ink,
    Color? container,
    Color? onContainer,
  }) {
    return AppBrandColors(
      strategy: strategy ?? this.strategy,
      fill: fill ?? this.fill,
      onFill: onFill ?? this.onFill,
      largeFill: largeFill ?? this.largeFill,
      onLargeFill: onLargeFill ?? this.onLargeFill,
      ink: ink ?? this.ink,
      container: container ?? this.container,
      onContainer: onContainer ?? this.onContainer,
    );
  }

  @override
  AppBrandColors lerp(covariant AppBrandColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppBrandColors(
      strategy: t < 0.5 ? strategy : other.strategy,
      fill: Color.lerp(fill, other.fill, t)!,
      onFill: Color.lerp(onFill, other.onFill, t)!,
      largeFill: Color.lerp(largeFill, other.largeFill, t)!,
      onLargeFill: Color.lerp(onLargeFill, other.onLargeFill, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      container: Color.lerp(container, other.container, t)!,
      onContainer: Color.lerp(onContainer, other.onContainer, t)!,
    );
  }
}

abstract final class AppBreakpoints {
  static const double phone = TrBreakpoints.phone;
  static const double tablet = TrBreakpoints.tablet;
  static const double desktop = TrBreakpoints.desktop;
}

extension AppColorSchemeTokens on ColorScheme {
  Color get surfaceLowest => surfaceContainerLowest;

  Color get focus =>
      brightness == Brightness.dark ? TrColorDark.focus : TrColorLight.focus;

  Color get overlay => brightness == Brightness.dark
      ? TrColorDark.overlay
      : TrColorLight.overlay;
}

abstract final class AppTheme {
  static ThemeData get light => build(brightness: Brightness.light);

  static ThemeData get dark => build(brightness: Brightness.dark);

  static ThemeData get lightDeepGreen =>
      build(colorStrategy: AppColorStrategy.deepGreenFill);

  static ThemeData get darkDeepGreen => build(
    brightness: Brightness.dark,
    colorStrategy: AppColorStrategy.deepGreenFill,
  );

  static ThemeData build({
    Brightness brightness = Brightness.light,
    AppColorStrategy colorStrategy = AppColorStrategy.emeraldFill,
    AppArabicFont arabicFont = AppArabicFont.notoSansArabic,
    bool isArabic = false,
  }) {
    final isLight = brightness == Brightness.light;
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final c = isLight ? _lightColors : _darkColors;
    final brandToken = colorStrategy == AppColorStrategy.emeraldFill
        ? (isLight ? TrBrandLight.emeraldFill : TrBrandDark.emeraldFill)
        : (isLight ? TrBrandLight.deepGreenFill : TrBrandDark.deepGreenFill);
    final brand = AppBrandColors(
      strategy: colorStrategy,
      fill: brandToken.fill,
      onFill: brandToken.onFill,
      largeFill: isLight ? TrColorLight.primaryLarge : TrColorDark.primaryLarge,
      onLargeFill: isLight
          ? TrColorLight.onPrimaryLarge
          : TrColorDark.onPrimaryLarge,
      ink: brandToken.ink,
      container: brandToken.container,
      onContainer: brandToken.onContainer,
    );
    final scheme =
        ColorScheme.fromSeed(
          seedColor: brand.ink,
          brightness: brightness,
        ).copyWith(
          primary: brand.ink,
          onPrimary: isLight
              ? TrColorLight.surfaceLowest
              : TrColorDark.surfaceLowest,
          primaryContainer: brand.container,
          onPrimaryContainer: brand.onContainer,
          secondary: c.secondary,
          onSecondary: c.onSecondary,
          secondaryContainer: c.secondaryContainer,
          onSecondaryContainer: c.onSecondaryContainer,
          surface: c.surface,
          onSurface: c.onSurface,
          surfaceContainerLowest: c.surfaceLowest,
          surfaceContainerLow: c.surfaceLow,
          surfaceContainer: c.surfaceContainer,
          surfaceContainerHigh: c.surfaceHigh,
          surfaceContainerHighest: c.surfaceHighest,
          onSurfaceVariant: c.onSurfaceVariant,
          outline: c.outline,
          outlineVariant: c.outlineVariant,
          error: c.error,
          onError: c.onError,
          errorContainer: c.errorContainer,
          onErrorContainer: c.onErrorContainer,
          inverseSurface: c.inverseSurface,
          onInverseSurface: c.onInverseSurface,
          scrim: c.scrim,
        );
    final arabicFamily = arabicFont == AppArabicFont.notoSansArabic
        ? TrFontFamilies.arabicDefault
        : TrFontFamilies.arabicAlternative;
    final type = isArabic ? const _ArabicTypeScale() : const _LatinTypeScale();
    TextStyle style(TrTypeStyleToken token) => TextStyle(
      color: c.onSurface,
      fontFamily: TrFontFamilies.latin,
      fontFamilyFallback: <String>[
        arabicFamily,
        TrFontFamilies.cyrillicFallback,
        TrFontFamilies.cjkFallback,
      ],
      fontSize: token.size,
      height: token.height,
      fontWeight: _fontWeight(token.weight),
      letterSpacing: token.tracking,
    );
    final textTheme = base.textTheme.copyWith(
      displayLarge: style(type.display),
      displayMedium: style(type.headlineXl),
      displaySmall: style(type.headlineLg),
      headlineLarge: style(type.headlineLg),
      headlineMedium: style(type.headlineMd),
      headlineSmall: style(type.titleLg),
      titleLarge: style(type.titleLg),
      titleMedium: style(type.titleLg),
      titleSmall: style(type.labelLg),
      bodyLarge: style(type.bodyLg),
      bodyMedium: style(type.bodyMd),
      bodySmall: style(type.bodySm),
      labelLarge: style(type.labelLg),
      labelMedium: style(type.labelMd),
      labelSmall: style(type.labelSm),
    );
    const spacing = AppSpacingTokens.standard;
    const radii = AppRadiiTokens.standard;
    const sizing = AppSizingTokens.standard;
    final shadows = AppShadowTokens(
      card: TrShadows.card,
      floating: TrShadows.floating,
      button: colorStrategy == AppColorStrategy.emeraldFill
          ? TrShadows.buttonEmerald
          : TrShadows.buttonDeepGreen,
      buttonSubtle: TrShadows.buttonSubtle,
      focus: (isLight ? TrShadows.focusLight : TrShadows.focusDark).first,
      focusRing: isLight ? TrShadows.focusLight : TrShadows.focusDark,
    );
    final statusColors = isLight ? AppStatusColors.light : AppStatusColors.dark;
    final severityColors = isLight
        ? AppSeverityColors.light
        : AppSeverityColors.dark;
    return base.copyWith(
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceLowest,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(
            sizing.technicianPrimaryHeight,
            sizing.buttonHeight,
          ),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.xl,
            vertical: spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.pill),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(sizing.targetMin, sizing.targetMin),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.pill),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(sizing.targetMin, sizing.targetMin),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.xl,
            vertical: spacing.md,
          ),
          side: BorderSide(color: scheme.outline, width: sizing.borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.pill),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceLowest,
        surfaceTintColor: c.surfaceLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.card),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: spacing.lg,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.lg,
          vertical: spacing.xs,
        ),
        minVerticalPadding: spacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surfaceLowest,
        indicatorColor: brand.container,
        selectedIconTheme: IconThemeData(color: brand.onContainer),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: brand.onContainer,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceLowest,
        indicatorColor: brand.container,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: brand.ink,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelMedium,
        dividerColor: scheme.outlineVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        spacing,
        radii,
        shadows,
        sizing,
        AppMotionTokens.standard,
        statusColors,
        severityColors,
        brand,
      ],
    );
  }
}

ThemeData buildAppTheme({
  Brightness brightness = Brightness.light,
  AppColorStrategy colorStrategy = AppColorStrategy.emeraldFill,
  AppArabicFont arabicFont = AppArabicFont.notoSansArabic,
  bool isArabic = false,
}) => AppTheme.build(
  brightness: brightness,
  colorStrategy: colorStrategy,
  arabicFont: arabicFont,
  isArabic: isArabic,
);

extension AppThemeContext on BuildContext {
  AppSpacingTokens get spacing =>
      Theme.of(this).extension<AppSpacingTokens>() ?? AppSpacingTokens.standard;

  AppRadiiTokens get radii =>
      Theme.of(this).extension<AppRadiiTokens>() ?? AppRadiiTokens.standard;

  AppShadowTokens get shadows =>
      Theme.of(this).extension<AppShadowTokens>() ?? _fallbackShadows;

  AppSizingTokens get sizing =>
      Theme.of(this).extension<AppSizingTokens>() ?? AppSizingTokens.standard;

  AppMotionTokens get motion =>
      Theme.of(this).extension<AppMotionTokens>() ?? AppMotionTokens.standard;

  AppStatusColors get statusColors =>
      Theme.of(this).extension<AppStatusColors>() ?? AppStatusColors.light;

  AppSeverityColors get severityColors =>
      Theme.of(this).extension<AppSeverityColors>() ?? AppSeverityColors.light;

  AppBrandColors get brand =>
      Theme.of(this).extension<AppBrandColors>() ?? _fallbackBrand;

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  bool get isArabic =>
      Directionality.of(this) == TextDirection.rtl ||
      Localizations.localeOf(this).languageCode == 'ar';

  Duration motionDuration(Duration normal) =>
      ReduceMotion.duration(this, normal);

  /// Large primary technician action label (19 px bold, P1).
  TextStyle get largeButtonTextStyle {
    final token = isArabic ? TrTypeArabic.largeButton : TrType.largeButton;
    return TextStyle(
      color: colors.onSurface,
      fontFamily: TrFontFamilies.latin,
      fontFamilyFallback: const <String>[
        TrFontFamilies.arabicDefault,
        TrFontFamilies.cyrillicFallback,
        TrFontFamilies.cjkFallback,
      ],
      fontSize: token.size,
      height: token.height,
      fontWeight: _fontWeight(token.weight),
      letterSpacing: token.tracking,
    );
  }
}

final AppShadowTokens _fallbackShadows = AppShadowTokens(
  card: TrShadows.card,
  floating: TrShadows.floating,
  button: TrShadows.buttonEmerald,
  buttonSubtle: TrShadows.buttonSubtle,
  focus: TrShadows.focusLight.first,
  focusRing: TrShadows.focusLight,
);

final AppBrandColors _fallbackBrand = AppBrandColors(
  strategy: AppColorStrategy.emeraldFill,
  fill: TrBrandLight.emeraldFill.fill,
  onFill: TrBrandLight.emeraldFill.onFill,
  largeFill: TrColorLight.primaryLarge,
  onLargeFill: TrColorLight.onPrimaryLarge,
  ink: TrBrandLight.emeraldFill.ink,
  container: TrBrandLight.emeraldFill.container,
  onContainer: TrBrandLight.emeraldFill.onContainer,
);

abstract class _TypeScale {
  TrTypeStyleToken get display;
  TrTypeStyleToken get headlineXl;
  TrTypeStyleToken get headlineLg;
  TrTypeStyleToken get headlineMd;
  TrTypeStyleToken get titleLg;
  TrTypeStyleToken get bodyLg;
  TrTypeStyleToken get bodyMd;
  TrTypeStyleToken get bodySm;
  TrTypeStyleToken get labelLg;
  TrTypeStyleToken get labelMd;
  TrTypeStyleToken get labelSm;
}

class _LatinTypeScale implements _TypeScale {
  const _LatinTypeScale();
  @override
  TrTypeStyleToken get display => TrType.display;
  @override
  TrTypeStyleToken get headlineXl => TrType.headlineXl;
  @override
  TrTypeStyleToken get headlineLg => TrType.headlineLg;
  @override
  TrTypeStyleToken get headlineMd => TrType.headlineMd;
  @override
  TrTypeStyleToken get titleLg => TrType.titleLg;
  @override
  TrTypeStyleToken get bodyLg => TrType.bodyLg;
  @override
  TrTypeStyleToken get bodyMd => TrType.bodyMd;
  @override
  TrTypeStyleToken get bodySm => TrType.bodySm;
  @override
  TrTypeStyleToken get labelLg => TrType.labelLg;
  @override
  TrTypeStyleToken get labelMd => TrType.labelMd;
  @override
  TrTypeStyleToken get labelSm => TrType.labelSm;
}

class _ArabicTypeScale implements _TypeScale {
  const _ArabicTypeScale();
  @override
  TrTypeStyleToken get display => TrTypeArabic.display;
  @override
  TrTypeStyleToken get headlineXl => TrTypeArabic.headlineXl;
  @override
  TrTypeStyleToken get headlineLg => TrTypeArabic.headlineLg;
  @override
  TrTypeStyleToken get headlineMd => TrTypeArabic.headlineMd;
  @override
  TrTypeStyleToken get titleLg => TrTypeArabic.titleLg;
  @override
  TrTypeStyleToken get bodyLg => TrTypeArabic.bodyLg;
  @override
  TrTypeStyleToken get bodyMd => TrTypeArabic.bodyMd;
  @override
  TrTypeStyleToken get bodySm => TrTypeArabic.bodySm;
  @override
  TrTypeStyleToken get labelLg => TrTypeArabic.labelLg;
  @override
  TrTypeStyleToken get labelMd => TrTypeArabic.labelMd;
  @override
  TrTypeStyleToken get labelSm => TrTypeArabic.labelSm;
}

FontWeight _fontWeight(int weight) => switch (weight) {
  100 => FontWeight.w100,
  200 => FontWeight.w200,
  300 => FontWeight.w300,
  400 => FontWeight.w400,
  500 => FontWeight.w500,
  600 => FontWeight.w600,
  700 => FontWeight.w700,
  800 => FontWeight.w800,
  _ => FontWeight.w900,
};

StatusColorPair _pair(TrStatusPair token) =>
    StatusColorPair(foreground: token.foreground, background: token.background);

double _lerp(double a, double b, double t) => a + (b - a) * t;

Duration _lerpDuration(Duration a, Duration b, double t) => Duration(
  microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
      .round(),
);

@immutable
class _ColorSet {
  const _ColorSet({
    required this.surface,
    required this.surfaceLowest,
    required this.surfaceLow,
    required this.surfaceContainer,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.focus,
    required this.overlay,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
  });

  final Color surface;
  final Color surfaceLowest;
  final Color surfaceLow;
  final Color surfaceContainer;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color focus;
  final Color overlay;
  final Color scrim;
  final Color inverseSurface;
  final Color onInverseSurface;
}

const _lightColors = _ColorSet(
  surface: TrColorLight.surface,
  surfaceLowest: TrColorLight.surfaceLowest,
  surfaceLow: TrColorLight.surfaceLow,
  surfaceContainer: TrColorLight.surfaceContainer,
  surfaceHigh: TrColorLight.surfaceHigh,
  surfaceHighest: TrColorLight.surfaceHighest,
  onSurface: TrColorLight.onSurface,
  onSurfaceVariant: TrColorLight.onSurfaceVariant,
  outline: TrColorLight.outline,
  outlineVariant: TrColorLight.outlineVariant,
  secondary: TrColorLight.secondary,
  onSecondary: TrColorLight.onSecondary,
  secondaryContainer: TrColorLight.secondaryContainer,
  onSecondaryContainer: TrColorLight.onSecondaryContainer,
  error: TrColorLight.error,
  onError: TrColorLight.onError,
  errorContainer: TrColorLight.errorContainer,
  onErrorContainer: TrColorLight.onErrorContainer,
  focus: TrColorLight.focus,
  overlay: TrColorLight.overlay,
  scrim: TrColorLight.scrim,
  inverseSurface: TrColorLight.inverseSurface,
  onInverseSurface: TrColorLight.onInverseSurface,
);

const _darkColors = _ColorSet(
  surface: TrColorDark.surface,
  surfaceLowest: TrColorDark.surfaceLowest,
  surfaceLow: TrColorDark.surfaceLow,
  surfaceContainer: TrColorDark.surfaceContainer,
  surfaceHigh: TrColorDark.surfaceHigh,
  surfaceHighest: TrColorDark.surfaceHighest,
  onSurface: TrColorDark.onSurface,
  onSurfaceVariant: TrColorDark.onSurfaceVariant,
  outline: TrColorDark.outline,
  outlineVariant: TrColorDark.outlineVariant,
  secondary: TrColorDark.secondary,
  onSecondary: TrColorDark.onSecondary,
  secondaryContainer: TrColorDark.secondaryContainer,
  onSecondaryContainer: TrColorDark.onSecondaryContainer,
  error: TrColorDark.error,
  onError: TrColorDark.onError,
  errorContainer: TrColorDark.errorContainer,
  onErrorContainer: TrColorDark.onErrorContainer,
  focus: TrColorDark.focus,
  overlay: TrColorDark.overlay,
  scrim: TrColorDark.scrim,
  inverseSurface: TrColorDark.inverseSurface,
  onInverseSurface: TrColorDark.onInverseSurface,
);

