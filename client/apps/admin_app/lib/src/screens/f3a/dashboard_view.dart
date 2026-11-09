import 'dart:ui' as ui;

import 'package:admin_app/src/job_counts.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/screens/f3a/dashboard_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Workshop Dashboard View — Screen 01 (`02_1._Workshop_Dashboard`).
///
/// Pixel-perfect desktop layout (1280 x 1230.672) matching Figma specification.
/// Features:
/// - 96px left navigation rail with TrueReport logo and navigation icons
/// - 80px floating top header with Bay status, search, and user profile
/// - Telemetrics eyebrow, Overview title, and Shift toggle pills
/// - 3 Stat KPI cards: Active Jobs, Pending Finalization, Reports Sent
/// - Live Workshop Activity card with real-time status stream
/// - Floor Telemetry card with capacity donut gauge, flow metrics, and floor map CTA
class WorkshopDashboardView extends StatelessWidget {
  const WorkshopDashboardView({
    super.key,
    this.selectedNavIndex = 0,
    this.onNavSelected,
    this.onDispatchBay,
    this.onSearch,
    this.onProfileTap,
    this.onSignOut,
    this.onToggleLocale,
    required this.counts,
    this.recentJobs,
    this.userName,
    this.userRole,
    this.searchController,
    this.customSvgs,
  });

  final int selectedNavIndex;
  final ValueChanged<int>? onNavSelected;
  final VoidCallback? onDispatchBay;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSignOut;
  final VoidCallback? onToggleLocale;
  final JobCounts counts;
  final List<WorkshopJob>? recentJobs;
  final String? userName;
  final String? userRole;
  final TextEditingController? searchController;
  final Map<String, String>? customSvgs;

  static const double width = 1280;
  static const double height = 1230.672;

  String _svgString(String key) {
    if (customSvgs != null && customSvgs!.containsKey(key)) {
      return customSvgs![key]!;
    }
    switch (key) {
      case 'dispatch':
        return DashboardSvgAssets.dispatch;
      case 'c1':
        return DashboardSvgAssets.c1;
      case 'c2':
        return DashboardSvgAssets.c2;
      case 'c3':
        return DashboardSvgAssets.c3;
      case 'c3check':
        return DashboardSvgAssets.c3check;
      case 'r1':
        return DashboardSvgAssets.r1;
      case 'r2':
        return DashboardSvgAssets.r2;
      case 'r3':
        return DashboardSvgAssets.r3;
      case 'arrow':
        return DashboardSvgAssets.arrow;
      case 'search':
        return DashboardSvgAssets.search;
      case 'avatarUser':
        return DashboardSvgAssets.avatarUser;
      case 'logo':
        return DashboardSvgAssets.logo;
      case 'dash':
        return DashboardSvgAssets.dash;
      case 'jobs':
        return DashboardSvgAssets.jobs;
      case 'navset':
        return DashboardSvgAssets.navset;
      case 'setbot':
        return DashboardSvgAssets.setbot;
      case 'donut':
        return DashboardSvgAssets.donut;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: Fx.white,
            child: Stack(
              children: [
                Positioned(
                  left: _M.ninetySix,
                  top: _M.zero,
                  width: 1184,
                  height: 1231,
                  child: ColoredBox(color: Fx.white, child: _main(context)),
                ),
                Positioned(
                  key: const ValueKey('f3a-header'),
                  left: _M.ninetySix,
                  top: _M.zero,
                  width: 1184,
                  height: _M.eighty,
                  child: _header(context),
                ),
                Positioned(
                  left: _M.zero,
                  top: _M.zero,
                  width: _M.ninetySix,
                  height: _M.eightHundred,
                  child: _rail(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Figma `1:301` Main 1184 x 1230.672, padding 80/40/48/40.
  Widget _main(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _M.forty,
        _M.eighty,
        _M.forty,
        _M.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(context),
          const SizedBox(height: _M.forty),
          _kpiRow(context),
          const SizedBox(height: _M.sixtyFour),
          _lowerRow(context),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // Figma `1:303`-`1:324` title block 1104 x 84.
  Widget _titleRow(BuildContext context) {
    return SizedBox(
      width: 1104,
      height: _M.eightyFour,
      child: Stack(
        children: [
          Positioned(
            left: _M.zero,
            top: _M.zero,
            width: 398.38,
            height: _M.fourteen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: _M.eight,
                  height: _M.eight,
                  decoration: const BoxDecoration(
                    color: Fx.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: _M.eight),
                _t(
                  'TELEMETRICS \u2022 REAL-TIME',
                  154.86,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
                ),
              ],
            ),
          ),
          Positioned(
            left: _M.zero,
            top: _M.eighteen,
            child: _t(
              'Overview',
              147.59,
              _M.thirtyEight,
              Fx.text(32, 38, FontWeight.w800, -0.8, color: Fx.ink),
            ),
          ),
          Positioned(
            left: _M.zero,
            top: _M.sixty,
            child: _t(
              'Fleet throughput and active inspection velocity today',
              398.38,
              _M.twentyFour,
              Fx.text(16, 24, FontWeight.w500, -0.16, color: Fx.muted),
            ),
          ),
          Positioned(
            left: 697.75,
            top: _M.forty,
            width: 406.25,
            height: _M.fortyFour,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _segmented(),
                const SizedBox(width: _M.twelve),
                _dispatchBay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:315` segmented 240.11 x 44: tonal pill + white selected button.
  Widget _segmented() {
    return Container(
      width: 240.11,
      height: _M.fortyFour,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.six,
            top: _M.six,
            width: 136.97,
            height: _M.thirtyTwo,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.white,
                borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: _M.twenty,
                    top: _M.eight,
                    child: _t(
                      'Shift A (Current)',
                      96.97,
                      _M.sixteen,
                      Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 142.97,
            top: _M.six,
            width: 91.14,
            height: _M.thirtyTwo,
            child: Stack(
              children: [
                Positioned(
                  left: _M.twenty,
                  top: _M.eight,
                  child: _t(
                    'Past 24h',
                    51.14,
                    _M.sixteen,
                    Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:320` Dispatch Bay 154.14 x 42, emerald.
  Widget _dispatchBay() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDispatchBay,
        borderRadius: const BorderRadius.all(Radius.circular(Fx.pillRadius)),
        child: Container(
          width: 154.14,
          height: _M.fortyTwo,
          decoration: const BoxDecoration(
            color: Fx.emerald,
            borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
            boxShadow: Fx.ctaShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                left: _M.twenty,
                top: 12.67,
                width: 18.33,
                height: 16.67,
                child: _svg('dispatch', 18.33, 16.67),
              ),
              Positioned(
                left: 46.33,
                top: _M.twelve,
                child: _t(
                  'Dispatch Bay',
                  87.81,
                  _M.eighteen,
                  Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Figma `1:325`-`1:380` KPI row 1104 x 346.67.
  Widget _kpiRow(BuildContext context) {
    final activeNum = counts.inProgress.toString();
    final pendingNum = counts.readyToFinalize.toString();
    final sentNum = counts.finalized.toString();

    return SizedBox(
      width: 1104,
      height: 346.67,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            key: const ValueKey('f3a-kpi-1'),
            width: 346.666,
            height: 346.66,
            child: _statCard(
              icon: 'c1',
              iconWidth: 19.53,
              iconHeight: 20.05,
              pill: _kpiPill1(),
              number: activeNum,
              numberWidth: 29.09,
              suffix: '/ 14 BAYS',
              suffixX: 37.09,
              suffixWidth: 55.55,
              caption: 'Active Jobs',
              fillWidth: 240.26,
              fillColor: Fx.emerald,
            ),
          ),
          const SizedBox(width: _M.thirtyTwo),
          SizedBox(
            width: 346.666,
            height: 346.67,
            child: _statCard(
              icon: 'c2',
              iconWidth: 21.67,
              iconHeight: 19.5,
              pill: _kpiPill2(),
              number: pendingNum,
              numberWidth: 19.59,
              suffix: 'QUEUE',
              suffixX: 27.59,
              suffixWidth: 43.25,
              caption: 'Pending Finalization',
              fillWidth: 79.14,
              fillColor: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: _M.thirtyTwo),
          SizedBox(
            width: 346.666,
            height: 346.66,
            child: _statCard(
              icon: 'c3',
              iconWidth: 22.75,
              iconHeight: 19.5,
              pill: _kpiCircle(),
              number: sentNum,
              numberWidth: 18.66,
              suffix: '100% ACCURACY',
              suffixX: 26.65,
              suffixWidth: 107.28,
              caption: 'Reports Sent',
              fillWidth: 282.67,
              fillColor: Fx.emerald,
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:327` stat card: white r24, single 0/16/40 @3.5 % shadow.
  Widget _statCard({
    required String icon,
    required double iconWidth,
    required double iconHeight,
    required Widget pill,
    required String number,
    required double numberWidth,
    required String suffix,
    required double suffixX,
    required double suffixWidth,
    required String caption,
    required double fillWidth,
    required Color fillColor,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
        boxShadow: [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.thirtyTwo,
            top: _M.thirtyTwo,
            width: 282.67,
            height: _M.fortyEight,
            child: Stack(
              children: [
                Container(
                  width: _M.fortyEight,
                  height: _M.fortyEight,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                  ),
                  alignment: Alignment.center,
                  child: _svg(icon, iconWidth, iconHeight),
                ),
                pill,
              ],
            ),
          ),
          Positioned(
            left: _M.thirtyTwo,
            top: 223.66,
            width: 282.67,
            height: _M.sixtyOne,
            child: Stack(
              children: [
                Positioned(
                  left: _M.zero,
                  top: _M.zero,
                  child: _tNum(number, numberWidth),
                ),
                Positioned(
                  left: suffixX,
                  top: _M.seventeen,
                  child: _t(
                    suffix,
                    suffixWidth,
                    _M.sixteen,
                    Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
                  ),
                ),
                Positioned(
                  left: _M.zero,
                  top: _M.fortyOne,
                  child: _t(
                    caption,
                    282.67,
                    _M.twenty,
                    Fx.text(14, 20, FontWeight.w500, -0.07, color: Fx.muted),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: _M.thirtyTwo,
            top: 309.0,
            width: 282.67,
            height: _M.six,
            child: Stack(
              children: [
                Container(
                  width: 282.67,
                  height: _M.six,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                  ),
                ),
                Container(
                  width: fillWidth,
                  height: _M.six,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:332` +2 incoming pill 109.56 x 28.
  Widget _kpiPill1() {
    return Positioned(
      left: 173.1,
      top: _M.zero,
      width: 109.56,
      height: _M.twentyEight,
      child: Container(
        decoration: const BoxDecoration(
          color: Fx.container,
          borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: _M.twelve),
            Container(
              width: _M.six,
              height: _M.six,
              decoration: const BoxDecoration(
                color: Fx.emerald,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: _M.six),
            _t(
              '+2 incoming',
              73.56,
              _M.sixteen,
              Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.deepGreen),
            ),
          ],
        ),
      ),
    );
  }

  // Figma `1:350` Requires Action pill 134.41 x 28.
  Widget _kpiPill2() {
    return Positioned(
      left: 148.26,
      top: _M.zero,
      width: 134.41,
      height: _M.twentyEight,
      child: Container(
        decoration: const BoxDecoration(
          color: Fx.container,
          borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: _M.twelve),
            Container(
              width: _M.eight,
              height: _M.eight,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: _M.eight),
            _t(
              'Requires Action',
              94.41,
              _M.sixteen,
              Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
            ),
          ],
        ),
      ),
    );
  }

  // Figma `1:368` 32 x 32 tonal circle + check icon.
  Widget _kpiCircle() {
    return Positioned(
      left: 250.66,
      top: _M.zero,
      width: _M.thirtyTwo,
      height: _M.thirtyTwo,
      child: Container(
        decoration: const BoxDecoration(
          color: Fx.container,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: _svg('c3check', 12.23, 9.02),
      ),
    );
  }

  // Figma `1:381` lower split 1104 x 568.
  Widget _lowerRow(BuildContext context) {
    return SizedBox(
      width: 1104,
      height: _M.fiveSixtyEight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            key: const ValueKey('f3a-activity'),
            width: 725.33,
            height: _M.fourSeventySix,
            child: _activityCard(),
          ),
          const SizedBox(width: _M.thirtyTwo),
          SizedBox(
            key: const ValueKey('f3a-telemetry'),
            width: 346.67,
            height: _M.fiveSixtySix,
            child: _telemetryCard(),
          ),
        ],
      ),
    );
  }

  // Figma `1:382` activity card 725.33 x 476.
  Widget _activityCard() {
    return Container(
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
        boxShadow: [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.forty,
            top: _M.forty,
            width: 645.33,
            height: _M.seventySix,
            child: Stack(
              children: [
                Positioned(
                  left: _M.zero,
                  top: _M.zero,
                  child: _t(
                    'Live Workshop Activity',
                    194.27,
                    _M.twentyFour,
                    Fx.text(18, 24, FontWeight.w700, -0.27, color: Fx.ink),
                  ),
                ),
                Positioned(
                  left: _M.zero,
                  top: _M.twentySix,
                  child: _t(
                    'Real-time status stream across active physical bays',
                    314.44,
                    _M.eighteen,
                    Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                  ),
                ),
                Positioned(
                  left: 546.14,
                  top: _M.fifteen,
                  width: 99.19,
                  height: _M.fourteen,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: _M.ten,
                        height: _M.ten,
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: _M.eight),
                      _t(
                        'FEED SYNCED',
                        81.19,
                        _M.fourteen,
                        Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: _M.forty,
            top: 116,
            width: 645.33,
            height: _M.threeTwenty,
            child: Stack(
              children: [
                Positioned(
                  left: _M.zero,
                  top: _M.zero,
                  width: 645.33,
                  height: _M.eightyEight,
                  child: _activityRow(
                    avatarIcon: 'r1',
                    avatarWidth: 22,
                    avatarHeight: 21,
                    textWidth: 384.72,
                    title: 'Porsche Taycan 4S',
                    titleWidth: 142.16,
                    vin: 'VIN \u2022 9J18',
                    vinWidth: 75.83,
                    detail:
                        'Bay 04 \u2022 Full diagnostic pass complete '
                        '(48/48 points checked)',
                    detailLines: 1,
                    pillWidth: 65.23,
                    pillHeight: 26,
                    pillLabel: 'Passed',
                    pillWidthInner: 41.23,
                    pillColor: Fx.deepGreen,
                    pillBold: true,
                    time: '2m ago',
                    timeWidth: 42,
                    timeLines: 1,
                    rightX: 506.08,
                    rightY: 31,
                    rightWidth: 119.24,
                    rightHeight: 26,
                    rightGap: 12.01,
                    contentHeight: 48,
                    avatarTop: 0,
                    textTop: 3,
                  ),
                ),
                Positioned(
                  left: _M.zero,
                  top: 104,
                  width: 645.33,
                  height: _M.oneHundred,
                  child: _activityRow(
                    avatarIcon: 'r2',
                    avatarWidth: 20,
                    avatarHeight: 20,
                    textWidth: 315.27,
                    title: 'Ford Transit Custom',
                    titleWidth: 152.17,
                    vin: 'VIN \u2022 3E41',
                    vinWidth: 78.42,
                    detail:
                        'Bay 02 \u2022 Secondary structural markup '
                        'awaiting lead\ninspector review',
                    detailLines: 2,
                    pillWidth: 105.83,
                    pillHeight: 40,
                    pillLabel: 'Awaiting\nReview',
                    pillWidthInner: 50.68,
                    pillColor: const Color(0xFFD97706),
                    pillBold: true,
                    time: '14m\nago',
                    timeWidth: 40.84,
                    timeLines: 2,
                    rightX: 466.67,
                    rightY: 30,
                    rightWidth: 158.66,
                    rightHeight: 40,
                    rightGap: 11.99,
                    contentHeight: 60,
                    avatarTop: 6,
                    textTop: 0,
                  ),
                ),
                Positioned(
                  left: _M.zero,
                  top: _M.twoTwenty,
                  width: 645.33,
                  height: _M.oneHundred,
                  child: _activityRow(
                    avatarIcon: 'r3',
                    avatarWidth: 21.9,
                    avatarHeight: 12.02,
                    textWidth: 376.72,
                    title: 'Renault M\u00e9gane E-Tech',
                    titleWidth: 179.88,
                    vin: 'VIN \u2022 7K89',
                    vinWidth: 80.69,
                    detail:
                        'Bay 01 \u2022 Sign-off certificate compiled and '
                        'dispatched to fleet\nlead',
                    detailLines: 2,
                    pillWidth: 82.72,
                    pillHeight: 40,
                    pillLabel: 'Signed\nOff',
                    pillWidthInner: 40.36,
                    pillColor: Fx.ink,
                    pillBold: true,
                    time: '42m\nago',
                    timeWidth: 46.52,
                    timeLines: 2,
                    rightX: 484.08,
                    rightY: 30,
                    rightWidth: 141.24,
                    rightHeight: 40,
                    rightGap: 12,
                    contentHeight: 60,
                    avatarTop: 6,
                    textTop: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:394` activity row: white r16, single 0/4/16 @2 % shadow.
  Widget _activityRow({
    required String avatarIcon,
    required double avatarWidth,
    required double avatarHeight,
    required double textWidth,
    required String title,
    required double titleWidth,
    required String vin,
    required double vinWidth,
    required String detail,
    required int detailLines,
    required double pillWidth,
    required double pillHeight,
    required String pillLabel,
    required double pillWidthInner,
    required Color pillColor,
    required bool pillBold,
    required String time,
    required double timeWidth,
    required int timeLines,
    required double rightX,
    required double rightY,
    required double rightWidth,
    required double rightHeight,
    required double rightGap,
    required double contentHeight,
    required double avatarTop,
    required double textTop,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.twenty,
            top: _M.twenty,
            width: textWidth + 64,
            height: contentHeight,
            child: Stack(
              children: [
                Positioned(
                  left: _M.zero,
                  top: avatarTop,
                  width: _M.fortyEight,
                  height: _M.fortyEight,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Fx.container,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _svg(avatarIcon, avatarWidth, avatarHeight),
                  ),
                ),
                Positioned(
                  left: _M.sixtyFour,
                  top: textTop,
                  width: textWidth,
                  height: contentHeight,
                  child: Stack(
                    children: [
                      Positioned(
                        left: _M.zero,
                        top: _M.zero,
                        width: textWidth,
                        height: _M.twentyTwo,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _t(
                              title,
                              titleWidth,
                              _M.twentyTwo,
                              Fx.text(
                                16,
                                22,
                                FontWeight.w700,
                                -0.16,
                                color: Fx.ink,
                              ),
                            ),
                            const SizedBox(width: _M.eight),
                            Container(
                              width: vinWidth,
                              height: _M.eighteen,
                              padding: const EdgeInsets.only(left: _M.ten),
                              decoration: const BoxDecoration(
                                color: Fx.container,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(Fx.pillRadius),
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              child: _t(
                                vin,
                                vinWidth - _M.ten,
                                _M.fourteen,
                                Fx.text(
                                  11,
                                  14,
                                  FontWeight.w600,
                                  0.44,
                                  color: Fx.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: _M.zero,
                        top: _M.twentyFour,
                        child: _tMulti(
                          detail,
                          textWidth,
                          detailLines,
                          Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: rightX,
            top: rightY,
            width: rightWidth,
            height: rightHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: pillWidth,
                  height: pillHeight,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _tMulti(
                    pillLabel,
                    pillWidthInner,
                    2,
                    Fx.text(
                      11,
                      14,
                      pillBold ? FontWeight.w700 : FontWeight.w600,
                      0.44,
                      color: pillColor,
                    ),
                  ),
                ),
                SizedBox(width: rightGap),
                _tMulti(
                  time,
                  timeWidth,
                  timeLines,
                  Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:448` telemetry card 346.67 x 566.
  Widget _telemetryCard() {
    return Container(
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
        boxShadow: [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.thirtyTwo,
            top: _M.thirtyTwo,
            width: 282.67,
            height: 398,
            child: Stack(
              children: [
                Positioned(
                  left: _M.zero,
                  top: _M.zero,
                  width: 282.67,
                  height: _M.twentyTwo,
                  child: Stack(
                    children: [
                      Positioned(
                        left: _M.zero,
                        top: _M.zero,
                        child: _t(
                          'Floor Telemetry',
                          118.42,
                          _M.twentyTwo,
                          Fx.text(
                            16,
                            22,
                            FontWeight.w700,
                            -0.16,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 217.25,
                        top: _M.four,
                        child: _t(
                          'Bays 01-08',
                          65.42,
                          _M.fourteen,
                          Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.44,
                            color: Fx.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: _M.zero,
                  top: _M.fortySix,
                  width: 282.67,
                  height: 192,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 61.33,
                        top: _M.sixteen,
                        width: _M.oneSixty,
                        height: _M.oneSixty,
                        child: _svg('donut', 160, 160),
                      ),
                      Positioned(
                        left: 118.26,
                        top: _M.seventyFive,
                        child: _t(
                          '76%',
                          46.14,
                          _M.twentyEight,
                          Fx.text(
                            22,
                            28,
                            FontWeight.w700,
                            -0.44,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 112.36,
                        top: 103,
                        child: _t(
                          'CAPACITY',
                          57.94,
                          _M.fourteen,
                          Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.44,
                            color: Fx.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: _M.zero,
                  top: 262,
                  width: 282.67,
                  height: 136,
                  child: Stack(
                    children: [
                      _kvRow(
                        top: 8,
                        label: 'Turnaround Target',
                        labelWidth: 110.91,
                        value: '45 mins / car',
                        valueX: 206.7,
                        valueWidth: 75.97,
                        valueStyle: Fx.text(
                          12,
                          16,
                          FontWeight.w600,
                          0.24,
                          color: Fx.ink,
                        ),
                        divider: true,
                      ),
                      _kvRow(
                        top: 55,
                        label: 'Median Flow Rate',
                        labelWidth: 107.52,
                        value: '38 mins',
                        valueX: 236.53,
                        valueWidth: 46.14,
                        valueStyle: Fx.text(
                          12,
                          16,
                          FontWeight.w700,
                          0.24,
                          color: Fx.deepGreen,
                        ),
                        divider: true,
                      ),
                      _kvRow(
                        top: 102,
                        label: 'Inspection Compliance',
                        labelWidth: 143.7,
                        value: '99.4%',
                        valueX: 242.5,
                        valueWidth: 40.17,
                        valueStyle: Fx.text(
                          12,
                          16,
                          FontWeight.w700,
                          0.24,
                          color: Fx.ink,
                        ),
                        divider: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: _M.thirtyTwo,
            top: 486,
            width: 282.67,
            height: _M.fortyEight,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 58.71,
                    top: _M.sixteen,
                    child: _t(
                      'View Detailed Floor Map',
                      145.25,
                      _M.sixteen,
                      Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                    ),
                  ),
                  Positioned(
                    left: 211.96,
                    top: _M.eighteen,
                    width: _M.twelve,
                    height: _M.twelve,
                    child: _svg('arrow', 12, 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:466` kv row: label/value + 1 px bottom divider (rows 1-2).
  Widget _kvRow({
    required double top,
    required String label,
    required double labelWidth,
    required String value,
    required double valueX,
    required double valueWidth,
    required TextStyle valueStyle,
    required bool divider,
  }) {
    return Positioned(
      left: _M.zero,
      top: top,
      width: 282.67,
      height: divider ? _M.thirtyFive : 34,
      child: Container(
        decoration: divider
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Fx.container, width: 1),
                ),
              )
            : null,
        child: Stack(
          children: [
            Positioned(
              left: _M.zero,
              top: _M.eight,
              child: _t(
                label,
                labelWidth,
                _M.eighteen,
                Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
              ),
            ),
            Positioned(
              left: valueX,
              top: _M.nine,
              child: _t(value, valueWidth, _M.sixteen, valueStyle),
            ),
          ],
        ),
      ),
    );
  }

  // Figma `1:487` floating header 1184 x 80, white 90 % + blur 48.
  Widget _header(BuildContext context) {
    final effectiveUser = (userName != null && userName!.isNotEmpty)
        ? userName!
        : 'Marcus Vance';
    final effectiveRole = (userRole != null && userRole!.isNotEmpty)
        ? userRole!
        : 'Lead Inspector';

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          width: 1184,
          height: _M.eighty,
          color: Fx.whiteE5,
          child: Stack(
            children: [
              Positioned(
                left: _M.forty,
                top: _M.twentyFour,
                width: 229.72,
                height: _M.thirtyTwo,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _M.sixteen,
                        top: _M.eleven,
                        width: _M.ten,
                        height: _M.ten,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Fx.emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: _M.thirtyEight,
                        top: _M.nine,
                        child: _t(
                          'BAY ACTIVE',
                          67.8,
                          _M.fourteen,
                          Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.55,
                            color: const Color(0xFF3C4A42),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 117.8,
                        top: _M.eight,
                        child: _t(
                          'Shop Floor #04',
                          95.92,
                          _M.sixteen,
                          Fx.text(12, 16, FontWeight.w700, 0.24, color: Fx.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 675.61,
                top: _M.twentyThree,
                width: 468.39,
                height: 34,
                child: Stack(
                  children: [
                    Positioned(
                      left: _M.zero,
                      top: _M.zero,
                      width: 299,
                      height: 34,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Fx.container,
                          borderRadius: BorderRadius.all(
                            Radius.circular(Fx.pillRadius),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: _M.sixteen,
                              top: 9.5,
                              width: _M.fifteen,
                              height: _M.fifteen,
                              child: _svg('search', 15, 15),
                            ),
                            Positioned(
                              left: _M.fortyThree,
                              top: _M.zero,
                              right: _M.sixteen,
                              bottom: _M.zero,
                              child: TextField(
                                controller: searchController,
                                onChanged: onSearch,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  hintText: 'Search VIN, tech, job ticket...',
                                  hintStyle: Fx.text(
                                    13,
                                    16,
                                    FontWeight.w400,
                                    0,
                                    color: Fx.muted,
                                  ),
                                ),
                                style: Fx.text(
                                  13,
                                  16,
                                  FontWeight.w400,
                                  0,
                                  color: Fx.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 323,
                      top: _M.one,
                      width: 145.39,
                      height: _M.thirtyTwo,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onProfileTap ?? () => _showUserMenu(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Positioned(
                                left: _M.eight,
                                top: 0.25,
                                width: 93.39,
                                height: 31.5,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: _M.zero,
                                      top: -1,
                                      child: _t(
                                        effectiveUser,
                                        93.39,
                                        _M.eighteen,
                                        Fx.text(
                                          14,
                                          17.5,
                                          FontWeight.w700,
                                          -0.14,
                                          color: Fx.ink,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: _M.zero,
                                      top: 17.5,
                                      width: 93.39,
                                      height: _M.fourteen,
                                      child: Transform.translate(
                                        offset: const Offset(0, -1),
                                        child: Text(
                                          effectiveRole,
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.clip,
                                          textAlign: TextAlign.right,
                                          style: Fx.text(
                                            11,
                                            14,
                                            FontWeight.w600,
                                            0.44,
                                            color: Fx.muted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 113.39,
                                top: _M.zero,
                                width: _M.thirtyTwo,
                                height: _M.thirtyTwo,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF006C49),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: _svg('avatarUser', 12, 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Color(0xFF10B981)),
              title: const Text(
                'Workshop Settings & Profile',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Workshop profile, operating hours, and dispatch preferences'),
              onTap: () {
                Navigator.pop(ctx);
                onNavSelected?.call(4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Workshop Staff Management'),
              subtitle: const Text('View roster and manage technicians'),
              onTap: () {
                Navigator.pop(ctx);
                onNavSelected?.call(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Inspection Templates'),
              subtitle: const Text('Service checklists and template builder'),
              onTap: () {
                Navigator.pop(ctx);
                onNavSelected?.call(3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Toggle Language (EN / AR)'),
              onTap: () {
                Navigator.pop(ctx);
                onToggleLocale?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onSignOut?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Figma `1:510` icon rail 96 x 800.
  Widget _rail(BuildContext context) {
    return Container(
      width: _M.ninetySix,
      height: _M.eightHundred,
      color: Fx.white,
      child: Stack(
        children: [
          Positioned(
            left: _M.twentyFour,
            top: _M.thirtyTwo,
            width: _M.fortyEight,
            height: _M.fortyEight,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Color(0x0B000000),
                    blurRadius: 40,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _svg('logo', 21.67, 21.67),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 112,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 0,
              icon: 'dash',
              iconWidth: 18,
              iconHeight: 18,
              isActive: selectedNavIndex == 0,
              tooltip: 'Overview Dashboard',
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 176,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 1,
              icon: 'jobs',
              iconWidth: 18,
              iconHeight: 20,
              isActive: selectedNavIndex == 1,
              tooltip: 'Live Job Queue',
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 240,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 2,
              icon: 'staff',
              iconWidth: 18,
              iconHeight: 18,
              isActive: selectedNavIndex == 2,
              tooltip: 'Staff Management',
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 304,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 3,
              icon: 'templates',
              iconWidth: 18,
              iconHeight: 18,
              isActive: selectedNavIndex == 3,
              tooltip: 'Inspection Templates',
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 368,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 4,
              icon: 'navset',
              iconWidth: 18,
              iconHeight: 18,
              isActive: selectedNavIndex == 4,
              tooltip: 'Workshop Settings & Profile',
            ),
          ),
          Positioned(
            left: _M.twentyEight,
            top: 728,
            width: _M.forty,
            height: _M.forty,
            child: Material(
              color: Colors.transparent,
              child: Tooltip(
                message: 'Profile & Workshop Settings',
                child: InkWell(
                  onTap: onSignOut ?? () => _showUserMenu(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Fx.container,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _svg('setbot', 18.33, 17.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required int index,
    required String icon,
    required double iconWidth,
    required double iconHeight,
    required bool isActive,
    String? tooltip,
  }) {
    Widget iconWidget;
    if (icon == 'staff') {
      iconWidget = Icon(
        Icons.groups_outlined,
        size: 20,
        color: isActive ? Colors.white : Fx.muted,
      );
    } else if (icon == 'templates') {
      iconWidget = Icon(
        Icons.dashboard_customize_outlined,
        size: 20,
        color: isActive ? Colors.white : Fx.muted,
      );
    } else {
      iconWidget = _svg(icon, iconWidth, iconHeight);
    }

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: () => onNavSelected?.call(index),
          borderRadius: const BorderRadius.all(Radius.circular(_M.sixteen)),
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? Fx.emerald : Fx.container,
              borderRadius: const BorderRadius.all(Radius.circular(_M.sixteen)),
              boxShadow: isActive ? Fx.ctaShadow : null,
            ),
            alignment: Alignment.center,
            child: iconWidget,
          ),
        ),
      ),
    );
  }

  Widget _t(String data, double width, double height, TextStyle style) {
    final size = style.fontSize ?? 14;
    final dy = size == 11
        ? -1.0
        : size == 32
        ? 1.0
        : 0.0;
    final text = Text(
      data,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      style: style,
    );
    return SizedBox(
      width: width,
      height: height,
      child: dy == 0
          ? text
          : Transform.translate(offset: Offset(0, dy), child: text),
    );
  }

  Widget _tNum(String data, double width) {
    return SizedBox(
      width: width,
      height: _M.thirtyTwo,
      child: Transform.translate(
        offset: const Offset(1, 2.5),
        child: Text(
          data,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: Fx.text(32, 32, FontWeight.w800, -1.6, color: Fx.ink),
        ),
      ),
    );
  }

  Widget _tMulti(String data, double width, int lines, TextStyle style) {
    final size = style.fontSize ?? 14;
    final dy = size == 11
        ? -1.0
        : size == 32
        ? 1.0
        : 0.0;
    final height = ((style.height ?? 1) * size * lines).roundToDouble();
    final text = Text(
      data,
      maxLines: lines,
      softWrap: true,
      overflow: TextOverflow.clip,
      style: style,
    );
    return SizedBox(
      width: width,
      height: height,
      child: dy == 0
          ? text
          : Transform.translate(offset: Offset(0, dy), child: text),
    );
  }

  Widget _svg(String key, double width, double height) {
    final raw = _svgString(key);
    if (raw.isEmpty) {
      return SizedBox(width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.string(raw, width: width, height: height),
    );
  }
}

// Spacing constants (clean layout numbers)
abstract final class _M {
  static const double zero = 0;
  static const double one = 1;
  static const double four = 4;
  static const double six = 6;
  static const double eight = 8;
  static const double nine = 9;
  static const double ten = 10;
  static const double eleven = 11;
  static const double twelve = 12;
  static const double fourteen = 14;
  static const double fifteen = 15;
  static const double sixteen = 16;
  static const double seventeen = 17;
  static const double eighteen = 18;
  static const double twenty = 20;
  static const double twentyTwo = 22;
  static const double twentyThree = 23;
  static const double twentyFour = 24;
  static const double twentySix = 26;
  static const double twentyEight = 28;
  static const double thirtyTwo = 32;
  static const double thirtyFive = 35;
  static const double thirtyEight = 38;
  static const double forty = 40;
  static const double fortyOne = 41;
  static const double fortyTwo = 42;
  static const double fortyThree = 43;
  static const double fortyFour = 44;
  static const double fortySix = 46;
  static const double fortyEight = 48;
  static const double fiftySix = 56;
  static const double sixty = 60;
  static const double sixtyOne = 61;
  static const double sixtyFour = 64;
  static const double seventyFive = 75;
  static const double seventySix = 76;
  static const double eighty = 80;
  static const double eightyFour = 84;
  static const double eightyEight = 88;
  static const double ninetySix = 96;
  static const double oneHundred = 100;
  static const double oneSixty = 160;
  static const double twoTwenty = 220;
  static const double threeTwenty = 320;
  static const double fourSeventySix = 476;
  static const double fiveSixtySix = 566;
  static const double fiveSixtyEight = 568;
  static const double eightHundred = 800;
}
