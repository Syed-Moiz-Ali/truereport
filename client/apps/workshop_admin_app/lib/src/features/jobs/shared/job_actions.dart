/// One pure policy for a clean job: which lifecycle actions are allowed.
///
/// Server rules mirrored here (M3/M5/M6/M12):
/// - assignable only in DRAFT, SCHEDULED, ASSIGNED, IN_PROGRESS;
/// - approve/reject only in PENDING_REVIEW;
/// - the checklist (never `publishJob`) only for APPROVED + consent;
/// - cancel never in CANCELLED/PUBLISHED/APPROVED/REJECTED;
/// - CANCELLED/PUBLISHED/REJECTED are read-only, and APPROVED hides
///   assign/cancel;
/// - every mutating action needs a non-null version.
///
/// The function is deliberately pure Dart: the table test exercises every
/// status without a widget tree.
library;

/// The single primary affordance the detail screen (and the inspector) offers.
enum JobPrimaryAction {
  /// No primary action. Used when publishing is blocked, and while the page
  /// has no job yet.
  none,

  /// Open the assign sheet.
  assign,

  /// The job is already open (inspector rows only); detail renders no primary.
  openJob,

  /// Open the approve/reject page. Approve/reject exist only here.
  reviewApprove,

  /// Open the publish checklist. This is the only client publish gate (M6).
  publishChecklist,

  /// Open the public-link page.
  publicLink,
}

/// Allowed actions for one job state.
class JobActions {
  const JobActions({
    required this.primary,
    required this.canAssign,
    required this.canCancel,
    required this.canApprove,
    required this.canReject,
    required this.readOnly,
    required this.requiresVersion,
  });

  final JobPrimaryAction primary;
  final bool canAssign;
  final bool canCancel;
  final bool canApprove;
  final bool canReject;

  /// Terminal: no lifecycle mutation is offered at all.
  final bool readOnly;

  /// The primary/secondary mutations must not be submitted without a version.
  final bool requiresVersion;

  bool get hasPrimary => primary != JobPrimaryAction.none;
}

const JobActions _readOnly = JobActions(
  primary: JobPrimaryAction.openJob,
  canAssign: false,
  canCancel: false,
  canApprove: false,
  canReject: false,
  readOnly: true,
  requiresVersion: false,
);

const JobActions _assignable = JobActions(
  primary: JobPrimaryAction.assign,
  canAssign: true,
  canCancel: true,
  canApprove: false,
  canReject: false,
  readOnly: false,
  requiresVersion: true,
);

const JobActions _inBay = JobActions(
  primary: JobPrimaryAction.openJob,
  canAssign: true,
  canCancel: true,
  canApprove: false,
  canReject: false,
  readOnly: false,
  requiresVersion: true,
);

const JobActions _pendingReview = JobActions(
  primary: JobPrimaryAction.reviewApprove,
  canAssign: false,
  canCancel: true,
  canApprove: true,
  canReject: true,
  readOnly: false,
  requiresVersion: true,
);

/// Resolve the policy for a job status. `consentGranted` only matters for
/// APPROVED: without it publishing is blocked and no action is promised.
JobActions jobActionsFor({
  required String status,
  required bool consentGranted,
}) => switch (status) {
  'DRAFT' || 'SCHEDULED' => _assignable,
  'ASSIGNED' || 'IN_PROGRESS' => _inBay,
  'PENDING_REVIEW' => _pendingReview,
  'APPROVED' => JobActions(
    primary: consentGranted
        ? JobPrimaryAction.publishChecklist
        : JobPrimaryAction.none,
    canAssign: false,
    canCancel: false,
    canApprove: false,
    canReject: false,
    readOnly: false,
    requiresVersion: false,
  ),
  'PUBLISHED' => const JobActions(
    primary: JobPrimaryAction.publicLink,
    canAssign: false,
    canCancel: false,
    canApprove: false,
    canReject: false,
    readOnly: true,
    requiresVersion: false,
  ),
  // REJECTED / CANCELLED are terminal; an unknown status never invents an
  // action (and never mutates).
  _ => _readOnly,
};
