import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

abstract final class PtTheme {
  static const deepGreen = Color(0xFF006C49);
  static const emerald = Color(0xFF10B981);
  static const ink = Color(0xFF1A1B1F);
  static const muted = Color(0xFF5E5D69);
  static const border = Color(0xFFE9E7ED);
  static const canvas = Color(0xFFF4F3F8);
  static const white = Color(0xFFFFFFFF);
  static const darkNavText = Color(0xFF3C4A42);
  static const rose = Color(0xFFE11D48);
  static const amber = Color(0xFFD97706);
  static const gold = Color(0xFFB45309);

  static TextStyle font(
    double size, {
    double? lineHeight,
    FontWeight weight = FontWeight.w400,
    double tracking = 0,
    Color color = ink,
  }) {
    return Fx.text(
      size,
      lineHeight ?? (size * 1.3).roundToDouble(),
      weight,
      tracking,
      color: color,
    );
  }

  static TextStyle get pageTitle => font(
    24,
    lineHeight: 30,
    weight: FontWeight.w800,
    tracking: -0.4,
    color: ink,
  );

  static TextStyle get sectionTitle => font(
    16,
    lineHeight: 22,
    weight: FontWeight.w700,
    tracking: -0.2,
    color: ink,
  );

  static TextStyle get body =>
      font(13, lineHeight: 20, weight: FontWeight.w400, color: ink);

  static TextStyle get bodyMuted =>
      font(13, lineHeight: 20, weight: FontWeight.w400, color: muted);

  static TextStyle get label =>
      font(12, lineHeight: 16, weight: FontWeight.w600, color: muted);

  static TextStyle get caption =>
      font(11, lineHeight: 15, weight: FontWeight.w500, color: muted);
}
