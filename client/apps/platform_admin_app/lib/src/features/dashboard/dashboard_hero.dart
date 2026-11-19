import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';
import 'dashboard_data.dart';
import 'dashboard_palette.dart';
import 'dashboard_primitives.dart';

/// The one focal point of the dashboard: verdict, lifecycle band and the three
/// numbers an operator checks before opening anything else.
class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.summary,
    required this.strings,
    required this.segments,
    required this.attentionCount,
    required this.onRefresh,
    required this.onReviewHealth,
  });

  final OverviewSummary summary;
  final UiMessageStrings strings;
  final List<DashboardRailSegment> segments;
  final int attentionCount;
  final VoidCallback onRefresh;
  final VoidCallback onReviewHealth;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final healthy = attentionCount == 0;
    final verdict = strings.tKey(
      healthy
          ? PlatformAdminKeys.dashboardStatusHealthy
          : PlatformAdminKeys.dashboardStatusAttention,
    );
    final verdictBody = healthy
        ? strings.tKey(PlatformAdminKeys.dashboardStatusHealthySubtitle)
        : strings.tArgsKey(PlatformAdminKeys.dashboardStatusAttentionSubtitle, {
            'count': '$attentionCount',
          });

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.slabTop, palette.slabBottom],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _SlabGrid())),
            ),
            PositionedDirectional(
              top: -110,
              end: -70,
              child: IgnorePointer(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        palette.accent.withValues(alpha: 0.32),
                        palette.accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 22, 24, 22),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  final verdictBlock = _VerdictBlock(
                    eyebrow: strings.tKey(PlatformAdminKeys.pageDashboardTitle),
                    verdict: verdict,
                    body: verdictBody,
                    healthy: healthy,
                  );
                  final stats = _HeroStats(
                    summary: summary,
                    strings: strings,
                    compact: compact,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (compact) ...[
                        verdictBlock,
                        const SizedBox(height: 22),
                        stats,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: verdictBlock),
                            const SizedBox(width: 28),
                            Expanded(flex: 5, child: stats),
                          ],
                        ),
                      if (segments.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        const SizedBox(height: 16),
                        DashboardEyebrow(
                          strings.tKey(PlatformAdminKeys.chartJobsByStatus),
                          color: palette.onSlabMuted,
                        ),
                        const SizedBox(height: 10),
                        DashboardRail(
                          segments: segments,
                          onSlab: true,
                          showLegend: true,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _SlabPrimaryButton(
                            label: strings.tKey(
                              PlatformAdminKeys.buttonHealthReview,
                            ),
                            onPressed: onReviewHealth,
                          ),
                          _SlabGhostButton(
                            label: strings.tKey(CommonKeys.buttonRefresh),
                            onPressed: onRefresh,
                            buttonKey: const Key('btn-dashboard-refresh'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerdictBlock extends StatelessWidget {
  const _VerdictBlock({
    required this.eyebrow,
    required this.verdict,
    required this.body,
    required this.healthy,
  });

  final String eyebrow;
  final String verdict;
  final String body;
  final bool healthy;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final dot = healthy ? palette.railA : palette.railWarn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusDot(color: dot),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                eyebrow.toUpperCase(),
                style: DashboardType.eyebrow(palette.onSlabMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final style = constraints.maxWidth < 420
                ? DashboardType.heroCompact(palette.onSlab)
                : DashboardType.hero(palette.onSlab);
            return Text(verdict, style: style, maxLines: 3);
          },
        ),
        const SizedBox(height: 6),
        Text(body, style: DashboardType.meta(palette.onSlabMuted)),
      ],
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({
    required this.summary,
    required this.strings,
    required this.compact,
  });

  final OverviewSummary summary;
  final UiMessageStrings strings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final stats = [
      (
        strings.tKey(PlatformAdminKeys.kpiWorkshopsActive),
        summary.workshops.active,
      ),
      (
        strings.tKey(PlatformAdminKeys.kpiReportsPublished),
        summary.reports.published,
      ),
      (
        strings.tKey(PlatformAdminKeys.kpiLanguagesLive),
        summary.languages.live,
      ),
    ];

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        border: compact
            ? null
            : BorderDirectional(
                start: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: compact ? 8 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '${stats[i].$2}',
                        style: compact
                            ? DashboardType.statCompact(palette.onSlab)
                            : DashboardType.stat(palette.onSlab),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (compact)
                      Text(
                        stats[i].$1,
                        style: DashboardType.meta(palette.onSlabMuted).copyWith(
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                        maxLines: 2,
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          stats[i].$1,
                          style: DashboardType.meta(palette.onSlabMuted)
                              .copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                height: 1.3,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.22),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}

class _SlabPrimaryButton extends StatelessWidget {
  const _SlabPrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: _ButtonShell(
        base: const Color(0xFFF3F7F3),
        hover: Colors.white,
        foreground: palette.slabTop,
        label: label,
        onPressed: onPressed,
      ),
    );
  }
}

class _SlabGhostButton extends StatelessWidget {
  const _SlabGhostButton({
    required this.label,
    required this.onPressed,
    required this.buttonKey,
  });

  final String label;
  final VoidCallback onPressed;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      child: _ButtonShell(
        buttonKey: buttonKey,
        base: Colors.transparent,
        hover: Colors.white.withValues(alpha: 0.10),
        foreground: palette.onSlab,
        border: Colors.white.withValues(alpha: 0.18),
        label: label,
        icon: Icons.refresh_rounded,
        onPressed: onPressed,
      ),
    );
  }
}

class _ButtonShell extends StatefulWidget {
  const _ButtonShell({
    required this.base,
    required this.hover,
    required this.foreground,
    required this.label,
    required this.onPressed,
    this.border,
    this.icon,
    this.buttonKey,
  });

  final Color base;
  final Color hover;
  final Color foreground;
  final String label;
  final VoidCallback onPressed;
  final Color? border;
  final IconData? icon;
  final Key? buttonKey;

  @override
  State<_ButtonShell> createState() => _ButtonShellState();
}

class _ButtonShellState extends State<_ButtonShell> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: GestureDetector(
        key: widget.buttonKey,
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: 44,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _hovered ? widget.hover : widget.base,
                  borderRadius: BorderRadius.circular(10),
                  border: widget.border == null
                      ? null
                      : Border.all(color: widget.border!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 15,
                        color: widget.foreground.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      widget.label,
                      style: DashboardType.button(widget.foreground),
                    ),
                    if (widget.icon == null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: widget.foreground,
                      ),
                    ],
                  ],
                ),
              ),
              if (_focused)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.accent, width: 2),
                      ),
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

class _SlabGrid extends CustomPainter {
  const _SlabGrid();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const pitch = 56.0;
    for (var x = 0.0; x <= size.width; x += pitch) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += pitch) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
