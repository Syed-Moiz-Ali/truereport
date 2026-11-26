import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/evidence_upload_queue.dart';
import 'package:technician_app/src/inspection_models.dart';

import '../../jobs/queue/jobs_queue_style.dart';

/// Per-tile upload state, derived from served data plus the page's
/// in-flight tracking. Nothing here is invented: a served danger status, a
/// locally queued row, or a sha the page is currently uploading or failed.
enum EvidenceTileState { uploading, queued, failed, ready }

EvidenceTileState tileStateFor({
  required Evidence item,
  required EvidenceUploadState upload,
  required String? uploadingSha,
  required String? failedSha,
}) {
  final sha = item.sha256;
  if (uploadingSha != null &&
      sha != null &&
      uploadingSha == sha &&
      (upload.stage == EvidenceUploadStage.capturing ||
          upload.stage == EvidenceUploadStage.uploading)) {
    return EvidenceTileState.uploading;
  }
  if (failedSha != null && sha != null && failedSha == sha) {
    return EvidenceTileState.failed;
  }
  if (item.id.startsWith('local-')) {
    return EvidenceTileState.queued;
  }
  return EvidenceTileState.ready;
}

String _badgeLabel(UiStrings t, EvidenceTileState state) {
  switch (state) {
    case EvidenceTileState.uploading:
      return t(TechnicianKeys.technicianEvidenceStateUploading);
    case EvidenceTileState.queued:
      return t(TechnicianKeys.technicianEvidenceStateQueued);
    case EvidenceTileState.failed:
      return t(TechnicianKeys.technicianEvidenceStateFailed);
    case EvidenceTileState.ready:
      return '';
  }
}

/// The captured evidence as a horizontal strip of 72 px thumbnails.
///
/// Tapping a photo opens the existing mark flow; videos and documents open a
/// viewer sheet. The trailing × deletes with a confirm sheet, and it sits
/// outside the tile's tap area so deleting never also opens the tile.
class EvidenceStrip extends StatefulWidget {
  const EvidenceStrip({
    required this.items,
    required this.upload,
    required this.onOpen,
    required this.onDelete,
    required this.loadBytes,
    this.uploadingSha,
    this.failedSha,
    this.interactive = true,
    super.key,
  });

  final List<Evidence> items;
  final EvidenceUploadState upload;
  final ValueChanged<Evidence> onOpen;
  final ValueChanged<Evidence> onDelete;
  final Future<Uint8List?> Function(Evidence item) loadBytes;
  final String? uploadingSha;
  final String? failedSha;

  /// Read-only items keep viewing but lose the delete affordance.
  final bool interactive;

  @override
  State<EvidenceStrip> createState() => _EvidenceStripState();
}

class _EvidenceStripState extends State<EvidenceStrip> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _EvidenceTile(
            item: item,
            state: tileStateFor(
              item: item,
              upload: widget.upload,
              uploadingSha: widget.uploadingSha,
              failedSha: widget.failedSha,
            ),
            interactive: widget.interactive,
            onOpen: () => widget.onOpen(item),
            onDelete: () => widget.onDelete(item),
            loadBytes: () => widget.loadBytes(item),
          );
        },
      ),
    );
  }
}

class _EvidenceTile extends StatefulWidget {
  const _EvidenceTile({
    required this.item,
    required this.state,
    required this.interactive,
    required this.onOpen,
    required this.onDelete,
    required this.loadBytes,
  });

  final Evidence item;
  final EvidenceTileState state;
  final bool interactive;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final Future<Uint8List?> Function() loadBytes;

  @override
  State<_EvidenceTile> createState() => _EvidenceTileState();
}

class _EvidenceTileState extends State<_EvidenceTile> {
  Uint8List? _bytes;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isPhoto) {
      _load();
    } else {
      _done = true;
    }
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.loadBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _done = true;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final item = widget.item;
    final typeLabel = item.isPhoto
        ? t(TechnicianKeys.technicianPhoto)
        : item.isVideo
        ? t(TechnicianKeys.technicianVideo)
        : t(TechnicianKeys.technicianDocument);
    final stateLabel = _badgeLabel(t, widget.state);
    final semantics = stateLabel.isEmpty
        ? typeLabel
        : '$typeLabel, $stateLabel';
    return Semantics(
      button: true,
      explicitChildNodes: true,
      label: semantics,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpen,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(child: _content(context)),
                        PositionedDirectional(
                          end: 2,
                          top: 2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: colors.surface.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: Icon(
                              item.isPhoto
                                  ? Icons.photo_outlined
                                  : item.isVideo
                                  ? Icons.videocam_outlined
                                  : Icons.description_outlined,
                              size: 11,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (stateLabel.isNotEmpty)
                          PositionedDirectional(
                            start: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _badgeBackground(context),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _badgeForeground(context),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    stateLabel,
                                    maxLines: 1,
                                    style: queueText(
                                      context,
                                      10,
                                      weight: FontWeight.w700,
                                      height: 13,
                                      color: _badgeForeground(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.interactive)
              PositionedDirectional(
                start: 2,
                top: 2,
                child: Semantics(
                  button: true,
                  excludeSemantics: true,
                  label: t(TechnicianKeys.technicianDeleteEvidence),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onDelete,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _badgeBackground(BuildContext context) {
    final pair = context.statusColors.forTone(_badgeTone());
    return pair.background;
  }

  Color _badgeForeground(BuildContext context) {
    final pair = context.statusColors.forTone(_badgeTone());
    return pair.foreground;
  }

  StatusTone _badgeTone() {
    switch (widget.state) {
      case EvidenceTileState.uploading:
        return StatusTone.info;
      case EvidenceTileState.queued:
        return StatusTone.warning;
      case EvidenceTileState.failed:
        return StatusTone.danger;
      case EvidenceTileState.ready:
        return StatusTone.neutral;
    }
  }

  Widget _content(BuildContext context) {
    final colors = context.colors;
    final bytes = _bytes;
    if (widget.item.isPhoto && bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        cacheWidth: 240,
        gaplessPlayback: true,
        errorBuilder: (context, _, _) => _fallbackIcon(context),
      );
    }
    if (widget.item.isPhoto && !_done) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (widget.item.isPhoto) {
      return _fallbackIcon(context);
    }
    final duration = widget.item.durationMs;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.item.isVideo
                ? Icons.play_circle_outline_rounded
                : Icons.description_outlined,
            size: 22,
            color: context.brand.ink,
          ),
          if (widget.item.isVideo && duration != null) ...[
            const SizedBox(height: 2),
            Text(
              _formatDuration(duration),
              style: queueText(
                context,
                10,
                weight: FontWeight.w700,
                height: 13,
                tabular: true,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 20,
        color: context.colors.onSurfaceVariant,
      ),
    );
  }

  /// Clock-style duration from the served milliseconds: numbers and one
  /// colon only, so no copy key is needed.
  String _formatDuration(int durationMs) {
    final totalSeconds = (durationMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
