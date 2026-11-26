import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_controls.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_states.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Page head: the floor total, the one sentence that says what needs a
/// decision, and the page's single primary action.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.counts,
    required this.compact,
    required this.onNewJob,
    required this.onRetry,
    this.onReview,
    super.key,
  });

  final AsyncValue<CleanJobCounts> counts;
  final bool compact;
  final VoidCallback onNewJob;
  final VoidCallback onRetry;

  /// Null when there is nothing to review; the header then promotes "New job"
  /// to the primary action instead of showing a dead button.
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);

    final date = pinDigits(
      DateFormat.MMMd(Localizations.localeOf(context).toString())
          .format(DateTime.now()),
    );
    final todayLine = t(WorkshopAdminKeys.dashboardToday, {'date': date});

    final ready = counts.value;
    final total = ready?.total;
    final waiting = ready?.pendingReview;

    final title = Text(todayLine, style: DashboardType.eyebrow(ws));

    final actions = _HeaderActions(
      compact: compact,
      onNewJob: onNewJob,
      onReview: onReview,
    );

    final decision = counts.hasError
        ? Padding(
            padding: const EdgeInsetsDirectional.only(top: 10),
            child: DashboardInlineError(
              message: t(WorkshopAdminKeys.commonLoadFailed),
              retryLabel: t(WorkshopAdminKeys.retryAction),
              onRetry: onRetry,
              compact: compact,
            ),
          )
        : Padding(
            padding: const EdgeInsetsDirectional.only(top: 6),
            child: _Decision(waiting: waiting, loading: !counts.hasValue),
          );

    final totalBlock = counts.hasError
        ? const SizedBox.shrink()
        : counts.hasValue
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                NumberFormat.decimalPattern(
                  Localizations.localeOf(context).toString(),
                ).format(total!),
                style: DashboardType.total(ws, compact: compact),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 6),
                  child: Text(
                    total == 1
                        ? t(WorkshopAdminKeys.dashFloorLabelOne)
                        : t(WorkshopAdminKeys.dashFloorLabel),
                    style: DashboardType.totalCaption(ws),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              _Bar(width: compact ? 56 : 76, height: compact ? 36 : 46),
              const SizedBox(width: 10),
              const _Bar(width: 130, height: 14),
            ],
          );

    final heading = Semantics(
      header: true,
      label: counts.hasValue
          ? [
              '${NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(total!)} '
                  '${total == 1 ? t(WorkshopAdminKeys.dashFloorLabelOne) : t(WorkshopAdminKeys.dashFloorLabel)}',
              if (waiting != null && waiting > 0)
                t(WorkshopAdminKeys.dashDecisionWaiting, {'count': waiting}),
            ].join('. ')
          : null,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [totalBlock, decision],
      ),
    );

    // The empty panel owns the only "New job" action on a zero floor; a second
    // filled button in the head would compete with it.
    final noJobs = ready != null && ready.total == 0;

    if (!compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [title, const SizedBox(height: 12), heading],
            ),
          ),
          if (!noJobs) ...[const SizedBox(width: 24), actions],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        const SizedBox(height: 10),
        heading,
        if (!noJobs) ...[const SizedBox(height: 20), actions],
      ],
    );
  }
}

class _Decision extends StatelessWidget {
  const _Decision({required this.waiting, required this.loading});

  final int? waiting;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);

    if (loading) {
      return const Row(
        children: [
          _Bar(width: 6, height: 6, round: true),
          SizedBox(width: 8),
          _Bar(width: 240, height: 12),
        ],
      );
    }

    final hasWork = (waiting ?? 0) > 0;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: hasWork ? ws.warning : ws.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasWork
                ? t(WorkshopAdminKeys.dashDecisionWaiting, {'count': waiting})
                : t(WorkshopAdminKeys.dashNothingWaiting),
            style: DashboardType.decision(ws),
          ),
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.compact,
    required this.onNewJob,
    required this.onReview,
  });

  final bool compact;
  final VoidCallback onNewJob;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final review = onReview;
    final newJob = QueueButton(
      label: t(WorkshopAdminKeys.newJob),
      icon: Icons.add_rounded,
      onPressed: onNewJob,
      variant: review == null
          ? QueueButtonVariant.primary
          : QueueButtonVariant.outline,
    );
    if (review == null) {
      return newJob;
    }
    final reviewButton = QueueButton(
      label: t(WorkshopAdminKeys.dashReviewVerb),
      icon: Icons.arrow_forward_rounded,
      onPressed: review,
    );
    if (!compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [newJob, const SizedBox(width: 10), reviewButton],
      );
    }
    return Row(
      children: [
        Expanded(child: newJob),
        const SizedBox(width: 10),
        Expanded(child: reviewButton),
      ],
    );
  }
}

/// Calm loading block, shaped like the content it replaces.
class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, this.round = false});

  final double width;
  final double height;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ws.canvas,
        borderRadius: BorderRadius.circular(round ? height : 4),
        border: Border.all(color: ws.border.withValues(alpha: 0.6)),
      ),
    );
  }
}
