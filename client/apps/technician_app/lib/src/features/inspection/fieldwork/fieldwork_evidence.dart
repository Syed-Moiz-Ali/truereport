import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/evidence_upload_queue.dart';
import 'package:technician_app/src/inspection_models.dart';

import 'fieldwork_ui.dart';

/// Per-tile upload state, derived from served data plus the page's in-flight
/// tracking. Nothing here is invented: a served danger status, a locally
/// queued row, or a sha the page is currently uploading or failed.
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

/// Evidence in place: what the rule asks for, what is already captured, the
/// capture tiles and the live upload state. Nothing navigates away from the
/// item and nothing draws an outer card — this is a zone of the focus card.
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

  /// Thumbnail strip under the header; null when there is nothing captured
  /// yet. The screen owns open/delete/bytes — this zone only lays it out.
  final Widget? strip;

  bool get _empty =>
      photos == 0 && videos == 0 && documents == 0 && !busy && strip == null;

  bool get _satisfied =>
      photos >= minPhotos &&
      videos >= minVideos &&
      (minDocuments == 0 || documents >= minDocuments);

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final tiles = <Widget>[
      if (interactive && !busy)
        _CaptureTile(
          icon: Icons.photo_camera_outlined,
          label: t(TechnicianKeys.technicianPhoto),
          count: '$photos/$minPhotos',
          onTap: onCapturePhoto,
        ),
      if (interactive && !busy)
        _CaptureTile(
          icon: Icons.videocam_outlined,
          label: t(TechnicianKeys.technicianVideo),
          count: '$videos/$minVideos',
          onTap: onCaptureVideo,
        ),
      if (interactive && !busy && minDocuments > 0 && onCaptureDocument != null)
        _CaptureTile(
          icon: Icons.description_outlined,
          label: t(TechnicianKeys.technicianDocument),
          count: '$documents/$minDocuments',
          onTap: onCaptureDocument!,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldworkSectionHeader(
          title: t(TechnicianKeys.technicianEvidence),
          trailing: Text(
            '$photos/$minPhotos · $videos/$minVideos',
            textDirection: TextDirection.ltr,
            style: fieldworkNumber(
              context,
              12,
              weight: FontWeight.w700,
              height: 16,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (strip != null) ...[
          strip!,
          const SizedBox(height: 12),
        ] else if (_empty) ...[
          _EmptyEvidence(label: t(TechnicianKeys.technicianSessionNoPhoto)),
          const SizedBox(height: 12),
        ],
        if (tiles.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tile in tiles)
                    SizedBox(width: tileWidth, child: tile),
                ],
              );
            },
          )
        else if (interactive && busy)
          const SizedBox.shrink()
        else if (!interactive)
          Row(
            children: [
              _CountPill(
                icon: Icons.photo_camera_outlined,
                label: t(TechnicianKeys.technicianPhoto),
                value: '$photos/$minPhotos',
              ),
              const SizedBox(width: 8),
              _CountPill(
                icon: Icons.videocam_outlined,
                label: t(TechnicianKeys.technicianVideo),
                value: '$videos/$minVideos',
              ),
            ],
          ),
        if (busy) ...[
          const SizedBox(height: 12),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
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
                  style: fieldworkText(
                    context,
                    12.5,
                    height: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (onCancel != null)
                FieldworkButton(
                  label: t(TechnicianKeys.technicianEvidenceCancel),
                  variant: FieldworkButtonVariant.text,
                  height: FieldworkMetrics.secondaryHeight,
                  onPressed: onCancel,
                ),
            ],
          ),
        ],
        if (failed && onRetry != null) ...[
          const SizedBox(height: 10),
          FieldworkButton(
            label: t(TechnicianKeys.technicianRetryUpload),
            icon: Icons.refresh_rounded,
            variant: FieldworkButtonVariant.tonal,
            height: FieldworkMetrics.secondaryHeight,
            expand: true,
            onPressed: onRetry,
          ),
        ],
        if (queued) ...[
          const SizedBox(height: 10),
          FieldworkNote(
            message: t(TechnicianKeys.technicianEvidenceQueued),
            tone: StatusTone.warning,
            icon: Icons.cloud_off_rounded,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 10),
          FieldworkNote(
            message: error!,
            tone: StatusTone.danger,
            icon: Icons.error_outline_rounded,
          ),
        ],
        if (!_satisfied) ...[
          const SizedBox(height: 10),
          FieldworkNote(
            message: t(TechnicianKeys.technicianEvidenceRequired),
            tone: StatusTone.warning,
            icon: Icons.camera_outlined,
          ),
        ] else if (strip != null && !queued && !busy && !failed) ...[
          const SizedBox(height: 10),
          FieldworkNote(
            message: t(TechnicianKeys.technicianEvidenceSatisfied),
            tone: StatusTone.success,
            icon: Icons.check_circle_outline,
          ),
        ],
      ],
    );
  }
}

class _EmptyEvidence extends StatelessWidget {
  const _EmptyEvidence({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(FieldworkMetrics.controlRadius),
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 20,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: fieldworkText(
                context,
                13.5,
                weight: FontWeight.w600,
                height: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureTile extends StatefulWidget {
  const _CaptureTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String count;
  final VoidCallback onTap;

  @override
  State<_CaptureTile> createState() => _CaptureTileState();
}

class _CaptureTileState extends State<_CaptureTile> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${widget.label} ${widget.count}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? context.motion.pressScale : 1,
            duration: context.motionDuration(context.motion.fast),
            curve: context.motion.enterCurve,
            child: AnimatedContainer(
              duration: context.motionDuration(context.motion.fast),
              height: 56,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _hover
                    ? context.colors.surfaceContainer
                    : context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(
                  FieldworkMetrics.controlRadius,
                ),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 19, color: context.brand.ink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fieldworkText(
                        context,
                        13,
                        weight: FontWeight.w700,
                        height: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.count,
                    textDirection: TextDirection.ltr,
                    style: fieldworkNumber(
                      context,
                      11.5,
                      weight: FontWeight.w700,
                      height: 15,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(FieldworkMetrics.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: fieldworkText(
              context,
              11.5,
              weight: FontWeight.w600,
              height: 15,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: fieldworkNumber(
              context,
              11.5,
              weight: FontWeight.w700,
              height: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// The captured evidence as a strip of 72 px thumbnails.
///
/// Tapping a tile opens it; the delete affordance sits in the corner with a
/// 44 px hit area but a small visual so it never looks louder than the photo.
class EvidenceStrip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return _EvidenceTile(
            item: item,
            state: tileStateFor(
              item: item,
              upload: upload,
              uploadingSha: uploadingSha,
              failedSha: failedSha,
            ),
            interactive: interactive,
            onOpen: () => onOpen(item),
            onDelete: () => onDelete(item),
            loadBytes: () => loadBytes(item),
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
        width: 76,
        height: 76,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpen,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(
                      FieldworkMetrics.controlRadius,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      FieldworkMetrics.controlRadius,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _content(context),
                        PositionedDirectional(
                          end: 4,
                          top: 4,
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
                                borderRadius: BorderRadius.circular(
                                  FieldworkMetrics.chipRadius,
                                ),
                              ),
                              child: Text(
                                stateLabel,
                                maxLines: 1,
                                style: fieldworkText(
                                  context,
                                  10,
                                  weight: FontWeight.w700,
                                  height: 13,
                                  color: _badgeForeground(context),
                                ),
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
                // The 44 px hit area sits a few pixels proud of the tile so
                // the tile's own centre still opens it, while the visible ×
                // stays a small 20 px dot inside the corner.
                start: -6,
                top: -6,
                width: 44,
                height: 44,
                child: Semantics(
                  button: true,
                  excludeSemantics: true,
                  label: t(TechnicianKeys.technicianDeleteEvidence),
                  child: Tooltip(
                    message: t(TechnicianKeys.technicianDeleteEvidence),
                    excludeFromSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onDelete,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 10,
                            top: 10,
                          ),
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
              textDirection: TextDirection.ltr,
              style: fieldworkNumber(
                context,
                10,
                weight: FontWeight.w700,
                height: 13,
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

  /// Clock-style duration from the served milliseconds: numbers and one colon
  /// only, so no copy key is needed.
  String _formatDuration(int durationMs) {
    final totalSeconds = (durationMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
