import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../platform_theme.dart';
import '../../platform_dashboard_models.dart';
import 'trellis/trellis_ui.dart';

/// Platform dashboard charts and stat cards.
///
/// The flow chart is interactive: hover or tap a day for counts, toggle either
/// series, and switch the 7/14/30-day window (which refetches every card).

class PlatformFlowCard extends StatefulWidget {
  const PlatformFlowCard({
    super.key,
    required this.data,
    required this.days,
    required this.onDaysChanged,
    required this.refreshing,
    required this.strings,
  });

  final PlatformDashboard data;
  final int days;
  final ValueChanged<int> onDaysChanged;
  final bool refreshing;
  final UiMessageStrings strings;

  @override
  State<PlatformFlowCard> createState() => _PlatformFlowCardState();
}

class _PlatformFlowCardState extends State<PlatformFlowCard> {
  int? _hovered;
  int? _pinned;
  bool _showCreated = true;
  bool _showPublished = true;

  int? get _active => _hovered ?? _pinned;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final trend = widget.data.trend;
    final locale = Localizations.localeOf(context).toString();
    final totalCreated = trend.fold<int>(0, (sum, day) => sum + day.created);
    final totalPublished = trend.fold<int>(
      0,
      (sum, day) => sum + day.published,
    );
    final hasActivity = trend.isNotEmpty && (totalCreated + totalPublished) > 0;

    return TrellisSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.tKey(PlatformAdminKeys.dashboardFlowTitle),
                      style: Trellis.sectionTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.tKey(PlatformAdminKeys.dashboardFlowSubtitle),
                      style: Trellis.body,
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                _RangeChips(
                  days: widget.days,
                  onChanged: widget.onDaysChanged,
                  strings: s,
                ),
              ],
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (compact) ...[
                header,
                const SizedBox(height: 12),
                _RangeChips(
                  days: widget.days,
                  onChanged: widget.onDaysChanged,
                  strings: s,
                ),
              ] else
                header,
              const SizedBox(height: 14),
              if (widget.refreshing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(height: 2, color: Trellis.tint),
                ),
              Row(
                children: [
                  _SeriesToggle(
                    label: s.tKey(PlatformAdminKeys.dashboardFlowCreated),
                    color: PtTheme.ink.withValues(alpha: 0.72),
                    selected: _showCreated,
                    onTap: () {
                      if (_showCreated && !_showPublished) return;
                      setState(() => _showCreated = !_showCreated);
                    },
                  ),
                  const SizedBox(width: 8),
                  _SeriesToggle(
                    label: s.tKey(PlatformAdminKeys.dashboardFlowPublished),
                    color: PtTheme.deepGreen,
                    selected: _showPublished,
                    onTap: () {
                      if (_showPublished && !_showCreated) return;
                      setState(() => _showPublished = !_showPublished);
                    },
                  ),
                  const Spacer(),
                  if (_active != null && _active! < trend.length)
                    Text(
                      DateFormat.MMMEd(locale)
                          .format(trend[_active!].day ?? DateTime.now()),
                      style: Trellis.text(11, color: PtTheme.muted),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (!hasActivity)
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      s.tKey(PlatformAdminKeys.dashboardFlowEmpty),
                      style: Trellis.body,
                    ),
                  ),
                )
              else
                _FlowChart(
                  trend: trend,
                  showCreated: _showCreated,
                  showPublished: _showPublished,
                  active: _active,
                  onHover: (index) => setState(() => _hovered = index),
                  onSelect: (index) => setState(() {
                    _pinned = _pinned == index ? null : index;
                  }),
                  locale: locale,
                  strings: s,
                ),
              const SizedBox(height: 16),
              Container(height: 1, color: PtTheme.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TotalStat(
                    label: s.tKey(PlatformAdminKeys.dashboardFlowCreated),
                    value: NumberFormat.decimalPattern(locale)
                        .format(totalCreated),
                    color: PtTheme.ink.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 28),
                  _TotalStat(
                    label: s.tKey(PlatformAdminKeys.dashboardFlowPublished),
                    value: NumberFormat.decimalPattern(locale)
                        .format(totalPublished),
                    color: PtTheme.deepGreen,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FlowChart extends StatelessWidget {
  const _FlowChart({
    required this.trend,
    required this.showCreated,
    required this.showPublished,
    required this.active,
    required this.onHover,
    required this.onSelect,
    required this.locale,
    required this.strings,
  });

  final List<PlatformFlowDay> trend;
  final bool showCreated;
  final bool showPublished;
  final int? active;
  final ValueChanged<int?> onHover;
  final ValueChanged<int> onSelect;
  final String locale;
  final UiMessageStrings strings;

  static const double _height = 180;
  static const double _axis = 26;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final day in trend) ...[
        if (showCreated) day.created,
        if (showPublished) day.published,
      ],
    ];
    final maxValue = values.fold<int>(
      1,
      (best, value) => math.max(best, value),
    );
    final labelEvery = (trend.length / 7).ceil().clamp(1, 30).toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth - _axis;
        final columnWidth = trend.isEmpty
            ? chartWidth
            : chartWidth / trend.length;
        final barWidth = columnWidth * 0.28;
        final tooltipWidth = math.min(160.0, chartWidth);
        final tooltipLeft = active == null
            ? 0.0
            : ((active! + 0.5) * columnWidth - tooltipWidth / 2)
                  .clamp(0.0, math.max(0.0, chartWidth - tooltipWidth))
                  .toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _axis,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Axis(value: maxValue),
                        _Axis(value: (maxValue / 2).round()),
                        const _Axis(value: 0),
                      ],
                    ),
                  ),
                  Expanded(
                    child: MouseRegion(
                      onHover: (event) {
                        if (trend.isEmpty) return;
                        final index = (event.localPosition.dx / columnWidth)
                            .floor()
                            .clamp(0, trend.length - 1)
                            .toInt();
                        onHover(index);
                      },
                      onExit: (_) => onHover(null),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          if (trend.isEmpty) return;
                          final index = (details.localPosition.dx / columnWidth)
                              .floor()
                              .clamp(0, trend.length - 1)
                              .toInt();
                          onSelect(index);
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned.fill(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [_Grid(), _Grid(), _Grid()],
                              ),
                            ),
                            Positioned.fill(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  for (
                                    var index = 0;
                                    index < trend.length;
                                    index++
                                  )
                                    Expanded(
                                      child: _DayBars(
                                        day: trend[index],
                                        maxValue: maxValue,
                                        barWidth: barWidth,
                                        height: _height,
                                        showCreated: showCreated,
                                        showPublished: showPublished,
                                        highlighted: active == index,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (active != null && active! < trend.length)
                              Positioned(
                                left: tooltipLeft,
                                top: 0,
                                width: tooltipWidth,
                                child: IgnorePointer(
                                  child: _FlowTooltip(
                                    day: trend[active!],
                                    showCreated: showCreated,
                                    showPublished: showPublished,
                                    locale: locale,
                                    strings: strings,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: _axis),
              child: Row(
                children: [
                  for (var index = 0; index < trend.length; index++)
                    Expanded(
                      child: Text(
                        index % labelEvery == 0
                            ? DateFormat.d(locale)
                                  .format(trend[index].day ?? DateTime.now())
                            : '',
                        textAlign: TextAlign.center,
                        style: Trellis.text(9.5, color: PtTheme.muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DayBars extends StatelessWidget {
  const _DayBars({
    required this.day,
    required this.maxValue,
    required this.barWidth,
    required this.height,
    required this.showCreated,
    required this.showPublished,
    required this.highlighted,
  });

  final PlatformFlowDay day;
  final int maxValue;
  final double barWidth;
  final double height;
  final bool showCreated;
  final bool showPublished;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final usable = height - 10;
    Widget bar(int value, Color color) {
      final barHeight = math.max(2.0, usable * value / maxValue);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: math.max(3.0, math.min(barWidth, 18.0)),
        height: highlighted ? math.min(usable, barHeight + 4) : barHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showCreated) bar(day.created, PtTheme.ink.withValues(alpha: 0.72)),
        if (showCreated && showPublished) const SizedBox(width: 2),
        if (showPublished) bar(day.published, PtTheme.deepGreen),
      ],
    );
  }
}

class _FlowTooltip extends StatelessWidget {
  const _FlowTooltip({
    required this.day,
    required this.showCreated,
    required this.showPublished,
    required this.locale,
    required this.strings,
  });

  final PlatformFlowDay day;
  final bool showCreated;
  final bool showPublished;
  final String locale;
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern(locale);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
        boxShadow: [
          BoxShadow(
            color: PtTheme.ink.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat.MMMEd(locale).format(day.day ?? DateTime.now()),
            style: Trellis.text(11, weight: FontWeight.w700),
          ),
          if (showCreated) ...[
            const SizedBox(height: 4),
            _TooltipRow(
              color: PtTheme.ink.withValues(alpha: 0.72),
              label: strings.tKey(PlatformAdminKeys.dashboardFlowCreated),
              value: number.format(day.created),
            ),
          ],
          if (showPublished) ...[
            const SizedBox(height: 3),
            _TooltipRow(
              color: PtTheme.deepGreen,
              label: strings.tKey(PlatformAdminKeys.dashboardFlowPublished),
              value: number.format(day.published),
            ),
          ],
        ],
      ),
    );
  }
}

class _TooltipRow extends StatelessWidget {
  const _TooltipRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(label, style: Trellis.text(11, color: PtTheme.muted)),
        ),
        Text(value, style: Trellis.text(11.5, weight: FontWeight.w700)),
      ],
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({
    required this.days,
    required this.onChanged,
    required this.strings,
  });

  final int days;
  final ValueChanged<int> onChanged;
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in const [7, 14, 30])
            _RangeChip(
              label: strings.tArgsKey(PlatformAdminKeys.dashboardDays, {
                'count': '$value',
              }),
              selected: value == days,
              onTap: () => onChanged(value),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? PtTheme.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? PtTheme.border : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Trellis.text(
                11.5,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? PtTheme.ink : PtTheme.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesToggle extends StatelessWidget {
  const _SeriesToggle({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.10) : PtTheme.canvas,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.35) : PtTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected
                      ? color
                      : PtTheme.muted.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Trellis.text(
                  11.5,
                  weight: FontWeight.w600,
                  color: selected ? PtTheme.ink : PtTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalStat extends StatelessWidget {
  const _TotalStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(label, style: Trellis.text(11.5, color: PtTheme.muted)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Trellis.text(
            20,
            weight: FontWeight.w800,
            color: PtTheme.ink,
            tabular: true,
          ),
        ),
      ],
    );
  }
}

class _Axis extends StatelessWidget {
  const _Axis({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) =>
      Text('$value', style: Trellis.text(9.5, color: PtTheme.muted));
}

class _Grid extends StatelessWidget {
  const _Grid();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: PtTheme.border.withValues(alpha: 0.7));
}

/// Top workshops by job volume.
class PlatformWorkshopLeadersCard extends StatelessWidget {
  const PlatformWorkshopLeadersCard({
    super.key,
    required this.workshops,
    required this.strings,
    required this.onOpenWorkshops,
  });

  final PlatformDashboardWorkshops workshops;
  final UiMessageStrings strings;
  final VoidCallback onOpenWorkshops;

  @override
  Widget build(BuildContext context) {
    final maxJobs = workshops.top.isEmpty
        ? 1
        : workshops.top
              .map((workshop) => workshop.jobs)
              .fold<int>(1, (best, value) => value > best ? value : best);

    return TrellisSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.tKey(PlatformAdminKeys.dashboardWorkshopsTitle),
                      style: Trellis.sectionTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${workshops.active} / ${workshops.total}',
                      style: Trellis.body,
                    ),
                  ],
                ),
              ),
              TrellisButton(
                label: strings.tKey(PlatformAdminKeys.buttonViewAll),
                onPressed: onOpenWorkshops,
                variant: TrellisButtonVariant.ghost,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: PtTheme.border),
          if (workshops.top.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                strings.tKey(PlatformAdminKeys.dashboardWorkshopsEmpty),
                style: Trellis.body,
              ),
            )
          else
            for (var index = 0; index < workshops.top.length; index++) ...[
              if (index > 0) Container(height: 1, color: PtTheme.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workshops.top[index].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Trellis.text(13, weight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          strings.tArgsKey(
                            PlatformAdminKeys.dashboardWorkshopsJobs,
                            {'count': '${workshops.top[index].jobs}'},
                          ),
                          style: Trellis.text(
                            11.5,
                            weight: FontWeight.w700,
                            color: PtTheme.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 5,
                        color: PtTheme.canvas,
                        child: FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: (workshops.top[index].jobs / maxJobs)
                              .clamp(0, 1),
                          child: const ColoredBox(color: PtTheme.deepGreen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Platform-wide status mix as a donut with a legend.
class PlatformStatusDonutCard extends StatelessWidget {
  const PlatformStatusDonutCard({
    super.key,
    required this.jobs,
    required this.strings,
  });

  final PlatformDashboardJobs jobs;
  final UiMessageStrings strings;

  static const Map<String, Color> _colors = <String, Color>{
    'DRAFT': Color(0xFFC9C6D4),
    'SCHEDULED': Color(0xFF9FA3B2),
    'ASSIGNED': Color(0xFF8FB7FF),
    'IN_PROGRESS': Color(0xFF1D4ED8),
    'PENDING_REVIEW': Color(0xFFF0B26A),
    'APPROVED': Color(0xFF10B981),
    'PUBLISHED': Color(0xFF006C49),
    'REJECTED': Color(0xFFE11D48),
    'CANCELLED': Color(0xFF5E5D69),
  };

  @override
  Widget build(BuildContext context) {
    final entries = jobs.byStatus.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false);
    final total = jobs.byStatus.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    final donut = SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _DonutPainter(
              slices: [
                for (final entry in entries)
                  (entry.value.toDouble(), _colors[entry.key] ?? PtTheme.muted),
              ],
              total: total.toDouble(),
            ),
          ),
          Center(
            child: Text(
              NumberFormat.decimalPattern(
                Localizations.localeOf(context).toString(),
              ).format(total),
              style: Trellis.text(32, weight: FontWeight.w800, tabular: true),
            ),
          ),
        ],
      ),
    );

    final legend = Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _colors[entry.key] ?? PtTheme.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _humanize(entry.key),
                style: Trellis.text(11, color: PtTheme.muted),
              ),
              const SizedBox(width: 5),
              Text(
                '${entry.value}',
                style: Trellis.text(11.5, weight: FontWeight.w700),
              ),
            ],
          ),
      ],
    );

    return TrellisSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.tKey(PlatformAdminKeys.dashboardStatusTitle),
            style: Trellis.sectionTitle,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 520) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    donut,
                    const SizedBox(width: 28),
                    Expanded(child: legend),
                  ],
                );
              }
              return Column(
                children: [donut, const SizedBox(height: 16), legend],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _humanize(String code) {
    final words = code
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty);
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.slices, required this.total});

  final List<(double, Color)> slices;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    const stroke = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = PtTheme.canvas,
    );
    const gap = 0.025;
    var angle = -math.pi / 2;
    for (final (value, color) in slices) {
      final sweep = value / total * math.pi * 2;
      canvas.drawArc(
        rect,
        angle + gap / 2,
        math.max(sweep - gap, 0.008),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.total != total || old.slices.toString() != slices.toString();
}

/// Language pipeline + configuration coverage.
class PlatformLanguagesConfigCard extends StatelessWidget {
  const PlatformLanguagesConfigCard({
    super.key,
    required this.config,
    required this.strings,
  });

  final PlatformDashboardConfig config;
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    final languages =
        config.languagesLive +
        config.languagesTranslating +
        config.languagesReview +
        config.languagesDraft;

    Widget languageRow(String label, int value, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: Trellis.text(12, color: PtTheme.muted)),
          ),
          Text('$value', style: Trellis.text(12.5, weight: FontWeight.w700)),
        ],
      ),
    );

    Widget configRow(String label, int value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Trellis.text(12, color: PtTheme.muted)),
          ),
          Text('$value', style: Trellis.text(12.5, weight: FontWeight.w700)),
        ],
      ),
    );

    return TrellisSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.tKey(PlatformAdminKeys.dashboardLanguagesTitle),
                  style: Trellis.sectionTitle,
                ),
                const SizedBox(height: 12),
                languageRow(
                  strings.tKey(PlatformAdminKeys.dashboardLanguagesLive),
                  config.languagesLive,
                  PtTheme.deepGreen,
                ),
                languageRow(
                  strings.tKey(PlatformAdminKeys.dashboardLanguagesTranslating),
                  config.languagesTranslating,
                  Trellis.blue,
                ),
                languageRow(
                  strings.tKey(PlatformAdminKeys.dashboardLanguagesReview),
                  config.languagesReview,
                  PtTheme.amber,
                ),
                languageRow(
                  strings.tKey(PlatformAdminKeys.dashboardLanguagesDraft),
                  config.languagesDraft,
                  PtTheme.muted,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        if (config.languagesLive > 0)
                          Expanded(
                            flex: config.languagesLive,
                            child: const ColoredBox(color: PtTheme.deepGreen),
                          ),
                        if (config.languagesTranslating > 0)
                          Expanded(
                            flex: config.languagesTranslating,
                            child: const ColoredBox(color: Trellis.blue),
                          ),
                        if (config.languagesReview > 0)
                          Expanded(
                            flex: config.languagesReview,
                            child: const ColoredBox(color: Color(0xFFD97706)),
                          ),
                        if (config.languagesDraft > 0)
                          Expanded(
                            flex: config.languagesDraft,
                            child: const ColoredBox(color: PtTheme.muted),
                          ),
                        if (languages == 0)
                          const Expanded(
                            child: ColoredBox(color: PtTheme.canvas),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(width: 1, height: 150, color: PtTheme.border),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.tKey(PlatformAdminKeys.dashboardConfigTitle),
                  style: Trellis.sectionTitle,
                ),
                const SizedBox(height: 12),
                configRow(
                  strings.tKey(PlatformAdminKeys.dashboardConfigTemplates),
                  config.templates,
                ),
                configRow(
                  strings.tKey(PlatformAdminKeys.dashboardConfigVersions),
                  config.templateVersions,
                ),
                configRow(
                  strings.tKey(PlatformAdminKeys.dashboardConfigItems),
                  config.items,
                ),
                configRow(
                  strings.tKey(PlatformAdminKeys.dashboardConfigCategories),
                  config.categories,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Delivery side: reports, documents, public links, export volume.
class PlatformReportsCard extends StatelessWidget {
  const PlatformReportsCard({
    super.key,
    required this.reports,
    required this.strings,
  });

  final PlatformDashboardReports reports;
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final documents = reports.readyDocuments + reports.failedDocuments;
    final health = documents == 0 ? 0.0 : reports.readyDocuments / documents;

    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Trellis.text(12, color: PtTheme.muted)),
          ),
          Text(
            value,
            style: Trellis.text(
              12.5,
              weight: FontWeight.w700,
              color: color ?? PtTheme.ink,
            ),
          ),
        ],
      ),
    );

    return TrellisSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.tKey(PlatformAdminKeys.dashboardReportsTitle),
            style: Trellis.sectionTitle,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Big(
                  label: strings.tKey(PlatformAdminKeys.dashboardFlowPublished),
                  value: number.format(reports.published),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Big(
                  label: strings.tKey(
                    PlatformAdminKeys.dashboardReportsActiveLinks,
                  ),
                  value: number.format(reports.activeLinks),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          row(
            strings.tKey(PlatformAdminKeys.dashboardReportsVersions),
            number.format(reports.versions),
          ),
          row(
            strings.tKey(PlatformAdminKeys.dashboardReportsDocumentsReady),
            number.format(reports.readyDocuments),
          ),
          row(
            strings.tKey(PlatformAdminKeys.dashboardReportsDocumentsFailed),
            number.format(reports.failedDocuments),
            color: reports.failedDocuments > 0 ? PtTheme.rose : null,
          ),
          row(
            strings.tKey(PlatformAdminKeys.dashboardReportsExports),
            _bytes(reports.exportBytes),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              color: PtTheme.canvas,
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: health.clamp(0, 1),
                child: const ColoredBox(color: PtTheme.deepGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _bytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Trellis.text(11, color: PtTheme.muted)),
        const SizedBox(height: 3),
        Text(
          value,
          style: Trellis.text(30, weight: FontWeight.w800, tabular: true),
        ),
      ],
    );
  }
}

/// Compact KPI strip for the platform dashboard.
class PlatformKpiStrip extends StatelessWidget {
  const PlatformKpiStrip({
    super.key,
    required this.data,
    required this.strings,
  });

  final PlatformDashboard data;
  final UiMessageStrings strings;

  @override
  Widget build(BuildContext context) {
    final tiles = <_Kpi>[
      _Kpi(
        label: strings.tKey(PlatformAdminKeys.kpiWorkshopsActive),
        value: '${data.workshops.active}',
        caption: '${data.workshops.active} / ${data.workshops.total}',
        color: PtTheme.deepGreen,
      ),
      _Kpi(
        label: strings.tKey(PlatformAdminKeys.kpiTechnicians),
        value: '${data.staff.technicians}',
        color: Trellis.blue,
      ),
      _Kpi(
        label: strings.tKey(PlatformAdminKeys.kpiJobsActive),
        value: '${data.jobs.active}',
        color: Trellis.blue,
      ),
      _Kpi(
        label: strings.tKey(PlatformAdminKeys.kpiReportsPublished),
        value: '${data.reports.published}',
        color: PtTheme.deepGreen,
      ),
    ];

    Widget tile(_Kpi item) => Expanded(
      child: TrellisSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.label,
                    style: Trellis.text(11.5, color: PtTheme.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.value,
                  style: Trellis.text(
                    36,
                    weight: FontWeight.w800,
                    tabular: true,
                  ),
                ),
                if (item.caption != null) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      item.caption!,
                      style: Trellis.text(10.5, color: PtTheme.muted),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                tile(tiles[index]),
              ],
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                tile(tiles[0]),
                const SizedBox(width: 12),
                tile(tiles[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                tile(tiles[2]),
                const SizedBox(width: 12),
                tile(tiles[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Kpi {
  const _Kpi({
    required this.label,
    required this.value,
    required this.color,
    this.caption,
  });

  final String label;
  final String value;
  final Color color;
  final String? caption;
}
