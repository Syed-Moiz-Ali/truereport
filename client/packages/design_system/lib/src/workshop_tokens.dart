import 'package:flutter/material.dart';

/// Workshop Admin visual language (Phase 1 of the UI redesign).
///
/// The palette is a warm, paper-like surface set with one green accent. It is
/// deliberately calmer than the shared `AppBrandColors` emerald fill: no
/// shadows, hairline borders and a single control radius. Every app screen
/// reads these values from [WorkshopTokensContext.ws] — screens never inline
/// colours, radii, sizes or type.
///
/// Type styles are derived from the active [TextTheme] so the Latin family and
/// the Arabic/Cyrillic/CJK/Telugu fallbacks configured by `AppTheme.build`
/// survive unchanged. Arabic gets `letterSpacing: 0` because tracking breaks
/// Arabic shaping.
@immutable
class WorkshopTokens extends ThemeExtension<WorkshopTokens> {
  const WorkshopTokens({
    required this.canvas,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.border,
    required this.accent,
    required this.accentHover,
    required this.accentSoft,
    required this.onAccent,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.success,
    required this.successSoft,
    required this.focus,
    required this.cardRadius,
    required this.cardLargeRadius,
    required this.controlRadius,
    required this.chipRadius,
    required this.controlHeight,
    required this.touchTarget,
    required this.topBarHeight,
    required this.sidebarWidth,
    required this.railWidth,
    required this.contentMaxWidth,
    required this.pageGutterDesktop,
    required this.pageGutterTablet,
    required this.pageGutterPhone,
    required this.cardPadding,
    required this.cardPaddingDesktop,
    required this.pageTitle,
    required this.sectionTitle,
    required this.cardTitle,
    required this.body,
    required this.bodyStrong,
    required this.meta,
    required this.eyebrow,
    required this.panelHeadline,
    required this.panelBody,
  });

  /// Warm off-white page canvas.
  final Color canvas;

  /// White card / bar surface.
  final Color surface;

  /// Near-black primary ink.
  final Color ink;

  /// Cool muted secondary text.
  final Color muted;

  /// 1 px hairline border.
  final Color border;

  /// The single green accent.
  final Color accent;
  final Color accentHover;
  final Color accentSoft;

  /// Text/icon colour on [accent].
  final Color onAccent;

  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color success;
  final Color successSoft;

  /// Focus ring (matches the shared `TrColorLight.focus`).
  final Color focus;

  final double cardRadius;
  final double cardLargeRadius;
  final double controlRadius;
  final double chipRadius;

  final double controlHeight;
  final double touchTarget;
  final double topBarHeight;
  final double sidebarWidth;
  final double railWidth;
  final double contentMaxWidth;
  final double pageGutterDesktop;
  final double pageGutterTablet;
  final double pageGutterPhone;
  final double cardPadding;
  final double cardPaddingDesktop;

  final TextStyle pageTitle;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle meta;
  final TextStyle eyebrow;

  /// Brand-panel headline (dark surface). 34/42 w700.
  final TextStyle panelHeadline;

  /// Brand-panel supporting line (dark surface). 15/22 w400.
  final TextStyle panelBody;

  /// Convenience aliases for React/shadcn style token access.
  TextStyle get metadata => meta;
  Color get surfaceMuted => canvas;
  Color get inkSecondary => muted;
  Color get inkTertiary => muted.withValues(alpha: 0.7);

  /// 40-44px bold stat figure with tabular numbers.
  TextStyle get heroNumber => pageTitle.copyWith(
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Horizontal gutter for the given viewport width.
  double pageGutter(double width) {
    if (width >= 1000) {
      return pageGutterDesktop;
    }
    if (width >= 680) {
      return pageGutterTablet;
    }
    return pageGutterPhone;
  }

  /// Page padding for the given viewport width (gutter on both sides, the
  /// same value vertically).
  EdgeInsetsDirectional pagePadding(double width) {
    final gutter = pageGutter(width);
    return EdgeInsetsDirectional.symmetric(
      horizontal: gutter,
      vertical: gutter,
    );
  }

  /// Resolves the responsive page padding from the current window.
  EdgeInsetsDirectional pagePaddingOf(BuildContext context) =>
      pagePadding(MediaQuery.sizeOf(context).width);

  /// Card padding: 20 on phone/tablet, 24 on desktop.
  EdgeInsetsDirectional cardPaddingFor(double width) =>
      EdgeInsetsDirectional.all(
        width >= 1000 ? cardPaddingDesktop : cardPadding,
      );

  static WorkshopTokens standard(TextTheme textTheme) {
    // [TextStyle.height] is a line-height *multiplier*, not a pixel value.
    TextStyle style(
      TextStyle? base,
      double size,
      double lineHeight,
      FontWeight weight,
      double tracking,
    ) {
      return (base ?? const TextStyle()).copyWith(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        letterSpacing: tracking,
      );
    }

    return WorkshopTokens(
      canvas: const Color(0xFFF7F5F1),
      surface: const Color(0xFFFFFFFF),
      ink: const Color(0xFF1B1C19),
      muted: const Color(0xFF6A6F6A),
      border: const Color(0xFFE6E2DA),
      accent: const Color(0xFF0B6B4F),
      accentHover: const Color(0xFF095840),
      accentSoft: const Color(0xFFE8F2EC),
      onAccent: const Color(0xFFFFFFFF),
      warning: const Color(0xFFB45309),
      warningSoft: const Color(0xFFFDF3E2),
      danger: const Color(0xFFB42318),
      dangerSoft: const Color(0xFFFDEBE9),
      success: const Color(0xFF15803D),
      successSoft: const Color(0xFFE9F5EE),
      focus: const Color(0xFF0B63CE),
      cardRadius: 14,
      cardLargeRadius: 16,
      controlRadius: 10,
      chipRadius: 8,
      controlHeight: 52,
      touchTarget: 44,
      topBarHeight: 60,
      sidebarWidth: 256,
      railWidth: 72,
      contentMaxWidth: 1200,
      pageGutterDesktop: 32,
      pageGutterTablet: 20,
      pageGutterPhone: 16,
      cardPadding: 20,
      cardPaddingDesktop: 24,
      pageTitle: style(textTheme.titleLarge, 30, 38, FontWeight.w700, -0.4),
      sectionTitle: style(textTheme.titleLarge, 19, 26, FontWeight.w700, -0.1),
      cardTitle: style(textTheme.titleLarge, 15.5, 22, FontWeight.w700, 0),
      body: style(textTheme.bodyMedium, 14, 21, FontWeight.w400, 0),
      bodyStrong: style(textTheme.bodyMedium, 14, 21, FontWeight.w600, 0),
      meta: style(textTheme.bodySmall, 12.5, 18, FontWeight.w500, 0),
      eyebrow: style(textTheme.bodySmall, 11, 16, FontWeight.w600, 0.6),
      panelHeadline: style(textTheme.titleLarge, 34, 42, FontWeight.w700, -0.5),
      panelBody: style(textTheme.bodyMedium, 15, 22, FontWeight.w400, 0),
    );
  }

  @override
  WorkshopTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? border,
    Color? accent,
    Color? accentHover,
    Color? accentSoft,
    Color? onAccent,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? success,
    Color? successSoft,
    Color? focus,
    double? cardRadius,
    double? cardLargeRadius,
    double? controlRadius,
    double? chipRadius,
    double? controlHeight,
    double? touchTarget,
    double? topBarHeight,
    double? sidebarWidth,
    double? railWidth,
    double? contentMaxWidth,
    double? pageGutterDesktop,
    double? pageGutterTablet,
    double? pageGutterPhone,
    double? cardPadding,
    double? cardPaddingDesktop,
    TextStyle? pageTitle,
    TextStyle? sectionTitle,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? meta,
    TextStyle? eyebrow,
    TextStyle? panelHeadline,
    TextStyle? panelBody,
  }) {
    return WorkshopTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      focus: focus ?? this.focus,
      cardRadius: cardRadius ?? this.cardRadius,
      cardLargeRadius: cardLargeRadius ?? this.cardLargeRadius,
      controlRadius: controlRadius ?? this.controlRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      controlHeight: controlHeight ?? this.controlHeight,
      touchTarget: touchTarget ?? this.touchTarget,
      topBarHeight: topBarHeight ?? this.topBarHeight,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      railWidth: railWidth ?? this.railWidth,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      pageGutterDesktop: pageGutterDesktop ?? this.pageGutterDesktop,
      pageGutterTablet: pageGutterTablet ?? this.pageGutterTablet,
      pageGutterPhone: pageGutterPhone ?? this.pageGutterPhone,
      cardPadding: cardPadding ?? this.cardPadding,
      cardPaddingDesktop: cardPaddingDesktop ?? this.cardPaddingDesktop,
      pageTitle: pageTitle ?? this.pageTitle,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      meta: meta ?? this.meta,
      eyebrow: eyebrow ?? this.eyebrow,
      panelHeadline: panelHeadline ?? this.panelHeadline,
      panelBody: panelBody ?? this.panelBody,
    );
  }

  @override
  WorkshopTokens lerp(covariant WorkshopTokens? other, double t) {
    if (other == null) {
      return this;
    }
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => a + (b - a) * t;
    TextStyle s(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return WorkshopTokens(
      canvas: c(canvas, other.canvas),
      surface: c(surface, other.surface),
      ink: c(ink, other.ink),
      muted: c(muted, other.muted),
      border: c(border, other.border),
      accent: c(accent, other.accent),
      accentHover: c(accentHover, other.accentHover),
      accentSoft: c(accentSoft, other.accentSoft),
      onAccent: c(onAccent, other.onAccent),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      focus: c(focus, other.focus),
      cardRadius: d(cardRadius, other.cardRadius),
      cardLargeRadius: d(cardLargeRadius, other.cardLargeRadius),
      controlRadius: d(controlRadius, other.controlRadius),
      chipRadius: d(chipRadius, other.chipRadius),
      controlHeight: d(controlHeight, other.controlHeight),
      touchTarget: d(touchTarget, other.touchTarget),
      topBarHeight: d(topBarHeight, other.topBarHeight),
      sidebarWidth: d(sidebarWidth, other.sidebarWidth),
      railWidth: d(railWidth, other.railWidth),
      contentMaxWidth: d(contentMaxWidth, other.contentMaxWidth),
      pageGutterDesktop: d(pageGutterDesktop, other.pageGutterDesktop),
      pageGutterTablet: d(pageGutterTablet, other.pageGutterTablet),
      pageGutterPhone: d(pageGutterPhone, other.pageGutterPhone),
      cardPadding: d(cardPadding, other.cardPadding),
      cardPaddingDesktop: d(cardPaddingDesktop, other.cardPaddingDesktop),
      pageTitle: s(pageTitle, other.pageTitle),
      sectionTitle: s(sectionTitle, other.sectionTitle),
      cardTitle: s(cardTitle, other.cardTitle),
      body: s(body, other.body),
      bodyStrong: s(bodyStrong, other.bodyStrong),
      meta: s(meta, other.meta),
      eyebrow: s(eyebrow, other.eyebrow),
      panelHeadline: s(panelHeadline, other.panelHeadline),
      panelBody: s(panelBody, other.panelBody),
    );
  }
}

/// `context.ws` — the workshop kit token accessor.
extension WorkshopTokensContext on BuildContext {
  WorkshopTokens get ws {
    final theme = Theme.of(this);
    return theme.extension<WorkshopTokens>() ??
        WorkshopTokens.standard(theme.textTheme);
  }

  /// Workshop page scroll padding for the current window.
  EdgeInsetsDirectional get workshopPagePadding => ws.pagePaddingOf(this);
}
