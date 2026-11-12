import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:uuid/uuid.dart';

class TechnicianSignaturePage extends ConsumerStatefulWidget {
  const TechnicianSignaturePage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<TechnicianSignaturePage> createState() =>
      _TechnicianSignaturePageState();
}

class _TechnicianSignaturePageState
    extends ConsumerState<TechnicianSignaturePage> {
  final _padKey = GlobalKey();
  final _name = TextEditingController();
  final List<List<Offset>> _strokes = [];
  List<Offset>? _current;
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _startStroke(Offset point) {
    setState(() {
      _current = [point];
      _strokes.add(_current!);
    });
  }

  void _extendStroke(Offset point) {
    final stroke = _current;
    if (stroke == null) {
      return;
    }
    setState(() => stroke.add(point));
  }

  void _endStroke() {
    setState(() => _current = null);
  }

  void _undo() {
    if (_strokes.isEmpty) {
      return;
    }
    setState(_strokes.removeLast);
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _current = null;
      _error = null;
    });
  }

  Future<Uint8List?> _exportPng() async {
    final box = _padKey.currentContext?.findRenderObject();
    if (box is! RenderBox) {
      return null;
    }
    final size = box.size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final paint = Paint()
      ..color = const Color(0xFF1A1B1F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in _strokes) {
      if (stroke.length < 2) {
        if (stroke.length == 1) {
          canvas.drawCircle(stroke.first, 1.6, paint);
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.round().clamp(1, 4096),
      size.height.round().clamp(1, 4096),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_strokes.isEmpty || _name.text.trim().isEmpty) {
      setState(() => _error = l10n.technicianSignatureRequired);
      return;
    }
    final bytes = await _exportPng();
    if (bytes == null) {
      setState(() => _error = l10n.technicianSignatureRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final deviceId = await DeviceIdentity.deviceId();
      await ref.read(technicianApiProvider).submitSignature(
            widget.jobId,
            SignatureRequest(
              signerName: _name.text.trim(),
              deviceId: deviceId,
              method: 'DRAWN',
              mime: 'image/png',
              signatureBase64: base64Encode(bytes),
            ),
            idempotencyKey: const Uuid().v7(),
          );
      ref.invalidate(technicianSummaryProvider(widget.jobId));
      ref.invalidate(technicianReviewProvider(widget.jobId));
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: l10n.technicianSignatureSuccess);
      Navigator.of(context).pop();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = l10n.commonActionFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      backgroundColor: context.colors.surface,
      appBar: TechnicianAppBar(
        title: l10n.technicianSignatureTitle,
        showBack: true,
      ),
      body: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: EdgeInsetsDirectional.all(context.spacing.gutter),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TechnicianSectionTitle(
                      title: l10n.technicianSignatureTitle,
                      subtitle: l10n.technicianSignatureHint,
                    ),
                    SizedBox(height: context.spacing.md),
                    AppTextField(
                      key: const Key('signature-name'),
                      controller: _name,
                      label: l10n.technicianSignerName,
                      labelAbove: true,
                    ),
                    SizedBox(height: context.spacing.md),
                    Container(
                      key: _padKey,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(context.radii.lg),
                        border: Border.all(color: context.colors.outlineVariant),
                      ),
                      child: AspectRatio(
                        aspectRatio: 2.4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) =>
                              _startStroke(details.localPosition),
                          onPanUpdate: (details) =>
                              _extendStroke(details.localPosition),
                          onPanEnd: (_) => _endStroke(),
                          onPanCancel: _endStroke,
                          child: CustomPaint(
                            painter: _SignaturePainter(
                              strokes: _strokes,
                              color: context.colors.onSurface,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: context.spacing.xs),
                      Text(
                        _error!,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                    ],
                    SizedBox(height: context.spacing.sm),
                    Wrap(
                      spacing: context.spacing.sm,
                      runSpacing: context.spacing.sm,
                      children: [
                        AppButton(
                          key: const Key('signature-clear'),
                          label: l10n.technicianClearSignature,
                          icon: Icons.clear,
                          variant: AppButtonVariant.tonal,
                          onPressed: _submitting ? null : _clear,
                        ),
                        AppButton(
                          key: const Key('signature-undo'),
                          label: l10n.technicianUndo,
                          icon: Icons.undo,
                          variant: AppButtonVariant.tonal,
                          onPressed: _submitting ? null : _undo,
                        ),
                      ],
                    ),
                    SizedBox(height: context.spacing.lg),
                    AppButton(
                      key: const Key('signature-submit'),
                      label: l10n.technicianSignature,
                      icon: Icons.check,
                      large: true,
                      expand: true,
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.length == 1) {
          canvas.drawCircle(stroke.first, 1.6, paint);
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.color != color;
}
