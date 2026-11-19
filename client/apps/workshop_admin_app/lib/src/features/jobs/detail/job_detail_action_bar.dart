import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/approve_job_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_documents_page.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_actions.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Sticky bottom bar. One policy-driven primary action; secondary routes and
/// the destructive cancel live in the overflow. Never calls `publishJob`.
class JobDetailActionBar extends StatelessWidget {
  const JobDetailActionBar({
    required this.job,
    required this.actions,
    required this.busy,
    required this.mutationsEnabled,
    required this.onAssign,
    required this.onCancel,
    required this.onRefresh,
    required this.onOpen,
    super.key,
  });

  final CleanJob job;
  final JobActions actions;
  final bool busy;
  final bool mutationsEnabled;
  final VoidCallback onAssign;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;
  final ValueChanged<Widget> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);
    final primary = _primary(context);
    final canAssign = actions.canAssign && mutationsEnabled && !busy;
    final canCancel = actions.canCancel && mutationsEnabled && !busy;
    // APPROVED without consent: publication is blocked, but the checklist stays
    // reachable (brief §5). This is a route, not a publish promise.
    final blockedByConsent = job.status == 'APPROVED' && !job.consentGranted;
    final checklistRoute = WorkshopButton(
      key: const Key('job-detail-publish-checklist'),
      label: l10n.jobsViewChecklist,
      icon: Icons.playlist_add_check_outlined,
      variant: WorkshopButtonVariant.secondary,
      onPressed: busy
          ? null
          : () => onOpen(PublishChecklistPage(jobId: job.id)),
    );
    final secondary = <Widget>[
      if (blockedByConsent) checklistRoute,
      if (actions.primary != JobPrimaryAction.publicLink)
        WorkshopButton(
          label: l10n.publicLink,
          icon: Icons.link,
          variant: WorkshopButtonVariant.secondary,
          onPressed: busy ? null : () => onOpen(PublicLinkPage(jobId: job.id)),
        ),
      WorkshopButton(
        label: l10n.jobsDocumentsTitle,
        icon: Icons.description_outlined,
        variant: WorkshopButtonVariant.secondary,
        onPressed: busy ? null : () => onOpen(DocumentsPage(jobId: job.id)),
      ),
      if (canAssign && actions.primary != JobPrimaryAction.assign)
        WorkshopButton(
          label: job.assignedTechnicianId == null ? l10n.assign : l10n.reassign,
          icon: Icons.person_add_alt_1_outlined,
          variant: WorkshopButtonVariant.ghost,
          onPressed: onAssign,
        ),
    ];
    final more = _ActionMoreMenu(
      canCancel: canCancel,
      showRoutes: false,
      onCancel: onCancel,
      onRefresh: onRefresh,
    );
    final compactMore = _ActionMoreMenu(
      canCancel: canCancel,
      showRoutes: true,
      iconOnly: true,
      onCancel: onCancel,
      onRefresh: onRefresh,
      onPublicLink: busy ? null : () => onOpen(PublicLinkPage(jobId: job.id)),
      onDocuments: busy ? null : () => onOpen(DocumentsPage(jobId: job.id)),
    );
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: gutter,
        vertical: spacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 680) {
                  final fallback = actions.primary == JobPrimaryAction.openJob
                      ? WorkshopButton(
                          label: l10n.publicLink,
                          icon: Icons.link,
                          onPressed: busy
                              ? null
                              : () => onOpen(PublicLinkPage(jobId: job.id)),
                        )
                      : null;
                  final compactPrimary =
                      primary ?? (blockedByConsent ? checklistRoute : fallback);
                  return Row(
                    children: [
                      if (compactPrimary != null)
                        Expanded(child: compactPrimary)
                      else
                        const Spacer(),
                      SizedBox(width: spacing.sm),
                      compactMore,
                    ],
                  );
                }
                return Wrap(
                  spacing: spacing.sm,
                  runSpacing: spacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [?primary, ...secondary, more],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? _primary(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Stale version or a 409 leaves every mutation disabled. A saturated
    // primary that does nothing is deceptive (N7): swap it for a real reload.
    final mutationBlocked =
        !mutationsEnabled &&
        (actions.primary == JobPrimaryAction.assign ||
            actions.primary == JobPrimaryAction.reviewApprove ||
            actions.primary == JobPrimaryAction.publishChecklist);
    if (mutationBlocked) {
      return WorkshopButton(
        key: const Key('job-detail-reload'),
        label: l10n.refresh,
        icon: Icons.refresh,
        onPressed: busy ? null : onRefresh,
      );
    }
    return switch (actions.primary) {
      JobPrimaryAction.assign => WorkshopButton(
        key: const Key('job-detail-primary-action'),
        label: l10n.jobsNextAssign,
        icon: Icons.person_add_alt_1_outlined,
        isLoading: busy,
        onPressed: mutationsEnabled && !busy ? onAssign : null,
      ),
      JobPrimaryAction.reviewApprove => WorkshopButton(
        key: const Key('job-detail-primary-action'),
        label: l10n.jobsNextReview,
        icon: Icons.verified_outlined,
        onPressed: busy ? null : () => onOpen(ApproveIssuePage(jobId: job.id)),
      ),
      JobPrimaryAction.publishChecklist => WorkshopButton(
        key: const Key('job-detail-primary-action'),
        label: l10n.jobsNextPublish,
        icon: Icons.playlist_add_check_outlined,
        onPressed: busy
            ? null
            : () => onOpen(PublishChecklistPage(jobId: job.id)),
      ),
      JobPrimaryAction.publicLink => WorkshopButton(
        key: const Key('job-detail-primary-action'),
        label: l10n.jobsNextLink,
        icon: Icons.link,
        onPressed: busy ? null : () => onOpen(PublicLinkPage(jobId: job.id)),
      ),
      // `openJob` means the job is already open; `none` promises nothing.
      JobPrimaryAction.openJob || JobPrimaryAction.none => null,
    };
  }
}

class _ActionMoreMenu extends StatelessWidget {
  const _ActionMoreMenu({
    required this.canCancel,
    required this.showRoutes,
    required this.onCancel,
    required this.onRefresh,
    this.iconOnly = false,
    this.onPublicLink,
    this.onDocuments,
  });

  final bool canCancel;
  final bool showRoutes;
  final bool iconOnly;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;
  final VoidCallback? onPublicLink;
  final VoidCallback? onDocuments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return PopupMenuButton<String>(
      key: const Key('job-detail-more'),
      tooltip: l10n.jobDetailMoreActions,
      position: PopupMenuPosition.under,
      color: ws.surface,
      onSelected: (value) {
        switch (value) {
          case 'cancel':
            onCancel();
          case 'publicLink':
            onPublicLink?.call();
          case 'documents':
            onDocuments?.call();
          default:
            onRefresh();
        }
      },
      itemBuilder: (context) => [
        if (showRoutes && onPublicLink != null)
          PopupMenuItem<String>(
            value: 'publicLink',
            child: Row(
              children: [
                Icon(Icons.link, size: 18, color: ws.ink),
                SizedBox(width: spacing.sm),
                Text(l10n.publicLink, style: ws.body.copyWith(color: ws.ink)),
              ],
            ),
          ),
        if (showRoutes && onDocuments != null)
          PopupMenuItem<String>(
            value: 'documents',
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: ws.ink),
                SizedBox(width: spacing.sm),
                Text(
                  l10n.jobsDocumentsTitle,
                  style: ws.body.copyWith(color: ws.ink),
                ),
              ],
            ),
          ),
        if (canCancel)
          PopupMenuItem<String>(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 18, color: ws.danger),
                SizedBox(width: spacing.sm),
                Text(l10n.cancelJob, style: ws.body.copyWith(color: ws.danger)),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 18, color: ws.ink),
              SizedBox(width: spacing.sm),
              Text(l10n.refresh, style: ws.body.copyWith(color: ws.ink)),
            ],
          ),
        ),
      ],
      child: Semantics(
        button: true,
        label: l10n.jobDetailMoreActions,
        child: Container(
          constraints: BoxConstraints(minHeight: ws.touchTarget),
          width: iconOnly ? ws.touchTarget : null,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: iconOnly ? 0 : spacing.md,
          ),
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(ws.controlRadius),
            border: Border.all(color: ws.border),
          ),
          child: iconOnly
              ? Icon(Icons.more_horiz, size: 20, color: ws.ink)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.more_horiz, size: 18, color: ws.ink),
                    SizedBox(width: spacing.xs),
                    Text(
                      l10n.jobDetailMoreActions,
                      style: ws.bodyStrong.copyWith(color: ws.ink),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
