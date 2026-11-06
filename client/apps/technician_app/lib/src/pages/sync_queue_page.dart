import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/screens/f2a/profile_sheet.dart';
import 'package:technician_app/src/screens/f2b/offline_sync_view.dart';
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
    final count = ref.watch(pendingSyncCountProvider).value ?? 0;
    final online = ref.watch(connectivityProvider).value ?? true;
    return pending.when(
      loading: () => Scaffold(
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 4),
        ),
      ),
      error: (error, _) =>
          Scaffold(body: Center(child: Text(l10n.genericError))),
      data: (operations) => OfflineSyncView(
        operations: operations,
        pendingCount: count,
        online: online,
        busy: _busy,
        onRetry: _sync,
        onBack: () => context.pop(),
        onProfile: () => showTechnicianProfile(context, ref),
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
