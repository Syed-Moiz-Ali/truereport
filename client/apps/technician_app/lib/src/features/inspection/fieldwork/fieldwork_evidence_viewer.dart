import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/inspection_models.dart';

import 'fieldwork_ui.dart';

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
    final typeLabel = item.isVideo
        ? t(TechnicianKeys.technicianVideo)
        : t(TechnicianKeys.technicianDocument);
    final title = item.captionFor(language) ?? typeLabel;
    final meta = _metaLine();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.brand.container,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.isVideo
                    ? Icons.play_circle_outline_rounded
                    : Icons.description_outlined,
                size: 21,
                color: context.brand.onContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 3,
                    style: fieldworkText(
                      context,
                      16,
                      weight: FontWeight.w800,
                      height: 21,
                      tracking: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    typeLabel,
                    style: fieldworkText(
                      context,
                      11.5,
                      height: 15,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 156,
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(FieldworkMetrics.controlRadius),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.isVideo
                    ? Icons.videocam_outlined
                    : Icons.description_outlined,
                size: 36,
                color: colors.onSurfaceVariant,
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  meta,
                  textDirection: TextDirection.ltr,
                  style: fieldworkNumber(
                    context,
                    12.5,
                    weight: FontWeight.w600,
                    height: 17,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        FieldworkButton(
          label: MaterialLocalizations.of(context).closeButtonLabel,
          variant: FieldworkButtonVariant.ghost,
          height: FieldworkMetrics.secondaryHeight,
          expand: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 4),
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
