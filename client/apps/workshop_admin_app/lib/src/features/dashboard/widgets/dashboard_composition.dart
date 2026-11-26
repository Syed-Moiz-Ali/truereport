import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tokens.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Status composition as a donut plus the full status register.
///
/// One ring, one legend, one published ratio. Every number is a served count —
/// no sampled trend, no estimate.
class DashboardComposition extends StatelessWidget {
  const DashboardComposition({
    required this.counts,
    required this.statuses,
    super.key,
  });

  final CleanJobCounts counts;
  final List<ReferenceRecord>? statuses;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);

    final slices = <_Slice>[
      for (final code in dashboardStatusOrder)
        if (dashboardStatusCount(counts, code) > 0)
          _Slice(
            label: referenceStatusText(statuses, code),
            count: dashboardStatusCount(counts, code),
            color: dashboardToneColor(referenceStatusTone(statuses, code), ws),
          ),
    ];
    final accounted = slices.fold<int>(0, (sum, slice) => sum + slice.count);
    final other = counts.total - accounted;
    if (other > 0) {
      slices.add(
        _Slice(
          label: t(WorkshopAdminKeys.dashSegmentOther),
          count: other,
          color: ws.muted.withValues(alpha: 0.45),
        ),
      );
    }

    final legend = <_Legend>[
      for (final code in dashboardStatusOrder)
        _Legend(
          label: referenceStatusText(statuses, code),
          count: dashboardStatusCount(counts, code),
          color: dashboardToneColor(referenceStatusTone(statuses, code), ws),
        ),
      if (other > 0)
        _Legend(
          label: t(WorkshopAdminKeys.dashSegmentOther),
          count: other,
          color: ws.muted.withValues(alpha: 0.45),
        ),
    ];

    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(DashboardShape.card),
        border: Border.all(color: ws.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 480;
          final donut = _Donut(
            slices: slices,
            total: counts.total,
            label: t(WorkshopAdminKeys.dashFloorLabel),
          );
          final register = _Register(items: legend);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t(WorkshopAdminKeys.dashJobsByStatus),
                      style: DashboardType.cardTitle(ws),
                    ),
                  ),
                ],
              ),
              SizedBox(height: wide ? 16 : 20),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    donut,
                    const SizedBox(width: 28),
                    Expanded(child: register),
                  ],
                )
              else ...[
                Center(child: donut),
                const SizedBox(height: 20),
                register,
              ],
              const SizedBox(height: 18),
              _PublishedMeter(counts: counts),
            ],
          );
        },
      ),
    );
  }
}

class _Slice {
  const _Slice({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;
}

class _Legend {
  const _Legend({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class _Donut extends StatelessWidget {
  const _Donut({
    required this.slices,
    required this.total,
    required this.label,
  });

  final List<_Slice> slices;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final summary = slices.map((s) => '${s.label} ${s.count}').join(', ');
    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: SizedBox(
        width: 168,
        height: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _DonutPainter(
                slices: [
                  for (final slice in slices)
                    (slice.count.toDouble(), slice.color),
                ],
                total: total.toDouble(),
                track: ws.canvas,
              ),
            ),
            Center(
              child: SizedBox(
                width: 104,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat.decimalPattern(
                        Localizations.localeOf(context).toString(),
                      ).format(total),
                      style: DashboardType.tileNumber(ws),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: ws.meta.copyWith(
                        fontSize: 10.5,
                        height: 14 / 10.5,
                        color: ws.muted,
                      ),
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

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.slices,
    required this.total,
    required this.track,
  });

  final List<(double, Color)> slices;
  final double total;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) {
      return;
    }
    const stroke = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    const gap = 0.022;
    var angle = -math.pi / 2;
    for (final (value, color) in slices) {
      final sweep = value / total * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color
        ..strokeCap = StrokeCap.butt;
      final usable = math.max(sweep - gap, 0.008);
      canvas.drawArc(rect, angle + gap / 2, usable, false, paint);
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) {
    return old.total != total ||
        old.track != track ||
        old.slices.length != slices.length;
  }
}

class _Register extends StatelessWidget {
  const _Register({required this.items});

  final List<_Legend> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: [for (final item in items) _RegisterItem(item: item)],
    );
  }
}

class _RegisterItem extends StatelessWidget {
  const _RegisterItem({required this.item});

  final _Legend item;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: item.count == 0
                ? item.color.withValues(alpha: 0.28)
                : item.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(item.label, style: DashboardType.registerLabel(ws)),
        const SizedBox(width: 5),
        Text(
          '${item.count}',
          style: DashboardType.registerCount(ws)
              .copyWith(color: item.count == 0 ? ws.muted : ws.ink),
        ),
      ],
    );
  }
}

class _PublishedMeter extends StatelessWidget {
  const _PublishedMeter({required this.counts});

  final CleanJobCounts counts;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final total = counts.total;
    final fraction = total <= 0 ? 0.0 : counts.published / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: ws.border),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                t(WorkshopAdminKeys.dashPublishedReports),
                style: DashboardType.registerLabel(ws),
              ),
            ),
            Text(
              '${counts.published} / $total',
              style: DashboardType.registerCount(ws),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(DashboardShape.pill),
          child: Container(
            height: 6,
            color: ws.canvas,
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction.clamp(0, 1),
              child: ColoredBox(color: ws.success),
            ),
          ),
        ),
      ],
    );
  }
}
