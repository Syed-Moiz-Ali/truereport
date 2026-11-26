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

import '../inspection/assessment/item_footer.dart';
import '../jobs/queue/jobs_queue_primitives.dart';
import '../jobs/queue/jobs_queue_style.dart';
import '../jobs/queue/queue_model.dart';
import 'signature/signature_header.dart';
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
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 28),
              child: _Capped(
                child: readOnly
                    ? _ReadOnlyBody(job: job, onBack: _pop)
                    : _SigningBody(
                        job: job,
                        name: _name,
                        nameFocus: _nameFocus,
                        nameError: _nameError(t),
                        padKey: _padKey,
                        strokes: _strokes,
                        version: _paintVersion,
                        ready: _ready,
                        error: _error,
                        onNameChanged: (_) => setState(() => _error = null),
                        onNameSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
                        onStartStroke: _startStroke,
                        onExtendStroke: _extendStroke,
                        onEndStroke: _endStroke,
                        onUndo: _submitting || _strokes.isEmpty ? null : _undo,
                        onClear: _submitting || _strokes.isEmpty
                            ? null
                            : _clear,
                        onRetry: _submitting ? null : _submit,
                        onBack: _pop,
                      ),
              ),
            ),
          ),
          ItemFooter(
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
          ),
        ],
      ),
    );
  }

  void _pop() => Navigator.of(context).maybePop();
}

/// The editable sheet: header, one white signing card, states below the pad.
class _SigningBody extends StatelessWidget {
  const _SigningBody({
    required this.job,
    required this.name,
    required this.nameFocus,
    required this.nameError,
    required this.padKey,
    required this.strokes,
    required this.version,
    required this.ready,
    required this.error,
    required this.onNameChanged,
    required this.onNameSubmitted,
    required this.onStartStroke,
    required this.onExtendStroke,
    required this.onEndStroke,
    required this.onUndo,
    required this.onClear,
    required this.onRetry,
    required this.onBack,
  });

  final JobSummary? job;
  final TextEditingController name;
  final FocusNode nameFocus;
  final String? nameError;
  final GlobalKey padKey;
  final List<List<Offset>> strokes;
  final int version;
  final bool ready;
  final String? error;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onNameSubmitted;
  final ValueChanged<Offset> onStartStroke;
  final ValueChanged<Offset> onExtendStroke;
  final VoidCallback onEndStroke;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;
  final VoidCallback? onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SignatureHeader(job: job, onBack: onBack),
        const SizedBox(height: 12),
        queueReveal(
          context: context,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(20),
            decoration: BoxDecoration(
              color: context.colors.surfaceLowest,
              borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SignatureCardTitle(),
                const SizedBox(height: 12),
                AppTextField(
                  key: const Key('signature-name'),
                  controller: name,
                  focusNode: nameFocus,
                  label: t(TechnicianKeys.technicianSignerName),
                  labelAbove: true,
                  errorText: nameError,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.done,
                  maxLength: 80,
                  // The name is spoken, not autocompleted: no autofill hints.
                  onChanged: onNameChanged,
                  onFieldSubmitted: onNameSubmitted,
                ),
                const SizedBox(height: 16),
                SignaturePad(
                  padKey: padKey,
                  strokes: strokes,
                  version: version,
                  showPrompt: strokes.isEmpty,
                  onStart: onStartStroke,
                  onUpdate: onExtendStroke,
                  onEnd: onEndStroke,
                  onUndo: onUndo,
                  onClear: onClear,
                ),
                if (ready) ...[
                  const SizedBox(height: 12),
                  _SignedRow(name: name.text.trim()),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: QueueNote(
                      icon: Icons.error_outline_rounded,
                      label: error!,
                      tone: StatusTone.danger,
                    ),
                  ),
                  const SizedBox(height: 8),
                  QueueButton(
                    label: t(TechnicianKeys.retryAction),
                    variant: QueueButtonVariant.soft,
                    icon: Icons.refresh_rounded,
                    expand: true,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// View-only jobs: the reason, nothing to sign, one way back.
class _ReadOnlyBody extends StatelessWidget {
  const _ReadOnlyBody({required this.job, required this.onBack});

  final JobSummary? job;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (job != null) ...[
          SignatureHeader(job: job, onBack: onBack),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceLowest,
            borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.statusColors.warning.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.visibility_outlined,
                  size: 22,
                  color: context.statusColors.warning.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t(TechnicianKeys.technicianSignatureReadOnly),
                  style: queueBody(context, color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The signed state: who signed, with the check.
class _SignedRow extends StatelessWidget {
  const _SignedRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final pair = context.statusColors.success;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: pair.background,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 16, color: pair.foreground),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$name · ${t(TechnicianKeys.technicianSignatureCaptured)}',
            maxLines: 2,
            style: queueText(
              context,
              13,
              weight: FontWeight.w600,
              height: 18,
              color: pair.foreground,
            ),
          ),
        ),
      ],
    );
  }
}

class _Capped extends StatelessWidget {
  const _Capped({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );
  }
}
