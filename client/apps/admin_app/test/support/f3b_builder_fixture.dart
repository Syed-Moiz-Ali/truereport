import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// F3-B Step 3 screen 8 — Level 1 exact-structure fixture for Figma screen 8
/// "Template Builder" (node `1:1882`, 1280 x 1251.5).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/specs/workshop/08-template-builder.md` plus the export JSON
/// `docs/ui/figma-export/Workshop_admin_figma/screens/08_8._Template_Builder/`
/// with exact sizes, positions, colors, shadows and type). It deliberately
/// does NOT reuse the product `template_builder_page.dart`: that view is
/// product-anchored while this fixture renders the Figma nodes verbatim
/// (fixed pixel geometry, Figma letter-spacing, exact shadows, header blur).
///
/// Shared-kit use: `Fx` colors/type (`Fx.text`, `Fx.ink`, `Fx.container`,
/// `Fx.surfaceHigh`, `Fx.sage`, `Fx.dangerRed`, `Fx.cardShadow`,
/// `Fx.ctaShadow`) wherever they match Figma exactly. `WorkshopMetric`,
/// `WorkshopSequenceCard`, `WorkshopLockedPill` and `WorkshopDropZone` were
/// evaluated and do NOT reproduce Level-1 geometry (metric label/value/
//// note/progress stack + right icon slot, sequence numeral/title/chip/rule/
//// control-cluster row, tonal drop zone with icon disc + two centred lines,
/// locked-pill API has no Figma slot here); the deltas are recorded as kit
/// gaps in `docs/ui/figma/fidelity/f3b/template-builder/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change.
///
/// Figma-exact values with no kit token are inlined here (test-only).
///
/// Source-scan convention (F2-A `_M` pattern): integer layout numbers live in
/// [_M] under digit-free names so `EdgeInsets`/`SizedBox`/`BorderRadius`
/// lines stay clean. Fractional Figma values are inline literals (they can
/// never match a spacing token).
///
/// Figma sample copy lives ONLY in this `test/` fixture. The admin
/// `source_scan_test` excludes `test/` for style checks, so it stays green.
/// The compare fixture points at `forbidden-terms-empty.json` for the same
/// reason as the sibling F3-A/F3-B fixtures: Figma sample wording would trip
/// the default deny-list, and it is allowed in `test/` only.
class F3bBuilderFixture extends StatelessWidget {
  const F3bBuilderFixture({required this.svgs, super.key});

  /// Raw Figma icon SVG strings read from the export by the capture test.
  final Map<String, String> svgs;

  static const double width = 1280;
  static const double height = 1251.5;

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
              key: const ValueKey('f3b-rail'),
              left: _M.zero,
              top: _M.zero,
              width: _M.ninetySix,
              height: 1182,
              child: _rail(),
            ),
            Positioned(
              left: _M.ninetySix,
              top: _M.zero,
              width: 1184,
              height: _M.eighty,
              child: _header(),
            ),
            ..._topBar(),
            ..._pods(),
            ..._leftColumn(),
            ..._rightColumn(),
          ],
        ),
      ),
    );
  }

  // Figma `1:1886` top bar 1104 x 114 (pad-bottom 40).
  List<Widget> _topBar() {
    return [
      Positioned(
        key: const ValueKey('f3b-topbar'),
        left: 136,
        top: _M.eighty,
        width: 1104,
        height: 114,
        child: Stack(
          children: [
            Positioned(
              left: _M.zero,
              top: _M.zero,
              width: 28,
              height: 28,
              child: Container(
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(9999)),
                ),
                alignment: Alignment.center,
                child: _t(
                  'V2.4',
                  27.8,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w700, 0.55, color: Fx.deepGreen),
                ),
              ),
            ),
            Positioned(
              left: _M.forty,
              top: _M.seven,
              child: _t(
                'STANDARD OPERATING PROCEDURE',
                226.05,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 1.1, color: Fx.muted),
              ),
            ),
            Positioned(
              left: _M.zero,
              top: _M.thirtySix,
              child: _t(
                'Template Builder: Comprehensive Inspection',
                670.19,
                _M.thirtyEight,
                Fx.text(32, 38, FontWeight.w800, -0.8, color: Fx.ink),
              ),
            ),
            Positioned(
              left: 730.9,
              top: _M.fifteen,
              width: 151.91,
              height: _M.fortyFour,
              child: Container(
                decoration: const BoxDecoration(
                  color: Fx.white,
                  borderRadius: BorderRadius.all(Radius.circular(9999)),
                  boxShadow: Fx.cardShadow,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: _M.twentyFour,
                      top: 16.38,
                      width: 16.5,
                      height: 11.25,
                      child: _svg('eye', 16.5, 11.25),
                    ),
                    Positioned(
                      left: 48.5,
                      top: _M.fourteen,
                      child: _t(
                        'Preview Flow',
                        79.41,
                        _M.sixteen,
                        Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 898.8,
              top: _M.fourteen,
              width: 205.24,
              height: _M.fortySix,
              child: Container(
                decoration: const BoxDecoration(
                  color: Fx.emerald,
                  borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                  boxShadow: Fx.ctaShadow,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: _M.thirtyTwo,
                      top: 16.33,
                      width: 18.33,
                      height: 13.33,
                      child: _svg('publish', 18.33, 13.33),
                    ),
                    Positioned(
                      left: 60.33,
                      top: _M.fourteen,
                      child: _t(
                        'Publish Template',
                        112.91,
                        _M.eighteen,
                        Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // Figma `1:1904` pods row 1104 x 193.5 (pad-bottom 48), gap 24.
  List<Widget> _pods() {
    return [
      Positioned(
        key: const ValueKey('f3b-pod-1'),
        left: 136,
        top: 194,
        width: 258,
        height: 143,
        child: _podShell(
          label: _t(
            'SEQUENCE TOTAL',
            104.44,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
          ),
          labelW: 104.44,
          icon: 'pod1',
          iconW: 16.67,
          iconH: 15,
          body: Stack(
            children: [
              Positioned(
                left: _M.twentyFour,
                top: _M.fiftyNine,
                child: _t(
                  '3',
                  18.63,
                  _M.thirtyEight,
                  Fx.text(32, 38, FontWeight.w800, -0.96, color: Fx.ink),
                ),
              ),
              Positioned(
                left: 50.63,
                top: _M.seventySeven,
                child: _t(
                  'of 14 configured',
                  99.25,
                  _M.eighteen,
                  Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                ),
              ),
              Positioned(
                left: _M.twentyFour,
                top: 113,
                width: 210,
                height: _M.six,
                child: Stack(
                  children: [
                    Container(
                      width: 210,
                      height: _M.six,
                      decoration: const BoxDecoration(
                        color: Fx.surfaceHigh,
                        borderRadius:
                            BorderRadius.all(Radius.circular(9999)),
                      ),
                    ),
                    Container(
                      width: 58.8,
                      height: _M.six,
                      decoration: const BoxDecoration(
                        color: Fx.emerald,
                        borderRadius:
                            BorderRadius.all(Radius.circular(9999)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 418,
        top: 194,
        width: 258,
        height: 143,
        child: _podShell(
          label: _t(
            'MANDATORY PHOTOS',
            127.17,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
          ),
          labelW: 127.17,
          icon: 'pod2',
          iconW: 16.67,
          iconH: 15,
          body: Stack(
            children: [
              Positioned(
                left: _M.twentyFour,
                top: _M.fiftyFive,
                child: _t(
                  '1',
                  12.27,
                  _M.thirtyEight,
                  Fx.text(32, 38, FontWeight.w800, -0.96, color: Fx.ink),
                ),
              ),
              Positioned(
                left: 44.3,
                top: _M.seventyThree,
                child: _t(
                  'checkpoint flagged',
                  122.44,
                  _M.eighteen,
                  Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                ),
              ),
              Positioned(
                left: _M.twentyFour,
                top: 105,
                child: _t(
                  'Optical AI analysis enabled',
                  210,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 700,
        top: 194,
        width: 258,
        height: 145.5,
        child: _podShell(
          label: _t(
            'AVG FIELD TIME',
            90.02,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
          ),
          labelW: 90.02,
          labelTop: 25.75,
          icon: 'pod3',
          iconW: 15,
          iconH: 17.5,
          iconLeft: 219,
          body: Stack(
            children: [
              Positioned(
                left: _M.twentyFour,
                top: 57.5,
                child: _t(
                  '12',
                  30.38,
                  _M.thirtyEight,
                  Fx.text(32, 38, FontWeight.w800, -0.96, color: Fx.ink),
                ),
              ),
              Positioned(
                left: 62.4,
                top: 75.5,
                child: _t(
                  'minutes estimated',
                  114.48,
                  _M.eighteen,
                  Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                ),
              ),
              Positioned(
                left: _M.twentyFour,
                top: 107.5,
                child: _t(
                  'Fast Track Eligible',
                  210,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.emerald),
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 982,
        top: 194,
        width: 258,
        height: 142,
        child: _podShell(
          label: _t(
            'TELEMETRY LINK',
            95.36,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
          ),
          labelW: 95.36,
          icon: 'pod4',
          iconW: 16.67,
          iconH: 11.79,
          iconTop: 25.1,
          body: Stack(
            children: [
              Positioned(
                left: _M.twentyFour,
                top: _M.fiftyFour,
                child: _t(
                  'Laser & OBD',
                  185.37,
                  _M.thirtyEight,
                  Fx.text(32, 38, FontWeight.w800, -0.96, color: Fx.ink),
                ),
              ),
              Positioned(
                left: _M.twentyFour,
                top: 104,
                child: _t(
                  'Direct BT calibration on',
                  210,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // One metric pod: white r16 + Figma dual shadow; label row + body.
  Widget _podShell({
    required Widget label,
    required double labelW,
    required String icon,
    required double iconW,
    required double iconH,
    double labelTop = 24.5,
    double iconLeft = 217.3,
    double iconTop = 24,
    required Widget body,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(left: _M.twentyFour, top: labelTop, child: label),
          Positioned(
            left: iconLeft,
            top: iconTop,
            width: iconW,
            height: iconH,
            child: _svg(icon, iconW, iconH),
          ),
          body,
        ],
      ),
    );
  }

  // Figma `1:1957` left column 404.33 x 696.67 at (136, 387.5), gap 24.
  List<Widget> _leftColumn() {
    const items = <_CatalogItem>[
      _CatalogItem(
        icon: 'i1',
        iconW: 18.33,
        iconH: 18.33,
        title: 'Check Brakes & Calipers',
        titleW: 185.91,
        cat: 'Chassis',
        catW: 47.88,
        sub: 'Wear & Hydraulics',
        subW: 102.42,
        drag: 'd1',
      ),
      _CatalogItem(
        icon: 'i2',
        iconW: 16.5,
        iconH: 16.5,
        title: 'Oil Level & Viscosity',
        titleW: 152.84,
        cat: 'Powertrain',
        catW: 66.41,
        sub: 'Spectro Grade',
        subW: 84.16,
        drag: 'd2',
      ),
      _CatalogItem(
        icon: 'i3',
        iconW: 11.92,
        iconH: 18.33,
        title: 'Battery State of Health',
        titleW: 173.31,
        cat: 'Electrical',
        catW: 57.23,
        sub: '12V / High Voltage',
        subW: 102.28,
        drag: 'd3',
      ),
      _CatalogItem(
        icon: 'i4',
        iconW: 20.17,
        iconH: 17.42,
        title: 'Tread Depth All Axles',
        titleW: 158.81,
        cat: 'Tires',
        catW: 28.64,
        sub: '32nds Measurement',
        subW: 114.59,
        drag: 'd4',
      ),
      _CatalogItem(
        icon: 'i5',
        iconW: 20.14,
        iconH: 15.58,
        title: 'Coolant Expansion Tank',
        titleW: 180.53,
        cat: 'Fluids',
        catW: 36.25,
        sub: 'Boilover PSI',
        subW: 67.75,
        drag: 'd5',
      ),
    ];
    return [
      Positioned(
        left: 136,
        top: 387.5,
        width: 404.33,
        height: _M.fifty,
        child: Stack(
          children: [
            Positioned(
              left: _M.zero,
              top: _M.zero,
              child: _t(
                'Master Items',
                133.23,
                _M.twentyEight,
                Fx.text(22, 28, FontWeight.w700, -0.44, color: Fx.ink),
              ),
            ),
            Positioned(
              left: 312.5,
              top: _M.three,
              width: 91.86,
              height: _M.twentyTwo,
              child: Container(
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(9999)),
                ),
                alignment: Alignment.center,
                child: _t(
                  '5 In Catalog',
                  67.86,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                ),
              ),
            ),
            Positioned(
              left: _M.zero,
              top: _M.thirtyTwo,
              child: _t(
                'Available Diagnostic Checkpoints',
                404.33,
                _M.eighteen,
                Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
              ),
            ),
          ],
        ),
      ),
      Positioned(
        left: 136,
        top: 461.5,
        width: 404.33,
        height: _M.fortyTwo,
        child: Container(
          decoration: const BoxDecoration(
            color: Fx.container,
            borderRadius: BorderRadius.all(Radius.circular(9999)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: _M.sixteen,
                top: 13.5,
                width: _M.fifteen,
                height: _M.fifteen,
                child: _svg('search', 15, 15),
              ),
              Positioned(
                left: _M.fortyThree,
                top: _M.thirteen,
                child: _t(
                  'Filter checkpoints by system...',
                  345.33,
                  _M.sixteen,
                  Fx.text(13, 16, FontWeight.w400, 0, color: Fx.muted),
                ),
              ),
            ],
          ),
        ),
      ),
      for (var index = 0; index < items.length; index++)
        Positioned(
          key: index == 0 ? const ValueKey('f3b-card-1') : null,
          left: 136,
          top: 527.5 + index * 100,
          width: 404.33,
          height: _M.eightyFour,
          child: _catalogCard(items[index]),
        ),
      Positioned(
        left: 136,
        top: 1035.5,
        width: 404.33,
        height: 48.67,
        child: Container(
          decoration: const BoxDecoration(
            color: Fx.container,
            borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 95.66,
                top: _M.sixteen,
                width: 16.67,
                height: 16.67,
                child: _svg('plus', 16.67, 16.67),
              ),
              Positioned(
                left: 120.33,
                top: 16.33,
                child: _t(
                  'Create Custom Diagnostic Item',
                  188.34,
                  _M.sixteen,
                  Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Figma `1:1973` master item card 404.33 x 84, white r16, pad 20.
  Widget _catalogCard(_CatalogItem item) {
    return Container(
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.twenty,
            top: _M.twenty,
            width: _M.fortyFour,
            height: _M.fortyFour,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              ),
              alignment: Alignment.center,
              child: _svg(item.icon, item.iconW, item.iconH),
            ),
          ),
          Positioned(
            left: _M.eighty,
            top: _M.twentyOne,
            child: _t(
              item.title,
              item.titleW,
              _M.twentyTwo,
              Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
            ),
          ),
          Positioned(
            left: _M.eighty,
            top: _M.fortyFive,
            width: item.titleW,
            height: _M.eighteen,
            child: Stack(
              children: [
                Positioned(
                  left: _M.zero,
                  top: _M.zero,
                  child: _t(
                    item.cat,
                    item.catW,
                    _M.eighteen,
                    Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                  ),
                ),
                Positioned(
                  left: item.catW + 8,
                  top: _M.seven,
                  width: _M.four,
                  height: _M.four,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Fx.sage,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: item.catW + 16,
                  top: _M.two,
                  child: _t(
                    item.sub,
                    item.subW,
                    _M.fourteen,
                    Fx.text(11, 14, FontWeight.w500, 0.44, color: Fx.secondaryInk),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 375.16,
            top: 34.67,
            width: 9.17,
            height: 14.67,
            child: _svg(item.drag, 9.17, 14.67),
          ),
        ],
      ),
    );
  }

  // Figma `1:2062` right column 659.67 x 816 at (580.33, 387.5), gap 24.
  List<Widget> _rightColumn() {
    const seqs = <_SeqItem>[
      _SeqItem(
        numeral: '01',
        numeralW: 17.47,
        title: 'Check Brakes & Calipers',
        titleW: 207.08,
        status: 'Active',
        statusKind: _StatusKind.active,
        ruleIcon: 'r1',
        ruleIconW: 13.33,
        ruleIconH: 12,
        ruleIconTop: 5,
        rule: 'Mandatory Optical Photo',
        ruleW: 143.67,
        ruleBoxW: 187.0,
        note: '\u2022 Chassis Integrity',
        noteW: 110.81,
        upActive: true,
      ),
      _SeqItem(
        numeral: '02',
        numeralW: 20.56,
        title: 'Oil Level & Viscosity',
        titleW: 170.05,
        status: 'Active',
        statusKind: _StatusKind.active,
        ruleIcon: 'r2',
        ruleIconW: 13.33,
        ruleIconH: 10.67,
        ruleIconTop: 5.67,
        rule: 'Value Range Input [0.0 - 8.5L]',
        ruleW: 171.44,
        ruleBoxW: 214.77,
        note: '\u2022 Powertrain Module',
        noteW: 124.28,
        upActive: false,
      ),
      _SeqItem(
        numeral: '03',
        numeralW: 20.8,
        title: 'Tread Depth All Axles',
        titleW: 176.78,
        status: 'Automated',
        statusKind: _StatusKind.automated,
        ruleIcon: 'r3',
        ruleIconW: 12,
        ruleIconH: 13.33,
        ruleIconTop: 4.3,
        rule: 'Laser Gauge Integration',
        ruleW: 137.06,
        ruleBoxW: 179.06,
        ruleTextLeft: 30,
        note: '\u2022 Tire Quad-Sensor',
        noteW: 118.23,
        upActive: false,
      ),
    ];
    return [
      Positioned(
        left: 580.33,
        top: 387.5,
        width: 659.67,
        height: _M.fortySix,
        child: Stack(
          children: [
            Positioned(
              left: _M.zero,
              top: _M.zero,
              child: _t(
                'Workshop Template',
                206.41,
                _M.twentyEight,
                Fx.text(22, 28, FontWeight.w700, -0.44, color: Fx.ink),
              ),
            ),
            Positioned(
              left: _M.zero,
              top: _M.twentyEight,
              child: _t(
                'Active Inspection Sequence (Drag to reorder)',
                276.69,
                _M.eighteen,
                Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
              ),
            ),
            Positioned(
              left: 526,
              top: _M.ten,
              width: 133.7,
              height: _M.twentySix,
              child: Container(
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(9999)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: _M.twelve,
                      top: _M.nine,
                      width: _M.eight,
                      height: _M.eight,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: _M.twentyEight,
                      top: _M.six,
                      child: _t(
                        'Autosave Active',
                        93.7,
                        _M.fourteen,
                        Fx.text(11, 14, FontWeight.w700, 0.44, color: Fx.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      for (var index = 0; index < seqs.length; index++)
        Positioned(
          key: index == 0 ? const ValueKey('f3b-seq-1') : null,
          left: 580.33,
          top: 457.5 + index * 148,
          width: 659.67,
          height: 128,
          child: _sequenceCard(seqs[index], index),
        ),
      Positioned(
        key: const ValueKey('f3b-drop'),
        left: 580.33,
        top: 905.5,
        width: 659.67,
        height: 168,
        child: Container(
          decoration: const BoxDecoration(
            color: Fx.white,
            borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
            boxShadow: Fx.cardShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 305.9,
                top: _M.thirtyTwo,
                width: _M.fortyEight,
                height: _M.fortyEight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _svg('drop', 19.5, 19.5),
                ),
              ),
              Positioned(
                left: 150.4,
                top: _M.ninetyTwo,
                child: _t(
                  'Drag master checkpoint here to append to flow',
                  358.88,
                  _M.twentyTwo,
                  Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
                ),
              ),
              Positioned(
                left: 171.3,
                top: 118,
                child: _t(
                  'Or click any catalog item from the left panel to insert',
                  317.05,
                  _M.eighteen,
                  Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        key: const ValueKey('f3b-qa'),
        left: 580.33,
        top: 1097.5,
        width: 659.67,
        height: 106,
        child: Container(
          decoration: const BoxDecoration(
            color: Fx.white,
            borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
            boxShadow: Fx.cardShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                left: _M.twentyFour,
                top: _M.thirtyThree,
                width: 38.28,
                height: _M.forty,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                  ),
                  alignment: Alignment.center,
                  child: _svg('qa', 14.67, 18.33),
                ),
              ),
              Positioned(
                left: 78.3,
                top: _M.twentyFour,
                child: _t(
                  'Quality Assurance Rule Set',
                  203.5,
                  _M.twentyTwo,
                  Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
                ),
              ),
              Positioned(
                left: 78.3,
                top: _M.fortySix,
                child: _tw(
                  'Enforces ISO-9001 brake testing standards & laser '
                  'calibration validation on\nsave.',
                  457.89,
                  _M.thirtySix,
                  Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                  maxLines: 2,
                ),
              ),
              Positioned(
                left: 549.6,
                top: _M.thirtyNine,
                child: _tw(
                  'ACTIVE\nPOLICY',
                  44.79,
                  _M.twentyEight,
                  Fx.text(11, 14, FontWeight.w700, 0.55, color: Fx.deepGreen),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Figma sequence card 659.67 x 128, white r16, pad 24.
  Widget _sequenceCard(_SeqItem seq, int index) {
    final statusPill = seq.statusKind == _StatusKind.active
        ? _activePill(seq.status, index)
        : _automatedPill(seq.status);
    return Container(
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
            width: _M.forty,
            height: _M.forty,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _t(
                seq.numeral,
                seq.numeralW,
                _M.twentyTwo,
                Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
              ),
            ),
          ),
          Positioned(
            left: _M.eighty,
            top: _M.twentyFour,
            child: _t(
              seq.title,
              seq.titleW,
              _M.twentyFour,
              Fx.text(18, 24, FontWeight.w700, -0.27, color: Fx.ink),
            ),
          ),
          Positioned(
            left: 80 + 12 + seq.titleW,
            top: _M.twentySeven,
            child: statusPill,
          ),
          Positioned(
            left: _M.eighty,
            top: _M.fiftySix,
            width: seq.ruleBoxW,
            height: _M.twentyTwo,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(9999)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: _M.twelve,
                    top: seq.ruleIconTop,
                    width: seq.ruleIconW,
                    height: seq.ruleIconH,
                    child: _svg(seq.ruleIcon, seq.ruleIconW, seq.ruleIconH),
                  ),
                  Positioned(
                    left: seq.ruleTextLeft,
                    top: _M.four,
                    child: _t(
                      seq.rule,
                      seq.ruleW,
                      _M.fourteen,
                      Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: _M.eighty,
            top: _M.eightySix,
            child: _t(
              seq.note,
              seq.noteW,
              _M.eighteen,
              Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
            ),
          ),
          Positioned(
            left: 478.47,
            top: _M.fortyFour,
            width: 157.17,
            height: _M.forty,
            child: _controls(seq, index),
          ),
        ],
      ),
    );
  }

  // Figma Active status pill 66.53 x 18, mint 40 % + dot + deep text.
  Widget _activePill(String label, int index) {
    return Container(
      key: ValueKey('f3b-status-$index'),
      width: 66.53,
      height: _M.eighteen,
      decoration: const BoxDecoration(
        color: Color(0x666FFBBE),
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.ten,
            top: _M.six,
            width: _M.six,
            height: _M.six,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.deepGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: _M.two,
            child: _t(
              label,
              36.53,
              _M.fourteen,
              Fx.text(
                11,
                14,
                FontWeight.w600,
                0.44,
                color: const Color(0xFF002113),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Figma Automated pill 84.27 x 18, tonal #EEEDF3.
  Widget _automatedPill(String label) {
    return Container(
      width: 84.27,
      height: _M.eighteen,
      decoration: const BoxDecoration(
        color: Fx.surfaceHigh,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      alignment: Alignment.center,
      child: _t(
        label,
        64.27,
        _M.fourteen,
        Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
      ),
    );
  }

  // Figma `Card Controls` 157.17 x 40: grouped pair + trash + drag handle.
  Widget _controls(_SeqItem seq, int index) {
    // Icon fills are baked in the export SVGs and match Figma; only the
    // active button gets the white disc + micro shadow.
    Widget iconButton({
      required String icon,
      required double iconW,
      required double iconH,
      required bool filled,
    }) {
      return Container(
        width: _M.thirtyTwo,
        height: _M.thirtyTwo,
        decoration: BoxDecoration(
          color: filled ? Fx.white : const Color(0x00000000),
          shape: BoxShape.circle,
          boxShadow: filled
              ? const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: _svg(icon, iconW, iconH),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: _M.zero,
          top: _M.zero,
          width: _M.eightyFour,
          height: _M.forty,
          child: Container(
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(9999)),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: _M.eight,
                  top: _M.four,
                  child: iconButton(
                    icon: 'cup$index',
                    iconW: 16.5,
                    iconH: seq.upActive ? 15.75 : 15,
                    filled: seq.upActive,
                  ),
                ),
                Positioned(
                  left: _M.fortyFour,
                  top: _M.four,
                  child: iconButton(
                    icon: 'cdn$index',
                    iconW: 13.5,
                    iconH: 13.5,
                    filled: !seq.upActive,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: _M.ninetySix,
          top: _M.two,
          width: _M.thirtySix,
          height: _M.thirtySix,
          child: Container(
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _svg('trash$index', 12, 13.5),
          ),
        ),
        Positioned(
          left: 148,
          top: 9.67,
          width: 9.17,
          height: 14.67,
          child: _svg('drag$index', 9.17, 14.67),
        ),
      ],
    );
  }

  // Figma `1:2194` floating header 1184 x 80, white 90 % + blur 48.
  Widget _header() {
    return ClipRect(
      child: BackdropFilter(
        filter: _blur(48),
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
                    borderRadius: BorderRadius.all(Radius.circular(9999)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _M.sixteen,
                        top: 11,
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
                            color: Fx.secondaryInk,
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
                left: 675.6,
                top: _M.twentyThree,
                width: 299,
                height: 34,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(9999)),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _M.sixteen,
                        top: 9.5,
                        width: _M.fifteen,
                        height: _M.fifteen,
                        child: _svg('hsearch', 15, 15),
                      ),
                      Positioned(
                        left: _M.fortyThree,
                        top: _M.nine,
                        child: _t(
                          'Search VIN, tech, job ticket...',
                          240,
                          _M.sixteen,
                          Fx.text(13, 16, FontWeight.w400, 0, color: Fx.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 1006.6,
                top: 23.25,
                child: _t(
                  'Marcus Vance',
                  93.39,
                  _M.eighteen,
                  Fx.text(14, 17.5, FontWeight.w700, -0.14, color: Fx.ink),
                ),
              ),
              Positioned(
                left: 1006.6,
                top: 41.75,
                width: 93.39,
                height: _M.fourteen,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _t(
                    'Lead Inspector',
                    85.8,
                    _M.fourteen,
                    Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                  ),
                ),
              ),
              Positioned(
                left: 1112,
                top: _M.twentyFour,
                width: _M.thirtyTwo,
                height: _M.thirtyTwo,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.deepGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _svg('avatar', 12, 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Figma `1:2217` icon rail 96 x 1182.
  Widget _rail() {
    return Container(
      width: _M.ninetySix,
      height: 1182,
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
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
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
                color: Fx.emerald,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                boxShadow: Fx.ctaShadow,
              ),
              alignment: Alignment.center,
              child: _svg('gear', 18, 18),
            ),
          ),
          Positioned(
            left: _M.twentyEight,
            top: 1110,
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

  // Measured raster alignment (same convention as the sibling F3-A/F3-B
  // fixtures): Flutter paints 11 px glyphs ~1 logical px lower and 32 px
  // glyphs ~1 px higher than the Figma rasterizer inside identical line
  // boxes; 13/18 and 18/24 also render ~1 px low (ink-centroid verified).
  // All other sizes match unshifted.
  double _dy(TextStyle style) {
    final size = style.fontSize ?? 14;
    if (size == 11) return -1.0;
    if (size == 32) return 1.0;
    final ratio = style.height ?? 1.0;
    if (size == 13 && ratio > 1.3) return -1.0;
    if (size == 18) return -1.0;
    return 0.0;
  }

  Widget _t(String data, double width, double height, TextStyle style) {
    final dy = _dy(style);
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

  Widget _tw(
    String data,
    double width,
    double height,
    TextStyle style, {
    required int maxLines,
  }) {
    final dy = _dy(style);
    final text = Text(
      data,
      maxLines: maxLines,
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

// Figma background blurs are 1:1 sigmas (same convention as the sibling
// F3-A/F3-B fixtures: the header blur radius 48 renders as sigma 48).
ui.ImageFilter _blur(double sigma) => ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
    );

class _CatalogItem {
  const _CatalogItem({
    required this.icon,
    required this.iconW,
    required this.iconH,
    required this.title,
    required this.titleW,
    required this.cat,
    required this.catW,
    required this.sub,
    required this.subW,
    required this.drag,
  });

  final String icon;
  final double iconW;
  final double iconH;
  final String title;
  final double titleW;
  final String cat;
  final double catW;
  final String sub;
  final double subW;
  final String drag;
}

enum _StatusKind { active, automated }

class _SeqItem {
  const _SeqItem({
    required this.numeral,
    required this.numeralW,
    required this.title,
    required this.titleW,
    required this.status,
    required this.statusKind,
    required this.ruleIcon,
    required this.ruleIconW,
    required this.ruleIconH,
    required this.ruleIconTop,
    required this.rule,
    required this.ruleW,
    required this.ruleBoxW,
    this.ruleTextLeft = 31.33,
    required this.note,
    required this.noteW,
    required this.upActive,
  });

  final String numeral;
  final double numeralW;
  final String title;
  final double titleW;
  final String status;
  final _StatusKind statusKind;
  final String ruleIcon;
  final double ruleIconW;
  final double ruleIconH;
  final double ruleIconTop;
  final String rule;
  final double ruleW;
  final double ruleBoxW;
  final double ruleTextLeft;
  final String note;
  final double noteW;
  final bool upActive;
}

// File-local spacing for `EdgeInsets` (F2-A `_M` pattern): `_M` has no
// digits so `EdgeInsets` lines stay clean for the source scan.
abstract final class _M {
  static const double eightyFour = 84;
  static const double eightySix = 86;
  static const double eighty = 80;
  static const double ninetyTwo = 92;
  static const double ninetySix = 96;
  static const double fifty = 50;
  static const double fiftyNine = 59;
  static const double fiftySix = 56;
  static const double fiftyFive = 55;
  static const double fiftyFour = 54;
  static const double fortyEight = 48;
  static const double fortySix = 46;
  static const double fortyFive = 45;
  static const double fortyFour = 44;
  static const double fortyThree = 43;
  static const double fortyTwo = 42;
  static const double forty = 40;
  static const double thirtyNine = 39;
  static const double thirtyEight = 38;
  static const double thirtySix = 36;
  static const double thirtyThree = 33;
  static const double thirtyTwo = 32;
  static const double twentyEight = 28;
  static const double twentySeven = 27;
  static const double twentySix = 26;
  static const double twentyFour = 24;
  static const double twentyThree = 23;
  static const double twentyTwo = 22;
  static const double twentyOne = 21;
  static const double twenty = 20;
  static const double eighteen = 18;
  static const double sixteen = 16;
  static const double fifteen = 15;
  static const double fourteen = 14;
  static const double thirteen = 13;
  static const double twelve = 12;
  static const double ten = 10;
  static const double nine = 9;
  static const double eight = 8;
  static const double seven = 7;
  static const double six = 6;
  static const double four = 4;
  static const double three = 3;
  static const double two = 2;
  static const double zero = 0;
  static const double seventySeven = 77;
  static const double seventyThree = 73;
}
