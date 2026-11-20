import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'dash_strings.dart';

final sprintStrings = UiMessageStrings(
  catalogs: const {
    'en': {'platform_admin': sprintPlatformAdminEn, 'common': sprintCommonEn},
  },
  activeLanguage: 'en',
  defaultLanguage: 'en',
);

abstract final class Pal {
  static const canvas = Color(0xFFF4F3F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFF8F7FB);
  static const border = Color(0xFFE9E7ED);
  static const ink = Color(0xFF1A1B1F);
  static const muted = Color(0xFF5E5D69);
  static const faint = Color(0xFF8E8B99);
  static const green = Color(0xFF006C49);
  static const greenDeep = Color(0xFF0B3B2E);
  static const greenTint = Color(0xFFE9F3EF);
  static const gold = Color(0xFFB45309);
  static const amber = Color(0xFFD97706);
  static const amberTint = Color(0xFFFBF1E2);
  static const rose = Color(0xFFE11D48);
  static const roseTint = Color(0xFFFCEBEF);
  static const blue = Color(0xFF1D4ED8);
  static const blueTint = Color(0xFFE9EEFC);
}

TextStyle txt(
  double size, {
  FontWeight weight = FontWeight.w400,
  double height = 1.3,
  double tracking = 0,
  Color color = Pal.ink,
  bool tabular = false,
}) {
  return TextStyle(
    fontFamily: TrFonts.latin,
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: tracking,
    color: color,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );
}

final TextStyle eyebrowStyle = txt(
  10.5,
  weight: FontWeight.w800,
  tracking: 1.1,
  color: Pal.faint,
);

class SprintDemo {
  static const workshopsTotal = 10;
  static const workshopsActive = 8;
  static const technicians = 62;
  static const admins = 14;
  static const jobsActive = 37;
  static const pendingReview = 3;
  static const reportsPublished = 128;
  static const checklistIssues = 2;
  static const categories = 24;
  static const items = 412;
  static const templates = 9;
  static const languagesLive = 2;
  static const languagesSetup = 1;

  static const jobsByStatus = <String, int>{
    'SCHEDULED': 9,
    'IN_PROGRESS': 18,
    'AWAITING_REVIEW': 6,
    'COMPLETED': 4,
  };

  static const reportsByMonth = <String, int>{
    'Jun': 8,
    'Jul': 12,
    'Aug': 11,
    'Sep': 15,
    'Oct': 19,
    'Nov': 14,
  };

  static int get attentionCount => 3;
  static int get staffTotal => technicians + admins;
}

class SprintShell extends StatelessWidget {
  const SprintShell({
    super.key,
    required this.rtl,
    required this.child,
    this.active = 0,
  });

  final bool rtl;
  final Widget child;
  final int active;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        return Scaffold(
          backgroundColor: Pal.canvas,
          body: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Sidebar(rtl: rtl, active: active),
                    Expanded(
                      child: Column(
                        children: [
                          _Header(rtl: rtl, wide: true),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _Header(rtl: rtl, wide: false),
                    Expanded(child: child),
                  ],
                ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.rtl, required this.active});

  final bool rtl;
  final int active;

  static const _keys = [
    PlatformAdminKeys.navDashboard,
    PlatformAdminKeys.navWorkshops,
    PlatformAdminKeys.navChecklist,
    PlatformAdminKeys.navReports,
    PlatformAdminKeys.pageAuditTitle,
    PlatformAdminKeys.pageSettingsTitle,
  ];

  static const _icons = [
    Icons.grid_view_rounded,
    Icons.storefront_outlined,
    Icons.rule_folder_outlined,
    Icons.description_outlined,
    Icons.history_rounded,
    Icons.tune_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Pal.surface,
        border: BorderDirectional(end: BorderSide(color: Pal.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Pal.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TrueReport',
                        style: txt(15, weight: FontWeight.w800, tracking: -0.2),
                      ),
                      Text(
                        rtl ? 'منصة الإدارة' : 'Platform console',
                        style: txt(10.5, color: Pal.faint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Pal.border),
          const SizedBox(height: 14),
          for (var i = 0; i < _keys.length; i++)
            _NavItem(
              label: sprintStrings.tKey(_keys[i]),
              icon: _icons[i],
              active: i == active,
            ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Pal.surfaceTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Pal.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Pal.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  sprintStrings.tKey(PlatformAdminKeys.dashboardStatusHealthy),
                  style: txt(10.5, weight: FontWeight.w600, color: Pal.muted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Pal.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Pal.greenTint,
                  child: Text(
                    'LA',
                    style: TextStyle(
                      fontFamily: TrFonts.latin,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Pal.green,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Layla Al Ameri',
                      style: txt(12, weight: FontWeight.w700),
                    ),
                    Text(
                      rtl ? 'مدير المنصة' : 'Platform admin',
                      style: txt(10.5, color: Pal.faint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: widget.active
              ? Pal.greenTint
              : _hover
              ? Pal.surfaceTint
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 18,
              color: widget.active ? Pal.green : Pal.muted,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                widget.label,
                style: txt(
                  12.5,
                  weight: widget.active ? FontWeight.w700 : FontWeight.w500,
                  color: widget.active ? Pal.greenDeep : Pal.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.rtl, required this.wide});

  final bool rtl;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: wide ? 64 : 56,
      padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 16),
      decoration: const BoxDecoration(
        color: Pal.surface,
        border: Border(bottom: BorderSide(color: Pal.border)),
      ),
      child: Row(
        children: [
          if (!wide) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Pal.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.radar_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(rtl ? 'المنصة' : 'Platform', style: txt(12, color: Pal.faint)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right_rounded, size: 15, color: Pal.faint),
          ),
          Text(
            sprintStrings.tKey(PlatformAdminKeys.pageDashboardTitle),
            style: txt(12, weight: FontWeight.w700),
          ),
          const Spacer(),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Pal.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Pal.border),
            ),
            child: const Icon(Icons.refresh_rounded, size: 17, color: Pal.muted),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 17,
            backgroundColor: Pal.greenTint,
            child: Text(
              'LA',
              style: TextStyle(
                fontFamily: TrFonts.latin,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Pal.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PS extends StatelessWidget {
  const PS({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Pal.surface,
    this.radius = 16,
    this.border = Pal.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class PBtn extends StatelessWidget {
  const PBtn({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.secondary = false,
    this.height = 44,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool secondary;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secondary ? Pal.surface : Pal.green,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: secondary ? Border.all(color: Pal.border) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: secondary ? Pal.ink : Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: txt(
                  12.5,
                  weight: FontWeight.w700,
                  color: secondary ? Pal.ink : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PTone { good, warn, bad, neutral, info }

class PChip extends StatelessWidget {
  const PChip({super.key, required this.label, this.tone = PTone.neutral});

  final String label;
  final PTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      PTone.good => (Pal.green, Pal.greenTint),
      PTone.warn => (Pal.gold, Pal.amberTint),
      PTone.bad => (Pal.rose, Pal.roseTint),
      PTone.info => (Pal.blue, Pal.blueTint),
      PTone.neutral => (Pal.muted, Pal.surfaceTint),
    };
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: txt(10.5, weight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}

class PSpark extends StatelessWidget {
  const PSpark({
    super.key,
    required this.values,
    this.height = 34,
    this.color = Pal.green,
  });

  final List<int> values;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1
        : values.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: FractionallySizedBox(
                heightFactor: (values[i] / maxValue).clamp(0.08, 1.0),
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: i == values.length - 1
                        ? color
                        : color.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PStackBar extends StatelessWidget {
  const PStackBar({
    super.key,
    required this.segments,
    this.height = 10,
    this.background = const Color(0xFFEDEBF2),
  });

  final List<(int, Color)> segments;
  final double height;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.$1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            if (total == 0)
              Expanded(child: Container(color: background))
            else
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  flex: math.max(1, segments[i].$1),
                  child: Container(color: segments[i].$2),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class PEyebrow extends StatelessWidget {
  const PEyebrow(this.text, {super.key, this.color = Pal.faint});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: eyebrowStyle.copyWith(color: color));
  }
}

class PStyleTile extends StatelessWidget {
  const PStyleTile({super.key, required this.name, required this.rtl});

  final String name;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return PS(
      color: Pal.surfaceTint,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PEyebrow(rtl ? 'لوحة النمط' : 'STYLE TILE'),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 1, color: Pal.border)),
              const SizedBox(width: 10),
              Text(
                name,
                style: txt(11, weight: FontWeight.w600, color: Pal.faint),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 3 : 1;
              final width = (c.maxWidth - 20 * (cols - 1)) / cols;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PEyebrow('TYPE SCALE'),
                        const SizedBox(height: 8),
                        Text(
                          '36',
                          style: txt(
                            40,
                            weight: FontWeight.w800,
                            tracking: -1.2,
                            tabular: true,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          rtl ? 'ورشة نشطة' : 'active workshops',
                          style: txt(11.5, color: Pal.faint),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Section heading',
                          style: txt(17, weight: FontWeight.w700),
                        ),
                        Text(
                          rtl ? 'نص أساسي هادئ يشرح ما يهم.' : 'Body copy stays quiet; scale carries hierarchy.',
                          style: txt(12.5, color: Pal.muted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PEyebrow('PALETTE'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _Swatch(color: Pal.green, label: 'Accent'),
                            _Swatch(color: Pal.greenTint, label: 'Tint'),
                            _Swatch(color: Pal.ink, label: 'Ink'),
                            _Swatch(color: Pal.muted, label: 'Muted'),
                            _Swatch(color: Pal.border, label: 'Line'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            PChip(
                              label: sprintStrings.tKey(
                                CommonKeys.statusActive,
                              ),
                              tone: PTone.good,
                            ),
                            PChip(label: '3 pending', tone: PTone.warn),
                            PChip(label: '2 issues', tone: PTone.bad),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PEyebrow('CONTROLS'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PBtn(
                              label: sprintStrings.tKey(
                                CommonKeys.buttonRefresh,
                              ),
                              icon: Icons.refresh_rounded,
                            ),
                            PBtn(
                              label: sprintStrings.tKey(
                                PlatformAdminKeys
                                    .dashboardQuickActionsViewHealth,
                              ),
                              secondary: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Pal.border),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: txt(9.5, color: Pal.faint)),
      ],
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter({required this.segments, required this.track});

  final List<(double, Color)> segments;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 22) / 2;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..color = track;
    canvas.drawCircle(center, radius, bg);
    var start = -math.pi / 2;
    for (final segment in segments) {
      if (segment.$1 <= 0) continue;
      final sweep = math.pi * 2 * segment.$1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.butt
        ..color = segment.$2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.035,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter old) => true;
}
