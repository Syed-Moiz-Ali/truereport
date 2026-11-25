import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

import '../../../inspection_models.dart';
import '../../jobs/queue/jobs_queue_format.dart';
import '../../jobs/queue/jobs_queue_primitives.dart';
import '../../jobs/queue/jobs_queue_style.dart';
import '../../../reference_ui.dart';

/// The summary header: back, vehicle identity, plate + reference, the served
/// status and the items count. Identity text wraps; nothing truncates it.
class SummaryHeader extends ConsumerWidget {
  const SummaryHeader({
    required this.job,
    required this.done,
    required this.total,
    required this.onBack,
    super.key,
  });

  final JobSummary? job;
  final int done;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final vehicle = job == null ? '' : queueVehicleLabel(job!);
    final plate = (job?.vehiclePlate ?? '').trim();
    final reference = (job?.reference ?? '').trim();
    final showReference =
        reference.isNotEmpty && plate.isNotEmpty && plate != reference;
    final status = job?.status ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: GestureDetector(
            onTap: onBack,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                size: 21,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vehicle,
                maxLines: 2,
                style: queueText(
                  context,
                  24,
                  weight: FontWeight.w800,
                  height: 29,
                  tracking: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  QueuePlate(plate.isNotEmpty ? plate : reference),
                  if (showReference)
                    Text(
                      reference,
                      key: const Key('summary-job-reference'),
                      textDirection: TextDirection.ltr,
                      style: queueText(
                        context,
                        12.5,
                        height: 18,
                        tabular: true,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (status.isNotEmpty)
                    QueueStatusChip(
                      label: jobStatusLabel(ref, status),
                      tone: jobStatusTone(ref, status),
                    ),
                  Text(
                    UiStrings.of(context)(TechnicianKeys.technicianQueueItems, {
                      'done': done,
                      'total': total,
                    }),
                    style: queueText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      height: 18,
                      tabular: true,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
