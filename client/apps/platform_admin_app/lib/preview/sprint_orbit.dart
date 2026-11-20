import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'sprint_shell.dart';

/// Direction A — "Orbit": one radial instrument for the whole network, a
/// decision rail on the right, quick actions underneath.
class SprintOrbit extends StatelessWidget {
  const SprintOrbit({super.key, required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return SprintShell(
      rtl: rtl,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1000;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              wide ? 28 : 16,
              24,
              wide ? 28 : 16,
              44,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(rtl: rtl, wide: wide),
                    const SizedBox(height: 20),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _Orbit(),
                                const SizedBox(height: 16),
                                _QuickActions(wide: false, rtl: rtl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 400,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                _Attention(),
                                SizedBox(height: 16),
                                _Activity(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      const _Orbit(compact: true),
                      const SizedBox(height: 16),
                      const _Attention(),
                      const SizedBox(height: 16),
                      const _Activity(),
                      const SizedBox(height: 24),
                      _QuickActions(wide: false, rtl: rtl),
                    ],
                    const SizedBox(height: 32),
                    PStyleTile(name: 'Orbit', rtl: rtl),
                  ],
                ),
              ),
            ),
          );
        },
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
    final s = sprintStrings;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PEyebrow(s.tKey(PlatformAdminKeys.dashboardSnapshotTitle)),
            const SizedBox(width: 10),
            PChip(label: rtl ? 'بيانات تجريبية' : 'Sample data'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          s.tKey(PlatformAdminKeys.pageDashboardTitle),
          style: txt(30, weight: FontWeight.w800, tracking: -0.9, height: 1.2),
        ),
        const SizedBox(height: 5),
        Text(
          s.tKey(PlatformAdminKeys.pageDashboardSubtitle),
          style: txt(12.5, color: Pal.muted),
        ),
      ],
    );
    final refresh = PBtn(
      label: s.tKey(CommonKeys.buttonRefresh),
      icon: Icons.refresh_rounded,
      secondary: true,
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 14),
          Align(alignment: AlignmentDirectional.centerStart, child: refresh),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: title),
        refresh,
      ],
    );
  }
}

class _Orbit extends StatelessWidget {
  const _Orbit({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final statuses = SprintDemo.jobsByStatus.entries.toList();
    final colors = [Pal.green, const Color(0xFF5FD3A9), Pal.amber, Pal.blue];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF0B3B2E), Color(0xFF00563C)],
        ),
      ),
      padding: EdgeInsets.all(compact ? 20 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: PEyebrow(
                  s.tKey(PlatformAdminKeys.chartJobsByStatus),
                  color: const Color(0xFFB7E4CE),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF7EE2B8),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 4),
          if (compact)
            Column(
              children: [
                const SizedBox(height: 260, child: _Dial()),
                const SizedBox(height: 8),
                _Legend(statuses: statuses, colors: colors),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 300, height: 300, child: _Dial()),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Legend(statuses: statuses, colors: colors),
                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _Mini(
                            value: '${SprintDemo.workshopsActive}',
                            label: s.tKey(PlatformAdminKeys.kpiWorkshopsActive),
                          ),
                          _Mini(
                            value: '${SprintDemo.staffTotal}',
                            label: s.tKey(PlatformAdminKeys.tabWorkshopStaff),
                          ),
                          _Mini(
                            value: '${SprintDemo.reportsPublished}',
                            label: s.tKey(
                              PlatformAdminKeys.kpiReportsPublished,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (compact) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
            const SizedBox(height: 16),
            Row(
              children: [
                _Mini(
                  value: '${SprintDemo.workshopsActive}',
                  label: s.tKey(PlatformAdminKeys.kpiWorkshopsActive),
                ),
                _Mini(
                  value: '${SprintDemo.staffTotal}',
                  label: s.tKey(PlatformAdminKeys.tabWorkshopStaff),
                ),
                _Mini(
                  value: '${SprintDemo.reportsPublished}',
                  label: s.tKey(PlatformAdminKeys.kpiReportsPublished),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial();

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final statuses = SprintDemo.jobsByStatus.entries.toList();
    final colors = [Pal.green, const Color(0xFF5FD3A9), Pal.amber, Pal.blue];
    final total = SprintDemo.jobsActive;
    return SizedBox(
      width: 300,
      height: 300,
      child: CustomPaint(
        painter: RingPainter(
          track: Colors.white.withValues(alpha: 0.10),
          segments: [
            for (var i = 0; i < statuses.length; i++)
              (
                statuses[i].value / math.max(1, total),
                colors[i % colors.length],
              ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$total',
                style: txt(
                  64,
                  weight: FontWeight.w800,
                  tracking: -2.4,
                  tabular: true,
                  height: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s
                    .tKey(PlatformAdminKeys.dashboardKpiJobsActiveCount)
                    .replaceAll('{count}', '')
                    .trim()
                    .toUpperCase(),
                style: txt(
                  9.5,
                  weight: FontWeight.w800,
                  tracking: 1.2,
                  color: const Color(0xFFB7E4CE),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.statuses, required this.colors});

  final List<MapEntry<String, int>> statuses;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < statuses.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _humanize(statuses[i].key),
                    style: txt(12, color: Colors.white.withValues(alpha: 0.86)),
                  ),
                ),
                Text(
                  '${statuses[i].value}',
                  style: txt(
                    13,
                    weight: FontWeight.w800,
                    tabular: true,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: txt(
              24,
              weight: FontWeight.w800,
              tabular: true,
              tracking: -0.6,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: txt(9.5, color: const Color(0xFFB7E4CE)),
          ),
        ],
      ),
    );
  }
}

class _Attention extends StatelessWidget {
  const _Attention();

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final rows = _attentionRows(s);
    return PS(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.tKey(PlatformAdminKeys.dashboardNeedsAttentionTitle),
                    style: txt(15, weight: FontWeight.w800),
                  ),
                ),
                PChip(
                  label: '${rows.length}',
                  tone: rows.isEmpty ? PTone.good : PTone.warn,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Pal.border),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                s.tKey(PlatformAdminKeys.dashboardNeedsAttentionEmpty),
                style: txt(12, color: Pal.muted),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++)
              _AttentionRow(
                title: rows[i].$1,
                meta: rows[i].$2,
                tone: rows[i].$3,
                last: i == rows.length - 1,
              ),
          const Divider(height: 1, color: Pal.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PBtn(
                label: s.tKey(
                  PlatformAdminKeys.dashboardQuickActionsViewHealth,
                ),
                secondary: true,
                height: 38,
                icon: Icons.arrow_outward_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<(String, String, PTone)> _attentionRows(UiMessageStrings s) {
  return [
    (
      s.tArgsKey(PlatformAdminKeys.dashboardNeedsAttentionChecklistIssues, {
        'count': '${SprintDemo.checklistIssues}',
      }),
      s.tArgsKey(PlatformAdminKeys.dashboardHealthSummaryMultiple, {
        'count': '${SprintDemo.checklistIssues}',
      }),
      PTone.bad,
    ),
    (
      s.tArgsKey(PlatformAdminKeys.dashboardNeedsAttentionPendingReviews, {
        'count': '${SprintDemo.pendingReview}',
      }),
      s.tKey(PlatformAdminKeys.sectionDashboardAlerts),
      PTone.warn,
    ),
    (
      s.tArgsKey(PlatformAdminKeys.dashboardNeedsAttentionLanguageInSetup, {
        'language': 'العربية (ar)',
        'status': s.tKey(PlatformAdminKeys.statusLanguageTranslating),
      }),
      s.tKey(PlatformAdminKeys.pageLanguagesTitle),
      PTone.info,
    ),
  ];
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.title,
    required this.meta,
    required this.tone,
    required this.last,
  });

  final String title;
  final String meta;
  final PTone tone;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      PTone.bad => Pal.rose,
      PTone.warn => Pal.amber,
      PTone.info => Pal.blue,
      _ => Pal.green,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 14, 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Pal.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: txt(12.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(meta, style: txt(10.5, color: Pal.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 16, color: Pal.faint),
        ],
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity();

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final rows = [
      ('Workshop updated', 'Riverside Auto Centre', 'Nov 20, 9:40 AM'),
      ('Report published', 'job-2481', 'Nov 20, 8:15 AM'),
      ('Template published', 'Comprehensive 110', 'Nov 19, 4:02 PM'),
      ('Language live', 'العربية (ar)', 'Nov 19, 11:20 AM'),
    ];
    return PS(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              s.tKey(PlatformAdminKeys.sectionDashboardRecentActivity),
              style: txt(15, weight: FontWeight.w800),
            ),
          ),
          const Divider(height: 1, color: Pal.border),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 11, 18, 11),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: Pal.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Pal.surfaceTint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 15,
                      color: Pal.muted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rows[i].$1,
                          style: txt(12, weight: FontWeight.w700),
                        ),
                        Text(rows[i].$2, style: txt(10, color: Pal.faint)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(rows[i].$3, style: txt(9.5, color: Pal.faint)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.wide, required this.rtl});

  final bool wide;
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final actions = [
      (
        s.tKey(PlatformAdminKeys.dashboardQuickActionsAddWorkshop),
        s.tKey(PlatformAdminKeys.dashboardQuickActionsAddWorkshopDesc),
        Icons.add_business_outlined,
      ),
      (
        s.tKey(PlatformAdminKeys.dashboardQuickActionsCreateTemplate),
        s.tKey(PlatformAdminKeys.dashboardQuickActionsCreateTemplateDesc),
        Icons.dashboard_customize_outlined,
      ),
      (
        s.tKey(PlatformAdminKeys.dashboardQuickActionsAddChecklistItem),
        s.tKey(PlatformAdminKeys.dashboardQuickActionsAddChecklistItemDesc),
        Icons.playlist_add_rounded,
      ),
      (
        s.tKey(PlatformAdminKeys.dashboardQuickActionsAddLanguage),
        s.tKey(PlatformAdminKeys.dashboardQuickActionsAddLanguageDesc),
        Icons.translate_rounded,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.tKey(PlatformAdminKeys.dashboardQuickActionsTitle),
                style: txt(17, weight: FontWeight.w800, tracking: -0.2),
              ),
            ),
            PEyebrow('${actions.length}'),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final cols = wide ? 4 : (c.maxWidth < 560 ? 1 : 2);
            final width = (c.maxWidth - 12 * (cols - 1)) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: width,
                    child: _ActionTile(action: action),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({required this.action});

  final (String, String, IconData) action;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hover ? Pal.surfaceTint : Pal.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Pal.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Pal.greenTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.action.$3, size: 19, color: Pal.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.action.$1,
                    style: txt(12.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.action.$2,
                    maxLines: 2,
                    style: txt(10.5, height: 1.4, color: Pal.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 15, color: Pal.faint),
          ],
        ),
      ),
    );
  }
}

String _humanize(String code) {
  final words = code
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty);
  if (words.isEmpty) return code;
  return words
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
