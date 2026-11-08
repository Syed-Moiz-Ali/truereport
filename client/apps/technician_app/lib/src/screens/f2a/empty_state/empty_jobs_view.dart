import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Screen 03: 3._Empty_State_Dashboard
///
/// Pixel-perfect implementation matching Figma export node 1:7287 (390 x 883.75).
/// All icons, text styles, colors, and layout bounding boxes mirror Figma exactly.
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
    this.onIntake,
    this.selectedIndex = 0,
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
  final VoidCallback? onIntake;
  final int selectedIndex;
  final ui.Image? avatarImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final isLargeText = textScale > 1.05;

    return AppScaffold(
      backgroundColor: Fx.white,
      extendBody: true,
      appBar: FxHeader(
        title: l10n.technicianInspectionQueue,
        titleStyle: Fx.text(16, 22, FontWeight.w700, -0.4),
        horizontalPadding: _Metrics.gutter,
        endPadding: 18.75,
        actions: [
          const _SyncPill(online: true),
          const SizedBox(width: _Metrics.g8),
          SizedBox(
            width: _Metrics.profileHit,
            height: _Metrics.profileHit,
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
        selectedIndex: selectedIndex,
        jobsLabel: isAr ? 'استلام' : 'Intake',
        fleetLabel: isAr ? 'الأسطول' : 'Fleet',
        syncLabel: l10n.technicianSyncTitle,
        profileLabel: l10n.technicianProfileTitle,
        onIntake: onIntake,
        onSync: onSync,
        onProfile: onProfile,
        onCompleted: onCompleted,
        iconIds: const ['1_7378', '1_7383', '1_7388', '1_7393'],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          _Metrics.gutter,
          0,
          _Metrics.gutter,
          _Metrics.dockReservedBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Avatar (48x48) + Shift Pill (116.48x22) + Bay Pill (84.69x26)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _Metrics.topRowHeight),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: 8,
                  bottom: 16,
                ),
                child: Row(
                  children: [
                    FxAvatar(
                      initials: fxInitials(technicianName),
                      image: null, // Monogram circle only, photo belongs in header FxProfileButton
                      size: _Metrics.avatarSize,
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
                    const SizedBox(width: _Metrics.g8),
                    if (isLargeText)
                      Flexible(
                        child: _ShiftPill(
                          label: l10n.technicianQueueEmpty,
                        ),
                      )
                    else
                      _ShiftPill(
                        label: l10n.technicianQueueEmpty,
                      ),
                    const Spacer(),
                    _BayPill(
                      label: l10n.technicianJobsCount(0),
                    ),
                  ],
                ),
              ),
            ),

            // Welcome Section: Welcome back, David Vance (height: 66)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _Metrics.welcomeHeight),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.technicianWelcomeBack,
                      style: Fx.welcome16.copyWith(color: Fx.muted),
                    ),
                    const SizedBox(height: _Metrics.g2),
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

            // Vacated Job-List Region / Empty Center Stack (height: 497.75)
            SizedBox(
              height: _Metrics.emptyStackHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 128x128 Art Card (y: 250 in frame -> 48 inside stack)
                  const Positioned(
                    top: _Metrics.artTop,
                    left: 0,
                    right: 0,
                    child: Center(child: _EmptyArt()),
                  ),

                  // 3 Floating Equalizer Bars (y: 238 in frame -> 36 inside stack, painted over art card)
                  const Positioned(
                    top: _Metrics.barsTop,
                    left: 0,
                    right: 0,
                    child: Center(child: _Bars()),
                  ),

                  // Queue Pill: "0 IN QUEUE" (y: 410 in frame -> 208 inside stack)
                  Positioned(
                    top: _Metrics.queuePillTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        height: 22,
                        padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
                        decoration: BoxDecoration(
                          color: Fx.tintEmerald,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FxIcon(
                              id: '1_7318',
                              size: 11.67,
                              color: Fx.emerald,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.technicianJobsInQueue(0).toUpperCase(),
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w700,
                                0.44,
                                color: Fx.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Heading: "You are all caught up!" (y: 443.6 in frame -> 241.6 inside stack)
                  Positioned(
                    top: _Metrics.headingTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: _Metrics.headingWidth,
                        child: Text(
                          l10n.technicianAllCaughtUp,
                          textAlign: TextAlign.center,
                          style: Fx.display22.copyWith(color: Fx.ink),
                        ),
                      ),
                    ),
                  ),

                  // Body: "No pending vehicle inspections assigned..." (y: 481.57 in frame -> 279.57 inside stack)
                  Positioned(
                    top: _Metrics.bodyTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 280,
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
                  ),

                  // Refresh Button: "Refresh Queue" (y: 559.75 in frame -> 357.75 inside stack, x: 107.47)
                  Positioned(
                    top: _Metrics.refreshTop,
                    left: 87.47,
                    width: _Metrics.refreshWidth,
                    child: _RefreshButton(
                      label: l10n.technicianRefreshQueue,
                      onPressed: onRefresh,
                    ),
                  ),

                  // Synced Status Pill (Figma node 1:7341, opacity: 0 in design)
                  Positioned(
                    top: _Metrics.syncedPillTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Opacity(
                        opacity: 0,
                        child: Container(
                          width: 251.74,
                          height: 26,
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEDF3),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Queue is current • Synced just now',
                                style: Fx.text(
                                  11,
                                  14,
                                  FontWeight.w600,
                                  0.44,
                                  color: const Color(0xFF3C4A42),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Summary Strip: Today's Summary | 14 Completed | 100% Pass Rate (height: 72)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _Metrics.summaryHeight),
              child: _SummaryCard(
                completedToday: completedToday,
                isLargeText: isLargeText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftPill extends StatelessWidget {
  const _ShiftPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _Metrics.shiftPillHeight,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Fx.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: _Metrics.g6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Fx.text(
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
    );
  }
}

class _BayPill extends StatelessWidget {
  const _BayPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _Metrics.bayPillHeight,
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: Fx.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FxIcon(
            id: '1_7302',
            width: 14.67,
            height: 14,
            color: Fx.deepGreen,
          ),
          const SizedBox(width: _Metrics.g6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Fx.text(
                11,
                14,
                FontWeight.w700,
                0.44,
                color: Fx.ink,
              ),
            ),
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
      width: _Metrics.artSize,
      height: _Metrics.artSize,
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.circular(_Metrics.artRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000), // rgba(0, 0, 0, 0.016)
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0B000000), // rgba(0, 0, 0, 0.043)
            blurRadius: 40,
            offset: Offset(0, 14),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: _Metrics.artInner,
        height: _Metrics.artInner,
        decoration: BoxDecoration(
          color: Fx.container,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: FxIcon(
            id: '1_7335',
            width: 33,
            height: 33,
            color: Color(0xFF62616D),
          ),
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
      width: _Metrics.barsWidth,
      height: _Metrics.barsHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 12,
            decoration: BoxDecoration(
              color: Fx.barMedium, // rgba(94, 93, 105, 0.30)
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          const SizedBox(width: _Metrics.g4),
          Container(
            width: 6,
            height: 16,
            decoration: BoxDecoration(
              color: Fx.barStrong, // rgba(94, 93, 105, 0.40)
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          const SizedBox(width: _Metrics.g4),
          Container(
            width: 6,
            height: 10,
            decoration: BoxDecoration(
              color: Fx.barWeak, // rgba(94, 93, 105, 0.20)
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _Metrics.refreshWidth,
      height: 48,
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000), // rgba(0, 0, 0, 0.03)
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(9999),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FxIcon(
                id: '1_7328',
                width: 13.33,
                height: 13.33,
                color: Color(0xFF5E5D69),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.text(
                    14,
                    18,
                    FontWeight.w700,
                    -0.14,
                    color: Fx.ink,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.completedToday,
    this.isLargeText = false,
  });

  final int completedToday;
  final bool isLargeText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.technicianTodaySummary,
          style: Fx.text(
            11,
            14,
            FontWeight.w600,
            0.44,
            color: Fx.muted,
          ),
        ),
        Text(
          l10n.technicianCompletedToday(completedToday),
          style: Fx.text(
            16,
            22,
            FontWeight.w700,
            -0.16,
            color: Fx.ink,
          ),
        ),
      ],
    );

    final passRateBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLargeText)
          Flexible(
            child: Text(
              l10n.technicianCoverageOnly,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Fx.text(
                12,
                16,
                FontWeight.w700,
                0.24,
                color: Fx.deepGreen,
              ),
            ),
          )
        else
          Text(
            l10n.technicianCoverageOnly,
            style: Fx.text(
              12,
              16,
              FontWeight.w700,
              0.24,
              color: Fx.deepGreen,
            ),
          ),
        const SizedBox(width: 4),
        const FxIcon(
          id: '1_7360',
          width: 15,
          height: 9,
          color: Fx.deepGreen,
        ),
      ],
    );

    return Container(
      constraints: const BoxConstraints(minHeight: _Metrics.summaryHeight),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 40x40 White circular badge with checkmark icon
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Fx.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const FxIcon(
              id: '1_7350',
              width: 16.5,
              height: 18.33,
              color: Fx.emerald,
            ),
          ),
          const SizedBox(width: 12),
          // Center Text: TODAY'S SUMMARY + {n} Completed
          if (isLargeText)
            Flexible(child: titleBlock)
          else
            titleBlock,
          const Spacer(),
          // Right cluster: 100% Pass Rate + Trend arrow icon
          passRateBlock,
        ],
      ),
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
      width: 65.75,
      height: 36,
      padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 4),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4.81,
            height: 8,
            decoration: BoxDecoration(
              color: online ? Fx.emerald : Fx.muted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Fx.text(
                11,
                14,
                FontWeight.w600,
                0.275,
                color: const Color(0xFF3C4A42),
              ),
            ),
          ),
        ],
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
    this.onIntake,
    this.onCompleted,
    this.iconIds = const ['1_7378', '1_7383', '1_7388', '1_7393'],
  });

  final int selectedIndex;
  final String jobsLabel;
  final String fleetLabel;
  final String syncLabel;
  final String profileLabel;
  final VoidCallback onSync;
  final VoidCallback onProfile;
  final VoidCallback? onIntake;
  final VoidCallback? onCompleted;
  final List<String> iconIds;

  @override
  Widget build(BuildContext context) {
    return FxDock(
      key: const Key('f2a1-dock'),
      selectedIndex: selectedIndex,
      onSelected: (index) {
        switch (index) {
          case 0:
            onIntake?.call();
            break;
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
          iconWidth: 18,
          iconHeight: 20,
          semanticLabel: jobsLabel,
        ),
        FxDockItem(
          label: fleetLabel,
          iconId: iconIds[1],
          iconWidth: 18,
          iconHeight: 16,
          semanticLabel: fleetLabel,
        ),
        FxDockItem(
          label: syncLabel,
          iconId: iconIds[2],
          iconWidth: 22,
          iconHeight: 18,
          semanticLabel: syncLabel,
        ),
        FxDockItem(
          label: profileLabel,
          iconId: iconIds[3],
          iconWidth: 20,
          iconHeight: 20,
          semanticLabel: profileLabel,
        ),
      ],
    );
  }
}

abstract class _Metrics {
  static const double gutter = 20;
  static const double g2 = 2;
  static const double g4 = 4;
  static const double g6 = 6;
  static const double g8 = 8;
  static const double profileHit = 44;
  static const double topRowHeight = 72;
  static const double avatarSize = 48;
  static const double shiftPillHeight = 22;
  static const double bayPillHeight = 26;
  static const double welcomeHeight = 66;
  static const double emptyStackHeight = 497.75;
  static const double barsTop = 36;
  static const double barsWidth = 26;
  static const double barsHeight = 16;
  static const double artTop = 48;
  static const double artSize = 128;
  static const double artInner = 80;
  static const double artRadius = 24;
  static const double queuePillTop = 208;
  static const double headingTop = 241.6;
  static const double headingWidth = 216;
  static const double bodyTop = 279.57;
  static const double refreshTop = 357.75;
  static const double refreshWidth = 168.39;
  static const double syncedPillTop = 421.75;
  static const double summaryHeight = 72;
  static const double dockReservedBottom = 88;
}
