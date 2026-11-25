import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import '../../jobs/queue/jobs_queue_style.dart';

/// One blocker row: icon, one-line title, short body and the one action.
///
/// The action is the whole row; read-only rows render without it.
class BlockerRow extends StatelessWidget {
  const BlockerRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.tone,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final StatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(tone);
    final tappable = onTap != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: tappable,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: pair.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: pair.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: queueText(
                        context,
                        15,
                        weight: FontWeight.w600,
                        height: 22,
                        tracking: -0.1,
                      ),
                    ),
                    if (body != null && body!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body!.trim(),
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: queueText(
                          context,
                          12.5,
                          height: 18,
                          tabular: true,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (tappable) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8),
                  child: Icon(
                    rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The blockers card: grouped rows with a count, hairline dividers.
///
/// `quiet` renders the same shape in a tonal surface with muted type for
/// warnings, which must never read as blockers.
class BlockerCard extends StatelessWidget {
  const BlockerCard({
    required this.title,
    required this.count,
    required this.tone,
    required this.rows,
    this.quiet = false,
    super.key,
  });

  final String title;
  final int count;
  final StatusTone tone;
  final List<Widget> rows;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pair = context.statusColors.forTone(tone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: quiet ? colors.surfaceContainer : colors.surfaceLowest,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: queueText(
                    context,
                    11.5,
                    weight: FontWeight.w700,
                    height: 14,
                    tracking: 0.9,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: pair.background,
                  borderRadius: BorderRadius.circular(QueueMetrics.radiusChip),
                ),
                child: Text(
                  '$count',
                  textDirection: TextDirection.ltr,
                  style: queueText(
                    context,
                    12,
                    weight: FontWeight.w700,
                    height: 16,
                    tabular: true,
                    color: pair.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.outlineVariant),
            rows[index],
          ],
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
              child: Text(
                UiStrings.of(context)(TechnicianKeys.technicianAllCaughtUp),
                style: queueText(
                  context,
                  13,
                  height: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
