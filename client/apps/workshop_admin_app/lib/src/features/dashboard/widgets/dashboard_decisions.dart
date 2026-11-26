import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_format.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_controls.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_states.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// The dashboard's only job list: at most three decisions waiting for the admin.
///
/// Three, not the whole queue — the Jobs screen owns the queue. The header link
/// and the count make the truncation explicit instead of pretending this is
/// everything.
class DashboardDecisions extends StatelessWidget {
  const DashboardDecisions({
    required this.pending,
    required this.counts,
    required this.statuses,
    required this.onOpenJob,
    required this.onOpenQueue,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<JobPage> pending;
  final CleanJobCounts? counts;
  final List<ReferenceRecord>? statuses;
  final void Function(String jobId) onOpenJob;
  final VoidCallback onOpenQueue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final count = counts?.pendingReview ?? pending.value?.total;

    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(DashboardShape.card),
        border: Border.all(color: ws.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: ws.warning,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t(WorkshopAdminKeys.dashGroupWaiting),
                    style: DashboardType.cardTitle(ws),
                  ),
                ),
                if (count != null)
                  Text(
                    t(WorkshopAdminKeys.dashGroupCountPending, {
                      'count': count,
                    }),
                    style: DashboardType.bandMeta(ws),
                  ),
                const SizedBox(width: 4),
                QueueTextAction(
                  label: t(WorkshopAdminKeys.dashViewAll),
                  onTap: onOpenQueue,
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
          Container(height: 1, color: ws.border),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              if (pending.hasError) {
                return Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
                  child: DashboardInlineError(
                    message: t(WorkshopAdminKeys.commonLoadFailed),
                    retryLabel: t(WorkshopAdminKeys.retryAction),
                    onRetry: onRetry,
                    compact: true,
                    filled: false,
                  ),
                );
              }
              if (!pending.hasValue) {
                return DashboardSkeletonRows(compact: compact);
              }
              final items = pending.value!.items.take(3).toList();
              if (items.isEmpty) {
                return DashboardGroupEmpty(
                  text: t(WorkshopAdminKeys.dashGroupEmpty),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) Container(height: 1, color: ws.border),
                    _DecisionRow(
                      job: items[index],
                      statuses: statuses,
                      compact: compact,
                      onOpen: () => onOpenJob(items[index].id),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DecisionRow extends StatefulWidget {
  const _DecisionRow({
    required this.job,
    required this.statuses,
    required this.compact,
    required this.onOpen,
  });

  final CleanJob job;
  final List<ReferenceRecord>? statuses;
  final bool compact;
  final VoidCallback onOpen;

  @override
  State<_DecisionRow> createState() => _DecisionRowState();
}

class _DecisionRowState extends State<_DecisionRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final job = widget.job;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final schedule = dashboardSchedule(
      context,
      job.scheduledAt,
      todayTemplate: t(WorkshopAdminKeys.dashboardToday),
    );
    final title = dashboardJobTitle(
      make: job.vehicleMake,
      model: job.vehicleModel,
      customer: job.customerName,
    );
    final status = referenceStatusText(widget.statuses, job.status);
    final tone = referenceStatusTone(widget.statuses, job.status);

    final titles = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: ws.body.copyWith(
            fontSize: widget.compact ? 15.5 : 17,
            height: (widget.compact ? 21 : 24) / (widget.compact ? 15.5 : 17),
            fontWeight: FontWeight.w600,
            color: ws.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dashboardJobMeta(
            reference: job.reference,
            customer: job.customerName,
            technician: job.assignedTechnicianName,
            schedule: schedule,
          ),
          textDirection: TextDirection.ltr,
          textAlign: rtl ? TextAlign.right : TextAlign.left,
          style: DashboardType.meta(ws),
        ),
      ],
    );

    final pill = QueueStatusPill(label: status, tone: tone);
    final verb = t(WorkshopAdminKeys.dashReviewVerb);

    final body = widget.compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titles,
              const SizedBox(height: 10),
              Row(
                children: [
                  pill,
                  const Spacer(),
                  Text(verb, style: DashboardType.verb(ws)),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _hovered ? ws.accent : ws.muted,
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(child: titles),
              const SizedBox(width: 20),
              pill,
              const SizedBox(width: 16),
              Text(verb, style: DashboardType.verb(ws)),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: _hovered ? ws.accent : ws.muted,
              ),
            ],
          );

    return Semantics(
      button: true,
      label: dashboardRowSemantics(
        title: title,
        reference: job.reference,
        customer: job.customerName,
        technician: job.assignedTechnicianName,
        schedule: schedule,
        status: status,
        verb: verb,
      ),
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onOpen();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onOpen,
            child: AnimatedContainer(
              duration: DashboardMotion.quick,
              curve: DashboardMotion.enter,
              padding: EdgeInsetsDirectional.fromSTEB(
                widget.compact ? 16 : 20,
                16,
                widget.compact ? 12 : 20,
                16,
              ),
              decoration: BoxDecoration(
                color: _hovered ? ws.canvas : ws.surface,
                border: Border.all(
                  color: _focused ? ws.focus : Colors.transparent,
                  width: DashboardShape.focusWidth,
                ),
                borderRadius: BorderRadius.circular(DashboardShape.control),
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
