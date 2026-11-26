import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Job flow: created vs published per day, for 7 / 14 / 30 days.
///
/// Interactive on purpose: hover or tap a day for its counts, switch either
/// series off, and change the window — each change refetches the whole
/// insights payload so every card on the page shows the same range.
class DashboardFlowCard extends StatefulWidget {
  const DashboardFlowCard({
    required this.data,
    required this.days,
    required this.onDaysChanged,
    this.refreshing = false,
    super.key,
  });

  final WorkshopDashboard data;
  final int days;
  final ValueChanged<int> onDaysChanged;
  final bool refreshing;

  @override
  State<DashboardFlowCard> createState() => _DashboardFlowCardState();
}

class _DashboardFlowCardState extends State<DashboardFlowCard> {
  int? _hovered;
  int? _pinned;
  bool _showCreated = true;
  bool _showPublished = true;

  int? get _active => _hovered ?? _pinned;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final trend = widget.data.trend;
    final locale = Localizations.localeOf(context).toString();

    final totalCreated = trend.fold<int>(0, (sum, day) => sum + day.created);
    final totalPublished = trend.fold<int>(
      0,
      (sum, day) => sum + day.published,
    );
    final hasActivity = (totalCreated + totalPublished) > 0 && trend.isNotEmpty;

    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(DashboardShape.card),
        border: Border.all(color: ws.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeader = constraints.maxWidth < 560;
          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t(WorkshopAdminKeys.dashFlowTitle),
                      style: DashboardType.cardTitle(ws),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t(WorkshopAdminKeys.dashFlowSubtitle),
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ),
              ),
              if (!compactHeader) ...[
                const SizedBox(width: 12),
                _RangeControl(
                  days: widget.days,
                  onChanged: widget.onDaysChanged,
                ),
              ],
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (compactHeader) ...[
                header,
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _RangeControl(
                    days: widget.days,
                    onChanged: widget.onDaysChanged,
                  ),
                ),
              ] else
                header,
              const SizedBox(height: 16),
              if (widget.refreshing)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 10),
                  child: Container(
                    height: 2,
                    color: ws.accent.withValues(alpha: 0.35),
                  ),
                ),
              Row(
                children: [
                  _SeriesToggle(
                    label: t(WorkshopAdminKeys.dashFlowCreated),
                    color: _createdColor(ws),
                    selected: _showCreated,
                    onTap: () {
                      if (_showCreated && !_showPublished) {
                        return;
                      }
                      setState(() => _showCreated = !_showCreated);
                    },
                  ),
                  const SizedBox(width: 8),
                  _SeriesToggle(
                    label: t(WorkshopAdminKeys.dashFlowPublished),
                    color: ws.success,
                    selected: _showPublished,
                    onTap: () {
                      if (_showPublished && !_showCreated) {
                        return;
                      }
                      setState(() => _showPublished = !_showPublished);
                    },
                  ),
                  const Spacer(),
                  if (_active != null && _active! < trend.length)
                    Text(
                      DateFormat.MMMEd(locale)
                          .format(trend[_active!].day ?? DateTime.now()),
                      style: DashboardType.bandMeta(ws),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (!hasActivity)
                SizedBox(
                  height: 190,
                  child: Center(
                    child: Text(
                      t(WorkshopAdminKeys.dashFlowEmpty),
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ),
                )
              else
                _Chart(
                  trend: trend,
                  showCreated: _showCreated,
                  showPublished: _showPublished,
                  hovered: _active,
                  onHover: (index) => setState(() => _hovered = index),
                  onSelect: (index) => setState(() {
                    _pinned = _pinned == index ? null : index;
                  }),
                ),
              const SizedBox(height: 18),
              Container(height: 1, color: ws.border),
              const SizedBox(height: 14),
              Wrap(
                spacing: 28,
                runSpacing: 12,
                children: [
                  _FooterStat(
                    label: t(WorkshopAdminKeys.dashFlowCreated),
                    value: NumberFormat.decimalPattern(locale)
                        .format(totalCreated),
                    color: _createdColor(ws),
                  ),
                  _FooterStat(
                    label: t(WorkshopAdminKeys.dashFlowPublished),
                    value: NumberFormat.decimalPattern(locale)
                        .format(totalPublished),
                    color: ws.success,
                  ),
                  if (widget.data.turnaround.averageMinutes != null)
                    _FooterStat(
                      label: t(WorkshopAdminKeys.dashTurnaround),
                      value: t(WorkshopAdminKeys.dashTurnaroundValue, {
                        'hours': (widget.data.turnaround.averageMinutes! / 60)
                            .toStringAsFixed(1),
                      }),
                      color: ws.warning,
                    ),
                  if (widget.data.quality.averageScore != null)
                    _FooterStat(
                      label: t(WorkshopAdminKeys.dashQuality),
                      value: t(WorkshopAdminKeys.dashQualityValue, {
                        'score': widget.data.quality.averageScore,
                      }),
                      color: ws.muted,
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

class _Chart extends StatelessWidget {
  const _Chart({
    required this.trend,
    required this.showCreated,
    required this.showPublished,
    required this.hovered,
    required this.onHover,
    required this.onSelect,
  });

  final List<DashboardFlow> trend;
  final bool showCreated;
  final bool showPublished;
  final int? hovered;
  final ValueChanged<int?> onHover;
  final ValueChanged<int> onSelect;

  static const double _height = 190;
  static const double _axisWidth = 28;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final locale = Localizations.localeOf(context).toString();
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
        final chartWidth = constraints.maxWidth - _axisWidth;
        final columnWidth = trend.isEmpty
            ? chartWidth
            : chartWidth / trend.length;
        final barWidth = columnWidth * 0.28;
        final active = hovered;
        final tooltipWidth = math.min(168.0, chartWidth);
        final tooltipLeft = active == null
            ? 0.0
            : ((active + 0.5) * columnWidth - tooltipWidth / 2)
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
                    width: _axisWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AxisLabel(value: maxValue),
                        _AxisLabel(value: (maxValue / 2).round()),
                        const _AxisLabel(value: 0),
                      ],
                    ),
                  ),
                  Expanded(
                    child: MouseRegion(
                      onHover: (event) {
                        if (trend.isEmpty) {
                          return;
                        }
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
                          if (trend.isEmpty) {
                            return;
                          }
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
                                children: [
                                  _GridLine(),
                                  _GridLine(),
                                  _GridLine(),
                                ],
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
                            if (active != null && active < trend.length)
                              Positioned(
                                left: tooltipLeft,
                                top: 0,
                                width: tooltipWidth,
                                child: _Tooltip(
                                  day: trend[active],
                                  showCreated: showCreated,
                                  showPublished: showPublished,
                                  locale: locale,
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
              padding: const EdgeInsetsDirectional.only(start: _axisWidth),
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
                        style: ws.meta.copyWith(fontSize: 9.5, color: ws.muted),
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

  final DashboardFlow day;
  final int maxValue;
  final double barWidth;
  final double height;
  final bool showCreated;
  final bool showPublished;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final usable = height - 10;

    Widget bar(int value, Color color) {
      final barHeight = math.max(2.0, usable * value / maxValue);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
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
        if (showCreated) bar(day.created, _createdColor(ws)),
        if (showCreated && showPublished) const SizedBox(width: 2),
        if (showPublished) bar(day.published, ws.success),
      ],
    );
  }
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({
    required this.day,
    required this.showCreated,
    required this.showPublished,
    required this.locale,
  });

  final DashboardFlow day;
  final bool showCreated;
  final bool showPublished;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final number = NumberFormat.decimalPattern(locale);
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsetsDirectional.all(10),
        decoration: BoxDecoration(
          color: ws.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ws.border),
          boxShadow: [
            BoxShadow(
              color: ws.ink.withValues(alpha: 0.10),
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
              style: ws.meta.copyWith(
                fontWeight: FontWeight.w600,
                color: ws.ink,
              ),
            ),
            if (showCreated) ...[
              const SizedBox(height: 4),
              _TooltipRow(
                color: _createdColor(ws),
                label: t(WorkshopAdminKeys.dashFlowCreated),
                value: number.format(day.created),
              ),
            ],
            if (showPublished) ...[
              const SizedBox(height: 3),
              _TooltipRow(
                color: ws.success,
                label: t(WorkshopAdminKeys.dashFlowPublished),
                value: number.format(day.published),
              ),
            ],
          ],
        ),
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
    final ws = context.ws;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Expanded(child: Text(label, style: DashboardType.registerLabel(ws))),
        Text(value, style: DashboardType.registerCount(ws)),
      ],
    );
  }
}

class _RangeControl extends StatelessWidget {
  const _RangeControl({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ws.canvas,
        borderRadius: BorderRadius.circular(DashboardShape.pill),
        border: Border.all(color: ws.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in const [7, 14, 30])
            _RangeItem(
              label: t(WorkshopAdminKeys.dashDays, {'count': value}),
              selected: value == days,
              onTap: () => onChanged(value),
            ),
        ],
      ),
    );
  }
}

class _RangeItem extends StatefulWidget {
  const _RangeItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RangeItem> createState() => _RangeItemState();
}

class _RangeItemState extends State<_RangeItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: DashboardMotion.settle,
            height: 38,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.selected
                  ? ws.surface
                  : (_hovered
                        ? ws.surface.withValues(alpha: 0.6)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(DashboardShape.pill),
              border: Border.all(
                color: widget.selected ? ws.border : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: ws.meta.copyWith(
                  fontSize: 11.5,
                  fontWeight: widget.selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: widget.selected ? ws.ink : ws.muted,
                ),
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
    final ws = context.ws;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: DashboardMotion.settle,
            height: 28,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.12) : ws.canvas,
              borderRadius: BorderRadius.circular(DashboardShape.pill),
              border: Border.all(
                color: selected ? color.withValues(alpha: 0.35) : ws.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? color : ws.muted.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: ws.meta.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? ws.ink : ws.muted,
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

class _FooterStat extends StatelessWidget {
  const _FooterStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
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
            Text(
              label,
              style: ws.meta.copyWith(fontSize: 11.5, color: ws.muted),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: ws.body.copyWith(
            fontSize: 20,
            height: 26 / 20,
            fontWeight: FontWeight.w800,
            color: ws.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Text(
      '$value',
      style: ws.meta.copyWith(fontSize: 9.5, color: ws.muted),
    );
  }
}

class _GridLine extends StatelessWidget {
  const _GridLine();

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(height: 1, color: ws.border.withValues(alpha: 0.6));
  }
}

Color _createdColor(WorkshopTokens ws) => ws.ink.withValues(alpha: 0.72);
