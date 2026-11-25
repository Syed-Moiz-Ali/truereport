import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../../../inspection_models.dart';
import '../../../reference_ui.dart';
import '../../../technician_providers.dart';
import 'jobs_queue_format.dart';
import 'jobs_queue_primitives.dart';
import 'jobs_queue_style.dart';
import 'queue_model.dart';
import 'widgets/job_preview_pane.dart';
import 'widgets/job_row.dart';
import 'widgets/now_card.dart';
import 'widgets/queue_filter_sheet.dart';
import 'widgets/queue_section.dart';

/// The technician's jobs queue: what to do next, then the day's work.
///
/// The calendar is a filter here, not the screen. The default view is every
/// non-cancelled job split into Now/Today/Upcoming/Unfinished/Done today; a
/// date or status selection narrows that set without replacing the sections.
///
/// Search is page-local on purpose: the queue is already client-filtered by
/// day and status (invariant 2), so a term must not force a server round-trip.
class JobsQueuePage extends ConsumerStatefulWidget {
  const JobsQueuePage({super.key});

  @override
  ConsumerState<JobsQueuePage> createState() => _JobsQueuePageState();
}

class _JobsQueuePageState extends ConsumerState<JobsQueuePage> {
  static const int _pageSize = 50;

  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _unfinishedKey = GlobalKey();

  int _page = 0;
  String _status = '';
  DateTime? _day;
  bool _searchOpen = false;
  bool _doneExpanded = false;
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

  /// Status filtering is client-side (like the day filter) so one page can
  /// also count the cancelled jobs the sections hide.
  TechnicianJobsQuery get _query =>
      (page: _page, size: _pageSize, status: null);

  void _setPage(int page) {
    setState(() => _page = page);
    _toTop();
  }

  void _setDay(DateTime? day) {
    setState(() {
      _day = day == null ? null : DateTime(day.year, day.month, day.day);
      _page = 0;
    });
    _toTop();
  }

  void _setStatus(String status) {
    setState(() {
      _status = status;
      _page = 0;
    });
    _toTop();
  }

  void _clearFilters() {
    setState(() {
      _day = null;
      _status = '';
      _page = 0;
    });
    _toTop();
  }

  void _toTop() {
    if (!_scroll.hasClients) {
      return;
    }
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      FocusScope.of(context).unfocus();
      _search.clear();
    }
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(technicianJobPageProvider)
      ..invalidate(syncQueueStatusProvider);
    await ref.read(technicianJobPageProvider(_query).future);
  }

  Future<void> _openFilters(int cancelledCount) async {
    await showAppBottomSheet<void>(
      context,
      child: QueueFilterSheet(
        selectedDay: _day,
        selectedStatus: _status,
        cancelledCount: cancelledCount,
        onDaySelected: _setDay,
        onStatusSelected: _setStatus,
        onClear: _clearFilters,
      ),
    );
  }

  /// From the empty-day panel: drop the date filter so the UNFINISHED section
  /// becomes visible, then bring it into view. This is the fix for the old rail
  /// that could not reach past-dated work at all.
  void _showUnfinished() {
    setState(() {
      _day = null;
      _page = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final target = _unfinishedKey.currentContext;
      if (target == null) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  void _openJob(JobSummary job) => context.push('/jobs/${job.id}');

  void _selectJob(JobSummary job) => setState(() => _selectedJobId = job.id);

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    // `now` is an instant, not a day key: every queue helper converts it to
    // the Dubai day itself. Passing a midnight key here would shift the day.
    final now = DateTime.now();
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value != true) {
        ref.read(syncServiceProvider).syncAll().then((_) {
          ref
            ..invalidate(syncQueueStatusProvider)
            ..invalidate(pendingOperationsProvider)
            ..invalidate(technicianJobPageProvider);
        });
      }
    });

    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 1024;
    final pageAsync = ref.watch(technicianJobPageProvider(_query));
    final sync = ref.watch(syncQueueStatusProvider).asData?.value;
    ref.watch(statusesProvider('job'));
    final online = ref.watch(connectivityProvider).value ?? true;
    final session = ref.watch(authControllerProvider).value;
    final name = session?.user.displayName ?? t(TechnicianKeys.roleTechnician);
    final waiting = (sync?.pending ?? 0) + (sync?.failed ?? 0);
    final conflicts = sync?.conflicts ?? 0;
    final term = _search.text.trim().toLowerCase();
    final data = pageAsync.asData == null
        ? null
        : _dataFor(pageAsync.asData!.value, term, now);
    final hasFilter = _day != null || _status.isNotEmpty;

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: Column(
        children: [
          _Centered(
            maxWidth: wide ? 1296 : 720,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 2),
            child: _Header(
              title: t(TechnicianKeys.technicianJobsTitle),
              subtitle: data == null
                  ? null
                  : t(TechnicianKeys.technicianQueueSummary, {
                      'toStart': data.summary.toStartCount,
                      'inProgress': data.summary.inProgressCount,
                    }),
              searchOpen: _searchOpen,
              onSearch: _toggleSearch,
              onProfile: () => context.push('/profile'),
              technicianName: name,
            ),
          ),
          if (_searchOpen)
            _Centered(
              maxWidth: wide ? 1296 : 720,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
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
              ),
            ),
          _Centered(
            maxWidth: wide ? 1296 : 720,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: QueueChip(
                label: t(TechnicianKeys.technicianQueueShowing, {
                  'label': _filterLabel(t, locale, now),
                }),
                selected: hasFilter,
                onPressed: () => _openFilters(data?.cancelledCount ?? 0),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(
              context: context,
              wide: wide,
              pageAsync: pageAsync,
              data: data,
              online: online,
              waiting: waiting,
              conflicts: conflicts,
              t: t,
              locale: locale,
              now: now,
            ),
          ),
        ],
      ),
    );
  }

  _QueueData _dataFor(JobSummaryPage page, String term, DateTime now) {
    final searched = page.items
        .where((job) => _matches(job, term))
        .toList(growable: false);
    final statusFiltered = _filterStatus(searched);
    final dateFiltered = _filterDay(statusFiltered, now);
    final buckets = groupJobs(dateFiltered, now: now);
    final anyBuckets = groupJobs(statusFiltered, now: now);
    // A date filter is a deliberate look at one day; only the unfiltered queue
    // claims a "now".
    final hero = _day == null ? nowJob(dateFiltered, now: now) : null;
    final showCancelled = _isCancelledStatus(_status);
    final rows = showCancelled ? buckets.cancelled : buckets.visible;

    JobSummary? preview;
    if (rows.isNotEmpty) {
      final selectedId = _selectedJobId;
      preview = rows.firstWhere(
        (job) => job.id == selectedId,
        orElse: () => hero ?? rows.first,
      );
    }

    return _QueueData(
      page: page,
      summary: groupJobs(page.items, now: now),
      searched: searched,
      statusFiltered: statusFiltered,
      buckets: buckets,
      anyBuckets: anyBuckets,
      hero: hero,
      previewJob: preview,
      cancelledCount: searched.where(isCancelledJob).length,
      showCancelled: showCancelled,
      term: term,
    );
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

  List<JobSummary> _filterDay(List<JobSummary> jobs, DateTime now) {
    final day = _day;
    if (day == null) {
      return jobs;
    }
    final target = DateTime(day.year, day.month, day.day);
    final today = queueTodayKey(now);
    return jobs
        .where((job) {
          final key = queueDayKey(job);
          if (key == null) {
            return _isSameDay(target, today);
          }
          return _isSameDay(key, target);
        })
        .toList(growable: false);
  }

  bool _matches(JobSummary job, String term) {
    if (term.isEmpty) {
      return true;
    }
    final haystack = <String>[
      job.reference,
      job.customerName,
      job.vehicleMake,
      job.vehicleModel,
      job.vehiclePlate ?? '',
      job.vehicleVin ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(term);
  }

  String _filterLabel(UiStrings t, String locale, DateTime now) {
    final day = _day;
    final dayLabel = day == null
        ? t(TechnicianKeys.technicianQueueFilterAllDates)
        : _isSameDay(day, queueTodayKey(now))
        ? t(TechnicianKeys.technicianQueueSectionToday)
        : _isSameDay(day, queueTodayKey(now).add(const Duration(days: 1)))
        ? t(TechnicianKeys.technicianQueueFilterTomorrow)
        : queueDateFormat(day, locale, weekday: false);
    if (_status.isEmpty) {
      return dayLabel;
    }
    return '$dayLabel · ${jobStatusLabel(ref, _status)}';
  }

  Widget _buildBody({
    required BuildContext context,
    required bool wide,
    required AsyncValue<JobSummaryPage> pageAsync,
    required _QueueData? data,
    required bool online,
    required int waiting,
    required int conflicts,
    required UiStrings t,
    required String locale,
    required DateTime now,
  }) {
    final queue = _queuePane(
      context: context,
      pageAsync: pageAsync,
      data: data,
      online: online,
      waiting: waiting,
      conflicts: conflicts,
      t: t,
      locale: locale,
      now: now,
    );
    if (!wide) {
      return queue;
    }
    final preview = data?.previewJob;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 380, child: queue),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: context.colors.outlineVariant,
        ),
        Expanded(
          child: JobPreviewPane(
            job: preview,
            onOpen: () {
              final job = preview;
              if (job != null) {
                _openJob(job);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _queuePane({
    required BuildContext context,
    required AsyncValue<JobSummaryPage> pageAsync,
    required _QueueData? data,
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
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 28),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
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
                  child: _asyncContent(
                    context: context,
                    pageAsync: pageAsync,
                    data: data,
                    t: t,
                    locale: locale,
                    now: now,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _asyncContent({
    required BuildContext context,
    required AsyncValue<JobSummaryPage> pageAsync,
    required _QueueData? data,
    required UiStrings t,
    required String locale,
    required DateTime now,
  }) {
    if (pageAsync.hasError && !pageAsync.hasValue) {
      return QueueErrorPanel(
        key: const ValueKey('queue-error'),
        title: t(TechnicianKeys.error),
        body: t(TechnicianKeys.genericError),
        retryLabel: t(TechnicianKeys.retryAction),
        onRetry: _refresh,
      );
    }
    if (pageAsync.isLoading && !pageAsync.hasValue) {
      return const QueueSkeleton(key: ValueKey('queue-loading'));
    }
    final resolved = data;
    if (resolved == null) {
      return const QueueSkeleton(key: ValueKey('queue-loading'));
    }
    return KeyedSubtree(
      key: ValueKey(
        'queue-content-${_day?.toIso8601String() ?? 'all'}-$_status',
      ),
      child: _content(
        data: resolved,
        t: t,
        locale: locale,
        now: now,
        tablet: MediaQuery.sizeOf(context).width >= 1024,
      ),
    );
  }

  Widget _content({
    required _QueueData data,
    required UiStrings t,
    required String locale,
    required DateTime now,
    required bool tablet,
  }) {
    if (data.page.items.isEmpty) {
      return _withPager(_emptyAll(t, data, onRefresh: _refresh), data.page);
    }
    if (data.term.isNotEmpty && data.searched.isEmpty) {
      return _withPager(
        QueueEmptyPanel(
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
        ),
        data.page,
      );
    }

    final hasRows = data.showCancelled
        ? data.buckets.cancelled.isNotEmpty
        : !data.buckets.isEmpty;
    if (!hasRows) {
      if (_day != null) {
        return _withPager(_emptyDay(data, t, locale, now), data.page);
      }
      if (_status.isNotEmpty) {
        return _withPager(_emptyStatus(data, t, locale, now), data.page);
      }
      return _withPager(_emptyAll(t, data, onRefresh: _refresh), data.page);
    }

    final hero = data.hero;
    final heroId = hero?.id;
    List<JobSummary> strip(List<JobSummary> jobs) => heroId == null
        ? jobs
        : jobs.where((job) => job.id != heroId).toList(growable: false);

    final sections = <Widget>[];
    if (data.showCancelled) {
      sections.add(
        QueueSection(
          title: jobStatusLabel(ref, _status),
          rows: _rows(data.buckets.cancelled, tablet),
        ),
      );
    } else {
      void addSection(
        String title,
        List<JobSummary> jobs, {
        Key? key,
        bool showDate = false,
      }) {
        final rows = strip(jobs);
        if (rows.isEmpty) {
          return;
        }
        sections.add(
          QueueSection(
            key: key,
            title: title,
            rows: _rows(rows, tablet, showDate: showDate),
          ),
        );
      }

      addSection(t(TechnicianKeys.technicianQueueSectionNow), data.buckets.now);
      addSection(
        t(TechnicianKeys.technicianQueueSectionToday),
        data.buckets.today,
      );
      addSection(
        t(TechnicianKeys.technicianQueueSectionUpcoming),
        data.buckets.upcoming,
      );
      addSection(
        t(TechnicianKeys.technicianQueueSectionUnfinished),
        data.buckets.unfinished,
        key: _unfinishedKey,
        showDate: true,
      );

      final doneRows = strip(data.buckets.doneToday);
      if (doneRows.isNotEmpty) {
        sections.add(
          QueueSection(
            title: t(TechnicianKeys.technicianQueueSectionDoneToday),
            rows: _rows(doneRows, tablet),
            collapsed: !_doneExpanded,
            onToggle: () => setState(() => _doneExpanded = !_doneExpanded),
          ),
        );
      }
    }

    final children = <Widget>[];
    if (hero != null) {
      final heroDay = queueDayKey(hero);
      children.add(
        NowCard(
          job: hero,
          verb: verbFor(hero),
          eyebrow: heroDay == null
              ? t(TechnicianKeys.technicianQueueSectionNow)
              : queueDayLabel(heroDay, t, locale, now: now),
          onOpen: () => _openJob(hero),
        ),
      );
    }
    for (final section in sections) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 18));
      }
      children.add(section);
    }
    if (data.page.totalPages > 1) {
      children
        ..add(const SizedBox(height: 16))
        ..add(_Pager(page: data.page, onPage: _setPage));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  List<Widget> _rows(
    List<JobSummary> jobs,
    bool tablet, {
    bool showDate = false,
  }) => <Widget>[
    for (final job in jobs)
      JobRow(
        key: ValueKey('queue-row-${job.id}'),
        job: job,
        verb: verbFor(job),
        selected: tablet && job.id == _selectedJobId,
        showDate: showDate,
        onTap: () => tablet ? _selectJob(job) : _openJob(job),
      ),
  ];

  Widget _emptyAll(
    UiStrings t,
    _QueueData data, {
    required Future<void> Function() onRefresh,
  }) {
    final cancelled = data.cancelledCount;
    final refresh = QueueButton(
      label: t(TechnicianKeys.technicianRefreshQueue),
      variant: QueueButtonVariant.soft,
      icon: Icons.refresh_rounded,
      onPressed: () {
        onRefresh();
      },
    );
    return QueueEmptyPanel(
      key: const ValueKey('queue-empty-all'),
      title: t(TechnicianKeys.jobsEmpty),
      body: t(TechnicianKeys.technicianJobListEmpty),
      action: cancelled > 0
          ? _stackButtons(<Widget>[
              QueueButton(
                label:
                    '${t(TechnicianKeys.technicianQueueCancelled)} · '
                    '$cancelled',
                variant: QueueButtonVariant.soft,
                onPressed: () => _setStatus('CANCELLED'),
              ),
              refresh,
            ])
          : refresh,
    );
  }

  Widget _emptyStatus(
    _QueueData data,
    UiStrings t,
    String locale,
    DateTime now,
  ) {
    return QueueEmptyPanel(
      key: ValueKey('queue-empty-status-$_status'),
      showRoute: false,
      title: t(TechnicianKeys.jobsNoJobsInView),
      body: t(TechnicianKeys.technicianQueueShowing, {
        'label': _filterLabel(t, locale, now),
      }),
      action: QueueButton(
        label: t(TechnicianKeys.technicianQueueClearFilters),
        variant: QueueButtonVariant.soft,
        onPressed: _clearFilters,
      ),
    );
  }

  Widget _emptyDay(_QueueData data, UiStrings t, String locale, DateTime now) {
    final day = _day;
    final dayLabel = queueDayLabel(day, t, locale, now: now);
    final nearest = nearestDayWithWork(data.statusFiltered, now: now);
    final nearestLabel = nearest == null
        ? null
        : queueDayLabel(nearest, t, locale, now: now);
    final unfinished = data.anyBuckets.unfinished;
    final actions = <Widget>[
      if (nearest != null)
        QueueButton(
          label: t(TechnicianKeys.technicianQueueGoToDay, {
            'date': nearestLabel,
          }),
          variant: QueueButtonVariant.soft,
          icon: Icons.event_rounded,
          onPressed: () => _setDay(nearest),
        ),
      if (unfinished.isNotEmpty)
        QueueButton(
          label:
              '${t(TechnicianKeys.technicianQueueSectionUnfinished)} · '
              '${unfinished.length}',
          variant: QueueButtonVariant.ghost,
          onPressed: _showUnfinished,
        ),
      if (_status.isNotEmpty)
        QueueButton(
          label: t(TechnicianKeys.technicianQueueClearFilters),
          variant: QueueButtonVariant.ghost,
          onPressed: _clearFilters,
        ),
      if (nearest == null && unfinished.isEmpty && _status.isEmpty)
        QueueButton(
          label: t(TechnicianKeys.technicianRefreshQueue),
          variant: QueueButtonVariant.soft,
          icon: Icons.refresh_rounded,
          onPressed: _refresh,
        ),
    ];
    return QueueEmptyPanel(
      key: ValueKey('queue-empty-day-${day?.toIso8601String() ?? 'all'}'),
      showRoute: false,
      title: t(TechnicianKeys.technicianQueueNothingScheduled, {
        'date': dayLabel,
      }),
      body: nearestLabel == null
          ? t(TechnicianKeys.technicianNoJobsThisDay)
          : t(TechnicianKeys.technicianQueueNearestDay, {'date': nearestLabel}),
      action: actions.isEmpty ? null : _stackButtons(actions),
    );
  }

  Widget _stackButtons(List<Widget> buttons) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var index = 0; index < buttons.length; index += 1) ...[
        buttons[index],
        if (index != buttons.length - 1) const SizedBox(height: 8),
      ],
    ],
  );

  /// The pager stays reachable even when a client-side filter empties the
  /// current page, so "no jobs in this view" can never hide later pages.
  Widget _withPager(Widget child, JobSummaryPage page) {
    if (page.totalPages <= 1) {
      return child;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: 16),
        _Pager(page: page, onPage: _setPage),
      ],
    );
  }
}

/// Everything the screen derives from one job page plus the active filters.
class _QueueData {
  const _QueueData({
    required this.page,
    required this.summary,
    required this.searched,
    required this.statusFiltered,
    required this.buckets,
    required this.anyBuckets,
    required this.hero,
    required this.previewJob,
    required this.cancelledCount,
    required this.showCancelled,
    required this.term,
  });

  final JobSummaryPage page;

  /// Unfiltered sections; used only for the header counts.
  final QueueBuckets summary;
  final List<JobSummary> searched;
  final List<JobSummary> statusFiltered;
  final QueueBuckets buckets;

  /// Status-filtered but not date-filtered: what the empty-day panel offers.
  final QueueBuckets anyBuckets;
  final JobSummary? hero;
  final JobSummary? previewJob;
  final int cancelledCount;
  final bool showCancelled;
  final String term;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isCancelledStatus(String status) =>
    normalizeStatusCode(status) == 'CANCELLED';

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.searchOpen,
    required this.onSearch,
    required this.onProfile,
    required this.technicianName,
  });

  final String title;

  /// Null while the first page loads: the slot keeps its height but never
  /// shows fabricated zero counts.
  final String? subtitle;
  final bool searchOpen;
  final VoidCallback onSearch;
  final VoidCallback onProfile;
  final String technicianName;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final subtitleText = subtitle;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: queueText(
                  context,
                  22,
                  weight: FontWeight.w700,
                  height: 28,
                  tracking: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              if (subtitleText == null)
                const SizedBox(height: 18)
              else
                Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: queueMeta(context, color: colors.onSurfaceVariant),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AppIconButton(
          icon: searchOpen ? Icons.close_rounded : Icons.search_rounded,
          semanticLabel: t(TechnicianKeys.search),
          onPressed: onSearch,
        ),
        const SizedBox(width: 4),
        Semantics(
          button: true,
          label: t(TechnicianKeys.technicianProfileTitle),
          child: GestureDetector(
            onTap: onProfile,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: TechnicianAvatar(name: technicianName, size: 38),
              ),
            ),
          ),
        ),
      ],
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

/// Full-width band whose content is capped, so the header and the scroll body
/// share one measure at phone and tablet widths.
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
