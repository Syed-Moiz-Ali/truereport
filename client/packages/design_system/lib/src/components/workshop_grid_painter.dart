import 'package:flutter/material.dart';

/// Hairline grid used as quiet texture on brand panels.
///
/// Extracted from the sign-in page so no screen carries a colour literal. The
/// caller passes a token (`ws.onAccent.withValues(alpha: 0.05)`), which keeps
/// this painter token-agnostic and testable.
@immutable
class WorkshopGridPainter extends CustomPainter {
  const WorkshopGridPainter({
    required this.color,
    this.step = 48,
    this.strokeWidth = 1,
  });

  final Color color;
  final double step;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WorkshopGridPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.step != step ||
      oldDelegate.strokeWidth != strokeWidth;
}
