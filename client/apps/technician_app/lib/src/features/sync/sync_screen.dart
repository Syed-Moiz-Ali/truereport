import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'sync_providers.dart';
import 'widgets/sync_conflict_strip.dart';
import 'widgets/sync_operation_row.dart';

/// The outbox: every change still held on this device, grouped by job, with the
/// conflicts that need a decision above them and one action that pushes it all.
class TechnicianSyncPage extends ConsumerStatefulWidget {
  const TechnicianSyncPage({super.key});

  @override
  ConsumerState<TechnicianSyncPage> createState() => _TechnicianSyncPageState();
}

class _TechnicianSyncPageState extends ConsumerState<TechnicianSyncPage> {
  bool _replaying = false;

  Future<void> _replay() async {
    final t = UiStrings.of(context);
    setState(() => _replaying = true);
    final report = await ref.read(syncServiceProvider).syncAll();
    ref.invalidate(syncQueueStatusProvider);
    ref.invalidate(pendingOperationsProvider);
    ref.invalidate(allTechnicianConflictsProvider);
    ref.invalidate(technicianJobPageProvider);
    if (!mounted) {
      return;
    }
    setState(() => _replaying = false);
    final message = report.conflicts > 0
        ? t(TechnicianKeys.technicianSyncConflictsCount, {
            'count': report.conflicts,
          })
        : t(TechnicianKeys.technicianSyncApplied, {'count': report.synced});
    showAppSnackBar(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final operationsAsync = ref.watch(pendingOperationsProvider);
    final conflictsAsync = ref.watch(allTechnicianConflictsProvider);
    final online = ref.watch(connectivityProvider).value ?? true;
    final operations = operationsAsync.asData?.value ?? const <SyncOperation>[];
    final conflicts = conflictsAsync.asData?.value ?? const [];
    final groups = _group(operations);
    final total = operations.length;
    final oldest = operations.isEmpty
        ? null
        : operations
              .map((value) => value.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b);
    final canSync = online && total > 0 && !_replaying;

    return AppScaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: Column(
        children: [
          _SyncBar(
            title: t(TechnicianKeys.technicianSyncTitle),
            online: online,
          ),
          Expanded(
            child: RefreshIndicator(
              color: context.brand.ink,
              backgroundColor: colors.surface,
              onRefresh: () async {
                ref.invalidate(pendingOperationsProvider);
                ref.invalidate(allTechnicianConflictsProvider);
                await ref.read(pendingOperationsProvider.future);
              },
              child: ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  16,
                  total == 0 && conflicts.isEmpty ? 72 : 0,
                  16,
                  24,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (total > 0) ...[
                            _StatusLine(
                              total: total,
                              online: online,
                              oldest: oldest,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (conflicts.isNotEmpty) ...[
                            SyncConflictStrip(
                              conflicts: conflicts,
                              onOpen: _openConflict,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (total == 0 && conflicts.isEmpty)
                            _AllClear(
                              title: t(TechnicianKeys.technicianSyncNothing),
                              body: t(TechnicianKeys.technicianSyncAllSafe),
                              online: online,
                            ),
                          for (final group in groups) ...[
                            _GroupHeader(
                              jobId: group.jobId,
                              count: group.operations.length,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < group.operations.length;
                                    index++
                                  ) ...[
                                    if (index > 0)
                                      Divider(
                                        height: 1,
                                        color: colors.outlineVariant,
                                        indent: 14,
                                        endIndent: 14,
                                      ),
                                    SyncOperationRow(
                                      operation: group.operations[index],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SyncFooter(
            showAction: total > 0,
            savedHint: t(TechnicianKeys.technicianSyncSavedHint),
            label: t(TechnicianKeys.technicianSyncReplayNow),
            online: online,
            replaying: _replaying,
            canSync: canSync,
            onSync: _replay,
          ),
        ],
      ),
    );
  }

  Future<void> _openConflict(SyncConflictRecord conflict) async {
    await context.push('/sync/conflicts/${conflict.id}');
    ref.invalidate(allTechnicianConflictsProvider);
    ref.invalidate(pendingOperationsProvider);
    ref.invalidate(syncQueueStatusProvider);
  }

  List<_JobGroupData> _group(List<SyncOperation> operations) {
    final order = <String>[];
    final buckets = <String, List<SyncOperation>>{};
    for (final operation in operations) {
      (buckets[operation.jobId] ??= []).add(operation);
      if (!order.contains(operation.jobId)) {
        order.add(operation.jobId);
      }
    }
    return [
      for (final jobId in order)
        _JobGroupData(jobId: jobId, operations: buckets[jobId]!),
    ];
  }
}

class _JobGroupData {
  const _JobGroupData({required this.jobId, required this.operations});

  final String jobId;
  final List<SyncOperation> operations;
}

class _SyncBar extends StatelessWidget {
  const _SyncBar({required this.title, required this.online});

  final String title;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 16, 8),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      size: 21,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              StatusChip(
                label: online
                    ? t(TechnicianKeys.technicianSyncOnline)
                    : t(TechnicianKeys.technicianSyncOffline),
                tone: online ? StatusTone.success : StatusTone.warning,
                icon: online
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_rounded,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: colors.onSurfaceVariant.withValues(alpha: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One honest line about the outbox: how much, how old, and whether it can go.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.total,
    required this.online,
    required this.oldest,
  });

  final int total;
  final bool online;
  final DateTime? oldest;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final tone = online
        ? context.statusColors.success
        : context.statusColors.warning;
    final oldestLabel = oldest == null
        ? ''
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(oldest!.toLocal()),
            alwaysUse24HourFormat: true,
          );
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: tone.foreground,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t(TechnicianKeys.technicianSyncChangesOnPhone, {'count': total}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (oldestLabel.isNotEmpty) ...[
          Icon(
            Icons.schedule_rounded,
            size: 12,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            oldestLabel,
            style: context.texts.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.jobId, required this.count});

  final String jobId;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            jobId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '$count',
          style: context.texts.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _AllClear extends StatelessWidget {
  const _AllClear({
    required this.title,
    required this.body,
    required this.online,
  });

  final String title;
  final String body;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final success = context.statusColors.success;
    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: success.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              online ? Icons.cloud_done_outlined : Icons.offline_pin_outlined,
              size: 24,
              color: success.foreground,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncFooter extends StatelessWidget {
  const _SyncFooter({
    required this.showAction,
    required this.savedHint,
    required this.label,
    required this.online,
    required this.replaying,
    required this.canSync,
    required this.onSync,
  });

  final bool showAction;
  final String savedHint;
  final String label;
  final bool online;
  final bool replaying;
  final bool canSync;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  savedHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (showAction)
                _SyncButton(
                  label: label,
                  online: online,
                  replaying: replaying,
                  enabled: canSync,
                  onPressed: onSync,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({
    required this.label,
    required this.online,
    required this.replaying,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool online;
  final bool replaying;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: 48,
        child: Material(
          color: enabled
              ? context.brand.ink
              : context.brand.ink.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (replaying)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  if (!replaying) ...[
                    const SizedBox(width: 8),
                    Icon(
                      online ? Icons.sync_rounded : Icons.cloud_off_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
