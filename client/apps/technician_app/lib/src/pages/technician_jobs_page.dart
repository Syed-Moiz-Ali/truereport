import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';

class TechnicianJobsPage extends ConsumerStatefulWidget {
  const TechnicianJobsPage({super.key});

  @override
  ConsumerState<TechnicianJobsPage> createState() => _TechnicianJobsPageState();
}

class _TechnicianJobsPageState extends ConsumerState<TechnicianJobsPage> {
  final _search = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final jobs = ref.watch(technicianJobsProvider);
    final online = ref.watch(connectivityProvider).value ?? true;
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;
    ref.listen(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value == false) {
        ref.read(syncServiceProvider).syncAll().then((_) {
          ref.invalidate(pendingSyncCountProvider);
          ref.invalidate(technicianJobsProvider);
          ref.invalidate(inspectionChecklistProvider);
          ref.invalidate(inspectionReviewProvider);
        });
      }
    });
    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.assignedJobs),
        actions: [
          AppButton(
            label: locale.languageCode == 'ar'
                ? l10n.languageEnglish
                : l10n.languageArabic,
            onPressed: () => ref
                .read(localeProvider.notifier)
                .setLocale(
                  locale.languageCode == 'ar'
                      ? const Locale('en')
                      : const Locale('ar'),
                ),
            variant: AppButtonVariant.text,
          ),
          IconButton(
            tooltip: l10n.syncQueue,
            onPressed: () async {
              await context.push('/sync');
              ref.invalidate(pendingSyncCountProvider);
            },
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.sync),
            ),
          ),
          IconButton(
            tooltip: l10n.signOut,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/jobs/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.walkInJob),
      ),
      body: jobs.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 5),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(technicianJobsProvider),
              retryLabel: l10n.search,
            ),
          ),
        ),
        data: (items) {
          final filtered = items
              .where((job) {
                final query = _search.text.trim().toLowerCase();
                final matchesQuery =
                    query.isEmpty ||
                    job.reference.toLowerCase().contains(query) ||
                    job.customerName.toLowerCase().contains(query) ||
                    '${job.vehicleMake} ${job.vehicleModel}'
                        .toLowerCase()
                        .contains(query);
                return matchesQuery &&
                    (_status.isEmpty || job.status == _status);
              })
              .toList(growable: false);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(technicianJobsProvider),
            child: ListView(
              padding: EdgeInsetsDirectional.all(context.spacing.lg),
              children: [
                SectionHeader(title: l10n.assignedJobs),
                if (!online)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: context.spacing.sm,
                    ),
                    child: StatusChip(
                      label: l10n.offlineBanner,
                      tone: StatusTone.warning,
                      icon: Icons.cloud_off_outlined,
                    ),
                  ),
                AppTextField(
                  controller: _search,
                  label: l10n.search,
                  hint: l10n.search,
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: context.spacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filter(l10n.filterAll, ''),
                      SizedBox(width: context.spacing.sm),
                      _filter(l10n.statusAssigned, 'ASSIGNED'),
                      SizedBox(width: context.spacing.sm),
                      _filter(l10n.statusInProgress, 'IN_PROGRESS'),
                      SizedBox(width: context.spacing.sm),
                      _filter(l10n.statusReadyToFinalize, 'READY_TO_FINALIZE'),
                      SizedBox(width: context.spacing.sm),
                      _filter(l10n.statusFinalized, 'FINALIZED'),
                    ],
                  ),
                ),
                SizedBox(height: context.spacing.md),
                if (filtered.isEmpty)
                  EmptyState(
                    title: l10n.noAssignedJobs,
                    body: l10n.walkInJob,
                    icon: Icons.work_outline,
                    action: AppButton(
                      label: l10n.walkInJob,
                      onPressed: () => context.push('/jobs/new'),
                      variant: AppButtonVariant.tonal,
                    ),
                  )
                else
                  ...filtered.map(
                    (job) => Padding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: context.spacing.sm,
                      ),
                      child: Card(
                        child: AppListTile(
                          key: Key('technician-job-${job.id}'),
                          leading: const Icon(Icons.directions_car_outlined),
                          title: '${job.reference} · ${job.customerName}',
                          subtitle:
                              '${job.vehicleMake} ${job.vehicleModel} · ${job.templateName} v${job.templateVersionNo ?? '-'}',
                          trailing: StatusChip(
                            label: technicianStatusLabel(l10n, job.status),
                            tone: technicianStatusTone(job.status),
                          ),
                          onTap: () => context.push('/jobs/${job.id}'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filter(String label, String status) {
    return AppSelectableText(
      label: label,
      selected: _status == status,
      onTap: () => setState(() => _status = status),
    );
  }
}
