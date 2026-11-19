import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/sync/sync_providers.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

/// The field outbox: everything saved on this phone, grouped by job, with the
/// conflicts called out and handed to their own screen.
class TechnicianSyncPage extends ConsumerStatefulWidget {
  const TechnicianSyncPage({super.key});

  @override
  ConsumerState<TechnicianSyncPage> createState() => _TechnicianSyncPageState();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final operationsAsync = ref.watch(pendingOperationsProvider);
    final conflictsAsync = ref.watch(allTechnicianConflictsProvider);
    final online = ref.watch(connectivityProvider).value ?? true;
    final operations = operationsAsync.asData?.value ?? const <SyncOperation>[];
    final conflicts = conflictsAsync.asData?.value ?? const [];

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: Column(
        children: [
          _SyncBar(title: l10n.technicianSyncTitle, online: online),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pendingOperationsProvider);
                ref.invalidate(allTechnicianConflictsProvider);
                await ref.read(pendingOperationsProvider.future);
              },
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OutboxHero(
                            count: operations.length,
                            online: online,
                            replaying: _replaying,
                            onReplay: _replay,
                          ),
                          if (operations.isEmpty && conflicts.isEmpty) ...[
                            const SizedBox(height: 16),
                            _AllClear(
                              title: l10n.technicianSyncNothing,
                              body: l10n.technicianSyncAllSafe,
                            ),
                          ],
                          if (operations.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _SectionLabel(
                              label: l10n.technicianSyncQueuedChanges,
                              trailing: '${operations.length}',
                            ),
                            const SizedBox(height: 6),
                            for (final group in _group(operations)) ...[
                              _JobGroup(
                                jobId: group.jobId,
                                operations: group.operations,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                          if (conflicts.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _ConflictsCard(
                              conflicts: conflicts,
                              onOpen: _openConflict,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    final l10n = AppLocalizations.of(context);
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 16, 6),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              StatusChip(
                label: online
                    ? l10n.technicianSyncOnline
                    : l10n.technicianSyncOffline,
                tone: online ? StatusTone.success : StatusTone.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutboxHero extends StatelessWidget {
  const _OutboxHero({
    required this.count,
    required this.online,
    required this.replaying,
    required this.onReplay,
  });

  final int count;
  final bool online;
  final bool replaying;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final tone = online
        ? context.statusColors.success
        : context.statusColors.warning;
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tone.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  size: 21,
                  color: tone.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 0
                      ? l10n.technicianSyncNothing
                      : l10n.technicianSyncChangesOnPhone(count),
                  style: context.texts.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.technicianSyncSavedHint,
            style: context.texts.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _PillButton(
            label: l10n.technicianSyncReplayNow,
            icon: Icons.sync,
            variant: _PillVariant.soft,
            loading: replaying,
            onPressed: replaying ? null : onReplay,
          ),
        ],
      ),
    );
  }
}

class _AllClear extends StatelessWidget {
  const _AllClear({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(18),
      decoration: BoxDecoration(
        color: context.statusColors.success.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 22,
            color: context.statusColors.success.foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: context.texts.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: context.texts.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _JobGroup extends StatelessWidget {
  const _JobGroup({required this.jobId, required this.operations});

  final String jobId;
  final List<SyncOperation> operations;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    jobId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Text(
                  '${operations.length}',
                  style: context.texts.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < operations.length; index++) ...[
            if (index == 0)
              Divider(height: 1, color: colors.outlineVariant)
            else
              Divider(
                height: 1,
                color: colors.outlineVariant,
                indent: 16,
                endIndent: 16,
              ),
            _OperationRow(operation: operations[index]),
          ],
        ],
      ),
    );
  }
}

class _OperationRow extends StatelessWidget {
  const _OperationRow({required this.operation});

  final SyncOperation operation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final failed = operation.state == 'FAILED';
    final itemCode =
        operation.payload['itemCode'] as String? ??
        operation.payload['itemId'] as String?;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(operation.createdAt.toLocal()),
      alwaysUse24HourFormat: true,
    );
    final meta = [
      if (itemCode != null && itemCode.isNotEmpty) itemCode,
      _stateLabel(l10n, operation.state),
      time,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: failed
                  ? context.statusColors.danger.background
                  : colors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _operationIcon(operation.type),
              size: 18,
              color: failed
                  ? context.statusColors.danger.foreground
                  : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _operationTitle(l10n, operation.type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (failed && operation.lastError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.technicianSyncLastError}: ${operation.lastError}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.statusColors.danger.foreground,
                    ),
                  ),
                ],
                if (failed && operation.attempts > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.technicianSyncAttempts(operation.attempts),
                    style: context.texts.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictsCard extends StatelessWidget {
  const _ConflictsCard({required this.conflicts, required this.onOpen});

  final List<SyncConflictRecord> conflicts;
  final ValueChanged<SyncConflictRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final danger = context.statusColors.danger;
    return Container(
      decoration: BoxDecoration(
        color: danger.background,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: danger.foreground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.technicianSyncServerChanges(conflicts.length),
                        style: context.texts.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: danger.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.technicianSyncConflictHint,
                  style: context.texts.bodySmall?.copyWith(
                    color: danger.foreground.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < conflicts.length; index++) ...[
                  if (index != 0)
                    Divider(
                      height: 1,
                      color: colors.outlineVariant,
                      indent: 14,
                      endIndent: 14,
                    ),
                  _ConflictRow(
                    conflict: conflicts[index],
                    onTap: () => onOpen(conflicts[index]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictRow extends StatelessWidget {
  const _ConflictRow({required this.conflict, required this.onTap});

  final SyncConflictRecord conflict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = context.statusColors.danger;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 12, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conflict.itemCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${conflict.jobId} · '
                      'rev ${conflict.clientRevision} → '
                      '${conflict.serverRevision}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: tone.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PillVariant { primary, soft }

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.variant,
    this.icon,
    this.loading = false,
    this.onPressed,
  });

  final String label;
  final _PillVariant variant;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg) = switch (variant) {
      _PillVariant.primary => (context.brand.ink, Colors.white),
      _PillVariant.soft => (
        context.colors.surfaceContainer,
        context.colors.onSurface,
      ),
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: enabled ? bg : bg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else ...[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 17, color: fg),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _operationTitle(AppLocalizations l10n, String type) {
  switch (type.replaceAll('_clean', '')) {
    case 'assessment':
      return l10n.technicianOpAssessment;
    case 'evidence':
      return l10n.technicianOpEvidence;
    case 'customer':
      return l10n.technicianOpCustomer;
    case 'vehicle':
      return l10n.technicianOpVehicle;
    case 'consent':
      return l10n.technicianOpConsent;
    default:
      return type;
  }
}

IconData _operationIcon(String type) {
  switch (type.replaceAll('_clean', '')) {
    case 'evidence':
      return Icons.photo_camera_outlined;
    case 'customer':
      return Icons.person_outline;
    case 'vehicle':
      return Icons.directions_car_outlined;
    case 'consent':
      return Icons.verified_user_outlined;
    default:
      return Icons.checklist_rounded;
  }
}

String _stateLabel(AppLocalizations l10n, String state) {
  switch (state) {
    case 'FAILED':
      return l10n.technicianSyncStateFailed;
    case 'SYNCING':
      return l10n.technicianSyncStateSyncing;
    case 'CONFLICT':
      return l10n.technicianSyncStateConflict;
    default:
      return l10n.technicianQueued;
  }
}
