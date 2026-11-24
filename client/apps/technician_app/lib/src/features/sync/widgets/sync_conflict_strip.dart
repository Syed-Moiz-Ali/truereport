import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/offline/offline_models.dart';

/// Conflicts are decisions, not rows to scan: one strip that names the problem
/// and lists each item that needs a call.
class SyncConflictStrip extends StatelessWidget {
  const SyncConflictStrip({
    required this.conflicts,
    required this.onOpen,
    super.key,
  });

  final List<SyncConflictRecord> conflicts;
  final ValueChanged<SyncConflictRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final danger = context.statusColors.danger;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger.foreground.withValues(alpha: 0.28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
            color: danger.background,
            child: Row(
              children: [
                Icon(
                  Icons.sync_problem_rounded,
                  size: 18,
                  color: danger.foreground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t(TechnicianKeys.technicianSyncServerChanges, {
                          'count': conflicts.length,
                        }),
                        maxLines: 2,
                        style: context.texts.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: danger.foreground,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        t(TechnicianKeys.technicianSyncConflictHint),
                        maxLines: 2,
                        style: context.texts.labelSmall?.copyWith(
                          color: danger.foreground.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < conflicts.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.outlineVariant),
            _ConflictLine(
              conflict: conflicts[index],
              onTap: () => onOpen(conflicts[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConflictLine extends StatelessWidget {
  const _ConflictLine({required this.conflict, required this.onTap});

  final SyncConflictRecord conflict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final danger = context.statusColors.danger;
    return Semantics(
      button: true,
      label: '${conflict.itemCode}, ${conflict.jobId}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 12, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conflict.itemCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${conflict.jobId} · '
                      '${conflict.clientRevision} → ${conflict.serverRevision}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Review',
                style: context.texts.labelSmall?.copyWith(
                  color: danger.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: danger.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
