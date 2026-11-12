import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/shared/technician_intl.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';

class TechnicianJobsCleanPage extends ConsumerStatefulWidget {
  const TechnicianJobsCleanPage({super.key});

  @override
  ConsumerState<TechnicianJobsCleanPage> createState() =>
      _TechnicianJobsCleanPageState();
}

class _TechnicianJobsCleanPageState
    extends ConsumerState<TechnicianJobsCleanPage> {
  static const _pageSize = 20;
  final _search = TextEditingController();
  int _page = 0;
  String _status = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setStatus(String status) {
    setState(() {
      _status = status;
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = (
      page: _page,
      size: _pageSize,
      status: _status.isEmpty ? null : _status,
    );
    final pageAsync = ref.watch(technicianJobPageProvider(query));
    final sync = ref.watch(syncQueueStatusProvider);

    return AppScaffold(
      backgroundColor: context.colors.surface,
      appBar: TechnicianAppBar(
        title: l10n.technicianJobQueue,
        onSearch: null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(technicianJobPageProvider);
          ref.invalidate(syncQueueStatusProvider);
          await ref.read(technicianJobPageProvider(query).future);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: EdgeInsetsDirectional.all(context.spacing.gutter),
                  children: [
                    _FilterBar(
                      search: _search,
                      status: _status,
                      onSearchChanged: (_) => setState(() {}),
                      onStatusChanged: _setStatus,
                    ),
                    SizedBox(height: context.spacing.md),
                    sync.maybeWhen(
                      data: (status) => _SyncSummary(status: status),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    SizedBox(height: context.spacing.md),
                    pageAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsetsDirectional.all(24),
                        child: LoadingSkeleton(lines: 6),
                      ),
                      error: (error, _) => ErrorState(
                        title: l10n.error,
                        body: l10n.genericError,
                        onRetry: () =>
                            ref.invalidate(technicianJobPageProvider),
                        retryLabel: l10n.retryAction,
                      ),
                      data: (page) {
                        final term = _search.text.trim().toLowerCase();
                        final items = page.items
                            .where((job) => _matches(job, term))
                            .toList(growable: false);
                        if (page.items.isEmpty) {
                          return EmptyState(
                            title: l10n.technicianAllCaughtUp,
                            body: l10n.technicianJobListEmpty,
                            icon: Icons.assignment_turned_in_outlined,
                          );
                        }
                        if (items.isEmpty) {
                          return EmptyState(
                            title: l10n.search,
                            body: l10n.technicianNoSearchResults,
                            icon: Icons.search_off,
                          );
                        }
                        final syncStatus = sync.asData?.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final job in items) ...[
                              _JobCard(
                                job: job,
                                pending: _pendingLabel(syncStatus),
                                onOpen: () => _open(job),
                              ),
                              SizedBox(height: context.spacing.sm),
                            ],
                            if (page.totalPages > 1) ...[
                              SizedBox(height: context.spacing.md),
                              _Pagination(
                                page: page,
                                onPrevious: _page <= 0
                                    ? null
                                    : () => setState(() => _page -= 1),
                                onNext: _page + 1 >= page.totalPages
                                    ? null
                                    : () => setState(() => _page += 1),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _matches(JobSummary job, String term) {
    if (term.isEmpty) {
      return true;
    }
    return job.reference.toLowerCase().contains(term) ||
        job.customerName.toLowerCase().contains(term) ||
        '${job.vehicleMake} ${job.vehicleModel}'.toLowerCase().contains(term);
  }

  String? _pendingLabel(SyncQueueStatus? status) {
    if (status == null || status.total == 0) {
      return null;
    }
    final l10n = AppLocalizations.of(context);
    if (status.conflicts > 0) {
      return l10n.technicianSyncConflictsCount(status.conflicts);
    }
    return '${l10n.technicianSyncPending} ${status.pending + status.failed}';
  }

  void _open(JobSummary job) => context.push('/jobs/${job.id}');
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.search,
    required this.status,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final TextEditingController search;
  final String status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: search,
          label: l10n.technicianJobSearch,
          labelAbove: true,
          prefixIcon: const Icon(Icons.search),
          onChanged: onSearchChanged,
        ),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: [
            AppFilterChip(
              label: l10n.technicianAllStatuses,
              selected: status.isEmpty,
              onSelected: (_) => onStatusChanged(''),
            ),
            AppFilterChip(
              label: technicianStatusLabel(l10n, 'ASSIGNED'),
              selected: status == 'ASSIGNED',
              onSelected: (_) => onStatusChanged('ASSIGNED'),
            ),
            AppFilterChip(
              label: technicianStatusLabel(l10n, 'IN_PROGRESS'),
              selected: status == 'IN_PROGRESS',
              onSelected: (_) => onStatusChanged('IN_PROGRESS'),
            ),
            AppFilterChip(
              label: technicianStatusLabel(l10n, 'PENDING_REVIEW'),
              selected: status == 'PENDING_REVIEW',
              onSelected: (_) => onStatusChanged('PENDING_REVIEW'),
            ),
            AppFilterChip(
              label: technicianStatusLabel(l10n, 'FINALIZED'),
              selected: status == 'FINALIZED',
              onSelected: (_) => onStatusChanged('FINALIZED'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SyncSummary extends StatelessWidget {
  const _SyncSummary({required this.status});

  final SyncQueueStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasConflict = status.conflicts > 0;
    return Wrap(
      spacing: context.spacing.sm,
      runSpacing: context.spacing.sm,
      children: [
        StatusChip(
          label: '${l10n.technicianSyncPending} ${status.pending + status.failed}',
          tone: StatusTone.warning,
          icon: Icons.cloud_upload_outlined,
        ),
        if (hasConflict)
          StatusChip(
            label: l10n.technicianSyncConflictsCount(status.conflicts),
            tone: StatusTone.danger,
            icon: Icons.sync_problem,
          ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.pending,
    required this.onOpen,
  });

  final JobSummary job;
  final String? pending;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final scheduled = job.startedAt != null && job.startedAt!.isNotEmpty
        ? job.startedAt!
        : job.scheduledAt;
    final total = job.totalItems <= 0 ? 1 : job.totalItems;
    return AppCard(
      onTap: onOpen,
      semanticLabel: job.reference,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      job.reference,
                      style: context.texts.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.spacing.xxs),
                    Text(
                      '${job.vehicleMake} ${job.vehicleModel}'
                      '${job.vehicleYear == null ? '' : ' · ${job.vehicleYear}'}',
                      style: context.texts.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      job.customerName,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    if (scheduled != null && scheduled.isNotEmpty) ...[
                      SizedBox(height: context.spacing.xxs),
                      Text(
                        formatInstantDubaiLocalized(scheduled, locale),
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: context.spacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusChip(
                    label: technicianStatusLabel(l10n, job.status),
                    tone: technicianStatusTone(job.status),
                  ),
                  if (pending != null) ...[
                    SizedBox(height: context.spacing.xxs),
                    StatusChip(
                      label: pending!,
                      tone: StatusTone.warning,
                      icon: Icons.cloud_off,
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          AppCoverageBar(
            covered: job.completedItems,
            total: job.totalItems,
            label: l10n.technicianAssessmentProgress,
            valueLabel: formatCountPairLocalized(
              job.completedItems,
              total,
              locale,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final JobSummaryPage page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.spacing.sm,
      runSpacing: context.spacing.sm,
      children: [
        AppButton(
          label: l10n.technicianPreviousPage,
          variant: AppButtonVariant.tonal,
          onPressed: onPrevious,
        ),
        Text(
          l10n.technicianPageOf(page.page + 1, page.totalPages),
          style: context.texts.bodyMedium,
        ),
        AppButton(
          label: l10n.technicianNextPage,
          variant: AppButtonVariant.tonal,
          onPressed: onNext,
        ),
      ],
    );
  }
}

