import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../jobs/queue/jobs_queue_primitives.dart';
import '../../jobs/queue/jobs_queue_style.dart';

/// Evidence in place: counts from the requirement, direct capture rows and
/// the upload state. Nothing navigates away from the item.
class EvidenceSection extends StatelessWidget {
  const EvidenceSection({
    required this.photos,
    required this.minPhotos,
    required this.videos,
    required this.minVideos,
    required this.onCapturePhoto,
    required this.onCaptureVideo,
    this.documents = 0,
    this.minDocuments = 0,
    this.onCaptureDocument,
    this.interactive = true,
    this.busy = false,
    this.progress,
    this.progressLabel,
    this.onCancel,
    this.failed = false,
    this.onRetry,
    this.error,
    this.queued = false,
    this.strip,
    super.key,
  });

  final int photos;
  final int minPhotos;
  final int videos;
  final int minVideos;
  final int documents;
  final int minDocuments;
  final VoidCallback onCapturePhoto;
  final VoidCallback onCaptureVideo;
  final VoidCallback? onCaptureDocument;

  /// Read-only items show the counts with no capture affordance.
  final bool interactive;
  final bool busy;
  final double? progress;
  final String? progressLabel;
  final VoidCallback? onCancel;
  final bool failed;
  final VoidCallback? onRetry;
  final String? error;
  final bool queued;

  /// Thumbnail strip under the Photo/Video rows; null when there is nothing
  /// captured yet. The screen owns open/delete/bytes — this card only lays
  /// the rows and the strip out.
  final Widget? strip;

  bool get _empty => photos == 0 && videos == 0 && documents == 0 && !busy;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t(TechnicianKeys.technicianEvidence),
            style: queueText(
              context,
              16,
              weight: FontWeight.w700,
              height: 22,
              tracking: -0.1,
            ),
          ),
          if (_empty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 24,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t(TechnicianKeys.technicianSessionNoPhoto),
                    style: queueText(
                      context,
                      15,
                      weight: FontWeight.w600,
                      height: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          _EvidenceRow(
            icon: Icons.photo_camera_outlined,
            label: t(TechnicianKeys.technicianPhoto),
            done: photos,
            required: minPhotos,
            interactive: interactive && !busy,
            onTap: onCapturePhoto,
          ),
          Divider(height: 1, color: colors.outlineVariant),
          _EvidenceRow(
            icon: Icons.videocam_outlined,
            label: t(TechnicianKeys.technicianVideo),
            done: videos,
            required: minVideos,
            interactive: interactive && !busy,
            onTap: onCaptureVideo,
          ),
          if (minDocuments > 0) ...[
            Divider(height: 1, color: colors.outlineVariant),
            _EvidenceRow(
              icon: Icons.description_outlined,
              label: t(TechnicianKeys.technicianDocument),
              done: documents,
              required: minDocuments,
              interactive: interactive && !busy && onCaptureDocument != null,
              onTap: onCaptureDocument ?? onCapturePhoto,
            ),
          ],
          if (strip != null) ...[const SizedBox(height: 12), strip!],
          if (busy) ...[
            const SizedBox(height: 12),
            if (progress != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(value: progress),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    progressLabel ?? '',
                    style: queueMeta(context, color: colors.onSurfaceVariant),
                  ),
                ),
                if (onCancel != null)
                  GestureDetector(
                    onTap: onCancel,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        t(TechnicianKeys.technicianEvidenceCancel),
                        style: queueText(
                          context,
                          13,
                          weight: FontWeight.w700,
                          height: 18,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (failed && onRetry != null) ...[
            const SizedBox(height: 12),
            QueueButton(
              label: t(TechnicianKeys.technicianRetryUpload),
              variant: QueueButtonVariant.soft,
              icon: Icons.refresh_rounded,
              expand: true,
              onPressed: onRetry,
            ),
          ],
          if (queued) ...[
            const SizedBox(height: 12),
            QueueNote(
              icon: Icons.cloud_off_rounded,
              label: t(TechnicianKeys.technicianEvidenceQueued),
              tone: StatusTone.warning,
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            QueueNote(
              icon: Icons.error_outline_rounded,
              label: error!,
              tone: StatusTone.danger,
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.icon,
    required this.label,
    required this.done,
    required this.required,
    required this.interactive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int done;
  final int required;
  final bool interactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: interactive,
      label: '$label, $done/$required',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: interactive ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
          color: Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: context.brand.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: queueText(
                    context,
                    15,
                    weight: FontWeight.w600,
                    height: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$done/$required',
                textDirection: TextDirection.ltr,
                style: queueText(
                  context,
                  14,
                  weight: FontWeight.w700,
                  height: 20,
                  tabular: true,
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (interactive) ...[
                const SizedBox(width: 4),
                Icon(
                  rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
