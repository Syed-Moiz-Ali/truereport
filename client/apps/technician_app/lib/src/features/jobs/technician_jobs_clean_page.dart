import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../inspection/fieldwork/fieldwork_ui.dart';
import '../../inspection_models.dart';
import '../../reference_ui.dart';
import '../../technician_providers.dart';
import 'queue/fieldwork/jobs_board.dart';
import 'queue/jobs_queue_format.dart';
import 'queue/queue_model.dart';

/// The technician's shift as a Fieldwork board: one top bar, a NOW card in a
/// pinned rail (or above the agenda on phones), a segmented shift switch,
/// status chips and one time-anchored agenda surface.
///
/// Behaviour is unchanged: the same providers, offline queue, sync service,
/// search, status filter, job routes and pull-to-refresh.
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
  final _searchFocus = FocusNode();
  final _scroll = ScrollController();
  int _page = 0;
  String _status = '';
  bool _searchOpen = false;
  ShiftTab _tab = ShiftTab.today;

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
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _handleSearch() => setState(() {});

  void _setTab(ShiftTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _toTop();
  }

  void _setStatus(String status) {
    setState(() {
      _status = status;
      _page = 0;
    });
    _toTop();
  }

  void _toTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      _searchFocus.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      _search.clear();
    }
  }

  void _clearFilters() {
    _search.clear();
    _setStatus('');
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
              style: fieldworkText(
                context,
                16,
                weight: FontWeight.w800,
                height: 21,
                tracking: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppFilterChip(
                  label: t(TechnicianKeys.filterAll),
                  selected: _status.isEmpty,
                  onSelected: (_) {
                    Navigator.of(context).pop();
                    _setStatus('');
                  },
                ),
                for (final record in statuses.where(
                  (value) => value.selectable,
                ))
                  AppFilterChip(
                    label: referenceStatusCodeLabel(statuses, record.code),
                    selected:
                        normalizeStatusCode(_status) ==
                        normalizeStatusCode(record.code),
                    onSelected: (_) {
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
          ref
            ..invalidate(syncQueueStatusProvider)
            ..invalidate(pendingOperationsProvider)
            ..invalidate(technicianJobPageProvider);
        });
      }
    });

    final pageAsync = ref.watch(technicianJobPageProvider(_query));
    final sync = ref.watch(syncQueueStatusProvider).asData?.value;
    final statuses =
        ref.watch(statusesProvider('job')).value ?? const <ReferenceRecord>[];
    final online = ref.watch(connectivityProvider).value ?? true;
    final session = ref.watch(authControllerProvider).value;
    final name = session?.user.displayName ?? t(TechnicianKeys.roleTechnician);
    final waiting = (sync?.pending ?? 0) + (sync?.failed ?? 0);
    final conflicts = sync?.conflicts ?? 0;

    final data = pageAsync.asData?.value;
    final term = _search.text.trim().toLowerCase();
    final searched = data == null
        ? const <JobSummary>[]
        : data.items.where((job) => _matches(job, term)).toList();
    final filtered = _filterStatus(searched);
    final buckets = groupJobs(filtered, now: now);
    final focus = nowJob(buckets.visible, now: now);
    final todayRows = <JobSummary>[
      ...buckets.now,
      ...buckets.today,
    ].where((job) => job.id != focus?.id).toList(growable: false);

    final emptyQueue = data?.items.isEmpty ?? false;
    // A search/status filter that matches nothing is also a bare screen:
    // showing the NOW card would claim "all caught up" when there is simply no
    // match.
    final noMatches =
        !emptyQueue && (data?.items.isNotEmpty ?? false) && filtered.isEmpty;

    final nextTime = queueNextTimeLabel(buckets.visible, now: now);
    final nextTimeLabel = nextTime == null
        ? null
        : t(TechnicianKeys.technicianQueueNextAt, {'time': nextTime});

    final (
      String syncLabel,
      StatusTone syncTone,
      IconData syncIcon,
    ) = conflicts > 0
        ? (
            '${t(TechnicianKeys.technicianSyncStateConflict)} · $conflicts',
            StatusTone.danger,
            Icons.sync_problem_rounded,
          )
        : waiting > 0
        ? (
            '${t(TechnicianKeys.technicianSessionSyncPending)} · $waiting',
            StatusTone.warning,
            Icons.cloud_upload_outlined,
          )
        : !online
        ? (
            t(TechnicianKeys.technicianSyncOffline),
            StatusTone.warning,
            Icons.cloud_off_rounded,
          )
        : (
            t(TechnicianKeys.technicianSyncOnline),
            StatusTone.success,
            Icons.cloud_done_outlined,
          );

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: JobsBoard(
        header: JobsHeaderData(
          eyebrow: t(TechnicianKeys.technicianDeckEyebrow),
          name: name,
          dateLabel: queueDateFormat(now, locale),
          profileLabel: t(TechnicianKeys.technicianProfileTitle),
          searchLabel: t(TechnicianKeys.technicianJobSearch),
          filterLabel: t(TechnicianKeys.technicianFilter),
          searchOpen: _searchOpen,
          filterActive: _status.isNotEmpty,
          syncLabel: syncLabel.trim().isEmpty ? null : syncLabel,
          syncTone: syncTone,
          syncIcon: syncIcon,
        ),
        now: focus == null ? null : _nowData(focus, t),
        nowEmptyTitle: t(TechnicianKeys.technicianAllCaughtUp),
        nowEmptyBody: t(TechnicianKeys.technicianNoJobsBody),
        nowEmptyActionLabel: t(TechnicianKeys.technicianDeckSeeAll),
        nextTimeLabel: nextTimeLabel,
        summary: JobsSummaryData(
          title: t(TechnicianKeys.technicianQueueSectionToday),
          startLabel: t(TechnicianKeys.start),
          nowLabel: t(TechnicianKeys.technicianQueueSectionNow),
          doneLabel: t(TechnicianKeys.technicianQueueSectionDoneToday),
          toStart: buckets.toStartCount,
          inProgress: buckets.inProgressCount,
          doneToday: buckets.doneToday.length,
          nextTimeLabel: nextTimeLabel,
        ),
        tabs: JobsTabsData(
          selected: _tab,
          todayLabel: t(TechnicianKeys.technicianQueueSectionToday),
          upcomingLabel: t(TechnicianKeys.technicianQueueSectionUpcoming),
          unfinishedLabel: t(TechnicianKeys.technicianQueueSectionUnfinished),
          today:
              buckets.now.length +
              buckets.today.length +
              buckets.doneToday.length,
          upcoming: buckets.upcoming.length,
          unfinished: buckets.unfinished.length,
        ),
        statusFilters: data == null
            ? const <JobsStatusFilter>[]
            : _statusFilters(data.items, statuses, t),
        sections: data == null
            ? const <JobsAgendaSection>[]
            : _sections(
                buckets: buckets,
                focus: focus,
                todayRows: todayRows,
                t: t,
                locale: locale,
                now: now,
              ),
        searchOpen: _searchOpen,
        searchController: _search,
        searchFocusNode: _searchFocus,
        searchLabel: t(TechnicianKeys.technicianJobSearch),
        searchHint: t(TechnicianKeys.technicianJobSearchHint),
        clearSearchLabel: t(TechnicianKeys.technicianQueueClearFilters),
        loading: pageAsync.isLoading && data == null,
        empty: emptyQueue
            ? JobsEmptyData(
                title: t(TechnicianKeys.technicianAllCaughtUp),
                body: t(TechnicianKeys.technicianNoJobsBody),
              )
            : null,
        noResults: noMatches
            ? JobsEmptyData(
                title: t(TechnicianKeys.technicianNoSearchResults),
                body: t(TechnicianKeys.technicianNoJobsBody),
                actionLabel: t(TechnicianKeys.technicianQueueClearFilters),
              )
            : null,
        error: pageAsync.hasError
            ? JobsErrorData(
                title: t(TechnicianKeys.error),
                body: t(TechnicianKeys.genericError),
                retryLabel: t(TechnicianKeys.retryAction),
              )
            : null,
        offlineLabel: online ? null : t(TechnicianKeys.offlineBanner),
        onRefresh: _refresh,
        onRetry: _refresh,
        onSearchToggle: _toggleSearch,
        onSearchChanged: (_) => setState(() {}),
        onSearchClear: () {
          _search.clear();
          setState(() {});
        },
        onFilter: _openFilters,
        onProfile: () => context.push('/profile'),
        onSync: () => context.push('/sync'),
        onTab: _setTab,
        onStatus: _setStatus,
        onOpenNow: focus == null
            ? () => _setTab(ShiftTab.upcoming)
            : () => context.push('/jobs/${focus.id}'),
        onSeeUpcoming: () => _setTab(ShiftTab.upcoming),
        onOpenJob: (id) => context.push('/jobs/$id'),
        onClearFilters: _clearFilters,
        scrollController: _scroll,
      ),
    );
  }

  JobsNowData _nowData(JobSummary job, UiStrings t) {
    final verb = verbFor(job);
    final time = queueTimeLabel(job);
    final started = job.startedAt;
    final nextTimeCopy = time.isEmpty
        ? ''
        : t(TechnicianKeys.technicianQueueNextAt, {'time': time});
    return JobsNowData(
      eyebrow: t(TechnicianKeys.technicianQueueSectionNow),
      vehicle: queueVehicleLabel(job),
      plate: (job.vehiclePlate ?? '').trim(),
      reference: job.reference,
      customer: job.customerName,
      timeLabel:
          (verb == QueueVerb.continueJob || verb == QueueVerb.finish) &&
              started != null
          ? time
          : nextTimeCopy,
      itemsLabel: t(TechnicianKeys.technicianQueueItems, {
        'done': job.completedItems,
        'total': job.totalItems,
      }),
      statusLabel: jobStatusLabel(ref, job.status),
      statusTone: jobStatusTone(ref, job.status),
      primaryLabel: _primaryLabel(t, verb),
      done: job.completedItems,
      total: job.totalItems,
    );
  }

  List<JobsStatusFilter> _statusFilters(
    List<JobSummary> items,
    List<ReferenceRecord> statuses,
    UiStrings t,
  ) {
    final counts = <String, int>{};
    for (final job in items) {
      final key = normalizeStatusCode(job.status);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return <JobsStatusFilter>[
      JobsStatusFilter(
        code: '',
        label: t(TechnicianKeys.filterAll),
        count: items.length,
        selected: _status.isEmpty,
      ),
      for (final record in statuses.where((value) => value.selectable))
        if ((counts[normalizeStatusCode(record.code)] ?? 0) > 0 ||
            normalizeStatusCode(_status) == normalizeStatusCode(record.code))
          JobsStatusFilter(
            code: record.code,
            label: referenceStatusCodeLabel(statuses, record.code),
            count: counts[normalizeStatusCode(record.code)] ?? 0,
            selected:
                normalizeStatusCode(_status) ==
                normalizeStatusCode(record.code),
          ),
    ];
  }

  List<JobsAgendaSection> _sections({
    required QueueBuckets buckets,
    required JobSummary? focus,
    required List<JobSummary> todayRows,
    required UiStrings t,
    required String locale,
    required DateTime now,
  }) {
    switch (_tab) {
      case ShiftTab.today:
        final rows = [for (final job in todayRows) _agendaRow(job, t)];
        final done = [for (final job in buckets.doneToday) _agendaRow(job, t)];
        return [
          if (rows.isNotEmpty)
            JobsAgendaSection(
              label: t(TechnicianKeys.technicianQueueSectionToday),
              rows: rows,
            )
          else if (done.isEmpty)
            JobsAgendaSection(
              label: t(TechnicianKeys.technicianQueueSectionToday),
              rows: const [],
              emptyMessage: t(TechnicianKeys.technicianNoJobsThisDay),
            ),
          if (done.isNotEmpty)
            JobsAgendaSection(
              label: t(TechnicianKeys.technicianQueueSectionDoneToday),
              rows: done,
            ),
        ];
      case ShiftTab.upcoming:
        final list = focus == null
            ? buckets.upcoming
            : buckets.upcoming
                  .where((job) => job.id != focus.id)
                  .toList(growable: false);
        if (list.isEmpty) {
          return [
            JobsAgendaSection(
              label: t(TechnicianKeys.technicianQueueSectionUpcoming),
              rows: const [],
              emptyMessage: t(TechnicianKeys.technicianNoJobsThisDay),
            ),
          ];
        }
        return [
          for (final section in groupQueueJobs(list, now: now))
            JobsAgendaSection(
              label: queueDayLabel(section.day, t, locale, now: now),
              rows: [for (final job in section.jobs) _agendaRow(job, t)],
            ),
        ];
      case ShiftTab.unfinished:
        final list = focus == null
            ? buckets.unfinished
            : buckets.unfinished
                  .where((job) => job.id != focus.id)
                  .toList(growable: false);
        if (list.isEmpty) {
          return [
            JobsAgendaSection(
              label: t(TechnicianKeys.technicianQueueSectionUnfinished),
              rows: const [],
              emptyMessage: t(TechnicianKeys.technicianNoJobsThisDay),
            ),
          ];
        }
        return [
          for (final section in groupQueueJobs(list, now: now))
            JobsAgendaSection(
              label: queueDayLabel(section.day, t, locale, now: now),
              rows: [for (final job in section.jobs) _agendaRow(job, t)],
            ),
        ];
    }
  }

  JobsAgendaRowData _agendaRow(JobSummary job, UiStrings t) {
    final verb = verbFor(job);
    final time = queueTimeLabel(job);
    final items = t(TechnicianKeys.technicianQueueItems, {
      'done': job.completedItems,
      'total': job.totalItems,
    });
    return JobsAgendaRowData(
      id: job.id,
      timeLabel: time,
      vehicle: queueVehicleLabel(job),
      plate: (job.vehiclePlate ?? '').trim(),
      reference: job.reference,
      customer: job.customerName,
      itemsLabel: items,
      statusLabel: jobStatusLabel(ref, job.status),
      statusTone: jobStatusTone(ref, job.status),
      done: job.completedItems,
      total: job.totalItems,
      semanticLabel: [
        time,
        queueVehicleLabel(job),
        job.customerName,
        items,
        _verbLabel(t, verb),
      ].join('. '),
    );
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

  String _verbLabel(UiStrings t, QueueVerb verb) {
    switch (verb) {
      case QueueVerb.start:
        return t(TechnicianKeys.start);
      case QueueVerb.continueJob:
        return t(TechnicianKeys.technicianQueueActionContinue);
      case QueueVerb.finish:
        return t(TechnicianKeys.technicianQueueActionFinish);
      case QueueVerb.view:
        return t(TechnicianKeys.technicianQueueActionView);
    }
  }

  List<JobSummary> _filterStatus(List<JobSummary> jobs) {
    if (_status.isEmpty) return jobs;
    return jobs
        .where(
          (job) =>
              normalizeStatusCode(job.status) == normalizeStatusCode(_status),
        )
        .toList(growable: false);
  }

  bool _matches(JobSummary job, String term) {
    if (term.isEmpty) return true;
    final haystack = [
      job.reference,
      job.customerName,
      job.vehicleMake,
      job.vehicleModel,
      job.vehiclePlate ?? '',
      job.vehicleVin ?? '',
      job.templateNameEn,
    ].join(' ').toLowerCase();
    return haystack.contains(term);
  }
}
