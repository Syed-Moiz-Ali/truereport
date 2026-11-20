import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_action_set.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Renders exactly the actions in [actions].
///
/// No job status is inspected here. `CONSENT` is hidden once consent is
/// granted; an action that declares `requiresConsent` stays disabled until
/// consent exists. When the list lacks a CONSENT action but a requiring action
/// needs one, [onGrantConsent] surfaces the control directly.
class JobActionButtons extends StatelessWidget {
  const JobActionButtons({
    super.key,
    required this.actions,
    required this.onAction,
    this.consentGranted = false,
    this.onGrantConsent,
    this.enabled = true,
  });

  final List<JobAction> actions;
  final ValueChanged<JobAction> onAction;
  final bool consentGranted;
  final VoidCallback? onGrantConsent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final visible = <JobAction>[
      for (final action in actions)
        if (!(consentGranted &&
            normalizedJobActionCode(action.code) == 'CONSENT'))
          action,
    ];
    if (visible.isEmpty) return const SizedBox.shrink();

    final t = UiStrings.of(context);
    final hasConsentAction = visible.any(
      (action) => normalizedJobActionCode(action.code) == 'CONSENT',
    );
    final needsConsent =
        !consentGranted && visible.any((action) => action.requiresConsent);
    final primaryCode = visible
        .firstWhere(
          (action) => normalizedJobActionCode(action.code) != 'CONSENT',
          orElse: () => visible.first,
        )
        .code;
    final showConsentControl =
        needsConsent && !hasConsentAction && onGrantConsent != null;

    final pills = <Widget>[
      if (showConsentControl)
        JobPillButton(
          key: const Key('job-action-consent'),
          label: t(WorkshopAdminKeys.jobsConsentGrant),
          icon: Icons.verified_user_outlined,
          variant: JobPillVariant.outline,
          onPressed: enabled ? onGrantConsent : null,
        ),
      for (final action in visible)
        JobPillButton(
          key: Key('job-action-${action.code}'),
          label: jobActionLabel(action),
          icon: _iconFor(action.code),
          variant: action.dangerous
              ? JobPillVariant.danger
              : normalizedJobActionCode(action.code) ==
                    normalizedJobActionCode(primaryCode)
              ? JobPillVariant.filled
              : JobPillVariant.outline,
          onPressed:
              !enabled ||
                  !isHandledJobAction(action.code) ||
                  (action.requiresConsent && !consentGranted)
              ? null
              : () => onAction(action),
        ),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: pills);
  }
}

IconData _iconFor(String code) => switch (normalizedJobActionCode(code)) {
  'ASSIGN' => Icons.person_add_alt_1_outlined,
  'CONSENT' => Icons.verified_user_outlined,
  'CANCEL' => Icons.cancel_outlined,
  'APPROVE' => Icons.verified_outlined,
  'REJECT' => Icons.block_outlined,
  'REVIEW' => Icons.rate_review_outlined,
  'PUBLISH' || 'PUBLISHCHECKLIST' => Icons.playlist_add_check,
  'UNPUBLISH' || 'REVOKE' => Icons.link_off,
  'ROTATE_TOKEN' => Icons.autorenew,
  'PUBLIC_LINK' => Icons.link,
  _ => Icons.open_in_new,
};
