import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A **test-only** dark palette for shell goldens.
///
/// The shipped app is light-only (`AppTheme` asserts light). This wrapper
/// replaces only the theme extensions the production widgets read, so the same
/// widgets can be photographed in a dark room without a shipped dark theme and
/// without touching `AppTheme`.
ThemeData darkProofTheme() {
  final light = AppTheme.build();
  const surface = Color(0xFF111417);
  const surfaceLowest = Color(0xFF171A1E);
  const surfaceLow = Color(0xFF1C2025);
  const surfaceContainer = Color(0xFF242A30);
  const surfaceHigh = Color(0xFF2C333A);
  const surfaceHighest = Color(0xFF353D45);
  const onSurface = Color(0xFFEDEFF1);
  const onSurfaceVariant = Color(0xFFAFB6BE);
  const outline = Color(0xFF87909A);
  const outlineVariant = Color(0xFF353D45);

  final scheme = light.colorScheme.copyWith(
    brightness: Brightness.dark,
    surface: surface,
    surfaceContainerLowest: surfaceLowest,
    surfaceContainerLow: surfaceLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHighest,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    primary: const Color(0xFF6EE7B7),
    onPrimary: const Color(0xFF06281D),
    primaryContainer: const Color(0xFF0E3327),
    onPrimaryContainer: const Color(0xFFB7F3D9),
    error: const Color(0xFFFCA5A5),
    onError: const Color(0xFF3A0B0B),
  );

  final brand = light.extension<AppBrandColors>()!.copyWith(
    fill: const Color(0xFF10B981),
    onFill: const Color(0xFF06281D),
    ink: const Color(0xFF34D399),
    container: const Color(0xFF0E3327),
    onContainer: const Color(0xFFB7F3D9),
  );

  const status = AppStatusColors(
    neutral: StatusColorPair(
      foreground: Color(0xFFCBD5E1),
      background: Color(0xFF2A3037),
    ),
    info: StatusColorPair(
      foreground: Color(0xFF93C5FD),
      background: Color(0xFF10243D),
    ),
    success: StatusColorPair(
      foreground: Color(0xFF6EE7B7),
      background: Color(0xFF10301F),
    ),
    warning: StatusColorPair(
      foreground: Color(0xFFFBBF24),
      background: Color(0xFF33260A),
    ),
    danger: StatusColorPair(
      foreground: Color(0xFFFCA5A5),
      background: Color(0xFF3A1515),
    ),
    critical: StatusColorPair(
      foreground: Color(0xFFFCA5A5),
      background: Color(0xFF3A1515),
    ),
  );

  final extensions = <ThemeExtension<dynamic>>[
    light.extension<AppSpacingTokens>()!,
    light.extension<AppRadiiTokens>()!,
    light.extension<AppShadowTokens>()!,
    light.extension<AppSizingTokens>()!,
    light.extension<AppMotionTokens>()!,
    light.extension<AppSeverityColors>()!,
    light.extension<WorkshopTokens>()!,
    brand,
    status,
  ];

  final texts = light.textTheme.apply(
    bodyColor: onSurface,
    displayColor: onSurface,
  );

  return light.copyWith(
    colorScheme: scheme,
    textTheme: texts,
    scaffoldBackgroundColor: surface,
    appBarTheme: light.appBarTheme.copyWith(
      backgroundColor: surface,
      foregroundColor: onSurface,
      titleTextStyle: texts.titleLarge,
    ),
    cardTheme: light.cardTheme.copyWith(color: surfaceLowest),
    dividerTheme: light.dividerTheme.copyWith(color: outlineVariant),
    extensions: extensions,
  );
}
