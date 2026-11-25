import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../jobs_queue_style.dart';

/// Deck-shaped loading skeleton: header lines, tab pill, front card and the
/// pinned primary. Honours reduced motion by holding still.
class DeckSkeleton extends StatefulWidget {
  const DeckSkeleton({super.key});

  @override
  State<DeckSkeleton> createState() => _DeckSkeletonState();
}

class _DeckSkeletonState extends State<DeckSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.45 + (_controller.value * 0.35);
        final color = base.withValues(alpha: alpha);
        Widget block(double? width, double height, [double radius = 8]) =>
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(radius),
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                block(44, 44, 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(120, 12),
                      const SizedBox(height: 8),
                      block(double.infinity, 30, 8),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                block(44, 44, 22),
              ],
            ),
            const SizedBox(height: 16),
            block(double.infinity, 56, 999),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsetsDirectional.all(20),
              decoration: BoxDecoration(
                color: context.colors.surfaceLowest,
                borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(140, 28, 999),
                  const SizedBox(height: 12),
                  block(double.infinity, 34, 8),
                  const SizedBox(height: 8),
                  block(200, 16, 8),
                  const SizedBox(height: 12),
                  block(double.infinity, 84, 16),
                  const SizedBox(height: 16),
                  block(double.infinity, 6, 999),
                ],
              ),
            ),
            const SizedBox(height: 24),
            block(double.infinity, QueueMetrics.buttonHeight, 14),
          ],
        );
      },
    );
  }
}
