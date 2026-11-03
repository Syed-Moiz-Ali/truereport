import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

class SyncQueuePage extends ConsumerStatefulWidget {
  const SyncQueuePage({super.key});

  @override
  ConsumerState<SyncQueuePage> createState() => _SyncQueuePageState();
}

class _SyncQueuePageState extends ConsumerState<SyncQueuePage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(pendingOperationsProvider);
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.syncQueue)),
      body: pending.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 4),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(pendingOperationsProvider),
              retryLabel: l10n.search,
            ),
          ),
        ),
        data: (operations) => ListView(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          children: [
            SectionHeader(title: l10n.syncQueue),
            if (operations.isEmpty)
              EmptyState(title: l10n.noPendingSync, body: l10n.syncQueue)
            else
              ...operations.map((operation) => _OperationTile(operation)),
            SizedBox(height: context.spacing.lg),
            AppButton(
              label: l10n.syncNow,
              onPressed: operations.isEmpty || _busy ? null : _sync,
              isLoading: _busy,
              icon: Icons.sync,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sync() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final report = await ref.read(syncServiceProvider).syncAll();
      ref.invalidate(pendingOperationsProvider);
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(technicianJobsProvider);
      ref.invalidate(inspectionChecklistProvider);
      ref.invalidate(inspectionReviewProvider);
      ref.invalidate(technicianJobProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              report.failed == 0 && report.conflicts == 0
                  ? l10n.syncComplete
                  : l10n.actionFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile(this.operation);

  final SyncOperation operation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = operation.state;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
      child: Card(
        child: AppListTile(
          leading: Icon(
            operation.type == 'evidence'
                ? Icons.photo_outlined
                : Icons.fact_check_outlined,
          ),
          title: operation.type == 'evidence'
              ? l10n.attachments
              : l10n.saveAnswer,
          subtitle: operation.lastError ?? operation.jobId,
          trailing: StatusChip(
            label: state == 'CONFLICT' ? l10n.error : l10n.pending,
            tone: state == 'CONFLICT' ? StatusTone.danger : StatusTone.warning,
          ),
        ),
      ),
    );
  }
}
