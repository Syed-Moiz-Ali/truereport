import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';

import '../../../reference_ui.dart';
import 'jobs_queue_format.dart';
import 'jobs_queue_primitives.dart';
import 'jobs_queue_style.dart';

String _dayKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Seven-day strip. The selected day carries the agenda below.
class QueueWeekStrip extends StatelessWidget {
  const QueueWeekStrip({
    required this.days,
    required this.selected,
    required this.daysWithJobs,
    required this.onSelect,
    super.key,
  });

  final List<DateTime> days;
  final DateTime selected;
  final Set<String> daysWithJobs;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          return _DayCell(
            weekday: queueWeekdayShort(day, locale),
            number: queueDayNumber(day),
            selected: _dayKey(day) == _dayKey(selected),
            hasJobs: daysWithJobs.contains(_dayKey(day)),
            onTap: () => onSelect(day),
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.weekday,
    required this.number,
    required this.selected,
    required this.hasJobs,
    required this.onTap,
  });

  final String weekday;
  final String number;
  final bool selected;
  final bool hasJobs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final fg = selected ? Colors.white : colors.onSurface;
    final muted = selected
        ? Colors.white.withValues(alpha: 0.7)
        : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: '$weekday $number',
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: context.motionDuration(const Duration(milliseconds: 140)),
            width: 56,
            decoration: BoxDecoration(
              color: selected ? brand.ink : colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? brand.ink : colors.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekday.toUpperCase(),
                  maxLines: 1,
                  style: queueText(
                    context,
                    9,
                    weight: FontWeight.w700,
                    height: 12,
                    tracking: 0.6,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  number,
                  style: queueText(
                    context,
                    20,
                    weight: FontWeight.w700,
                    height: 24,
                    tabular: true,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: hasJobs
                        ? (selected
                              ? Colors.white
                              : colors.onSurfaceVariant.withValues(alpha: 0.55))
                        : Colors.transparent,
                    shape: BoxShape.circle,
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

/// Tablet rail: the same week, filters and sync, without a second hero.
class QueueWeekRail extends ConsumerWidget {
  const QueueWeekRail({
    required this.days,
    required this.selected,
    required this.daysWithJobs,
    required this.onSelect,
    required this.status,
    required this.onStatus,
    required this.pending,
    required this.conflicts,
    required this.onSync,
    super.key,
  });

  final List<DateTime> days;
  final DateTime selected;
  final Set<String> daysWithJobs;
  final ValueChanged<DateTime> onSelect;
  final String status;
  final ValueChanged<String> onStatus;
  final int pending;
  final int conflicts;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final waiting = pending;
    final statuses =
        ref.watch(statusesProvider('job')).value ?? const <ReferenceRecord>[];
    return Container(
      width: 196,
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(
          end: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 18, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t(TechnicianKeys.technicianThisWeek),
              style: queueEyebrow(context),
            ),
            const SizedBox(height: 8),
            for (final day in days)
              _RailDay(
                weekday: queueWeekdayShort(day, locale).toUpperCase(),
                number: queueDayNumber(day),
                selected: _dayKey(day) == _dayKey(selected),
                hasJobs: daysWithJobs.contains(_dayKey(day)),
                onTap: () => onSelect(day),
              ),
            const SizedBox(height: 20),
            Text(
              t(TechnicianKeys.technicianFilter).toUpperCase(),
              style: queueEyebrow(context),
            ),
            const SizedBox(height: 6),
            _RailFilter(
              label: t(TechnicianKeys.filterAll),
              selected: status.isEmpty,
              onTap: () => onStatus(''),
            ),
            for (final record in statuses.where((value) => value.selectable))
              _RailFilter(
                label: referenceStatusCodeLabel(statuses, record.code),
                selected: status == record.code,
                onTap: () => onStatus(record.code),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsetsDirectional.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        conflicts > 0
                            ? Icons.sync_problem_rounded
                            : Icons.cloud_done_outlined,
                        size: 16,
                        color: conflicts > 0
                            ? context.statusColors.danger.foreground
                            : context.brand.ink,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          waiting == 0 && conflicts == 0
                              ? t(TechnicianKeys.technicianAllSynced)
                              : conflicts > 0
                              ? t(TechnicianKeys.technicianSyncConflictsCount, {
                                  'count': conflicts,
                                })
                              : '${t(TechnicianKeys.technicianSyncPending)} $waiting',
                          style: queueMeta(context)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  QueueButton(
                    label: t(TechnicianKeys.syncNow),
                    variant: QueueButtonVariant.soft,
                    icon: Icons.sync_rounded,
                    expand: true,
                    onPressed: onSync,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailDay extends StatelessWidget {
  const _RailDay({
    required this.weekday,
    required this.number,
    required this.selected,
    required this.hasJobs,
    required this.onTap,
  });

  final String weekday;
  final String number;
  final bool selected;
  final bool hasJobs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '$weekday $number',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: context.motionDuration(const Duration(milliseconds: 140)),
          height: 40,
          margin: const EdgeInsetsDirectional.only(bottom: 2),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? brand.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(
                weekday,
                style: queueText(
                  context,
                  9.5,
                  weight: FontWeight.w700,
                  height: 12,
                  tracking: 0.7,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.7)
                      : colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                number,
                style: queueText(
                  context,
                  17,
                  weight: FontWeight.w700,
                  height: 21,
                  tabular: true,
                  color: selected ? Colors.white : colors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: hasJobs
                      ? (selected
                            ? Colors.white
                            : colors.onSurfaceVariant.withValues(alpha: 0.55))
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailFilter extends StatelessWidget {
  const _RailFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: context.motionDuration(const Duration(milliseconds: 140)),
          height: 36,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? brand.container : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_rounded : Icons.circle_outlined,
                size: 14,
                color: selected ? brand.onContainer : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: queueText(
                    context,
                    13,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 17,
                    color: selected
                        ? brand.onContainer
                        : colors.onSurfaceVariant,
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
