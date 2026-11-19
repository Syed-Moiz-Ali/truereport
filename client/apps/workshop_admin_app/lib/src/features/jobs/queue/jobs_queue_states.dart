import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Loading in the real sheet geometry: a tonal head band and six 64 px rows.
class JobsQueueLoading extends StatelessWidget {
  const JobsQueueLoading({this.rows = 6, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    Widget bar(int flex, {bool last = false}) => Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: last ? 0 : spacing.md),
        child: Container(
          height: 10,
          decoration: BoxDecoration(
            color: ws.canvas,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(ws.cardRadius),
        border: Border.all(color: ws.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 42,
            color: ws.canvas.withValues(alpha: 0.75),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ws.cardPadding,
            ),
            child: Row(
              children: [bar(5), bar(4), bar(3), bar(5), bar(4, last: true)],
            ),
          ),
          for (var index = 0; index < rows; index++)
            Container(
              height: 64,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ws.cardPadding,
              ),
              decoration: BoxDecoration(
                color: index.isOdd
                    ? ws.canvas.withValues(alpha: 0.45)
                    : ws.surface,
                border: BorderDirectional(bottom: BorderSide(color: ws.border)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      bar(5),
                      bar(4),
                      bar(3),
                      bar(5),
                      bar(4, last: true),
                    ],
                  ),
                  SizedBox(height: spacing.sm),
                  FractionallySizedBox(
                    widthFactor: 0.28,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: ws.canvas,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Counts failed: every status stays named, numbers are withheld, and one
/// bounded retry is offered.
class JobsCountsErrorNote extends StatelessWidget {
  const JobsCountsErrorNote({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 16, color: ws.muted),
        SizedBox(width: spacing.sm),
        Expanded(
          child: Text(
            l10n.commonLoadFailed,
            style: ws.meta.copyWith(color: ws.muted),
          ),
        ),
        SizedBox(width: spacing.sm),
        WorkshopButton(
          key: const Key('jobs-counts-retry'),
          label: l10n.retryAction,
          variant: WorkshopButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

/// List failed: bounded inside the content region, counts may still be visible.
class JobsQueueListError extends StatelessWidget {
  const JobsQueueListError({
    required this.copy,
    required this.onRetry,
    super.key,
  });

  final String copy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      padding: EdgeInsetsDirectional.all(ws.cardPaddingDesktop),
      decoration: BoxDecoration(
        color: ws.dangerSoft,
        borderRadius: BorderRadius.circular(ws.cardRadius),
        border: Border.all(color: ws.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 22, color: ws.danger),
          SizedBox(height: spacing.sm),
          Text(l10n.error, style: ws.sectionTitle),
          SizedBox(height: spacing.xs),
          Text(copy, style: ws.body.copyWith(color: ws.ink)),
          SizedBox(height: spacing.md),
          WorkshopButton(
            label: l10n.retryAction,
            icon: Icons.refresh,
            variant: WorkshopButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Empty sheet. `filtered` distinguishes "no jobs yet" from "nothing in this
/// view"; only the former offers create and teaches the first step.
class JobsQueueEmpty extends StatelessWidget {
  const JobsQueueEmpty({
    required this.filtered,
    required this.onClear,
    required this.onCreate,
    super.key,
  });

  final bool filtered;
  final VoidCallback onClear;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(ws.cardRadius),
        border: Border.all(color: ws.border),
      ),
      padding: EdgeInsetsDirectional.all(ws.cardPaddingDesktop),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: ws.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: spacing.lg),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: ws.canvas, shape: BoxShape.circle),
            child: Icon(Icons.work_outline, size: 22, color: ws.muted),
          ),
          SizedBox(height: spacing.md),
          Text(
            filtered ? l10n.jobsNoJobsInView : l10n.jobsEmptyFirstUseTitle,
            style: ws.sectionTitle,
          ),
          if (!filtered) ...[
            SizedBox(height: spacing.xs),
            Text(
              l10n.jobsEmptyFirstUseBody,
              style: ws.body.copyWith(color: ws.muted),
            ),
          ],
          SizedBox(height: spacing.lg),
          if (filtered)
            WorkshopButton(
              key: const Key('jobs-clear-filters'),
              label: l10n.jobsClearFilters,
              variant: WorkshopButtonVariant.secondary,
              onPressed: onClear,
            )
          else
            WorkshopButton(
              key: const Key('jobs-empty-create'),
              label: l10n.newJob,
              icon: Icons.add,
              onPressed: onCreate,
            ),
        ],
      ),
    );
  }
}
