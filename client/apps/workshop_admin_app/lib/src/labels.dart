import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';

/// Maps master-content lifecycle codes to localized labels.
String contentStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'DRAFT' => l10n.draft,
      'PUBLISHED' => l10n.published,
      'RETIRED' => l10n.retired,
      _ => status,
    };

/// Maps membership role codes to localized labels.
String memberRoleLabel(AppLocalizations l10n, String role) => switch (role) {
  'TECHNICIAN' => l10n.roleTechnician,
  'WORKSHOP_ADMIN' => l10n.roleWorkshopAdmin,
  'PLATFORM_ADMIN' => l10n.rolePlatformAdmin,
  _ => role,
};

/// Maps membership status codes to localized labels.
String memberStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'ACTIVE' => l10n.filterActive,
      'DISABLED' => l10n.disabled,
      'PENDING' => l10n.pending,
      _ => status,
    };

/// Maps job status codes to localized labels.
String jobStatusLabel(AppLocalizations l10n, String status) => switch (status) {
  'DRAFT' => l10n.draft,
  'SCHEDULED' => l10n.statusScheduled,
  'ASSIGNED' => l10n.statusAssigned,
  'IN_PROGRESS' => l10n.statusInProgress,
  'READY_TO_FINALIZE' => l10n.statusReadyToFinalize,
  'PENDING_REVIEW' => l10n.jobsStatusPendingReview,
  'APPROVED' => l10n.jobsStatusApproved,
  'PUBLISHED' => l10n.jobsStatusPublished,
  'REJECTED' => l10n.jobsStatusRejected,
  'FINALIZED' => l10n.statusFinalized,
  'CANCELLED' => l10n.statusCancelled,
  _ => status,
};

/// Maps job status to design system status tone.
StatusTone jobStatusTone(String status) => switch (status) {
  'FINALIZED' || 'APPROVED' || 'PUBLISHED' => StatusTone.success,
  'CANCELLED' || 'REJECTED' => StatusTone.danger,
  'ASSIGNED' || 'IN_PROGRESS' || 'READY_TO_FINALIZE' => StatusTone.info,
  'SCHEDULED' || 'PENDING_REVIEW' => StatusTone.warning,
  _ => StatusTone.neutral,
};
