import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// F3-A Step 4 screen 2 — Level 1 exact-structure fixture for Figma screen 2
/// "Live Job Queue" (node `1:529`, 1280 x 1125).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/specs/workshop/02-live-job-queue.md` plus the export JSON
/// `docs/ui/figma-export/Workshop_admin_figma/screens/03_2._Live_Job_Queue/`
/// with exact sizes, positions, colors, shadows and type). It deliberately
/// does NOT reuse the production `JobsTab`: that view is product-anchored
/// (search/status model, no images/bays/progress/stats/footer) while this
/// fixture renders the Figma nodes verbatim (fixed pixel geometry, Figma
/// letter-spacing, exact shadows).
///
/// Shared-kit use: `Fx` primitives/tokens (`Fx.text`, `Fx` colors,
/// `Fx.cardShadow`, `Fx.ctaShadow`) wherever they match Figma exactly.
/// `WorkshopHeader`/`WorkshopJobCard` were evaluated and do NOT match the
/// Level-1 geometry (header/content paddings, title typography, card padding
/// 32 vs kit, 22/28 w700 titles vs kit `titleLarge`); the deltas are recorded
/// as kit gaps in `docs/ui/figma/fidelity/f3a/live-job-queue/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change.
///
/// Figma-exact values with no kit token are inlined here (test-only).
///
/// Source-scan convention (F2-A `_M` pattern): integer layout numbers live in
/// [_M] under digit-free names so `EdgeInsets`/`SizedBox`/`BorderRadius`
/// lines stay clean for the source scan. Fractional Figma values are inline
/// literals (they can never match a spacing token).
///
/// Figma sample copy ("Pending Review", bay/turnaround wording, partial VINs,
/// people and vehicle names) lives ONLY in this `test/` fixture. The
/// `i18n_source_scan_test` (technician) covers `lib/` only and the admin
/// `source_scan_test` excludes `test/` for style checks, so both stay green.
class F3aQueueFixture extends StatelessWidget {
  const F3aQueueFixture({required this.images, required this.svgs, super.key});

  /// Decoded Figma `@2x` vehicle rasters (`rendered_png`, 160 px) drawn 1:1
  /// via `RawImage` scale 2. Keys: `v1`..`v4`.
  final Map<String, ui.Image> images;

  /// Raw Figma icon SVG strings read from the export by the capture test.
  final Map<String, String> svgs;

  static const double width = 1280;
  static const double height = 1125;

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
              height: 1125,
              child: ColoredBox(color: Fx.white, child: _main()),
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
              height: 1101,
              child: _rail(),
            ),
          ],
        ),
      ),
    );
  }

  // Figma `1:531` Main 1184 x 1125, padding 80/40/48/40.
  Widget _main() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _M.forty,
        _M.eighty,
        _M.forty,
        _M.fortyEight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(),
          const SizedBox(height: _M.forty),
          _filterRow(),
          const SizedBox(height: _M.thirtyTwo),
          _card(_CardData.porsche, 'v1'),
          const SizedBox(height: _M.twentyFour),
          _card(_CardData.ford, 'v2'),
          const SizedBox(height: _M.twentyFour),
          _card(_CardData.renault, 'v3'),
          const SizedBox(height: _M.twentyFour),
          _card(_CardData.bmw, 'v4'),
          const SizedBox(height: _M.fortyEight),
          _footer(),
        ],
      ),
    );
  }

  // Figma `1:533`-`1:561` title/header row 1104 x 107.
  Widget _titleRow() {
    return SizedBox(
      width: 1104,
      height: 107,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 412.73,
            height: 107,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(),
                const SizedBox(height: _M.nine),
                SizedBox(
                  width: 412.73,
                  height: _M.fortySix,
                  child: Padding(
                    padding: const EdgeInsets.only(top: _M.eight),
                    child: _t(
                      'Live Job Queue',
                      412.73,
                      _M.thirtyEight,
                      Fx.text(32, 38, FontWeight.w800, -0.8, color: Fx.ink),
                    ),
                  ),
                ),
                const SizedBox(height: _M.six),
                _t(
                  'All vehicles currently in bays or scheduled for inspection',
                  412.73,
                  _M.twentyFour,
                  Fx.text(16, 24, FontWeight.w500, -0.16, color: Fx.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 238.24),
          SizedBox(
            width: 453.03,
            height: _M.sixtyFour,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _statCard(),
                const SizedBox(width: _M.sixteen),
                _newJobButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Figma `1:536` eyebrow pill 164.39 x 22.
  Widget _eyebrow() {
    return Container(
      width: 164.39,
      height: _M.twentyTwo,
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
              color: Fx.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: _M.eight),
          _t(
            'REAL-TIME DISPATCH',
            124.39,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
          ),
          const SizedBox(width: _M.twelve),
        ],
      ),
    );
  }

  // Figma `1:545` stat card 279.89 x 64 (+ `1:557` primary button).
  Widget _statCard() {
    return Container(
      key: const ValueKey('f3a-stat-card'),
      width: 279.89,
      height: _M.sixtyFour,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _M.twentyFour,
          _M.fourteen,
          _M.twentyFour,
          _M.fourteen,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 73.92,
              height: _M.thirtySix,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _t(
                    'ACTIVE BAYS',
                    73.92,
                    _M.fourteen,
                    Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                  ),
                  _t(
                    '06 / 08',
                    73.92,
                    _M.twentyTwo,
                    Fx.stat16.copyWith(color: Fx.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: _M.twentyFour),
            Container(width: _M.one, height: _M.thirtyTwo, color: Fx.divider),
            const SizedBox(width: _M.twentyFour),
            SizedBox(
              width: 108.97,
              height: _M.thirtySix,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _t(
                    'AVG TURNAROUND',
                    108.97,
                    _M.fourteen,
                    Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                  ),
                  _t(
                    '42m',
                    108.97,
                    _M.twentyTwo,
                    Fx.stat16.copyWith(color: Fx.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Figma `1:557` "+ New Job" 157.14 x 56, emerald, radius 16.
  Widget _newJobButton() {
    return Container(
      key: const ValueKey('f3a-new-job'),
      width: 157.14,
      height: _M.fiftySix,
      decoration: const BoxDecoration(
        color: Fx.emerald,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.ctaShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: _M.thirtyTwo),
          _svg('plus', 12.83, 12.83),
          const SizedBox(width: _M.twelve),
          _t(
            '+ New Job',
            68.31,
            _M.eighteen,
            Fx.label14.copyWith(color: Fx.white),
          ),
          const SizedBox(width: _M.thirtyTwo),
        ],
      ),
    );
  }

  // Figma `1:562`-`1:581` filter/sort row 1104 x 48.
  Widget _filterRow() {
    return SizedBox(
      width: 1104,
      height: _M.fortyEight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: const ValueKey('f3a-filters'),
            width: 542.1,
            height: _M.fortyEight,
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
              // Figma `1:564` inner shadow (0,2,4 @5%) has no Flutter
              // equivalent; recorded as a residual in METHOD.md.
            ),
            child: Padding(
              padding: const EdgeInsets.all(_M.six),
              child: Row(
                children: [
                  _filterButton('All (12)', 86.52, active: true),
                  const SizedBox(width: _M.four),
                  _filterButton('In Progress (4)', 134.06),
                  const SizedBox(width: _M.four),
                  _filterButton('Pending Review (3)', 161.94),
                  const SizedBox(width: _M.four),
                  _filterButton('Completed (5)', 135.58),
                ],
              ),
            ),
          ),
          const SizedBox(width: 398.54),
          SizedBox(
            width: 163.36,
            height: _M.forty,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 111.36,
                  height: _M.thirty,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: _M.sixteen),
                      _svg('sort', 13.5, 9),
                      const SizedBox(width: _M.eight),
                      _t(
                        'Bay Order',
                        57.86,
                        _M.fourteen,
                        Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.ink),
                      ),
                      const SizedBox(width: _M.sixteen),
                    ],
                  ),
                ),
                const SizedBox(width: _M.twelve),
                Container(
                  width: _M.forty,
                  height: _M.forty,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12.5),
                      _svg('filter', 15, 10),
                      const SizedBox(width: 12.5),
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

  Widget _filterButton(String label, double width, {bool active = false}) {
    return Container(
      width: width,
      height: _M.thirtySix,
      decoration: BoxDecoration(
        color: active ? Fx.white : const Color(0x00000000),
        borderRadius: const BorderRadius.all(Radius.circular(Fx.pillRadius)),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
        style: Fx.label12.copyWith(color: active ? Fx.ink : Fx.muted),
      ),
    );
  }

  // Figma `1:583`+ article card 1104 x 150, radius 24, padding 32.
  Widget _card(_CardData data, String imageKey) {
    return Container(
      key: ValueKey('f3a-card-${data.key}'),
      width: 1104,
      height: 150,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
        boxShadow: Fx.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(_M.thirtyTwo),
        child: SizedBox(
          width: 1040,
          height: 86,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: data.leftWidth,
                height: 86,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _thumb(imageKey),
                    const SizedBox(width: _M.twenty),
                    SizedBox(
                      width: data.textWidth,
                      height: 86,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _t(
                            data.title,
                            data.titleWidth,
                            _M.twentyEight,
                            Fx.heading22.copyWith(color: Fx.ink),
                          ),
                          const SizedBox(height: _M.twelve),
                          _chip(data),
                          const SizedBox(height: _M.six),
                          _vinRow(data),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: data.middleGap),
              SizedBox(
                width: data.middleWidth,
                height: _M.fortyEight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _assignee(data),
                    const SizedBox(width: _M.twentyFour),
                    _metricBlock(data),
                    const SizedBox(width: _M.twentyFour),
                    _chevron(data),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Figma `1:586` thumbnail tile 80 x 80, radius 16, raster drawn 1:1.
  Widget _thumb(String imageKey) {
    final image = images[imageKey];
    return Container(
      width: _M.eighty,
      height: _M.eighty,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: image == null
          ? const SizedBox.shrink()
          : ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(_M.sixteen),
              ),
              child: SizedBox(
                width: _M.eighty,
                height: _M.eighty,
                child: RawImage(image: image, scale: 2),
              ),
            ),
    );
  }

  Widget _chip(_CardData data) {
    return Container(
      width: data.chipWidth,
      height: _M.twentyTwo,
      decoration: BoxDecoration(
        color: data.chipColor,
        borderRadius: const BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: _M.fourteen),
          _t(
            data.chip,
            data.chipTextWidth,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.275, color: data.chipText),
          ),
          const SizedBox(width: _M.fourteen),
        ],
      ),
    );
  }

  // Figma VIN row: `VIN` + value + bullet + icon + customer.
  Widget _vinRow(_CardData data) {
    return SizedBox(
      width: data.textWidth,
      height: _M.eighteen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _t(
            'VIN',
            20.28,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.ink),
          ),
          const SizedBox(width: _M.six),
          _t(data.vin, data.vinWidth, _M.eighteen, Fx.body13Medium),
          const SizedBox(width: _M.sixteen),
          _t(
            '•',
            6.97,
            _M.eighteen,
            Fx.text(13, 18, FontWeight.w400, 0, color: Fx.surfaceHighest),
          ),
          const SizedBox(width: _M.sixteen),
          _svg(data.sideIcon, data.sideIconSize, data.sideIconSize),
          const SizedBox(width: _M.six),
          _t(data.customer, data.customerWidth, _M.eighteen, Fx.body13),
        ],
      ),
    );
  }

  Widget _assignee(_CardData data) {
    return SizedBox(
      width: data.assigneeWidth,
      height: _M.forty,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: _M.forty,
            height: _M.forty,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            // Figma initials sit at y 11.5 (0.5 above center).
            child: Padding(
              padding: const EdgeInsets.only(top: 11.5),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  data.initials,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: Fx.label12Bold.copyWith(color: data.initialsColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: _M.twelve),
          SizedBox(
            width: data.assigneeTextWidth,
            height: _M.thirty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _t(
                  'ASSIGNED TECH',
                  93.3,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                ),
                _t(data.assignee, data.assigneeTextWidth, _M.sixteen, Fx.label12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBlock(_CardData data) {
    switch (data.kind) {
      case _CardKind.progress:
        return SizedBox(
          width: data.metricWidth,
          height: _M.thirtyTwo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _t(
                'PROGRESS',
                64.47,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
              SizedBox(
                width: data.metricWidth,
                height: _M.eighteen,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    // Figma bar row: track sits low (y 7-15), value sits
                    // high (y 0-14) — not co-centered.
                    width: data.metricWidth - _M.sixteen,
                    height: _M.eighteen,
                    child: Stack(
                      children: [
                        Positioned(
                          left: _M.zero,
                          top: 7,
                          width: _M.ninetySix,
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
                              width: data.fillWidth,
                              height: _M.eight,
                              decoration: const BoxDecoration(
                                color: Fx.emerald,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(Fx.pillRadius),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 104,
                          top: _M.zero,
                          width: data.metricValueWidth,
                          height: _M.fourteen,
                          child: Transform.translate(
                            offset: const Offset(0, -1),
                            child: Text(
                              data.metricValue,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w600,
                                0.44,
                                color: Fx.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case _CardKind.review:
        return SizedBox(
          width: data.metricWidth,
          height: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _t(
                'REVIEW ITEMS',
                81.39,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
              SizedBox(
                width: data.metricWidth,
                height: _M.twenty,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    // Figma flag row: dot at y 8, text at y 4.
                    width: 103.48,
                    height: _M.twenty,
                    child: Stack(
                      children: [
                        Positioned(
                          left: _M.zero,
                          top: _M.eight,
                          width: _M.eight,
                          height: _M.eight,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFBA1A1A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: _M.fourteen,
                          top: _M.four,
                          width: 89.48,
                          height: _M.sixteen,
                          child: Text(
                            '2 Flags Marked',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: Fx.label12.copyWith(color: Fx.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case _CardKind.slot:
        return SizedBox(
          width: data.metricWidth,
          height: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _t(
                'SLOT TIME',
                58.97,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
              SizedBox(
                width: data.metricWidth,
                height: _M.twenty,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    // Figma slot row: clock at y 5.33, text at y 4.
                    width: 91.8,
                    height: _M.twenty,
                    child: Stack(
                      children: [
                        Positioned(
                          left: _M.zero,
                          top: 5.33,
                          width: 13.33,
                          height: 13.33,
                          child: _svg('clock', 13.33, 13.33),
                        ),
                        Positioned(
                          left: 19.33,
                          top: _M.four,
                          width: 72.47,
                          height: _M.sixteen,
                          child: Text(
                            '14:30 Today',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: Fx.label12.copyWith(color: Fx.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _chevron(_CardData data) {
    return SizedBox(
      width: _M.fiftySix,
      height: _M.fortyEight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: _M.eight),
          Container(
            width: _M.fortyEight,
            height: _M.fortyEight,
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
            alignment: Alignment.center,
            child: _svg(data.chevron, 7.4, 12),
          ),
        ],
      ),
    );
  }

  // Figma `1:767` live-sync footer strip 1104 x 50 on a 48 top margin.
  Widget _footer() {
    return Container(
      width: 1104,
      height: _M.fifty,
      decoration: const BoxDecoration(
        color: Fx.container99,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _M.twentyFour,
          _M.sixteen,
          _M.twentyFour,
          _M.sixteen,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 275.33,
              height: _M.eighteen,
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
                  const SizedBox(width: _M.twelve),
                  _t(
                    'Live sync active. Updated 4 seconds ago.',
                    253.33,
                    _M.eighteen,
                    Fx.body13.copyWith(color: Fx.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 406.15),
            SizedBox(
              width: 374.52,
              height: _M.sixteen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _t(
                    'Export Daily Log',
                    97.52,
                    _M.sixteen,
                    Fx.label12.copyWith(color: Fx.muted),
                  ),
                  const SizedBox(width: _M.twentyFour),
                  _t(
                    'Batch Reassign',
                    91.47,
                    _M.sixteen,
                    Fx.label12.copyWith(color: Fx.muted),
                  ),
                  const SizedBox(width: _M.twentyFour),
                  _t(
                    'Bay Schedule Matrix →',
                    137.53,
                    _M.sixteen,
                    Fx.label12Bold.copyWith(color: Fx.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Figma `1:779` floating header 1184 x 80, white 90 % + blur 48.
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
                        Fx.label12Bold.copyWith(color: Fx.ink),
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
                          width: 137.39,
                          height: _M.thirtyTwo,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 93.39,
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
                                        child: Text(
                                          'Lead Inspector',
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
                              const SizedBox(width: _M.twelve),
                              Container(
                                width: _M.thirtyTwo,
                                height: _M.thirtyTwo,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF006C49),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: _svg('avatarUser', 12, 12),
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

  // Figma `1:802` icon rail 96 x 1101.
  Widget _rail() {
    return Container(
      width: _M.ninetySix,
      height: 1101,
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
            left: _M.twentyEight,
            top: 1029,
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

  Widget _t(String data, double width, double height, TextStyle style) {
    // Measured raster alignment (see METHOD.md): Flutter paints 11 px
    // glyphs ~1 logical px lower and 32 px glyphs ~1 logical px higher than
    // the Figma rasterizer inside identical line boxes. All other sizes
    // match. The paint-level shift keeps the Figma-exact layout boxes.
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

enum _CardKind { progress, review, slot }

/// Per-card Figma measurements (nodes `1:583`, `1:629`, `1:674`, `1:720`).
class _CardData {
  const _CardData({
    required this.key,
    required this.title,
    required this.titleWidth,
    required this.chip,
    required this.chipWidth,
    required this.chipTextWidth,
    required this.chipColor,
    required this.chipText,
    required this.vin,
    required this.vinWidth,
    required this.customer,
    required this.customerWidth,
    required this.sideIcon,
    required this.sideIconSize,
    required this.leftWidth,
    required this.textWidth,
    required this.middleGap,
    required this.middleWidth,
    required this.initials,
    required this.initialsColor,
    required this.assignee,
    required this.assigneeWidth,
    required this.assigneeTextWidth,
    required this.kind,
    required this.metricWidth,
    required this.metricValue,
    required this.metricValueWidth,
    required this.fillWidth,
    required this.chevron,
  });

  final String key;
  final String title;
  final double titleWidth;
  final String chip;
  final double chipWidth;
  final double chipTextWidth;
  final Color chipColor;
  final Color chipText;
  final String vin;
  final double vinWidth;
  final String customer;
  final double customerWidth;
  final String sideIcon;
  final double sideIconSize;
  final double leftWidth;
  final double textWidth;
  final double middleGap;
  final double middleWidth;
  final String initials;
  final Color initialsColor;
  final String assignee;
  final double assigneeWidth;
  final double assigneeTextWidth;
  final _CardKind kind;
  final double metricWidth;
  final String metricValue;
  final double metricValueWidth;
  final double fillWidth;
  final String chevron;

  static const porsche = _CardData(
    key: '1',
    title: 'Porsche 911 Carrera S',
    titleWidth: 213.47,
    chip: 'In Progress',
    chipWidth: 89.86,
    chipTextWidth: 61.86,
    chipColor: Color(0xFFFFFBEB),
    chipText: Color(0xFFB45309),
    vin: 'WP0AB2A91LS',
    vinWidth: 93.11,
    customer: 'Alexander Wright',
    customerWidth: 104.42,
    sideIcon: 'person1',
    sideIconSize: 10.67,
    leftWidth: 379.45,
    textWidth: 279.45,
    middleGap: 221.9,
    middleWidth: 438.65,
    initials: 'MV',
    initialsColor: Fx.emerald,
    assignee: 'Marcus Vance (Bay 04)',
    assigneeWidth: 188.7,
    assigneeTextWidth: 136.7,
    kind: _CardKind.progress,
    metricWidth: 145.95,
    metricValue: '65%',
    metricValueWidth: 25.95,
    fillWidth: 62.39,
    chevron: 'chev1',
  );

  static const ford = _CardData(
    key: '2',
    title: 'Ford Transit 350 High Roof',
    titleWidth: 264.75,
    chip: 'Pending Review',
    chipWidth: 115.97,
    chipTextWidth: 87.97,
    chipColor: Color(0xFFFFF7ED),
    chipText: Color(0xFFC2410C),
    vin: '1FTBR1Y88PK',
    vinWidth: 83.33,
    customer: 'Fleet Logistics Inc',
    customerWidth: 110.63,
    sideIcon: 'bldg',
    sideIconSize: 13.33,
    leftWidth: 378.54,
    textWidth: 278.54,
    middleGap: 259.09,
    middleWidth: 402.37,
    initials: 'DV',
    initialsColor: Fx.emerald,
    assignee: 'David Vance (Bay 02)',
    assigneeWidth: 178.89,
    assigneeTextWidth: 126.89,
    kind: _CardKind.review,
    metricWidth: 119.48,
    metricValue: '2 Flags Marked',
    metricValueWidth: 89.48,
    fillWidth: 0,
    chevron: 'chev2',
  );

  static const renault = _CardData(
    key: '3',
    title: 'Renault Megan 3 E-Tech',
    titleWidth: 243.75,
    chip: 'In Progress',
    chipWidth: 89.86,
    chipTextWidth: 61.86,
    chipColor: Color(0xFFFFFBEB),
    chipText: Color(0xFFB45309),
    vin: 'VF1RCB00078',
    vinWidth: 92.31,
    customer: 'Arthur Pendelton',
    customerWidth: 103.36,
    sideIcon: 'person3',
    sideIconSize: 10.67,
    leftWidth: 377.59,
    textWidth: 277.59,
    middleGap: 234.82,
    middleWidth: 427.59,
    initials: 'DV',
    initialsColor: Fx.emerald,
    assignee: 'David Vance (Bay 01)',
    assigneeWidth: 176.42,
    assigneeTextWidth: 124.42,
    kind: _CardKind.progress,
    metricWidth: 147.17,
    metricValue: '30%',
    metricValueWidth: 27.17,
    fillWidth: 28.8,
    chevron: 'chev3',
  );

  static const bmw = _CardData(
    key: '4',
    title: 'BMW i4 M50 Gran Coupe',
    titleWidth: 254.34,
    chip: 'Scheduled',
    chipWidth: 88.08,
    chipTextWidth: 60.08,
    chipColor: Fx.surfaceHigh,
    chipText: Fx.muted,
    vin: 'WBA33AW05N',
    vinWidth: 94.72,
    customer: 'Elena Rostova',
    customerWidth: 86.17,
    sideIcon: 'person4',
    sideIconSize: 10.67,
    leftWidth: 362.81,
    textWidth: 262.81,
    middleGap: 320.09,
    middleWidth: 357.1,
    initials: '--',
    initialsColor: Fx.muted,
    assignee: 'Unassigned',
    assigneeWidth: 145.3,
    assigneeTextWidth: 93.3,
    kind: _CardKind.slot,
    metricWidth: 107.8,
    metricValue: '14:30 Today',
    metricValueWidth: 72.47,
    fillWidth: 0,
    chevron: 'chev4',
  );
}

// File-local spacing for `EdgeInsets` (F2-A `_M` pattern): `_M` has no
// digits so `EdgeInsets` lines stay clean for the source scan.
abstract final class _M {
  static const double eighty = 80;
  static const double fortyEight = 48;
  static const double fortySix = 46;
  static const double forty = 40;
  static const double thirtyEight = 38;
  static const double thirtySix = 36;
  static const double thirtyTwo = 32;
  static const double thirty = 30;
  static const double twentyEight = 28;
  static const double twentyFour = 24;
  static const double twentyTwo = 22;
  static const double twenty = 20;
  static const double eighteen = 18;
  static const double sixteen = 16;
  static const double fourteen = 14;
  static const double twelve = 12;
  static const double ten = 10;
  static const double nine = 9;
  static const double eight = 8;
  static const double six = 6;
  static const double four = 4;
  static const double one = 1;
  static const double zero = 0;
  static const double ninetySix = 96;
  static const double fiftySix = 56;
  static const double fifty = 50;
  static const double sixtyFour = 64;
}
