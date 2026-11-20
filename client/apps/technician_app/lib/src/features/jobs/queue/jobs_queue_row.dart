import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inspection_models.dart';
import '../../../reference_ui.dart';
import '../../../shared/technician_intl.dart';
import 'jobs_queue_format.dart';
import 'jobs_queue_primitives.dart';
import 'jobs_queue_style.dart';

/// Day divider above a run of jobs: "TODAY, 19 NOV" with a hairline.
class QueueDayHeader extends StatelessWidget {
  const QueueDayHeader({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 10),
      child: Row(
        children: [
          Text(label, style: queueEyebrow(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: context.colors.outlineVariant),
          ),
        ],
      ),
    );
  }
}

/// A run of jobs on one surface. Mobile-first: the whole row is the target.
class QueueDayGroup extends StatelessWidget {
  const QueueDayGroup({
    required this.jobs,
    required this.highlightId,
    required this.onOpen,
    super.key,
  });

  final List<JobSummary> jobs;
  final String? highlightId;
  final ValueChanged<JobSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        child: Column(
          children: [
            for (var index = 0; index < jobs.length; index++) ...[
              QueueJobRow(
                job: jobs[index],
                highlighted: jobs[index].id == highlightId,
                onTap: () => onOpen(jobs[index]),
              ),
              if (index != jobs.length - 1)
                Divider(
                  height: 1,
                  color: colors.outlineVariant,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class QueueJobRow extends ConsumerStatefulWidget {
  const QueueJobRow({
    required this.job,
    required this.highlighted,
    required this.onTap,
    super.key,
  });

  final JobSummary job;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  ConsumerState<QueueJobRow> createState() => _QueueJobRowState();
}

class _QueueJobRowState extends ConsumerState<QueueJobRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final job = widget.job;
    final statusLabel = jobStatusLabel(ref, job.status);
    final statusTone = jobStatusTone(ref, job.status);
    final vehicle = _vehicleLabel(job);
    final time = queueTimeLabel(job);
    final background = widget.highlighted
        ? context.brand.container.withValues(alpha: 0.34)
        : _hovered
        ? colors.surfaceContainerLow
        : Colors.transparent;

    return Semantics(
      button: true,
      label: '${job.reference}, $vehicle, ${job.customerName}, $statusLabel',
      child: FocusableActionDetector(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: context.motionDuration(
                const Duration(milliseconds: 120),
              ),
              color: background,
              foregroundDecoration: _focused
                  ? BoxDecoration(
                      border: Border.all(color: colors.focus, width: 2),
                    )
                  : null,
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2),
                      child: Text(
                        time.isEmpty ? '—' : time,
                        textDirection: TextDirection.ltr,
                        style: queueText(
                          context,
                          13,
                          weight: FontWeight.w700,
                          height: 17,
                          tabular: true,
                          color: time.isEmpty
                              ? colors.onSurfaceVariant
                              : colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            QueuePlate(job.vehiclePlate ?? job.reference),
                            Text(
                              vehicle,
                              style: queueText(
                                context,
                                14.5,
                                weight: FontWeight.w700,
                                height: 19,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          job.customerName,
                          maxLines: 2,
                          style: queueMeta(
                            context,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: context.statusColors
                                        .forTone(statusTone)
                                        .foreground,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: queueText(
                                    context,
                                    11.5,
                                    weight: FontWeight.w600,
                                    height: 14,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (job.totalItems > 0)
                              Text(
                                formatCountPairLocalized(
                                  job.completedItems,
                                  job.totalItems,
                                  locale,
                                ),
                                textDirection: TextDirection.ltr,
                                style: queueText(
                                  context,
                                  11.5,
                                  weight: FontWeight.w600,
                                  height: 14,
                                  tabular: true,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 24),
                    child: Icon(
                      rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _vehicleLabel(JobSummary job) {
  final year = job.vehicleYear;
  final base = '${job.vehicleMake} ${job.vehicleModel}'.trim();
  if (base.isEmpty) {
    return job.vehiclePlate ?? job.reference;
  }
  return year == null ? base : '$base $year';
}
