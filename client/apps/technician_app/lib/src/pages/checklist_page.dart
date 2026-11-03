import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';

class ChecklistPage extends ConsumerWidget {
  const ChecklistPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final checklist = ref.watch(inspectionChecklistProvider(jobId));
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.checklist)),
      body: checklist.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 7),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(inspectionChecklistProvider(jobId)),
              retryLabel: l10n.search,
            ),
          ),
        ),
        data: (value) => _Body(checklist: value),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.checklist});

  final InspectionChecklist checklist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final grouped = <String, List<InspectionItem>>{};
    final labels = <String, String>{};
    for (final item in checklist.items) {
      final key = item.categoryLabelEn;
      grouped.putIfAbsent(key, () => []).add(item);
      labels[key] = item.categoryLabelEn;
    }
    final progress = checklist.total == 0
        ? 0.0
        : checklist.completed / checklist.total;
    final finalized = checklist.job.status == 'FINALIZED';
    return ListView(
      padding: EdgeInsetsDirectional.all(context.spacing.lg),
      children: [
        SectionHeader(
          title: l10n.checklist,
          subtitle:
              '${checklist.completed}/${checklist.total} ${l10n.completedItems}',
        ),
        LinearProgressIndicator(value: progress),
        SizedBox(height: context.spacing.lg),
        if (checklist.items.isEmpty)
          EmptyState(title: l10n.noResults, body: l10n.checklist)
        else
          ...grouped.entries.map(
            (group) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: labels[group.key] ?? group.key),
                ...group.value.map(
                  (item) => Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: context.spacing.sm,
                    ),
                    child: Card(
                      child: AppListTile(
                        key: Key('checklist-item-${item.inspectionItemId}'),
                        leading: Icon(
                          item.assessment == null
                              ? Icons.radio_button_unchecked
                              : Icons.check_circle_outline,
                        ),
                        title: item.labelEn,
                        subtitle:
                            '${item.stableCode} - v${item.versionNo}'
                            '${item.evidenceRequirement == 'NONE' ? '' : ' - ${l10n.evidenceRequirement}'}'
                            '${item.syncState == 'LOCAL_ONLY' ? ' - ${l10n.savedOnPhone}' : ''}'
                            '${item.syncState == 'CONFLICT' ? ' - ${l10n.error}' : ''}',
                        trailing: StatusChip(
                          label: item.assessment == null
                              ? l10n.notStarted
                              : resultLabel(l10n, item.assessment!.resultCode),
                          tone: resultTone(item.assessment?.resultCode),
                        ),
                        onTap: finalized
                            ? null
                            : () => context.push(
                                '/jobs/${checklist.job.id}/items/${item.inspectionItemId}',
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.spacing.sm),
              ],
            ),
          ),
        if (!finalized) ...[
          SizedBox(height: context.spacing.lg),
          AppButton(
            label: l10n.reviewAndFinalize,
            onPressed: () => context.push('/jobs/${checklist.job.id}/review'),
            icon: Icons.fact_check_outlined,
            expand: true,
          ),
        ],
      ],
    );
  }
}
