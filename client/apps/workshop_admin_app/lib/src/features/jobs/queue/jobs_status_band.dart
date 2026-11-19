import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_states.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_scroll_fade.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// The data band: one oversized workshop total, then the status rail that
/// filters the sheet. Counts come from `GET /workshop/jobs/counts`; a missing
/// number renders `—`, never a zero.
class JobsStatusBand extends ConsumerWidget {
  const JobsStatusBand({
    required this.selectedStatus,
    required this.onSelect,
    super.key,
  });

  final String selectedStatus;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final counts = ref.watch(cleanJobCountsProvider);
    final data = counts.value;
    final failed = counts.hasError && data == null;

    final segments = <_Segment>[
      _Segment('', l10n.filterAll, data?.total),
      _Segment('DRAFT', l10n.jobsCountDraft, data?.draft),
      _Segment('SCHEDULED', l10n.jobsCountScheduled, data?.scheduled),
      _Segment('ASSIGNED', l10n.jobsCountAssigned, data?.assigned),
      _Segment('IN_PROGRESS', l10n.jobsCountInProgress, data?.inProgress),
      _Segment(
        'PENDING_REVIEW',
        l10n.jobsCountPendingReview,
        data?.pendingReview,
      ),
      _Segment('APPROVED', l10n.jobsCountApproved, data?.approved),
      _Segment('PUBLISHED', l10n.jobsCountPublished, data?.published),
      _Segment('REJECTED', l10n.jobsCountRejected, data?.rejected),
      _Segment('CANCELLED', l10n.jobsCountCancelled, data?.cancelled),
    ];

    final hero = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        ws.cardPadding,
        spacing.md,
        ws.cardPadding,
        spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.jobsWorkshopTotals,
            style: ws.eyebrow.copyWith(color: ws.muted),
          ),
          SizedBox(height: spacing.xs),
          Text(
            data == null ? '—' : pinDigits(formatNumber(context, data.total)),
            style: ws.heroNumber.copyWith(
              fontSize: 52,
              height: 54 / 52,
              letterSpacing: -1.4,
              color: ws.ink,
            ),
            textDirection: TextDirection.ltr,
          ),
          Container(
            width: 40,
            height: 3,
            margin: EdgeInsetsDirectional.only(top: spacing.xs),
            decoration: BoxDecoration(
              color: ws.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );

    final rail = _Rail(
      segments: segments,
      selectedStatus: selectedStatus,
      onSelect: onSelect,
    );

    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(ws.cardRadius),
        border: Border.all(color: ws.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    hero,
                    Divider(height: 1, thickness: 1, color: ws.border),
                    rail,
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 208, child: hero),
                    VerticalDivider(width: 1, thickness: 1, color: ws.border),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: spacing.sm,
                          vertical: spacing.sm,
                        ),
                        child: rail,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (failed)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                ws.cardPadding,
                0,
                ws.cardPadding,
                spacing.md,
              ),
              child: JobsCountsErrorNote(
                onRetry: () => ref.invalidate(cleanJobCountsProvider),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment {
  const _Segment(this.value, this.label, this.count);

  final String value;
  final String label;
  final int? count;
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.segments,
    required this.selectedStatus,
    required this.onSelect,
  });

  final List<_Segment> segments;
  final String selectedStatus;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    final cells = [
      for (final segment in segments)
        _StatusCell(
          key: Key('jobs-filter-${segment.value}'),
          segment: segment,
          selected: segment.value == selectedStatus,
          onTap: () => onSelect(segment.value),
        ),
    ];
    if (!compact) {
      return Wrap(
        key: const Key('jobs-status-row'),
        spacing: 2,
        runSpacing: 2,
        children: cells,
      );
    }
    return SizedBox(
      key: const Key('jobs-status-row'),
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsetsDirectional.only(
                    start: context.ws.cardPadding,
                    end: 40,
                  ),
                  child: Row(
                    children: [
                      for (var index = 0; index < cells.length; index++) ...[
                        if (index > 0) SizedBox(width: context.spacing.xs),
                        cells[index],
                      ],
                    ],
                  ),
                ),
                const PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  end: 0,
                  width: 36,
                  child: JobsScrollFade(
                    key: Key('jobs-status-fade'),
                    axis: Axis.horizontal,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.spacing.xs),
          // The rail scrolls sideways; the chevron says a clipped cell is not
          // the end of the list.
          ExcludeSemantics(
            child: Icon(
              key: const Key('jobs-status-more'),
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              size: 18,
              color: context.ws.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({
    required this.segment,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final _Segment segment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final label = segment.count == null
        ? segment.label
        : '${segment.label} (${pinDigits(formatNumber(context, segment.count!))})';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: ws.canvas,
          child: AnimatedContainer(
            duration: context.motionDuration(const Duration(milliseconds: 140)),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 52),
            padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.md),
            decoration: BoxDecoration(
              color: selected ? ws.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? ws.accent.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? ws.accent
                          : ws.muted.withValues(alpha: 0.45),
                    ),
                  ),
                  SizedBox(width: spacing.xs),
                  Text(
                    label,
                    maxLines: 1,
                    style: (selected ? ws.bodyStrong : ws.meta).copyWith(
                      color: selected ? ws.accent : ws.ink,
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
