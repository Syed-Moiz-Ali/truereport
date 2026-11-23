import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../inspection_models.dart';
import '../../../reference_ui.dart';
import '../../../shared/technician_intl.dart';
import 'jobs_queue_format.dart';
import 'jobs_queue_primitives.dart';
import 'jobs_queue_style.dart';

/// Direction A "Day Agenda": one surface for the whole selected day.
///
/// A time gutter runs down the left; every job sits at its hour. The job that
/// is live right now carries a NOW tag, a tinted row and its progress bar, so
/// "what am I doing, what is next" is answered by position alone — no separate
/// hero band and no per-day group cards.
class QueueAgenda extends StatelessWidget {
  const QueueAgenda({
    required this.jobs,
    required this.liveJobId,
    required this.onOpen,
    super.key,
  });

  final List<JobSummary> jobs;

  /// Id of the job currently in progress, if any.
  final String? liveJobId;
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
              QueueAgendaRow(
                job: jobs[index],
                live: jobs[index].id == liveJobId,
                first: index == 0,
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

/// One row of the agenda: time gutter · identity · state · progress.
class QueueAgendaRow extends ConsumerStatefulWidget {
  const QueueAgendaRow({
    required this.job,
    required this.live,
    required this.first,
    required this.onTap,
    super.key,
  });

  final JobSummary job;
  final bool live;

  /// True for the first row of the day — the one that carries the NOW tag.
  final bool first;
  final VoidCallback onTap;

  @override
  ConsumerState<QueueAgendaRow> createState() => _QueueAgendaRowState();
}

class _QueueAgendaRowState extends ConsumerState<QueueAgendaRow> {
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
    final tone = context.statusColors.forTone(statusTone);
    final vehicle = queueVehicleLabel(job);
    final time = queueSlotLabel(job);
    final progress = job.totalItems > 0
        ? (job.completedItems / job.totalItems).clamp(0.0, 1.0)
        : 0.0;

    // The live row is tinted with the status' own tone, so the band and the
    // chip never disagree about what colour this job is.
    final background = widget.live
        ? tone.background
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
              constraints: const BoxConstraints(minHeight: 78),
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time gutter.
                  SizedBox(
                    width: 56,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          time.isEmpty ? '—' : time,
                          textDirection: TextDirection.ltr,
                          style: queueText(
                            context,
                            widget.live ? 14.5 : 13.5,
                            weight: FontWeight.w800,
                            height: 18,
                            tabular: true,
                            color: widget.live
                                ? tone.foreground
                                : colors.onSurface,
                          ),
                        ),
                        if (widget.live) ...[
                          const SizedBox(height: 2),
                          Text(
                            'NOW',
                            style: queueText(
                              context,
                              9.5,
                              weight: FontWeight.w800,
                              height: 12,
                              tracking: 0.8,
                              color: tone.foreground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Vertical hairline between the gutter and the row body.
                  Container(
                    width: 2,
                    height: 54,
                    margin: const EdgeInsetsDirectional.only(end: 12, top: 2),
                    decoration: BoxDecoration(
                      color: widget.live
                          ? tone.foreground
                          : colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Narrow rows put the status chip under the identity so
                        // the vehicle name never has to truncate.
                        final stacked = constraints.maxWidth < 420;
                        final identity = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              vehicle,
                              maxLines: 2,
                              style: queueText(
                                context,
                                15,
                                weight: FontWeight.w700,
                                height: 20,
                                tracking: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${job.customerName} · ${job.reference}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: queueMeta(
                                context,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                        final chip = QueueStatusChip(
                          label: statusLabel,
                          tone: statusTone,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (stacked) ...[
                              identity,
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  chip,
                                  const Spacer(),
                                  _chevron(rtl, colors.onSurfaceVariant),
                                ],
                              ),
                            ] else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: identity),
                                  const SizedBox(width: 10),
                                  chip,
                                  const SizedBox(width: 4),
                                  _chevron(rtl, colors.onSurfaceVariant),
                                ],
                              ),
                            if (progress > 0) ...[
                              const SizedBox(height: 8),
                              QueueProgressBar(
                                value: job.completedItems,
                                total: job.totalItems,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCountPairLocalized(
                                  job.completedItems,
                                  job.totalItems,
                                  locale,
                                ),
                                textDirection: TextDirection.ltr,
                                style: queueText(
                                  context,
                                  11,
                                  weight: FontWeight.w600,
                                  height: 14,
                                  tabular: true,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
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

  Widget _chevron(bool rtl, Color color) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 2),
    child: Icon(
      rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      size: 20,
      color: color,
    ),
  );
}
