import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/inspection_models.dart';

import '../../jobs/queue/jobs_queue_primitives.dart';
import '../../jobs/queue/jobs_queue_style.dart';

/// Read-only evidence viewer for video and documents.
///
/// Photos open the existing markup route instead; this sheet is the viewer
/// for everything else. All copy is the served caption or an existing type
/// label — the meta line is numbers and symbols only.
Future<void> showEvidenceViewer(BuildContext context, Evidence item) {
  return showAppBottomSheet<void>(
    context,
    child: _EvidenceViewerSheet(item: item),
  );
}

class _EvidenceViewerSheet extends StatelessWidget {
  const _EvidenceViewerSheet({required this.item});

  final Evidence item;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    final title =
        item.captionFor(language) ??
        (item.isVideo
            ? t(TechnicianKeys.technicianVideo)
            : t(TechnicianKeys.technicianDocument));
    final meta = _metaLine();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isVideo
                    ? Icons.play_circle_outline_rounded
                    : Icons.description_outlined,
                size: 24,
                color: context.brand.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: queueText(
                  context,
                  16,
                  weight: FontWeight.w700,
                  height: 22,
                  tracking: -0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.isVideo
                    ? Icons.videocam_outlined
                    : Icons.description_outlined,
                size: 40,
                color: colors.onSurfaceVariant,
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  meta,
                  textDirection: TextDirection.ltr,
                  style: queueText(
                    context,
                    13,
                    weight: FontWeight.w600,
                    height: 18,
                    tabular: true,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        QueueButton(
          label: MaterialLocalizations.of(context).closeButtonLabel,
          variant: QueueButtonVariant.soft,
          expand: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  /// Size and duration only — no words, so no copy key is needed.
  String _metaLine() {
    final parts = <String>[_formatBytes(item.bytes)];
    final durationMs = item.durationMs;
    if (item.isVideo && durationMs != null) {
      final totalSeconds = (durationMs / 1000).round();
      final minutes = totalSeconds ~/ 60;
      final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
      parts.add('$minutes:$seconds');
    }
    return parts.join(' • ');
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}
