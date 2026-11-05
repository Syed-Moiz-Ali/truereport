import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    required this.value,
    this.label,
    this.semanticsLabel,
    this.size,
    super.key,
  });

  final double value;
  final String? label;
  final String? semanticsLabel;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final fraction = value.clamp(0.0, 1.0).toDouble();
    final percent = (fraction * 100).round();
    final diameter = size ?? context.spacing.huge * 2;
    final strokeWidth = context.spacing.sm;
    final text = '$percent%';

    return Semantics(
      label: semanticsLabel ?? label ?? text,
      value: text,
      child: SizedBox.square(
        dimension: diameter,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fraction),
          duration: context.motionDuration(context.motion.normal),
          curve: context.motion.enterCurve,
          builder: (context, animated, child) {
            final animatedPercent = (animated * 100).round();
            return Stack(
              alignment: AlignmentDirectional.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: animated,
                    strokeWidth: strokeWidth,
                    color: context.brand.ink,
                    backgroundColor: context.colors.outlineVariant,
                    semanticsLabel: semanticsLabel ?? label,
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.all(context.spacing.md),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$animatedPercent%',
                      textDirection: TextDirection.ltr,
                      style: context.texts.headlineMedium?.copyWith(
                        color: context.brand.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AppCoverageBar extends StatelessWidget {
  const AppCoverageBar({
    required this.covered,
    required this.total,
    this.label,
    this.semanticsLabel,
    this.valueLabel,
    super.key,
  });

  final int covered;
  final int total;
  final String? label;
  final String? semanticsLabel;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    final fraction = total <= 0 ? 0.0 : (covered / total).clamp(0.0, 1.0);
    final percent = (fraction * 100).round();
    final countText = valueLabel ?? '$covered / $total';
    final colors = context.colors;

    final header = label == null
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              countText,
              textDirection: TextDirection.ltr,
              style: context.texts.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          )
        : Row(
            children: [
              Expanded(
                child: Text(
                  label!,
                  style: context.texts.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Text(
                countText,
                textDirection: TextDirection.ltr,
                style: context.texts.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          );

    return Semantics(
      label: semanticsLabel ?? label ?? countText,
      value: '$percent%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          SizedBox(height: context.spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.radii.pill),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: context.spacing.xs,
              color: context.brand.ink,
              backgroundColor: colors.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
