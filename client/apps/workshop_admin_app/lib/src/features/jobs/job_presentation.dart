import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';

/// Shared presentation for a legacy (`WorkshopJob`) inspection job: the job
/// status tone, vehicle/identity labels, the status badge, a wrapping meta
/// line, the tabular header and the adaptive list row.
///
/// The row renders a table row from [jobWideRowMinWidth] (and only while text
/// is not scaled past 1.35x); below that it stacks into a card. Callers own the
/// key so dashboard (`dashboard-job-<id>`) and queue (`job-<id>`) stay stable.
const double jobWideRowMinWidth = 820;

/// Status tone for the workshop kit badge (never colour-only).
WorkshopStatusTone workshopJobTone(String status) => switch (status) {
  'ASSIGNED' || 'IN_PROGRESS' => WorkshopStatusTone.accent,
  'READY_TO_FINALIZE' || 'PENDING_REVIEW' => WorkshopStatusTone.warning,
  'APPROVED' || 'PUBLISHED' || 'FINALIZED' => WorkshopStatusTone.success,
  'CANCELLED' || 'REJECTED' => WorkshopStatusTone.danger,
  _ => WorkshopStatusTone.neutral,
};

/// `Make Model`, falling back to the customer name when the vehicle is blank.
String jobVehicleTitle(WorkshopJob job) {
  final title = '${job.vehicleMake} ${job.vehicleModel}'.trim();
  return title.isEmpty ? job.customerName : title;
}

/// `year · plate` for compact rows. The VIN stays in job detail where it has
/// room to be read in full (never wrapped across lines in a table row).
String jobVehicleMeta(BuildContext context, WorkshopJob job) {
  final parts = <String>[
    if (job.vehicleYear != null) '${job.vehicleYear}',
    if ((job.vehiclePlate ?? '').trim().isNotEmpty) job.vehiclePlate!.trim(),
  ];
  return parts.join(' · ');
}

/// Locale-aware schedule label (`formatInstant`), or "Not available".
String jobScheduleLabel(BuildContext context, WorkshopJob job) {
  final label = formatInstant(context, job.scheduledAt);
  return label.isEmpty
      ? AppLocalizations.of(context).commonNotAvailable
      : label;
}

/// `Template vN` label; never invents a version.
String jobTemplateLabel(BuildContext context, WorkshopJob job) {
  final l10n = AppLocalizations.of(context);
  final name = job.templateName.trim();
  if (name.isEmpty) {
    return l10n.commonNotAvailable;
  }
  final version = job.templateVersionNo;
  return version == null ? name : '$name v$version';
}

/// Localized job status pill with the workshop tone mapping.
class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WorkshopStatusBadge(
      label: jobStatusLabel(l10n, status),
      tone: workshopJobTone(status),
    );
  }
}

/// Small icon + text row; the text wraps instead of being clipped unless the
/// caller pins it (identifiers such as job references never wrap).
class JobMetaLine extends StatelessWidget {
  const JobMetaLine({
    required this.icon,
    required this.text,
    this.textDirection,
    this.maxLines = 2,
    this.softWrap = true,
    super.key,
  });

  final IconData icon;
  final String text;
  final TextDirection? textDirection;
  final int maxLines;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(top: spacing.xxs),
          child: Icon(icon, size: 14, color: ws.muted),
        ),
        SizedBox(width: spacing.xs),
        Flexible(
          child: Text(
            text,
            textDirection: textDirection,
            maxLines: maxLines,
            softWrap: softWrap,
            style: ws.meta.copyWith(color: ws.muted),
          ),
        ),
      ],
    );
  }
}

String _rowSemanticLabel(BuildContext context, WorkshopJob job) {
  final l10n = AppLocalizations.of(context);
  return [
    jobVehicleTitle(job),
    job.reference,
    job.customerName,
    jobStatusLabel(l10n, job.status),
  ].where((value) => value.trim().isNotEmpty).join(', ');
}

/// Column header for the tabular job list. The queue supplies it once above
/// the rows so the card reads as a deliberate table, never a floating card.
class JobListHeader extends StatelessWidget {
  const JobListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final style = ws.eyebrow.copyWith(color: ws.muted);
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.cardPadding,
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          _HeaderCell(flex: 3, label: l10n.jobsListColumnVehicle, style: style),
          _HeaderCell(flex: 3, label: l10n.jobsListColumnJob, style: style),
          _HeaderCell(
            flex: 2,
            label: l10n.jobsListColumnCustomer,
            style: style,
          ),
          _HeaderCell(
            flex: 3,
            label: l10n.jobsListColumnScheduled,
            style: style,
          ),
          _HeaderCell(
            flex: 2,
            label: l10n.jobsListColumnTechnician,
            style: style,
          ),
          _HeaderCell(
            flex: 2,
            label: l10n.jobsListColumnInspection,
            style: style,
          ),
          _HeaderCell(flex: 3, label: l10n.status, style: style, last: true),
          SizedBox(width: context.spacing.xl, height: context.spacing.xl),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.flex,
    required this.label,
    required this.style,
    this.last = false,
  });

  final int flex;
  final String label;
  final TextStyle style;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: last ? 0 : context.spacing.md),
        child: Text(label, style: style, maxLines: 2),
      ),
    );
  }
}

/// One job in the queue or a dashboard list.
///
/// Wide: a single table row (no card border) with 3/2/2/2/2/2/3 flexible
/// columns, badge and chevron. Narrow: a stacked card; [embedded] keeps the
/// stacked layout without a second card when the caller already draws one.
class JobListRow extends StatelessWidget {
  const JobListRow({
    required this.job,
    this.onTap,
    this.embedded = false,
    super.key,
  });

  final WorkshopJob job;
  final VoidCallback? onTap;

  /// True when the row already sits inside a caller-owned card.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final wide =
            constraints.maxWidth >= jobWideRowMinWidth && textScale <= 1.35;
        final label = _rowSemanticLabel(context, job);
        if (wide) {
          return _RowSurface(
            onTap: onTap,
            semanticLabel: label,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ws.cardPadding,
              vertical: context.spacing.md,
            ),
            child: _WideRowContent(job: job),
          );
        }
        final content = _StackedRowContent(job: job, showChevron: embedded);
        if (embedded) {
          return _RowSurface(
            onTap: onTap,
            semanticLabel: label,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ws.cardPadding,
              vertical: context.spacing.md,
            ),
            child: content,
          );
        }
        return WorkshopCard(onTap: onTap, semanticLabel: label, child: content);
      },
    );
  }
}

/// Focus/hover surface for rows that live inside a caller-owned card.
class _RowSurface extends StatefulWidget {
  const _RowSurface({
    required this.child,
    required this.padding,
    required this.semanticLabel,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  State<_RowSurface> createState() => _RowSurfaceState();
}

class _RowSurfaceState extends State<_RowSurface> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final radius = BorderRadius.circular(ws.chipRadius);
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: AnimatedContainer(
        duration: context.motionDuration(const Duration(milliseconds: 140)),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          color: _hovered && widget.onTap != null ? ws.canvas : null,
          borderRadius: radius,
          boxShadow: _focused ? context.shadows.focusRing : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            onHover: (value) => setState(() => _hovered = value),
            canRequestFocus: widget.onTap != null,
            borderRadius: radius,
            child: Padding(
              padding: widget.padding,
              child: ExcludeSemantics(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

class _WideRowContent extends StatelessWidget {
  const _WideRowContent({required this.job});

  final WorkshopJob job;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final meta = jobVehicleMeta(context, job);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    jobVehicleTitle(job),
                    maxLines: 2,
                    style: ws.bodyStrong.copyWith(color: ws.ink),
                  ),
                  if (meta.isNotEmpty) ...[
                    SizedBox(height: spacing.xxs),
                    Text(
                      meta,
                      maxLines: 2,
                      textDirection: TextDirection.ltr,
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: spacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      job.reference,
                      maxLines: 1,
                      softWrap: false,
                      textDirection: TextDirection.ltr,
                      style: ws.body.copyWith(color: ws.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: spacing.md),
              child: Text(
                job.customerName,
                maxLines: 2,
                style: ws.body.copyWith(color: ws.ink),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: spacing.md),
              child: Text(
                jobScheduleLabel(context, job),
                maxLines: 2,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: spacing.md),
              child: Text(
                job.assignedTechnicianName ?? l10n.unassigned,
                maxLines: 2,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: spacing.md),
              child: Text(
                jobTemplateLabel(context, job),
                maxLines: 2,
                style: ws.meta.copyWith(color: ws.muted),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: JobStatusBadge(status: job.status),
            ),
          ),
          SizedBox(width: spacing.lg),
          Icon(
            rtl ? Icons.chevron_left : Icons.chevron_right,
            size: 18,
            color: ws.muted,
          ),
        ],
      ),
    );
  }
}

class _StackedRowContent extends StatelessWidget {
  const _StackedRowContent({required this.job, this.showChevron = false});

  final WorkshopJob job;

  /// Dashboard rows show a trailing chevron as the "open job" affordance.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final meta = jobVehicleMeta(context, job);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    jobVehicleTitle(job),
                    maxLines: 2,
                    style: ws.bodyStrong.copyWith(color: ws.ink),
                  ),
                  if (meta.isNotEmpty) ...[
                    SizedBox(height: spacing.xxs),
                    Text(
                      meta,
                      maxLines: 2,
                      textDirection: TextDirection.ltr,
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: spacing.sm),
            Flexible(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: JobStatusBadge(status: job.status),
              ),
            ),
            if (showChevron) ...[
              SizedBox(width: spacing.xs),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                size: 18,
                color: ws.muted,
              ),
            ],
          ],
        ),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.md,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            JobMetaLine(
              icon: Icons.confirmation_number_outlined,
              text: job.reference,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              softWrap: false,
            ),
            JobMetaLine(icon: Icons.person_outline, text: job.customerName),
          ],
        ),
        SizedBox(height: spacing.xs),
        Wrap(
          spacing: spacing.md,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            JobMetaLine(
              icon: Icons.schedule,
              text: jobScheduleLabel(context, job),
            ),
            JobMetaLine(
              icon: Icons.engineering_outlined,
              text: job.assignedTechnicianName ?? l10n.unassigned,
            ),
            JobMetaLine(
              icon: Icons.assignment_outlined,
              text: jobTemplateLabel(context, job),
            ),
          ],
        ),
      ],
    );
  }
}

/// 60 px page top bar for job sub-pages: back, title and trailing actions.
///
/// Grows with the title (two lines) instead of truncating at large text
/// scales, and keeps a 44 px back target with a semantic label.
class JobPageTopBar extends StatelessWidget {
  const JobPageTopBar({
    required this.title,
    this.breadcrumbs,
    this.onBack,
    this.actions = const [],
    super.key,
  });

  final String title;
  final List<String>? breadcrumbs;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      constraints: BoxConstraints(minHeight: ws.topBarHeight),
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
        vertical: spacing.xs,
      ),
      child: Row(
        children: [
          WorkshopIconButton(
            icon: rtl ? Icons.arrow_forward : Icons.arrow_back,
            semanticLabel: l10n.commonBack,
            onPressed:
                onBack ??
                () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                },
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: breadcrumbs != null && breadcrumbs!.isNotEmpty
                ? Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: spacing.xs,
                    children: [
                      for (int i = 0; i < breadcrumbs!.length; i++) ...[
                        if (i > 0)
                          Text(
                            '/',
                            style: ws.meta.copyWith(color: ws.muted),
                          ),
                        Text(
                          breadcrumbs![i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: i == breadcrumbs!.length - 1
                              ? ws.cardTitle.copyWith(color: ws.ink)
                              : ws.meta.copyWith(
                                  color: ws.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                        ),
                      ],
                    ],
                  )
                : Text(
                    title,
                    maxLines: 2,
                    style: ws.cardTitle.copyWith(color: ws.ink),
                  ),
          ),
          for (final action in actions) ...[
            SizedBox(width: spacing.xs),
            action,
          ],
        ],
      ),
    );
  }
}

/// Compact label-above-value fact used across the job surfaces.
class JobFact extends StatelessWidget {
  const JobFact({
    required this.label,
    required this.value,
    this.valueDirection,
    super.key,
  });

  final String label;
  final String value;
  final TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(label, style: ws.meta.copyWith(color: ws.muted)),
        ),
        SizedBox(height: context.spacing.xxs),
        Text(
          value,
          textDirection: valueDirection,
          style: ws.body.copyWith(color: ws.ink),
        ),
      ],
    );
  }
}

/// Wrapping grid of [JobFact]s: 3 columns on desktop, 2 on tablet, 1 on phone.
class JobFactGrid extends StatelessWidget {
  const JobFactGrid({required this.facts, super.key});

  final List<Widget> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) {
      return const SizedBox.shrink();
    }
    final gap = context.spacing.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 3
            : width >= 600
            ? 2
            : 1;
        final cell = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final fact in facts) SizedBox(width: cell, child: fact),
          ],
        );
      },
    );
  }
}
