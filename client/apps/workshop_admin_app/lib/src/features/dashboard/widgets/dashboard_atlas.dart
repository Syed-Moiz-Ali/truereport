import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One slice of the workshop's jobs-by-status partition.
@immutable
class AtlasSegment {
  const AtlasSegment({
    required this.status,
    required this.label,
    required this.count,
    required this.color,
    this.isRemainder = false,
  });

  /// Server status value, or `__other__` for the remainder segment.
  final String status;
  final String label;
  final int count;
  final Color color;
  final bool isRemainder;

  Key get key => Key('dashboard-segment-$status');
}

/// The nine-segment partition that is the page's spine (direction B).
///
/// Truth rules it enforces:
/// - segments are laid out by their real counts, never rescaled;
/// - a zero-count segment draws nothing but still appears in the legend;
/// - when [total] exceeds the sum of the segments, the caller passes a
///   remainder segment, so the bar can never claim a false whole;
/// - the legend is the accessible equivalent, and is always present.
class DashboardAtlas extends StatelessWidget {
  const DashboardAtlas({
    required this.segments,
    required this.total,
    required this.height,
    this.semanticLabel,
    super.key,
  });

  final List<AtlasSegment> segments;

  /// Workshop total. `0` means the caller should not render the atlas at all.
  final int total;

  /// Bar height. `0` (or less) renders the vertical spine instead.
  final double height;

  final String? semanticLabel;

  bool get _spine => height <= 0;

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.count > 0).toList(growable: false);
    return Semantics(
      label: semanticLabel,
      container: true,
      child: _spine
          ? _Spine(segments: segments, total: total)
          : _Horizontal(
              segments: segments,
              visible: visible,
              total: total,
              height: height,
            ),
    );
  }
}

class _Horizontal extends StatelessWidget {
  const _Horizontal({
    required this.segments,
    required this.visible,
    required this.total,
    required this.height,
  });

  final List<AtlasSegment> segments;
  final List<AtlasSegment> visible;
  final int total;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final safeTotal = total <= 0
        ? visible.fold<int>(0, (sum, s) => sum + s.count)
        : total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: SizedBox(
            key: const Key('dashboard-atlas-bar'),
            height: height,
            child: TweenAnimationBuilder<double>(
              // One motion on the page: the partition grows once into the
              // reading direction, then never moves again. Disabled when the
              // platform asks for reduced motion.
              tween: Tween<double>(
                begin: ReduceMotion.enabled(context) ? 0 : 1,
                end: 1,
              ),
              duration: ReduceMotion.duration(
                context,
                const Duration(milliseconds: 260),
              ),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: t,
                  child: child,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final segment in visible)
                    Expanded(
                      flex: segment.count,
                      child: Semantics(
                        label: '${segment.label}, ${segment.count}',
                        child: ColoredBox(
                          key: segment.key,
                          color: segment.color,
                        ),
                      ),
                    ),
                  // Unaccounted jobs (a status the client does not know) are
                  // drawn as a neutral tail rather than dropped.
                  if (safeTotal > visible.fold<int>(0, (s, e) => s + e.count))
                    Expanded(
                      flex:
                          safeTotal -
                          visible.fold<int>(0, (s, e) => s + e.count),
                      child: ColoredBox(
                        color: ws.muted.withValues(alpha: 0.18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.md),
        // A legend, not a ruler. An earlier version spread the nine labels in a
        // fixed grid under a bar whose widths come from data, so "Pending
        // review" printed beneath the in-progress block — the gate caught it.
        // Items now size to their content and wrap, so no label ever claims a
        // segment it does not describe, and no label breaks mid-word at 2x.
        Wrap(
          spacing: spacing.lg,
          runSpacing: spacing.sm,
          children: [
            for (final segment in segments)
              _LegendItem(
                key: Key('dashboard-legend-${segment.status}'),
                segment: segment,
                total: safeTotal,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.segment, required this.total, super.key});

  final AtlasSegment segment;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 6, bottom: spacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: segment.count == 0 ? ws.border : segment.color,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              SizedBox(width: spacing.xs),
              Text(
                '${segment.count}',
                style:
                    (segment.count == 0
                            ? ws.bodyStrong.copyWith(color: ws.muted)
                            : ws.bodyStrong)
                        .copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          ConstrainedBox(
            // Long labels wrap on spaces inside a bounded box; unbounded they
            // would push the whole wrap row wider than the page at 2x.
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              segment.label,
              maxLines: 2,
              softWrap: true,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Phone / tablet spine: one row per status, ordered, proportional bar behind
/// the name. Replaces the horizontal atlas below 768 px.
class _Spine extends StatelessWidget {
  const _Spine({required this.segments, required this.total});

  final List<AtlasSegment> segments;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final safeTotal = total <= 0
        ? segments.fold<int>(0, (sum, s) => sum + s.count)
        : total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final segment in segments)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: Semantics(
              label: '${segment.label}, ${segment.count}',
              child: Row(
                children: [
                  // The label gets a proportional share, not a fixed 96 px, so
                  // a 2x text scale wraps it instead of truncating it to
                  // "Sched…".
                  Expanded(
                    flex: 5,
                    child: Text(segment.label, maxLines: 2, style: ws.meta),
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    flex: 6,
                    child: Stack(
                      children: [
                        Container(height: 10, color: ws.surface),
                        FractionallySizedBox(
                          widthFactor: safeTotal == 0
                              ? 0
                              : (segment.count / safeTotal).clamp(0.0, 1.0),
                          child: Container(
                            key: segment.key,
                            height: 10,
                            color: segment.count == 0
                                ? ws.border
                                : segment.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${segment.count}',
                      textAlign: TextAlign.end,
                      style: ws.bodyStrong.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
