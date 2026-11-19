import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/labels.dart';

/// Status tone for a job chip. Shared by the queue, board and detail; never
/// colour alone (the badge always renders its label too).
WorkshopStatusTone workshopJobTone(String status) => switch (status) {
  'ASSIGNED' || 'IN_PROGRESS' => WorkshopStatusTone.accent,
  'READY_TO_FINALIZE' || 'PENDING_REVIEW' => WorkshopStatusTone.warning,
  'APPROVED' || 'PUBLISHED' || 'FINALIZED' => WorkshopStatusTone.success,
  'CANCELLED' || 'REJECTED' => WorkshopStatusTone.danger,
  _ => WorkshopStatusTone.neutral,
};

/// Localized lifecycle label. An unknown code reads "Unknown status", never
/// the raw enum (inventory §6.1 rule 1).
String cleanJobStatusLabel(AppLocalizations l10n, String status) {
  if (status.isEmpty) {
    return l10n.jobsStatusUnknown;
  }
  final label = jobStatusLabel(l10n, status);
  return label == status ? l10n.jobsStatusUnknown : label;
}

/// Review sub-status label; `NOT_SUBMITTED` has no dedicated key, so callers
/// render [AppLocalizations.commonNotAvailable] instead of a raw code.
String? reviewStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'PENDING_REVIEW' => l10n.jobsStatusPendingReview,
      'APPROVED' => l10n.jobsStatusApproved,
      'REJECTED' => l10n.jobsStatusRejected,
      _ => null,
    };

/// Publication status mapping (G-J2). The only live value is the job's
/// `PUBLISHED` publication status; the stale `ACTIVE` value is not trusted.
String publicationStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'PUBLISHED' => l10n.jobsStatusPublished,
      'UNPUBLISHED' || 'NOT_PUBLISHED' => l10n.notPublished,
      'REVOKED' => l10n.linkRevoked,
      _ => l10n.notPublished,
    };

WorkshopStatusTone publicationStatusTone(String status) => switch (status) {
  'PUBLISHED' => WorkshopStatusTone.success,
  'REVOKED' => WorkshopStatusTone.danger,
  _ => WorkshopStatusTone.neutral,
};

/// Localized job status pill (clean vocabulary).
class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WorkshopStatusBadge(
      label: cleanJobStatusLabel(l10n, status),
      tone: workshopJobTone(status),
    );
  }
}

/// Review sub-status pill, only rendered when it adds information.
class JobReviewStatusBadge extends StatelessWidget {
  const JobReviewStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = reviewStatusLabel(l10n, status);
    if (label == null) {
      return const SizedBox.shrink();
    }
    return WorkshopStatusBadge(
      label: '${l10n.jobsReviewTitle}: $label',
      tone: workshopJobTone(status),
      icon: Icons.rate_review_outlined,
    );
  }
}

/// Publication pill. Unknown/absent values read "Not published" — a revoked
/// or stale link is never presented as live (J10).
class JobPublicationBadge extends StatelessWidget {
  const JobPublicationBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WorkshopStatusBadge(
      label: publicationStatusLabel(l10n, status),
      tone: publicationStatusTone(status),
      icon: Icons.public_outlined,
    );
  }
}
