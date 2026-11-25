import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

import '../../../../inspection_models.dart';
import '../../../../reference_ui.dart';
import '../../../../shared/technician_intl.dart';
import '../jobs_queue_format.dart';
import '../jobs_queue_primitives.dart';
import '../jobs_queue_style.dart';

/// The tablet second pane: the selected job's facts and one explicit action.
///
/// It never embeds the inspection deck. Selecting a queue row only refreshes
/// this pane; opening the job is a deliberate tap on [onOpen].
class JobPreviewPane extends ConsumerWidget {
  const JobPreviewPane({required this.job, required this.onOpen, super.key});

  /// Null when the current filter has nothing selected.
  final JobSummary? job;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final selected = job;
    if (selected == null) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: QueueEmptyPanel(
              showRoute: false,
              title: t(TechnicianKeys.jobsSelectJob),
              body: t(TechnicianKeys.jobsNoSelection),
            ),
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context).toString();
    final language = Localizations.localeOf(context).languageCode;
    final plate = (selected.vehiclePlate ?? '').trim();
    final items = selected.totalItems > 0
        ? t(TechnicianKeys.technicianQueueItems, {
            'done': selected.completedItems,
            'total': selected.totalItems,
          })
        : '';
    final slot = queueSlotLabel(selected);
    final day = queueDayKey(selected);
    final schedule = [
      if (day != null) queueDayLabel(day, t, locale),
      if (slot.isNotEmpty) slot,
    ].join(' · ');
    final odometer = formatOdometerLocalized(
      selected.odometerValue,
      selected.odometerUnit,
      locale,
    );
    final template = selected.templateNameFor(language).trim();

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsetsDirectional.all(20),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selected.reference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: queueEyebrow(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    QueueStatusChip(
                      label: jobStatusLabel(ref, selected.status),
                      tone: jobStatusTone(ref, selected.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  queueVehicleLabel(selected),
                  maxLines: 2,
                  style: queueText(
                    context,
                    22,
                    weight: FontWeight.w800,
                    height: 28,
                    tracking: -0.4,
                  ),
                ),
                if (plate.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  QueuePlate(plate, large: true),
                ],
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(items, style: queueMeta(context)),
                ],
                if (selected.totalItems > 0) ...[
                  const SizedBox(height: 8),
                  QueueProgressBar(
                    value: selected.completedItems,
                    total: selected.totalItems,
                  ),
                ],
                const SizedBox(height: 18),
                Divider(height: 1, color: context.colors.outlineVariant),
                const SizedBox(height: 10),
                if (selected.customerName.trim().isNotEmpty)
                  _Fact(
                    label: t(TechnicianKeys.technicianCustomer),
                    value: selected.customerName,
                  ),
                if (schedule.isNotEmpty)
                  _Fact(
                    label: t(TechnicianKeys.jobsScheduled),
                    value: schedule,
                  ),
                if (template.isNotEmpty)
                  _Fact(
                    label: t(TechnicianKeys.technicianTemplate),
                    value: template,
                  ),
                if (odometer.isNotEmpty)
                  _Fact(
                    label: t(TechnicianKeys.technicianOdometer),
                    value: odometer,
                  ),
                const SizedBox(height: 20),
                QueueButton(
                  label: t(TechnicianKeys.jobsOpenJob),
                  expand: true,
                  onPressed: onOpen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              maxLines: 2,
              style: queueMeta(context, color: context.colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: queueBody(context))),
        ],
      ),
    );
  }
}
