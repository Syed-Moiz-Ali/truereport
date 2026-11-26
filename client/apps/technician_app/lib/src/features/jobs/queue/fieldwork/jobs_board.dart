import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../inspection/fieldwork/fieldwork_ui.dart';
import '../queue_model.dart';

/// The shift board in the Fieldwork language: one top bar, a NOW card in a
/// pinned rail (or above the agenda on phones), one segmented shift switch,
/// status chips and one time-anchored agenda surface.
///
/// Presentation only: the page maps providers and gate logic into these models
/// and callbacks; the preview harness mounts the same widget with sample data.

class JobsHeaderData {
  const JobsHeaderData({
    required this.eyebrow,
    required this.name,
    required this.dateLabel,
    required this.profileLabel,
    required this.searchLabel,
    required this.filterLabel,
    required this.searchOpen,
    required this.filterActive,
    this.syncLabel,
    this.syncTone = StatusTone.neutral,
    this.syncIcon = Icons.cloud_done_outlined,
  });

  final String eyebrow;
  final String name;
  final String dateLabel;
  final String profileLabel;
  final String searchLabel;
  final String filterLabel;
  final bool searchOpen;
  final bool filterActive;

  /// Resolved sync/offline state; null hides the pill.
  final String? syncLabel;
  final StatusTone syncTone;
  final IconData syncIcon;
}

/// The current/next job as the focal card.
class JobsNowData {
  const JobsNowData({
    required this.eyebrow,
    required this.vehicle,
    required this.plate,
    required this.reference,
    required this.customer,
    required this.timeLabel,
    required this.itemsLabel,
    required this.statusLabel,
    required this.statusTone,
    required this.primaryLabel,
    required this.done,
    required this.total,
  });

  final String eyebrow;
  final String vehicle;
  final String plate;
  final String reference;
  final String customer;

  /// Already composed ("09:30" or "next at 13:30").
  final String timeLabel;
  final String itemsLabel;
  final String statusLabel;
  final StatusTone statusTone;
  final String primaryLabel;
  final int done;
  final int total;
}

/// The shift counters under the NOW card; all values are served/derived counts.
class JobsSummaryData {
  const JobsSummaryData({
    required this.title,
    required this.startLabel,
    required this.nowLabel,
    required this.doneLabel,
    required this.toStart,
    required this.inProgress,
    required this.doneToday,
    this.nextTimeLabel,
  });

  final String title;
  final String startLabel;
  final String nowLabel;
  final String doneLabel;
  final int toStart;
  final int inProgress;
  final int doneToday;
  final String? nextTimeLabel;
}

class JobsTabsData {
  const JobsTabsData({
    required this.selected,
    required this.todayLabel,
    required this.upcomingLabel,
    required this.unfinishedLabel,
    required this.today,
    required this.upcoming,
    required this.unfinished,
  });

  final ShiftTab selected;
  final String todayLabel;
  final String upcomingLabel;
  final String unfinishedLabel;
  final int today;
  final int upcoming;
  final int unfinished;
}

class JobsStatusFilter {
  const JobsStatusFilter({
    required this.code,
    required this.label,
    required this.count,
    required this.selected,
  });

  /// Empty string is the "all" chip.
  final String code;
  final String label;
  final int count;
  final bool selected;
}

class JobsAgendaRowData {
  const JobsAgendaRowData({
    required this.id,
    required this.timeLabel,
    required this.vehicle,
    required this.plate,
    required this.reference,
    required this.customer,
    required this.itemsLabel,
    required this.statusLabel,
    required this.statusTone,
    required this.done,
    required this.total,
    required this.semanticLabel,
  });

  final String id;
  final String timeLabel;
  final String vehicle;
  final String plate;
  final String reference;
  final String customer;
  final String itemsLabel;
  final String statusLabel;
  final StatusTone statusTone;
  final int done;
  final int total;
  final String semanticLabel;
}

class JobsAgendaSection {
  const JobsAgendaSection({
    required this.label,
    required this.rows,
    this.emptyMessage,
  });

  final String label;
  final List<JobsAgendaRowData> rows;

  /// Shown in the surface when this section has no rows.
  final String? emptyMessage;
}

class JobsEmptyData {
  const JobsEmptyData({
    required this.title,
    required this.body,
    this.actionLabel,
  });

  final String title;
  final String body;
  final String? actionLabel;
}

class JobsErrorData {
  const JobsErrorData({
    required this.title,
    required this.body,
    required this.retryLabel,
  });

  final String title;
  final String body;
  final String retryLabel;
}

/// The whole jobs screen. The page owns providers and filters; this widget owns
/// the layout and every visual state.
class JobsBoard extends StatelessWidget {
  const JobsBoard({
    required this.header,
    required this.now,
    required this.nowEmptyTitle,
    required this.nowEmptyBody,
    required this.nowEmptyActionLabel,
    required this.summary,
    required this.tabs,
    required this.statusFilters,
    required this.sections,
    required this.searchOpen,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchLabel,
    required this.searchHint,
    required this.clearSearchLabel,
    required this.loading,
    required this.onRefresh,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onFilter,
    required this.onProfile,
    required this.onSync,
    required this.onTab,
    required this.onStatus,
    required this.onOpenNow,
    required this.onSeeUpcoming,
    required this.onOpenJob,
    required this.onClearFilters,
    this.nextTimeLabel,
    this.offlineLabel,
    this.empty,
    this.noResults,
    this.error,
    required this.onRetry,
    this.scrollController,
    super.key,
  });

  final JobsHeaderData header;

  /// Null when no job is in flight; the designed empty NOW card renders instead.
  final JobsNowData? now;
  final String nowEmptyTitle;
  final String nowEmptyBody;
  final String nowEmptyActionLabel;
  final String? nextTimeLabel;
  final JobsSummaryData summary;
  final JobsTabsData tabs;
  final List<JobsStatusFilter> statusFilters;
  final List<JobsAgendaSection> sections;

  final bool searchOpen;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchLabel;
  final String searchHint;
  final String clearSearchLabel;

  final bool loading;
  final JobsEmptyData? empty;
  final JobsEmptyData? noResults;
  final JobsErrorData? error;
  final String? offlineLabel;

  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onFilter;
  final VoidCallback onProfile;
  final VoidCallback onSync;
  final ValueChanged<ShiftTab> onTab;
  final ValueChanged<String> onStatus;
  final VoidCallback onOpenNow;
  final VoidCallback onSeeUpcoming;
  final ValueChanged<String> onOpenJob;
  final VoidCallback onClearFilters;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth >= 600 ? 24.0 : 16.0;
    // The rail needs 760 + 32 + 340; below that the board keeps the 760 work
    // measure and stacks the NOW card above the agenda.
    final boardMax = screenWidth >= 1180 ? 1132.0 : 760.0;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: hPad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: boardMax),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 12, bottom: 10),
                child: JobsTopBar(
                  header: header,
                  onSearch: onSearchToggle,
                  onFilter: onFilter,
                  onProfile: onProfile,
                  onSync: onSync,
                ),
              ),
              if (offlineLabel != null) ...[
                FieldworkNote(
                  message: offlineLabel!,
                  tone: StatusTone.warning,
                  icon: Icons.cloud_off_rounded,
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1000;
                    return _body(
                      context,
                      wide: wide,
                      height: constraints.maxHeight,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required bool wide,
    required double height,
  }) {
    final emptyData = noResults ?? empty;
    if (emptyData != null) {
      final searching = noResults != null;
      return _stateBody(
        context,
        height: height,
        child: _JobsStatePanel(
          icon: searching ? Icons.search_off_rounded : Icons.task_alt_rounded,
          tone: searching ? StatusTone.neutral : StatusTone.success,
          title: emptyData.title,
          body: emptyData.body,
          action: emptyData.actionLabel == null
              ? null
              : FieldworkButton(
                  label: emptyData.actionLabel!,
                  variant: FieldworkButtonVariant.ghost,
                  height: FieldworkMetrics.secondaryHeight,
                  onPressed: onClearFilters,
                ),
        ),
      );
    }
    if (loading) {
      return _skeleton(context, wide: wide);
    }
    final errorData = error;
    if (errorData != null) {
      return _stateBody(
        context,
        height: height,
        child: _JobsStatePanel(
          icon: Icons.error_outline_rounded,
          tone: StatusTone.danger,
          title: errorData.title,
          body: errorData.body,
          action: FieldworkButton(
            label: errorData.retryLabel,
            icon: Icons.refresh_rounded,
            height: FieldworkMetrics.secondaryHeight,
            onPressed: onRetry,
          ),
        ),
      );
    }
    if (wide) {
      return _wideBoard(context);
    }
    return _stackedBoard(context);
  }

  /// A centred state panel over a scrollable body, so pull-to-refresh still
  /// works and the search field stays reachable.
  Widget _stateBody(
    BuildContext context, {
    required double height,
    required Widget child,
  }) {
    return Column(
      children: [
        _searchArea(context),
        Expanded(
          child: RefreshIndicator(
            color: context.brand.ink,
            backgroundColor: context.colors.surface,
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (height - 44).clamp(0, double.infinity),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wideBoard(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JobsSegmentedTabs(data: tabs, onSelect: onTab),
              _searchArea(context),
              _statusArea(),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  color: context.brand.ink,
                  backgroundColor: context.colors.surface,
                  onRefresh: onRefresh,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: JobsAgenda(sections: sections, onOpen: onOpenJob),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _nowWidget(),
                const SizedBox(height: 12),
                JobsShiftSummary(data: summary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stackedBoard(BuildContext context) {
    return RefreshIndicator(
      color: context.brand.ink,
      backgroundColor: context.colors.surface,
      onRefresh: onRefresh,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(bottom: 28),
        children: [
          _nowWidget(),
          const SizedBox(height: 12),
          JobsShiftSummary(data: summary),
          const SizedBox(height: 16),
          JobsSegmentedTabs(data: tabs, onSelect: onTab),
          _searchArea(context),
          _statusArea(),
          const SizedBox(height: 10),
          JobsAgenda(sections: sections, onOpen: onOpenJob),
        ],
      ),
    );
  }

  Widget _nowWidget() {
    final data = now;
    if (data != null) {
      return JobsNowCard(data: data, onOpen: onOpenNow);
    }
    return JobsNowEmptyCard(
      title: nowEmptyTitle,
      body: nowEmptyBody,
      nextTimeLabel: nextTimeLabel,
      actionLabel: nowEmptyActionLabel,
      onSeeUpcoming: onSeeUpcoming,
    );
  }

  Widget _searchArea(BuildContext context) {
    return AnimatedSize(
      duration: context.motionDuration(const Duration(milliseconds: 180)),
      curve: context.motion.enterCurve,
      alignment: AlignmentDirectional.topCenter,
      child: !searchOpen
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsetsDirectional.only(top: 10),
              child: AppTextField(
                controller: searchController,
                focusNode: searchFocusNode,
                label: searchLabel,
                labelAbove: true,
                hint: searchHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: searchController.text.trim().isEmpty
                    ? null
                    : AppIconButton(
                        icon: Icons.close_rounded,
                        semanticLabel: clearSearchLabel,
                        onPressed: onSearchClear,
                      ),
                textInputAction: TextInputAction.search,
                onChanged: onSearchChanged,
              ),
            ),
    );
  }

  Widget _statusArea() {
    if (statusFilters.length <= 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in statusFilters)
            AppFilterChip(
              label: filter.label.trim().isEmpty
                  ? '${filter.count}'
                  : '${filter.label} · ${filter.count}',
              selected: filter.selected,
              semanticLabel: filter.label,
              onSelected: (_) => onStatus(filter.code),
            ),
        ],
      ),
    );
  }

  Widget _skeleton(BuildContext context, {required bool wide}) {
    const nowBlock = FieldworkCard(
      padding: EdgeInsetsDirectional.all(20),
      child: LoadingSkeleton(lines: 4, height: 14),
    );
    const rowsBlock = FieldworkCard(
      child: Padding(
        padding: EdgeInsetsDirectional.all(16),
        child: LoadingSkeleton(lines: 5, height: 52),
      ),
    );
    if (wide) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: SingleChildScrollView(child: rowsBlock)),
          SizedBox(width: 32),
          SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [nowBlock],
              ),
            ),
          ),
        ],
      );
    }
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [nowBlock, SizedBox(height: 12), rowsBlock],
      ),
    );
  }
}

/// Identity, actions and the shift date.
class JobsTopBar extends StatelessWidget {
  const JobsTopBar({
    required this.header,
    required this.onSearch,
    required this.onFilter,
    required this.onProfile,
    required this.onSync,
    super.key,
  });

  final JobsHeaderData header;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onProfile;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(header.eyebrow, style: fieldworkEyebrow(context)),
                  const SizedBox(height: 4),
                  Text(
                    header.name,
                    maxLines: 2,
                    style: fieldworkText(
                      context,
                      24,
                      weight: FontWeight.w800,
                      height: 29,
                      tracking: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            FieldworkIconButton(
              icon: Icons.search_rounded,
              semanticLabel: header.searchLabel,
              onPressed: onSearch,
              selected: header.searchOpen,
            ),
            const SizedBox(width: 4),
            FieldworkIconButton(
              icon: Icons.tune_rounded,
              semanticLabel: header.filterLabel,
              onPressed: onFilter,
              selected: header.filterActive,
            ),
            const SizedBox(width: 4),
            Semantics(
              button: true,
              label: header.profileLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onProfile,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: TechnicianAvatar(
                      name: header.name,
                      size: 36,
                      semanticLabel: header.profileLabel,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.event_outlined,
              size: 13,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                header.dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fieldworkText(
                  context,
                  12,
                  weight: FontWeight.w600,
                  height: 16,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            if (header.syncLabel != null)
              FieldworkPress(
                onTap: onSync,
                radius: FieldworkMetrics.chipRadius,
                semanticLabel: header.syncLabel,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
                  child: ExcludeSemantics(
                    child: FieldworkPill(
                      label: header.syncLabel!,
                      tone: header.syncTone,
                      icon: header.syncIcon,
                      dense: true,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The served ShiftTab values as one segmented row with counts.
class JobsSegmentedTabs extends StatelessWidget {
  const JobsSegmentedTabs({
    required this.data,
    required this.onSelect,
    super.key,
  });

  final JobsTabsData data;
  final ValueChanged<ShiftTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = <(ShiftTab, String, int)>[
      (ShiftTab.today, data.todayLabel, data.today),
      (ShiftTab.upcoming, data.upcomingLabel, data.upcoming),
      (ShiftTab.unfinished, data.unfinishedLabel, data.unfinished),
    ];
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest,
        borderRadius: BorderRadius.circular(FieldworkMetrics.chipRadius),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        children: [
          for (final (tab, label, count) in entries)
            Expanded(
              child: _TabSegment(
                label: label,
                count: count,
                selected: data.selected == tab,
                onTap: () => onSelect(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  const _TabSegment({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label $count',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: context.motionDuration(context.motion.fast),
          curve: context.motion.enterCurve,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? brand.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(FieldworkMetrics.chipRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: fieldworkText(
                    context,
                    12.5,
                    weight: FontWeight.w700,
                    height: 16,
                    color: selected
                        ? colors.surfaceLowest
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colors.surfaceLowest
                      : colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(
                    FieldworkMetrics.chipRadius,
                  ),
                ),
                child: Text(
                  '$count',
                  textDirection: TextDirection.ltr,
                  style: fieldworkNumber(
                    context,
                    10.5,
                    weight: FontWeight.w700,
                    height: 14,
                    color: selected ? brand.ink : colors.onSurfaceVariant,
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

/// The focal job card: identity, time, progress and one action.
class JobsNowCard extends StatelessWidget {
  const JobsNowCard({required this.data, required this.onOpen, super.key});

  final JobsNowData data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final onContainer = context.brand.onContainer;
    return FieldworkCard(
      semanticLabel: data.vehicle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldworkTint(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.eyebrow.toUpperCase(),
                        style: fieldworkEyebrow(
                          context,
                          color: onContainer.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FieldworkPill(
                      label: data.statusLabel,
                      tone: data.statusTone,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.vehicle,
                  maxLines: 3,
                  style: fieldworkText(
                    context,
                    23,
                    weight: FontWeight.w800,
                    height: 27,
                    tracking: -0.6,
                    color: onContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (data.plate.trim().isNotEmpty)
                      _JobsPlate(label: data.plate),
                    if (data.reference.trim().isNotEmpty)
                      Text(
                        data.reference,
                        textDirection: TextDirection.ltr,
                        style: fieldworkNumber(
                          context,
                          11.5,
                          weight: FontWeight.w700,
                          height: 15,
                          color: onContainer.withValues(alpha: 0.85),
                        ),
                      ),
                    if (data.customer.trim().isNotEmpty)
                      Text(
                        data.customer,
                        style: fieldworkText(
                          context,
                          11.5,
                          weight: FontWeight.w500,
                          height: 15,
                          color: onContainer.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
                if (data.timeLabel.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: onContainer.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          data.timeLabel,
                          style: fieldworkNumber(
                            context,
                            12,
                            weight: FontWeight.w700,
                            height: 16,
                            color: onContainer.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    FieldworkRing(
                      value: data.total <= 0 ? 0 : data.done / data.total,
                      center: '${data.done}',
                      sub: '/${data.total}',
                      size: 54,
                      stroke: 5,
                      semanticLabel: data.itemsLabel,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.itemsLabel,
                            style: fieldworkText(
                              context,
                              13,
                              weight: FontWeight.w700,
                              height: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FieldworkBar(
                            value: data.total <= 0 ? 0 : data.done / data.total,
                            height: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FieldworkButton(
                  label: data.primaryLabel,
                  icon: Icons.arrow_forward_rounded,
                  expand: true,
                  onPressed: onOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The designed NOW card when nothing is in flight.
class JobsNowEmptyCard extends StatelessWidget {
  const JobsNowEmptyCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onSeeUpcoming,
    this.nextTimeLabel,
    super.key,
  });

  final String title;
  final String body;
  final String? nextTimeLabel;
  final String actionLabel;
  final VoidCallback onSeeUpcoming;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.success;
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pair.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_rounded, size: 22, color: pair.foreground),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: fieldworkText(
              context,
              16,
              weight: FontWeight.w800,
              height: 21,
              tracking: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: fieldworkText(
              context,
              13,
              height: 19,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (nextTimeLabel != null && nextTimeLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            FieldworkPill(
              label: nextTimeLabel!,
              tone: StatusTone.info,
              icon: Icons.schedule_rounded,
              dense: true,
            ),
          ],
          const SizedBox(height: 14),
          FieldworkButton(
            label: actionLabel,
            variant: FieldworkButtonVariant.ghost,
            height: FieldworkMetrics.secondaryHeight,
            expand: true,
            onPressed: onSeeUpcoming,
          ),
        ],
      ),
    );
  }
}

/// Three served counters for the shift, plus the next time.
class JobsShiftSummary extends StatelessWidget {
  const JobsShiftSummary({required this.data, super.key});

  final JobsSummaryData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(data.title.toUpperCase(), style: fieldworkEyebrow(context)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _JobsStat(value: data.toStart, label: data.startLabel),
              ),
              Expanded(
                child: _JobsStat(value: data.inProgress, label: data.nowLabel),
              ),
              Expanded(
                child: _JobsStat(value: data.doneToday, label: data.doneLabel),
              ),
            ],
          ),
          if (data.nextTimeLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              data.nextTimeLabel!,
              style: fieldworkText(
                context,
                11.5,
                weight: FontWeight.w600,
                height: 15,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JobsStat extends StatelessWidget {
  const _JobsStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          textDirection: TextDirection.ltr,
          style: fieldworkNumber(
            context,
            26,
            weight: FontWeight.w800,
            height: 30,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fieldworkText(
            context,
            10.5,
            weight: FontWeight.w600,
            height: 14,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A designed state panel in the module's own card language.
class _JobsStatePanel extends StatelessWidget {
  const _JobsStatePanel({
    required this.icon,
    required this.tone,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final StatusTone tone;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pair = context.statusColors.forTone(tone);
    return FieldworkCard(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: pair.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: pair.foreground),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: fieldworkText(
              context,
              18,
              weight: FontWeight.w800,
              height: 24,
              tracking: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: fieldworkText(
              context,
              13,
              height: 19,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// One surface, hairline dividers, time-anchored rows grouped by shift section.
class JobsAgenda extends StatelessWidget {
  const JobsAgenda({required this.sections, required this.onOpen, super.key});

  final List<JobsAgendaSection> sections;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[];
    for (var index = 0; index < sections.length; index++) {
      final section = sections[index];
      if (index > 0 && section.rows.isNotEmpty) {
        children.add(const FieldworkDivider());
      }
      if (section.rows.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Text(
              section.emptyMessage ?? '',
              textAlign: TextAlign.center,
              style: fieldworkText(
                context,
                12.5,
                height: 18,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        );
        continue;
      }
      children.add(
        JobsSectionHeader(label: section.label, count: section.rows.length),
      );
      for (var row = 0; row < section.rows.length; row++) {
        if (row > 0) {
          children.add(const FieldworkDivider(indent: 14));
        }
        children.add(
          JobsAgendaRow(
            data: section.rows[row],
            onTap: () => onOpen(section.rows[row].id),
          ),
        );
      }
    }
    return FieldworkCard(child: Column(children: children));
  }
}

class JobsSectionHeader extends StatelessWidget {
  const JobsSectionHeader({
    required this.label,
    required this.count,
    super.key,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 2,
              style: fieldworkEyebrow(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            textDirection: TextDirection.ltr,
            style: fieldworkNumber(
              context,
              11.5,
              weight: FontWeight.w700,
              height: 15,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class JobsAgendaRow extends StatelessWidget {
  const JobsAgendaRow({required this.data, required this.onTap, super.key});

  final JobsAgendaRowData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final tone = context.statusColors.forTone(data.statusTone);
    return FieldworkPress(
      onTap: onTap,
      radius: 0,
      semanticLabel: data.semanticLabel,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 46,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.timeLabel,
                    textDirection: TextDirection.ltr,
                    style: fieldworkNumber(
                      context,
                      12,
                      weight: FontWeight.w800,
                      height: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: tone.foreground,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          data.vehicle,
                          maxLines: 3,
                          style: fieldworkText(
                            context,
                            14.5,
                            weight: FontWeight.w700,
                            height: 19,
                            tracking: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FieldworkPill(
                        label: data.statusLabel,
                        tone: data.statusTone,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (data.plate.trim().isNotEmpty)
                        _JobsPlate(label: data.plate),
                      if (data.reference.trim().isNotEmpty)
                        Text(
                          data.reference,
                          textDirection: TextDirection.ltr,
                          style: fieldworkNumber(
                            context,
                            11,
                            weight: FontWeight.w600,
                            height: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      if (data.customer.trim().isNotEmpty)
                        Text(
                          data.customer,
                          style: fieldworkText(
                            context,
                            11.5,
                            height: 15,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: FieldworkBar(
                          value: data.total <= 0 ? 0 : data.done / data.total,
                          height: 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.itemsLabel,
                        textDirection: TextDirection.ltr,
                        style: fieldworkNumber(
                          context,
                          10.5,
                          weight: FontWeight.w600,
                          height: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _JobsPlate extends StatelessWidget {
  const _JobsPlate({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Text(
        label,
        textDirection: TextDirection.ltr,
        style: fieldworkNumber(
          context,
          11,
          weight: FontWeight.w700,
          height: 15,
          tracking: 0.4,
        ),
      ),
    );
  }
}
