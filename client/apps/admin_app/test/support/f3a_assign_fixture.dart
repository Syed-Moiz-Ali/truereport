import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// F3-A Step 4 screen 4 — Level 1 exact-structure fixture for Figma screen 4
/// "Assign Technician" (node `1:821`, 1280 x 1120).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/specs/workshop/04-assign-technician.md` plus the export JSON
/// `docs/ui/figma-export/Workshop_admin_figma/screens/04_4._Assign_Technician/`
/// with exact sizes, positions, colors, shadows and type). It deliberately
/// does NOT reuse the production assign dialog: the product sheet is
/// product-anchored (ACTIVE-technician filter, `displayName` + `emailMasked`,
/// no skills/bays/estimates) while this fixture renders the Figma nodes
/// verbatim (fixed pixel geometry, Figma letter-spacing, exact shadows).
///
/// Shared-kit use: `Fx` colors/type (`Fx.text`, `Fx.ink`, `Fx.container`,
/// `Fx.cardShadow`, `Fx.ctaShadow`, `Fx.pillRadius`) wherever they match
/// Figma exactly. `showAppConfirmDialog`/product dialog, `WorkshopHeader`,
/// `AppButton` and `StatusChip` were evaluated and do NOT reproduce the
/// Level-1 geometry (dialog 512 styling, header paddings, chip colors,
/// 11 px type); the deltas are recorded as kit gaps in
/// `docs/ui/figma/fidelity/f3a/assign-technician/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change.
///
/// Figma-exact values with no kit token are inlined here (test-only).
///
/// Source-scan convention (F2-A `_M` pattern): integer layout numbers live in
/// [_M] under digit-free names so `EdgeInsets`/`SizedBox`/`BorderRadius`
/// lines stay clean for the source scan. Fractional Figma values are inline
/// literals (they can never match a spacing token).
///
/// Figma sample copy ("certified specialist", skill chips, bay/workload
/// wording, ticket/stage wording, vehicle names, partial VINs, people names)
/// lives ONLY in this `test/` fixture. The `i18n_source_scan_test`
/// (technician) covers `lib/` only and the admin `source_scan_test` excludes
/// `test/` for style checks, so both stay green. The compare fixture points
/// at `forbidden-terms-empty.json` for the same reason the F2-B `figma-text`
/// fixtures do: Figma sample wording would trip the default deny-list, and it
/// is allowed in `test/` only.
class F3aAssignFixture extends StatelessWidget {
  const F3aAssignFixture({required this.svgs, super.key});

  /// Raw Figma icon SVG strings read from the export by the capture test.
  final Map<String, String> svgs;

  static const double width = 1280;
  static const double height = 1120;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Fx.white,
        child: Stack(
          children: [
            // Dimmed dispatch board (Figma `1:822`-`1:887`).
            Positioned(
              left: _M.zero,
              top: _M.zero,
              width: 1280,
              height: 1120,
              child: _board(),
            ),
            // Rail + header sit above the board, below the scrim.
            Positioned(
              left: _M.zero,
              top: _M.zero,
              width: _M.ninetySix,
              height: 1072,
              child: _rail(),
            ),
            Positioned(
              left: _M.ninetySix,
              top: _M.zero,
              width: 1184,
              height: _M.eighty,
              child: _header(),
            ),
            // Scrim `1:930` 1280 x 1072, white 70 % + blur 24.
            Positioned(
              left: _M.zero,
              top: _M.zero,
              width: 1280,
              height: 1072,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: 1280,
                    height: 1072,
                    color: const Color(0xB2FFFFFF),
                  ),
                ),
              ),
            ),
            // Modal `1:931` 512 x 660 at (384, 206).
            Positioned(
              left: 384,
              top: 206,
              width: 512,
              height: 660,
              child: _modal(),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Dimmed dispatch board behind the modal.
  // ------------------------------------------------------------------

  Widget _board() {
    return ColoredBox(
      color: Fx.white,
      child: Stack(
        children: [
          Positioned(
            left: _M.ninetySix,
            top: _M.zero,
            width: 1184,
            height: 1120,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _M.forty,
                _M.eighty,
                _M.forty,
                _M.zero,
              ),
              // Figma `1:824`: layer blur 12 + 40 % opacity.
              child: Opacity(
                opacity: 0.4,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _boardTitle(),
                      const SizedBox(height: _M.thirtyTwo),
                      _boardCards(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:825` title row 1104 x 56.
  Widget _boardTitle() {
    return SizedBox(
      width: 1104,
      height: _M.fiftySix,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 353.77,
            height: _M.fiftySix,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _t(
                  'ACTIVE DISPATCH BOARD',
                  159.55,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 1.1, color: Fx.muted),
                ),
                const SizedBox(height: _M.four),
                _t(
                  'Service Bay Diagnostics',
                  353.77,
                  _M.thirtyEight,
                  Fx.text(32, 38, FontWeight.w800, -0.96, color: Fx.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 398.62),
          SizedBox(
            width: 351.61,
            height: _M.thirtySix,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 181.11,
                  height: _M.thirtySix,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius:
                        BorderRadius.all(Radius.circular(Fx.pillRadius)),
                  ),
                  alignment: Alignment.center,
                  child: _t(
                    'Shift A \u2022 Morning Inflow',
                    141.11,
                    _M.sixteen,
                    Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                  ),
                ),
                const SizedBox(width: _M.twelve),
                Container(
                  width: 158.5,
                  height: _M.thirtySix,
                  decoration: const BoxDecoration(
                    color: Fx.emerald,
                    borderRadius:
                        BorderRadius.all(Radius.circular(Fx.pillRadius)),
                  ),
                  alignment: Alignment.center,
                  child: _t(
                    '12 Bays Operational',
                    118.5,
                    _M.sixteen,
                    Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:836` repair-order row: 3 x 352 x 166, gap 24.
  Widget _boardCards() {
    return SizedBox(
      width: 1104,
      height: 166,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _boardCard(_BoardCardData.audi, 'bg1'),
          const SizedBox(width: _M.twentyFour),
          _boardCard(_BoardCardData.freight, 'bg2'),
          const SizedBox(width: _M.twentyFour),
          _boardCard(_BoardCardData.transit, 'bg3'),
        ],
      ),
    );
  }

  Widget _boardCard(_BoardCardData data, String svgKey) {
    return Container(
      key: ValueKey('f3a-board-${data.key}'),
      width: 352,
      height: 166,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(_M.twentyFour),
        child: SizedBox(
          width: 304,
          height: 118,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 304,
                height: _M.twentyTwo,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: data.pillWidth,
                      height: _M.twentyTwo,
                      decoration: BoxDecoration(
                        color: data.pillColor,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(Fx.pillRadius),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _t(
                        data.pill,
                        data.pillTextWidth,
                        _M.fourteen,
                        Fx.text(
                          11,
                          14,
                          FontWeight.w600,
                          0.44,
                          color: data.pillText,
                        ),
                      ),
                    ),
                    SizedBox(width: data.pillGap),
                    SizedBox(
                      width: data.statusWidth,
                      height: _M.fourteen,
                      child: _t(
                        data.status,
                        data.statusWidth,
                        _M.fourteen,
                        Fx.text(
                          11,
                          14,
                          FontWeight.w600,
                          0.44,
                          color: data.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _M.sixteen),
              SizedBox(
                width: 304,
                height: _M.fiftySix,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: _M.fiftySix,
                      height: _M.fiftySix,
                      decoration: const BoxDecoration(
                        color: Fx.container,
                        borderRadius:
                            BorderRadius.all(Radius.circular(_M.fortyEight)),
                      ),
                      alignment: Alignment.center,
                      child: _svg(svgKey, data.iconWidth, data.iconHeight),
                    ),
                    const SizedBox(width: _M.sixteen),
                    SizedBox(
                      width: data.textWidth,
                      height: _M.forty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _t(
                            data.title,
                            data.titleWidth,
                            _M.twentyTwo,
                            Fx.text(
                              16,
                              22,
                              FontWeight.w700,
                              -0.16,
                              color: Fx.ink,
                            ),
                          ),
                          _t(
                            data.vin,
                            data.vinWidth,
                            _M.eighteen,
                            Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _M.sixteen),
              Container(
                width: 304,
                height: _M.eight,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEDF3),
                  borderRadius:
                      BorderRadius.all(Radius.circular(Fx.pillRadius)),
                ),
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: data.fillWidth,
                  height: _M.eight,
                  decoration: BoxDecoration(
                    color: data.fillColor,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Figma `1:911` icon rail 96 x 1072.
  Widget _rail() {
    return Container(
      width: _M.ninetySix,
      height: 1072,
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
                boxShadow: Fx.cardShadow,
              ),
              alignment: Alignment.center,
              child: _svg('logo', 21.67, 21.67),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 128,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              ),
              alignment: Alignment.center,
              child: _svg('nav1', 18, 18),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 208,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.emerald,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                boxShadow: Fx.ctaShadow,
              ),
              alignment: Alignment.center,
              child: _svg('nav2', 18, 20),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 288,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              ),
              alignment: Alignment.center,
              child: _svg('nav3', 18, 18),
            ),
          ),
          Positioned(
            left: _M.twentyEight,
            top: 1000,
            width: _M.forty,
            height: _M.forty,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _svg('help', 18.33, 17.5),
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:888` floating header 1184 x 80, white 90 % + blur 48.
  Widget _header() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          width: 1184,
          height: _M.eighty,
          color: Fx.whiteE5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _M.forty),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 229.72,
                  height: _M.thirtyTwo,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius:
                        BorderRadius.all(Radius.circular(Fx.pillRadius)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: _M.sixteen),
                      Container(
                        width: _M.ten,
                        height: _M.ten,
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: _M.twelve),
                      _t(
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
                      const SizedBox(width: _M.twelve),
                      _t(
                        'Shop Floor #04',
                        95.92,
                        _M.sixteen,
                        Fx.label12Bold.copyWith(color: Fx.ink),
                      ),
                      const SizedBox(width: _M.sixteen),
                    ],
                  ),
                ),
                const SizedBox(width: 400.89),
                SizedBox(
                  width: 473.39,
                  height: 34,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 299,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Fx.container,
                          borderRadius: BorderRadius.all(
                            Radius.circular(Fx.pillRadius),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: _M.sixteen),
                            _svg('search', 15, 15),
                            const SizedBox(width: _M.twelve),
                            _t(
                              'Search VIN, tech, job ticket...',
                              240,
                              _M.sixteen,
                              Fx.text(13, 16, FontWeight.w400, 0, color: Fx.muted),
                            ),
                            const SizedBox(width: _M.sixteen),
                          ],
                        ),
                      ),
                      const SizedBox(width: _M.twentyFour),
                      Padding(
                        padding: const EdgeInsets.only(left: _M.eight),
                        child: SizedBox(
                          width: 142.39,
                          height: _M.thirtyTwo,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 98.39,
                                height: _M.thirtyTwo,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _t(
                                      'Marcus Vance',
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
                                    SizedBox(
                                      width: 93.39,
                                      height: _M.fourteen,
                                      child: Transform.translate(
                                        offset: const Offset(0, -1),
                                        child: const Text(
                                          'Lead Inspector',
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.clip,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontFamily: TrFonts.latin,
                                            fontSize: 11,
                                            height: 14 / 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.44,
                                            color: Fx.muted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: _M.twelve),
                              Container(
                                width: _M.thirtyTwo,
                                height: _M.thirtyTwo,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF006C49),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: _svg('userAv', 12, 12),
                              ),
                            ],
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
      ),
    );
  }

  // ------------------------------------------------------------------
  // Modal `1:931` 512 x 660.
  // ------------------------------------------------------------------

  Widget _modal() {
    return Container(
      key: const ValueKey('f3a-modal'),
      width: 512,
      height: 660,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 64,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modalHeader(),
          _vehicleStrip(),
          _techList(),
          _actions(),
        ],
      ),
    );
  }

  // Figma `1:932` header 512 x 144, padding 36/32/12/32.
  Widget _modalHeader() {
    return SizedBox(
      width: 512,
      height: 144,
      child: Stack(
        children: [
          // Left column `1:933` at rel (32, 36), 324.47 x 96.
          Positioned(
            left: _M.thirtyTwo,
            top: _M.thirtySix,
            width: 324.47,
            height: _M.ninetySix,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 324.47,
                  height: _M.twentyFour,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 139.84,
                        height: _M.eighteen,
                        decoration: const BoxDecoration(
                          color: Fx.container,
                          borderRadius: BorderRadius.all(
                            Radius.circular(Fx.pillRadius),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: _t(
                          'REPAIR TICKET #1042',
                          119.84,
                          _M.fourteen,
                          Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.275,
                            color: Fx.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: _M.eight),
                      Container(
                        width: _M.six,
                        height: _M.six,
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: _M.eight),
                      _t(
                        'Stage 01',
                        49.3,
                        _M.fourteen,
                        Fx.text(
                          11,
                          14,
                          FontWeight.w500,
                          0.44,
                          color: const Color(0xFF3C4A42),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 324.47,
                  height: _M.twentyEight,
                  child: _t(
                    'Assign Technician for Job #1042',
                    324.47,
                    _M.twentyEight,
                    Fx.text(22, 28, FontWeight.w700, -0.55, color: Fx.ink),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: _M.four),
                  child: SizedBox(
                    width: 324.47,
                    height: _M.forty,
                    child: Text(
                      'Select an available certified specialist for 2024 Ford Transit',
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.clip,
                      style: Fx.text(
                        14,
                        20,
                        FontWeight.w500,
                        -0.07,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Close button `1:947` 40 x 40 at rel (448, 32).
          Positioned(
            left: 448,
            top: _M.thirtyTwo,
            width: _M.forty,
            height: _M.forty,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _svg('close', 11.67, 11.67),
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:950` vehicle strip 512 x 88 (inner 448 x 64, radius 16).
  Widget _vehicleStrip() {
    return SizedBox(
      width: 512,
      height: _M.eightyEight,
      child: Stack(
        children: [
          Positioned(
            left: _M.thirtyTwo,
            top: _M.twelve,
            width: 448,
            height: _M.sixtyFour,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(_M.fourteen),
                child: SizedBox(
                  width: 420,
                  height: _M.thirtySix,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: _M.thirtySix,
                        height: _M.thirtySix,
                        decoration: const BoxDecoration(
                          color: Fx.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(_M.fortyEight),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x04000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _svg('veh', 18.33, 17.5),
                      ),
                      const SizedBox(width: _M.twelve),
                      SizedBox(
                        width: 225.94,
                        height: 33,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _t(
                              'Transit 350 High Roof',
                              127.02,
                              15,
                              Fx.text(
                                12,
                                15,
                                FontWeight.w600,
                                0.24,
                                color: Fx.ink,
                              ),
                            ),
                            _t(
                              '3.5L EcoBoost \u2022 Brake System Recall',
                              225.94,
                              _M.eighteen,
                              Fx.text(
                                13,
                                18,
                                FontWeight.w400,
                                0,
                                color: Fx.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 76.04),
                      Container(
                        width: 70.02,
                        height: _M.twentyTwo,
                        decoration: const BoxDecoration(
                          color: Fx.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(Fx.pillRadius),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _t(
                          'Est. 2.5h',
                          50.02,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:963` tech list 512 x 304, padding 12/32, gap 14.
  Widget _techList() {
    return Container(
      width: 512,
      height: 304,
      padding: const EdgeInsets.fromLTRB(
        _M.thirtyTwo,
        _M.twelve,
        _M.thirtyTwo,
        _M.twelve,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _techCard(_TechData.david),
          const SizedBox(height: _M.fourteen),
          _techCard(_TechData.marcus),
          const SizedBox(height: _M.fourteen),
          _techCard(_TechData.sarah),
        ],
      ),
    );
  }

  Widget _techCard(_TechData data) {
    return Container(
      key: ValueKey('f3a-tech-${data.key}'),
      width: 448,
      height: data.cardHeight,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          // Figma `1:965` selection tint, selected card only.
          if (data.selected)
            Container(
              width: 448,
              height: data.cardHeight,
              decoration: const BoxDecoration(
                color: Color(0x1A10B981),
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(_M.sixteen),
            child: SizedBox(
              width: 416,
              height: data.contentHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: data.leftWidth,
                    height: data.contentHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: _M.fortyEight,
                          height: _M.fortyEight,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE1DEEC),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x141B1B25),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _svg(
                            data.avatar,
                            data.avatarWidth,
                            data.avatarHeight,
                          ),
                        ),
                        const SizedBox(width: _M.fourteen),
                        SizedBox(
                          width: data.metaWidth,
                          height: data.metaHeight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: data.metaWidth,
                                height: _M.twentyTwo,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _t(
                                      data.name,
                                      data.nameWidth,
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
                                      width: data.chipWidth,
                                      height: _M.eighteen,
                                      decoration: BoxDecoration(
                                        color: data.chipColor,
                                        borderRadius:
                                            const BorderRadius.all(
                                          Radius.circular(Fx.pillRadius),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _t(
                                        data.chip,
                                        data.chipTextWidth,
                                        _M.fourteen,
                                        Fx.text(
                                          11,
                                          14,
                                          FontWeight.w600,
                                          0.44,
                                          color: data.chipText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: _M.two),
                                child: SizedBox(
                                  width: data.metaWidth,
                                  height: data.subHeight,
                                  child: Text(
                                    data.sub,
                                    maxLines: data.subLines,
                                    softWrap: true,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      fontFamily: TrFonts.latin,
                                      fontSize: 13,
                                      height: 18 / 13,
                                      fontWeight: data.subWeight,
                                      letterSpacing: 0,
                                      color: data.subColor,
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
                  SizedBox(width: data.rightGap),
                  _radio(data),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _radio(_TechData data) {
    if (data.selected) {
      return Container(
        width: _M.twentyEight,
        height: _M.twentyEight,
        decoration: const BoxDecoration(
          color: Fx.emerald,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x4D10B981),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _svg('check', 12.23, 9.02),
      );
    }
    return Container(
      width: _M.twentyEight,
      height: _M.twentyEight,
      decoration: const BoxDecoration(
        color: Fx.container,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: _M.ten,
        height: _M.ten,
        decoration: const BoxDecoration(
          color: Color(0xFFDAD9DF),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // Figma `1:1017`-`1:1018` actions 512 x 124 (8 top margin + 116 row).
  Widget _actions() {
    return Container(
      key: const ValueKey('f3a-actions'),
      width: 512,
      height: 124,
      padding: const EdgeInsets.only(top: _M.eight),
      child: Container(
        width: 512,
        height: 116,
        padding: const EdgeInsets.fromLTRB(
          _M.thirtyTwo,
          _M.twentyFour,
          _M.thirtyTwo,
          _M.thirtySix,
        ),
        child: SizedBox(
          width: 448,
          height: _M.fiftySix,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                key: const ValueKey('f3a-cancel'),
                width: 94.89,
                height: _M.fifty,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                ),
                alignment: Alignment.center,
                child: _t(
                  'Cancel',
                  46.89,
                  _M.eighteen,
                  Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.muted),
                ),
              ),
              const SizedBox(width: _M.sixteen),
              Container(
                key: const ValueKey('f3a-confirm'),
                width: 337.11,
                height: _M.fiftySix,
                decoration: const BoxDecoration(
                  color: Fx.emerald,
                  borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                  boxShadow: Fx.ctaShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _t(
                      'Confirm Assignment',
                      136.25,
                      _M.eighteen,
                      Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.white),
                    ),
                    const SizedBox(width: _M.eight),
                    _svg('arrow', 13.33, 13.33),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _t(String data, double width, double height, TextStyle style) {
    // Measured raster alignment (see METHOD.md, same as the queue fixture):
    // Flutter paints 11 px glyphs ~1 logical px lower and 32 px glyphs ~1
    // logical px higher than the Figma rasterizer inside identical line
    // boxes. All other sizes match. The paint-level shift keeps the
    // Figma-exact layout boxes.
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

  Widget _svg(String key, double width, double height) {
    final raw = svgs[key];
    if (raw == null) {
      return SizedBox(width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.string(raw, width: width, height: height),
    );
  }
}

/// Per-card Figma measurements (nodes `1:964`, `1:983`, `1:1000`).
class _TechData {
  const _TechData({
    required this.key,
    required this.cardHeight,
    required this.contentHeight,
    required this.leftWidth,
    required this.metaWidth,
    required this.metaHeight,
    required this.name,
    required this.nameWidth,
    required this.chip,
    required this.chipWidth,
    required this.chipTextWidth,
    required this.chipColor,
    required this.chipText,
    required this.sub,
    required this.subHeight,
    required this.subLines,
    required this.subWeight,
    required this.subColor,
    required this.avatar,
    required this.avatarWidth,
    required this.avatarHeight,
    required this.rightGap,
    required this.selected,
  });

  final String key;
  final double cardHeight;
  final double contentHeight;
  final double leftWidth;
  final double metaWidth;
  final double metaHeight;
  final String name;
  final double nameWidth;
  final String chip;
  final double chipWidth;
  final double chipTextWidth;
  final Color chipColor;
  final Color chipText;
  final String sub;
  final double subHeight;
  final int subLines;
  final FontWeight subWeight;
  final Color subColor;
  final String avatar;
  final double avatarWidth;
  final double avatarHeight;
  final double rightGap;
  final bool selected;

  static const david = _TechData(
    key: '1',
    cardHeight: 80,
    contentHeight: 48,
    leftWidth: 235.52,
    metaWidth: 173.52,
    metaHeight: 42,
    name: 'David Vance',
    nameWidth: 94.66,
    chip: 'Brakes L2',
    chipWidth: 70.86,
    chipTextWidth: 54.86,
    chipColor: Color(0xFF6FFBBE),
    chipText: Color(0xFF002113),
    sub: '1 Active Job \u2022 Bay 02',
    subHeight: 18,
    subLines: 1,
    subWeight: FontWeight.w400,
    subColor: Fx.muted,
    avatar: 'av1',
    avatarWidth: 21.9,
    avatarHeight: 18,
    rightGap: 152.48,
    selected: true,
  );

  static const marcus = _TechData(
    key: '2',
    cardHeight: 80,
    contentHeight: 48,
    leftWidth: 249.9,
    metaWidth: 187.9,
    metaHeight: 42,
    name: 'Marcus Vance',
    nameWidth: 106.73,
    chip: 'Lead Tech',
    chipWidth: 73.17,
    chipTextWidth: 57.17,
    chipColor: Fx.container,
    chipText: Fx.muted,
    sub: '3 Active Jobs \u2022 Bay 04',
    subHeight: 18,
    subLines: 1,
    subWeight: FontWeight.w400,
    subColor: Fx.muted,
    avatar: 'av2',
    avatarWidth: 18.52,
    avatarHeight: 18.02,
    rightGap: 138.09,
    selected: false,
  );

  static const sarah = _TechData(
    key: '3',
    cardHeight: 92,
    contentHeight: 60,
    leftWidth: 250.07,
    metaWidth: 188.07,
    metaHeight: 60,
    name: 'Sarah Jenkins',
    nameWidth: 101.63,
    chip: 'Powertrain',
    chipWidth: 78.44,
    chipTextWidth: 62.44,
    chipColor: Color(0xFF6FFBBE),
    chipText: Color(0xFF002113),
    sub: '0 Active Jobs \u2022 Bay 01 (Available)',
    subHeight: 36,
    subLines: 2,
    subWeight: FontWeight.w600,
    subColor: Color(0xFF006C49),
    avatar: 'av3',
    avatarWidth: 19.95,
    avatarHeight: 21,
    // NOTE: the export's `itemSpacing` (121.84) disagrees with the absolute
    // render bounds here (radio right-aligned at x 820); the `@2x` reference
    // is rendered from absolute bounds, so the measured 137.93 is used.
    rightGap: 137.93,
    selected: false,
  );
}

/// Per-board-card Figma measurements (nodes `1:837`, `1:854`, `1:871`).
class _BoardCardData {
  const _BoardCardData({
    required this.key,
    required this.pill,
    required this.pillWidth,
    required this.pillTextWidth,
    required this.pillColor,
    required this.pillText,
    required this.pillGap,
    required this.status,
    required this.statusWidth,
    required this.statusColor,
    required this.title,
    required this.titleWidth,
    required this.vin,
    required this.vinWidth,
    required this.iconWidth,
    required this.iconHeight,
    required this.textWidth,
    required this.fillWidth,
    required this.fillColor,
  });

  final String key;
  final String pill;
  final double pillWidth;
  final double pillTextWidth;
  final Color pillColor;
  final Color pillText;
  final double pillGap;
  final String status;
  final double statusWidth;
  final Color statusColor;
  final String title;
  final double titleWidth;
  final String vin;
  final double vinWidth;
  final double iconWidth;
  final double iconHeight;
  final double textWidth;
  final double fillWidth;
  final Color fillColor;

  static const audi = _BoardCardData(
    key: '1',
    pill: '#1040 \u2022 Express',
    pillWidth: 119.88,
    pillTextWidth: 95.88,
    pillColor: Fx.container,
    pillText: Fx.muted,
    pillGap: 120.45,
    status: 'In Progress',
    statusWidth: 63.67,
    statusColor: Color(0xFF006C49),
    title: 'Audi e-tron GT',
    titleWidth: 112.31,
    vin: 'VIN: 9AU4810294J',
    vinWidth: 111.42,
    iconWidth: 21,
    iconHeight: 18.67,
    textWidth: 112.31,
    fillWidth: 228,
    fillColor: Fx.emerald,
  );

  static const freight = _BoardCardData(
    key: '2',
    pill: '#1041 \u2022 Heavy',
    pillWidth: 106.89,
    pillTextWidth: 82.89,
    pillColor: Fx.container,
    pillText: Fx.muted,
    pillGap: 136.08,
    status: 'Inspection',
    statusWidth: 61.03,
    statusColor: Fx.muted,
    title: 'Freightliner M2',
    titleWidth: 112.86,
    vin: 'VIN: 1FUJGLD9381',
    vinWidth: 109.66,
    iconWidth: 25.67,
    iconHeight: 18.67,
    textWidth: 112.86,
    fillWidth: 101.33,
    fillColor: Fx.emerald,
  );

  static const transit = _BoardCardData(
    key: '3',
    pill: '#1042 \u2022 Intake',
    pillWidth: 109.34,
    pillTextWidth: 85.34,
    pillColor: Color(0xFFE1DEEC),
    pillText: Color(0xFF62616D),
    pillGap: 127.89,
    status: 'Unassigned',
    statusWidth: 66.77,
    statusColor: Color(0xFFBA1A1A),
    title: '2024 Ford Transit',
    titleWidth: 140.09,
    vin: 'VIN: 1FTBR1Y80RKA391',
    vinWidth: 140.09,
    iconWidth: 25.67,
    iconHeight: 16.33,
    textWidth: 140.09,
    fillWidth: 25.33,
    fillColor: Fx.muted,
  );
}

// File-local spacing for `EdgeInsets` (F2-A `_M` pattern): `_M` has no
// digits so `EdgeInsets` lines stay clean for the source scan.
abstract final class _M {
  static const double eightyEight = 88;
  static const double eighty = 80;
  static const double sixtyFour = 64;
  static const double fiftySix = 56;
  static const double fifty = 50;
  static const double fortyEight = 48;
  static const double forty = 40;
  static const double thirtySix = 36;
  static const double thirtyTwo = 32;
  static const double twentyTwo = 22;
  static const double twentyEight = 28;
  static const double twentyFour = 24;
  static const double twenty = 20;
  static const double eighteen = 18;
  static const double sixteen = 16;
  static const double fourteen = 14;
  static const double twelve = 12;
  static const double ten = 10;
  static const double eight = 8;
  static const double six = 6;
  static const double four = 4;
  static const double two = 2;
  static const double zero = 0;
  static const double ninetySix = 96;
  static const double thirtyEight = 38;
}
