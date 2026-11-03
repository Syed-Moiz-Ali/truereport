import 'package:design_system/src/reduce_motion.dart';
import 'package:flutter/material.dart';

enum StatusTone { neutral, info, success, warning, danger, critical }

@immutable
class AppSpacingTokens extends ThemeExtension<AppSpacingTokens> {
  const AppSpacingTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.huge,
  });

  static const standard = AppSpacingTokens(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    xxl: 32,
    huge: 48,
  );

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double huge;

  @override
  AppSpacingTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? huge,
  }) {
    return AppSpacingTokens(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      huge: huge ?? this.huge,
    );
  }

  @override
  AppSpacingTokens lerp(covariant AppSpacingTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return AppSpacingTokens(
      xs: _lerp(xs, other.xs, t),
      sm: _lerp(sm, other.sm, t),
      md: _lerp(md, other.md, t),
      lg: _lerp(lg, other.lg, t),
      xl: _lerp(xl, other.xl, t),
      xxl: _lerp(xxl, other.xxl, t),
      huge: _lerp(huge, other.huge, t),
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
    required this.pill,
  });

  static const standard = AppRadiiTokens(
    sm: 4,
    md: 8,
    lg: 12,
    xl: 16,
    pill: 999,
  );

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double pill;

  @override
  AppRadiiTokens copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? pill,
  }) {
    return AppRadiiTokens(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
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
      pill: _lerp(pill, other.pill, t),
    );
  }
}

@immutable
class AppMotionTokens extends ThemeExtension<AppMotionTokens> {
  const AppMotionTokens({
    required this.fast,
    required this.normal,
    required this.slow,
    required this.enterCurve,
    required this.exitCurve,
  });

  static const standard = AppMotionTokens(
    fast: Duration(milliseconds: 120),
    normal: Duration(milliseconds: 220),
    slow: Duration(milliseconds: 320),
    enterCurve: Curves.easeOutCubic,
    exitCurve: Curves.easeInCubic,
  );

  final Duration fast;
  final Duration normal;
  final Duration slow;
  final Curve enterCurve;
  final Curve exitCurve;

  @override
  AppMotionTokens copyWith({
    Duration? fast,
    Duration? normal,
    Duration? slow,
    Curve? enterCurve,
    Curve? exitCurve,
  }) {
    return AppMotionTokens(
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
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

  static const light = AppStatusColors(
    neutral: StatusColorPair(
      foreground: Color(0xFF4D6670),
      background: Color(0xFFEDF1F3),
    ),
    info: StatusColorPair(
      foreground: Color(0xFF1D5C8A),
      background: Color(0xFFE5F0F8),
    ),
    success: StatusColorPair(
      foreground: Color(0xFF1F6B45),
      background: Color(0xFFE6F3EC),
    ),
    warning: StatusColorPair(
      foreground: Color(0xFF8A5A00),
      background: Color(0xFFFFF4D6),
    ),
    danger: StatusColorPair(
      foreground: Color(0xFFA3231F),
      background: Color(0xFFFBE9E7),
    ),
    critical: StatusColorPair(
      foreground: Color(0xFF7F1D1D),
      background: Color(0xFFF7DADA),
    ),
  );

  static const dark = AppStatusColors(
    neutral: StatusColorPair(
      foreground: Color(0xFFC3D4DA),
      background: Color(0xFF26373C),
    ),
    info: StatusColorPair(
      foreground: Color(0xFFB7DCF7),
      background: Color(0xFF173247),
    ),
    success: StatusColorPair(
      foreground: Color(0xFFB5E8C9),
      background: Color(0xFF173D2B),
    ),
    warning: StatusColorPair(
      foreground: Color(0xFFFFDFA3),
      background: Color(0xFF463611),
    ),
    danger: StatusColorPair(
      foreground: Color(0xFFFFC4BD),
      background: Color(0xFF4A1F1C),
    ),
    critical: StatusColorPair(
      foreground: Color(0xFFFFD0D0),
      background: Color(0xFF551C1C),
    ),
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

abstract final class AppBreakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

abstract final class AppTheme {
  static ThemeData get light => build(brightness: Brightness.light);

  static ThemeData get dark => build(brightness: Brightness.dark);

  static ThemeData build({Brightness brightness = Brightness.light}) {
    final isLight = brightness == Brightness.light;
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B3B4A),
          brightness: brightness,
        ).copyWith(
          primary: isLight ? const Color(0xFF0B3B4A) : const Color(0xFF8FD1D8),
          onPrimary: isLight
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF00363D),
          secondary: isLight
              ? const Color(0xFF0F6B6F)
              : const Color(0xFF82D0D4),
          surface: isLight ? const Color(0xFFF7FAFA) : const Color(0xFF0D1416),
          surfaceContainerLowest: isLight
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF090F11),
          surfaceContainerLow: isLight
              ? const Color(0xFFF1F5F5)
              : const Color(0xFF151E21),
          surfaceContainer: isLight
              ? const Color(0xFFEAF0F0)
              : const Color(0xFF1B262A),
          surfaceContainerHigh: isLight
              ? const Color(0xFFE3EBEC)
              : const Color(0xFF223035),
          surfaceContainerHighest: isLight
              ? const Color(0xFFDCE6E8)
              : const Color(0xFF2A3B41),
          error: isLight ? const Color(0xFFA3231F) : const Color(0xFFFFB4AB),
          onSurface: isLight
              ? const Color(0xFF17212B)
              : const Color(0xFFE4ECEF),
          outlineVariant: isLight
              ? const Color(0xFFD5E3E6)
              : const Color(0xFF33464C),
        );
    final textTheme = base.textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
    const spacing = AppSpacingTokens.standard;
    const radii = AppRadiiTokens.standard;
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
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
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
          minimumSize: Size(spacing.huge, spacing.huge),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.lg),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(spacing.huge, spacing.huge),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.lg),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(spacing.huge, spacing.huge),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.md,
          ),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radii.lg),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.xl),
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
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSecondaryContainer,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.secondary,
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
        AppMotionTokens.standard,
        isLight ? AppStatusColors.light : AppStatusColors.dark,
      ],
    );
  }
}

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) =>
    AppTheme.build(brightness: brightness);

extension AppThemeContext on BuildContext {
  AppSpacingTokens get spacing =>
      Theme.of(this).extension<AppSpacingTokens>() ?? AppSpacingTokens.standard;

  AppRadiiTokens get radii =>
      Theme.of(this).extension<AppRadiiTokens>() ?? AppRadiiTokens.standard;

  AppMotionTokens get motion =>
      Theme.of(this).extension<AppMotionTokens>() ?? AppMotionTokens.standard;

  AppStatusColors get statusColors =>
      Theme.of(this).extension<AppStatusColors>() ?? AppStatusColors.light;

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  Duration motionDuration(Duration normal) =>
      ReduceMotion.duration(this, normal);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

Duration _lerpDuration(Duration a, Duration b, double t) => Duration(
  microseconds: (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
      .round(),
);
