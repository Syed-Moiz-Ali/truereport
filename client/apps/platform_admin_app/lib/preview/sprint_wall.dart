import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'sprint_shell.dart';

/// Direction B — "Split Wall": a persistent dark status wall on the left and a
/// light work surface on the right. No hero band, no page header.
class SprintWall extends StatelessWidget {
  const SprintWall({super.key, required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    return SprintShell(
      rtl: rtl,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1000;
          if (!wide) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Wall(rtl: rtl, compact: true),
                  const _Work(compact: true),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: PStyleTile(name: 'Split Wall', rtl: rtl),
                  ),
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 404, child: _Wall(rtl: rtl)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const _Work(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(26, 0, 26, 20),
                        child: PStyleTile(name: 'Split Wall', rtl: rtl),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Wall extends StatelessWidget {
  const _Wall({required this.rtl, this.compact = false});

  final bool rtl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final ledger = [
      (
        s.tKey(PlatformAdminKeys.kpiWorkshopsActive),
        '${SprintDemo.workshopsActive}/${SprintDemo.workshopsTotal}',
      ),
      (s.tKey(PlatformAdminKeys.kpiTechnicians), '${SprintDemo.technicians}'),
      (s.tKey(PlatformAdminKeys.kpiJobsActive), '${SprintDemo.jobsActive}'),
      (
        s.tKey(PlatformAdminKeys.kpiReportsPublished),
        '${SprintDemo.reportsPublished}',
      ),
      (
        s.tKey(PlatformAdminKeys.kpiLanguagesLive),
        '${SprintDemo.languagesLive}',
      ),
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topCenter,
          end: AlignmentDirectional.bottomCenter,
          colors: [Color(0xFF0B3B2E), Color(0xFF072A21)],
        ),
      ),
      padding: EdgeInsets.all(compact ? 20 : 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  size: 16,
                  color: Color(0xFF7EE2B8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.tKey(PlatformAdminKeys.pageDashboardTitle),
                  style: txt(12, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
              PChip(label: rtl ? 'بيانات تجريبية' : 'Sample data'),
            ],
          ),
          SizedBox(height: compact ? 22 : 40),
          PEyebrow(
            s.tKey(PlatformAdminKeys.dashboardSnapshotTitle),
            color: const Color(0xFF7FA898),
          ),
          const SizedBox(height: 8),
          Text(
            s.tKey(PlatformAdminKeys.dashboardStatusAttention),
            style: txt(
              compact ? 26 : 32,
              weight: FontWeight.w800,
              tracking: -0.8,
              height: 1.15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.tArgsKey(PlatformAdminKeys.dashboardStatusAttentionSubtitle, {
              'count': '${SprintDemo.attentionCount}',
            }),
            style: txt(12, height: 1.5, color: const Color(0xFFB7D8CA)),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '0${SprintDemo.attentionCount}',
                style: txt(
                  compact ? 56 : 84,
                  weight: FontWeight.w800,
                  tracking: -3,
                  tabular: true,
                  height: 0.95,
                  color: const Color(0xFFFCD34D),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  s.tKey(PlatformAdminKeys.dashboardNeedsAttentionTitle),
                  style: txt(11, color: const Color(0xFFB7D8CA)),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 20 : 28),
          if (compact)
            for (final row in ledger)
              _LedgerRow(label: row.$1, value: row.$2, compact: true)
          else
            for (final row in ledger) _LedgerRow(label: row.$1, value: row.$2),
          if (compact) const SizedBox(height: 20) else const Spacer(),
          if (!compact) ...[
            const Divider(color: Color(0x26FFFFFF), height: 1),
            const SizedBox(height: 12),
            for (final action in _actions(s))
              _WallAction(label: action.$1, icon: action.$2),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PBtn(
              label: s.tKey(CommonKeys.buttonRefresh),
              icon: Icons.refresh_rounded,
              secondary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 9 : 12),
      decoration: BoxDecoration(
        border: compact
            ? const Border(bottom: BorderSide(color: Color(0x1FFFFFFF)))
            : const Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: txt(11.5, color: const Color(0xFFB7D8CA)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: txt(
              compact ? 22 : 24,
              weight: FontWeight.w800,
              tabular: true,
              tracking: -0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _WallAction extends StatefulWidget {
  const _WallAction({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  State<_WallAction> createState() => _WallActionState();
}

class _WallActionState extends State<_WallAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _hover
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 16, color: const Color(0xFF7EE2B8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: txt(11.5, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: Color(0xFF7FA898),
            ),
          ],
        ),
      ),
    );
  }
}

List<(String, IconData)> _actions(UiMessageStrings s) => [
  (
    s.tKey(PlatformAdminKeys.dashboardQuickActionsAddWorkshop),
    Icons.add_business_outlined,
  ),
  (
    s.tKey(PlatformAdminKeys.dashboardQuickActionsCreateTemplate),
    Icons.dashboard_customize_outlined,
  ),
  (
    s.tKey(PlatformAdminKeys.dashboardQuickActionsAddChecklistItem),
    Icons.playlist_add_rounded,
  ),
  (
    s.tKey(PlatformAdminKeys.dashboardQuickActionsViewHealth),
    Icons.health_and_safety_outlined,
  ),
];

class _Work extends StatelessWidget {
  const _Work({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final rows = [
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
    final activity = [
      ('Workshop updated', 'Riverside Auto Centre', '9:40 AM'),
      ('Report published', 'job-2481', '8:15 AM'),
      ('Template published', 'Comprehensive 110', 'Yesterday'),
      ('Language live', 'العربية (ar)', 'Yesterday'),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 26,
        compact ? 18 : 24,
        compact ? 16 : 26,
        compact ? 8 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.tKey(PlatformAdminKeys.dashboardNeedsAttentionTitle),
                  style: txt(21, weight: FontWeight.w800, tracking: -0.4),
                ),
              ),
              PBtn(
                label: s.tKey(
                  PlatformAdminKeys.dashboardQuickActionsViewHealth,
                ),
                icon: Icons.arrow_outward_rounded,
                secondary: true,
                height: 40,
              ),
            ],
          ),
          const SizedBox(height: 14),
          PS(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                    decoration: BoxDecoration(
                      border: i == rows.length - 1
                          ? null
                          : const Border(bottom: BorderSide(color: Pal.border)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: switch (rows[i].$3) {
                              PTone.bad => Pal.rose,
                              PTone.warn => Pal.amber,
                              PTone.info => Pal.blue,
                              _ => Pal.green,
                            },
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rows[i].$1,
                                style: txt(13, weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rows[i].$2,
                                style: txt(11, color: Pal.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 17,
                          color: Pal.faint,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.tKey(PlatformAdminKeys.sectionDashboardRecentActivity),
                  style: txt(16, weight: FontWeight.w800),
                ),
              ),
              PEyebrow('${activity.length}'),
            ],
          ),
          const SizedBox(height: 10),
          PS(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < activity.length; i++)
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    decoration: BoxDecoration(
                      border: i == activity.length - 1
                          ? null
                          : const Border(bottom: BorderSide(color: Pal.border)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Pal.border,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                activity[i].$1,
                                style: txt(12, weight: FontWeight.w700),
                              ),
                              Text(
                                activity[i].$2,
                                style: txt(10.5, color: Pal.faint),
                              ),
                            ],
                          ),
                        ),
                        Text(activity[i].$3, style: txt(10, color: Pal.faint)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
