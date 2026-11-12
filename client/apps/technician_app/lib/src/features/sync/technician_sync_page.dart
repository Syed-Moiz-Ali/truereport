import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/inspection/clean_conflict_panel.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

final allTechnicianConflictsProvider =
    FutureProvider.autoDispose<List<SyncConflictRecord>>((ref) {
      return ref.watch(offlineStoreProvider).openConflicts();
    });

class TechnicianSyncPage extends ConsumerStatefulWidget {
  const TechnicianSyncPage({super.key});

  @override
  ConsumerState<TechnicianSyncPage> createState() =>
      _TechnicianSyncPageState();
}

class _TechnicianSyncPageState extends ConsumerState<TechnicianSyncPage> {
  bool _replaying = false;

  Future<void> _replay() async {
    final l10n = AppLocalizations.of(context);
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
        ? l10n.technicianSyncConflictsCount(report.conflicts)
        : l10n.technicianSyncApplied(report.synced);
    showAppSnackBar(context, message: message);
  }

  Future<void> _reloadConflict(ConflictViewData conflict) async {
    final l10n = AppLocalizations.of(context);
    final id = conflict.id;
    if (id != null) {
      await ref.read(offlineStoreProvider).resolveConflict(id);
    }
    ref.invalidate(allTechnicianConflictsProvider);
    ref.invalidate(syncQueueStatusProvider);
    ref.invalidate(technicianChecklistProvider);
    ref.invalidate(technicianSummaryProvider);
    ref.invalidate(technicianJobPageProvider);
    if (mounted) {
      showAppSnackBar(context, message: l10n.technicianConflictReloaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusAsync = ref.watch(syncQueueStatusProvider);
    final operationsAsync = ref.watch(pendingOperationsProvider);
    final conflictsAsync = ref.watch(allTechnicianConflictsProvider);
    final status = statusAsync.asData?.value;
    final operations = operationsAsync.asData?.value ?? const <SyncOperation>[];
    final conflicts = conflictsAsync.asData?.value ?? const [];
    return AppScaffold(
      backgroundColor: context.colors.surface,
      appBar: TechnicianAppBar(
        title: l10n.technicianSyncTitle,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(syncQueueStatusProvider);
          ref.invalidate(pendingOperationsProvider);
          ref.invalidate(allTechnicianConflictsProvider);
          await ref.read(syncQueueStatusProvider.future);
        },
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: EdgeInsetsDirectional.all(context.spacing.gutter),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TechnicianSectionTitle(
                        title: l10n.technicianSyncPending,
                        subtitle: l10n.technicianOfflineQueued,
                      ),
                      SizedBox(height: context.spacing.sm),
                      Wrap(
                        spacing: context.spacing.sm,
                        runSpacing: context.spacing.sm,
                        children: [
                          StatusChip(
                            label:
                                '${l10n.technicianSyncPending} ${status?.pending ?? 0}',
                            tone: StatusTone.warning,
                            icon: Icons.cloud_upload_outlined,
                          ),
                          StatusChip(
                            label:
                                l10n.technicianSyncConflictsCount(status?.conflicts ?? 0),
                            tone: (status?.conflicts ?? 0) > 0
                                ? StatusTone.danger
                                : StatusTone.neutral,
                            icon: Icons.sync_problem,
                          ),
                        ],
                      ),
                      SizedBox(height: context.spacing.md),
                      AppButton(
                        label: l10n.technicianSyncReplay,
                        icon: Icons.sync,
                        expand: true,
                        isLoading: _replaying,
                        onPressed: _replaying ? null : _replay,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.spacing.md),
                if (operations.isEmpty && conflicts.isEmpty)
                  EmptyState(
                    title: l10n.technicianSyncNothing,
                    body: l10n.technicianSyncNothing,
                    icon: Icons.cloud_done_outlined,
                  )
                else ...[
                  if (operations.isNotEmpty)
                    AppCard(
                      variant: AppCardVariant.flat,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TechnicianSectionTitle(
                            title: l10n.technicianSyncPending,
                          ),
                          SizedBox(height: context.spacing.sm),
                          for (final operation in operations) ...[
                            _OperationRow(operation: operation),
                            SizedBox(height: context.spacing.xs),
                          ],
                        ],
                      ),
                    ),
                  if (conflicts.isNotEmpty)
                    ConflictPanel(
                      conflicts: [
                        for (final conflict in conflicts)
                          ConflictViewData(
                            id: conflict.id,
                            itemCode: conflict.itemCode,
                            clientPayload: conflict.clientPayloadJson,
                            serverPayload: conflict.serverPayloadJson,
                          ),
                      ],
                      onReload: _reloadConflict,
                    ),
                ],
                SizedBox(height: context.spacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationRow extends StatelessWidget {
  const _OperationRow({required this.operation});

  final SyncOperation operation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.all(context.spacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(context.radii.lg),
      ),
      child: Row(
        children: [
          Icon(
            operation.isConflict
                ? Icons.sync_problem
                : Icons.cloud_upload_outlined,
            color: operation.isConflict
                ? context.statusColors.danger.foreground
                : context.brand.ink,
          ),
          SizedBox(width: context.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(operation.type, style: context.texts.labelLarge),
                Text(
                  '${operation.jobId} · ${operation.state}',
                  style: context.texts.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
