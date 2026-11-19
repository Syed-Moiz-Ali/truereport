import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'dashboard_data.dart';
import 'dashboard_palette.dart';
import 'dashboard_primitives.dart';

/// The work queue. Rows, not cards: one field set, a count, one target.
class DashboardAttention extends StatelessWidget {
  const DashboardAttention({
    super.key,
    required this.entries,
    required this.strings,
    required this.onOpen,
    required this.onViewAll,
    required this.onOpenHealth,
  });

  final List<DashboardAttentionEntry> entries;
  final UiMessageStrings strings;
  final ValueChanged<String> onOpen;
  final VoidCallback onViewAll;
  final VoidCallback onOpenHealth;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return DashboardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 15, 10, 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings.tKey(
                      PlatformAdminKeys.dashboardNeedsAttentionTitle,
                    ),
                    style: DashboardType.sectionTitle(palette.ink),
                  ),
                ),
                if (entries.isNotEmpty)
                  _TextAction(
                    label: strings.tKey(PlatformAdminKeys.buttonViewAll),
                    onTap: onViewAll,
                    actionKey: const Key('btn-attention-view-all'),
                  ),
              ],
            ),
          ),
          if (entries.isEmpty)
            _QuietState(
              icon: Icons.check_circle_outline_rounded,
              message: strings.tKey(
                PlatformAdminKeys.dashboardNeedsAttentionEmpty,
              ),
              actionLabel: strings.tKey(PlatformAdminKeys.buttonHealthReview),
              onAction: onOpenHealth,
            )
          else
            for (final entry in entries)
              _AttentionRow(
                entry: entry,
                onTap: entry.route.isEmpty ? null : () => onOpen(entry.route),
              ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.entry, required this.onTap});

  final DashboardAttentionEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final tone = severityColor(entry.severity, palette);
    final soft = severitySoftColor(entry.severity, palette);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.hairline)),
      ),
      child: DashboardPressable(
        onTap: onTap,
        semanticLabel: dashboardActionSemantics(entry.title, entry.meta),
        borderRadius: 8,
        builder: (context, state) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            color: state.hovered ? palette.hover : Colors.transparent,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 13, 14, 13),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: tone.withValues(alpha: 0.18)),
                  ),
                  child: Icon(entry.icon, size: 17, color: tone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.title,
                        style: DashboardType.rowTitle(palette.ink),
                        maxLines: 2,
                      ),
                      if (entry.meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.meta,
                          style: DashboardType.meta(palette.muted),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
                if (entry.count != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    '${entry.count}',
                    style: DashboardType.numberSmall(palette.ink),
                  ),
                ],
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: palette.muted.withValues(alpha: 0.65),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuietState extends StatelessWidget {
  const _QuietState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.hairline)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: palette.goodSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: palette.good),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 6),
                  child: Text(
                    message,
                    style: DashboardType.body(palette.muted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TextAction(
            label: actionLabel,
            onTap: onAction,
            actionKey: const Key('btn-attention-review-health'),
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.onTap,
    required this.actionKey,
  });

  final String label;
  final VoidCallback onTap;
  final Key actionKey;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return DashboardPressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: 8,
      builder: (context, state) {
        return Container(
          key: actionKey,
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: state.hovered ? palette.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: DashboardType.meta(palette.accent)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 13,
                color: palette.accent,
              ),
            ],
          ),
        );
      },
    );
  }
}
