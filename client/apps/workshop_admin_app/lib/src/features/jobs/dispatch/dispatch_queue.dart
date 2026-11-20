import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_actions.dart';
import 'package:workshop_admin_app/src/workshop_clock.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// The jobs module front door: one table surface, pill filters, one row per job.
///
/// Same data path as before — `cleanJobsProvider` for the page and
/// `cleanJobCountsProvider` for the filter counts — and the same navigation and
/// mutations, delegated to [JobsQueueActions] so no behaviour is re-implemented.
class DispatchQueuePage extends ConsumerStatefulWidget {
  const DispatchQueuePage({super.key});

  @override
  ConsumerState<DispatchQueuePage> createState() => _DispatchQueuePageState();
}

class _DispatchQueuePageState extends ConsumerState<DispatchQueuePage> {
  static const _size = 20;
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _status = '';
  int _page = 0;
  String? _banner;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  String get _key =>
      cleanJobsKey(page: _page, size: _size, status: _status, search: _query);

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _query = value.trim();
          _page = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1000;
    final jobs = ref.watch(cleanJobsProvider(_key));
    final counts = ref.watch(cleanJobCountsProvider).value;
    final stages = _filterStages(ref.watch(statusesProvider('job')).value);
    final actions = JobsQueueActions(
      context: context,
      ref: ref,
      onRefresh: () => setState(() {}),
      onConflict: (message) => setState(() => _banner = message),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: ws.pagePadding(constraints.maxWidth),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t(WorkshopAdminKeys.jobsTab),
                              style: ws.pageTitle.copyWith(
                                fontSize: width < 520 ? 26 : 30,
                                letterSpacing: -0.6,
                                color: ws.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t(WorkshopAdminKeys.jobsQueueSubtitle),
                              style: ws.meta.copyWith(color: ws.muted),
                            ),
                          ],
                        ),
                      ),
                      JobPillButton(
                        label: t(WorkshopAdminKeys.newJob),
                        icon: Icons.add,
                        onPressed: actions.openCreate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: WorkshopSearchField(
                        key: const Key('jobs-search'),
                        controller: _search,
                        hint: t(WorkshopAdminKeys.search),
                        semanticLabel: t(WorkshopAdminKeys.search),
                        onChanged: _onSearch,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        JobPillChip(
                          label: t(WorkshopAdminKeys.filterAll),
                          count: counts?.total,
                          selected: _status.isEmpty,
                          onTap: () => _select(''),
                        ),
                        const SizedBox(width: 8),
                        for (final stage in stages) ...[
                          JobPillChip(
                            label: stage.label,
                            count: _countFor(counts, stage.code),
                            selected: _status == stage.code,
                            onTap: () => _select(stage.code),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  if (_banner != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ws.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _banner!,
                        style: ws.meta.copyWith(color: ws.danger),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  jobs.when(
                    loading: () => const _QueueSkeleton(),
                    error: (error, _) => _QueueError(
                      onRetry: () => ref.invalidate(cleanJobsProvider(_key)),
                    ),
                    data: (page) => page.items.isEmpty
                        ? _QueueEmpty(
                            onCreate: actions.openCreate,
                            filtered: _status.isNotEmpty || _query.isNotEmpty,
                            onClear: () => setState(() {
                              _search.clear();
                              _query = '';
                              _status = '';
                              _page = 0;
                            }),
                          )
                        : _table(page, actions, wide),
                  ),
                  if (jobs.value != null && jobs.value!.totalPages > 1) ...[
                    const SizedBox(height: 14),
                    _pager(jobs.value!),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const _fallbackStages = <String>[
    'DRAFT',
    'SCHEDULED',
    'ASSIGNED',
    'IN_PROGRESS',
    'PENDING_REVIEW',
    'APPROVED',
    'PUBLISHED',
  ];

  List<({String code, String label})> _filterStages(
    List<ReferenceRecord>? records,
  ) {
    if (records == null || records.isEmpty) {
      return <({String code, String label})>[
        for (final code in _fallbackStages)
          (code: code, label: humanizeReferenceCode(code)),
      ];
    }
    final stages = <({String code, String label})>[];
    for (final record in records) {
      if (!record.selectable) continue;
      if (record.visibleFor.isNotEmpty &&
          !record.visibleFor.contains('queue') &&
          !record.visibleFor.contains('job')) {
        continue;
      }
      stages.add((
        code: record.code,
        label: referenceLabelFor(record) ?? humanizeReferenceCode(record.code),
      ));
    }
    if (stages.isEmpty) {
      return <({String code, String label})>[
        for (final code in _fallbackStages)
          (code: code, label: humanizeReferenceCode(code)),
      ];
    }
    return stages;
  }

  int? _countFor(CleanJobCounts? counts, String status) {
    if (counts == null) {
      return null;
    }
    return switch (status) {
      'DRAFT' => counts.draft,
      'SCHEDULED' => counts.scheduled,
      'ASSIGNED' => counts.assigned,
      'IN_PROGRESS' => counts.inProgress,
      'PENDING_REVIEW' => counts.pendingReview,
      'APPROVED' => counts.approved,
      'PUBLISHED' => counts.published,
      _ => null,
    };
  }

  void _select(String status) {
    if (_status == status) {
      return;
    }
    setState(() {
      _status = status;
      _page = 0;
    });
  }

  Widget _table(JobPage page, JobsQueueActions actions, bool wide) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Container(
              color: ws.canvas,
              padding: const EdgeInsetsDirectional.fromSTEB(18, 9, 18, 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: _head(context, t(WorkshopAdminKeys.jobsReference)),
                  ),
                  Expanded(
                    child: _head(context, t(WorkshopAdminKeys.jobsCustomer)),
                  ),
                  Expanded(
                    child: _head(context, t(WorkshopAdminKeys.jobsVehicle)),
                  ),
                  SizedBox(
                    width: 132,
                    child: _head(context, t(WorkshopAdminKeys.jobsTechnician)),
                  ),
                  SizedBox(
                    width: 140,
                    child: _head(context, t(WorkshopAdminKeys.status)),
                  ),
                  SizedBox(
                    width: 132,
                    child: _head(
                      context,
                      t(WorkshopAdminKeys.scheduledAt),
                      end: true,
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < page.items.length; i++) ...[
            if (i > 0 || wide) Container(height: 1, color: ws.border),
            _row(page.items[i], actions, wide),
          ],
        ],
      ),
    );
  }

  Widget _head(BuildContext context, String label, {bool end = false}) => Text(
    label.toUpperCase(),
    textAlign: end ? TextAlign.end : TextAlign.start,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: context.ws.eyebrow.copyWith(color: context.ws.muted),
  );

  Widget _row(CleanJob job, JobsQueueActions actions, bool wide) {
    final ws = context.ws;
    final scheduled = WorkshopClock.formatInstant(context, job.scheduledAt);
    final vehicle = [
      [job.vehicleMake, job.vehicleModel].where((v) => v.isNotEmpty).join(' '),
      if (job.vehicleYear != null) '${job.vehicleYear}',
      if ((job.vehiclePlate ?? '').isNotEmpty) job.vehiclePlate!,
    ].join(' - ');
    return _HoverRow(
      key: Key('job-${job.id}'),
      onTap: () => actions.openDetail(job),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 13, 18, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: wide ? 92 : null,
              child: wide
                  ? Text(
                      job.reference,
                      style: ws.meta.copyWith(
                        color: ws.ink,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  : Row(
                      children: [
                        const JobGlyph(),
                        const SizedBox(width: 12),
                        Text(
                          job.reference,
                          style: ws.meta.copyWith(
                            color: ws.muted,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
            ),
            if (!wide) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ws.body.copyWith(
                      color: ws.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!wide) ...[
                    const SizedBox(height: 2),
                    Text(
                      vehicle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                  if (!wide) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        JobStatusPill(status: job.status),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            scheduled.isEmpty ? '—' : scheduled,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ws.meta.copyWith(color: ws.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (wide) ...[
              Expanded(
                child: Text(
                  vehicle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ),
              SizedBox(
                width: 132,
                child: Text(
                  job.assignedTechnicianName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.meta.copyWith(color: ws.ink),
                ),
              ),
              SizedBox(
                width: 140,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: JobStatusPill(status: job.status),
                ),
              ),
              SizedBox(
                width: 132,
                child: Text(
                  scheduled.isEmpty ? '—' : scheduled,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: ws.muted),
          ],
        ),
      ),
    );
  }

  Widget _pager(JobPage page) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    return Row(
      children: [
        Text(
          '${t(WorkshopAdminKeys.commonPage)} ${page.page + 1} ${t(WorkshopAdminKeys.commonOf)} ${page.totalPages}',
          style: ws.meta.copyWith(color: ws.muted),
        ),
        const Spacer(),
        JobPillButton(
          label: t(WorkshopAdminKeys.commonPrevious),
          icon: Icons.arrow_back,
          variant: JobPillVariant.outline,
          compact: true,
          onPressed: page.page == 0
              ? null
              : () => setState(() => _page = page.page - 1),
        ),
        const SizedBox(width: 8),
        JobPillButton(
          label: t(WorkshopAdminKeys.commonNext),
          icon: Icons.arrow_forward,
          variant: JobPillVariant.outline,
          compact: true,
          onPressed: page.page >= page.totalPages - 1
              ? null
              : () => setState(() => _page = page.page + 1),
        ),
      ],
    );
  }
}

class _HoverRow extends StatefulWidget {
  const _HoverRow({super.key, required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: ColoredBox(
          color: _hover ? context.ws.canvas : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

class _QueueSkeleton extends StatefulWidget {
  const _QueueSkeleton();

  @override
  State<_QueueSkeleton> createState() => _QueueSkeletonState();
}

class _QueueSkeletonState extends State<_QueueSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulse.duration = const Duration(milliseconds: 1100);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 0.55;
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: ws.border,
        borderRadius: BorderRadius.circular(h / 2),
      ),
    );
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.42,
        end: 0.95,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: Container(
        decoration: BoxDecoration(
          color: ws.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ws.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < 6; i++)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
                child: Row(
                  children: [
                    bar(64, 12),
                    const SizedBox(width: 18),
                    Expanded(child: bar(180, 12)),
                    bar(90, 22),
                    const SizedBox(width: 18),
                    bar(80, 12),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QueueError extends StatelessWidget {
  const _QueueError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 30, 22, 30),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.priority_high_rounded, size: 20, color: ws.danger),
          const SizedBox(height: 10),
          Text(
            t(WorkshopAdminKeys.error),
            style: ws.sectionTitle.copyWith(color: ws.ink),
          ),
          const SizedBox(height: 6),
          Text(
            t(WorkshopAdminKeys.commonLoadFailed),
            style: ws.body.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 14),
          JobPillButton(
            label: t(WorkshopAdminKeys.retryAction),
            icon: Icons.refresh,
            variant: JobPillVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty({
    required this.onCreate,
    required this.filtered,
    required this.onClear,
  });

  final VoidCallback onCreate;
  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 40, 24, 40),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        children: [
          const JobGlyph(size: 52),
          const SizedBox(height: 16),
          Text(
            filtered
                ? t(WorkshopAdminKeys.jobsNoJobsInView)
                : t(WorkshopAdminKeys.jobsEmptyFirstUseTitle),
            textAlign: TextAlign.center,
            style: ws.sectionTitle.copyWith(color: ws.ink),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? t(WorkshopAdminKeys.noResults)
                : t(WorkshopAdminKeys.jobsEmptyFirstUseBody),
            textAlign: TextAlign.center,
            style: ws.body.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 18),
          JobPillButton(
            label: filtered
                ? t(WorkshopAdminKeys.jobsClearFilters)
                : t(WorkshopAdminKeys.jobsCreateCta),
            icon: filtered ? null : Icons.add,
            onPressed: filtered ? onClear : onCreate,
          ),
        ],
      ),
    );
  }
}
