import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_clock.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'report_actions.dart';
import 'report_copy.dart';
import 'report_data.dart';
import 'report_findings.dart';
import 'report_metrics.dart';
import 'report_pills.dart';

/// Reading canvas: a 760 px sheet with a 320 px distribution stub beside it,
/// collapsing to one column below 900 px. The sheet is the only surface; the
/// stub follows it on phones.
class ReportCanvas extends StatelessWidget {
  const ReportCanvas({required this.sheet, this.stub, super.key});

  final Widget sheet;
  final Widget? stub;

  static const double _wideSheet = 760;
  static const double _wideStub = 320;
  static const double _wideGap = 32;
  static const double _canvasMax = _wideSheet + _wideStub + _wideGap; // 1112

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasStub = stub != null;
        final wide = constraints.maxWidth >= 1160;
        final twoPane = hasStub && constraints.maxWidth >= 900;

        final Widget content;
        if (wide) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: _wideSheet, child: sheet),
              const SizedBox(width: _wideGap),
              SizedBox(width: _wideStub, child: stub),
            ],
          );
        } else if (twoPane) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: sheet),
              SizedBox(width: spacing.xl),
              SizedBox(width: 300, child: stub),
            ],
          );
        } else {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sheet,
              if (hasStub) ...[SizedBox(height: spacing.gutter), stub!],
            ],
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _canvasMax),
            child: content,
          ),
        );
      },
    );
  }
}

/// The certificate itself. The header, identity facts and generation states
/// live here; ready reports append the focal block, counts, findings and
/// footer.
class ReportSheet extends StatelessWidget {
  const ReportSheet({
    required this.report,
    required this.canPop,
    this.isBusy = false,
    this.onRetry,
    this.onBack,
    super.key,
  });

  final ReportAdmin report;
  final bool canPop;
  final bool isBusy;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  static const double _sheetRadius = 24;
  static const double _sheetPadding = 34;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final radius = compact ? ws.cardLargeRadius : _sheetRadius;
    final padding = compact ? spacing.gutter : _sheetPadding;
    final summary = ReportData.summarize(report);
    final ready = report.reportReady;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ws.border),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(report: report),
            SizedBox(height: spacing.xl),
            const WorkshopDivider(),
            SizedBox(height: spacing.lg),
            if (ready)
              _ReadyBody(report: report, summary: summary)
            else
              _GenerationState(
                report: report,
                canPop: canPop,
                isBusy: isBusy,
                onRetry: onRetry,
                onBack: onBack,
              ),
            if (ready && summary.verificationHash != null) ...[
              SizedBox(height: spacing.xl),
              const WorkshopDivider(),
              SizedBox(height: spacing.md),
              _SheetFooter(summary: summary),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.report});

  final ReportAdmin report;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final copy = context.reportCopy;
    final l10n = AppLocalizations.of(context);
    final finalized = report.finalizedAt.trim().isEmpty
        ? ''
        : WorkshopClock.formatInstant(
            context,
            report.finalizedAt,
            fallback: report.finalizedAt,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: ReportEyebrow(label: copy.eyebrow)),
            SizedBox(width: spacing.sm),
            ReportStatusPill(
              label: generationLabel(l10n, report.generationStatus),
              tone: generationTone(report.generationStatus),
            ),
          ],
        ),
        SizedBox(height: spacing.md),
        Semantics(header: true, child: Text(copy.title, style: ws.pageTitle)),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              report.reportNumber,
              textDirection: TextDirection.ltr,
              style: ws.body.copyWith(
                color: ws.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const _MetaDot(),
            Text(
              'v${report.version}',
              style: ws.meta.copyWith(color: ws.muted),
            ),
            if (finalized.isNotEmpty) ...[
              const _MetaDot(),
              Text(
                finalized,
                textDirection: TextDirection.ltr,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        '·',
        style: context.ws.meta.copyWith(color: context.ws.muted),
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.report, required this.summary});

  final ReportAdmin report;
  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final facts = <_Fact>[
      _Fact(
        value: summary.vehicleLine,
        label: AppLocalizations.of(context).vehicle,
      ),
      if (summary.customerName != null)
        _Fact(value: summary.customerName!, label: context.reportCopy.customer),
      if (summary.plate != null)
        _Fact(
          value: summary.plate!,
          label: AppLocalizations.of(context).vehiclePlate,
          ltr: true,
        ),
      if (summary.odometer != null)
        _Fact(
          value: summary.odometer!,
          label: AppLocalizations.of(context).odometer,
          ltr: true,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FactGrid(facts: facts),
        SizedBox(height: spacing.xl),
        const WorkshopDivider(),
        SizedBox(height: spacing.xl),
        ReportFocalBlock(summary: summary),
        SizedBox(height: spacing.xl),
        ReportCountRow(summary: summary),
        SizedBox(height: spacing.xl),
        const WorkshopDivider(),
        SizedBox(height: spacing.lg),
        ReportKeyFindings(items: summary.keyFindings),
        SizedBox(height: spacing.xl),
        const WorkshopDivider(),
        SizedBox(height: spacing.lg),
        ReportCategoryFindings(categories: summary.categories),
      ],
    );
  }
}

class _Fact {
  const _Fact({required this.label, required this.value, this.ltr = false});

  final String label;
  final String value;
  final bool ltr;
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});

  final List<_Fact> facts;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final visible = facts
        .where((fact) => fact.value.trim().isNotEmpty)
        .toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560
            ? 3
            : constraints.maxWidth >= 340
            ? 2
            : 1;
        final limit = visible.length < columns ? visible.length : columns;
        final gap = spacing.xl;
        final cellWidth = (constraints.maxWidth - gap * (limit - 1)) / limit;
        return Wrap(
          spacing: gap,
          runSpacing: spacing.lg,
          children: [
            for (final fact in visible)
              SizedBox(
                width: cellWidth > 0 ? cellWidth : constraints.maxWidth,
                child: _FactCell(fact: fact),
              ),
          ],
        );
      },
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      container: true,
      label: '${fact.label}: ${fact.value}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportEyebrow(label: fact.label),
          SizedBox(height: spacing.xxs),
          Text(
            fact.value,
            textDirection: fact.ltr ? TextDirection.ltr : null,
            textAlign: TextAlign.start,
            style: ws.bodyStrong.copyWith(color: ws.ink),
          ),
        ],
      ),
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final copy = context.reportCopy;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (summary.vin != null) ...[
          ReportEyebrow(label: copy.vin),
          SizedBox(height: spacing.xxs),
          Text(
            summary.vin!,
            textDirection: TextDirection.ltr,
            style: ws.meta.copyWith(color: ws.ink, letterSpacing: 0.6),
          ),
          SizedBox(height: spacing.md),
        ],
        if (summary.verificationHash != null) ...[
          ReportEyebrow(label: l10n.snapshotHash),
          SizedBox(height: spacing.xxs),
          SelectableText(
            summary.verificationHash!,
            textDirection: TextDirection.ltr,
            style: ws.meta.copyWith(color: ws.muted),
          ),
        ],
      ],
    );
  }
}

class _GenerationState extends StatelessWidget {
  const _GenerationState({
    required this.report,
    required this.canPop,
    required this.isBusy,
    required this.onRetry,
    required this.onBack,
  });

  final ReportAdmin report;
  final bool canPop;
  final bool isBusy;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final failed = report.generationStatus == 'FAILED';
    final errorText = report.generationError?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopEmptyState(
          title: failed ? l10n.reportFailed : l10n.reportNotReadyTitle,
          body: failed
              ? (errorText.isEmpty ? null : errorText)
              : l10n.reportNotReadyBody,
          icon: failed ? Icons.error_outline : Icons.description_outlined,
        ),
        if (failed) ...[
          SizedBox(height: spacing.lg),
          ReportActionButton(
            label: l10n.retryReport,
            onPressed: isBusy ? null : onRetry,
            loading: isBusy,
            icon: Icons.refresh,
            expand: true,
          ),
        ],
        if (canPop) ...[
          SizedBox(height: spacing.sm),
          ReportActionButton(
            label: l10n.reportBackToJob,
            onPressed: onBack,
            variant: failed
                ? ReportActionVariant.secondary
                : ReportActionVariant.primary,
            expand: true,
          ),
        ],
      ],
    );
  }
}

/// Skeleton in the shape of the sheet and stub, so the first paint already has
/// the final geometry.
class ReportSheetSkeleton extends StatelessWidget {
  const ReportSheetSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final radius = compact ? ws.cardLargeRadius : ReportSheet._sheetRadius;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ws.border),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(
          compact ? spacing.gutter : ReportSheet._sheetPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WorkshopSkeleton(lines: 1),
            SizedBox(height: spacing.md),
            const WorkshopSkeleton(lines: 2),
            SizedBox(height: spacing.xl),
            const WorkshopSkeleton(lines: 4),
            SizedBox(height: spacing.xl),
            const WorkshopSkeleton(lines: 5),
          ],
        ),
      ),
    );
  }
}

/// Stub-shaped skeleton shown beside the sheet while the report loads.
class ReportStubSkeleton extends StatelessWidget {
  const ReportStubSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(ws.cardLargeRadius),
        border: Border.all(color: ws.border),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(spacing.gutter),
        child: const WorkshopSkeleton(lines: 5, card: true),
      ),
    );
  }
}
