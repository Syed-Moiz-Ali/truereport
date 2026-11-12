import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_creation_wizard_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Jobs board: counts, filters, search and a paginated API-backed list.
class JobsBoardTab extends ConsumerStatefulWidget {
  const JobsBoardTab({super.key});

  @override
  ConsumerState<JobsBoardTab> createState() => _JobsBoardTabState();
}

class _JobsBoardTabState extends ConsumerState<JobsBoardTab> {
  final _search = TextEditingController();
  String _status = '';
  int _page = 0;
  final int _pageSize = 10;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _key => cleanJobsKey(
    page: _page,
    size: _pageSize,
    status: _status,
    search: _search.text,
  );

  void _selectStatus(String status) {
    setState(() {
      _status = status;
      _page = 0;
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(cleanJobsProvider(_key));
    ref.invalidate(cleanJobCountsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = ref.watch(cleanJobCountsProvider);
    final jobs = ref.watch(cleanJobsProvider(_key));
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              context.spacing.lg,
              context.spacing.lg,
              context.spacing.lg,
              context.spacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: WorkshopHeader(
                title: l10n.jobsBoardTab,
                semanticLabel: l10n.jobsBoardTab,
                search: AppTextField(
                  key: const Key('jobs-jobs-search'),
                  controller: _search,
                  label: l10n.jobSearch,
                  hint: l10n.jobSearch,
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (_) => setState(() => _page = 0),
                ),
                actions: [
                  AppButton(
                    label: l10n.newJob,
                    onPressed: _openCreate,
                    icon: Icons.add,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: context.spacing.lg,
              vertical: context.spacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: counts.when(
                loading: () => const LoadingSkeleton(lines: 3),
                error: (error, _) => ErrorState(
                  title: l10n.error,
                  body: l10n.commonLoadFailed,
                  retryLabel: l10n.retryAction,
                  onRetry: () => ref.invalidate(cleanJobCountsProvider),
                ),
                data: (value) => _CountGrid(counts: value),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: context.spacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: [
                  _filter(l10n.filterAll, '', counts),
                  _filter(l10n.jobsCountDraft, 'DRAFT', counts),
                  _filter(l10n.jobsCountScheduled, 'SCHEDULED', counts),
                  _filter(l10n.jobsCountAssigned, 'ASSIGNED', counts),
                  _filter(l10n.jobsCountInProgress, 'IN_PROGRESS', counts),
                  _filter(
                    l10n.jobsCountPendingReview,
                    'PENDING_REVIEW',
                    counts,
                  ),
                  _filter(l10n.jobsCountApproved, 'APPROVED', counts),
                  _filter(l10n.jobsCountPublished, 'PUBLISHED', counts),
                  _filter(l10n.jobsCountRejected, 'REJECTED', counts),
                  _filter(l10n.jobsCountCancelled, 'CANCELLED', counts),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              context.spacing.lg,
              context.spacing.md,
              context.spacing.lg,
              context.spacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(title: l10n.jobsCountsTitle),
            ),
          ),
          ...jobs.when(
            loading: () => [
              SliverPadding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: context.spacing.lg,
                ),
                sliver: const SliverToBoxAdapter(
                  child: LoadingSkeleton(lines: 4),
                ),
              ),
            ],
            error: (error, _) => [
              SliverPadding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: context.spacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: ErrorState(
                    title: l10n.error,
                    body: l10n.commonLoadFailed,
                    retryLabel: l10n.retryAction,
                    onRetry: () => ref.invalidate(cleanJobsProvider(_key)),
                  ),
                ),
              ),
            ],
            data: (page) => _jobSlivers(context, page),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              context.spacing.lg,
              context.spacing.sm,
              context.spacing.lg,
              context.spacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: jobs.maybeWhen(
                data: (page) => _pagination(context, page),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filter(String label, String value, AsyncValue<CleanJobCounts> counts) {
    final count = counts.maybeWhen(
      data: (data) => _countFor(data, value),
      orElse: () => null,
    );
    return AppSelectableText(
      key: Key('jobs-filter-$value'),
      label: count == null
          ? label
          : '$label (${formatNumber(context, count)})',
      selected: _status == value,
      onTap: () => _selectStatus(value),
    );
  }

  int _countFor(CleanJobCounts counts, String status) => switch (status) {
    'DRAFT' => counts.draft,
    'SCHEDULED' => counts.scheduled,
    'ASSIGNED' => counts.assigned,
    'IN_PROGRESS' => counts.inProgress,
    'PENDING_REVIEW' => counts.pendingReview,
    'APPROVED' => counts.approved,
    'PUBLISHED' => counts.published,
    'REJECTED' => counts.rejected,
    'CANCELLED' => counts.cancelled,
    _ => counts.total,
  };

  List<Widget> _jobSlivers(BuildContext context, JobPage page) {
    final l10n = AppLocalizations.of(context);
    if (page.items.isEmpty) {
      return [
        SliverPadding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          sliver: SliverToBoxAdapter(
            child: EmptyState(
              title: l10n.jobsEmpty,
              body: '',
              icon: Icons.search_off_outlined,
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.spacing.lg,
        ),
        sliver: SliverList.separated(
          itemCount: page.items.length,
          separatorBuilder: (_, _) => SizedBox(height: context.spacing.sm),
          itemBuilder: (context, index) {
            final job = page.items[index];
            final vehicle = '${job.vehicleMake} ${job.vehicleModel}'.trim();
            return WorkshopJobCard(
              key: Key('jobs-job-${job.id}'),
              title: vehicle.isEmpty
                  ? job.customerName
                  : localizedText(
                      context,
                      en: vehicle,
                      ar: vehicle,
                    ),
              reference: job.reference,
              status: StatusChip(
                label: jobStatusLabel(l10n, job.status),
                tone: jobStatusTone(job.status),
              ),
              meta: [
                Text(job.customerName),
                Text(
                  localizedText(
                    context,
                    en: job.templateNameEn,
                    ar: job.templateNameAr,
                  ),
                ),
                Text(job.assignedTechnicianName ?? l10n.unassigned),
              ],
              onTap: () => _openDetails(job),
            );
          },
        ),
      ),
    ];
  }

  Widget _pagination(BuildContext context, JobPage page) {
    final l10n = AppLocalizations.of(context);
    if (page.totalPages <= 1) {
      return const SizedBox.shrink();
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.spacing.md,
      runSpacing: context.spacing.sm,
      children: [
        AppButton(
          label: l10n.commonPrevious,
          onPressed: page.page <= 0
              ? null
              : () => setState(() => _page = page.page - 1),
          variant: AppButtonVariant.tonal,
          icon: Icons.chevron_left,
        ),
        Text(
          '${l10n.commonPage} ${formatNumber(context, page.page + 1)} '
          '${l10n.commonOf} ${formatNumber(context, page.totalPages)}',
          style: context.texts.bodyMedium,
        ),
        AppButton(
          label: l10n.commonNext,
          onPressed: page.page + 1 >= page.totalPages
              ? null
              : () => setState(() => _page = page.page + 1),
          variant: AppButtonVariant.tonal,
          icon: Icons.chevron_right,
        ),
      ],
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<CleanJob>(
      MaterialPageRoute<CleanJob>(
        builder: (_) => const JobCreationWizardPage(),
      ),
    );
    if (created == null || !mounted) {
      return;
    }
    ref.invalidate(cleanJobCountsProvider);
    ref.invalidate(cleanJobsProvider(_key));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).jobsCreated)),
    );
  }

  Future<void> _openDetails(CleanJob job) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => JobDetailPage(jobId: job.id),
      ),
    );
    if (mounted) {
      ref.invalidate(cleanJobsProvider(_key));
      ref.invalidate(cleanJobCountsProvider);
    }
  }
}

class _CountGrid extends StatelessWidget {
  const _CountGrid({required this.counts});

  final CleanJobCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = <Widget>[
      _card(context, l10n.jobsCountDraft, counts.draft, Icons.edit_note),
      _card(
        context,
        l10n.jobsCountScheduled,
        counts.scheduled,
        Icons.schedule_outlined,
      ),
      _card(
        context,
        l10n.jobsCountAssigned,
        counts.assigned,
        Icons.person_add_alt_1_outlined,
      ),
      _card(
        context,
        l10n.jobsCountInProgress,
        counts.inProgress,
        Icons.play_circle_outline,
      ),
      _card(
        context,
        l10n.jobsCountPendingReview,
        counts.pendingReview,
        Icons.rate_review_outlined,
      ),
      _card(
        context,
        l10n.jobsCountApproved,
        counts.approved,
        Icons.verified_outlined,
      ),
      _card(
        context,
        l10n.jobsCountPublished,
        counts.published,
        Icons.public_outlined,
      ),
      _card(
        context,
        l10n.jobsCountRejected,
        counts.rejected,
        Icons.block_outlined,
      ),
      _card(
        context,
        l10n.jobsCountCancelled,
        counts.cancelled,
        Icons.cancel_outlined,
      ),
      _card(
        context,
        l10n.jobsCountTotal,
        counts.total,
        Icons.work_outline,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 1200
            ? 4
            : maxWidth >= 900
            ? 3
            : maxWidth >= 600
            ? 2
            : 1;
        final gap = context.spacing.md;
        final width = (maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    String caption,
    int value,
    IconData icon,
  ) {
    return WorkshopStatCard(
      value: formatNumber(context, value),
      caption: caption,
      icon: icon,
    );
  }
}
