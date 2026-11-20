import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
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
    final t = UiStrings.of(context);
    if (_strokes.isEmpty || _name.text.trim().isEmpty) {
      setState(() => _error = t(TechnicianKeys.technicianSignatureRequired));
      return;
    }
    final bytes = await _exportPng();
    if (bytes == null) {
      setState(() => _error = t(TechnicianKeys.technicianSignatureRequired));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final deviceId = await DeviceIdentity.deviceId();
      await ref
          .read(technicianApiProvider)
          .submitSignature(
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
      showAppSnackBar(
        context,
        message: t(TechnicianKeys.technicianSignatureSuccess),
      );
      Navigator.of(context).pop();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = t(TechnicianKeys.commonActionFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: Column(
        children: [
          _SignatureBar(title: t(TechnicianKeys.technicianSignatureTitle)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t(TechnicianKeys.technicianSignatureHint),
                        style: context.texts.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        key: const Key('signature-name'),
                        controller: _name,
                        label: t(TechnicianKeys.technicianSignerName),
                        labelAbove: true,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        key: _padKey,
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _error == null
                                ? context.colors.outlineVariant
                                : context.colors.error,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: 2.1,
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
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: context.texts.bodySmall?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppButton(
                            key: const Key('signature-clear'),
                            label: t(TechnicianKeys.technicianClearSignature),
                            icon: Icons.clear,
                            variant: AppButtonVariant.tonal,
                            onPressed: _submitting ? null : _clear,
                          ),
                          AppButton(
                            key: const Key('signature-undo'),
                            label: t(TechnicianKeys.technicianUndo),
                            icon: Icons.undo,
                            variant: AppButtonVariant.tonal,
                            onPressed: _submitting ? null : _undo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(
                top: BorderSide(color: context.colors.outlineVariant),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AppButton(
                  key: const Key('signature-submit'),
                  label: t(TechnicianKeys.technicianSignature),
                  icon: Icons.check,
                  large: true,
                  expand: true,
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureBar extends StatelessWidget {
  const _SignatureBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 16, 6),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
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
