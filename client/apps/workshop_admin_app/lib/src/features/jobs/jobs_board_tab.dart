import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_creation_wizard_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Job board: the client-visible inspection jobs with one search, one filter
/// row (All / Pending review / Approved / Published) and API pagination.
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

  bool get _filtersActive =>
      _status.isNotEmpty || _search.text.trim().isNotEmpty;

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
    final ws = context.ws;
    final spacing = context.spacing;
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);
    final counts = ref.watch(cleanJobCountsProvider);
    final jobs = ref.watch(cleanJobsProvider(_key));
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth - 2 * gutter >= jobWideRowMinWidth;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  gutter,
                  gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: WorkshopPageHeader(
                    title: l10n.jobsBoardTab,
                    subtitle: l10n.jobBoardSubtitle,
                    primaryAction: WorkshopButton(
                      label: l10n.newJob,
                      icon: Icons.add,
                      onPressed: _openCreate,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  spacing.lg,
                  gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: WorkshopToolbar(
                    search: WorkshopSearchField(
                      key: const Key('jobs-jobs-search'),
                      controller: _search,
                      hint: l10n.jobSearch,
                      semanticLabel: l10n.jobSearch,
                      onChanged: (_) => setState(() => _page = 0),
                    ),
                    filters: _filters(l10n, counts),
                  ),
                ),
              ),
              ..._contentSlivers(context, l10n, jobs, wide),
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  spacing.sm,
                  gutter,
                  spacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: jobs.maybeWhen(
                    data: (page) => _pagination(context, l10n, page),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _filters(
    AppLocalizations l10n,
    AsyncValue<CleanJobCounts> counts,
  ) {
    Widget chip(String value, String label, int? count) => WorkshopFilterChip(
      key: Key('jobs-filter-$value'),
      label: label,
      count: count,
      selected: _status == value,
      onTap: () => _selectStatus(value),
    );
    final data = counts.value;
    return [
      chip('', l10n.filterAll, data?.total),
      chip('PENDING_REVIEW', l10n.jobsCountPendingReview, data?.pendingReview),
      chip('APPROVED', l10n.jobsCountApproved, data?.approved),
      chip('PUBLISHED', l10n.jobsCountPublished, data?.published),
    ];
  }

  List<Widget> _contentSlivers(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<JobPage> jobs,
    bool wide,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);
    final padding = EdgeInsetsDirectional.fromSTEB(
      gutter,
      spacing.lg,
      gutter,
      0,
    );
    if (jobs.isLoading) {
      return [
        SliverPadding(
          padding: padding,
          sliver: const SliverToBoxAdapter(
            child: WorkshopSkeleton(card: true, lines: 6),
          ),
        ),
      ];
    }
    if (jobs.hasError) {
      return [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: WorkshopErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(cleanJobsProvider(_key)),
            ),
          ),
        ),
      ];
    }
    final page = jobs.value;
    if (page == null || page.items.isEmpty) {
      return [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: WorkshopCard(
              child: WorkshopEmptyState(
                title: _filtersActive
                    ? l10n.jobsEmptyQueueTitle
                    : l10n.jobsEmpty,
                body: _filtersActive ? l10n.jobsEmptyQueueBody : null,
                icon: Icons.work_outline,
              ),
            ),
          ),
        ),
      ];
    }
    if (wide) {
      return [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: WorkshopCard(
              padding: EdgeInsetsDirectional.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BoardHeader(),
                  const WorkshopDivider(),
                  for (var index = 0; index < page.items.length; index++) ...[
                    if (index > 0) const WorkshopDivider(),
                    _BoardRow(
                      key: Key('jobs-job-${page.items[index].id}'),
                      job: page.items[index],
                      onTap: () => _openDetails(page.items[index]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: padding,
        sliver: SliverList.separated(
          itemCount: page.items.length,
          separatorBuilder: (_, _) => SizedBox(height: spacing.md),
          itemBuilder: (context, index) {
            final job = page.items[index];
            return _BoardRow(
              key: Key('jobs-job-${job.id}'),
              job: job,
              onTap: () => _openDetails(job),
            );
          },
        ),
      ),
    ];
  }

  Widget _pagination(
    BuildContext context,
    AppLocalizations l10n,
    JobPage page,
  ) {
    if (page.totalPages <= 1) {
      return const SizedBox.shrink();
    }
    final spacing = context.spacing;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: spacing.md,
      runSpacing: spacing.sm,
      children: [
        WorkshopButton(
          label: l10n.commonPrevious,
          icon: rtl ? Icons.chevron_right : Icons.chevron_left,
          variant: WorkshopButtonVariant.secondary,
          onPressed: page.page <= 0
              ? null
              : () => setState(() => _page = page.page - 1),
        ),
        Text(
          '${l10n.commonPage} ${formatNumber(context, page.page + 1)} '
          '${l10n.commonOf} ${formatNumber(context, page.totalPages)}',
          style: context.ws.body.copyWith(color: context.ws.ink),
        ),
        WorkshopButton(
          label: l10n.commonNext,
          icon: rtl ? Icons.chevron_left : Icons.chevron_right,
          variant: WorkshopButtonVariant.secondary,
          onPressed: page.page + 1 >= page.totalPages
              ? null
              : () => setState(() => _page = page.page + 1),
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
      MaterialPageRoute<void>(builder: (_) => JobDetailPage(jobId: job.id)),
    );
    if (mounted) {
      ref.invalidate(cleanJobsProvider(_key));
      ref.invalidate(cleanJobCountsProvider);
    }
  }
}

class _BoardHeader extends StatelessWidget {
  const _BoardHeader();

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final style = ws.eyebrow.copyWith(color: ws.muted);
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.cardPadding,
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          _BoardHeaderCell(
            flex: 3,
            label: l10n.jobsListColumnVehicle,
            style: style,
          ),
          _BoardHeaderCell(
            flex: 3,
            label: l10n.jobsListColumnJob,
            style: style,
          ),
          _BoardHeaderCell(
            flex: 2,
            label: l10n.jobsListColumnCustomer,
            style: style,
          ),
          _BoardHeaderCell(
            flex: 2,
            label: l10n.jobsListColumnScheduled,
            style: style,
          ),
          _BoardHeaderCell(
            flex: 2,
            label: l10n.status,
            style: style,
            last: true,
          ),
          SizedBox(width: context.spacing.xl, height: context.spacing.xl),
        ],
      ),
    );
  }
}

class _BoardHeaderCell extends StatelessWidget {
  const _BoardHeaderCell({
    required this.flex,
    required this.label,
    required this.style,
    this.last = false,
  });

  final int flex;
  final String label;
  final TextStyle style;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: last ? 0 : context.spacing.md),
        child: Text(label, style: style, maxLines: 2),
      ),
    );
  }
}

/// One client-visible job: table row on wide layouts, stacked card on phones.
class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.job, required this.onTap, super.key});

  final CleanJob job;
  final VoidCallback onTap;

  String _vehicleTitle(BuildContext context) {
    final title = '${job.vehicleMake} ${job.vehicleModel}'.trim();
    return title.isEmpty ? job.customerName : title;
  }

  String _vehicleMeta() {
    final parts = <String>[
      if (job.vehicleYear != null) '${job.vehicleYear}',
      if ((job.vehiclePlate ?? '').trim().isNotEmpty) job.vehiclePlate!.trim(),
      if ((job.vehicleVin ?? '').trim().isNotEmpty) job.vehicleVin!.trim(),
    ];
    return parts.join(' · ');
  }

  String _schedule(BuildContext context) {
    final label = formatInstant(context, job.scheduledAt);
    return label.isEmpty
        ? AppLocalizations.of(context).commonNotAvailable
        : label;
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final meta = _vehicleMeta();
    final title = _vehicleTitle(context);
    final schedule = _schedule(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final templateLabel = localizedText(
      context,
      en: job.templateNameEn,
      ar: job.templateNameAr,
    );
    final label = [
      title,
      job.reference,
      job.customerName,
    ].where((value) => value.trim().isNotEmpty).join(', ');
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final wide =
            constraints.maxWidth >= jobWideRowMinWidth && textScale <= 1.35;
        final content = wide
            ? _row(ws, spacing, meta, title, schedule, rtl)
            : _stacked(ws, l10n, spacing, meta, title, schedule, templateLabel);
        if (!wide) {
          return WorkshopCard(
            onTap: onTap,
            semanticLabel: label,
            child: content,
          );
        }
        return Semantics(
          button: true,
          label: label,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(ws.chipRadius),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ws.cardPadding,
                  vertical: spacing.md,
                ),
                child: ExcludeSemantics(child: content),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _row(
    WorkshopTokens ws,
    AppSpacingTokens spacing,
    String meta,
    String title,
    String schedule,
    bool rtl,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  style: ws.bodyStrong.copyWith(color: ws.ink),
                ),
                if (meta.isNotEmpty) ...[
                  SizedBox(height: spacing.xxs),
                  Text(
                    meta,
                    maxLines: 2,
                    textDirection: TextDirection.ltr,
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: spacing.md),
            child: Text(
              job.reference,
              maxLines: 1,
              softWrap: false,
              textDirection: TextDirection.ltr,
              style: ws.body.copyWith(color: ws.ink),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: spacing.md),
            child: Text(
              job.customerName,
              maxLines: 2,
              style: ws.body.copyWith(color: ws.ink),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: spacing.md),
            child: Text(
              schedule,
              maxLines: 2,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: JobStatusBadge(status: job.status),
          ),
        ),
        SizedBox(width: spacing.lg),
        Icon(
          rtl ? Icons.chevron_left : Icons.chevron_right,
          size: 18,
          color: ws.muted,
        ),
      ],
    );
  }

  Widget _stacked(
    WorkshopTokens ws,
    AppLocalizations l10n,
    AppSpacingTokens spacing,
    String meta,
    String title,
    String schedule,
    String templateLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    style: ws.bodyStrong.copyWith(color: ws.ink),
                  ),
                  if (meta.isNotEmpty) ...[
                    SizedBox(height: spacing.xxs),
                    Text(
                      meta,
                      maxLines: 2,
                      textDirection: TextDirection.ltr,
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: spacing.sm),
            Flexible(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: JobStatusBadge(status: job.status),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.md,
          runSpacing: spacing.xs,
          children: [
            JobMetaLine(
              icon: Icons.confirmation_number_outlined,
              text: job.reference,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              softWrap: false,
            ),
            JobMetaLine(icon: Icons.person_outline, text: job.customerName),
          ],
        ),
        SizedBox(height: spacing.xs),
        Wrap(
          spacing: spacing.md,
          runSpacing: spacing.xs,
          children: [
            JobMetaLine(icon: Icons.schedule, text: schedule),
            JobMetaLine(
              icon: Icons.engineering_outlined,
              text: job.assignedTechnicianName ?? l10n.unassigned,
            ),
            JobMetaLine(icon: Icons.assignment_outlined, text: templateLabel),
          ],
        ),
      ],
    );
  }
}
