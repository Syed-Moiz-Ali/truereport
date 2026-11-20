import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_config_models.dart';
import '../../../platform_theme.dart';
import '../dashboard_feed.dart';
import 'trellis_ui.dart';

/// Six domain modules, equal weight. Each card carries real figures plus one
/// micro-visual; no verdict hero.
class TrellisBento extends StatelessWidget {
  const TrellisBento({
    super.key,
    required this.strings,
    required this.summary,
    required this.languages,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final OverviewSummary summary;
  final List<PlatformLanguage> languages;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final modules = <(int, Widget)>[
      (5, _WorkshopsModule(strings: strings, summary: summary, onOpen: onOpen)),
      (4, _JobsModule(strings: strings, summary: summary, onOpen: onOpen)),
      (3, _ChecklistModule(strings: strings, summary: summary, onOpen: onOpen)),
      (4, _ReportsModule(strings: strings, summary: summary, onOpen: onOpen)),
      (
        3,
        _LanguagesModule(
          strings: strings,
          summary: summary,
          languages: languages,
          onOpen: onOpen,
        ),
      ),
      (5, _StaffModule(strings: strings, summary: summary, onOpen: onOpen)),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        final twoUp = c.maxWidth >= 700;
        if (wide) {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(flex: modules[i].$1, child: modules[i].$2),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 3; i < 6; i++) ...[
                      if (i > 3) const SizedBox(width: 12),
                      Expanded(flex: modules[i].$1, child: modules[i].$2),
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        if (twoUp) {
          return Column(
            children: [
              for (var row = 0; row < 3; row++) ...[
                if (row > 0) const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: modules[row * 2].$2),
                      const SizedBox(width: 12),
                      Expanded(child: modules[row * 2 + 1].$2),
                    ],
                  ),
                ),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < modules.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              modules[i].$2,
            ],
          ],
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
    required this.onTap,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String value;
  final String label;
  final Widget child;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 176),
        child: Material(
          color: PtTheme.white,
          borderRadius: BorderRadius.circular(Trellis.surfaceRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(Trellis.surfaceRadius),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Trellis.surfaceRadius),
                border: Border.all(color: PtTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 15, color: PtTheme.deepGreen),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Trellis.eyebrow,
                        ),
                      ),
                      ?trailing,
                      const SizedBox(width: 8),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_outward_rounded,
                        size: 14,
                        color: PtTheme.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: Trellis.text(
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
                        child: Text(
                          label,
                          style: Trellis.text(10.5, color: PtTheme.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkshopsModule extends StatelessWidget {
  const _WorkshopsModule({
    required this.strings,
    required this.summary,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final OverviewSummary summary;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final active = summary.workshops.active.clamp(0, summary.workshops.total);
    final inactive = (summary.workshops.total - active).clamp(0, 1 << 30);
    return _Module(
      title: strings.tKey(PlatformAdminKeys.navWorkshops),
      icon: Icons.storefront_outlined,
      value: '${summary.workshops.active}',
      label: strings.tKey(PlatformAdminKeys.kpiWorkshopsActive),
      trailing: Text(
        '/ ${summary.workshops.total}',
        style: Trellis.text(
          10.5,
          weight: FontWeight.w600,
          tabular: true,
          color: PtTheme.muted,
        ),
      ),
      onTap: () => onOpen('/workshops'),
      child: _ModuleBody(
        children: [
          _StackBar(
            segments: [
              (active, PtTheme.deepGreen),
              (inactive, const Color(0xFFE2DFE8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.workshops.total} ${strings.tKey(PlatformAdminKeys.kpiWorkshopsTotal)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Trellis.text(10, color: PtTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _JobsModule extends StatelessWidget {
  const _JobsModule({
    required this.strings,
    required this.summary,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final OverviewSummary summary;
  final ValueChanged<String> onOpen;

  static const _colors = [
    Color(0xFF006C49),
    Color(0xFF5FD3A9),
    Color(0xFFD97706),
    Color(0xFF1D4ED8),
    Color(0xFFA9A5B6),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = summary.jobs.byStatus.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false);
    return _Module(
      title: strings.tKey(PlatformAdminKeys.kpiJobsActive),
      icon: Icons.work_outline_rounded,
      value: '${summary.jobs.active}',
      label: strings.tKey(PlatformAdminKeys.chartJobsByStatus),
      onTap: () => onOpen('/audit-log'),
      child: _ModuleBody(
        children: [
          if (entries.isEmpty)
            Text(
              strings.tKey(CommonKeys.emptyTitle),
              style: Trellis.text(10.5, color: PtTheme.muted),
            )
          else ...[
            _StackBar(
              segments: [
                for (var i = 0; i < entries.length; i++)
                  (entries[i].value, _colors[i % _colors.length]),
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
                                color: _colors[i % _colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                humanizeCode(entries[i].key),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Trellis.text(9.5, color: PtTheme.muted),
                              ),
                            ),
                            Text(
                              '${entries[i].value}',
                              style: Trellis.text(
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
        ],
      ),
    );
  }
}

class _ChecklistModule extends StatelessWidget {
  const _ChecklistModule({
    required this.strings,
    required this.summary,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final OverviewSummary summary;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final issues = summary.checklist.issues;
    final tone = issues > 0 ? PtTheme.gold : PtTheme.deepGreen;
    return _Module(
      title: strings.tKey(PlatformAdminKeys.navChecklist),
      icon: Icons.rule_folder_outlined,
      value: '$issues',
      label: strings.tKey(PlatformAdminKeys.kpiChecklistHealth),
      onTap: () => onOpen('/checklist/items'),
      child: _ModuleBody(
        children: [
          Text(
            issues == 0
                ? strings.tKey(PlatformAdminKeys.dashboardStatusHealthy)
                : issues == 1
                ? strings.tKey(PlatformAdminKeys.dashboardHealthSummarySingle)
                : strings.tArgsKey(
                    PlatformAdminKeys.dashboardHealthSummaryMultiple,
                    {'count': '$issues'},
                  ),
            style: Trellis.text(10.5, weight: FontWeight.w600, color: tone),
          ),
          const SizedBox(height: 6),
          Text(
            strings.tArgsKey(PlatformAdminKeys.checklistCategoriesItemCount, {
              'count': '${summary.checklist.items}',
            }),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Trellis.text(10, color: PtTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _ReportsModule extends StatelessWidget {
  const _ReportsModule({
    required this.strings,
    required this.summary,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final OverviewSummary summary;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final values = summary.reports.byMonth.values.toList(growable: false);
    return _Module(
      title: strings.tKey(PlatformAdminKeys.navReports),
      icon: Icons.description_outlined,
      value: '${summary.reports.published}',
      label: strings.tKey(PlatformAdminKeys.kpiReportsPublished),
      onTap: () => onOpen('/reports/document-types'),
      child: _ModuleBody(
        children: [
          if (values.isEmpty)
            Text(
              strings.tKey(CommonKeys.emptyTitle),
              style: Trellis.text(10.5, color: PtTheme.muted),
            )
          else
            _Spark(values: values, height: 28),
        ],
      ),
    );
  }
}

class _LanguagesModule extends StatelessWidget {
  const _LanguagesModule({
    required this.strings,
    required this.summary,
    required this.languages,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final OverviewSummary summary;
  final List<PlatformLanguage> languages;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final setup = languages.isEmpty
        ? summary.languages.translating
        : languages.where((language) => language.isInSetup).length;
    return _Module(
      title: strings.tKey(PlatformAdminKeys.pageLanguagesTitle),
      icon: Icons.translate_rounded,
      value: '${summary.languages.live}',
      label: strings.tKey(PlatformAdminKeys.kpiLanguagesLive),
      onTap: () => onOpen('/settings/languages'),
      child: _ModuleBody(
        children: [
          Text(
            strings.tArgsKey(PlatformAdminKeys.dashboardKpiLanguagesInSetup, {
              'count': '$setup',
            }),
            style: Trellis.text(
              11,
              weight: FontWeight.w600,
              color: setup > 0 ? PtTheme.gold : PtTheme.deepGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffModule extends StatelessWidget {
  const _StaffModule({
    required this.strings,
    required this.summary,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final OverviewSummary summary;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final technicians = summary.staff.technicians;
    final admins = summary.staff.admins;
    return _Module(
      title: strings.tKey(PlatformAdminKeys.tabWorkshopStaff),
      icon: Icons.groups_outlined,
      value: '$technicians',
      label: strings.tKey(PlatformAdminKeys.kpiTechnicians),
      trailing: Text(
        '$admins ${strings.tKey(PlatformAdminKeys.sectionWorkshopAdmins)}',
        style: Trellis.text(9.5, color: PtTheme.muted),
      ),
      onTap: () => onOpen('/workshops'),
      child: _ModuleBody(
        children: [
          _StackBar(
            segments: [
              (technicians, PtTheme.deepGreen),
              (admins, const Color(0xFF9BE3C6)),
            ],
            height: 8,
          ),
          const SizedBox(height: 8),
          Text(
            strings.tKey(PlatformAdminKeys.sectionWorkshopTechnicians),
            style: Trellis.text(10, color: PtTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _ModuleBody extends StatelessWidget {
  const _ModuleBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _StackBar extends StatelessWidget {
  const _StackBar({required this.segments, this.height = 10});

  final List<(int, Color)> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.$1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            if (total == 0)
              Expanded(child: Container(color: const Color(0xFFEDEBF2)))
            else
              for (var i = 0; i < segments.length; i++) ...[
                if (segments[i].$1 > 0) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: segments[i].$1,
                    child: Container(color: segments[i].$2),
                  ),
                ],
              ],
          ],
        ),
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  const _Spark({required this.values, this.height = 28});

  final List<int> values;
  final double height;

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
                        ? PtTheme.deepGreen
                        : PtTheme.deepGreen.withValues(alpha: 0.22),
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
