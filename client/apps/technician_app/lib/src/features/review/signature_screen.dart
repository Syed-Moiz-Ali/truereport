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

import '../../reference_ui.dart';
import '../jobs/queue/jobs_queue_format.dart';
import '../jobs/queue/queue_model.dart';
import 'fieldwork/review_ui.dart';
import 'fieldwork/signature_ui.dart';
import 'signature/signature_pad.dart';

/// The customer's signature, captured on the device.
///
/// One white sheet in the deck language: the signer name sits above it, the
/// pad is the hero, undo/clear ride inside the pad, and one pinned primary
/// saves the signature onto the report. The submit call, payload, validation
/// and navigation are unchanged from the previous screen — only the
/// presentation is this file's own.
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
  final _nameFocus = FocusNode();
  final List<List<Offset>> _strokes = [];
  List<Offset>? _current;
  int _paintVersion = 0;
  String? _error;
  bool _submitting = false;

  /// Shows the name message after the first blur or submit attempt, then
  /// stays live while the technician types.
  bool _nameBlurred = false;
  bool _submitAttempted = false;

  bool get _nameValid => _name.text.trim().isNotEmpty;

  bool get _ready => _strokes.isNotEmpty && _nameValid;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(_handleNameFocus);
  }

  @override
  void dispose() {
    _nameFocus
      ..removeListener(_handleNameFocus)
      ..dispose();
    _name.dispose();
    super.dispose();
  }

  void _handleNameFocus() {
    if (!_nameFocus.hasFocus && mounted) {
      setState(() => _nameBlurred = true);
    }
  }

  String? _nameError(UiStrings t) {
    if (_nameValid || (!_nameBlurred && !_submitAttempted)) {
      return null;
    }
    return t(TechnicianKeys.technicianSignerNameRequired);
  }

  void _startStroke(Offset point) {
    // Pan start follows tap down on a real drag: one stroke per touch.
    if (_current != null) {
      return;
    }
    // First touch on the sheet puts the keyboard away: the hand is signing.
    _nameFocus.unfocus();
    setState(() {
      _nameBlurred = true;
      _current = [point];
      _strokes.add(_current!);
      _paintVersion++;
      _error = null;
    });
  }

  void _extendStroke(Offset point) {
    final stroke = _current;
    if (stroke == null) {
      return;
    }
    setState(() {
      stroke.add(point);
      _paintVersion++;
    });
  }

  void _endStroke() {
    setState(() => _current = null);
  }

  void _undo() {
    if (_strokes.isEmpty) {
      return;
    }
    setState(() {
      _strokes.removeLast();
      _paintVersion++;
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _current = null;
      _paintVersion++;
      _error = null;
    });
  }

  /// The saved image: white sheet, ink strokes, at the pad's own resolution.
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
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in _strokes) {
      if (stroke.length < 2) {
        if (stroke.length == 1) {
          canvas.drawCircle(stroke.first, 2, paint);
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
    picture.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _submit() async {
    final t = UiStrings.of(context);
    if (!_ready) {
      // The name is the field the technician can fix with the keyboard; put
      // the caret there instead of only showing the message.
      if (!_nameValid) {
        _nameFocus.requestFocus();
      }
      setState(() {
        _submitAttempted = true;
        _error = t(TechnicianKeys.technicianSignatureRequired);
      });
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
    final job = ref
        .watch(technicianJobSummaryProvider(widget.jobId))
        .asData
        ?.value;
    final readOnly = job == null || verbFor(job) == QueueVerb.view;
    final status = (job?.status ?? '').trim();
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: SignatureView(
        header: ReviewJobHeader(
          vehicle: job == null ? '' : queueVehicleLabel(job),
          plate: (job?.vehiclePlate ?? '').trim(),
          reference: (job?.reference ?? '').trim(),
          statusLabel: status.isEmpty ? null : jobStatusLabel(ref, status),
          statusTone: status.isEmpty
              ? StatusTone.neutral
              : jobStatusTone(ref, status),
        ),
        onBack: _pop,
        readOnly: readOnly,
        primaryLabel: readOnly
            ? t(TechnicianKeys.commonBack)
            : t(TechnicianKeys.technicianSaveSignature),
        onPrimary: readOnly
            ? _pop
            : _ready && !_submitting
            ? _submit
            : null,
        saving: _submitting && !readOnly,
        secondaryLabel: readOnly
            ? null
            : t(TechnicianKeys.technicianBackToSummary),
        onSecondary: readOnly ? null : _pop,
        body: readOnly
            ? SignatureReadOnlyCard(
                reason: t(TechnicianKeys.technicianSignatureReadOnly),
              )
            : SignatureSigningCard(
                title: t(TechnicianKeys.technicianSignatureTitle),
                hint: t(TechnicianKeys.technicianSignatureHint),
                nameController: _name,
                nameFocus: _nameFocus,
                nameLabel: t(TechnicianKeys.technicianSignerName),
                nameHint: t(TechnicianKeys.fullNameHint),
                nameHelper: t(TechnicianKeys.technicianSignerNameRequired),
                nameError: _nameError(t),
                onNameChanged: (_) => setState(() => _error = null),
                onNameSubmitted: (_) => FocusScope.of(context).unfocus(),
                pad: SignaturePad(
                  padKey: _padKey,
                  strokes: _strokes,
                  version: _paintVersion,
                  showPrompt: _strokes.isEmpty,
                  onStart: _startStroke,
                  onUpdate: _extendStroke,
                  onEnd: _endStroke,
                  onUndo: _submitting || _strokes.isEmpty ? null : _undo,
                  onClear: _submitting || _strokes.isEmpty ? null : _clear,
                ),
                signedName: _ready ? _name.text.trim() : null,
                signedLabel: t(TechnicianKeys.technicianSignatureCaptured),
                error: _error,
                retryLabel: t(TechnicianKeys.retryAction),
                onRetry: _submitting ? null : _submit,
              ),
      ),
    );
  }

  void _pop() => Navigator.of(context).maybePop();
}
