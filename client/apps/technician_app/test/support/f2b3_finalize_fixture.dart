import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'f2b_views.dart';

/// F2-B.3 Part 2 — Level 1 exact-structure fixture for Figma screen 14
/// "Finalize & Approval (Swipe)" (node `1:8809`, 390 x 1231.25).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/f2b-nodes/14-finalize.txt`) using only the shared
/// kits (`Fx*` + `F2b*` primitives/tokens) plus the Figma export rasters
/// (decoded by the capture test via `loadFigmaTestImage`; never in `lib/`).
///
/// It deliberately does NOT reuse the production `FinalizeView`: that view
/// is product-anchored (neutral silhouette, initials disc, real counts,
/// approved limitation copy) while this fixture renders the Figma nodes
/// verbatim (visual order header / photo / stats / technician, avatar and
/// vehicle rasters, `Bay #04`, `104` / `2`, invented disclaimer copy).
///
/// Figma-exact values that have no kit token are inlined here (test-only)
/// and listed as kit gaps in `docs/ui/figma/fidelity/f2b3/finalize/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change.
class F2b3FinalizeFixture extends StatelessWidget {
  const F2b3FinalizeFixture({
    required this.avatar,
    required this.vehicle,
    super.key,
  });

  /// Decoded `assets/images/rendered_png/...-1_8859@2x.png` (70 x 80 px).
  final ui.Image avatar;

  /// Decoded `assets/images/rendered_png/...-1_8874@2x.png` (604 x 288 px).
  final ui.Image vehicle;

  static const double width = 390;
  static const double height = 1231.5;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Fx.white,
        child: _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final fixture = context
        .findAncestorWidgetOfExactType<F2b3FinalizeFixture>()!;
    return Stack(
      children: [
        // 1:8810 Main, pad top 64; 1:8811 Container 390x1167.25, pad bottom 128.
        Positioned(
          top: 64,
          child: SizedBox(
            width: 390,
            height: 1167.25,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Intro(),
                _SummaryMargin(avatar: fixture.avatar, vehicle: fixture.vehicle),
                const _FlaggedMargin(),
                const _DisclaimerMargin(),
                const SizedBox(width: 390, height: 128),
              ],
            ),
          ),
        ),
        // 1:8910 swipe dock @0,1126.63 390x104.
        const Positioned(
          top: 1126.63,
          child: _Dock(),
        ),
        // 1:8920 header @0,0 390x64.
        const Positioned(
          top: 0,
          child: _Header(),
        ),
      ],
    );
  }
}

// 1:8812 intro @0,64 390x126 VERTICAL gap 4 pad 12,20,8,20.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 390,
      height: 126,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1:8813 step pill 180.38x22 r9999 #F4F3F8 pad 4,12,4,12 gap 6.
            // Kit F2bStatusPill pads 10 (not 12) and has no 12.5 icon slot,
            // so the pill is built exact from primitives.
            _StepPill(),
            SizedBox(width: 350, height: 4),
            // 1:8818 heading 350x36 pad top 4; 1:8819 text 350x32.
            SizedBox(
              width: 350,
              height: 36,
              child: Padding(
                padding: EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 350,
                  height: 32,
                  child: Text(
                    F2bFigmaStrings.reviewFinalizeTitle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
                      fontSize: 26,
                      height: 32 / 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.65,
                      color: Fx.ink,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 350, height: 4),
            // 1:8820 body 350x40; 1:8821 text 14/500 lh 20 ls -0.07.
            SizedBox(
              width: 350,
              height: 40,
              child: Text(
                'Review verified points and sign off to dispatch fleet\n'
                'records.',
                maxLines: 2,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontFamily: Fx.fontFamily,
                  fontFamilyFallback: Fx.fontFallback,
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.07,
                  color: Fx.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.38,
      height: 22,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 12.5,
            height: 12.5,
            child: Center(
              child: FxIcon(id: '1_8815', size: 12.5, color: Fx.deepGreen),
            ),
          ),
          SizedBox(width: 6, height: 14),
          SizedBox(
            width: 137.88,
            height: 14,
            child: Text(
              'INSPECTION STEP 4 OF 4',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: Fx.fontFamily,
                fontFamilyFallback: Fx.fontFallback,
                fontSize: 11,
                height: 14 / 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.275,
                color: Fx.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 1:8822 summary margin @0,190 390x574 pad 16,20,0,20.
class _SummaryMargin extends StatelessWidget {
  const _SummaryMargin({required this.avatar, required this.vehicle});

  final ui.Image avatar;
  final ui.Image vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: 574,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: _SummaryCard(avatar: avatar, vehicle: vehicle),
      ),
    );
  }
}

// 1:8823 card @20,206 350x558 r32 #FFFFFF + two DROP_SHADOWs
// (10 0,8 s-6 and 25 0,20 s-5, both black 10%). Kit F2b.summaryShadow uses
// 5.1 % / 7.8 % alphas, so the shadows are inlined exact here.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.avatar, required this.vehicle});

  final ui.Image avatar;
  final ui.Image vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('f2b3-summary'),
      width: 350,
      height: 558,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            spreadRadius: -6,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 25,
            spreadRadius: -5,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VehicleHeader(),
            const SizedBox(width: 302, height: 20),
            _PhotoBlock(image: vehicle),
            const SizedBox(width: 302, height: 24),
            const _StatsRow(),
            const SizedBox(width: 302, height: 24),
            _TechnicianRow(avatar: avatar),
            const SizedBox(width: 302, height: 24),
          ],
        ),
      ),
    );
  }
}

// 1:8824 header @44,230 302x68 HORIZONTAL gap 3.62 pad bottom 20.
// Content 302x48: left block 224.55 (48 circle + 12 + 164.55 texts),
// bay chip 73.83x22 vertically centred (+13).
class _VehicleHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 302,
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 224.55,
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1:8826 car circle 48x48 r9999 #F4F3F8; icon 19.5x17.33.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: _CarCircle(),
                ),
                SizedBox(width: 12, height: 48),
                SizedBox(
                  width: 164.55,
                  height: 40,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 164.55,
                        height: 22,
                        child: Text(
                          '2024 Ford Transit 350',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: Fx.fontFamily,
                            fontFamilyFallback: Fx.fontFallback,
                            fontSize: 16,
                            height: 22 / 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.16,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 162.17,
                        height: 18,
                        child: Text(
                          'VIN \u2022 1FTBR1Y85RKB92104',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: Fx.fontFamily,
                            fontFamilyFallback: Fx.fontFallback,
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                            color: Fx.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 3.62, height: 48),
          // 1:8834 bay chip 73.83x22 r9999 #E1DEEC pad 4,12,4,12.
          _BayChip(),
        ],
      ),
    );
  }
}

class _CarCircle extends StatelessWidget {
  const _CarCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Fx.container,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 19.5,
        height: 17.33,
        child: Center(
          child: FxIcon(id: '1_8828', size: 19.5, color: Fx.deepGreen),
        ),
      ),
    );
  }
}

class _BayChip extends StatelessWidget {
  const _BayChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 73.83,
      height: 22,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: const BoxDecoration(
        color: F2b.plateBackground,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: const SizedBox(
        width: 49.83,
        height: 14,
        child: Text(
          'Bay #04',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontFamily: Fx.fontFamily,
            fontFamilyFallback: Fx.fontFallback,
            fontSize: 11,
            height: 14 / 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.44,
            color: Fx.iconGrey,
          ),
        ),
      ),
    );
  }
}

// 1:8873 photo @44,298 302x144 (visual order: photo sits between the
// vehicle header and the stat tiles). 1:8874 raster 302x144; chip
// 1:8875 @52,412 155.39x22 rel photo (8,114).
class _PhotoBlock extends StatelessWidget {
  const _PhotoBlock({required this.image});

  final ui.Image image;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 302,
      height: 144,
      child: Stack(
        children: [
          RawImage(image: image, scale: 2),
          const Positioned(
            left: 8,
            top: 114,
            child: _OdometerChip(),
          ),
        ],
      ),
    );
  }
}

// Odometer chip: fill #FFFFFFE5 + DROP_SHADOW(2 0,1 a5 %) +
// BACKGROUND_BLUR(24), HORIZONTAL gap 6 pad 4,10,4,10.
class _OdometerChip extends StatelessWidget {
  const _OdometerChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155.39,
      height: 22,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(9999)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(9999)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: Fx.whiteE5,
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1:8876 dot 8x8 r9999 #10B981, centred in the 14 content row.
                SizedBox(
                  width: 8,
                  height: 14,
                  child: Center(
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Fx.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6, height: 14),
                SizedBox(
                  width: 121.39,
                  height: 14,
                  child: Text(
                    'Odometer: 14,820 mi',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.44,
                      color: Fx.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 1:8836 stats @44,466 302x152 HORIZONTAL gap 12: two 145x152 tiles.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 302,
      height: 152,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1:8837 left tile 145x152 #F4F3F8 pad 16.
          _StatTile(
            iconId: '1_8841',
            iconSize: 15,
            iconBoxWidth: 15,
            iconBoxHeight: 15,
            iconBackground: Fx.selectedTint,
            iconColor: F2b.pineDeep,
            count: '104',
            countWidth: 37.19,
            lines: ['Checks', 'Completed'],
            lineWidths: [47.14, 71.44],
          ),
          SizedBox(width: 12, height: 152),
          // 1:8847 right tile 145x152 #F4F3F8 pad 16 gap 24.
          _StatTile(
            iconId: '1_8851',
            iconSize: 12.75,
            iconBoxWidth: 11.25,
            iconBoxHeight: 12.75,
            iconBackground: F2b.rosePale,
            iconColor: F2b.redDeep,
            count: '2',
            countWidth: 113,
            tileGap: 24,
            countBottomPad: 4,
            lines: ['Defects Found'],
            lineWidths: [91.41],
          ),
        ],
      ),
    );
  }
}

// Stat tile 145x152: icon margin 32x44 (pad bottom 12), then the text block.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.iconId,
    required this.iconSize,
    required this.iconBoxWidth,
    required this.iconBoxHeight,
    required this.iconBackground,
    required this.iconColor,
    required this.count,
    required this.countWidth,
    required this.lines,
    required this.lineWidths,
    this.tileGap = 0,
    this.countBottomPad = 0,
  });

  final String iconId;
  final double iconSize;
  final double iconBoxWidth;
  final double iconBoxHeight;
  final Color iconBackground;
  final Color iconColor;
  final String count;
  final double countWidth;
  final List<String> lines;
  final List<double> lineWidths;
  final double tileGap;
  final double countBottomPad;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      SizedBox(
        width: 113,
        height: 44,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: iconBoxWidth,
                height: iconBoxHeight,
                child: Center(
                  child: FxIcon(id: iconId, size: iconSize, color: iconColor),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
    if (tileGap > 0) {
      children.add(SizedBox(width: 113, height: tileGap));
    }
    children.add(
      SizedBox(
        width: 113,
        height: 28,
        child: Text(
          count,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            fontFamily: Fx.fontFamily,
            fontFamilyFallback: Fx.fontFallback,
            fontSize: 22,
            height: 28 / 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.55,
            color: Fx.ink,
          ),
        ),
      ),
    );
    // Left tile: gaps 2, 6 + 4 bottom slack (76 block).
    // Right tile: gap 2 + 4 bottom pad (52 block).
    for (var i = 0; i < lines.length; i++) {
      children.add(SizedBox(width: 113, height: i == 0 ? 2 : 6));
      children.add(
        SizedBox(
          width: lineWidths[i],
          height: 18,
          child: Text(
            lines[i],
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              fontFamily: Fx.fontFamily,
              fontFamilyFallback: Fx.fontFallback,
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              color: Fx.muted,
            ),
          ),
        ),
      );
    }
    children.add(SizedBox(width: 113, height: countBottomPad == 0 ? 4 : countBottomPad));
    return Container(
      width: 145,
      height: 152,
      color: Fx.container,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// 1:8856 technician @44,642 302x98 #F4F3F8 HORIZONTAL pad 16:
// left 218.91x66 (avatar 34.94x40 + 12 + texts) + right 51.09x62.
class _TechnicianRow extends StatelessWidget {
  const _TechnicianRow({required this.avatar});

  final ui.Image avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 302,
      height: 98,
      color: Fx.container,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 218.91,
            height: 66,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1:8858 avatar @60,671 34.94x40 r9999 (rendered raster
                // 70x80 drawn 1:1 via RawImage scale 2, clipped 0.06 px).
                SizedBox(
                  width: 34.94,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(9999),
                    ),
                    child: Center(
                      child: RawImage(image: avatar, scale: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 12, height: 66),
                // 1:8860 texts 171.97x66: name row 18 + 2 + 18 + 6 + 18 + 4.
                const SizedBox(
                  width: 171.97,
                  height: 66,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 170.64,
                        height: 18,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 93.39,
                              height: 18,
                              child: Text(
                                'Marcus Vance',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontFamily: Fx.fontFamily,
                                  fontFamilyFallback: Fx.fontFallback,
                                  fontSize: 14,
                                  height: 18 / 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.14,
                                  color: Fx.ink,
                                ),
                              ),
                            ),
                            SizedBox(width: 6, height: 18),
                            SizedBox(
                              width: 14.67,
                              height: 14,
                              child: Center(
                                child: FxIcon(
                                  id: '1_8865',
                                  size: 14.67,
                                  color: Fx.deepGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 171.97, height: 2),
                      SizedBox(
                        width: 152.13,
                        height: 18,
                        child: Text(
                          'Lead Fleet Specialist \u2022 ID',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: Fx.fontFamily,
                            fontFamilyFallback: Fx.fontFallback,
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                            color: Fx.muted,
                          ),
                        ),
                      ),
                      SizedBox(width: 171.97, height: 6),
                      SizedBox(
                        width: 42.59,
                        height: 18,
                        child: Text(
                          '#8842',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: Fx.fontFamily,
                            fontFamilyFallback: Fx.fontFallback,
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                            color: Fx.muted,
                          ),
                        ),
                      ),
                      SizedBox(width: 171.97, height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 1:8868 right column 51.09x62: 14 + 3.5 + 16 + 8 + 16 + 4.5.
          const SizedBox(
            width: 51.09,
            height: 62,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 51.09,
                  height: 14,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Today',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.44,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 51.09, height: 3.5),
                SizedBox(
                  width: 51.09,
                  height: 16,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '14:48',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.24,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 51.09, height: 8),
                SizedBox(
                  width: 51.09,
                  height: 16,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'PST',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.24,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 51.09, height: 4.5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 1:8879 flagged margin @0,764 390x214 pad 16,20,0,20.
class _FlaggedMargin extends StatelessWidget {
  const _FlaggedMargin();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 390,
      height: 214,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: _FlaggedCard(),
      ),
    );
  }
}

// 1:8880 card @20,780 350x198 r32 #FFFFFF + DROP_SHADOW(2 0,1 a5 %)
// pad 20 gap 12. Kit Fx.cardShadow is a different two-layer shadow,
// so the single exact layer is inlined here.
class _FlaggedCard extends StatelessWidget {
  const _FlaggedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 198,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1:8881 header 310x22 HORIZONTAL gap 14.05.
          SizedBox(
            width: 310,
            height: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 184.28,
                  height: 22,
                  child: Text(
                    F2bFigmaStrings.flaggedSummary,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.16,
                      color: Fx.ink,
                    ),
                  ),
                ),
                SizedBox(width: 14.05, height: 22),
                SizedBox(
                  width: 111.67,
                  height: 22,
                  child: Center(
                    child: SizedBox(
                      width: 111.67,
                      height: 14,
                      child: Text(
                        'Requires Follow-up',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontFamily: Fx.fontFamily,
                          fontFamilyFallback: Fx.fontFallback,
                          fontSize: 11,
                          height: 14 / 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: Fx.dangerRed,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 310, height: 12),
          // 1:8886 rows 310x124 VERTICAL gap 12.
          _FlagRow(
            iconId: '1_8891',
            title: 'Front Left Tire Tread Depth',
            body: 'Measured at 3/32 in. Marginal wear pattern\n'
                'documented.',
          ),
          SizedBox(width: 310, height: 12),
          _FlagRow(
            iconId: '1_8901',
            title: 'Rear Cargo Door Latch',
            body: 'Minor resistance observed on secondary\n'
                'strike latch.',
          ),
        ],
      ),
    );
  }
}

// Flag row 310x56 HORIZONTAL gap 12: icon margin 24x26 (pad top 2,
// 24 circle #FFDAD6) + text column 274x56 (title 20 + body 36).
class _FlagRow extends StatelessWidget {
  const _FlagRow({
    required this.iconId,
    required this.title,
    required this.body,
  });

  final String iconId;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 26,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: F2b.rosePale,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 12.83,
                    height: 11.08,
                    child: Center(
                      child: FxIcon(
                        id: iconId,
                        size: 12.83,
                        color: F2b.redDeep,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12, height: 56),
          SizedBox(
            width: 274,
            height: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 274,
                  height: 20,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.07,
                      color: Fx.ink,
                    ),
                  ),
                ),
                SizedBox(
                  width: 274,
                  height: 36,
                  child: Text(
                    body,
                    maxLines: 2,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                      color: Fx.muted,
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
}

// 1:8907 disclaimer margin @0,978 390x125.25 pad 19.25,28,0,28;
// 1:8908 text box 334x106 centred; 1:8909 text 322.36x106 13/400
// lh 21.13 centred.
class _DisclaimerMargin extends StatelessWidget {
  const _DisclaimerMargin();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 390,
      height: 125.25,
      child: Padding(
        padding: EdgeInsets.fromLTRB(28, 19.25, 28, 0),
        child: SizedBox(
          width: 334,
          height: 106,
          child: Text(
            'By completing this inspection, technician confirms\n'
            'vehicle condition complies with fleet standards.\n'
            'Digital signature and GPS coordinates will be\n'
            'permanently appended to Fleet Ledger #2024-FLT-\n'
            '0982.',
            maxLines: 5,
            softWrap: false,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: Fx.fontFamily,
              fontFamilyFallback: Fx.fontFallback,
              fontSize: 13,
              height: 21.13 / 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              color: Fx.muted,
            ),
          ),
        ),
      ),
    );
  }
}

// 1:8910 dock @0,1126.63 390x104 fill #FFFFFFF2 + BACKGROUND_BLUR(48)
// pad 20. 1:8911 is a same-size #FFFFFF01 rect carrying the dock drop
// shadow DROP_SHADOW(50 0,25 s-12 a25 %); the 1 % fill is invisible so
// the shadow lives on the dock container itself.
class _Dock extends StatelessWidget {
  const _Dock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: 104,
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 50,
            spreadRadius: -12,
            offset: Offset(0, 25),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: _SlideTrack(),
          ),
        ),
      ),
    );
  }
}

// 1:8912 track @20,1146.63 350x64 r9999 #E9E7ED pad 6 HORIZONTAL.
// Kit F2bSlideToConfirm centres the label differently and uses the kit
// soft shadow on the thumb; the track, label slot and thumb shadows are
// built exact from primitives. 1:8913 reserves 40 left (thumb travel);
// the label box 189.36x18 sits at rel track (100.32, 23).
class _SlideTrack extends StatelessWidget {
  const _SlideTrack();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('f2b3-slide'),
      width: 350,
      height: 64,
      decoration: const BoxDecoration(
        color: Fx.surfaceHighest,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: Stack(
        children: [
          // 1:8916 thumb @26,1152.63 52x52 rel track (6,6) r9999 #10B981.
          // 1:8917 overlay carries (6 0,4 s-4 a10 %) + (15 0,10 s-3 a10 %);
          // its #FFFFFF01 fill shifts the colour by < 1/255, so only the
          // two exact shadow layers are reproduced.
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Fx.emerald,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    spreadRadius: -4,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 15,
                    spreadRadius: -3,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 16.33,
                height: 14,
                child: Center(
                  child: FxIcon(id: '1_8919', size: 16.33, color: Fx.white),
                ),
              ),
            ),
          ),
          // 1:8914 label @120.32,1169.63 189.36x18 rel track (100.32,23).
          const Positioned(
            left: 100.32,
            top: 23,
            child: SizedBox(
              width: 189.36,
              height: 18,
              child: Text(
                F2bFigmaStrings.slideToFinalize,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontFamily: Fx.fontFamily,
                  fontFamilyFallback: Fx.fontFallback,
                  fontSize: 14,
                  height: 18 / 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                  color: Fx.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 1:8920 header @0,0 390x64 fill #FFFFFFCC + DROP_SHADOW(8 0,1 a3 %)
// + BACKGROUND_BLUR(48). Kit Fx.headerShadow is 6.3 % (not 3 %), and kit
// FxHeader uses a Material back glyph with -0.27 tracking (Figma needs
// vector 1_8925 and -0.45), so the header is built exact from primitives.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('f2b3-header'),
      width: 390,
      height: 64,
      decoration: const BoxDecoration(
        color: Fx.whiteCC,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 223.53,
                  height: 44,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1:8923 back 44x44; icon slot 11.77x20.
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: SizedBox(
                            width: 11.77,
                            height: 20,
                            child: Center(
                              child: FxIcon(
                                id: '1_8925',
                                size: 20,
                                color: Fx.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4, height: 44),
                      // 1:8926 heading 175.53x24 pad left 4.
                      SizedBox(
                        width: 175.53,
                        height: 24,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: SizedBox(
                            width: 171.53,
                            height: 24,
                            child: Text(
                              'Diagnostic Checklist',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontFamily: Fx.fontFamily,
                                fontFamilyFallback: Fx.fontFallback,
                                fontSize: 18,
                                height: 24 / 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.45,
                                color: Fx.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 102.47, height: 44),
                // 1:8928 avatar 32x32 r9999 #006C49; icon 12x12.
                SizedBox(
                  width: 32,
                  height: 32,
                  child: _HeaderAvatar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Fx.deepGreen,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const FxIcon(id: '1_8930', size: 12, color: Fx.white),
    );
  }
}
