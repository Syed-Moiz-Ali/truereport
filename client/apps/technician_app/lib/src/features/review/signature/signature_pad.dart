import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../inspection/fieldwork/fieldwork_ui.dart';

/// The signing sheet: a white sheet inside the signing card, a tonal baseline
/// guide, a "Sign here" prompt that leaves on the first stroke, and Undo/Clear
/// riding inside the pad at 44 px targets.
///
/// Strokes are raw pad offsets, so RTL mirroring moves only the tools — the
/// ink itself is never transformed.
class SignaturePad extends StatelessWidget {
  const SignaturePad({
    required this.padKey,
    required this.strokes,
    required this.version,
    required this.showPrompt,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onUndo,
    required this.onClear,
    super.key,
  });

  final GlobalKey padKey;
  final List<List<Offset>> strokes;

  /// Bumps on every mutation: the stroke lists grow in place, so identity
  /// and length checks can never see the growth.
  final int version;
  final bool showPrompt;
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
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(FieldworkMetrics.cardRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GestureDetector(
            key: padKey,
            behavior: HitTestBehavior.opaque,
            // A dot is a mark too: taps register without needing a move.
            onTapDown: (details) => onStart(details.localPosition),
            onTapUp: (_) => onEnd(),
            onTapCancel: onEnd,
            onPanStart: (details) => onStart(details.localPosition),
            onPanUpdate: (details) => onUpdate(details.localPosition),
            onPanEnd: (_) => onEnd(),
            onPanCancel: onEnd,
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                width: double.infinity,
                // A signing sheet, not a letterbox: the rule and the ink stay
                // together from a phone to a wide window.
                height: (constraints.maxWidth / 1.8).clamp(200.0, 300.0),
                child: Stack(
                  children: [
                    PositionedDirectional(
                      start: 24,
                      end: 24,
                      bottom: 30,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: context.brand.ink.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (showPrompt)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.draw_outlined,
                              size: 22,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(TechnicianKeys.technicianSignHere),
                              style: fieldworkText(
                                context,
                                13.5,
                                weight: FontWeight.w600,
                                height: 18,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: SignaturePadPainter(
                            strokes: strokes,
                            version: version,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 10,
            end: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PadTool(
                  buttonKey: const Key('signature-undo'),
                  icon: Icons.undo_rounded,
                  label: t(TechnicianKeys.technicianUndo),
                  onTap: onUndo,
                ),
                const SizedBox(width: 6),
                _PadTool(
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

/// A 44 px pill tool living on the pad. Icon-only would save room, but the
/// word keeps Undo/Clear unmistakable at a glance.
class _PadTool extends StatelessWidget {
  const _PadTool({
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
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: colors.surfaceLowest.withValues(alpha: enabled ? 0.94 : 0.6),
            borderRadius: BorderRadius.circular(FieldworkMetrics.chipRadius),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: enabled ? colors.onSurface : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: fieldworkText(
                  context,
                  12,
                  weight: FontWeight.w700,
                  height: 16,
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

@visibleForTesting
class SignaturePadPainter extends CustomPainter {
  const SignaturePadPainter({
    required this.strokes,
    required this.version,
    required this.color,
  });

  final List<List<Offset>> strokes;
  final int version;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
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
  }

  @override
  bool shouldRepaint(covariant SignaturePadPainter oldDelegate) {
    // Strokes grow in place, so identity and length checks always tie: the
    // version counter is the only honest signal.
    return oldDelegate.version != version || oldDelegate.color != color;
  }
}
