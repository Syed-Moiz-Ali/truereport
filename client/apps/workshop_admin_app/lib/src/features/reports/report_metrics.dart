import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'report_copy.dart';
import 'report_data.dart';
import 'report_pills.dart';

/// Focal block of the certificate: the one number the sheet is about.
///
/// The admin payload carries a coverage pair (completed / applicable) and does
/// not carry a score, grade or safety cap, so coverage is what renders. If a
/// score ever appears in `content['score']` the same block switches to
/// score / 100 with its grade and cap instead — no invented figure either way.
class ReportFocalBlock extends StatelessWidget {
  const ReportFocalBlock({required this.summary, super.key});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 380;
        final primary = _PrimaryFigure(summary: summary);
        final findings = _FindingsFigure(summary: summary);
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              SizedBox(height: spacing.lg),
              const WorkshopDivider(),
              SizedBox(height: spacing.md),
              findings,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: primary),
              Container(
                width: 1,
                margin: EdgeInsetsDirectional.symmetric(horizontal: spacing.lg),
                color: ws.border,
              ),
              Expanded(flex: 2, child: findings),
            ],
          ),
        );
      },
    );
  }
}

class _PrimaryFigure extends StatelessWidget {
  const _PrimaryFigure({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final copy = context.reportCopy;

    final figure = summary.hasScore
        ? '${summary.score!.round()}'
        : summary.coverageText ?? '—';
    final caption = summary.hasScore ? copy.scoreScale : copy.coverageNote;

    return Semantics(
      container: true,
      label:
          '${summary.hasScore ? copy.scoreLabel : copy.coverageLabel}: '
          '$figure',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportEyebrow(
            label: summary.hasScore ? copy.scoreLabel : copy.coverageLabel,
          ),
          SizedBox(height: spacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  figure,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: ws.heroNumber.copyWith(color: ws.ink),
                ),
              ),
              if (summary.hasScore) ...[
                SizedBox(width: spacing.xs),
                Padding(
                  padding: EdgeInsetsDirectional.only(bottom: spacing.sm),
                  child: Text(
                    '/ 100',
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: spacing.xs),
          Text(caption, style: ws.meta.copyWith(color: ws.muted)),
          if (summary.hasScore) ...[
            SizedBox(height: spacing.sm),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.xs,
              children: [
                if (summary.grade != null)
                  ReportStatusPill(
                    label: summary.grade!,
                    tone: WorkshopStatusTone.accent,
                  ),
                if (summary.safetyCapApplied)
                  ReportStatusPill(
                    label: copy.safetyCapLabel,
                    tone: WorkshopStatusTone.warning,
                    icon: Icons.gpp_maybe_outlined,
                  ),
              ],
            ),
          ] else if (summary.coveragePercent != null) ...[
            SizedBox(height: spacing.md),
            _CoverageBar(percent: summary.coveragePercent!),
          ],
        ],
      ),
    );
  }
}

class _CoverageBar extends StatelessWidget {
  const _CoverageBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final clamped = percent.clamp(0, 100).toInt();
    const barHeight = 6.0;
    const radius = barHeight / 2;
    return Semantics(
      label: '$percent%',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            height: barHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (clamped > 0)
                  Expanded(
                    flex: clamped,
                    child: ColoredBox(color: ws.accent),
                  ),
                if (clamped < 100)
                  Expanded(
                    flex: 100 - clamped,
                    child: ColoredBox(color: ws.canvas),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FindingsFigure extends StatelessWidget {
  const _FindingsFigure({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final copy = context.reportCopy;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReportEyebrow(label: l10n.keyFindings),
        SizedBox(height: spacing.xs),
        Text(
          '${summary.findingsCount}',
          maxLines: 1,
          style: ws.heroNumber.copyWith(color: ws.ink),
        ),
        SizedBox(height: spacing.xs),
        if (summary.safetyCriticalCount > 0)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ReportStatusPill(
              label: '${summary.safetyCriticalCount} ${l10n.safetyCritical}',
              tone: WorkshopStatusTone.danger,
              icon: Icons.gpp_maybe_outlined,
            ),
          )
        else
          Text(copy.noSafetyCritical, style: ws.meta.copyWith(color: ws.muted)),
      ],
    );
  }
}

/// Four real counts under the focal block: checks, findings, safety, passed.
class ReportCountRow extends StatelessWidget {
  const ReportCountRow({required this.summary, super.key});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final copy = context.reportCopy;
    final l10n = AppLocalizations.of(context);

    final cells = <Widget>[
      _CountCell(
        label: copy.checks,
        value: _formatCount(summary.applicableChecks ?? summary.totalChecks),
      ),
      _CountCell(label: l10n.findings, value: '${summary.findingsCount}'),
      _CountCell(label: copy.safety, value: '${summary.safetyCriticalCount}'),
      _CountCell(
        label: l10n.jobsChecklistPassed,
        value: _formatCount(summary.passedCount),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              Row(children: _withDividers(cells.sublist(0, 2))),
              SizedBox(height: spacing.md),
              const WorkshopDivider(),
              SizedBox(height: spacing.md),
              Row(children: _withDividers(cells.sublist(2))),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _withDividers(cells),
        );
      },
    );
  }

  List<Widget> _withDividers(List<Widget> cells) {
    final result = <Widget>[];
    for (var index = 0; index < cells.length; index++) {
      if (index > 0) {
        result.add(const _CountDivider());
      }
      result.add(Expanded(child: cells[index]));
    }
    return result;
  }

  String _formatCount(int? value) => value == null ? '—' : '$value';
}

class _CountDivider extends StatelessWidget {
  const _CountDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: context.ws.border);
  }
}

class _CountCell extends StatelessWidget {
  const _CountCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      container: true,
      label: '$label: $value',
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ReportEyebrow(label: label),
            SizedBox(height: spacing.xxs),
            Text(value, style: ws.sectionTitle.copyWith(color: ws.ink)),
          ],
        ),
      ),
    );
  }
}
