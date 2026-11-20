import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Why the publish pill is disabled, stated next to it instead of promising a
/// publish path the server will refuse (CR-5).
///
/// Two independent gates exist: the server checklist must be ready, and
/// public-link consent must be granted. Both are named when both fail. When the
/// gate allows publishing this renders nothing, so the copy can never imply a
/// block that is not there.
class PublishGate extends ConsumerWidget {
  const PublishGate({required this.checklist, super.key});

  final PublishChecklist checklist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final consent = ref.watch(statusesProvider('consent')).value;
    final consentCode = consentStatusCode(false);
    final consentLabel = referenceStatusText(consent, consentCode);
    final (consentTone, _) = workshopPillColors(
      referenceStatusTone(consent, consentCode),
      ws,
    );
    if (checklist.ready && checklist.consentGranted) {
      return const SizedBox.shrink();
    }
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(spacing.md),
        decoration: BoxDecoration(
          color: ws.dangerSoft,
          borderRadius: BorderRadius.circular(ws.cardRadius),
          border: Border.all(color: ws.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!checklist.consentGranted) ...[
              Text(
                t(WorkshopAdminKeys.jobsPublicationBlocked),
                style: ws.bodyStrong.copyWith(color: ws.danger),
              ),
              SizedBox(height: spacing.xs),
              Text(
                t(WorkshopAdminKeys.jobsPublicationBlockedBody),
                style: ws.body.copyWith(color: ws.ink),
              ),
              SizedBox(height: spacing.sm),
            ],
            if (!checklist.consentGranted)
              _GateReason(
                key: const Key('jobs-consent-unavailable-note'),
                icon: Icons.verified_user_outlined,
                text: consentLabel,
                tone: consentTone,
              ),
            if (!checklist.ready) ...[
              if (!checklist.consentGranted) SizedBox(height: spacing.xs),
              _GateReason(
                key: const Key('jobs-checklist-blocked-note'),
                icon: Icons.error_outline,
                text: t(WorkshopAdminKeys.jobsChecklistNotReady),
                tone: ws.danger,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One plain reason line inside [PublishGate]. No inner surface: the gate is
/// already the container, and nested tinted boxes read as noise.
class _GateReason extends StatelessWidget {
  const _GateReason({
    required this.icon,
    required this.text,
    required this.tone,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: context.sizing.iconMd, color: tone),
        SizedBox(width: spacing.sm),
        Expanded(
          child: Text(text, style: ws.meta.copyWith(color: ws.ink)),
        ),
      ],
    );
  }
}
