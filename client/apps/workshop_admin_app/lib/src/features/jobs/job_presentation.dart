import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

export 'shared/job_fact.dart';
export 'shared/job_fact_grid.dart';
export 'shared/job_status_badge.dart';

/// Breakpoint at which a job list becomes a table instead of stacked rows.
/// Shared by any tabular job surface.
const double jobWideRowMinWidth = 820;

/// Small icon + text row; the text wraps instead of being clipped unless the
/// caller pins it (identifiers such as job references never wrap).
class JobMetaLine extends StatelessWidget {
  const JobMetaLine({
    required this.icon,
    required this.text,
    this.textDirection,
    this.maxLines = 2,
    this.softWrap = true,
    super.key,
  });

  final IconData icon;
  final String text;
  final TextDirection? textDirection;
  final int maxLines;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(top: spacing.xxs),
          child: Icon(icon, size: 14, color: ws.muted),
        ),
        SizedBox(width: spacing.xs),
        Flexible(
          child: Text(
            text,
            textDirection: textDirection,
            maxLines: maxLines,
            softWrap: softWrap,
            style: ws.meta.copyWith(color: ws.muted),
          ),
        ),
      ],
    );
  }
}
