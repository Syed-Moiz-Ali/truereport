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

/// Phone queue: one 16 px card per job. Header (reference + status), body
/// (vehicle, customer, schedule, technician), footer (the policy action).
class JobsQueueCards extends StatelessWidget {
  const JobsQueueCards({
    required this.items,
    required this.staff,
    required this.onOpen,
    required this.onAction,
    super.key,
  });

  final List<CleanJob> items;
  final List<StaffMember>? staff;
  final ValueChanged<CleanJob> onOpen;
  final void Function(CleanJob job, JobPrimaryAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Large text may use cards at any width: two-up from 900 so a 1440 card
        // is not a full-page banner.
        final twoUp = constraints.maxWidth >= 900;
        Widget card(int index) => _PhoneCard(
          job: items[index],
          staff: staff,
          onOpen: () => onOpen(items[index]),
          onAction: (action) => onAction(items[index], action),
        );
        if (!twoUp) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) SizedBox(height: spacing.md),
                card(index),
              ],
            ],
          );
        }
        final width = (constraints.maxWidth - spacing.md) / 2;
        return Wrap(
          key: const Key('jobs-queue-card-grid'),
          spacing: spacing.md,
          runSpacing: spacing.md,
          children: [
            for (var index = 0; index < items.length; index++)
              SizedBox(width: width, child: card(index)),
          ],
        );
      },
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({
    required this.job,
    required this.staff,
    required this.onOpen,
    required this.onAction,
  });

  final CleanJob job;
  final List<StaffMember>? staff;
  final VoidCallback onOpen;
  final ValueChanged<JobPrimaryAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(ws.cardRadius);
    final actions = jobActionsFor(
      status: job.status,
      consentGranted: job.consentGranted,
    );
    final vehicle = '${job.vehicleMake} ${job.vehicleModel}'.trim();
    final title = vehicle.isEmpty ? job.customerName : vehicle;
    final plate = job.vehiclePlate?.trim() ?? '';
    final schedule = pinDigits(formatInstant(context, job.scheduledAt));
    final technician = jobTechnicianName(l10n, job, staff);
    final semantic =
        '${job.reference}, $title, ${job.customerName}, '
        '${cleanJobStatusLabel(l10n, job.status)}, '
        '${schedule.isEmpty ? l10n.commonNotAvailable : schedule}, '
        '$technician';
    return Container(
      key: Key('job-${job.id}'),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: radius,
        border: Border.all(color: ws.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            key: Key('job-card-${job.id}'),
            container: true,
            button: true,
            label: semantic,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ws.cardRadius),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.all(ws.cardPadding),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.reference,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: ws.eyebrow.copyWith(
                                  color: ws.muted,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            JobStatusBadge(status: job.status),
                          ],
                        ),
                        SizedBox(height: spacing.sm),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ws.sectionTitle,
                        ),
                        if (plate.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            plate,
                            maxLines: 1,
                            textDirection: TextDirection.ltr,
                            style: ws.meta.copyWith(color: ws.muted),
                          ),
                        ],
                        SizedBox(height: spacing.md),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: ws.muted,
                            ),
                            SizedBox(width: spacing.xs),
                            Expanded(
                              child: Text(
                                job.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ws.body.copyWith(color: ws.ink),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.xs),
                        Wrap(
                          spacing: spacing.md,
                          runSpacing: spacing.xs,
                          children: [
                            JobMetaLine(
                              icon: Icons.schedule,
                              text: schedule.isEmpty
                                  ? l10n.commonNotAvailable
                                  : schedule,
                              textDirection: TextDirection.ltr,
                            ),
                            JobMetaLine(
                              icon: Icons.engineering_outlined,
                              text: technician,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: ws.canvas.withValues(alpha: 0.5),
              border: BorderDirectional(top: BorderSide(color: ws.border)),
            ),
            padding: EdgeInsetsDirectional.all(spacing.md),
            child: _footer(context, l10n, actions),
          ),
        ],
      ),
    );
  }

  Widget _footer(
    BuildContext context,
    AppLocalizations l10n,
    JobActions actions,
  ) {
    if (actions.primary == JobPrimaryAction.none) {
      if (job.status != 'APPROVED') {
        return WorkshopInlineNote(
          text: l10n.jobsNoSelection,
          icon: Icons.lock_outline,
        );
      }
      final ws = context.ws;
      final spacing = context.spacing;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.jobsPublicationBlocked,
            style: ws.bodyStrong.copyWith(color: ws.ink),
          ),
          SizedBox(height: spacing.xs),
          WorkshopInlineNote(
            key: Key('job-card-publication-blocked-${job.id}'),
            text: l10n.jobsPublicationBlockedBody,
            icon: Icons.lock_outline,
          ),
          SizedBox(height: spacing.sm),
          WorkshopButton(
            key: Key('job-card-publish-checklist-${job.id}'),
            label: l10n.jobsViewChecklist,
            icon: Icons.playlist_add_check_outlined,
            variant: WorkshopButtonVariant.secondary,
            expand: true,
            onPressed: () => onAction(JobPrimaryAction.publishChecklist),
          ),
        ],
      );
    }
    final versionBlocked = actions.requiresVersion && job.version == null;
    final label = switch (actions.primary) {
      JobPrimaryAction.assign => l10n.jobsNextAssign,
      JobPrimaryAction.openJob => l10n.jobsNextOpen,
      JobPrimaryAction.reviewApprove => l10n.jobsNextReview,
      JobPrimaryAction.publishChecklist => l10n.jobsNextPublish,
      JobPrimaryAction.publicLink => l10n.jobsNextLink,
      JobPrimaryAction.none => l10n.jobsNextOpen,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopButton(
          key: Key('job-primary-${job.id}'),
          label: label,
          expand: true,
          icon: switch (actions.primary) {
            JobPrimaryAction.assign => Icons.person_add_alt_1_outlined,
            JobPrimaryAction.reviewApprove => Icons.verified_outlined,
            JobPrimaryAction.publishChecklist =>
              Icons.playlist_add_check_outlined,
            JobPrimaryAction.publicLink => Icons.link,
            _ => Icons.open_in_new,
          },
          onPressed: versionBlocked ? null : () => onAction(actions.primary),
        ),
        if (versionBlocked) ...[
          SizedBox(height: context.spacing.sm),
          WorkshopInlineNote(text: l10n.jobsNoVersion),
        ],
      ],
    );
  }
}
