import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/jobs/assigned_jobs_view.dart';
import 'package:technician_app/src/features/profile/profile_sheet.dart';
import 'package:technician_app/src/technician_providers.dart';

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

  Future<void> _openFilters() async {
    final l10n = AppLocalizations.of(context);
    await showAppBottomSheet<void>(
      context,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TechnicianSectionTitle(title: l10n.search),
            SizedBox(height: context.spacing.md),
            AppTextField(
              controller: _search,
              label: l10n.search,
              labelAbove: true,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: context.spacing.lg),
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: [
                _filter(l10n.filterAll, ''),
                _filter(l10n.statusAssigned, 'ASSIGNED'),
                _filter(l10n.statusInProgress, 'IN_PROGRESS'),
                _filter(l10n.statusReadyToFinalize, 'READY_TO_FINALIZE'),
                _filter(l10n.statusFinalized, 'FINALIZED'),
              ],
            ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authControllerProvider).value;
    final jobs = ref.watch(technicianJobsProvider);
    final online = ref.watch(connectivityProvider).value ?? true;
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;
    final technicianName = session?.user.displayName ?? l10n.roleTechnician;

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

    Future<void> refresh() async {
      ref.invalidate(technicianJobsProvider);
      await ref.read(technicianJobsProvider.future);
    }

    Widget buildDock(int selectedIndex) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      return FxDock(
        key: const Key('f2a1-dock'),
        selectedIndex: selectedIndex,
        onSelected: (index) {
          switch (index) {
            case 0:
              setState(() => _status = '');
              break;
            case 1:
              setState(
                () => _status = _status == 'FINALIZED' ? '' : 'FINALIZED',
              );
              break;
            case 2:
              context.push('/sync').then((_) {
                ref.invalidate(pendingSyncCountProvider);
              });
              break;
            case 3:
              showTechnicianProfile(context, ref);
              break;
            default:
              break;
          }
        },
        items: [
          FxDockItem(
            label: isAr ? 'استلام' : 'Intake',
            iconId: '1_7269',
            iconWidth: 18,
            iconHeight: 20,
            semanticLabel: isAr ? 'استلام' : 'Intake',
          ),
          FxDockItem(
            label: isAr ? 'الأسطول' : 'Fleet',
            iconId: '1_7274',
            iconWidth: 18,
            iconHeight: 16,
            semanticLabel: isAr ? 'الأسطول' : 'Fleet',
          ),
          FxDockItem(
            label: l10n.technicianSyncTitle,
            iconId: '1_7279',
            iconWidth: 22,
            iconHeight: 18,
            semanticLabel: l10n.technicianSyncTitle,
          ),
          FxDockItem(
            label: l10n.technicianProfileTitle,
            iconId: '1_7284',
            iconWidth: 20,
            iconHeight: 20,
            semanticLabel: l10n.technicianProfileTitle,
          ),
        ],
      );
    }

    final selectedIndex = _status == 'FINALIZED' ? 1 : 0;

    return jobs.when(
      loading: () => AppScaffold(
        backgroundColor: Fx.white,
        extendBody: true,
        appBar: FxHeader(
          title: l10n.technicianInspectionQueue,
          titleStyle: Fx.text(16, 22, FontWeight.w700, -0.4),
        ),
        bottomNavigationBar: buildDock(selectedIndex),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.gutter),
          child: const LoadingSkeleton(lines: 6),
        ),
      ),
      error: (error, _) => AppScaffold(
        backgroundColor: Fx.white,
        extendBody: true,
        appBar: FxHeader(
          title: l10n.technicianInspectionQueue,
          titleStyle: Fx.text(16, 22, FontWeight.w700, -0.4),
        ),
        bottomNavigationBar: buildDock(selectedIndex),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.gutter),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(technicianJobsProvider),
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
      ),
      data: (items) {
        final query = _search.text.trim().toLowerCase();
        final filtered = items
            .where((job) {
              final matchesQuery =
                  query.isEmpty ||
                  job.reference.toLowerCase().contains(query) ||
                  job.customerName.toLowerCase().contains(query) ||
                  '${job.vehicleMake} ${job.vehicleModel}'
                      .toLowerCase()
                      .contains(query);
              return matchesQuery && (_status.isEmpty || job.status == _status);
            })
            .toList(growable: false);

        if (items.isEmpty) {
          return EmptyJobsView(
            technicianName: technicianName,
            pendingSyncCount: pending,
            selectedIndex: selectedIndex,
            onIntake: () => setState(() => _status = ''),
            onCompleted: () => setState(
              () => _status = _status == 'FINALIZED' ? '' : 'FINALIZED',
            ),
            onRefresh: refresh,
            onWalkIn: () => context.push('/jobs/new'),
            onSync: () async {
              await context.push('/sync');
              ref.invalidate(pendingSyncCountProvider);
            },
            onProfile: () => showTechnicianProfile(context, ref),
          );
        }

        return AssignedJobsView(
          technicianName: technicianName,
          jobs: filtered,
          pendingSyncCount: pending,
          online: online,
          selectedIndex: selectedIndex,
          onIntake: () => setState(() => _status = ''),
          onCompleted: () => setState(
            () => _status = _status == 'FINALIZED' ? '' : 'FINALIZED',
          ),
          onOpenJob: (job) => context.push('/jobs/${job.id}'),
          onRefresh: refresh,
          onWalkIn: () => context.push('/jobs/new'),
          onSync: () async {
            await context.push('/sync');
            ref.invalidate(pendingSyncCountProvider);
          },
          onProfile: () => showTechnicianProfile(context, ref),
          onSearch: _openFilters,
          showSearch: true,
        );
      },
    );
  }
}
