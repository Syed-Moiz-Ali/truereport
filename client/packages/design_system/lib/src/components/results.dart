import 'package:design_system/src/components/figma_components.dart';
import 'package:design_system/src/figma_spec.dart';
import 'package:design_system/src/tokens.dart';
import 'package:flutter/material.dart';

StatusTone _toneForResult(InspectionResult result) => switch (result) {
  InspectionResult.noIssueObserved => StatusTone.neutral,
  InspectionResult.attentionRecommended => StatusTone.warning,
  InspectionResult.defectFound => StatusTone.danger,
  InspectionResult.notChecked => StatusTone.neutral,
  InspectionResult.notApplicable => StatusTone.neutral,
  InspectionResult.couldNotVerify => StatusTone.warning,
};

IconData _iconForResult(InspectionResult result) => switch (result) {
  InspectionResult.noIssueObserved => Icons.check_circle_outline,
  InspectionResult.attentionRecommended => Icons.info_outline,
  InspectionResult.defectFound => Icons.warning_amber_rounded,
  InspectionResult.notChecked => Icons.remove_circle_outline,
  InspectionResult.notApplicable => Icons.block,
  InspectionResult.couldNotVerify => Icons.help_outline,
};

/// Single-select control for the six approved [InspectionResult] values.
///
/// The Figma `Severity Pill-Shaped Toggle Group` is a three-way pill. That
/// toggle is reproduced for the three main outcomes and the remaining three
/// results are rendered as a secondary chip row in the same visual language.
/// Labels are always supplied by the caller so no result wording is hardcoded.
class InspectionResultSelector extends StatelessWidget {
  const InspectionResultSelector({
    required this.labelBuilder,
    required this.selected,
    required this.onChanged,
    this.semanticLabelBuilder,
    this.results,
    this.enabled = true,
    this.groupLabel,
    super.key,
  });

  final String Function(InspectionResult result) labelBuilder;
  final String Function(InspectionResult result)? semanticLabelBuilder;
  final InspectionResult? selected;
  final ValueChanged<InspectionResult>? onChanged;
  final List<InspectionResult>? results;
  final bool enabled;
  final String? groupLabel;

  @override
  Widget build(BuildContext context) {
    final items = results ?? InspectionResult.values;
    final isEnabled = enabled && onChanged != null;
    final primary = items.take(3).toList(growable: false);
    final secondary = items.skip(3).toList(growable: false);
    final change = isEnabled ? onChanged! : null;
    final label = groupLabel;

    return Semantics(
      container: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (primary.isNotEmpty)
            FigmaThreeWaySelector<InspectionResult>(
              label: label ?? '',
              options: [
                for (final result in primary)
                  FigmaResultOption(
                    value: result,
                    label: labelBuilder(result),
                  ),
              ],
              selected: selected,
              onChanged: change,
              exact: false,
              semanticLabel: label,
            ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: FigmaGeometry.selectorLabelGap + 2),
            FigmaSecondaryResultChips<InspectionResult>(
              options: [
                for (final result in secondary)
                  FigmaResultOption(
                    value: result,
                    label: labelBuilder(result),
                  ),
              ],
              selected: selected,
              onChanged: change,
              semanticLabel: label,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact, read-only presentation of a single inspection result.
///
/// Provide [onTap] to turn the chip into an interactive target; the chip then
/// meets the 48 dp minimum target and exposes button semantics.
class InspectionResultChip extends StatelessWidget {
  const InspectionResultChip({
    required this.result,
    required this.label,
    this.semanticLabel,
    this.onTap,
    this.compact = false,
    super.key,
  });

  final InspectionResult result;
  final String label;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final sizing = context.sizing;
    final pair = context.statusColors.forTone(_toneForResult(result));
    final radius = BorderRadius.circular(radii.pill);
    final content = Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? spacing.sm : spacing.md,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(color: pair.background, borderRadius: radius),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: spacing.xs,
        runSpacing: spacing.xs,
        children: [
          Icon(
            _iconForResult(result),
            size: compact ? sizing.iconSm : sizing.iconMd,
            color: pair.foreground,
          ),
          Text(
            label,
            style:
                (compact ? context.texts.labelSmall : context.texts.labelMedium)
                    ?.copyWith(
                      color: pair.foreground,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: onTap == null
            ? content
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: sizing.targetMin),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: content,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Backwards-friendly alias for the compact chip presentation.
class InspectionResultBadge extends InspectionResultChip {
  const InspectionResultBadge({
    required super.result,
    required super.label,
    super.semanticLabel,
    super.onTap,
    super.key,
  }) : super(compact: true);
}
