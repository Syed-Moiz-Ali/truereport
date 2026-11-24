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

/// The customer's signature, captured on the device.
///
/// The pad takes the screen: it is the only thing that needs care here. The
/// signer name sits above it, undo/clear sit on the pad itself, and one pinned
/// action saves the signature onto the report.
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

  bool get _ready => _strokes.isNotEmpty && _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _startStroke(Offset point) {
    setState(() {
      _current = [point];
      _strokes.add(_current!);
      _error = null;
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
    picture.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _submit() async {
    final t = UiStrings.of(context);
    if (!_ready) {
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
    final reference =
        ref
            .watch(technicianJobSummaryProvider(widget.jobId))
            .asData
            ?.value
            .reference ??
        '';
    final language = Localizations.localeOf(context).languageCode;
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: Column(
        children: [
          _ScreenBar(reference: reference.trim()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const Key('signature-name'),
                        controller: _name,
                        label: t(TechnicianKeys.technicianSignerName),
                        labelAbove: true,
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      const SizedBox(height: 14),
                      _Pad(
                        padKey: _padKey,
                        strokes: _strokes,
                        prompt: t(TechnicianKeys.technicianSignatureHint),
                        showPrompt: _strokes.isEmpty,
                        invalid: _error != null,
                        onStart: _startStroke,
                        onUpdate: _extendStroke,
                        onEnd: _endStroke,
                        onUndo: _submitting || _strokes.isEmpty ? null : _undo,
                        onClear: _submitting || _strokes.isEmpty
                            ? null
                            : _clear,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: context.texts.bodySmall?.copyWith(
                              color: context.colors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (_ready) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: context.statusColors.success.foreground,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${t(TechnicianKeys.technicianSignatureCaptured)} · '
                                '${_name.text.trim()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.texts.labelSmall?.copyWith(
                                  color:
                                      context.statusColors.success.foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (language.isEmpty) const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _Footer(
            hint: _ready
                ? _name.text.trim()
                : t(TechnicianKeys.technicianSignatureRequired),
            ready: _ready,
            submitting: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _ScreenBar extends StatelessWidget {
  const _ScreenBar({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 16, 8),
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
                    child: Icon(Icons.arrow_back_rounded, size: 21),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  t(TechnicianKeys.technicianSignatureTitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (reference.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: context.texts.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

/// The signing sheet: a rule to sign above, undo/clear on its own corner.
class _Pad extends StatelessWidget {
  const _Pad({
    required this.padKey,
    required this.strokes,
    required this.prompt,
    required this.showPrompt,
    required this.invalid,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onUndo,
    required this.onClear,
  });

  final GlobalKey padKey;
  final List<List<Offset>> strokes;
  final String prompt;
  final bool showPrompt;
  final bool invalid;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: invalid ? colors.error : colors.outlineVariant,
          width: invalid ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 46),
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                // A signing sheet, not a letterbox: cap the height so the rule
                // and the strokes stay together on a wide window.
                height: (constraints.maxWidth / 2.1).clamp(160.0, 230.0),
                child: GestureDetector(
                  key: padKey,
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) => onStart(details.localPosition),
                  onPanUpdate: (details) => onUpdate(details.localPosition),
                  onPanEnd: (_) => onEnd(),
                  onPanCancel: onEnd,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 26,
                        child: Container(
                          height: 1.2,
                          color: colors.outlineVariant,
                        ),
                      ),
                      if (showPrompt)
                        Positioned(
                          left: 24,
                          bottom: 34,
                          child: Text(
                            prompt,
                            style: context.texts.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SignaturePainter(
                            strokes: strokes,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 10,
            end: 10,
            child: Row(
              children: [
                _Tool(
                  buttonKey: const Key('signature-undo'),
                  icon: Icons.undo_rounded,
                  label: t(TechnicianKeys.technicianUndo),
                  onTap: onUndo,
                ),
                const SizedBox(width: 8),
                _Tool(
                  buttonKey: const Key('signature-clear'),
                  icon: Icons.layers_clear_outlined,
                  label: t(TechnicianKeys.technicianClearSignature),
                  onTap: onClear,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        key: buttonKey,
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: enabled ? colors.onSurface : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: context.texts.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.hint,
    required this.ready,
    required this.submitting,
    required this.onPressed,
  });

  final String hint;
  final bool ready;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t(TechnicianKeys.technicianSignature).toUpperCase(),
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PrimaryAction(
                label: t(TechnicianKeys.technicianSaveSignature),
                saving: submitting,
                enabled: ready && !submitting,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.saving,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool saving;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        key: const Key('signature-submit'),
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: 48,
          child: Material(
            color: enabled
                ? context.brand.ink
                : context.brand.ink.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (saving)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.labelLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    if (!saving) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
