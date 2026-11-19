import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../inspection_models.dart';
import '../../technician_providers.dart';
import '../profile/profile_sheet.dart';
import 'queue/jobs_queue_format.dart';
import 'queue/jobs_queue_hero.dart';
import 'queue/jobs_queue_primitives.dart';
import 'queue/jobs_queue_row.dart';
import 'queue/jobs_queue_style.dart';
import 'queue/jobs_queue_week.dart';

/// Week-board shift view: pick a day, open the next job, scan the rest.
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
  late DateTime _selectedDay = queueTodayKey();
  int _page = 0;
  String _status = '';
  bool _searchOpen = false;

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

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
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
    final l10n = AppLocalizations.of(context);
    await showAppBottomSheet<void>(
      context,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.technicianFilter, style: queueSection(context)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                QueueChip(
                  label: l10n.filterAll,
                  selected: _status.isEmpty,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _setStatus('');
                  },
                ),
                QueueChip(
                  label: l10n.statusAssigned,
                  selected: _status == 'ASSIGNED',
                  onPressed: () {
                    Navigator.of(context).pop();
                    _setStatus('ASSIGNED');
                  },
                ),
                QueueChip(
                  label: l10n.statusInProgress,
                  selected: _status == 'IN_PROGRESS',
                  onPressed: () {
                    Navigator.of(context).pop();
                    _setStatus('IN_PROGRESS');
                  },
                ),
                QueueChip(
                  label: l10n.technicianReview,
                  selected: _status == 'PENDING_REVIEW',
                  onPressed: () {
                    Navigator.of(context).pop();
                    _setStatus('PENDING_REVIEW');
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
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 760;
    final pageAsync = ref.watch(technicianJobPageProvider(_query));
    final sync = ref.watch(syncQueueStatusProvider).asData?.value;
    final online = ref.watch(connectivityProvider).value ?? true;
    final session = ref.watch(authControllerProvider).value;
    final name = session?.user.displayName ?? l10n.roleTechnician;
    final waiting = (sync?.pending ?? 0) + (sync?.failed ?? 0);
    final conflicts = sync?.conflicts ?? 0;
    final today = queueTodayKey();
    final days = List.generate(7, (index) => today.add(Duration(days: index)));
    final allJobs = pageAsync.asData?.value.items ?? const <JobSummary>[];
    final daysWithJobs = _daysWithJobs(allJobs, today);

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: TechnicianDock(
            jobsLabel: l10n.technicianJobsTitle,
            syncLabel: l10n.technicianSyncTitle,
            profileLabel: l10n.technicianProfileTitle,
            selectedIndex: 0,
            onSelected: (index) {
              if (index == 1) {
                context.push('/sync');
              } else if (index == 2) {
                showTechnicianProfile(context, ref);
              }
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 8),
                child: _TopBar(
                  title: l10n.technicianJobQueue,
                  subtitle: queueDayLabel(_selectedDay, l10n, locale),
                  searchOpen: _searchOpen,
                  onSearch: _toggleSearch,
                  onProfile: () => showTechnicianProfile(context, ref),
                  technicianName: name,
                ),
              ),
            ),
          ),
          if (_searchOpen)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: QueueSearchField(
                    controller: _search,
                    autofocus: true,
                    hint: l10n.technicianJobSearchHint,
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _search.clear();
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          if (!wide)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: QueueWeekStrip(
                      days: days,
                      selected: _selectedDay,
                      daysWithJobs: daysWithJobs,
                      onSelect: _selectDay,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterIcon(
                    active: _status.isNotEmpty,
                    label: l10n.technicianFilter,
                    onPressed: _openFilters,
                  ),
                ],
              ),
            ),
          Expanded(
            child: wide
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: SizedBox.expand(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            QueueWeekRail(
                              days: days,
                              selected: _selectedDay,
                              daysWithJobs: daysWithJobs,
                              onSelect: _selectDay,
                              status: _status,
                              onStatus: _setStatus,
                              pending: waiting,
                              conflicts: conflicts,
                              onSync: () => context.push('/sync'),
                            ),
                            Expanded(
                              child: _buildScroll(
                                context: context,
                                wide: true,
                                pageAsync: pageAsync,
                                online: online,
                                waiting: waiting,
                                conflicts: conflicts,
                                l10n: l10n,
                                today: today,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _buildScroll(
                    context: context,
                    wide: false,
                    pageAsync: pageAsync,
                    online: online,
                    waiting: waiting,
                    conflicts: conflicts,
                    l10n: l10n,
                    today: today,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScroll({
    required BuildContext context,
    required bool wide,
    required AsyncValue<JobSummaryPage> pageAsync,
    required bool online,
    required int waiting,
    required int conflicts,
    required AppLocalizations l10n,
    required DateTime today,
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
          alignment: wide
              ? AlignmentDirectional.topStart
              : AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!online) ...[
                  QueueNote(
                    icon: Icons.cloud_off_rounded,
                    label: l10n.offlineBanner,
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
                        const QueueSkeleton(key: ValueKey('queue-loading')),
                    error: (error, _) => QueueErrorPanel(
                      key: const ValueKey('queue-error'),
                      title: l10n.error,
                      body: l10n.genericError,
                      retryLabel: l10n.retryAction,
                      onRetry: () => _refresh(),
                    ),
                    data: (page) {
                      final term = _search.text.trim().toLowerCase();
                      final searched = page.items
                          .where((job) => _matches(job, term))
                          .toList(growable: false);
                      if (page.items.isEmpty) {
                        return QueueEmptyPanel(
                          key: const ValueKey('queue-empty'),
                          title: l10n.technicianAllCaughtUp,
                          body: l10n.technicianJobListEmpty,
                          action: QueueButton(
                            label: l10n.technicianRefresh,
                            variant: QueueButtonVariant.soft,
                            icon: Icons.refresh_rounded,
                            onPressed: _refresh,
                          ),
                        );
                      }
                      if (searched.isEmpty) {
                        return QueueEmptyPanel(
                          key: const ValueKey('queue-no-results'),
                          showRoute: false,
                          title: l10n.noResults,
                          body: l10n.technicianNoSearchResults,
                          action: QueueButton(
                            label: l10n.technicianClear,
                            variant: QueueButtonVariant.soft,
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          ),
                        );
                      }
                      final jobs = _jobsForDay(searched, _selectedDay, today);
                      if (jobs.isEmpty) {
                        return QueueEmptyPanel(
                          key: ValueKey(
                            'queue-day-${_selectedDay.toIso8601String()}',
                          ),
                          showRoute: false,
                          title: l10n.technicianNoJobsThisDay,
                          body: l10n.technicianPickAnotherDay,
                        );
                      }
                      return _Agenda(
                        key: ValueKey(
                          'queue-day-${_selectedDay.toIso8601String()}-'
                          '${_status.isEmpty ? 'all' : _status}',
                        ),
                        jobs: jobs,
                        l10n: l10n,
                        page: page,
                        onOpen: (job) => context.push('/jobs/${job.id}'),
                        onPage: _setPage,
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

  List<JobSummary> _jobsForDay(
    List<JobSummary> jobs,
    DateTime day,
    DateTime today,
  ) {
    final key = DateTime(day.year, day.month, day.day);
    final selected = <JobSummary>[];
    for (final job in jobs) {
      final jobDay = queueDayKey(job);
      if (jobDay == null) {
        if (key == today) {
          selected.add(job);
        }
      } else if (jobDay.year == key.year &&
          jobDay.month == key.month &&
          jobDay.day == key.day) {
        selected.add(job);
      }
    }
    selected.sort((a, b) {
      final left = queueMoment(a);
      final right = queueMoment(b);
      if (left == null || right == null) {
        return left == null && right == null ? 0 : (left == null ? 1 : -1);
      }
      return left.compareTo(right);
    });
    return selected;
  }

  Set<String> _daysWithJobs(List<JobSummary> jobs, DateTime today) {
    final keys = <String>{};
    for (final job in jobs) {
      final day = queueDayKey(job);
      if (day == null) {
        keys.add(_key(today));
      } else {
        keys.add(_key(day));
      }
    }
    return keys;
  }

  String _key(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.searchOpen,
    required this.onSearch,
    required this.onProfile,
    required this.technicianName,
  });

  final String title;
  final String subtitle;
  final bool searchOpen;
  final VoidCallback onSearch;
  final VoidCallback onProfile;
  final String technicianName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                style: queueText(
                  context,
                  22,
                  weight: FontWeight.w700,
                  height: 28,
                  tracking: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                style: queueMeta(context, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _CircleIcon(
          icon: searchOpen ? Icons.close_rounded : Icons.search_rounded,
          label: AppLocalizations.of(context).search,
          onPressed: onSearch,
        ),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: AppLocalizations.of(context).technicianProfileTitle,
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

class _CircleIcon extends StatefulWidget {
  const _CircleIcon({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_CircleIcon> createState() => _CircleIconState();
}

class _CircleIconState extends State<_CircleIcon> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: widget.label,
      child: Tooltip(
        message: widget.label,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: context.motionDuration(
                const Duration(milliseconds: 120),
              ),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hovered ? colors.surfaceContainer : colors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _focused ? colors.focus : colors.outlineVariant,
                  width: _focused ? 2 : 1,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterIcon extends StatelessWidget {
  const _FilterIcon({
    required this.active,
    required this.label,
    required this.onPressed,
  });

  final bool active;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
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
                      border: Border.all(color: colors.surface, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Agenda extends StatelessWidget {
  const _Agenda({
    required this.jobs,
    required this.l10n,
    required this.page,
    required this.onOpen,
    required this.onPage,
    super.key,
  });

  final List<JobSummary> jobs;
  final AppLocalizations l10n;
  final JobSummaryPage page;
  final ValueChanged<JobSummary> onOpen;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final nextUp = _nextUp(jobs);
    final rest = nextUp == null
        ? jobs
        : jobs.where((job) => job.id != nextUp.id).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nextUp != null) ...[
          QueueNextUpBand(job: nextUp, onOpen: () => onOpen(nextUp)),
          const SizedBox(height: 20),
        ],
        if (rest.isNotEmpty) ...[
          Row(
            children: [
              Text(
                l10n.technicianJobsCount(rest.length).toUpperCase(),
                style: queueEyebrow(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: context.colors.outlineVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          QueueDayGroup(jobs: rest, highlightId: nextUp?.id, onOpen: onOpen),
        ] else
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Text(
              l10n.technicianQueueCurrent,
              style: queueBody(context, color: context.colors.onSurfaceVariant),
            ),
          ),
        if (page.totalPages > 1) ...[
          const SizedBox(height: 16),
          _Pager(page: page, onPage: onPage),
        ],
      ],
    );
  }

  JobSummary? _nextUp(List<JobSummary> items) {
    int rank(JobSummary job) => switch (job.status) {
      'IN_PROGRESS' => 0,
      'ASSIGNED' || 'SCHEDULED' => 1,
      'READY_TO_FINALIZE' => 2,
      _ => 9,
    };
    final candidates = items.where((job) => rank(job) < 9).toList();
    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) {
        return byRank;
      }
      final left = queueMoment(a);
      final right = queueMoment(b);
      if (left == null || right == null) {
        return 0;
      }
      return left.compareTo(right);
    });
    return candidates.first;
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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(QueueMetrics.radiusCard),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            conflicts > 0
                ? Icons.sync_problem_rounded
                : Icons.cloud_upload_outlined,
            size: 18,
            color: conflicts > 0
                ? context.statusColors.danger.foreground
                : context.statusColors.warning.foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              conflicts > 0
                  ? l10n.technicianSyncConflictsCount(conflicts)
                  : '${l10n.technicianSyncPending} $waiting',
              style: queueMeta(context).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          QueueButton(
            label: l10n.syncNow,
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
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          l10n.technicianPageOf(page.page + 1, page.totalPages),
          style: queueMeta(context, color: context.colors.onSurfaceVariant),
        ),
        const Spacer(),
        QueueButton(
          label: l10n.technicianPreviousPage,
          variant: QueueButtonVariant.ghost,
          onPressed: page.page <= 0 ? null : () => onPage(page.page - 1),
        ),
        const SizedBox(width: 8),
        QueueButton(
          label: l10n.technicianNextPage,
          variant: QueueButtonVariant.soft,
          onPressed: page.page + 1 >= page.totalPages
              ? null
              : () => onPage(page.page + 1),
        ),
      ],
    );
  }
}
