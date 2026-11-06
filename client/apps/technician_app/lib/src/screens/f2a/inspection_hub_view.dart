import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2a/assigned_jobs_view.dart';
import 'package:technician_app/src/ui_helpers.dart';

class InspectionHubView extends StatelessWidget {
  const InspectionHubView({
    required this.job,
    required this.checklist,
    required this.onOpenModule,
    required this.onContinue,
    required this.onVehicle,
    required this.onSync,
    required this.onProfile,
    this.onCompleted,
    this.pendingSyncCount = 0,
    this.online = true,
    this.avatarImage,
    this.vehicleImage,
    super.key,
  });

  final TechnicianJob job;
  final InspectionChecklist checklist;
  final ValueChanged<String> onOpenModule;
  final VoidCallback onContinue;
  final VoidCallback onVehicle;
  final VoidCallback onSync;
  final VoidCallback onProfile;
  final VoidCallback? onCompleted;
  final int pendingSyncCount;
  final bool online;
  final ui.Image? avatarImage;
  final ui.Image? vehicleImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = _categories(checklist.items);
    final noIssue = _countResult(checklist.items, 'NO_ISSUE_OBSERVED');
    final attention = _countResult(checklist.items, 'ATTENTION_RECOMMENDED');
    final next = _nextCategory(categories);
    final total = checklist.total == 0
        ? categories.fold<int>(0, (sum, c) => sum + c.total)
        : checklist.total;

    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: l10n.technicianInspectionHub,
        titleStyle: Fx.text(22, 28, FontWeight.w700, -0.55),
        horizontalPadding: _M.gutter,
        leading: Padding(
          padding: EdgeInsetsDirectional.only(end: context.spacing.sm),
          child: Container(
            width: _M.headerMark,
            height: _M.headerMark,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: FxIcon(id: '1_7868', size: 18.33, color: Fx.deepGreen),
            ),
          ),
        ),
        actions: [
          FxProfileButton(
            initials: fxInitials(job.assignedTechnicianName ?? ''),
            iconId: '1_7873',
            onPressed: onProfile,
            semanticLabel:
                job.assignedTechnicianName ?? l10n.technicianProfileTitle,
          ),
        ],
      ),
      bottomNavigationBar: FxDock(
        key: const Key('f2a1-dock'),
        selectedIndex: 0,
        slotWidth: _M.dockSlot,
        gap: _M.dockGap,
        onSelected: (index) {
          switch (index) {
            case 1:
              onCompleted?.call();
              break;
            case 2:
              onSync();
              break;
            case 3:
              onProfile();
              break;
            default:
              break;
          }
        },
        items: [
          FxDockItem(
            label: l10n.technicianJobsTitle,
            iconId: '1_7878',
            semanticLabel: l10n.technicianJobsTitle,
          ),
          FxDockItem(
            label: l10n.statusFinalized,
            iconId: '1_7883',
            semanticLabel: l10n.statusFinalized,
          ),
          FxDockItem(
            label: l10n.technicianSyncTitle,
            iconId: '1_7888',
            semanticLabel: l10n.technicianSyncTitle,
          ),
          FxDockItem(
            label: l10n.technicianProfileTitle,
            iconId: '1_7893',
            semanticLabel: l10n.technicianProfileTitle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          _M.gutter,
          _M.bodyTop,
          _M.gutter,
          _M.bodyBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.statusBlock),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: _M.statusBottom,
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: FxPill(
                        label: technicianStatusLabel(
                          l10n,
                          job.status,
                        ).toUpperCase(),
                        background: Fx.container,
                        foreground: Fx.ink,
                        height: _M.statusPillHeight,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        gap: 8,
                        leading: const FxDot(size: 8),
                        style: Fx.text(
                          11,
                          14,
                          FontWeight.w700,
                          0.55,
                          color: Fx.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: _M.g8),
                    Flexible(
                      child: Text(
                        [
                          job.reference,
                          if (job.templateVersionNo != null)
                            'v${job.templateVersionNo}',
                        ].where((value) => value.isNotEmpty).join(' • '),
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: Fx.text(
                          12,
                          16,
                          FontWeight.w600,
                          0.24,
                          color: Fx.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (total == 0)
              FxCard(
                padding: EdgeInsets.all(context.spacing.gutter),
                radius: _M.cardRadius,
                child: Text(
                  l10n.noResults,
                  style: Fx.body14.copyWith(color: Fx.muted),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _M.heroBlock),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: _M.heroBottom,
                  ),
                  child: FxCard(
                    radius: _M.cardRadius,
                    padding: const EdgeInsets.all(_M.cardPad),
                    child: Column(
                      children: [
                        SizedBox(
                          height: _M.ringBlock,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              vertical: _M.g8,
                            ),
                            child: Center(
                              child: FxCoverageRing(
                                done: checklist.completed,
                                total: total,
                                label: l10n.technicianChecksDoneLabel,
                                semanticLabel: l10n.technicianCoverageSemantics(
                                  checklist.completed,
                                  total,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: _M.g12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: FxPill(
                                label: l10n.technicianNoIssueCount(noIssue),
                                background: Fx.container,
                                foreground: Fx.ink,
                                height: _M.statPillHeight,
                                gap: 6,
                                leading: const FxIcon(
                                  id: '1_7790',
                                  size: 13.33,
                                  color: Fx.emerald,
                                ),
                                style: Fx.caption.copyWith(color: Fx.ink),
                              ),
                            ),
                            const SizedBox(width: _M.g8),
                            Flexible(
                              child: FxPill(
                                label: l10n.technicianAttentionCount(attention),
                                background: Fx.container,
                                foreground: Fx.ink,
                                height: _M.statPillHeight,
                                gap: 6,
                                leading: const FxIcon(
                                  id: '1_7795',
                                  size: 13.33,
                                  color: Fx.dangerRed,
                                ),
                                style: Fx.caption.copyWith(color: Fx.ink),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.vehicleBlock),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: _M.g2,
                  bottom: _M.heroBottom,
                ),
                child: _VehicleStrip(
                  job: job,
                  image: vehicleImage,
                  onTap: onVehicle,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.sectionBlock),
              child: Padding(
                padding: EdgeInsetsDirectional.only(bottom: context.spacing.md),
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: context.spacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.technicianInspectionModules,
                          style: Fx.text(
                            16,
                            22,
                            FontWeight.w700,
                            -0.16,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                      Text(
                        l10n.technicianCategoriesCount(categories.length),
                        style: Fx.text(
                          12,
                          16,
                          FontWeight.w600,
                          0.24,
                          color: Fx.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _ModuleGrid(categories: categories, onOpenModule: onOpenModule),
            const SizedBox(height: _M.g24),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.ctaBlock),
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: context.spacing.sm),
                child: FxButton(
                  label: next == null
                      ? l10n.technicianContinueChecklist
                      : '${l10n.technicianContinueChecklist} · ${next.label}',
                  onPressed: onContinue,
                  icon: const FxIcon(
                    id: '1_7861',
                    size: 11.67,
                    color: Fx.white,
                  ),
                  trailingIcon: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCount {
  const _CategoryCount({
    required this.label,
    required this.done,
    required this.total,
  });

  final String label;
  final int done;
  final int total;

  double get fraction => total <= 0 ? 0 : done / total;
}

List<_CategoryCount> _categories(List<InspectionItem> items) {
  final done = <String, int>{};
  final total = <String, int>{};
  final labels = <String, String>{};
  for (final item in items) {
    final key = item.categoryLabelEn.isEmpty
        ? item.categoryLabelAr
        : item.categoryLabelEn;
    labels[key] = key;
    total[key] = (total[key] ?? 0) + 1;
    if (item.assessment != null) {
      done[key] = (done[key] ?? 0) + 1;
    }
  }
  return [
    for (final entry in total.entries)
      _CategoryCount(
        label: labels[entry.key] ?? entry.key,
        done: done[entry.key] ?? 0,
        total: entry.value,
      ),
  ];
}

int _countResult(List<InspectionItem> items, String result) =>
    items.where((item) => item.assessment?.resultCode == result).length;

_CategoryCount? _nextCategory(List<_CategoryCount> categories) {
  for (final category in categories) {
    if (category.done > 0 && category.done < category.total) {
      return category;
    }
  }
  for (final category in categories) {
    if (category.done == 0) {
      return category;
    }
  }
  return categories.isEmpty ? null : categories.first;
}

String _iconIdForCategory(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('interior') || lower.contains('cabin')) {
    return '1_7819';
  }
  if (lower.contains('engine') || lower.contains('mechanical')) {
    return '1_7834';
  }
  if (lower.contains('under') || lower.contains('exhaust')) {
    return '1_7848';
  }
  return '1_7804';
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.categories, required this.onOpenModule});

  final List<_CategoryCount> categories;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _M.gridGap,
      runSpacing: _M.gridGap,
      children: [
        for (final category in categories)
          SizedBox(
            width: _M.moduleWidth,
            child: _ModuleCard(
              category: category,
              onTap: () => onOpenModule(category.label),
            ),
          ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.category, required this.onTap});

  final _CategoryCount category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = category.total > 0 && category.done >= category.total;
    final inProgress = category.done > 0 && !done;
    final state = done
        ? l10n.technicianModuleDone
        : inProgress
        ? l10n.technicianModuleInProgress
        : l10n.technicianModuleNotStarted;
    return FxCard(
      radius: _M.cardRadius,
      padding: EdgeInsets.all(context.spacing.gutter),
      onTap: onTap,
      semanticLabel:
          '${category.label}, ${category.done}/${category.total}, $state',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _M.moduleInner),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.moduleHeader),
              child: Row(
                children: [
                  FxIconTile(
                    iconId: _iconIdForCategory(category.label),
                    size: _M.moduleIcon,
                    iconSize: _M.moduleGlyph,
                    color: Fx.ink,
                  ),
                  const Spacer(),
                  if (done)
                    Container(
                      width: _M.donePin,
                      height: _M.donePin,
                      decoration: const BoxDecoration(
                        color: Fx.emerald,
                        shape: BoxShape.circle,
                        boxShadow: Fx.softShadow,
                      ),
                      child: const Center(
                        child: FxIcon(
                          id: '1_7807',
                          size: 12.23,
                          color: Fx.white,
                        ),
                      ),
                    )
                  else if (inProgress)
                    FxPill(
                      label: '${category.done}/${category.total}',
                      background: Fx.container,
                      foreground: Fx.muted,
                      height: _M.progressPill,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w700,
                        0.44,
                        color: Fx.muted,
                      ),
                    )
                  else
                    const FxDot(size: 8, color: Fx.surfaceHighest),
                ],
              ),
            ),
            const SizedBox(height: _M.moduleGap),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Fx.display18.copyWith(color: Fx.ink),
            ),
            const SizedBox(height: _M.g4),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.moduleFooter),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.technicianChecksCount(category.done, category.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: done
                          ? Fx.text(
                              11,
                              14,
                              FontWeight.w700,
                              0.44,
                              color: Fx.emerald,
                            )
                          : Fx.body13.copyWith(color: Fx.muted),
                    ),
                  ),
                  if (done)
                    const FxDot(size: 6)
                  else if (inProgress)
                    _ProgressBar(fraction: category.fraction)
                  else
                    Text(
                      l10n.technicianModuleNotStarted,
                      style: Fx.caption.copyWith(
                        color: Fx.muted,
                        letterSpacing: 0.44,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _M.progressWidth,
      height: _M.progressHeight,
      decoration: BoxDecoration(
        color: Fx.surfaceHigh,
        borderRadius: BorderRadius.circular(_M.pill),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          height: _M.progressHeight,
          decoration: BoxDecoration(
            color: Fx.emerald,
            borderRadius: BorderRadius.circular(_M.pill),
          ),
        ),
      ),
    );
  }
}

class _VehicleStrip extends StatelessWidget {
  const _VehicleStrip({required this.job, required this.onTap, this.image});

  final TechnicianJob job;
  final VoidCallback onTap;
  final ui.Image? image;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final odometer = formatOdometer(job.odometerValue, job.odometerUnit);
    final title = '${job.vehicleMake} ${job.vehicleModel}'.trim();
    final subtitle = [
      job.reference,
      if (odometer.isNotEmpty) odometer,
    ].where((value) => value.isNotEmpty).join(' • ');
    return Container(
      constraints: const BoxConstraints(minHeight: _M.vehicleHeight),
      decoration: const BoxDecoration(
        color: Fx.white,
        boxShadow: Fx.cardShadow,
      ),
      padding: EdgeInsets.all(context.spacing.lg),
      child: Semantics(
        button: true,
        label: '$title, $subtitle',
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: _M.vehicleAvatar,
                height: _M.vehicleAvatar,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Fx.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: image == null
                    ? const FxIcon(id: '1_7804', size: 24, color: Fx.ink)
                    : ClipOval(
                        child: RawImage(image: image, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(width: _M.g12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title.isEmpty ? l10n.technicianUnknownVehicle : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.title16.copyWith(color: Fx.ink),
                    ),
                    Text(
                      subtitle,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.body13.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: _M.g8),
              Container(
                width: _M.chevron,
                height: _M.chevron,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: FxIcon(id: '1_7765', size: 9, color: Fx.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _M {
  static const double gutter = 20;
  static const double bodyTop = 16;
  static const double bodyBottom = 16;
  static const double pill = 999;
  static const double g2 = 2;
  static const double g4 = 4;
  static const double g8 = 8;
  static const double g12 = 12;

  static const double g24 = 24;
  static const double headerMark = 36;
  static const double dockSlot = 56;
  static const double dockGap = 23.5;
  static const double statusBlock = 42;
  static const double statusBottom = 16;
  static const double statusPillHeight = 26;
  static const double heroBlock = 302;
  static const double heroBottom = 24;
  static const double cardRadius = 32;
  static const double cardPad = 24;
  static const double ringBlock = 192;
  static const double statPillHeight = 26;
  static const double vehicleBlock = 104;
  static const double vehicleHeight = 80;
  static const double vehicleAvatar = 48;
  static const double chevron = 32;
  static const double sectionBlock = 34;
  static const double gridGap = 16;
  static const double moduleWidth = 167;
  static const double moduleInner = 127;
  static const double moduleHeader = 40;
  static const double moduleGap = 41;
  static const double moduleFooter = 18;
  static const double moduleIcon = 40;
  static const double moduleGlyph = 16.5;
  static const double donePin = 28;
  static const double progressPill = 28;
  static const double progressWidth = 40;
  static const double progressHeight = 6;
  static const double ctaBlock = 64;
}
