import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_actions.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Case-insensitive action code used by the served payload (`APPROVE`) and the
/// local fallback (`APPROVE`).
String normalizedJobActionCode(String code) => code.trim().toUpperCase();

/// Server actions when present; otherwise the current status matrix expressed
/// as **codes only** (labels stay in the backend catalog / action resolver).
List<JobAction> effectiveDetailActions(CleanJob job) {
  if (job.allowedActions.isNotEmpty) return job.allowedActions;
  return _fallbackDetailActions(job);
}

List<JobAction> effectiveReviewActions(CleanJob job, {JobReview? review}) {
  if (review != null && review.allowedActions.isNotEmpty) {
    return review.allowedActions;
  }
  if (job.allowedActions.isNotEmpty) return job.allowedActions;
  return _fallbackReviewActions(job);
}

List<JobAction> effectivePublishActions(
  CleanJob? job,
  PublishChecklist checklist,
) {
  if (checklist.allowedActions.isNotEmpty) return checklist.allowedActions;
  if (job != null && job.allowedActions.isNotEmpty) {
    final actions = job.allowedActions
        .where((action) => _isPublishCode(action.code))
        .toList(growable: false);
    if (actions.isNotEmpty) return actions;
  }
  return _fallbackPublishActions(checklist);
}

List<JobAction> _fallbackDetailActions(CleanJob job) {
  final matrix = jobActionsFor(
    status: job.status,
    consentGranted: job.consentGranted,
  );
  final editable = job.status != 'CANCELLED' && job.status != 'PUBLISHED';
  final actions = <JobAction>[];
  void add(JobAction action) {
    if (actions.any(
      (existing) =>
          normalizedJobActionCode(existing.code) ==
          normalizedJobActionCode(action.code),
    )) {
      return;
    }
    actions.add(action);
  }

  if (matrix.canAssign || matrix.primary == JobPrimaryAction.assign) {
    add(const JobAction(code: 'ASSIGN', tone: 'info'));
  }
  if (!job.consentGranted && editable) {
    add(const JobAction(code: 'CONSENT', tone: 'info'));
  }
  switch (matrix.primary) {
    case JobPrimaryAction.reviewApprove:
      add(const JobAction(code: 'REVIEW', tone: 'info'));
    case JobPrimaryAction.publishChecklist:
      add(
        const JobAction(
          code: 'PUBLISH',
          tone: 'success',
          requiresConsent: true,
        ),
      );
    case JobPrimaryAction.publicLink:
      add(const JobAction(code: 'PUBLIC_LINK'));
    case JobPrimaryAction.assign:
    case JobPrimaryAction.openJob:
    case JobPrimaryAction.none:
      break;
  }
  if (matrix.canCancel) {
    add(const JobAction(code: 'CANCEL', tone: 'danger', dangerous: true));
  }
  return List<JobAction>.unmodifiable(actions);
}

List<JobAction> _fallbackReviewActions(CleanJob job) {
  final matrix = jobActionsFor(
    status: job.status,
    consentGranted: job.consentGranted,
  );
  final actions = <JobAction>[];
  if (matrix.canApprove) {
    actions.add(const JobAction(code: 'APPROVE', tone: 'success'));
  }
  if (matrix.canReject) {
    actions.add(
      const JobAction(code: 'REJECT', tone: 'danger', dangerous: true),
    );
  }
  if (matrix.primary == JobPrimaryAction.publishChecklist) {
    actions.add(
      const JobAction(code: 'PUBLISH', tone: 'success', requiresConsent: true),
    );
  }
  return List<JobAction>.unmodifiable(actions);
}

List<JobAction> _fallbackPublishActions(PublishChecklist checklist) {
  // Keep the primary visible (disabled by readiness) rather than hiding it;
  // the gate below explains what is missing.
  return const <JobAction>[
    JobAction(code: 'PUBLISH', tone: 'success', requiresConsent: true),
  ];
}

bool _isPublishCode(String code) {
  final normalized = normalizedJobActionCode(code);
  return normalized == 'PUBLISH' || normalized == 'PUBLISHCHECKLIST';
}

/// First action matching any of [codes]; null when the server did not allow it.
JobAction? jobActionFor(Iterable<JobAction> actions, Iterable<String> codes) {
  final wanted = codes.map(normalizedJobActionCode).toSet();
  for (final action in actions) {
    if (wanted.contains(normalizedJobActionCode(action.code))) return action;
  }
  return null;
}

/// True when this client has a handler for the served action code.
// gate-allow: behaviour - action code -> handler availability, not a label.
bool isHandledJobAction(String code) => switch (normalizedJobActionCode(code)) {
  'ASSIGN' ||
  'CONSENT' ||
  'APPROVE' ||
  'REJECT' ||
  'REVIEW' ||
  'PUBLISH' ||
  'PUBLISHCHECKLIST' ||
  'UNPUBLISH' ||
  'ROTATE_TOKEN' ||
  'REVOKE' ||
  'PUBLIC_LINK' ||
  'OPEN_JOB' ||
  'VIEW' ||
  'CANCEL' => true,
  _ => false,
};

/// Display label for an action: the served `labelKey` only.
///
/// The client never owns an action-code label map. A missing key falls back to
/// the humanized code so a newer action still renders something honest.
String jobActionLabel(JobAction action) {
  if (action.labelKey.isNotEmpty) {
    final served = remoteEnglish(action.labelKey);
    if (served.isNotEmpty) return served;
  }
  return humanizeReferenceCode(action.code);
}
