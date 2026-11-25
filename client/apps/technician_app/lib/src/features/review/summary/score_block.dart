import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../jobs/queue/jobs_queue_style.dart';

/// Score, grade and safety cap from the served summary: numbers large and
/// tabular, labels underneath. Omitted entirely when the summary carries
/// none of the three.
class ScoreBlock extends StatelessWidget {
  const ScoreBlock({
    required this.score,
    required this.grade,
    required this.capApplied,
    required this.capReason,
    super.key,
  });

  final int? score;
  final String? grade;
  final bool capApplied;
  final String capReason;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (score != null)
                Expanded(
                  child: _Stat(
                    value: '$score',
                    label: t(TechnicianKeys.technicianDraftScore),
                  ),
                ),
              if (grade != null)
                Expanded(
                  child: _Stat(
                    value: grade!,
                    label: t(TechnicianKeys.technicianGradeLabel),
                  ),
                ),
              if (capApplied)
                Expanded(
                  child: _Stat(
                    value: t(TechnicianKeys.technicianSummaryCapApplied),
                    label: t(TechnicianKeys.technicianSafetyCap),
                    valueColor: context.statusColors.warning.foreground,
                  ),
                ),
            ],
          ),
          if (capApplied && capReason.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              capReason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: queueText(
                context,
                12.5,
                height: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: queueText(
            context,
            36,
            weight: FontWeight.w800,
            height: 40,
            tracking: -0.7,
            tabular: true,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: queueText(
            context,
            11.5,
            weight: FontWeight.w700,
            height: 14,
            tracking: 0.6,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
