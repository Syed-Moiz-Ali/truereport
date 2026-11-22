import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

abstract final class PtTheme {
  // Shared control tokens. One family for buttons, fields and chips so the
  // whole admin stops drifting between 8/10/14px radii and 38/40/44px heights.
  static const double controlHeight = 48;
  static const double controlRadius = 999;
  static const double fieldHeight = 56;
  static const double fieldRadius = 16;
  static const double chipHeight = 30;
  static const double chipRadius = 999;

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

  /// The one field frame: 16px radius, 56px minimum height, centred hint.
  ///
  /// Used by [PlatformTextField], [PlatformDropdown] and the raw
  /// `TextField`/`TextFormField`s in dialogs, filters and inline editors so
  /// they cannot drift from the form tokens.
  static InputDecoration fieldDecoration({
    String? hint,
    String? helperText,
    Widget? prefixIcon,
    double hintSize = 13,
  }) {
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      helperMaxLines: 3,
      hintStyle: font(hintSize, lineHeight: 20, color: muted),
      filled: true,
      fillColor: canvas,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      constraints: const BoxConstraints(minHeight: fieldHeight),
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      border: outline(border, 1),
      enabledBorder: outline(border, 1),
      disabledBorder: outline(border, 1),
      focusedBorder: outline(deepGreen, 1.5),
      errorBorder: outline(rose, 1),
      focusedErrorBorder: outline(rose, 1.5),
    );
  }
}
