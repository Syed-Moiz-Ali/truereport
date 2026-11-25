import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../../inspection_models.dart';
import '../../reference_ui.dart';
import '../../technician_providers.dart';
import 'queue/deck/deck_board.dart';
import 'queue/deck/deck_facts.dart';
import 'queue/deck/deck_header.dart';
import 'queue/deck/deck_primary.dart';
import 'queue/deck/deck_sets.dart';
import 'queue/deck/deck_skeleton.dart';
import 'queue/deck/deck_tabs.dart';
import 'queue/jobs_queue_format.dart';
import 'queue/jobs_queue_primitives.dart';
import 'queue/jobs_queue_style.dart';
import 'queue/queue_model.dart';

/// The technician's ramp, presented as a deck: one front card with stacked
/// NEXT / THEN peeks behind it, a segmented set switcher above and a single
/// 56 px primary pinned in the thumb zone.
///
/// Presentation only. Routes, providers, the offline queue and the open-job
/// callback are exactly the jobs flow: tapping a card selects it, the primary
/// opens the existing job route.
class TechnicianJobsCleanPage extends ConsumerStatefulWidget {
  const TechnicianJobsCleanPage({super.key});

  @override
  ConsumerState<TechnicianJobsCleanPage> createState() =>
      _TechnicianJobsCleanPageState();
}

class _TechnicianJobsCleanPageState
    extends ConsumerState<TechnicianJobsCleanPage> {
  static const _pageSize = 50;

  final _search = TextEditingController();
  final _scroll = ScrollController();
  int _page = 0;
  String _status = '';
  bool _searchOpen = false;
  DeckTab _tab = DeckTab.today;
  String? _selectedJobId;

  @override
  void initState() {
    super.initState();
    _search.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_handleSearch)
      ..dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _handleSearch() => setState(() {});

  void _setTab(DeckTab tab) {
    setState(() => _tab = tab);
    _toTop();
  }

  void _selectJob(DeckJob job) => setState(() => _selectedJobId = job.id);

  void _seeAll() {
    _search.clear();
    setState(() => _tab = DeckTab.today);
    _toTop();
  }

  void _setStatus(String status) {
    setState(() {
      _status = status;
      _page = 0;
    });
    _toTop();
  }

  void _setPage(int page) {
    setState(() => _page = page);
    _toTop();
  }

  void _toTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      FocusScope.of(context).unfocus();
      _search.clear();
    }
  }

  TechnicianJobsQuery get _query =>
      (page: _page, size: _pageSize, status: _status.isEmpty ? null : _status);

  Future<void> _refresh() async {
    ref
      ..invalidate(technicianJobPageProvider)
      ..invalidate(syncQueueStatusProvider);
    await ref.read(technicianJobPageProvider(_query).future);
  }

  Future<void> _openFilters() async {
    final t = UiStrings.of(context);
    final statuses =
        ref.read(statusesProvider('job')).value ?? const <ReferenceRecord>[];
    await showAppBottomSheet<void>(
      context,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t(TechnicianKeys.technicianFilter),
              style: queueSection(context),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                QueueChip(
                  label: t(TechnicianKeys.filterAll),
                  selected: _status.isEmpty,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _setStatus('');
                  },
                ),
                for (final record in statuses.where(
                  (value) => value.selectable,
                ))
                  QueueChip(
                    label: referenceStatusCodeLabel(statuses, record.code),
                    selected: _status == record.code,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _setStatus(record.code);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value != true) {
        ref.read(syncServiceProvider).syncAll().then((_) {
          ref.invalidate(syncQueueStatusProvider);
          ref.invalidate(pendingOperationsProvider);
          ref.invalidate(technicianJobPageProvider);
        });
      }
    });
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final pageAsync = ref.watch(technicianJobPageProvider(_query));
    final sync = ref.watch(syncQueueStatusProvider).asData?.value;
    ref.watch(statusesProvider('job'));
    final online = ref.watch(connectivityProvider).value ?? true;
    final session = ref.watch(authControllerProvider).value;
    final name = session?.user.displayName ?? t(TechnicianKeys.roleTechnician);
    final waiting = (sync?.pending ?? 0) + (sync?.failed ?? 0);
    final conflicts = sync?.conflicts ?? 0;
    final todayKey = queueTodayKey(now);
    final term = _search.text.trim().toLowerCase();
    final data = pageAsync.asData?.value;
    final searched = data == null
        ? const <JobSummary>[]
        : data.items.where((job) => _matches(job, term)).toList();
    final filtered = _filterStatus(searched);
    final buckets = bucketDeckSets(filtered, todayKey);
    final summary = data == null
        ? const _Summary(toStart: 0, inProgress: 0)
        : _summarize(data.items);

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: Column(
        children: [
          _Centered(
            maxWidth: wide ? 1120 : 560,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 2),
            child: DeckHeader(
              toStart: summary.toStart,
              inProgress: summary.inProgress,
              technicianName: name,
              onProfile: () => context.push('/profile'),
            ),
          ),
          _Centered(
            maxWidth: wide ? 1120 : 560,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
            child: DeckTabs(
              today: buckets.today.length,
              upcoming: buckets.upcoming.length,
              unfinished: buckets.unfinished.length,
              selected: _tab,
              onSelect: _setTab,
            ),
          ),
          _Centered(
            maxWidth: wide ? 1120 : 560,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
            child: _Toolbar(
              searchOpen: _searchOpen,
              filterActive: _status.isNotEmpty,
              statusLabel: _status.isEmpty
                  ? null
                  : jobStatusLabel(ref, _status),
              onSearch: _toggleSearch,
              onFilter: _openFilters,
              onClearStatus: () => _setStatus(''),
            ),
          ),
          if (_searchOpen)
            _Centered(
              maxWidth: wide ? 1120 : 560,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 6),
              child: QueueSearchField(
                controller: _search,
                autofocus: true,
                hint: t(TechnicianKeys.technicianJobSearchHint),
                onChanged: (_) => setState(() {}),
                onClear: () {
                  _search.clear();
                  setState(() {});
                },
              ),
            ),
          Expanded(
            child: _buildScroll(
              context: context,
              wide: wide,
              pageAsync: pageAsync,
              buckets: buckets,
              filtered: filtered,
              searchedEmpty: searched.isEmpty && term.isNotEmpty,
              pageEmpty: data != null && data.items.isEmpty,
              online: online,
              waiting: waiting,
              conflicts: conflicts,
              t: t,
              locale: locale,
              now: now,
            ),
          ),
          if (!wide)
            _PinnedPrimary(
              buckets: buckets,
              tab: _tab,
              selectedJobId: _selectedJobId,
              onOpen: (job) => context.push('/jobs/${job.id}'),
            ),
        ],
      ),
    );
  }

  Widget _buildScroll({
    required BuildContext context,
    required bool wide,
    required AsyncValue<JobSummaryPage> pageAsync,
    required DeckSets buckets,
    required List<JobSummary> filtered,
    required bool searchedEmpty,
    required bool pageEmpty,
    required bool online,
    required int waiting,
    required int conflicts,
    required UiStrings t,
    required String locale,
    required DateTime now,
  }) {
    return RefreshIndicator(
      color: context.brand.ink,
      backgroundColor: context.colors.surface,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.fromSTEB(
          wide ? 24 : 16,
          8,
          wide ? 24 : 16,
          28,
        ),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 1120 : 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!online) ...[
                  QueueNote(
                    icon: Icons.cloud_off_rounded,
                    label: t(TechnicianKeys.offlineBanner),
                    tone: StatusTone.warning,
                  ),
                  const SizedBox(height: 12),
                ],
                if (waiting > 0 || conflicts > 0) ...[
                  _SyncStrip(
                    waiting: waiting,
                    conflicts: conflicts,
                    onSync: () => context.push('/sync'),
                  ),
                  const SizedBox(height: 12),
                ],
                AnimatedSwitcher(
                  duration: context.motionDuration(
                    const Duration(milliseconds: 180),
                  ),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: pageAsync.when(
                    loading: () =>
                        const DeckSkeleton(key: ValueKey('queue-loading')),
                    error: (error, _) => QueueErrorPanel(
                      key: const ValueKey('queue-error'),
                      title: t(TechnicianKeys.error),
                      body: t(TechnicianKeys.genericError),
                      retryLabel: t(TechnicianKeys.retryAction),
                      onRetry: () => _refresh(),
                    ),
                    data: (page) {
                      if (pageEmpty) {
                        return QueueEmptyPanel(
                          key: const ValueKey('queue-empty'),
                          title: t(TechnicianKeys.technicianAllCaughtUp),
                          body: t(TechnicianKeys.technicianJobListEmpty),
                          action: QueueButton(
                            label: t(TechnicianKeys.technicianRefresh),
                            variant: QueueButtonVariant.soft,
                            icon: Icons.refresh_rounded,
                            onPressed: _refresh,
                          ),
                        );
                      }
                      if (searchedEmpty) {
                        return QueueEmptyPanel(
                          key: const ValueKey('queue-no-results'),
                          showRoute: false,
                          title: t(TechnicianKeys.noResults),
                          body: t(TechnicianKeys.technicianNoSearchResults),
                          action: QueueButton(
                            label: t(TechnicianKeys.technicianClear),
                            variant: QueueButtonVariant.soft,
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          ),
                        );
                      }
                      final ordered = orderDeckJobs(buckets.forTab(_tab));
                      if (ordered.isEmpty) {
                        return _bucketEmpty(
                          t: t,
                          locale: locale,
                          now: now,
                          jobs: filtered,
                        );
                      }
                      final frontId = deckFrontId(ordered, _selectedJobId);
                      final deck = _deckJobs(
                        ordered,
                        ref,
                        frontId,
                        _nextUpLabel(ordered, frontId),
                      );
                      if (!wide) {
                        return Column(
                          key: ValueKey('deck-${_tab.name}'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DeckBoard(
                              jobs: deck,
                              frontId: frontId,
                              onSelect: _selectJob,
                            ),
                            const SizedBox(height: 4),
                            Center(child: DeckSeeAllLink(onTap: _seeAll)),
                            if (page.totalPages > 1) ...[
                              const SizedBox(height: 12),
                              _Pager(page: page, onPage: _setPage),
                            ],
                          ],
                        );
                      }
                      final front = ordered.firstWhere(
                        (job) => job.id == frontId,
                        orElse: () => ordered.first,
                      );
                      return Column(
                        key: ValueKey('deck-wide-${_tab.name}'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DeckBoard(
                                      jobs: deck,
                                      frontId: front.id,
                                      onSelect: _selectJob,
                                    ),
                                    const SizedBox(height: 4),
                                    Center(
                                      child: DeckSeeAllLink(onTap: _seeAll),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: DeckFactsPane(
                                  job: deck.firstWhere(
                                    (job) => job.id == front.id,
                                  ),
                                  scheduleLabel: _scheduleLabel(
                                    front,
                                    t,
                                    locale,
                                    now,
                                  ),
                                  onOpen: () =>
                                      context.push('/jobs/${front.id}'),
                                ),
                              ),
                            ],
                          ),
                          if (page.totalPages > 1) ...[
                            const SizedBox(height: 16),
                            _Pager(page: page, onPage: _setPage),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bucketEmpty({
    required UiStrings t,
    required String locale,
    required DateTime now,
    required List<JobSummary> jobs,
  }) {
    if (_tab == DeckTab.today) {
      final nearest = nearestDayWithWork(jobs, now: now);
      final nearestLabel = nearest == null
          ? null
          : queueDayLabel(nearest, t, locale, now: now);
      return QueueEmptyPanel(
        key: const ValueKey('queue-empty-today'),
        showRoute: false,
        title: t(TechnicianKeys.technicianRampNothingToday),
        body: nearestLabel == null
            ? t(TechnicianKeys.technicianNoJobsThisDay)
            : t(TechnicianKeys.technicianRampNothingTodayBody, {
                'date': nearestLabel,
              }),
      );
    }
    return QueueEmptyPanel(
      key: ValueKey('queue-empty-${_tab.name}'),
      showRoute: false,
      title: t(TechnicianKeys.technicianNoJobsThisDay),
      body: t(TechnicianKeys.technicianPickAnotherDay),
    );
  }

  /// The front card's next checklist item, or null while it loads, when the
  /// job has no items left, or when the checklist is unavailable offline.
  String? _nextUpLabel(List<JobSummary> ordered, String frontId) {
    if (ordered.isEmpty) {
      return null;
    }
    final checklist = ref
        .watch(technicianChecklistProvider(frontId))
        .asData
        ?.value;
    if (checklist == null) {
      return null;
    }
    final language = Localizations.localeOf(context).languageCode;
    for (final item in checklist.items) {
      if (item.assessment?.resultCode == null) {
        // LTR isolate: the "10. label" order holds in RTL locales instead of
        // flipping to "label .10" under the surrounding paragraph direction.
        return '\u2066${item.sortOrder}. ${item.labelFor(language)}\u2069';
      }
    }
    return null;
  }

  List<DeckJob> _deckJobs(
    List<JobSummary> ordered,
    WidgetRef ref,
    String frontId,
    String? nextUp,
  ) {
    return [
      for (final job in ordered)
        DeckJob(
          id: job.id,
          vehicle: queueVehicleLabel(job),
          plate: (job.vehiclePlate ?? '').trim(),
          customer: job.customerName,
          reference: job.reference,
          time: queueSlotLabel(job),
          statusLabel: jobStatusLabel(ref, job.status),
          tone: jobStatusTone(ref, job.status),
          done: job.completedItems,
          total: job.totalItems,
          verb: verbFor(job),
          nextUp: job.id == frontId ? nextUp : null,
        ),
    ];
  }

  String _scheduleLabel(
    JobSummary job,
    UiStrings t,
    String locale,
    DateTime now,
  ) {
    final day = queueDayKey(job);
    final dayLabel = queueDayLabel(day, t, locale, now: now);
    final time = queueSlotLabel(job);
    return time.isEmpty ? dayLabel : '$dayLabel · $time';
  }

  List<JobSummary> _filterStatus(List<JobSummary> jobs) {
    final selected = normalizeStatusCode(_status);
    if (selected.isEmpty) {
      return jobs;
    }
    return jobs
        .where((job) => normalizeStatusCode(job.status) == selected)
        .toList(growable: false);
  }

  _Summary _summarize(List<JobSummary> jobs) {
    var toStart = 0;
    var inProgress = 0;
    for (final job in jobs) {
      if (isCancelledJob(job)) {
        continue;
      }
      switch (verbFor(job)) {
        case QueueVerb.start:
          toStart += 1;
        case QueueVerb.continueJob:
        case QueueVerb.finish:
          inProgress += 1;
        case QueueVerb.view:
          break;
      }
    }
    return _Summary(toStart: toStart, inProgress: inProgress);
  }

  bool _matches(JobSummary job, String term) {
    if (term.isEmpty) {
      return true;
    }
    final haystack = [
      job.reference,
      job.customerName,
      job.vehicleMake,
      job.vehicleModel,
      job.vehiclePlate ?? '',
      job.vehicleVin ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(term);
  }
}

class _Summary {
  const _Summary({required this.toStart, required this.inProgress});

  final int toStart;
  final int inProgress;
}

String _primaryLabel(UiStrings t, QueueVerb verb) {
  switch (verb) {
    case QueueVerb.start:
      return t(TechnicianKeys.startInspection);
    case QueueVerb.continueJob:
      return t(TechnicianKeys.technicianDeckContinueAction);
    case QueueVerb.finish:
      return t(TechnicianKeys.technicianDeckFinishJob);
    case QueueVerb.view:
      return t(TechnicianKeys.technicianQueueActionView);
  }
}

/// Slim toolbar under the tabs: search toggle, filter, and the active status.
/// Behaviour matches the previous jobs list; only the presentation changed.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchOpen,
    required this.filterActive,
    required this.statusLabel,
    required this.onSearch,
    required this.onFilter,
    required this.onClearStatus,
  });

  final bool searchOpen;
  final bool filterActive;
  final String? statusLabel;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onClearStatus;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final status = statusLabel;
    return Row(
      children: [
        _ToolIcon(
          icon: searchOpen ? Icons.close_rounded : Icons.search_rounded,
          label: t(TechnicianKeys.technicianJobSearchHint),
          onPressed: onSearch,
        ),
        const SizedBox(width: 8),
        _ToolIcon(
          icon: Icons.tune_rounded,
          label: t(TechnicianKeys.technicianFilter),
          active: filterActive,
          onPressed: onFilter,
        ),
        if (status != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: QueueChip(
                label: status,
                selected: true,
                onPressed: onClearStatus,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.surfaceLowest,
              shape: BoxShape.circle,
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: colors.onSurfaceVariant),
                if (active)
                  PositionedDirectional(
                    top: 9,
                    end: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: context.brand.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surfaceLowest),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The pinned 56 px primary for narrow widths. Wide layouts carry the action
/// in the facts pane instead, so there is exactly one primary per screen.
class _PinnedPrimary extends ConsumerWidget {
  const _PinnedPrimary({
    required this.buckets,
    required this.tab,
    required this.selectedJobId,
    required this.onOpen,
  });

  final DeckSets buckets;
  final DeckTab tab;
  final String? selectedJobId;
  final ValueChanged<JobSummary> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final ordered = orderDeckJobs(buckets.forTab(tab));
    if (ordered.isEmpty) {
      return const SizedBox.shrink();
    }
    final frontId = deckFrontId(ordered, selectedJobId);
    final front = ordered.firstWhere(
      (job) => job.id == frontId,
      orElse: () => ordered.first,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DeckPrimaryButton(
              label: _primaryLabel(t, verbFor(front)),
              onPressed: () => onOpen(front),
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncStrip extends StatelessWidget {
  const _SyncStrip({
    required this.waiting,
    required this.conflicts,
    required this.onSync,
  });

  final int waiting;
  final int conflicts;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final tone = conflicts > 0
        ? context.statusColors.danger
        : context.statusColors.warning;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: tone.foreground.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            conflicts > 0
                ? Icons.sync_problem_rounded
                : Icons.cloud_upload_outlined,
            size: 18,
            color: tone.foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              conflicts > 0
                  ? t(TechnicianKeys.technicianSyncConflictsCount, {
                      'count': conflicts,
                    })
                  : t(TechnicianKeys.technicianSyncPendingCount, {
                      'count': waiting,
                    }),
              style: queueMeta(
                context,
                color: tone.foreground,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          QueueButton(
            label: t(TechnicianKeys.syncNow),
            variant: QueueButtonVariant.ghost,
            onPressed: onSync,
          ),
        ],
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.page, required this.onPage});

  final JobSummaryPage page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Row(
      children: [
        Text(
          t(TechnicianKeys.technicianPageOf, {
            'page': page.page + 1,
            'totalPages': page.totalPages,
          }),
          style: queueMeta(context, color: context.colors.onSurfaceVariant),
        ),
        const Spacer(),
        QueueButton(
          label: t(TechnicianKeys.technicianPreviousPage),
          variant: QueueButtonVariant.ghost,
          onPressed: page.page <= 0 ? null : () => onPage(page.page - 1),
        ),
        const SizedBox(width: 8),
        QueueButton(
          label: t(TechnicianKeys.technicianNextPage),
          variant: QueueButtonVariant.soft,
          onPressed: page.page + 1 >= page.totalPages
              ? null
              : () => onPage(page.page + 1),
        ),
      ],
    );
  }
}

/// Full-width band whose content is centred and capped, so the header, tabs
/// and scroll body all share one measure.
class _Centered extends StatelessWidget {
  const _Centered({
    required this.maxWidth,
    required this.padding,
    required this.child,
  });

  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
