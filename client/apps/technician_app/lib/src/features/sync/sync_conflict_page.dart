import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/sync/sync_providers.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'fieldwork/conflict_board.dart';
import 'sync_format.dart';

/// One conflict, side by side: what this phone saved and what the server holds.
/// Keeping the server version is the only supported resolution, so it is the
/// only action on the screen.
class TechnicianConflictPage extends ConsumerStatefulWidget {
  const TechnicianConflictPage({required this.conflictId, super.key});

  final String conflictId;

  @override
  ConsumerState<TechnicianConflictPage> createState() =>
      _TechnicianConflictPageState();
}

class _TechnicianConflictPageState
    extends ConsumerState<TechnicianConflictPage> {
  bool _busy = false;

  Future<void> _useServer(SyncConflictRecord conflict) async {
    final t = UiStrings.of(context);
    setState(() => _busy = true);
    await ref.read(offlineStoreProvider).resolveConflict(conflict.id);
    ref.invalidate(allTechnicianConflictsProvider);
    ref.invalidate(syncQueueStatusProvider);
    ref.invalidate(pendingOperationsProvider);
    ref.invalidate(technicianChecklistProvider);
    ref.invalidate(technicianSummaryProvider);
    ref.invalidate(technicianJobPageProvider);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    showAppSnackBar(
      context,
      message: t(TechnicianKeys.technicianConflictReloaded),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final conflictsAsync = ref.watch(allTechnicianConflictsProvider);
    final title = t(TechnicianKeys.technicianSyncConflictTitle);
    final actionLabel = t(TechnicianKeys.technicianConflictUseServer);
    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: conflictsAsync.when(
        loading: () => ConflictBoard(
          header: ConflictHeaderData(title: title),
          actionLabel: actionLabel,
          busy: false,
          loading: true,
          onBack: () => Navigator.of(context).maybePop(),
          onUseServer: () {},
          onRetry: () => ref.invalidate(allTechnicianConflictsProvider),
        ),
        error: (error, _) => ConflictBoard(
          header: ConflictHeaderData(title: title),
          actionLabel: actionLabel,
          busy: false,
          loading: false,
          error: ConflictErrorData(
            title: t(TechnicianKeys.error),
            body: t(TechnicianKeys.genericError),
            retryLabel: t(TechnicianKeys.retryAction),
          ),
          onBack: () => Navigator.of(context).maybePop(),
          onUseServer: () {},
          onRetry: () => ref.invalidate(allTechnicianConflictsProvider),
        ),
        data: (conflicts) {
          final index = conflicts.indexWhere(
            (record) => record.id == widget.conflictId,
          );
          if (index == -1) {
            return ConflictBoard(
              header: ConflictHeaderData(title: title),
              actionLabel: actionLabel,
              busy: false,
              loading: false,
              missing: ConflictMissingData(
                title: t(TechnicianKeys.technicianConflictUnavailable),
                body: t(TechnicianKeys.technicianSyncNothing),
              ),
              onBack: () => Navigator.of(context).maybePop(),
              onUseServer: () {},
              onRetry: () => ref.invalidate(allTechnicianConflictsProvider),
            );
          }
          final conflict = conflicts[index];
          final diff = buildConflictDiff(
            conflict.clientPayloadJson,
            conflict.serverPayloadJson,
          );
          return ConflictBoard(
            header: ConflictHeaderData(
              title: title,
              counterLabel: '${index + 1} / ${conflicts.length}',
            ),
            identity: ConflictIdentityData(
              itemCode: conflict.itemCode,
              jobLabel: t(TechnicianKeys.syncJobRef, {
                'jobId': _jobRef(conflict.jobId),
              }),
              phoneRevision: '${conflict.clientRevision}',
              serverRevision: '${conflict.serverRevision}',
              phoneRevLabel: t(TechnicianKeys.technicianConflictPhoneRev),
              serverRevLabel: t(TechnicianKeys.technicianConflictServerRev),
            ),
            compare: ConflictCompareData(
              caption: t(TechnicianKeys.technicianConflictCompare),
              phoneCaption: t(TechnicianKeys.technicianConflictPhone),
              serverCaption: t(TechnicianKeys.technicianConflictServer),
              structured: diff.structured,
              rawPhone: diff.rawPhone,
              rawServer: diff.rawServer,
              fields: [
                for (final field in diff.fields)
                  ConflictFieldData(
                    label: field.label,
                    phoneValue: field.serverOnly
                        ? t(TechnicianKeys.technicianConflictOnlyServer)
                        : _displayValue(field.phone),
                    serverValue: field.phoneOnly
                        ? t(TechnicianKeys.technicianConflictOnlyPhone)
                        : _displayValue(field.server),
                    phoneMuted: field.serverOnly,
                    serverMuted: field.phoneOnly,
                  ),
              ],
            ),
            notes: [
              ConflictNoteData(
                message: t(TechnicianKeys.technicianConflictPhoneHint),
                tone: StatusTone.warning,
                icon: Icons.info_outline_rounded,
              ),
              ConflictNoteData(
                message: t(TechnicianKeys.technicianConflictRevalidate),
                tone: StatusTone.neutral,
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
            actionLabel: actionLabel,
            busy: _busy,
            loading: false,
            onBack: () => Navigator.of(context).maybePop(),
            onUseServer: () => _useServer(conflict),
            onRetry: () => ref.invalidate(allTechnicianConflictsProvider),
          );
        },
      ),
    );
  }

  String _displayValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '—' : text;
  }
}

/// `job-10485` is an internal id; the UI shows `Job #10485`.
String _jobRef(String jobId) {
  final trimmed = jobId.trim();
  return trimmed.startsWith('job-') ? trimmed.substring(4) : trimmed;
}
