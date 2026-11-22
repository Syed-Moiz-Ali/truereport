import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Local geometry for the jobs queue: pill buttons, chips and fields, 56 px
/// controls, 16 px cards and 24 px sheets.
///
/// Divergence: `design_system` ships 24px cards. The queue uses this tighter
/// card family deliberately; see the handover notes.
abstract final class QueueMetrics {
  static const double buttonHeight = 56;
  static const double fieldHeight = 56;
  static const double radiusButton = 999;
  static const double radiusField = 999;
  static const double radiusCard = 16;
  static const double radiusSheet = 24;
  static const double radiusChip = 999;
  static const double contentMaxWidth = 560;
}

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

TextStyle queueText(
  BuildContext context,
  double size, {
  FontWeight weight = FontWeight.w400,
  double height = 1.45,
  Color? color,
  double tracking = 0,
  bool tabular = false,
}) {
  return context.texts.bodyMedium!.copyWith(
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: tracking,
    color: color ?? context.colors.onSurface,
    fontFeatures: tabular ? _tabular : null,
  );
}

TextStyle queueEyebrow(BuildContext context, {Color? color}) => queueText(
  context,
  11.5,
  weight: FontWeight.w700,
  height: 14,
  tracking: 0.9,
  color: color ?? context.colors.onSurfaceVariant,
);

TextStyle queueMeta(BuildContext context, {Color? color}) =>
    queueText(context, 12.5, height: 18, color: color);

TextStyle queueBody(BuildContext context, {Color? color}) =>
    queueText(context, 14.5, height: 22, color: color);

TextStyle queueTitle(BuildContext context) =>
    queueText(context, 30, weight: FontWeight.w700, height: 36, tracking: -0.6);

TextStyle queueSection(BuildContext context) =>
    queueText(context, 18, weight: FontWeight.w700, height: 24, tracking: -0.2);

/// Reveal motion that honours the platform "reduce motion" setting.
Widget queueReveal({
  required BuildContext context,
  required Widget child,
  bool visible = true,
}) {
  if (!visible) {
    return child;
  }
  final duration = context.motionDuration(const Duration(milliseconds: 220));
  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: duration,
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, (1 - value) * 8),
        child: child,
      ),
    ),
    child: child,
  );
}
