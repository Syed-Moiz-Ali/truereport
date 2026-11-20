import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'sprint_shell.dart';

/// Direction C — "Trellis": no hero. An attention ribbon, then a bento of six
/// domain modules with equal weight, then quick actions.
class SprintTrellis extends StatelessWidget {
  const SprintTrellis({super.key, required this.rtl});

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
                    const SizedBox(height: 16),
                    _Ribbon(rtl: rtl),
                    const SizedBox(height: 16),
                    if (wide) ...[
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: _Workshops(rtl: rtl)),
                            const SizedBox(width: 12),
                            Expanded(flex: 4, child: _Jobs(rtl: rtl)),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: _Checklist(rtl: rtl)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 4, child: _Reports(rtl: rtl)),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: _Languages(rtl: rtl)),
                            const SizedBox(width: 12),
                            Expanded(flex: 5, child: _Staff(rtl: rtl)),
                          ],
                        ),
                      ),
                    ] else
                      Column(
                        children: [
                          _Workshops(rtl: rtl),
                          const SizedBox(height: 12),
                          _Jobs(rtl: rtl),
                          const SizedBox(height: 12),
                          _Checklist(rtl: rtl),
                          const SizedBox(height: 12),
                          _Reports(rtl: rtl),
                          const SizedBox(height: 12),
                          _Languages(rtl: rtl),
                          const SizedBox(height: 12),
                          _Staff(rtl: rtl),
                        ],
                      ),
                    const SizedBox(height: 24),
                    _Actions(rtl: rtl, wide: wide),
                    const SizedBox(height: 32),
                    PStyleTile(name: 'Trellis', rtl: rtl),
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
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PEyebrow(s.tKey(PlatformAdminKeys.sectionDashboardKpis)),
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
          left,
          const SizedBox(height: 14),
          Align(alignment: AlignmentDirectional.centerStart, child: refresh),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: left),
        refresh,
      ],
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final title = s.tArgsKey(
      PlatformAdminKeys.dashboardNeedsAttentionChecklistIssues,
      {'count': '${SprintDemo.checklistIssues}'},
    );
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 720;
        final lead = Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Pal.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: txt(
                  12,
                  weight: FontWeight.w700,
                  color: const Color(0xFF7C4A05),
                ),
              ),
            ),
          ],
        );
        final tail = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PChip(label: '${SprintDemo.attentionCount}', tone: PTone.warn),
            const SizedBox(width: 10),
            Text(
              s.tKey(PlatformAdminKeys.dashboardQuickActionsViewHealth),
              style: txt(11.5, weight: FontWeight.w800, color: Pal.gold),
            ),
            const SizedBox(width: 4),
            Icon(
              rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
              size: 14,
              color: Pal.gold,
            ),
          ],
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Pal.amberTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1DFC2)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    lead,
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: tail,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: lead),
                    const SizedBox(width: 10),
                    tail,
                  ],
                ),
        );
      },
    );
  }
}

class _Module extends StatelessWidget {
  const _Module({
    required this.title,
    required this.icon,
    required this.value,
    required this.label,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String value;
  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 176),
      child: PS(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: Pal.green),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: eyebrowStyle.copyWith(color: Pal.muted),
                  ),
                ),
                if (trailing != null) trailing!,
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: Pal.faint,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: txt(
                    40,
                    weight: FontWeight.w800,
                    tracking: -1.4,
                    tabular: true,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(label, style: txt(10.5, color: Pal.muted)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _Workshops extends StatelessWidget {
  const _Workshops({required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    return _Module(
      title: s.tKey(PlatformAdminKeys.navWorkshops),
      icon: Icons.storefront_outlined,
      value: '0${SprintDemo.workshopsActive}',
      label: s.tKey(PlatformAdminKeys.kpiWorkshopsActive),
      trailing: Text(
        '/ ${SprintDemo.workshopsTotal}',
        style: txt(
          10.5,
          weight: FontWeight.w600,
          tabular: true,
          color: Pal.faint,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PStackBar(segments: const [(8, Pal.green), (2, Color(0xFFE2DFE8))]),
          const SizedBox(height: 8),
          Text(
            '${SprintDemo.workshopsTotal} ${s.tKey(PlatformAdminKeys.kpiWorkshopsTotal)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: txt(10, color: Pal.faint),
          ),
        ],
      ),
    );
  }
}

class _Jobs extends StatelessWidget {
  const _Jobs({required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final entries = SprintDemo.jobsByStatus.entries.toList();
    final colors = [Pal.green, const Color(0xFF5FD3A9), Pal.amber, Pal.blue];
    return _Module(
      title: s.tKey(PlatformAdminKeys.kpiJobsActive),
      icon: Icons.work_outline_rounded,
      value: '${SprintDemo.jobsActive}',
      label: s.tKey(PlatformAdminKeys.chartJobsByStatus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PStackBar(
            segments: [
              for (var i = 0; i < entries.length; i++)
                (entries[i].value, colors[i % colors.length]),
            ],
            height: 8,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final width = (c.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    SizedBox(
                      width: width,
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _humanize(entries[i].key),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: txt(9.5, color: Pal.faint),
                            ),
                          ),
                          Text(
                            '${entries[i].value}',
                            style: txt(
                              10,
                              weight: FontWeight.w700,
                              tabular: true,
                            ),
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

class _Checklist extends StatelessWidget {
  const _Checklist({required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    return _Module(
      title: s.tKey(PlatformAdminKeys.navChecklist),
      icon: Icons.rule_folder_outlined,
      value: '0${SprintDemo.checklistIssues}',
      label: s.tKey(PlatformAdminKeys.kpiChecklistHealth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.tArgsKey(PlatformAdminKeys.checklistCategoriesItemCount, {
              'count': '${SprintDemo.items}',
            }),
            style: txt(11, weight: FontWeight.w600, color: Pal.muted),
          ),
          const SizedBox(height: 6),
          Text(
            s.tKey(PlatformAdminKeys.dashboardStatusAttention),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: txt(10, color: Pal.faint),
          ),
        ],
      ),
    );
  }
}

class _Reports extends StatelessWidget {
  const _Reports({required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final values = SprintDemo.reportsByMonth.values.toList();
    return _Module(
      title: s.tKey(PlatformAdminKeys.navReports),
      icon: Icons.description_outlined,
      value: '${SprintDemo.reportsPublished}',
      label: s.tKey(PlatformAdminKeys.kpiReportsPublished),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PSpark(values: values, height: 28),
          const SizedBox(height: 8),
          Text(
            SprintDemo.reportsByMonth.keys.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: txt(9.5, color: Pal.faint),
          ),
        ],
      ),
    );
  }
}

class _Languages extends StatelessWidget {
  const _Languages({required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    return _Module(
      title: s.tKey(PlatformAdminKeys.pageLanguagesTitle),
      icon: Icons.translate_rounded,
      value: '${SprintDemo.languagesLive}',
      label: s.tKey(PlatformAdminKeys.kpiLanguagesLive),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.tArgsKey(PlatformAdminKeys.dashboardKpiLanguagesInSetup, {
              'count': '${SprintDemo.languagesSetup}',
            }),
            style: txt(11, weight: FontWeight.w600, color: Pal.gold),
          ),
          const SizedBox(height: 10),
          const PChip(label: 'العربية (ar)', tone: PTone.info),
        ],
      ),
    );
  }
}

class _Staff extends StatelessWidget {
  const _Staff({required this.rtl});

  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    return _Module(
      title: s.tKey(PlatformAdminKeys.tabWorkshopStaff),
      icon: Icons.groups_outlined,
      value: '${SprintDemo.technicians}',
      label: s.tKey(PlatformAdminKeys.kpiTechnicians),
      trailing: Text(
        '${SprintDemo.admins} ${s.tKey(PlatformAdminKeys.sectionWorkshopAdmins)}',
        style: txt(9.5, color: Pal.faint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PStackBar(
            segments: const [(62, Pal.green), (14, const Color(0xFF9BE3C6))],
            height: 8,
          ),
          const SizedBox(height: 8),
          Text(
            s.tKey(PlatformAdminKeys.sectionWorkshopTechnicians),
            style: txt(10, color: Pal.faint),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.rtl, required this.wide});

  final bool rtl;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final s = sprintStrings;
    final actions = [
      s.tKey(PlatformAdminKeys.dashboardQuickActionsAddWorkshop),
      s.tKey(PlatformAdminKeys.dashboardQuickActionsCreateTemplate),
      s.tKey(PlatformAdminKeys.dashboardQuickActionsAddChecklistItem),
      s.tKey(PlatformAdminKeys.dashboardQuickActionsAddLanguage),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.tKey(PlatformAdminKeys.dashboardQuickActionsTitle),
                style: txt(16, weight: FontWeight.w800),
              ),
            ),
            PEyebrow('${actions.length}'),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              PBtn(
                label: action,
                secondary: true,
                icon: Icons.add_rounded,
                height: 40,
              ),
          ],
        ),
      ],
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
