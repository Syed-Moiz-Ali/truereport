import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Counted footer: the loaded range, the list total, the local-sort note and a
/// tabular page indicator. When an unfiltered list's server total disagrees
/// with the workshop total, the scope is named instead of showing two
/// unexplained numbers.
class JobsQueueFooter extends StatelessWidget {
  const JobsQueueFooter({
    required this.page,
    required this.filtered,
    required this.workshopTotal,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final JobPage? page;

  /// True when a status or search filter is applied; the two server totals are
  /// then expected to disagree.
  final bool filtered;

  /// `CleanJobCounts.total`, the workshop-scoped server total.
  final int? workshopTotal;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final data = page;
    if (data == null || data.total == 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final from = data.page * data.size + 1;
    final to = math.min(data.total, data.page * data.size + data.items.length);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final range = ltrRange(from, to);
    final rawRange = '$from–$to';
    final sentence = pinDigits(l10n.jobsShownRange(from, to, data.total));
    final rangeText = sentence.contains(rawRange)
        ? sentence.replaceFirst(rawRange, range)
        : sentence;
    final scope =
        !filtered && workshopTotal != null && workshopTotal != data.total
        ? '${l10n.jobsWorkshopTotals}: '
              '${pinDigits(formatNumber(context, workshopTotal!))}'
        : null;
    final pageLabel = '${data.page + 1} / ${data.totalPages}';
    return Semantics(
      container: true,
      child: Container(
        key: const Key('jobs-queue-total'),
        width: double.infinity,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ws.cardPadding,
          vertical: spacing.sm,
        ),
        decoration: BoxDecoration(
          color: ws.surface,
          borderRadius: BorderRadius.circular(ws.cardRadius),
          border: Border.all(color: ws.border),
        ),
        child: Wrap(
          spacing: spacing.md,
          runSpacing: spacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rangeText,
                  style: ws.bodyStrong.copyWith(
                    color: ws.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (scope != null)
                  Text(scope, style: ws.meta.copyWith(color: ws.muted)),
              ],
            ),
            Text(l10n.jobsSortNote, style: ws.meta.copyWith(color: ws.muted)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pinDigits(pageLabel),
                  textDirection: TextDirection.ltr,
                  style: ws.meta.copyWith(
                    color: ws.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(width: spacing.sm),
                _Pager(
                  key: const Key('jobs-page-prev'),
                  label: l10n.jobsPagePrev,
                  icon: rtl ? Icons.chevron_right : Icons.chevron_left,
                  onPressed: data.page <= 0 ? null : onPrevious,
                ),
                SizedBox(width: spacing.xs),
                _Pager(
                  key: const Key('jobs-page-next'),
                  label: l10n.jobsPageNext,
                  icon: rtl ? Icons.chevron_left : Icons.chevron_right,
                  onPressed: data.page + 1 >= data.totalPages ? null : onNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A pager action. The disabled state is a plain, muted, non-interactive label
/// instead of the bordered secondary button, whose disabled style is too close
/// to its enabled one.
class _Pager extends StatelessWidget {
  const _Pager({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    if (onPressed != null) {
      return WorkshopButton(
        label: label,
        icon: icon,
        variant: WorkshopButtonVariant.secondary,
        onPressed: onPressed,
      );
    }
    return Semantics(
      button: true,
      enabled: false,
      label: label,
      child: SizedBox(
        height: ws.controlHeight,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: ws.muted),
              SizedBox(width: spacing.sm),
              Text(label, style: ws.bodyStrong.copyWith(color: ws.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
