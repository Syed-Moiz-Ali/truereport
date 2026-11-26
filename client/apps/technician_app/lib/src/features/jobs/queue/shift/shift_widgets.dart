import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/ui_strings.dart';

import '../../../../inspection_models.dart';
import '../jobs_queue_format.dart';
import '../jobs_queue_primitives.dart';
import '../jobs_queue_style.dart';
import '../queue_model.dart';

/// The technician's shift, mobile and tablet first.
///
/// One NOW card that never scrolls away on tablet, a time-anchored agenda, and
/// a single action per job. This is presentation only: every verb, status and
/// count still comes from `queue_model.dart` and the served taxonomy.

enum ShiftTab { today, upcoming, unfinished }

class ShiftHeader extends StatelessWidget {
  const ShiftHeader({
    super.key,
    required this.name,
    required this.toStart,
    required this.inProgress,
    this.showSummary = true,
    required this.waiting,
    required this.conflicts,
    required this.searchOpen,
    required this.filterActive,
    required this.filterLabel,
    required this.onProfile,
    required this.onSearch,
    required this.onFilter,
    required this.onClearFilter,
    required this.onSync,
  });

  final String name;
  final int toStart;
  final int inProgress;
  final bool showSummary;
  final int waiting;
  final int conflicts;
  final bool searchOpen;
  final bool filterActive;
  final String? filterLabel;
  final VoidCallback onProfile;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onClearFilter;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final syncing = waiting > 0 || conflicts > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t(TechnicianKeys.technicianDeckEyebrow),
                    style: queueEyebrow(context),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    maxLines: 2,
                    style: queueText(
                      context,
                      24,
                      weight: FontWeight.w800,
                      height: 29,
                      tracking: -0.4,
                    ),
                  ),
                  if (showSummary) ...[
                    const SizedBox(height: 2),
                    Text(
                      t(TechnicianKeys.technicianQueueSummary, {
                        'toStart': toStart,
                        'inProgress': inProgress,
                      }),
                      style: queueText(
                        context,
                        12.5,
                        height: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (syncing) ...[
              _SyncPill(waiting: waiting, conflicts: conflicts, onTap: onSync),
              const SizedBox(width: 6),
            ],
            _HeaderAction(
              icon: Icons.search_rounded,
              label: t(TechnicianKeys.technicianJobSearch),
              active: searchOpen,
              onPressed: onSearch,
            ),
            _HeaderAction(
              icon: Icons.tune_rounded,
              label: t(TechnicianKeys.technicianFilter),
              active: filterActive,
              onPressed: onFilter,
            ),
            const SizedBox(width: 4),
            Semantics(
              button: true,
              label: t(TechnicianKeys.technicianProfileTitle),
              child: GestureDetector(
                onTap: onProfile,
                child: TechnicianAvatar(
                  name: name,
                  size: 40,
                  semanticLabel: t(TechnicianKeys.technicianProfileTitle),
                ),
              ),
            ),
          ],
        ),
        if (filterActive) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _ActiveFilter(
              label: filterLabel ?? t(TechnicianKeys.technicianFilter),
              clearLabel: t(TechnicianKeys.technicianQueueClearFilters),
              onClear: onClearFilter,
            ),
          ),
        ],
      ],
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({
    required this.waiting,
    required this.conflicts,
    required this.onTap,
  });

  final int waiting;
  final int conflicts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final danger = conflicts > 0;
    final count = danger ? conflicts : waiting;
    return Semantics(
      button: true,
      label: '${t(TechnicianKeys.syncQueue)}: $count',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color:
                (danger
                        ? context.statusColors.danger
                        : context.statusColors.warning)
                    .background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                danger
                    ? Icons.sync_problem_rounded
                    : Icons.cloud_upload_outlined,
                size: 15,
                color:
                    (danger
                            ? context.statusColors.danger
                            : context.statusColors.warning)
                        .foreground,
              ),
              const SizedBox(width: 5),
              Text(
                '${danger ? conflicts : waiting}',
                style: queueText(
                  context,
                  12,
                  weight: FontWeight.w700,
                  color:
                      (danger
                              ? context.statusColors.danger
                              : context.statusColors.warning)
                          .foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? brand.container : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 21,
            color: active ? brand.onContainer : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ActiveFilter extends StatelessWidget {
  const _ActiveFilter({
    required this.label,
    required this.clearLabel,
    required this.onClear,
  });

  final String label;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      height: 32,
      padding: const EdgeInsetsDirectional.only(start: 11, end: 3),
      decoration: BoxDecoration(
        color: brand.container,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: queueText(
              context,
              12,
              weight: FontWeight.w600,
              color: brand.onContainer,
            ),
          ),
          const SizedBox(width: 2),
          Semantics(
            button: true,
            label: clearLabel,
            child: GestureDetector(
              onTap: onClear,
              child: SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: brand.onContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShiftTabs extends StatelessWidget {
  const ShiftTabs({
    super.key,
    required this.today,
    required this.upcoming,
    required this.unfinished,
    required this.selected,
    required this.onSelect,
  });

  final int today;
  final int upcoming;
  final int unfinished;
  final ShiftTab selected;
  final ValueChanged<ShiftTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final entries = <(ShiftTab, String, int)>[
      (ShiftTab.today, t(TechnicianKeys.technicianQueueSectionToday), today),
      (
        ShiftTab.upcoming,
        t(TechnicianKeys.technicianQueueSectionUpcoming),
        upcoming,
      ),
      (
        ShiftTab.unfinished,
        t(TechnicianKeys.technicianQueueSectionUnfinished),
        unfinished,
      ),
    ];

    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        children: [
          for (final (tab, label, count) in entries)
            Expanded(
              child: _Tab(
                label: label,
                count: count,
                selected: selected == tab,
                onTap: () => onSelect(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
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
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? brand.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: queueText(
                    context,
                    12.5,
                    weight: FontWeight.w600,
                    color: selected ? Colors.white : colors.onSurfaceVariant,
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
                      ? Colors.white.withValues(alpha: 0.94)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: queueText(
                    context,
                    10.5,
                    weight: FontWeight.w700,
                    tabular: true,
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

class ShiftNowCard extends StatelessWidget {
  const ShiftNowCard({
    super.key,
    required this.job,
    required this.verb,
    required this.statusLabel,
    required this.statusTone,
    required this.onOpen,
    required this.onSeeUpcoming,
  });

  final JobSummary? job;
  final QueueVerb? verb;
  final String? statusLabel;
  final StatusTone? statusTone;
  final VoidCallback onOpen;
  final VoidCallback onSeeUpcoming;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final job = this.job;

    if (job == null) {
      return Container(
        padding: const EdgeInsetsDirectional.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 26,
              color: context.statusColors.success.foreground,
            ),
            const SizedBox(height: 10),
            Text(
              t(TechnicianKeys.technicianAllCaughtUp),
              style: queueSection(context),
            ),
            const SizedBox(height: 4),
            Text(
              t(TechnicianKeys.technicianNoJobsBody),
              style: queueBody(context, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            QueueButton(
              label: t(TechnicianKeys.technicianDeckSeeAll),
              onPressed: onSeeUpcoming,
              variant: QueueButtonVariant.ghost,
            ),
          ],
        ),
      );
    }

    final plate = job.vehiclePlate?.trim() ?? '';
    final label = verb ?? verbFor(job);
    final started = job.startedAt;
    final time = queueTimeLabel(job);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: context.brand.ink),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          t(TechnicianKeys.technicianQueueSectionNow)
                              .toUpperCase(),
                          style: queueEyebrow(context).copyWith(
                            color: context.brand.ink,
                            letterSpacing: 1.1,
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            (label == QueueVerb.continueJob ||
                                        label == QueueVerb.finish) &&
                                    started != null
                                ? time
                                : t(TechnicianKeys.technicianQueueNextAt, {
                                    'time': time,
                                  }),
                            style: queueMeta(
                              context,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (statusLabel != null && statusTone != null)
                          QueueStatusChip(
                            label: statusLabel!,
                            tone: statusTone!,
                            dense: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      queueVehicleLabel(job),
                      style: queueText(
                        context,
                        24,
                        weight: FontWeight.w800,
                        height: 29,
                        tracking: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (plate.isNotEmpty) QueuePlate(plate),
                        Text(
                          job.customerName,
                          style: queueMeta(
                            context,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      job.templateNameEn,
                      style: queueText(
                        context,
                        12,
                        height: 17,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: QueueProgressBar(
                            value: job.completedItems,
                            total: job.totalItems,
                            height: 6,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          t(TechnicianKeys.technicianQueueItems, {
                            'done': job.completedItems,
                            'total': job.totalItems,
                          }),
                          style: queueMeta(
                            context,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    QueueButton(
                      label: _primaryLabel(t, label),
                      icon: Icons.arrow_forward_rounded,
                      expand: true,
                      onPressed: onOpen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class ShiftSectionHeader extends StatelessWidget {
  const ShiftSectionHeader({
    super.key,
    required this.label,
    required this.count,
    this.trailing,
  });

  final String label;
  final int count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 18, 0, 8),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: queueEyebrow(context)),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: queueText(
              context,
              11.5,
              weight: FontWeight.w700,
              tabular: true,
              color: colors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class ShiftAgendaRow extends StatefulWidget {
  const ShiftAgendaRow({
    super.key,
    required this.job,
    required this.verb,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final JobSummary job;
  final QueueVerb verb;
  final StatusTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<ShiftAgendaRow> createState() => _ShiftAgendaRowState();
}

class _ShiftAgendaRowState extends State<ShiftAgendaRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    final brand = context.brand;
    final job = widget.job;
    final time = queueTimeLabel(job);
    final plate = job.vehiclePlate?.trim() ?? '';
    final tone = context.statusColors.forTone(widget.tone);
    final done = job.completedItems;
    final total = job.totalItems;

    return Semantics(
      button: true,
      label: [
        time,
        queueVehicleLabel(job),
        job.customerName,
        t(TechnicianKeys.technicianQueueItems, {'done': done, 'total': total}),
        shiftVerbLabel(t, widget.verb),
      ].join('. '),
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: widget.selected
                  ? brand.container.withValues(alpha: 0.45)
                  : (_hovered
                        ? colors.surfaceContainerLow
                        : Colors.transparent),
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(2, 12, 2, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: queueText(
                          context,
                          12,
                          weight: FontWeight.w700,
                          tabular: true,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        queueVehicleLabel(job),
                        style: queueText(
                          context,
                          16,
                          weight: FontWeight.w600,
                          height: 21,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (plate.isNotEmpty) QueuePlate(plate),
                          Text(
                            job.customerName,
                            style: queueMeta(
                              context,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: QueueProgressBar(
                              value: done,
                              total: total,
                              height: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t(TechnicianKeys.technicianQueueItems, {
                              'done': done,
                              'total': total,
                            }),
                            style: queueText(
                              context,
                              11,
                              height: 15,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      shiftVerbLabel(t, widget.verb),
                      style: queueText(
                        context,
                        12,
                        weight: FontWeight.w600,
                        color: brand.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: widget.selected
                          ? brand.ink
                          : colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShiftDayStats extends StatelessWidget {
  const ShiftDayStats({
    super.key,
    required this.toStart,
    required this.inProgress,
    required this.doneToday,
    required this.nextTime,
  });

  final int toStart;
  final int inProgress;
  final int doneToday;
  final String? nextTime;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t(TechnicianKeys.technicianQueueSectionToday),
            style: queueSection(context),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Stat(value: toStart, label: t(TechnicianKeys.start)),
              ),
              Expanded(
                child: _Stat(
                  value: inProgress,
                  label: t(TechnicianKeys.technicianQueueSectionNow),
                ),
              ),
              Expanded(
                child: _Stat(
                  value: doneToday,
                  label: t(TechnicianKeys.technicianQueueSectionDoneToday),
                ),
              ),
            ],
          ),
          if (nextTime != null) ...[
            const SizedBox(height: 8),
            Text(
              t(TechnicianKeys.technicianQueueNextAt, {'time': nextTime!}),
              style: queueMeta(context, color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: queueText(
            context,
            30,
            weight: FontWeight.w800,
            height: 34,
            tabular: true,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: queueText(
            context,
            10.5,
            height: 14,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class ShiftSkeleton extends StatelessWidget {
  const ShiftSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget block(double height, [double? width]) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        block(14, 120),
        const SizedBox(height: 10),
        block(26, 180),
        const SizedBox(height: 16),
        block(210),
        const SizedBox(height: 18),
        for (var index = 0; index < 4; index++) ...[
          block(70),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// The tablet's "next" line under the agenda: what to do after the selected job.
String? shiftNextTime(List<JobSummary> jobs, JobSummary? current) {
  for (final job in jobs) {
    if (job.id == current?.id) {
      continue;
    }
    final time = queueTimeLabel(job);
    if (time.isNotEmpty) {
      return time;
    }
  }
  return null;
}

String shiftDayLabel(DateTime day, String locale) =>
    DateFormat('EEE d MMM', locale).format(day);

String shiftVerbLabel(UiStrings t, QueueVerb verb) {
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
