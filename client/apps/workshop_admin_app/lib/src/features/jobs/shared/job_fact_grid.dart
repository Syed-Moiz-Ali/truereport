import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Wrapping grid of facts: 3 columns on desktop, 2 on tablet, [minColumns] on
/// phone (1 by default; the detail summary uses 2 to stay compact).
class JobFactGrid extends StatelessWidget {
  const JobFactGrid({required this.facts, this.minColumns = 1, super.key});

  final List<Widget> facts;
  final int minColumns;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) {
      return const SizedBox.shrink();
    }
    final gap = context.spacing.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 3
            : width >= 600
            ? 2
            : (minColumns < 1 ? 1 : (minColumns > 2 ? 2 : minColumns));
        final cell = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final fact in facts) SizedBox(width: cell, child: fact),
          ],
        );
      },
    );
  }
}
