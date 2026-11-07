import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/ui_helpers.dart';

String formatOdometer(int? value, String? unit) {
  if (value == null) {
    return '';
  }
  final formatted =
      NumberFormat.decimalPattern(Intl.getCurrentLocale()).format(value);
  return '$formatted ${(unit ?? 'KM').toUpperCase()}';
}

String scheduledTimeUtc4(String scheduledAt) {
  final parsed = DateTime.tryParse(scheduledAt);
  if (parsed == null) {
    return '';
  }
  final local = parsed.toUtc().add(const Duration(hours: 4));
  final time = DateFormat.Hm(Intl.getCurrentLocale()).format(local);
  return '$time UTC+4';
}

bool scheduledTodayUtc4(String scheduledAt, DateTime nowUtc) {
  final parsed = DateTime.tryParse(scheduledAt);
  if (parsed == null) {
    return true;
  }
  final local = parsed.toUtc().add(const Duration(hours: 4));
  final today = nowUtc.toUtc().add(const Duration(hours: 4));
  return local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
}

class AssignedJobsView extends StatelessWidget {
  const AssignedJobsView({
    required this.technicianName,
    required this.jobs,
    required this.pendingSyncCount,
    required this.online,
    required this.onOpenJob,
    required this.onRefresh,
    required this.onWalkIn,
    required this.onSync,
    required this.onProfile,
    this.onCompleted,
    this.onSearch,
    this.nowUtc,
    this.showSearch = true,
    this.avatarImage,
    super.key,
  });

  final String technicianName;
  final List<TechnicianJob> jobs;
  final int pendingSyncCount;
  final bool online;
  final ValueChanged<TechnicianJob> onOpenJob;
  final Future<void> Function() onRefresh;
  final VoidCallback onWalkIn;
  final VoidCallback onSync;
  final VoidCallback onProfile;
  final VoidCallback? onCompleted;
  final VoidCallback? onSearch;
  final DateTime? nowUtc;
  final bool showSearch;
  final ui.Image? avatarImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = nowUtc ?? DateTime.now().toUtc();
    final today = jobs
        .where((job) => scheduledTodayUtc4(job.scheduledAt, now))
        .where((job) => job.status != 'FINALIZED' && job.status != 'CANCELLED')
        .toList(growable: false);
    final pendingCheck = jobs
        .where((job) => job.status != 'FINALIZED' && job.status != 'CANCELLED')
        .length;
    final inProgress = jobs
        .where(
          (job) =>
              job.status == 'IN_PROGRESS' || job.status == 'READY_TO_FINALIZE',
        )
        .length;
    final title = l10n.technicianInspectionQueue;
    final shiftLabel = l10n.technicianShiftToday(today.length);

    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: title,
        titleStyle: Fx.text(16, 22, FontWeight.w700, -0.4),
        horizontalPadding: _M.gutter,
        actions: [
          _SyncPill(online: online),
          const SizedBox(width: _M.g8),
          SizedBox(
            width: _M.profileHit,
            height: _M.profileHit,
            child: Center(
              child: FxProfileButton(
                initials: fxInitials(technicianName),
                image: avatarImage,
                onPressed: onProfile,
                semanticLabel: technicianName,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _JobsDock(
        selectedIndex: 0,
        jobsLabel: l10n.technicianJobsTitle,
        fleetLabel: l10n.statusFinalized,
        syncLabel: l10n.technicianSyncTitle,
        profileLabel: l10n.technicianProfileTitle,
        onSync: onSync,
        onProfile: onProfile,
        onCompleted: onCompleted,
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        color: Fx.emerald,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            _M.gutter,
            0,
            _M.gutter,
            _M.bodyBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _M.topRowHeight),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: _M.topRowTop,
                    bottom: _M.topRowBottom,
                  ),
                  child: Row(
                    children: [
                      FxAvatar(
                        initials: fxInitials(technicianName),
                        image: avatarImage,
                        size: _M.avatarOuter,
                        textStyle: Fx.text(
                          18,
                          24,
                          FontWeight.w700,
                          -0.45,
                          color: Fx.white,
                        ),
                        glow: true,
                        semanticLabel: technicianName,
                      ),
                      const Spacer(),
                      Flexible(
                        child: _InfoPill(
                          iconId: '1_7302',
                          iconColor: Fx.deepGreen,
                          label: shiftLabel,
                          height: _M.shiftPillHeight,
                          textStyle: Fx.text(
                            11,
                            14,
                            FontWeight.w700,
                            0.55,
                            color: Fx.secondaryInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _M.welcomeBlock),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: _M.welcomeBottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.technicianWelcomeBack,
                        style: Fx.text(
                          18,
                          24,
                          FontWeight.w600,
                          0,
                          color: Fx.muted,
                        ),
                      ),
                      const SizedBox(height: _M.g2),
                      Text(
                        technicianName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Fx.display26.copyWith(color: Fx.ink),
                      ),
                    ],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _M.snapshotBlock),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: _M.snapshotBottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SnapshotCard(
                          value: '$pendingCheck',
                          label: l10n.technicianPendingCheck,
                          iconId: '1_7158',
                          tint: Fx.tintMint,
                          iconColor: Fx.deepGreen,
                        ),
                      ),
                      const SizedBox(width: _M.cardGap),
                      Expanded(
                        child: _SnapshotCard(
                          value: '$inProgress',
                          label: l10n.statusInProgress,
                          iconId: '1_7167',
                          tint: Fx.tintLilac,
                          iconColor: Fx.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _M.sectionBlock),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: _M.cardGap),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.technicianAssignedToday.toUpperCase(),
                            style: Fx.text(
                              14,
                              18,
                              FontWeight.w700,
                              0.7,
                              color: Fx.muted,
                            ),
                          ),
                        ),
                        Flexible(
                          child: FxPill(
                            label: l10n.technicianJobsInQueue(today.length),
                            background: Fx.tintEmerald,
                            foreground: Fx.deepGreen,
                            height: _M.queuePillHeight,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            style: Fx.text(
                              11,
                              14,
                              FontWeight.w700,
                              0.44,
                              color: Fx.deepGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (today.isEmpty)
                _EmptyPanel(
                  onRefresh: onRefresh,
                  onWalkIn: onWalkIn,
                  pendingSyncCount: pendingSyncCount,
                )
              else
                ...today.indexed.map(
                  (entry) => Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: entry.$1 == today.length - 1 ? 0 : _M.cardGap,
                    ),
                    child: _JobCard(
                      job: entry.$2,
                      index: entry.$1,
                      onTap: () => onOpenJob(entry.$2),
                    ),
                  ),
                ),
              SizedBox(
                height: _M.ctaBlock,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: _M.ctaTop,
                    bottom: _M.ctaBottom,
                  ),
                  child: FxButton(
                    label: l10n.walkInJob,
                    onPressed: onWalkIn,
                    icon: const FxIcon(
                      id: '1_7158',
                      size: 16.67,
                      color: Fx.white,
                    ),
                    trailingIcon: false,
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

/// Screen 3: the dedicated empty-state dashboard.
class EmptyJobsView extends StatelessWidget {
  const EmptyJobsView({
    required this.technicianName,
    required this.pendingSyncCount,
    required this.onRefresh,
    required this.onWalkIn,
    required this.onSync,
    required this.onProfile,
    this.completedToday = 0,
    this.onCompleted,
    this.avatarImage,
    super.key,
  });

  final String technicianName;
  final int pendingSyncCount;
  final Future<void> Function() onRefresh;
  final VoidCallback onWalkIn;
  final VoidCallback onSync;
  final VoidCallback onProfile;
  final int completedToday;
  final VoidCallback? onCompleted;
  final ui.Image? avatarImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: l10n.technicianInspectionQueue,
        titleStyle: Fx.text(16, 22, FontWeight.w700, -0.4),
        horizontalPadding: _M.gutter,
        actions: [
          const _SyncPill(online: true),
          const SizedBox(width: _M.g8),
          SizedBox(
            width: _M.profileHit,
            height: _M.profileHit,
            child: Center(
              child: FxProfileButton(
                initials: fxInitials(technicianName),
                image: avatarImage,
                onPressed: onProfile,
                semanticLabel: technicianName,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _JobsDock(
        selectedIndex: 0,
        jobsLabel: l10n.technicianJobsTitle,
        fleetLabel: l10n.statusFinalized,
        syncLabel: l10n.technicianSyncTitle,
        profileLabel: l10n.technicianProfileTitle,
        onSync: onSync,
        onProfile: onProfile,
        onCompleted: onCompleted,
        iconIds: const ['1_7378', '1_7383', '1_7388', '1_7393'],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          _M.gutter,
          0,
          _M.gutter,
          _M.emptyBodyBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.emptyTopRow),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: 8,
                  end: 16,
                  bottom: 16,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _M.contentWidth,
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              FxAvatar(
                                initials: fxInitials(technicianName),
                                image: avatarImage,
                                size: _M.emptyAvatar,
                                glow: true,
                                glowInset: 8,
                                textStyle: Fx.text(
                                  16,
                                  22,
                                  FontWeight.w800,
                                  -0.4,
                                  color: Fx.white,
                                ),
                                semanticLabel: technicianName,
                              ),
                              const SizedBox(width: _M.g8),
                              Flexible(
                                child: _InfoPill(
                                  iconId: '1_7143',
                                  leadingDot: true,
                                  label: l10n.technicianQueueEmpty,
                                  height: _M.emptyShiftHeight,
                                  textStyle: Fx.text(
                                    11,
                                    14,
                                    FontWeight.w700,
                                    0.55,
                                    color: Fx.secondaryInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: _M.g8),
                        _InfoPill(
                          iconId: '1_7143',
                          iconColor: Fx.deepGreen,
                          label: l10n.technicianJobsCount(0),
                          height: _M.emptyBayHeight,
                          textStyle: Fx.text(
                            11,
                            14,
                            FontWeight.w700,
                            0.44,
                            color: Fx.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.emptyWelcome),
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: context.spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.technicianWelcomeBack,
                      style: Fx.welcome16.copyWith(color: Fx.muted),
                    ),
                    const SizedBox(height: _M.g2),
                    Text(
                      technicianName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.display26.copyWith(color: Fx.ink),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: _M.emptyStackHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    top: _M.barsTop,
                    left: 0,
                    right: 0,
                    child: Center(child: _Bars()),
                  ),
                  const Positioned(
                    top: _M.artTop,
                    left: 0,
                    right: 0,
                    child: Center(child: _EmptyArt()),
                  ),
                  Positioned(
                    top: _M.queuePillTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FxPill(
                        label: l10n.technicianJobsInQueue(0).toUpperCase(),
                        background: Fx.tintEmerald,
                        foreground: Fx.emerald,
                        height: 22,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        gap: 6,
                        leading: const FxIcon(
                          id: '1_7318',
                          size: 11.67,
                          color: Fx.emerald,
                        ),
                        style: Fx.text(
                          11,
                          14,
                          FontWeight.w700,
                          0.44,
                          color: Fx.emerald,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: _M.headTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: _M.headingWidth,
                        child: Text(
                          l10n.technicianAllCaughtUp,
                          textAlign: TextAlign.center,
                          style: Fx.display22.copyWith(color: Fx.ink),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: _M.bodyTop,
                    left: 35,
                    right: 35,
                    child: Center(
                      child: Text(
                        l10n.technicianNoJobsBody,
                        textAlign: TextAlign.center,
                        style: Fx.text(
                          14,
                          22.75,
                          FontWeight.w500,
                          -0.07,
                          color: Fx.muted,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: _M.refreshTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: _M.refreshWidth,
                        child: FxButton(
                          label: l10n.technicianRefreshQueue,
                          onPressed: onRefresh,
                          tone: FxButtonTone.tonal,
                          height: 48,
                          icon: const FxIcon(
                            id: '1_7328',
                            size: 13.33,
                            color: Fx.muted,
                          ),
                          trailingIcon: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.summaryHeight),
              child: _SummaryStrip(
                completedToday: completedToday,
                pendingSyncCount: pendingSyncCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobsDock extends StatelessWidget {
  const _JobsDock({
    required this.selectedIndex,
    required this.jobsLabel,
    required this.fleetLabel,
    required this.syncLabel,
    required this.profileLabel,
    required this.onSync,
    required this.onProfile,
    this.onCompleted,
    this.iconIds = const ['1_7269', '1_7274', '1_7279', '1_7284'],
  });

  final int selectedIndex;
  final String jobsLabel;
  final String fleetLabel;
  final String syncLabel;
  final String profileLabel;
  final VoidCallback onSync;
  final VoidCallback onProfile;
  final VoidCallback? onCompleted;
  final List<String> iconIds;

  @override
  Widget build(BuildContext context) {
    return FxDock(
      key: const Key('f2a1-dock'),
      selectedIndex: selectedIndex,
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
          label: jobsLabel,
          iconId: iconIds[0],
          semanticLabel: jobsLabel,
        ),
        FxDockItem(
          label: fleetLabel,
          iconId: iconIds[1],
          semanticLabel: fleetLabel,
        ),
        FxDockItem(
          label: syncLabel,
          iconId: iconIds[2],
          semanticLabel: syncLabel,
        ),
        FxDockItem(
          label: profileLabel,
          iconId: iconIds[3],
          semanticLabel: profileLabel,
        ),
      ],
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = online
        ? l10n.technicianOnlineSync
        : l10n.technicianOfflineSync;
    return Container(
      constraints: const BoxConstraints(minHeight: _M.syncPillHeight),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(_M.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _M.syncDotWidth,
            height: _M.syncDotHeight,
            decoration: BoxDecoration(
              color: online ? Fx.emerald : Fx.muted,
              borderRadius: BorderRadius.circular(_M.pill),
            ),
          ),
          const SizedBox(width: _M.g6),
          Text(
            label,
            style: Fx.text(
              11,
              14,
              FontWeight.w600,
              0.275,
              color: Fx.secondaryInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.iconId,
    required this.label,
    required this.height,
    required this.textStyle,
    this.iconColor = Fx.ink,
    this.leadingDot = false,
  });

  final String iconId;
  final String label;
  final double height;
  final TextStyle textStyle;
  final Color iconColor;
  final bool leadingDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(_M.pill),
        boxShadow: height >= 26 ? Fx.softShadow : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot)
            const FxDot(size: 8)
          else
            FxIcon(id: iconId, size: 14.67, color: iconColor),
          const SizedBox(width: _M.g6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.value,
    required this.label,
    required this.iconId,
    required this.tint,
    required this.iconColor,
  });

  final String value;
  final String label;
  final String iconId;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: _M.snapshotHeight),
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.circular(_M.r16),
        boxShadow: Fx.panelShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: FxIcon(id: iconId, size: 18, color: iconColor),
          ),
          const SizedBox(width: _M.g12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.display16.copyWith(color: Fx.ink),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Fx.caption.copyWith(color: Fx.muted),
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

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.index, required this.onTap});

  final TechnicianJob job;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = job.scope.isNotEmpty ? job.scope : job.templateName;
    final reference =
        '${job.reference}${job.vehiclePlate == null || job.vehiclePlate!.isEmpty ? '' : ' · ${job.vehiclePlate}'}';
    final dotColor = switch (job.status) {
      'ASSIGNED' => Fx.warningRed,
      'SCHEDULED' => Fx.sage,
      _ => Fx.emerald,
    };
    return FxCard(
      radius: _M.jobCardRadius,
      padding: EdgeInsets.all(context.spacing.gutter),
      onTap: onTap,
      semanticLabel:
          '${job.vehicleMake} ${job.vehicleModel}, $reference, '
          '${technicianStatusLabel(l10n, job.status)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _M.jobTopHeight),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: _M.carPillWidth,
                  height: _M.carPillHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.circular(_M.r16),
                  ),
                  child: const FxIcon(id: '1_7185', size: 21, color: Fx.ink),
                ),
                const SizedBox(width: _M.g16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${job.vehicleMake} ${job.vehicleModel}'.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Fx.title16.copyWith(color: Fx.ink),
                      ),
                      const SizedBox(height: _M.g2),
                      Text(
                        reference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: Fx.body13.copyWith(color: Fx.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _M.g8),
                Container(
                  width: _M.chevronHit,
                  height: _M.chevronHit,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Fx.tintEmerald,
                    shape: BoxShape.circle,
                    boxShadow: Fx.softShadow,
                  ),
                  child: const FxIcon(
                    id: '1_7194',
                    size: 11,
                    color: Fx.emerald,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _M.g16),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _M.jobBottomHeight),
            child: Padding(
              padding: EdgeInsetsDirectional.only(top: context.spacing.md),
              child: Row(
                children: [
                  FxDot(size: 8, color: dotColor),
                  const SizedBox(width: _M.g6),
                  Expanded(
                    child: Text(
                      service.isEmpty ? l10n.technicianTemplate : service,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.captionMedium.copyWith(
                        color: Fx.muted,
                        letterSpacing: 0.44,
                      ),
                    ),
                  ),
                  const SizedBox(width: _M.g8),
                  FxPill(
                    label: technicianStatusLabel(l10n, job.status),
                    height: _M.statusPillHeight,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    style: Fx.caption.copyWith(color: Fx.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.onRefresh,
    required this.onWalkIn,
    required this.pendingSyncCount,
  });

  final Future<void> Function() onRefresh;
  final VoidCallback onWalkIn;
  final int pendingSyncCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FxCard(
      radius: _M.jobCardRadius,
      padding: EdgeInsets.all(context.spacing.gutter),
      child: Column(
        children: [
          const _EmptyArt(),
          const SizedBox(height: _M.g16),
          FxPill(
            label: l10n.technicianJobsInQueue(0).toUpperCase(),
            background: Fx.tintEmerald,
            foreground: Fx.emerald,
            style: Fx.caption.copyWith(color: Fx.emerald),
          ),
          const SizedBox(height: _M.g12),
          Text(
            l10n.technicianAllCaughtUp,
            textAlign: TextAlign.center,
            style: Fx.display22.copyWith(color: Fx.ink),
          ),
          const SizedBox(height: _M.g8),
          Text(
            l10n.technicianNoJobsBody,
            textAlign: TextAlign.center,
            style: Fx.body14.copyWith(color: Fx.muted),
          ),
          const SizedBox(height: _M.g20),
          FxButton(
            label: l10n.technicianRefreshQueue,
            onPressed: onRefresh,
            tone: FxButtonTone.tonal,
            height: 48,
            icon: const FxIcon(id: '1_7328', size: 13.33, color: Fx.muted),
            trailingIcon: false,
          ),
          const SizedBox(height: _M.g8),
          FxButton(
            label: l10n.walkInJob,
            onPressed: onWalkIn,
            tone: FxButtonTone.text,
            height: 48,
            trailingIcon: false,
          ),
        ],
      ),
    );
  }
}

class _EmptyArt extends StatelessWidget {
  const _EmptyArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _M.artSize,
      height: _M.artSize,
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.circular(_M.artRadius),
        boxShadow: Fx.cardShadow,
      ),
      alignment: Alignment.center,
      child: Container(
        width: _M.artInner,
        height: _M.artInner,
        decoration: BoxDecoration(
          color: Fx.container,
          borderRadius: BorderRadius.circular(_M.r16),
        ),
        child: const Center(
          child: FxIcon(id: '1_7335', size: 33, color: Fx.iconGrey),
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _M.barsWidth,
      height: _M.barsHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 12,
            decoration: BoxDecoration(
              color: Fx.barMedium,
              borderRadius: BorderRadius.circular(_M.pill),
            ),
          ),
          const SizedBox(width: _M.g4),
          Container(
            width: 6,
            height: 16,
            decoration: BoxDecoration(
              color: Fx.barStrong,
              borderRadius: BorderRadius.circular(_M.pill),
            ),
          ),
          const SizedBox(width: _M.g4),
          Container(
            width: 6,
            height: 10,
            decoration: BoxDecoration(
              color: Fx.barWeak,
              borderRadius: BorderRadius.circular(_M.pill),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.completedToday,
    required this.pendingSyncCount,
  });

  final int completedToday;
  final int pendingSyncCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: _M.summaryHeight),
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(_M.r16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Fx.white,
              shape: BoxShape.circle,
              boxShadow: Fx.pillShadow,
            ),
            child: const FxIcon(id: '1_7350', size: 16.5, color: Fx.emerald),
          ),
          const SizedBox(width: _M.g12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.technicianTodaySummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.caption.copyWith(
                    color: Fx.muted,
                    letterSpacing: 0.44,
                  ),
                ),
                const SizedBox(height: _M.g2),
                Text(
                  l10n.technicianCompletedToday(completedToday),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: _M.g8),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    l10n.technicianCoverageOnly,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Fx.text(
                      12,
                      16,
                      FontWeight.w700,
                      0.24,
                      color: Fx.deepGreen,
                    ),
                  ),
                ),
                const SizedBox(width: _M.g4),
                const FxIcon(id: '1_7360', size: 12, color: Fx.deepGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class _M {
  static const double gutter = 20;
  static const double contentWidth = 334;
  static const double pill = 999;
  static const double r16 = 16;

  static const double g2 = 2;
  static const double g4 = 4;
  static const double g6 = 6;
  static const double g8 = 8;
  static const double g12 = 12;
  static const double g16 = 16;
  static const double g20 = 20;
  static const double bodyBottom = 32;
  static const double emptyBodyBottom = 32;
  static const double profileHit = 44;
  static const double topRowHeight = 88;
  static const double topRowTop = 8;
  static const double topRowBottom = 24;
  static const double avatarOuter = 56;
  static const double shiftPillHeight = 26;
  static const double welcomeBlock = 90;
  static const double welcomeBottom = 32;
  static const double snapshotBlock = 104;
  static const double snapshotBottom = 32;
  static const double snapshotHeight = 72;
  static const double cardGap = 16;
  static const double sectionBlock = 34;
  static const double queuePillHeight = 18;
  static const double jobCardRadius = 24;
  static const double jobTopHeight = 44;
  static const double jobBottomHeight = 30;
  static const double carPillWidth = 52;
  static const double carPillHeight = 18.67;
  static const double chevronHit = 44;
  static const double statusPillHeight = 18;
  static const double ctaBlock = 88;
  static const double ctaTop = 24;
  static const double ctaBottom = 8;
  static const double syncPillHeight = 36;
  static const double syncDotWidth = 4.81;
  static const double syncDotHeight = 8;
  static const double emptyTopRow = 72;
  static const double emptyAvatar = 48;
  static const double emptyShiftHeight = 22;
  static const double emptyBayHeight = 26;
  static const double emptyWelcome = 66;
  static const double emptyStackHeight = 497.75;
  static const double barsTop = 36;
  static const double barsWidth = 26;
  static const double barsHeight = 16;
  static const double artTop = 48;
  static const double artSize = 128;
  static const double artInner = 80;
  static const double artRadius = 24;
  static const double queuePillTop = 208;
  static const double headTop = 241.6;
  static const double bodyTop = 279.57;
  static const double headingWidth = 216;
  static const double refreshTop = 357.75;
  static const double refreshWidth = 168.39;
  static const double summaryHeight = 72;
}
