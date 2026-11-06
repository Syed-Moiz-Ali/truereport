import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2a/profile_sheet.dart';
import 'package:technician_app/src/screens/f2b/dense_mechanical_view.dart';
import 'package:technician_app/src/technician_providers.dart';

class ChecklistPage extends ConsumerStatefulWidget {
  const ChecklistPage({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends ConsumerState<ChecklistPage> {
  String? _busyItemId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checklist = ref.watch(inspectionChecklistProvider(widget.jobId));
    return checklist.when(
      loading: () => AppScaffold(
        appBar: AppBar(title: Text(l10n.checklist)),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 7),
        ),
      ),
      error: (error, _) => AppScaffold(
        appBar: AppBar(title: Text(l10n.checklist)),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () =>
                  ref.invalidate(inspectionChecklistProvider(widget.jobId)),
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
      ),
      data: (value) => DenseMechanicalView(
        checklist: value,
        finalized: value.job.status == 'FINALIZED',
        busyItemId: _busyItemId,
        onResult: (_, _) {},
        onSaveItem: _saveItem,
        onOpenItem: (item) => context.push(
          '/jobs/${widget.jobId}/items/${item.inspectionItemId}',
        ),
        onContinue: () => context.push('/jobs/${widget.jobId}/review'),
        onBack: () => context.pop(),
        onProfile: () => showTechnicianProfile(context, ref),
      ),
    );
  }

  Future<void> _saveItem(
    InspectionItem item,
    String result,
    String? severity,
    String note,
  ) async {
    final l10n = AppLocalizations.of(context);
    final defect =
        result == 'DEFECT_FOUND' || result == 'ATTENTION_RECOMMENDED';
    final reasonRequired =
        result == 'NOT_CHECKED' || result == 'COULD_NOT_VERIFY';
    if (defect && (severity == null || severity.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.severity)));
      return;
    }
    if (item.noteRequirement == 'REQUIRED' && note.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.note)));
      return;
    }
    setState(() => _busyItemId = item.inspectionItemId);
    try {
      final existing = item.assessment;
      final body = <String, dynamic>{
        'baseVersion': existing?.version ?? 0,
        'clientRevision': (existing?.clientRevision ?? 0) + 1,
        'resultCode': result,
        'severityCode': defect ? severity : null,
        'note': note,
        'reasonText': reasonRequired ? note : null,
      };
      final store = ref.read(offlineStoreProvider);
      final localAssessment = InspectionAssessment(
        id: existing?.id ?? 'local-${item.inspectionItemId}',
        resultCode: result,
        severityCode: defect ? severity : null,
        note: note,
        noteLanguage: existing?.noteLanguage,
        reasonCode: existing?.reasonCode,
        reasonText: reasonRequired ? note : null,
        clientRevision: body['clientRevision'] as int,
        serverRevision: existing?.serverRevision ?? 0,
        version: existing?.version ?? 0,
      ).toJson();
      await store.saveAssessmentLocally(
        jobId: widget.jobId,
        itemId: item.inspectionItemId,
        body: body,
        assessment: localAssessment,
      );
      await ref.read(syncServiceProvider).syncAll();
      final pending = await store.pendingCount();
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(pendingOperationsProvider);
      ref.invalidate(inspectionChecklistProvider(widget.jobId));
      ref.invalidate(inspectionReviewProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pending == 0 ? l10n.itemSaved : l10n.savedOnPhone),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busyItemId = null);
      }
    }
  }
}
