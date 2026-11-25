import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../jobs_queue_primitives.dart';
import '../jobs_queue_style.dart';
import 'deck_board.dart';
import 'deck_primary.dart';

/// The ≥1024 facts pane beside the deck: vehicle, plate, customer, status,
/// schedule and one "Open job" action.
///
/// Presentation only; the deck owns selection and the page owns navigation.
class DeckFactsPane extends StatelessWidget {
  const DeckFactsPane({
    required this.job,
    required this.scheduleLabel,
    required this.onOpen,
    super.key,
  });

  final DeckJob job;
  final String scheduleLabel;
  final VoidCallback onOpen;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            job.vehicle,
            style: queueText(
              context,
              20,
              weight: FontWeight.w800,
              height: 26,
              tracking: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (job.plate.isNotEmpty) QueuePlate(job.plate),
              Text(
                job.customer,
                style: queueText(
                  context,
                  13,
                  height: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 16),
          _FactRow(
            label: t(TechnicianKeys.technicianCustomer),
            child: Text(
              job.customer,
              style: queueText(
                context,
                15,
                weight: FontWeight.w600,
                height: 22,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FactRow(
            label: t(TechnicianKeys.status),
            child: QueueStatusChip(label: job.statusLabel, tone: job.tone),
          ),
          const SizedBox(height: 12),
          _FactRow(
            label: t(TechnicianKeys.technicianScheduledAt),
            child: Text(
              scheduleLabel,
              style: queueText(
                context,
                15,
                weight: FontWeight.w600,
                height: 22,
              ),
            ),
          ),
          if (job.reference.isNotEmpty) ...[
            const SizedBox(height: 12),
            _FactRow(
              label: t(TechnicianKeys.jobReferenceLabel),
              child: Text(
                job.reference,
                textDirection: TextDirection.ltr,
                style: queueText(
                  context,
                  13,
                  height: 18,
                  tabular: true,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          DeckPrimaryButton(
            label: t(TechnicianKeys.jobsOpenJob),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: queueEyebrow(context)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
