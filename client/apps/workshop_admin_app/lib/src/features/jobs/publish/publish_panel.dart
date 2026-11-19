import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// The one publish action (M6). It is disabled unless the server says the
/// checklist is ready AND consent is granted; both reasons are stated in place
/// instead of promising a publish path the server will refuse (CR-5).
class PublishPanel extends StatelessWidget {
  const PublishPanel({
    required this.checklist,
    required this.busy,
    required this.pdfDownload,
    required this.onPdfDownloadChanged,
    required this.onPublish,
    super.key,
  });

  final PublishChecklist checklist;
  final bool busy;
  final bool pdfDownload;
  final ValueChanged<bool> onPdfDownloadChanged;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.publish),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l10n.pdfDownload, style: ws.bodyStrong)),
                  _DownloadToggle(
                    value: pdfDownload,
                    onChanged: busy ? null : onPdfDownloadChanged,
                  ),
                ],
              ),
              SizedBox(height: spacing.md),
              if (!checklist.consentGranted) ...[
                Text(
                  l10n.jobsPublicationBlocked,
                  style: ws.bodyStrong.copyWith(color: ws.danger),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  l10n.jobsPublicationBlockedBody,
                  style: ws.body.copyWith(color: ws.ink),
                ),
                SizedBox(height: spacing.sm),
                WorkshopInlineNote(
                  key: const Key('jobs-consent-unavailable-note'),
                  text: l10n.jobsConsentUnavailableNote,
                  icon: Icons.verified_user_outlined,
                ),
                SizedBox(height: spacing.md),
              ],
              WorkshopButton(
                key: const Key('jobs-publish-button'),
                label: l10n.jobsPublishNow,
                icon: Icons.public_outlined,
                isLoading: busy,
                onPressed: onPublish,
                expand: true,
              ),
              if (!checklist.ready) ...[
                SizedBox(height: spacing.sm),
                WorkshopInlineNote(
                  key: const Key('jobs-checklist-blocked-note'),
                  text: l10n.jobsChecklistNotReady,
                  icon: Icons.error_outline,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A 44 px tappable, token-styled toggle. Not a Material `Switch`: the kit
/// owns the control geometry and mirrors in RTL via directional alignment.
class _DownloadToggle extends StatelessWidget {
  const _DownloadToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final enabled = onChanged != null;
    final duration = context.motionDuration(const Duration(milliseconds: 140));
    return Semantics(
      button: true,
      enabled: enabled,
      toggled: value,
      label: l10n.pdfDownload,
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(ws.touchTarget),
        child: SizedBox(
          width: ws.touchTarget + 12,
          height: ws.touchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              curve: context.motion.enterCurve,
              width: 46,
              height: 26,
              padding: const EdgeInsets.all(3),
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              decoration: BoxDecoration(
                color: value ? ws.accent : ws.border,
                borderRadius: BorderRadius.circular(ws.touchTarget),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: ws.surface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
