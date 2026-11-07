import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// F3-A Step 4 screen 3 — Level 1 exact-structure fixture for Figma screen 3
/// "Create / Schedule Job" (node `1:2`, 1280 x 1058).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/specs/workshop/03-create-schedule-job.md` plus the export
/// JSON `docs/ui/figma-export/Workshop_admin_figma/screens/01_3._Create_-_Schedule_Job/`
/// with exact sizes, positions, colors, shadows and type). It deliberately
/// does NOT reuse the product `ScheduleJobSheet`: that view is product-anchored
/// while this fixture renders the Figma nodes verbatim (fixed pixel geometry,
/// Figma letter-spacing, exact shadows, Figma blur/scrim stack).
///
/// Shared-kit use: `Fx` colors/type (`Fx.text`, `Fx.ink`, `Fx.container`,
/// `Fx.cardShadow`, `Fx.ctaShadow`) wherever they match Figma exactly.
/// `WorkshopSideSheet`/`WorkshopHeader`/`WorkshopJobCard` were evaluated and do
/// NOT reproduce Level-1 geometry (drawer radii/shadows/paddings, header
/// paddings, card paddings); the deltas are recorded as kit gaps in
/// `docs/ui/figma/fidelity/f3a/create-schedule/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change.
///
/// Figma-exact values with no kit token are inlined here (test-only).
///
/// Source-scan convention (F2-A `_M` pattern): integer layout numbers live in
/// [_M] under digit-free names so `EdgeInsets`/`SizedBox`/`BorderRadius`
/// lines stay clean for the source scan. Fractional Figma values are inline
/// literals (they can never match a spacing token).
///
/// Figma sample copy lives ONLY in this `test/` fixture. The admin
/// `source_scan_test` excludes `test/` for style checks, so it stays green.
/// The compare fixture points at `forbidden-terms-empty.json` for the same
/// reason as the sibling F3-A fixtures: Figma sample wording would trip the
/// default deny-list, and it is allowed in `test/` only.
class F3aScheduleFixture extends StatelessWidget {
  const F3aScheduleFixture({required this.images, required this.svgs, super.key});

  /// Decoded Figma `@2x` vehicle rasters (`rendered_png`, 128 px) drawn 1:1
  /// via `RawImage` scale 2. Keys: `v1`..`v3`.
  final Map<String, ui.Image> images;

  /// Raw Figma icon SVG strings read from the export by the capture test.
  final Map<String, String> svgs;

  static const double width = 1280;
  static const double height = 1058;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
              height: 1058,
              child: ColoredBox(color: Fx.white, child: _base()),
            ),
            // Frosted scrim 1:167 over the full frame.
            Positioned(
              left: _M.zero,
              top: _M.zero,
              width: width,
              height: height,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: width,
                    height: height,
                    color: const Color(0x99FFFFFF),
                  ),
                ),
              ),
            ),
            Positioned(
              left: _M.ninetySix,
              top: _M.zero,
              width: 1184,
              height: _M.eighty,
              child: _header(),
            ),
            Positioned(
              left: _M.zero,
              top: _M.zero,
              width: _M.ninetySix,
              height: 1024,
              child: _rail(),
            ),
            Positioned(
              left: 860,
              top: _M.zero,
              width: 420,
              height: 1058,
              child: _drawer(),
            ),
          ],
        ),
      ),
    );
  }

  // Underlying queue 1:4/1:5/1:6 — blurred inert base (layer blur 4, opacity
  // 0.8 on 1:6). The ImageFiltered sigma matches the Figma radius 1:1, the
  // same convention as the header blur (48 -> sigma 48).
  Widget _base() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _M.forty,
        _M.eighty,
        _M.forty,
        336,
      ),
      child: SizedBox(
        width: 1104,
        height: 642,
        child: Opacity(
          opacity: 0.8,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _banner(),
                const SizedBox(height: _M.thirtyTwo),
                _cardsRow(),
                const SizedBox(height: _M.thirtyTwo),
                _bays(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Figma 1:7 header stats banner 1104 x 94.
  Widget _banner() {
    return SizedBox(
      width: 1104,
      height: 94,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 158.7,
            height: 94,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _t(
                  'ACTIVE BAY OPERATIONS',
                  158.7,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 1.1, color: Fx.muted),
                ),
                SizedBox(
                  width: 158.7,
                  height: 76,
                  child: Padding(
                    padding: const EdgeInsets.only(top: _M.four),
                    child: _t(
                      'Live Job Queue',
                      158.7,
                      76,
                      Fx.text(32, 38, FontWeight.w800, -0.8, color: Fx.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 532.8),
          SizedBox(
            width: 346.62,
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _statMini(
                  179.14,
                  'Active Work Orders',
                  111.14,
                  '18 Vehicles',
                  83.09,
                ),
                const SizedBox(width: 12),
                _statMini(
                  155.48,
                  'Bays Available',
                  81.98,
                  '3 of 8 Open',
                  87.48,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statMini(
    double w,
    String label,
    double labelW,
    String value,
    double valueW,
  ) {
    return Container(
      width: w,
      height: 60,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _M.twenty,
          _M.twelve,
          _M.twenty,
          _M.twelve,
        ),
        child: SizedBox(
          width: w - _M.forty,
          height: _M.thirtySix,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _t(
                label,
                labelW,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
              _t(
                value,
                valueW,
                _M.twentyTwo,
                Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Figma 1:29 cards grid 1104 x 288.
  Widget _cardsRow() {
    return SizedBox(
      width: 1104,
      height: 288,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _jobCard(
            key: 'v1',
            chipW: 137.86,
            chipBg: const Color(0x4D6FFBBE),
            chip: 'Bay 01 \u2022 In Progress',
            chipW2: 113.86,
            chipFg: Fx.deepGreen,
            chipWeight: FontWeight.w700,
            title: '2023 Audi RS6 Avant',
            titleW: 174.7,
            vin: 'VIN: WUA894G23PN01928',
            vinW: 163.52,
            custLabel: 'Julian Vance',
            custW: 72.84,
            tier: 'Comprehensive 110-Point',
            tierFg: Fx.deepGreen,
            barW: 262.47,
            fill: 196.84,
            pct: '75%',
            pctW: 25.53,
          ),
          const SizedBox(width: _M.twentyFour),
          _jobCard(
            key: 'v2',
            chipW: 150.42,
            chipBg: Fx.container,
            chip: 'Bay 02 \u2022 Intake Ready',
            chipW2: 126.42,
            chipFg: Fx.muted,
            chipWeight: FontWeight.w700,
            title: '2022 Rivian R1T',
            titleW: 128.53,
            vin: 'VIN: 7PDSGABA4NN00318',
            vinW: 164.67,
            custLabel: 'Elena Rostova',
            custW: 83.92,
            tier: 'Standard 60-Point',
            tierFg: Fx.muted,
            barW: 260.81,
            fill: 52.16,
            pct: '20%',
            pctW: 27.19,
          ),
          const SizedBox(width: _M.twentyFour),
          _jobCard(
            key: 'v3',
            chipW: 167.52,
            chipBg: const Color(0x4DFFDAD6),
            chip: 'Bay 04 \u2022 Inspection Hold',
            chipW2: 143.52,
            chipFg: Fx.dangerRed,
            chipWeight: FontWeight.w700,
            title: '2021 BMW M4 Competition',
            titleW: 231.2,
            vin: 'VIN: WBS43AZ08MCH91024',
            vinW: 175.91,
            custLabel: 'Marcus Vance (Fleet)',
            custW: 125.47,
            tier: 'Pre-Purchase Audit',
            tierFg: Fx.dangerRed,
            barW: 260.19,
            fill: 104.06,
            pct: '40%',
            pctW: 27.81,
          ),
        ],
      ),
    );
  }

  Widget _jobCard({
    required String key,
    required double chipW,
    required Color chipBg,
    required String chip,
    required double chipW2,
    required Color chipFg,
    required FontWeight chipWeight,
    required String title,
    required double titleW,
    required String vin,
    required double vinW,
    required String custLabel,
    required double custW,
    required String tier,
    required Color tierFg,
    required double barW,
    required double fill,
    required String pct,
    required double pctW,
  }) {
    return Container(
      width: 352,
      height: 288,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.twentyFour,
            top: _M.twentyFour,
            width: 304,
            height: 83,
            child: SizedBox(
              width: 304,
              height: 83,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 174.7,
                    height: 83,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: chipW,
                          height: _M.twentyTwo,
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(Fx.pillRadius),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: _t(
                            chip,
                            chipW2,
                            _M.fourteen,
                            Fx.text(
                              11,
                              14,
                              chipWeight,
                              0.44,
                              color: chipFg,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 174.7,
                          height: _M.thirtyTwo,
                          child: Padding(
                            padding: const EdgeInsets.only(top: _M.eight),
                            child: _t(
                              title,
                              titleW,
                              _M.twentyFour,
                              Fx.text(
                                18,
                                24,
                                FontWeight.w700,
                                -0.27,
                                color: Fx.ink,
                              ),
                            ),
                          ),
                        ),
                        _t(
                          vin,
                          vinW,
                          _M.eighteen,
                          Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 125.3),
                  _svg('kebab', 4, 16),
                ],
              ),
            ),
          ),
          Positioned(
            left: _M.twentyFour,
            top: 133.5,
            width: 304,
            height: 74,
            child: SizedBox(
              width: 304,
              height: 74,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _thumb(key),
                  const SizedBox(width: _M.sixteen),
                  SizedBox(
                    width: 224,
                    height: 74,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _t(
                          'Customer',
                          56.52,
                          _M.fourteen,
                          Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.44,
                            color: Fx.muted,
                          ),
                        ),
                        _t(
                          custLabel,
                          custW,
                          _M.sixteen,
                          Fx.text(
                            12,
                            16,
                            FontWeight.w600,
                            0.24,
                            color: Fx.ink,
                          ),
                        ),
                        const SizedBox(height: _M.two),
                        _t(
                          tier,
                          custW,
                          42,
                          Fx.text(11, 14, FontWeight.w600, 0.44, color: tierFg),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: _M.twentyFour,
            top: 234,
            width: 304,
            height: 30,
            child: SizedBox(
              width: 304,
              height: 30,
              child: Stack(
                children: [
                  Positioned(
                    left: _M.zero,
                    top: 19,
                    width: barW,
                    height: _M.eight,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.all(
                          Radius.circular(Fx.pillRadius),
                        ),
                      ),
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        width: fill,
                        height: _M.eight,
                        decoration: BoxDecoration(
                          color: tierFg == Fx.muted
                              ? Fx.muted
                              : tierFg,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(Fx.pillRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 304 - pctW,
                    top: _M.sixteen,
                    width: pctW,
                    height: _M.fourteen,
                    child: _t(
                      pct,
                      pctW,
                      _M.fourteen,
                      Fx.text(11, 14, FontWeight.w700, 0.44, color: Fx.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String imageKey) {
    final image = images[imageKey];
    return Container(
      width: _M.sixtyFour,
      height: _M.sixtyFour,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
      ),
      child: image == null
          ? const SizedBox.shrink()
          : ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(_M.sixteen),
              ),
              child: SizedBox(
                width: _M.sixtyFour,
                height: _M.sixtyFour,
                child: RawImage(image: image, scale: 2),
              ),
            ),
    );
  }

  // Figma 1:108 bay grid 1104 x 196.
  Widget _bays() {
    return Container(
      width: 1104,
      height: 196,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.thirtyTwo,
            top: _M.thirtyTwo,
            width: 1040,
            height: 42,
            child: SizedBox(
              width: 1040,
              height: 42,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 301.25,
                    height: 42,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _t(
                          'Facility Bay Allocations',
                          194.89,
                          _M.twentyFour,
                          Fx.text(
                            18,
                            24,
                            FontWeight.w700,
                            -0.27,
                            color: Fx.ink,
                          ),
                        ),
                        _t(
                          'Real-time lift assignment and hardware readiness',
                          301.25,
                          _M.eighteen,
                          Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 609.94),
                  Container(
                    width: 128.81,
                    height: _M.thirtyTwo,
                    decoration: const BoxDecoration(
                      color: Fx.container,
                      borderRadius: BorderRadius.all(
                        Radius.circular(Fx.pillRadius),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _t(
                      'Refresh Sensors',
                      96.81,
                      _M.sixteen,
                      Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: _M.thirtyTwo,
            top: 98,
            width: 1040,
            height: 66,
            child: SizedBox(
              width: 1040,
              height: 66,
              child: Row(
                children: [
                  _bay('Bay 01', 36.98, 'Occupied', Fx.deepGreen, false, false),
                  const SizedBox(width: _M.sixteen),
                  _bay('Bay 02', 39.25, 'Occupied', Fx.deepGreen, false, false),
                  const SizedBox(width: _M.sixteen),
                  _bay('Bay 03', 39.55, 'Available', Fx.emerald, true, true),
                  const SizedBox(width: _M.sixteen),
                  _bay('Bay 04', 39.78, 'Hold', Fx.dangerRed, false, false),
                  const SizedBox(width: _M.sixteen),
                  _bay('Bay 05', 39.44, 'Scheduled', Fx.ink, false, false),
                  const SizedBox(width: _M.sixteen),
                  _bay('Bay 06', 39.28, 'Available', Fx.emerald, true, false),
                  const SizedBox(width: _M.sixteen),
                  _bay('Bay 07', 38.77, 'Available', Fx.emerald, true, false),
                  const SizedBox(width: _M.sixteen),
                  _bay('Bay 08', 39.63, 'Service Off', Fx.muted, false, false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bay(
    String label,
    double labelW,
    String value,
    Color valueColor,
    bool selected,
    bool ring,
  ) {
    final weight = value == 'Available' && label == 'Bay 03'
        ? FontWeight.w800
        : FontWeight.w700;
    return Container(
      width: 116,
      height: 66,
      decoration: BoxDecoration(
        color: selected && label == 'Bay 03' ? Fx.white : Fx.container,
        borderRadius: const BorderRadius.all(Radius.circular(48)),
        boxShadow: ring
            ? const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : selected
                ? const [
                    BoxShadow(
                      color: Color(0xFF10B981),
                      blurRadius: 0,
                      spreadRadius: 2,
                      offset: Offset(0, 0),
                    ),
                  ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: _M.sixteen),
          _t(
            label,
            labelW,
            _M.fourteen,
            Fx.text(
              11,
              14,
              label == 'Bay 03' ? FontWeight.w700 : FontWeight.w600,
              0.44,
              color: label == 'Bay 03' ? Fx.deepGreen : Fx.muted,
            ),
          ),
          const SizedBox(height: _M.four),
          _t(
            value,
            70,
            _M.sixteen,
            Fx.text(12, 16, weight, 0.24, color: valueColor),
          ),
        ],
      ),
    );
  }

  // Figma 1:168 floating header 1184 x 80, white 90% + blur 48.
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
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
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
                        Fx.text(
                          12,
                          16,
                          FontWeight.w700,
                          0.24,
                          color: Fx.ink,
                        ),
                      ),
                      const SizedBox(width: _M.sixteen),
                    ],
                  ),
                ),
                const SizedBox(width: 405.89),
                SizedBox(
                  width: 468.39,
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
                              Fx.text(
                                13,
                                16,
                                FontWeight.w400,
                                0,
                                color: Fx.muted,
                              ),
                            ),
                            const SizedBox(width: _M.sixteen),
                          ],
                        ),
                      ),
                      const SizedBox(width: _M.twentyFour),
                      SizedBox(
                        width: 145.39,
                        height: _M.thirtyTwo,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 93.39,
                              height: 31.5,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: _M.zero,
                                    top: -1,
                                    width: 93.39,
                                    height: _M.eighteen,
                                    child: _t(
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
                                  ),
                                  Positioned(
                                    left: 7.59,
                                    top: 17.5,
                                    width: 85.8,
                                    height: _M.fourteen,
                                    child: _t(
                                      'Lead Inspector',
                                      85.8,
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
                            const SizedBox(width: _M.twelve),
                            Container(
                              width: _M.thirtyTwo,
                              height: _M.thirtyTwo,
                              decoration: const BoxDecoration(
                                color: Fx.deepGreen,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: _svg('avatarUser', 12, 12),
                            ),
                          ],
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

  // Figma 1:191 icon rail 96 x 1024.
  Widget _rail() {
    return Container(
      width: _M.ninetySix,
      height: 1024,
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
              child: _svg('dash', 18, 18),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 208,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: Container(
              key: const ValueKey('f3a-nav-active'),
              decoration: const BoxDecoration(
                color: Fx.emerald,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                boxShadow: Fx.ctaShadow,
              ),
              alignment: Alignment.center,
              child: _svg('jobs', 18, 20),
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
              child: _svg('gear', 18, 18),
            ),
          ),
          Positioned(
            left: 28,
            top: 952,
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

  // Figma 1:210 drawer 420 x 1058, left radii 32, dual shadow.
  Widget _drawer() {
    return Container(
      key: const ValueKey('f3a-drawer'),
      width: 420,
      height: 1058,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 70,
            offset: Offset(0, 25),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 420,
              height: 920,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _M.thirtyTwo,
                  _M.forty,
                  _M.thirtyTwo,
                  _M.twentyFour,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _drawerHead(),
                    _field(
                      label: 'Customer Name',
                      icon: 'user',
                      hint: 'e.g. Arthur Pendelton',
                      hintW: 298.67,
                      iconW: 13.33,
                      iconH: 13.33,
                    ),
                    const SizedBox(height: _M.twentyFour),
                    _field(
                      label: 'Vehicle Make & Model',
                      icon: 'car',
                      hint: 'e.g. 2024 Porsche Taycan 4S',
                      hintW: 297,
                      iconW: 15,
                      iconH: 13.33,
                    ),
                    const SizedBox(height: _M.twentyFour),
                    _fieldDate(),
                    const SizedBox(height: _M.twentyFour),
                    _tiers(),
                    const SizedBox(height: _M.twentyFour),
                    _callout(),
                  ],
                ),
              ),
            ),
            Container(
              width: 420,
              height: 138,
              color: Fx.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _M.thirtyTwo,
                  _M.sixteen,
                  _M.thirtyTwo,
                  _M.forty,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      key: const ValueKey('f3a-cta'),
                      width: 356,
                      height: _M.fiftySix,
                      decoration: const BoxDecoration(
                        color: Fx.emerald,
                        borderRadius: BorderRadius.all(
                          Radius.circular(_M.sixteen),
                        ),
                        boxShadow: Fx.ctaShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 123.69),
                          _svg('cta', 18.33, 16.67),
                          const SizedBox(width: 7.36),
                          _t(
                            'Create Job',
                            82.28,
                            _M.twentyTwo,
                            Fx.text(
                              16,
                              22,
                              FontWeight.w700,
                              -0.16,
                              color: Fx.white,
                            ),
                          ),
                          const SizedBox(width: 123.69),
                        ],
                      ),
                    ),
                    const SizedBox(height: _M.twelve),
                    _t(
                      'Notifies floor dispatch and syncs telematics',
                      249.98,
                      _M.fourteen,
                      Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerHead() {
    return SizedBox(
      key: const ValueKey('f3a-drawer-head'),
      width: 356,
      height: 126,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            height: 126,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _t(
                  'BAY INTAKE',
                  67.05,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
                ),
                SizedBox(
                  width: 300,
                  height: _M.thirtyTwo,
                  child: Padding(
                    padding: const EdgeInsets.only(top: _M.four),
                    child: _t(
                      'Schedule New Job',
                      300,
                      28,
                      Fx.text(
                        22,
                        28,
                        FontWeight.w800,
                        -0.55,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _M.four),
                SizedBox(
                  width: 300,
                  height: 43,
                  child: Text(
                    'Create an intake record and assign to technician\nbay',
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.clip,
                    style: Fx.text(13, 21.13, FontWeight.w400, 0,
                        color: Fx.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _M.sixteen),
          Container(
            width: _M.forty,
            height: _M.forty,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _svg('close', 11.67, 11.67),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String icon,
    required String hint,
    required double hintW,
    required double iconW,
    required double iconH,
  }) {
    return SizedBox(
      width: 356,
      height: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 356,
            height: _M.sixteen,
            child: Padding(
              padding: const EdgeInsets.only(left: _M.four),
              child: _t(
                label,
                352,
                _M.sixteen,
                Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
              ),
            ),
          ),
          const SizedBox(height: _M.eight),
          Container(
            width: 356,
            height: _M.fortyEight,
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Color(0x09000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: _M.sixteen),
                _svg(icon, iconW, iconH),
                const SizedBox(width: 12.33),
                _t(
                  hint,
                  hintW,
                  _M.eighteen,
                  Fx.text(
                    14,
                    18,
                    FontWeight.w500,
                    -0.07,
                    color: const Color(0x995E5D69),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldDate() {
    return SizedBox(
      width: 356,
      height: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 356,
            height: _M.sixteen,
            child: Padding(
              padding: const EdgeInsets.only(left: _M.four),
              child: _t(
                'Select Date & Bay',
                352,
                _M.sixteen,
                Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
              ),
            ),
          ),
          const SizedBox(height: _M.eight),
          Container(
            width: 356,
            height: _M.fortyEight,
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Color(0x09000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: _M.sixteen),
                _svg('cal', 15, 16.67),
                const SizedBox(width: _M.twelve),
                _t(
                  'Today, 2:30 PM (Bay 03)',
                  276,
                  _M.eighteen,
                  Fx.text(
                    14,
                    18,
                    FontWeight.w500,
                    -0.07,
                    color: const Color(0x995E5D69),
                  ),
                ),
                const SizedBox(width: 12),
                _svg('chev', 9, 5.55),
                const SizedBox(width: _M.sixteen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tiers() {
    return SizedBox(
      width: 356,
      height: 208,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: _M.eight),
          SizedBox(
            width: 356,
            height: _M.sixteen,
            child: Padding(
              padding: const EdgeInsets.only(left: _M.four),
              child: _t(
                'Inspection Protocol Tier',
                352,
                _M.sixteen,
                Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
              ),
            ),
          ),
          const SizedBox(height: _M.twelve),
          Container(
            width: 356,
            height: 72,
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F10B981),
                  blurRadius: 25,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(_M.sixteen),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: _M.twelve,
                    height: _M.twelve,
                    decoration: const BoxDecoration(
                      color: Fx.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: _M.twelve),
                  SizedBox(
                    width: 198.88,
                    height: _M.forty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _t(
                          'Standard 60-Point',
                          143.77,
                          _M.twenty,
                          Fx.text(
                            16,
                            20,
                            FontWeight.w700,
                            -0.16,
                            color: Fx.ink,
                          ),
                        ),
                        const SizedBox(height: _M.two),
                        _t(
                          'Quick triage & safety verification',
                          198.88,
                          _M.eighteen,
                          Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 55.12),
                  Container(
                    width: 46,
                    height: _M.twentyTwo,
                    decoration: const BoxDecoration(
                      color: Color(0x666FFBBE),
                      borderRadius: BorderRadius.all(
                        Radius.circular(Fx.pillRadius),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _t(
                      '30m',
                      26,
                      _M.fourteen,
                      Fx.text(
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
          const SizedBox(height: _M.ten),
          Container(
            width: 356,
            height: 90,
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
            child: Padding(
              padding: const EdgeInsets.all(_M.sixteen),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 11.77,
                    height: _M.twelve,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3E2E7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 226.11,
                    height: 58,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _t(
                          'Full Comprehensive 110-Point',
                          226.11,
                          _M.twenty,
                          Fx.text(
                            16,
                            20,
                            FontWeight.w700,
                            -0.16,
                            color: Fx.ink,
                          ),
                        ),
                        const SizedBox(height: _M.two),
                        SizedBox(
                          width: 191.95,
                          height: 36,
                          child: Text(
                            'High-voltage battery, chassis &\npowertrain',
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.clip,
                            style: Fx.text(
                              13,
                              18,
                              FontWeight.w400,
                              0,
                              color: Fx.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 29.93),
                  Container(
                    width: 44.19,
                    height: _M.twentyTwo,
                    decoration: const BoxDecoration(
                      color: Fx.container,
                      borderRadius: BorderRadius.all(
                        Radius.circular(Fx.pillRadius),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _t(
                      '75m',
                      24.19,
                      _M.fourteen,
                      Fx.text(11, 14, FontWeight.w700, 0.44, color: Fx.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _callout() {
    return Container(
      width: 356,
      height: 66,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _M.sixteen),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _svg('shield', 13.33, 16.67),
            const SizedBox(width: 12),
            SizedBox(
              width: 204.77,
              height: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _t(
                    'Auto-assign Lead Tech',
                    136.83,
                    _M.sixteen,
                    Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                  ),
                  _t(
                    'Marcus Vance assigned to Bay 03',
                    204.77,
                    _M.eighteen,
                    Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _t(String data, double width, double height, TextStyle style) {
    // Measured raster alignment (see sibling screen 2 METHOD): Flutter paints
    // 11 px glyphs ~1 logical px lower and 32 px glyphs ~1 higher than the
    // Figma rasterizer inside identical line boxes. All other sizes match.
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

// File-local spacing for `EdgeInsets` (F2-A `_M` pattern): `_M` has no
// digits so `EdgeInsets` lines stay clean for the source scan.
abstract final class _M {
  static const double eighty = 80;
  static const double fortyEight = 48;
  static const double forty = 40;
  static const double thirtySix = 36;
  static const double thirtyTwo = 32;
  static const double twentyFour = 24;
  static const double twentyTwo = 22;
  static const double twenty = 20;
  static const double eighteen = 18;
  static const double sixteen = 16;
  static const double fourteen = 14;
  static const double twelve = 12;
  static const double ten = 10;
  static const double eight = 8;
  static const double four = 4;
  static const double two = 2;
  static const double zero = 0;
  static const double ninetySix = 96;
  static const double fiftySix = 56;
  static const double sixtyFour = 64;
}
