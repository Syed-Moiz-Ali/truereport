import 'package:flutter/material.dart';

/// Local visual tokens for the platform dashboard.
///
/// Divergence: the product ships a single light theme. This screen defines a
/// matching dark palette so the operations surface can be verified in dark
/// without touching the shared shell. Nothing else in the app reads it.
@immutable
class DashboardPalette {
  const DashboardPalette({
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.border,
    required this.borderStrong,
    required this.hairline,
    required this.hover,
    required this.track,
    required this.accent,
    required this.accentHover,
    required this.good,
    required this.goodSoft,
    required this.warn,
    required this.warnSoft,
    required this.bad,
    required this.badSoft,
    required this.info,
    required this.infoSoft,
    required this.slabTop,
    required this.slabBottom,
    required this.railA,
    required this.railB,
    required this.railWarn,
    required this.onSlab,
    required this.onSlabMuted,
  });

  final Color canvas;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color border;
  final Color borderStrong;
  final Color hairline;
  final Color hover;
  final Color track;
  final Color accent;
  final Color accentHover;
  final Color good;
  final Color goodSoft;
  final Color warn;
  final Color warnSoft;
  final Color bad;
  final Color badSoft;
  final Color info;
  final Color infoSoft;
  final Color slabTop;
  final Color slabBottom;
  final Color railA;
  final Color railB;
  final Color railWarn;
  final Color onSlab;
  final Color onSlabMuted;

  static DashboardPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static const light = DashboardPalette(
    canvas: Color(0xFFF4F3F8),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1A1B1F),
    inkSoft: Color(0xFF3B3B45),
    muted: Color(0xFF5E5D69),
    border: Color(0xFFE9E7ED),
    borderStrong: Color(0xFFD5D2DE),
    hairline: Color(0xFFEEEDF3),
    hover: Color(0xFFF7F6FB),
    track: Color(0xFFEDEBF3),
    accent: Color(0xFF006C49),
    accentHover: Color(0xFF00553A),
    good: Color(0xFF0F7B57),
    goodSoft: Color(0xFFE8F4EF),
    warn: Color(0xFFB45309),
    warnSoft: Color(0xFFFFF8EC),
    bad: Color(0xFFB3261E),
    badSoft: Color(0xFFFCEDEC),
    info: Color(0xFF1D4ED8),
    infoSoft: Color(0xFFEEF2FE),
    slabTop: Color(0xFF06251B),
    slabBottom: Color(0xFF0A3628),
    railA: Color(0xFF5FD3A9),
    railB: Color(0xFF9BE3C6),
    railWarn: Color(0xFFF0B26A),
    onSlab: Color(0xFFFFFFFF),
    onSlabMuted: Color(0xFF9DB5A9),
  );

  static const dark = DashboardPalette(
    canvas: Color(0xFF0E1210),
    surface: Color(0xFF151A17),
    ink: Color(0xFFF1F1EA),
    inkSoft: Color(0xFFD6D8D0),
    muted: Color(0xFF9AA199),
    border: Color(0xFF28302B),
    borderStrong: Color(0xFF3A453D),
    hairline: Color(0xFF222A25),
    hover: Color(0xFF1B221E),
    track: Color(0xFF232B26),
    accent: Color(0xFF47BE94),
    accentHover: Color(0xFF5FD3A9),
    good: Color(0xFF52C296),
    goodSoft: Color(0xFF143128),
    warn: Color(0xFFE0A55B),
    warnSoft: Color(0xFF2A2115),
    bad: Color(0xFFE8776B),
    badSoft: Color(0xFF331A18),
    info: Color(0xFF7FB2FF),
    infoSoft: Color(0xFF16233A),
    slabTop: Color(0xFF0A2A1E),
    slabBottom: Color(0xFF0D3527),
    railA: Color(0xFF5FD3A9),
    railB: Color(0xFF9BE3C6),
    railWarn: Color(0xFFF0B26A),
    onSlab: Color(0xFFF3F7F3),
    onSlabMuted: Color(0xFF9DB5A9),
  );
}
