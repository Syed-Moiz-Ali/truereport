import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/reference_ui.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'fieldwork/sync_board.dart';
import 'sync_format.dart';
import 'sync_providers.dart';

/// The outbox: every change still held on this device, grouped by job, with the
/// conflicts that need a decision above them and one action that pushes it all.
///
/// Behaviour is unchanged: the same providers, grouping, replay, refresh,
/// conflict route and offline semantics.
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

  void _reload() {
    ref.invalidate(pendingOperationsProvider);
    ref.invalidate(allTechnicianConflictsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final localizations = MaterialLocalizations.of(context);
    final operationsAsync = ref.watch(pendingOperationsProvider);
    final conflictsAsync = ref.watch(allTechnicianConflictsProvider);
    final online = ref.watch(connectivityProvider).value ?? true;
    final session = ref.watch(authControllerProvider).value;
    final name = session?.user.displayName.trim() ?? '';
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
      backgroundColor: context.colors.surfaceContainerLow,
      body: SyncBoard(
        header: SyncHeaderData(
          title: t(TechnicianKeys.technicianSyncTitle),
          subtitle: name.isNotEmpty
              ? name
              : total > 0
              ? t(TechnicianKeys.technicianSyncChangesOnPhone, {'count': total})
              : t(TechnicianKeys.technicianAllSynced),
          stateLabel: online
              ? t(TechnicianKeys.technicianSyncOnline)
              : t(TechnicianKeys.technicianSyncOffline),
          stateTone: online ? StatusTone.success : StatusTone.warning,
          stateIcon: online
              ? Icons.cloud_done_outlined
              : Icons.cloud_off_rounded,
        ),
        summary: SyncSummaryData(
          eyebrow: t(TechnicianKeys.technicianSyncQueuedChanges),
          count: total,
          countLabel: t(TechnicianKeys.technicianSyncChangesOnPhone, {
            'count': total,
          }),
          oldestLabel: oldest == null
              ? null
              : syncOldestLabel(localizations, oldest, DateTime.now()),
          conflictLabel: conflicts.isEmpty
              ? null
              : '${t(TechnicianKeys.technicianConflicts)} · ${conflicts.length}',
          hint: t(TechnicianKeys.technicianSyncSavedHint),
        ),
        conflicts: conflicts.isEmpty
            ? null
            : SyncConflictsData(
                title: t(TechnicianKeys.technicianSyncServerChanges, {
                  'count': conflicts.length,
                }),
                hint: t(TechnicianKeys.technicianSyncConflictHint),
                items: [
                  for (final conflict in conflicts)
                    SyncConflictData(
                      id: conflict.id,
                      itemCode: conflict.itemCode,
                      jobLabel: t(TechnicianKeys.technicianConflictJob, {
                        'jobId': _jobRef(conflict.jobId),
                      }),
                      revisionLabel:
                          '${conflict.clientRevision} → '
                          '${conflict.serverRevision}',
                      stateLabel: t(TechnicianKeys.technicianSyncConflictTitle),
                      semanticLabel: [
                        conflict.itemCode,
                        t(TechnicianKeys.technicianConflictJob, {
                          'jobId': _jobRef(conflict.jobId),
                        }),
                        '${conflict.clientRevision} → '
                            '${conflict.serverRevision}',
                        t(TechnicianKeys.technicianSyncConflictTitle),
                      ].join('. '),
                    ),
                ],
              ),
        groups: [
          for (final group in groups)
            SyncGroupData(
              jobLabel: t(TechnicianKeys.syncJobRef, {
                'jobId': _jobRef(group.jobId),
              }),
              metaLabel: t(TechnicianKeys.technicianSyncPendingCount, {
                'count': group.operations.length,
              }),
              operations: [
                for (final operation in group.operations)
                  _operationData(operation, t, localizations),
              ],
            ),
        ],
        empty: SyncEmptyData(
          title: t(TechnicianKeys.technicianAllSynced),
          body: t(TechnicianKeys.technicianSyncAllSafe),
        ),
        footer: SyncFooterData(
          hint: t(TechnicianKeys.technicianSyncSavedHint),
          actionLabel: t(TechnicianKeys.syncNow),
          savedLabel: t(TechnicianKeys.technicianAllSynced),
        ),
        loading:
            (operationsAsync.isLoading && !operationsAsync.hasValue) ||
            (conflictsAsync.isLoading && !conflictsAsync.hasValue),
        error: operationsAsync.hasError && !operationsAsync.hasValue
            ? SyncErrorData(
                title: t(TechnicianKeys.error),
                body: t(TechnicianKeys.genericError),
                retryLabel: t(TechnicianKeys.retryAction),
              )
            : null,
        offlineLabel: online ? null : t(TechnicianKeys.technicianSyncSavedHint),
        replaying: _replaying,
        canSync: canSync,
        onBack: () => Navigator.of(context).maybePop(),
        onSync: _replay,
        onOpenConflict: (id) {
          for (final conflict in conflicts) {
            if (conflict.id == id) {
              _openConflict(conflict);
              return;
            }
          }
        },
        onRetry: _reload,
        onRefresh: () async {
          _reload();
          await ref.read(pendingOperationsProvider.future);
        },
      ),
    );
  }

  SyncOperationData _operationData(
    SyncOperation operation,
    UiStrings t,
    MaterialLocalizations localizations,
  ) {
    final failed = operation.state == 'FAILED';
    final itemCode =
        (operation.payload['itemCode'] ?? operation.payload['itemId'] ?? '')
            .toString()
            .trim();
    final stateLabel = syncStatusLabel(ref, operation.state);
    final title = syncOperationTitle(t, operation.type);
    final timeLabel = syncClockLabel(localizations, operation.createdAt);
    return SyncOperationData(
      icon: syncOperationIcon(operation.type),
      title: title,
      itemCode: itemCode,
      timeLabel: timeLabel,
      stateLabel: stateLabel,
      stateTone: syncStatusTone(ref, operation.state),
      errorLabel: failed && operation.lastError != null
          ? '${t(TechnicianKeys.technicianSyncLastError)}: '
                '${operation.lastError}'
          : null,
      attemptsLabel: failed && operation.attempts > 1
          ? t(TechnicianKeys.technicianSyncAttempts, {
              'count': operation.attempts,
            })
          : null,
      semanticLabel: [
        title,
        stateLabel,
        if (itemCode.isNotEmpty) itemCode,
        timeLabel,
        if (failed && operation.lastError != null) operation.lastError!,
      ].join('. '),
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

/// `job-10485` is an internal id; the UI shows `Job #10485`.
String _jobRef(String jobId) {
  final trimmed = jobId.trim();
  return trimmed.startsWith('job-') ? trimmed.substring(4) : trimmed;
}
