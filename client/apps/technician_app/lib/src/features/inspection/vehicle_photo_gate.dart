import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_validation.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/technician_providers.dart';

/// Full-surface cover-photo prompt, and the small affordances used once a
/// photo already exists.
class VehiclePhotoGate extends ConsumerStatefulWidget {
  const VehiclePhotoGate({
    required this.jobId,
    required this.onDone,
    this.onContinueWithoutPhoto,
    super.key,
  });

  final String jobId;
  final VoidCallback onDone;

  /// Shown only after an upload failure; null hides the escape hatch.
  final VoidCallback? onContinueWithoutPhoto;

  @override
  ConsumerState<VehiclePhotoGate> createState() => _VehiclePhotoGateState();
}

class _VehiclePhotoGateState extends ConsumerState<VehiclePhotoGate> {
  bool _busy = false;
  double? _progress;
  String? _error;
  CapturedEvidence? _pending;

  Future<void> _pick(EvidenceSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _progress = null;
    });
    try {
      final captured = await ref
          .read(evidenceCaptureServiceProvider)
          .captureVehiclePhoto(source: source);
      if (!mounted) return;
      if (captured == null) {
        setState(() => _busy = false);
        return;
      }
      _pending = captured;
      await _upload(captured);
    } on EvidenceCaptureException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _captureError(UiStrings.of(context), error.failure);
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = UiStrings.of(context)(TechnicianKeys.vehiclePhotoFailed);
        });
      }
    }
  }

  String _captureError(UiStrings t, EvidenceValidationFailure failure) {
    return switch (failure) {
      EvidenceValidationFailure.unsupportedPhotoType => t(
        TechnicianKeys.vehiclePhotoUnsupportedType,
      ),
      EvidenceValidationFailure.resolutionTooLow => t(
        TechnicianKeys.vehiclePhotoTooSmall,
      ),
      EvidenceValidationFailure.tooLarge => t(
        TechnicianKeys.vehiclePhotoTooLarge,
      ),
      _ => t(TechnicianKeys.vehiclePhotoFailed),
    };
  }

  Future<void> _upload(CapturedEvidence captured) async {
    if (!mounted) return;
    final api = ref.read(technicianApiProvider);
    final request = VehiclePhotoInitRequest(
      mime: captured.mime,
      bytes: captured.bytes.length,
      sha256: sha256Hex(captured.bytes),
      capturedAt: captured.capturedAt,
      captureSource: captured.captureSource,
    );
    try {
      final photo = await api.initVehiclePhoto(widget.jobId, request);
      await api.uploadVehiclePhotoContent(
        widget.jobId,
        photo.id,
        captured.bytes,
        contentType: captured.mime,
        onSendProgress: (sent, total) {
          if (!mounted) return;
          setState(() {
            _progress = total > 0 ? sent / total : null;
          });
        },
      );
      await api.completeVehiclePhoto(widget.jobId, photo.id);
      if (!mounted) return;
      ref.invalidate(vehiclePhotoProvider(widget.jobId));
      ref.invalidate(vehiclePhotoContentProvider(widget.jobId));
      setState(() {
        _busy = false;
        _progress = null;
        _error = null;
        _pending = null;
      });
      widget.onDone();
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _error = UiStrings.of(context)(TechnicianKeys.vehiclePhotoFailed);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    return SingleChildScrollView(
      key: const Key('vehicle-photo-gate'),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_camera_front_outlined,
                size: 56,
                color: colors.onSurfaceVariant,
              ),
              SizedBox(height: spacing.md),
              Text(
                t(TechnicianKeys.vehiclePhotoTitle),
                textAlign: TextAlign.center,
                style: context.texts.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: spacing.sm),
              Text(
                t(TechnicianKeys.vehiclePhotoBody),
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.xl),
              AppButton(
                key: const Key('vehicle-photo-camera'),
                label: t(TechnicianKeys.technicianCapturePhoto),
                icon: Icons.photo_camera_outlined,
                variant: AppButtonVariant.tonal,
                expand: true,
                onPressed: _busy ? null : () => _pick(EvidenceSource.camera),
              ),
              SizedBox(height: spacing.sm),
              AppButton(
                key: const Key('vehicle-photo-gallery'),
                label: t(TechnicianKeys.photoSourceGallery),
                icon: Icons.photo_library_outlined,
                variant: AppButtonVariant.tonal,
                expand: true,
                onPressed: _busy ? null : () => _pick(EvidenceSource.file),
              ),
              if (_busy) ...[
                SizedBox(height: spacing.lg),
                LinearProgressIndicator(value: _progress),
                SizedBox(height: spacing.xs),
                Text(
                  t(TechnicianKeys.vehiclePhotoUploading),
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (_error != null) ...[
                SizedBox(height: spacing.lg),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium?.copyWith(
                    color: colors.error,
                  ),
                ),
                SizedBox(height: spacing.sm),
                if (_pending != null)
                  AppButton(
                    key: const Key('vehicle-photo-retry'),
                    label: t(TechnicianKeys.technicianRetryUpload),
                    icon: Icons.refresh,
                    variant: AppButtonVariant.tonal,
                    expand: true,
                    onPressed: _busy ? null : () => _upload(_pending!),
                  ),
                if (widget.onContinueWithoutPhoto != null)
                  TextButton(
                    key: const Key('vehicle-photo-continue'),
                    onPressed: _busy ? null : widget.onContinueWithoutPhoto,
                    child: Text(t(TechnicianKeys.vehiclePhotoContinueWithout)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class VehiclePhotoBanner extends StatelessWidget {
  const VehiclePhotoBanner({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    return Container(
      key: const Key('vehicle-photo-banner'),
      padding: EdgeInsetsDirectional.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  t(TechnicianKeys.vehiclePhotoBanner),
                  style: context.texts.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const Key('vehicle-photo-banner-add'),
              onPressed: onAdd,
              child: Text(t(TechnicianKeys.vehiclePhotoAdd)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small header thumbnail with a Retake tap target (44 px).
class VehiclePhotoThumb extends ConsumerWidget {
  const VehiclePhotoThumb({
    required this.jobId,
    required this.onRetake,
    super.key,
  });

  final String jobId;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final bytes = ref.watch(vehiclePhotoContentProvider(jobId)).asData?.value;
    final colors = context.colors;
    return Semantics(
      button: true,
      label: t(TechnicianKeys.vehiclePhotoRetake),
      child: Tooltip(
        message: t(TechnicianKeys.vehiclePhotoRetake),
        child: InkWell(
          key: const Key('vehicle-photo-retake'),
          onTap: onRetake,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: bytes == null
                        ? ColoredBox(
                            color: colors.surfaceContainerHighest,
                            child: Icon(
                              Icons.photo_camera_front_outlined,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                          )
                        : Image.memory(
                            Uint8List.fromList(bytes),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Icon(
                      Icons.refresh,
                      size: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
