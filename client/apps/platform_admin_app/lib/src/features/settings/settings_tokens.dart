import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../platform_theme.dart';

/// Local visual language for the redesigned Settings landing.
///
/// Deliberately scoped to this screen: the house control radius (999 pill) stays
/// untouched everywhere else, while this screen uses the 14px button family the
/// redesign calls for. See the report for the divergence note.
abstract final class DeckRadius {
  static const double button = 14;
  static const double chip = 999;
  static const double card = 16;
  static const double hero = 20;
  static const double dialog = 20;
  static const double tile = 10;
}

abstract final class DeckSize {
  static const double buttonHeight = 48;
  static const double chipHeight = 28;
  static const double rowHeight = 64;
  static const double heroNumber = 64;
}

abstract final class DeckMotion {
  static const Duration enter = Duration(milliseconds: 220);
  static const Duration feedback = Duration(milliseconds: 120);
}

/// One palette object resolved once per screen; widgets never branch on brightness.
@immutable
class DeckPalette {
  const DeckPalette({
    required this.canvas,
    required this.surface,
    required this.hero,
    required this.heroInk,
    required this.heroMuted,
    required this.heroAccent,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  final Color canvas;
  final Color surface;
  final Color hero;
  final Color heroInk;
  final Color heroMuted;
  final Color heroAccent;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color warning;
  final Color danger;
  final Color skeletonBase;
  final Color skeletonHighlight;

  static const light = DeckPalette(
    canvas: PtTheme.canvas,
    surface: PtTheme.white,
    hero: Fx.darkInk,
    heroInk: Colors.white,
    heroMuted: Color(0xFFB9D8CC),
    heroAccent: Fx.emerald,
    ink: PtTheme.ink,
    muted: PtTheme.muted,
    faint: Color(0xFF8A929C),
    border: PtTheme.border,
    accent: PtTheme.deepGreen,
    accentSoft: Color(0xFFE7F1EE),
    success: PtTheme.emerald,
    warning: PtTheme.amber,
    danger: PtTheme.rose,
    skeletonBase: PtTheme.border,
    skeletonHighlight: Colors.white,
  );

  static const dark = DeckPalette(
    canvas: Color(0xFF101319),
    surface: Color(0xFF191D25),
    hero: Color(0xFF0B3024),
    heroInk: Color(0xFFF2F6F4),
    heroMuted: Color(0xFFA7C9BB),
    heroAccent: Color(0xFF4ADEA8),
    ink: Color(0xFFECEFF3),
    muted: Color(0xFFA8AFBC),
    faint: Color(0xFF7C8492),
    border: Color(0xFF2C323D),
    accent: Color(0xFF34D399),
    accentSoft: Color(0xFF143B2D),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFFB7185),
    skeletonBase: Color(0xFF252B35),
    skeletonHighlight: Color(0xFF353D49),
  );

  static DeckPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// All type on this screen goes through one place: real font, real tabular
/// figures for numbers, and an explicit no-decoration so inherited link styles
/// can never leak into the design proof or the product.
abstract final class DeckType {
  static TextStyle style(
    double size,
    double line,
    FontWeight weight,
    Color color, {
    double tracking = 0,
    bool tabular = false,
  }) {
    final base = Fx.text(
      size,
      line,
      weight,
      tracking,
      color: color,
    ).copyWith(decoration: TextDecoration.none);
    if (!tabular) return base;
    return base.copyWith(
      fontFeatures: <FontFeature>[const FontFeature.tabularFigures()],
    );
  }
}
