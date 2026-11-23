import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'jobs_queue_format.dart';
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
      child: Row(
        children: [
          for (var index = 0; index < days.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: _DayCell(
                weekday: queueWeekdayShort(days[index], locale),
                number: queueDayNumber(days[index]),
                selected: _dayKey(days[index]) == _dayKey(selected),
                hasJobs: daysWithJobs.contains(_dayKey(days[index])),
                onTap: () => onSelect(days[index]),
              ),
            ),
          ],
        ],
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
