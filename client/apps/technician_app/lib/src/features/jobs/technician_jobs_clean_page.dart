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
import 'queue/jobs_queue_agenda.dart';
import 'queue/jobs_queue_format.dart';
import 'queue/jobs_queue_primitives.dart';
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
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value != true) {
        ref.read(syncServiceProvider).syncAll().then((_) {
          ref.invalidate(syncQueueStatusProvider);
          ref.invalidate(pendingOperationsProvider);
          ref.invalidate(technicianJobPageProvider);
        });
      }
    });
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 760;
    final pageAsync = ref.watch(technicianJobPageProvider(_query));
    final sync = ref.watch(syncQueueStatusProvider).asData?.value;
    ref.watch(statusesProvider('job'));
    final online = ref.watch(connectivityProvider).value ?? true;
    final session = ref.watch(authControllerProvider).value;
    final name = session?.user.displayName ?? t(TechnicianKeys.roleTechnician);
    final waiting = (sync?.pending ?? 0) + (sync?.failed ?? 0);
    final conflicts = sync?.conflicts ?? 0;
    final today = queueTodayKey();
    final days = List.generate(7, (index) => today.add(Duration(days: index)));
    final allJobs = pageAsync.asData?.value.items ?? const <JobSummary>[];
    final daysWithJobs = _daysWithJobs(allJobs, today);
    final dayJobs = _jobsForDay(allJobs, _selectedDay, today);
    final nextTime = queueNextTimeLabel(dayJobs);
    final dayLabel = queueDayLabel(_selectedDay, t, locale);
    final subtitle = nextTime == null
        ? dayLabel
        : '$dayLabel · '
              '${t(TechnicianKeys.technicianQueueNextAt, {'time': nextTime})}';

    return AppScaffold(
      backgroundColor: context.colors.surfaceContainerLow,
      body: Column(
        children: [
          _Centered(
            maxWidth: 820,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 2),
            child: _TopBar(
              title: t(TechnicianKeys.technicianJobQueue),
              subtitle: subtitle,
              searchOpen: _searchOpen,
              onSearch: _toggleSearch,
              onProfile: () => context.push('/profile'),
              technicianName: name,
            ),
          ),
          if (_searchOpen)
            _Centered(
              maxWidth: 820,
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
          // One week control on every width: the old tablet rail is gone, so
          // the day strip is the only way the week is presented.
          _Centered(
            maxWidth: 820,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 12, 4),
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
                  label: t(TechnicianKeys.technicianFilter),
                  onPressed: _openFilters,
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildScroll(
              context: context,
              wide: wide,
              pageAsync: pageAsync,
              online: online,
              waiting: waiting,
              conflicts: conflicts,
              t: t,
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
    required UiStrings t,
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
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
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
                if (_status.isNotEmpty) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: QueueChip(
                      label: jobStatusLabel(ref, _status),
                      selected: true,
                      onPressed: () => _setStatus(''),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                      title: t(TechnicianKeys.error),
                      body: t(TechnicianKeys.genericError),
                      retryLabel: t(TechnicianKeys.retryAction),
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
                      if (searched.isEmpty) {
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
                      final jobs = _jobsForDay(searched, _selectedDay, today);
                      if (jobs.isEmpty) {
                        return QueueEmptyPanel(
                          key: ValueKey(
                            'queue-day-${_selectedDay.toIso8601String()}',
                          ),
                          showRoute: false,
                          title: t(TechnicianKeys.technicianNoJobsThisDay),
                          body: t(TechnicianKeys.technicianPickAnotherDay),
                        );
                      }
                      final liveJobId = queueLiveJobId(jobs);
                      return Column(
                        key: ValueKey(
                          'queue-day-${_selectedDay.toIso8601String()}-'
                          '${_status.isEmpty ? 'all' : _status}',
                        ),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                t(TechnicianKeys.technicianQueueOnBoard, {
                                  'count': jobs.length,
                                }),
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
                          QueueAgenda(
                            jobs: jobs,
                            liveJobId: liveJobId,
                            onOpen: (job) => context.push('/jobs/${job.id}'),
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
          label: UiStrings.of(context)(TechnicianKeys.search),
          onPressed: onSearch,
        ),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: UiStrings.of(context)(TechnicianKeys.technicianProfileTitle),
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

/// Full-width band whose content is centred and capped, so the header, week
/// strip and scroll body all share one measure.
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
