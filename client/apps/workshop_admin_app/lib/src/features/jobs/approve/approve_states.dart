import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

enum ApproveNoticeTone { warning, danger }

/// Bounded load failure for the approve screen, with the honest copy supplied
/// by `jobErrorCopy` (403 vs 404 vs network are distinct).
class ApproveLoadError extends StatelessWidget {
  const ApproveLoadError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WorkshopErrorState(
      title: l10n.error,
      body: message,
      retryLabel: l10n.retryAction,
      onRetry: onRetry,
    );
  }
}

/// Inline notice for a blocked mutation or a stale/missing version. A reload
/// action is optional because a missing version or an approver guard is not
/// fixed by refreshing; a conflict is.
class ApproveNotice extends StatelessWidget {
  const ApproveNotice({
    required this.message,
    this.onReload,
    this.tone = ApproveNoticeTone.danger,
    super.key,
  });

  final String message;
  final VoidCallback? onReload;
  final ApproveNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final danger = tone == ApproveNoticeTone.danger;
    final foreground = danger ? ws.danger : ws.warning;
    final background = danger ? ws.dangerSoft : ws.warningSoft;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(spacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(ws.cardRadius),
          border: Border.all(color: foreground.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  danger ? Icons.error_outline : Icons.info_outline,
                  size: 18,
                  color: foreground,
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(message, style: ws.body.copyWith(color: ws.ink)),
                ),
              ],
            ),
            if (onReload != null) ...[
              SizedBox(height: spacing.sm),
              WorkshopButton(
                key: const Key('jobs-approve-reload'),
                label: l10n.refresh,
                icon: Icons.refresh,
                variant: WorkshopButtonVariant.secondary,
                onPressed: onReload,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
