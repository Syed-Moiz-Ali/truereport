import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_actions.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_technician.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_digits.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// The counter's decision panel: one job, one status-derived primary action
/// and the facts a manager needs before acting. A fixed 380 px column at
/// ≥1024, a full-width region above the sheet in the mid range.
class JobsQueueInspector extends StatelessWidget {
  const JobsQueueInspector({
    required this.job,
    required this.staff,
    required this.busy,
    required this.pinnedFooter,
    required this.banner,
    required this.onClose,
    required this.onOpen,
    required this.onAction,
    required this.onCancel,
    required this.onRefresh,
    super.key,
  });

  final CleanJob? job;
  final List<StaffMember>? staff;
  final bool busy;

  /// Wide screens pin the action footer; the mid-width region scrolls with the
  /// page and keeps the footer at the end of its content.
  final bool pinnedFooter;

  /// A failed mutation (for example a stale version). Persistent until reload.
  final String? banner;
  final VoidCallback onClose;
  final VoidCallback onOpen;
  final ValueChanged<JobPrimaryAction> onAction;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final selected = job;
    if (selected == null) {
      return _boundedEmpty(context);
    }
    final actions = jobActionsFor(
      status: selected.status,
      consentGranted: selected.consentGranted,
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _identity(context, selected),
        const WorkshopDivider(),
        _customer(context, selected),
        const WorkshopDivider(),
        _facts(context, selected),
      ],
    );
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (banner != null) _conflictBand(context),
        const WorkshopDivider(),
        _footer(context, selected, actions),
      ],
    );
    return Container(
      key: const Key('jobs-inspector'),
      decoration: BoxDecoration(
        color: context.ws.surface,
        borderRadius: BorderRadius.circular(context.ws.cardRadius),
        border: Border.all(color: context.ws.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: pinnedFooter
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SingleChildScrollView(child: body)),
                footer,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [body, footer],
            ),
    );
  }

  Widget _boundedEmpty(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 320),
        child: Container(
          key: const Key('jobs-inspector-empty'),
          padding: EdgeInsetsDirectional.all(ws.cardPaddingDesktop),
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(ws.cardRadius),
            border: Border.all(color: ws.border),
          ),
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
              SizedBox(height: spacing.md),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ws.canvas,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.touch_app_outlined,
                  size: 20,
                  color: ws.muted,
                ),
              ),
              SizedBox(height: spacing.md),
              Text(l10n.jobsSelectJob, style: ws.sectionTitle),
              SizedBox(height: spacing.xs),
              Text(
                l10n.jobsNoSelection,
                style: ws.body.copyWith(color: ws.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conflictBand(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Container(
      key: const Key('jobs-inspector-conflict'),
      margin: EdgeInsetsDirectional.all(spacing.sm),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: spacing.md,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: ws.warningSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ws.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_problem_outlined, size: 16, color: ws.warning),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(banner!, style: ws.meta.copyWith(color: ws.ink)),
          ),
          WorkshopIconButton(
            icon: Icons.refresh,
            semanticLabel: l10n.refresh,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }

  Widget _identity(BuildContext context, CleanJob job) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final vehicle = '${job.vehicleMake} ${job.vehicleModel}'.trim();
    return Padding(
      padding: EdgeInsetsDirectional.all(ws.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: ws.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    Text(
                      job.reference,
                      key: const Key('jobs-inspector-reference'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: ws.cardTitle.copyWith(
                        color: ws.ink,
                        fontSize: 18,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              WorkshopIconButton(
                key: const Key('job-detail-close'),
                icon: Icons.close,
                semanticLabel: l10n.close,
                onPressed: onClose,
              ),
            ],
          ),
          SizedBox(height: spacing.xxs),
          Text(
            vehicle.isEmpty ? job.customerName : vehicle,
            maxLines: 2,
            style: ws.body.copyWith(color: ws.muted),
          ),
          SizedBox(height: spacing.md),
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            children: [
              JobStatusBadge(status: job.status),
              if (job.reviewStatus.isNotEmpty && job.reviewStatus != job.status)
                JobReviewStatusBadge(status: job.reviewStatus),
              JobPublicationBadge(status: job.publicationStatus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customer(BuildContext context, CleanJob job) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.all(context.ws.cardPadding),
      child: JobFactGrid(
        minColumns: 2,
        facts: [
          JobFact(label: l10n.jobsCustomer, value: job.customerName),
          JobFact(
            label: l10n.customerPhone,
            value: job.customerPhone ?? l10n.commonNotAvailable,
            valueDirection: TextDirection.ltr,
          ),
          JobFact(
            label: l10n.customerEmail,
            value: job.customerEmail ?? l10n.commonNotAvailable,
            valueDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _facts(BuildContext context, CleanJob job) {
    final l10n = AppLocalizations.of(context);
    final template = localizedText(
      context,
      en: job.templateNameEn,
      ar: job.templateNameAr,
    );
    final schedule = pinDigits(formatInstant(context, job.scheduledAt));
    final mileage = job.odometerValue == null
        ? l10n.commonNotAvailable
        : pinDigits(
            '${formatNumber(context, job.odometerValue!)} '
                    '${job.odometerUnit ?? ''}'
                .trim(),
          );
    final review = reviewStatusLabel(l10n, job.reviewStatus);
    return Padding(
      padding: EdgeInsetsDirectional.all(context.ws.cardPadding),
      child: JobFactGrid(
        minColumns: 2,
        facts: [
          JobFact(
            label: l10n.jobsTechnician,
            value: jobTechnicianName(l10n, job, staff),
          ),
          JobFact(
            label: l10n.jobsScheduled,
            value: schedule.isEmpty ? l10n.commonNotAvailable : schedule,
            valueDirection: TextDirection.ltr,
          ),
          JobFact(
            label: l10n.jobsTemplate,
            value: template.isEmpty
                ? l10n.commonNotAvailable
                : job.templateVersionNo == null
                ? template
                : '$template · v${job.templateVersionNo}',
          ),
          JobFact(
            label: l10n.jobsMileage,
            value: mileage,
            valueDirection: TextDirection.ltr,
          ),
          JobFact(
            label: l10n.jobsReviewStatus,
            value: review ?? l10n.commonNotAvailable,
          ),
          JobFact(
            label: l10n.jobsConsentGranted,
            value: job.consentGranted
                ? l10n.commonYes
                : l10n.jobsConsentNotRecorded,
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, CleanJob job, JobActions actions) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final versionBlocked = actions.requiresVersion && job.version == null;
    final blocked = job.status == 'APPROVED' && !job.consentGranted;
    final primary = switch (actions.primary) {
      JobPrimaryAction.assign => (
        label: l10n.jobsNextAssign,
        icon: Icons.person_add_alt_1_outlined,
      ),
      JobPrimaryAction.openJob => (
        label: l10n.jobsNextOpen,
        icon: Icons.open_in_new,
      ),
      JobPrimaryAction.reviewApprove => (
        label: l10n.jobsNextReview,
        icon: Icons.verified_outlined,
      ),
      JobPrimaryAction.publishChecklist => (
        label: l10n.jobsNextPublish,
        icon: Icons.playlist_add_check_outlined,
      ),
      JobPrimaryAction.publicLink => (
        label: l10n.jobsNextLink,
        icon: Icons.link,
      ),
      JobPrimaryAction.none => null,
    };
    final openLink = _OpenJobLink(
      key: const Key('job-detail-open'),
      label: l10n.jobsOpenJob,
      onPressed: onOpen,
    );
    final moreMenu = _MoreMenu(
      actions: actions,
      busy: busy,
      onOpen: onOpen,
      onAssign: () => onAction(JobPrimaryAction.assign),
      onCancel: onCancel,
      onRefresh: onRefresh,
    );
    return Padding(
      padding: EdgeInsetsDirectional.all(ws.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (blocked) ...[
            Text(
              l10n.jobsPublicationBlocked,
              style: ws.bodyStrong.copyWith(color: ws.ink),
            ),
            SizedBox(height: spacing.xs),
            WorkshopInlineNote(
              key: const Key('job-detail-publication-blocked'),
              text: l10n.jobsPublicationBlockedBody,
              icon: Icons.lock_outline,
            ),
            SizedBox(height: spacing.sm),
            WorkshopButton(
              key: const Key('job-inspector-publish-checklist'),
              label: l10n.jobsViewChecklist,
              icon: Icons.playlist_add_check_outlined,
              variant: WorkshopButtonVariant.secondary,
              onPressed: () => onAction(JobPrimaryAction.publishChecklist),
            ),
            SizedBox(height: spacing.sm),
          ],
          if (primary != null)
            Row(
              children: [
                Expanded(
                  child: WorkshopButton(
                    key: const Key('job-detail-primary-action'),
                    label: primary.label,
                    icon: primary.icon,
                    expand: true,
                    isLoading:
                        busy && actions.primary == JobPrimaryAction.assign,
                    onPressed: busy || versionBlocked
                        ? null
                        : () => onAction(actions.primary),
                  ),
                ),
                if (actions.primary != JobPrimaryAction.openJob) ...[
                  SizedBox(width: spacing.xs),
                  openLink,
                ],
                SizedBox(width: spacing.xs),
                moreMenu,
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: openLink,
                  ),
                ),
                SizedBox(width: spacing.xs),
                moreMenu,
              ],
            ),
          if (versionBlocked) ...[
            SizedBox(height: spacing.sm),
            WorkshopInlineNote(text: l10n.jobsNoVersion),
          ],
        ],
      ),
    );
  }
}

/// Tertiary "Open job": inline with the pinned primary so the footer never
/// costs a second row that pushes the facts off-screen.
class _OpenJobLink extends StatelessWidget {
  const _OpenJobLink({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ws.controlRadius),
          hoverColor: ws.canvas,
          focusColor: ws.accentSoft,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: ws.touchTarget),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 18, color: ws.ink),
                  SizedBox(width: spacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ws.bodyStrong.copyWith(color: ws.ink),
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

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.actions,
    required this.busy,
    required this.onOpen,
    required this.onAssign,
    required this.onCancel,
    required this.onRefresh,
  });

  final JobActions actions;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onAssign;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    Widget row(IconData icon, String label, {Color? color}) => Row(
      children: [
        Icon(icon, size: 18, color: color ?? ws.ink),
        SizedBox(width: spacing.sm),
        Text(label, style: ws.body.copyWith(color: color ?? ws.ink)),
      ],
    );
    return PopupMenuButton<String>(
      key: const Key('job-detail-more'),
      tooltip: l10n.jobDetailMoreActions,
      position: PopupMenuPosition.under,
      color: ws.surface,
      onSelected: (value) {
        switch (value) {
          case 'open':
            onOpen();
          case 'assign':
            onAssign();
          case 'cancel':
            onCancel();
          default:
            onRefresh();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'open',
          child: row(Icons.open_in_new, l10n.jobsOpenJob),
        ),
        if (actions.canAssign && !busy)
          PopupMenuItem<String>(
            value: 'assign',
            child: row(Icons.person_add_alt_1_outlined, l10n.jobsNextAssign),
          ),
        if (actions.canCancel && !busy)
          PopupMenuItem<String>(
            value: 'cancel',
            child: row(Icons.cancel_outlined, l10n.cancelJob, color: ws.danger),
          ),
        PopupMenuItem<String>(
          value: 'refresh',
          child: row(Icons.refresh, l10n.refresh),
        ),
      ],
      child: Semantics(
        button: true,
        label: l10n.jobDetailMoreActions,
        child: Container(
          width: ws.touchTarget,
          height: ws.touchTarget,
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(ws.controlRadius),
            border: Border.all(color: ws.border),
          ),
          child: Icon(Icons.more_horiz, size: 20, color: ws.ink),
        ),
      ),
    );
  }
}
