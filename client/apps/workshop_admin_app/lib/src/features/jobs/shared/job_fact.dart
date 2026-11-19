import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Compact label-above-value fact used across the job surfaces.
class JobFact extends StatelessWidget {
  const JobFact({
    required this.label,
    required this.value,
    this.valueDirection,
    super.key,
  });

  final String label;
  final String value;
  final TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(label, style: ws.meta.copyWith(color: ws.muted)),
        ),
        SizedBox(height: context.spacing.xxs),
        Text(
          value,
          textDirection: valueDirection,
          style: ws.body.copyWith(color: ws.ink),
        ),
      ],
    );
  }
}
