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
import 'queue/jobs_queue_format.dart';
import 'queue/jobs_queue_primitives.dart';
import 'queue/jobs_queue_style.dart';
import 'queue/queue_model.dart';
import 'queue/shift/shift_widgets.dart';

/// The technician's shift — mobile and tablet first.
///
/// One NOW card (always visible, pinned in the tablet's right pane), one
/// time-anchored agenda, one action per job. This replaces the deck of stacked
/// cards: the page is a shift timeline, not a swipeable stack.
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
    final colors = context.colors;

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
    ref.watch(statusesProvider('job'));
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
    final summary = _summarize(data?.items ?? const <JobSummary>[]);

    final todayRows = <JobSummary>[
      ...buckets.now,
      ...buckets.today,
    ].where((job) => job.id != focus?.id).toList(growable: false);

    return AppScaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 768;
          final maxWidth = wide ? 1180.0 : 600.0;
          final emptyQueue = pageAsync.asData?.value.items.isEmpty ?? false;
          // A search/status filter that matches nothing is also a bare screen:
          // showing the NOW card would claim "all caught up" when there is
          // simply no match.
          final noMatches =
              !emptyQueue &&
              (pageAsync.asData?.value.items.isNotEmpty ?? false) &&
              filtered.isEmpty;
          final bare = emptyQueue || noMatches;

          final header = ShiftHeader(
            name: name,
            toStart: summary.toStart,
            inProgress: summary.inProgress,
            showSummary: !emptyQueue,
            waiting: waiting,
            conflicts: conflicts,
            searchOpen: _searchOpen,
            filterActive: _status.isNotEmpty,
            filterLabel: _status.isEmpty ? null : jobStatusLabel(ref, _status),
            onProfile: () => context.push('/profile'),
            onSearch: _toggleSearch,
            onFilter: _openFilters,
            onClearFilter: () => _setStatus(''),
            onSync: () => context.push('/sync'),
          );

          final search = _searchOpen
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(top: 10),
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
                )
              : const SizedBox.shrink();

          final notices = <Widget>[
            if (!online) ...[
              QueueNote(
                icon: Icons.cloud_off_rounded,
                label: t(TechnicianKeys.offlineBanner),
                tone: StatusTone.warning,
              ),
              const SizedBox(height: 10),
            ],
          ];

          final tabs = ShiftTabs(
            today:
                buckets.now.length +
                buckets.today.length +
                buckets.doneToday.length,
            upcoming: buckets.upcoming.length,
            unfinished: buckets.unfinished.length,
            selected: _tab,
            onSelect: _setTab,
          );

          final list = _buildList(
            context: context,
            t: t,
            locale: locale,
            now: now,
            pageAsync: pageAsync,
            filtered: filtered,
            buckets: buckets,
            focus: focus,
            todayRows: todayRows,
          );

          final nowCard = ShiftNowCard(
            job: focus,
            verb: focus == null ? null : verbFor(focus),
            statusLabel: focus == null
                ? null
                : jobStatusLabel(ref, focus.status),
            statusTone: focus == null ? null : jobStatusTone(ref, focus.status),
            onOpen: focus == null
                ? () => _setTab(ShiftTab.upcoming)
                : () => context.push('/jobs/${focus.id}'),
            onSeeUpcoming: () => _setTab(ShiftTab.upcoming),
          );

          final stats = ShiftDayStats(
            toStart: buckets.toStartCount,
            inProgress: buckets.inProgressCount,
            doneToday: buckets.doneToday.length,
            nextTime: queueNextTimeLabel(buckets.visible, now: now),
          );

          final padding = EdgeInsetsDirectional.fromSTEB(
            wide ? 24 : 16,
            14,
            wide ? 24 : 16,
            24,
          );
          final headerBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              search,
              if (notices.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...notices,
              ],
            ],
          );

          if (bare) {
            // No queue rows to show (nothing assigned, or no match): one
            // centred message instead of a header strip with a card stuck
            // under it. Still scrollable so pull-to-refresh keeps working.
            return RefreshIndicator(
              color: context.brand.ink,
              backgroundColor: colors.surface,
              onRefresh: _refresh,
              child: LayoutBuilder(
                builder: (context, inner) => SingleChildScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: inner.maxHeight,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Padding(
                          padding: padding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              headerBlock,
                              Expanded(child: Center(child: list)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          if (wide && !bare) {
            return SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        headerBlock,
                        const SizedBox(height: 14),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    tabs,
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: RefreshIndicator(
                                        color: context.brand.ink,
                                        backgroundColor: colors.surface,
                                        onRefresh: _refresh,
                                        child: SingleChildScrollView(
                                          controller: _scroll,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          child: list,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsetsDirectional.only(
                                    bottom: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      nowCard,
                                      const SizedBox(height: 12),
                                      stats,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: context.brand.ink,
            backgroundColor: colors.surface,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        headerBlock,
                        const SizedBox(height: 14),
                        nowCard,
                        const SizedBox(height: 14),
                        tabs,
                        const SizedBox(height: 4),
                        list,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList({
    required BuildContext context,
    required UiStrings t,
    required String locale,
    required DateTime now,
    required AsyncValue<JobSummaryPage> pageAsync,
    required List<JobSummary> filtered,
    required QueueBuckets buckets,
    required JobSummary? focus,
    required List<JobSummary> todayRows,
  }) {
    return pageAsync.when(
      loading: () => const ShiftSkeleton(),
      error: (error, _) => QueueErrorPanel(
        title: t(TechnicianKeys.error),
        body: t(TechnicianKeys.genericError),
        retryLabel: t(TechnicianKeys.retryAction),
        onRetry: _refresh,
      ),
      data: (page) {
        if (page.items.isEmpty) {
          return QueueEmptyPanel(
            title: t(TechnicianKeys.technicianAllCaughtUp),
            body: t(TechnicianKeys.technicianNoJobsBody),
          );
        }
        if (filtered.isEmpty) {
          return QueueEmptyPanel(
            title: t(TechnicianKeys.technicianNoSearchResults),
            body: t(TechnicianKeys.technicianNoJobsBody),
            action: QueueButton(
              label: t(TechnicianKeys.technicianQueueClearFilters),
              onPressed: () {
                _search.clear();
                _setStatus('');
              },
              variant: QueueButtonVariant.ghost,
            ),
          );
        }

        // The NOW card already carries one job. Never repeat it in the agenda,
        // whichever tab is open, so a row and the card can't disagree.
        final upcoming = focus == null
            ? buckets.upcoming
            : buckets.upcoming
                  .where((job) => job.id != focus.id)
                  .toList(growable: false);
        final unfinished = focus == null
            ? buckets.unfinished
            : buckets.unfinished
                  .where((job) => job.id != focus.id)
                  .toList(growable: false);

        final children = <Widget>[];
        switch (_tab) {
          case ShiftTab.today:
            if (todayRows.isEmpty && buckets.doneToday.isEmpty) {
              children.add(
                _emptyLine(context, t(TechnicianKeys.technicianNoJobsThisDay)),
              );
            } else {
              if (todayRows.isNotEmpty) {
                for (final job in todayRows) {
                  children.add(_row(context, job));
                }
              }
              if (buckets.doneToday.isNotEmpty) {
                children.add(
                  ShiftSectionHeader(
                    label: t(TechnicianKeys.technicianQueueSectionDoneToday),
                    count: buckets.doneToday.length,
                  ),
                );
                for (final job in buckets.doneToday) {
                  children.add(_row(context, job));
                }
              }
            }
          case ShiftTab.upcoming:
            if (upcoming.isEmpty) {
              children.add(
                _emptyLine(context, t(TechnicianKeys.technicianNoJobsThisDay)),
              );
            } else {
              for (final section in groupQueueJobs(upcoming, now: now)) {
                children.add(
                  ShiftSectionHeader(
                    label: queueDayLabel(section.day, t, locale, now: now),
                    count: section.jobs.length,
                  ),
                );
                for (final job in section.jobs) {
                  children.add(_row(context, job));
                }
              }
            }
          case ShiftTab.unfinished:
            if (unfinished.isEmpty) {
              children.add(
                _emptyLine(context, t(TechnicianKeys.technicianNoJobsThisDay)),
              );
            } else {
              for (final section in groupQueueJobs(unfinished, now: now)) {
                children.add(
                  ShiftSectionHeader(
                    label: queueDayLabel(section.day, t, locale, now: now),
                    count: section.jobs.length,
                  ),
                );
                for (final job in section.jobs) {
                  children.add(_row(context, job));
                }
              }
            }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  Widget _row(BuildContext context, JobSummary job) {
    return ShiftAgendaRow(
      key: ValueKey<String>('shift-${job.id}'),
      job: job,
      verb: verbFor(job),
      tone: jobStatusTone(ref, job.status),
      selected: false,
      onTap: () => context.push('/jobs/${job.id}'),
    );
  }

  Widget _emptyLine(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 24, bottom: 24),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: queueBody(context, color: context.colors.onSurfaceVariant),
        ),
      ),
    );
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

  _Summary _summarize(List<JobSummary> jobs) {
    var toStart = 0;
    var inProgress = 0;
    for (final job in jobs) {
      switch (verbFor(job)) {
        case QueueVerb.start:
          toStart++;
        case QueueVerb.continueJob:
        case QueueVerb.finish:
          inProgress++;
        case QueueVerb.view:
          break;
      }
    }
    return _Summary(toStart: toStart, inProgress: inProgress);
  }
}

class _Summary {
  const _Summary({required this.toStart, required this.inProgress});

  final int toStart;
  final int inProgress;
}
