import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../../../inspection_models.dart';
import '../jobs_queue_format.dart';
import '../jobs_queue_primitives.dart';
import '../jobs_queue_style.dart';
import '../queue_model.dart';
import 'job_row.dart';

/// The answer to "what do I do now", above every list section.
///
/// Brand-ink card: time, vehicle, plate, item progress and one primary action
/// whose verb is derived from the job state by [verbFor].
class NowCard extends StatelessWidget {
  const NowCard({
    required this.job,
    required this.verb,
    required this.eyebrow,
    required this.onOpen,
    super.key,
  });

  final JobSummary job;
  final QueueVerb verb;

  /// The job's day label, so overdue work is visibly overdue in the card.
  final String eyebrow;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final brand = context.brand;
    final time = queueSlotLabel(job);
    final plate = (job.vehiclePlate ?? '').trim();
    final vehicle = queueVehicleLabel(job);
    final verbLabel = queueVerbLabel(t, verb);
    final items = job.totalItems > 0
        ? t(TechnicianKeys.technicianQueueItems, {
            'done': job.completedItems,
            'total': job.totalItems,
          })
        : '';
    final soft = Colors.white.withValues(alpha: 0.74);

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(18),
      decoration: BoxDecoration(
        color: brand.ink,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: queueEyebrow(context, color: soft),
                ),
              ),
              if (time.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  time,
                  textDirection: TextDirection.ltr,
                  style: queueText(
                    context,
                    26,
                    weight: FontWeight.w800,
                    height: 30,
                    tracking: -0.4,
                    tabular: true,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            vehicle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: queueText(
              context,
              20,
              weight: FontWeight.w800,
              height: 26,
              tracking: -0.3,
              color: Colors.white,
            ),
          ),
          if (plate.isNotEmpty || items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (plate.isNotEmpty)
                  QueuePlate(plate, large: true, onDark: true),
                if (items.isNotEmpty)
                  Text(
                    items,
                    textDirection: TextDirection.ltr,
                    style: queueMeta(
                      context,
                      color: soft,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
          if (job.totalItems > 0) ...[
            const SizedBox(height: 14),
            QueueProgressBar(
              value: job.completedItems,
              total: job.totalItems,
              onDark: true,
            ),
          ],
          const SizedBox(height: 16),
          QueueButton(
            label: verbLabel,
            variant: QueueButtonVariant.onDark,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
