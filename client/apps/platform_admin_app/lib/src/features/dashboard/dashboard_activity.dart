import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'dashboard_data.dart';
import 'dashboard_palette.dart';
import 'dashboard_primitives.dart';

/// A single attributed feed. Time on the start rail, action, then who/what.
class DashboardActivity extends StatelessWidget {
  const DashboardActivity({
    super.key,
    required this.entries,
    required this.strings,
    required this.onOpenAudit,
  });

  final List<DashboardActivityEntry> entries;
  final UiMessageStrings strings;
  final VoidCallback onOpenAudit;

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
                      PlatformAdminKeys.sectionDashboardRecentActivity,
                    ),
                    style: DashboardType.sectionTitle(palette.ink),
                  ),
                ),
                _AuditAction(
                  label: strings.tKey(PlatformAdminKeys.pageAuditTitle),
                  onTap: onOpenAudit,
                ),
              ],
            ),
          ),
          if (entries.isEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: palette.hairline)),
              ),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 18),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: palette.canvas,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 17,
                      color: palette.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.tKey(PlatformAdminKeys.emptyActivityTitle),
                      style: DashboardType.body(palette.muted),
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < entries.length; i++)
              _ActivityRow(
                entry: entries[i],
                first: i == 0,
                last: i == entries.length - 1,
              ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.entry,
    required this.first,
    required this.last,
  });

  final DashboardActivityEntry entry;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.hairline)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 1,
                      color: first ? Colors.transparent : palette.border,
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: first ? palette.accent : palette.borderStrong,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 1,
                      color: last ? Colors.transparent : palette.border,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.title,
                      style: DashboardType.rowTitle(palette.ink),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.when,
                      style: DashboardType.meta(palette.muted)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditAction extends StatelessWidget {
  const _AuditAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return DashboardPressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: 8,
      builder: (context, state) {
        return Container(
          key: const Key('btn-activity-view-audit-log'),
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
