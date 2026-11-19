import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_inspector.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_actions.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_body.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_footer.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_header.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_table.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_status_band.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/queue_theme.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// The queue: a data band, one sheet, a fixed inspector at ≥1024 and cards on
/// a phone. State only; every region is its own file.
class JobsQueuePage extends ConsumerStatefulWidget {
  const JobsQueuePage({super.key});

  @override
  ConsumerState<JobsQueuePage> createState() => _JobsQueuePageState();
}

class _JobsQueuePageState extends ConsumerState<JobsQueuePage> {
  static const int _pageSize = 10;
  static const double _inspectorWidth = 380;
  static const double _wideBreakpoint = 1024;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _search = '';
  String _status = '';
  int _page = 0;
  String? _selectedId;
  JobsSort _sort = JobsSort.scheduled;
  bool _ascending = true;
  String? _conflict;

  String get _key => cleanJobsKey(
    page: _page,
    size: _pageSize,
    status: _status,
    search: _search,
  );
  bool get _filtersActive => _status.isNotEmpty || _search.trim().isNotEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _search = value.trim();
          _page = 0;
          _selectedId = null;
          _conflict = null;
        });
      }
    });
  }

  void _selectStatus(String status) {
    if (_status != status) {
      setState(() {
        _status = status;
        _page = 0;
        _selectedId = null;
        _conflict = null;
      });
    }
  }

  void _selectJob(String id) {
    setState(() {
      _selectedId = id;
      _conflict = null;
    });
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 680 &&
        width < _wideBreakpoint &&
        _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _status = '';
      _page = 0;
      _selectedId = null;
      _conflict = null;
    });
  }

  void _setPage(int page) => setState(() {
    _page = page;
    _selectedId = null;
    _conflict = null;
  });

  void _sortBy(JobsSort sort) => setState(() {
    if (_sort == sort) {
      _ascending = !_ascending;
    } else {
      _sort = sort;
      _ascending = true;
    }
  });

  void _refresh() {
    if (_conflict != null) {
      setState(() => _conflict = null);
    }
    ref.invalidate(cleanJobsProvider(_key));
    ref.invalidate(cleanJobCountsProvider);
  }

  String? _statusLabel(AppLocalizations l10n) => switch (_status) {
    'DRAFT' => l10n.jobsCountDraft,
    'SCHEDULED' => l10n.jobsCountScheduled,
    'ASSIGNED' => l10n.jobsCountAssigned,
    'IN_PROGRESS' => l10n.jobsCountInProgress,
    'PENDING_REVIEW' => l10n.jobsCountPendingReview,
    'APPROVED' => l10n.jobsCountApproved,
    'PUBLISHED' => l10n.jobsCountPublished,
    'REJECTED' => l10n.jobsCountRejected,
    'CANCELLED' => l10n.jobsCountCancelled,
    _ => _search.trim().isEmpty ? null : '"${_search.trim()}"',
  };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final wide = !largeText && width >= _wideBreakpoint;
    final mid = !largeText && width >= 680 && width < _wideBreakpoint;
    final l10n = AppLocalizations.of(context);
    final jobs = ref.watch(cleanJobsProvider(_key));
    final counts = ref.watch(cleanJobCountsProvider).value;
    final staff = ref.watch(staffProvider).value;
    ref.listen<AsyncValue<JobPage>>(cleanJobsProvider(_key), (_, next) {
      final value = next.value;
      if (value == null) {
        return;
      }
      final target = value.totalPages == 0 ? 0 : value.totalPages - 1;
      if (_page > target) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _page = target);
          }
        });
      }
    });
    final page = jobs.value;
    final items = page?.items ?? const <CleanJob>[];
    CleanJob? selected;
    for (final job in items) {
      if (job.id == _selectedId) {
        selected = job;
        break;
      }
    }
    final actions = JobsQueueActions(
      context: context,
      ref: ref,
      onRefresh: _refresh,
      onConflict: (message) => setState(() => _conflict = message),
    );
    final inspector = JobsQueueInspector(
      job: selected,
      staff: staff,
      busy: false,
      pinnedFooter: wide,
      banner: _conflict,
      onClose: () => setState(() => _selectedId = null),
      onOpen: () => actions.openDetail(selected!),
      onAction: (action) => actions.onAction(selected!, action),
      onCancel: () => actions.cancel(selected!),
      onRefresh: _refresh,
    );
    final header = JobsQueueHeader(
      onCreate: actions.openCreate,
      onOpenArchive: actions.openArchivePage,
    );
    final toolbar = JobsQueueToolbar(
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      filtersActive: _filtersActive,
      activeFilterLabel: _statusLabel(l10n),
      onClearFilters: _clearFilters,
    );
    final band = JobsStatusBand(
      selectedStatus: _status,
      onSelect: _selectStatus,
    );
    final body = JobsQueueBody(
      jobs: jobs,
      items: items,
      staff: staff,
      filtered: _filtersActive,
      wide: wide,
      cards: largeText,
      selectedId: _selectedId,
      sort: _sort,
      ascending: _ascending,
      onSort: _sortBy,
      onSelect: _selectJob,
      onOpen: actions.openDetail,
      onAction: actions.onAction,
      onRetry: () => ref.invalidate(cleanJobsProvider(_key)),
      onClear: _clearFilters,
      onCreate: actions.openCreate,
    );
    final footer = JobsQueueFooter(
      page: page,
      filtered: _filtersActive,
      workshopTotal: counts?.total,
      onPrevious: () => _setPage(_page - 1),
      onNext: () => _setPage(_page + 1),
    );
    return QueueTheme(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ws = context.ws;
          final spacing = context.spacing;
          final gutter = ws.pageGutter(width);
          if (wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    gutter,
                    gutter,
                    gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      SizedBox(height: spacing.lg),
                      toolbar,
                      SizedBox(height: spacing.lg),
                      band,
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      gutter,
                      spacing.lg,
                      gutter,
                      spacing.lg,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: body),
                              SizedBox(height: spacing.sm),
                              footer,
                            ],
                          ),
                        ),
                        SizedBox(width: spacing.xl),
                        SizedBox(width: _inspectorWidth, child: inspector),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: CustomScrollView(
              controller: _scrollController,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        SizedBox(height: spacing.lg),
                        toolbar,
                        SizedBox(height: spacing.lg),
                        band,
                      ],
                    ),
                  ),
                ),
                if (mid && selected != null)
                  SliverPadding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      gutter,
                      spacing.lg,
                      gutter,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(child: inspector),
                  ),
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    gutter,
                    spacing.lg,
                    gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(child: body),
                ),
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    gutter,
                    spacing.lg,
                    gutter,
                    spacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(child: footer),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
