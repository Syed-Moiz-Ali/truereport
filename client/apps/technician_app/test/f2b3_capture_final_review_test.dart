import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';

import 'support/f2a_fidelity_harness.dart';
import 'support/f2a_test_fonts.dart';
import 'support/f2b_views.dart';
import 'support/fidelity_output.dart';

// F2-B.3 Part 2, screen 13 (Fig want exact Figma text (Level 1 is a fidelity fixture, not product
// copy) instead of routing through product models. Chrome copy that exists in
// the override (Review Findings, Resolve to Continue, Diagnostic Checklist)
// resolves through [F2bFigmaStrings] via [f2bHost] `figmaStrings: true`; the
// remaining literals are the exact Figma node strings from
// `docs/ui/figma/f2b-nodes/13-final-review.txt`.
class _L1 extends StatelessWidget {
  const _L1();

  @override
  Widget build(BuildContext context) {
    // Reuse the existing test-only Figma wording where it exists.
    const resolveToContinue = F2bFigmaStrings.resolveToContinue;
    const headerTitle = 'Diagnostic Checklist';
    return SizedBox(
      width: 390,
      height: 1008,
      child: Container(
        color: Fx.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: SizedBox(
                width: 390,
                height: 944,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _overview(),
                      _bannerMargin(),
                      _missingMargin(),
                      _metadataMargin(),
                      _bottomAction(resolveToContinue),
                    ],
                  ),
                ),
              ),
            ),
            _header(headerTitle),
          ],
        ),
      ),
    );
  }

  // 1:8352 @20,64 350x138 VERTICAL gap=4 pad=8,0,24,0.
  static Widget _overview() {
    return SizedBox(
      width: 350,
      height: 138,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 350,
            height: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 165.38,
                  height: 16,
                  child: Text(
                    'STEP 4 OF 4 \u2022 VALIDATION',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Fx.text(
                      12,
                      16,
                      FontWeight.w600,
                      0.6,
                      color: Fx.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 71.23),
                F2bStatusPill(
                  label: '3 Action Items',
                  background: F2b.rosePale,
                  foreground: F2b.redMaroon,
                  dot: Fx.dangerRed,
                  style: Fx.text(
                    11,
                    14,
                    FontWeight.w600,
                    0.44,
                    color: F2b.redMaroon,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 350,
            height: 36,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                F2bFigmaStrings.reviewFindings,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: Fx.display26.copyWith(color: Fx.ink),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 350,
            height: 40,
            child: Text(
              'Resolve outstanding compliance requirements\n'
              'before submitting the digital work order.',
              maxLines: 2,
              style: Fx.body14.copyWith(color: Fx.muted),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 1:8363 @20,202 350x184 pad bottom 24; banner 1:8364 350x160 r32
  // fill #FFDAD74D + DROP_SHADOW(40 0,14), HORIZONTAL gap 16 pad 20.
  static Widget _bannerMargin() {
    return SizedBox(
      width: 350,
      height: 184,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const Key('f2b3-banner'),
            width: 350,
            height: 160,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: F2b.roseWash,
              borderRadius: BorderRadius.circular(Fx.cardRadius),
              boxShadow: Fx.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    shape: BoxShape.circle,
                    boxShadow: Fx.pillShadow,
                  ),
                  child: const Center(
                    child: FxIcon(
                      id: '1_8367',
                      size: 22,
                      color: Fx.dangerRed,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  height: 120,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 22,
                        child: Text(
                          '3 Mandatory Photos Missing',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.title16.copyWith(color: Fx.ink),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 250,
                        height: 54,
                        child: Text(
                          'Customer sign-off & quality assurance\n'
                          'mandate verified optical documentation\n'
                          'for critical fluid and wear sections.',
                          maxLines: 3,
                          style: Fx.text(
                            13,
                            18,
                            FontWeight.w400,
                            0,
                            color: Fx.iconGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 250,
                        height: 36,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 56,
                                height: 24,
                                child: Stack(
                                  children: [
                                    _badge('1', 0),
                                    _badge('2', 16),
                                    _badge('3', 32),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 182,
                                height: 28,
                                padding: const EdgeInsets.only(right: 11.17),
                                child: Text(
                                  'Tap any item below to capture\n'
                                  'instantly',
                                  maxLines: 2,
                                  style: Fx.text(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Numbered badges 24x24 fill #FFDAD6, numerals Nimbus Sans Bold 11 in Figma;
  // the test harness only ships Plus Jakarta Sans, so the shared-kit Jakarta
  // Bold stands in (sub-glyph residual, quantified in METHOD.md).
  static Widget _badge(String numeral, double left) {
    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: F2b.rosePale,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            numeral,
            textDirection: TextDirection.ltr,
            style: Fx.text(
              11,
              16.5,
              FontWeight.w700,
              0,
              color: F2b.redMaroon,
            ),
          ),
        ),
      ),
    );
  }

  // 1:8386 @20,386 350x354 pad bottom 32; stack 1:8387 350x322 gap 14.
  static Widget _missingMargin() {
    return SizedBox(
      width: 350,
      height: 354,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 350,
            height: 322,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 350,
                  height: 16,
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: Text(
                    'MANDATORY RESOLUTION ITEMS',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Fx.text(
                      12,
                      16,
                      FontWeight.w600,
                      0.6,
                      color: Fx.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _row(
                  iconId: '1_8394',
                  iconSize: 18,
                  title: 'Brake Fluid',
                  titleWidth: 83.95,
                  chip: _plainChip('Chassis', 60.03),
                  detail: 'Reservoir moisture gauge & test strip',
                  detailWidth: 165.66,
                  titleRowWidth: 165.66,
                  leftWidth: 229.66,
                  cameraId: '1_8406',
                  cameraSize: 18.33,
                  chevronId: '1_8408',
                ),
                const SizedBox(height: 14),
                _row(
                  iconId: '1_8413',
                  iconSize: 22,
                  title: 'Tread Photo',
                  titleWidth: 85.73,
                  titleRightPad: 8.37,
                  chip: _plainChip('Front Left', 72.27),
                  detail: '3/32" depth indicator macro verification',
                  detailWidth: 166,
                  titleRowWidth: 166,
                  leftWidth: 230,
                  cameraId: '1_8425',
                  cameraSize: 16.67,
                  chevronId: '1_8427',
                ),
                const SizedBox(height: 14),
                _row(
                  iconId: '1_8432',
                  iconSize: 19,
                  title: 'Signature',
                  titleWidth: 73.86,
                  chip: _requiredChip(),
                  detail: 'Digital advisor & vehicle owner sign-off',
                  detailWidth: 164.34,
                  titleRowWidth: 164.34,
                  leftWidth: 228.34,
                  cameraId: '1_8444',
                  cameraSize: 16.67,
                  chevronId: '1_8446',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Rows 1:8390/1:8409/1:8428 350x88 r32 white + two DROP_SHADOWs
  // (= Fx.cardShadow), HORIZONTAL pad 20; action cluster right-aligned via
  // spaceBetween exactly as the Figma x-positions require.
  static Widget _row({
    required String iconId,
    required double iconSize,
    required String title,
    required double titleWidth,
    double titleRightPad = 0,
    required Widget chip,
    required String detail,
    required double detailWidth,
    required double titleRowWidth,
    required double leftWidth,
    required String cameraId,
    required double cameraSize,
    required String chevronId,
  }) {
    return Container(
      width: 350,
      height: 88,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.circular(Fx.cardRadius),
        boxShadow: Fx.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: leftWidth,
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FxIcon(
                      id: iconId,
                      size: iconSize,
                      color: Fx.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: leftWidth - 64,
                  height: 42,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: titleRowWidth,
                        height: 22,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: titleWidth,
                              height: 22,
                              child: Padding(
                                padding: EdgeInsets.only(right: titleRightPad),
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                  style: Fx.title16.copyWith(color: Fx.ink),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            chip,
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: detailWidth,
                        height: 18,
                        child: Text(
                          detail,
                          maxLines: 1,
                          softWrap: false,
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
              ],
            ),
          ),
          SizedBox(
            width: 50.17,
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: F2b.rosePale,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FxIcon(
                      id: cameraId,
                      size: cameraSize,
                      color: Fx.dangerRed,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 6.17,
                  height: 10,
                  child: Center(
                    child: FxIcon(
                      id: chevronId,
                      size: 10,
                      color: F2b.greyLavender,
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

  // Row 1/2 category chips: transparent (no fill in Figma), 11/600 muted,
  // pad 2,8,2,8.
  static Widget _plainChip(String label, double width) {
    return Container(
      width: width,
      height: 18,
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
      ),
    );
  }

  // Row 3 "Required" chip 67.73x18 fill #FFDAD6, text #B91A24.
  static Widget _requiredChip() {
    return Container(
      width: 67.73,
      height: 18,
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      decoration: BoxDecoration(
        color: F2b.rosePale,
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: Text(
        'Required',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: Fx.text(
          11,
          14,
          FontWeight.w600,
          0.44,
          color: Fx.dangerRed,
        ),
      ),
    );
  }

  // 1:8447 @20,740 350x116 pad bottom 32; card 1:8448 350x84 r32
  // fill #F4F3F899, HORIZONTAL pad 16, no shadow.
  static Widget _metadataMargin() {
    return SizedBox(
      width: 350,
      height: 116,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 350,
            height: 84,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Fx.container99,
              borderRadius: BorderRadius.circular(Fx.cardRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 214.38,
                  height: 52,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 25.83,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Fx.white,
                          borderRadius: BorderRadius.circular(Fx.pillRadius),
                        ),
                        child: const Center(
                          child: FxIcon(
                            id: '1_8452',
                            size: 16.5,
                            color: Fx.emerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 176.55,
                        height: 52,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 176.55,
                              height: 16,
                              child: Text(
                                '28 Verified Data Points',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: Fx.text(
                                  12,
                                  16,
                                  FontWeight.w600,
                                  0.24,
                                  color: Fx.ink,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 176.55,
                              height: 36,
                              child: Text(
                                'Powertrain, OBD-II & exterior\n'
                                'scans passed',
                                maxLines: 2,
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
                    ],
                  ),
                ),
                Container(
                  width: 68.14,
                  height: 28,
                  padding: const EdgeInsets.only(right: 10.75),
                  child: Text(
                    '91%\nComplete',
                    maxLines: 2,
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 1:8460 @20,856 350x112 VERTICAL gap 12 pad top 8. CTA 1:8461 350x56
  // r9999 has NO fill and node opacity 0.8 (measured blend #D2D1DC on white),
  // so the content renders at 80% over the white page.
  static Widget _bottomAction(String resolveToContinue) {
    return SizedBox(
      width: 350,
      height: 112,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Opacity(
            opacity: 0.8,
            child: Container(
              key: const Key('f2b3-continue'),
              width: 350,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Fx.pillRadius),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 13.33,
                      height: 17.5,
                      child: Center(
                        child: FxIcon(
                          id: '1_8463',
                          size: 17.5,
                          color: F2b.greyLavender,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 133.39,
                      height: 18,
                      child: Text(
                        resolveToContinue,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                        style: Fx.text(
                          14,
                          18,
                          FontWeight.w700,
                          -0.14,
                          color: F2b.greyLavender,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 350,
            height: 36,
            child: Center(
              child: Text(
                'All 3 critical checklist items must be resolved to unlock\n'
                'client sign-off.',
                maxLines: 2,
                textAlign: TextAlign.center,
                style: Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1:8468 Header @0,0 390x64 fill #FFFFFFCC + DROP_SHADOW(8 0,1) +
  // BACKGROUND_BLUR(48). Custom-built from Fx primitives so the back vector
  // (1:8473 11.77x20) and the exact 18/24 tracking (-0.45) match the node;
  // the shared FxHeader's Material back glyph and -0.27 tracking do not.
  static Widget _header(String title) {
    return Container(
      key: const Key('f2b3-header'),
      width: 390,
      height: 64,
      decoration: const BoxDecoration(
        color: Fx.whiteCC,
        boxShadow: Fx.headerShadow,
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 223.53,
                  height: 44,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: FxIcon(
                            id: '1_8473',
                            size: 20,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 175.53,
                        height: 24,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            title,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: Fx.text(
                              18,
                              24,
                              FontWeight.w700,
                              -0.45,
                              color: Fx.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 102.47),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Fx.deepGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: FxIcon(
                      id: '1_8478',
                      size: 12,
                      color: Fx.white,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadF2AFonts();
  });

  testWidgets('capture f2b3 final-review level1', (tester) async {
    final root = repoRoot();
    final outDir = fidelityOutputDir(
      root,
      'figma/fidelity/f2b3/final-review',
    );
    final previous = enableFidelityShadows();
    try {
      const dpr = 2.0;
      const height = 1008.0;
      tester.view.physicalSize = const Size(390 * dpr, height * dpr);
      tester.view.devicePixelRatio = dpr;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const rootKey = ValueKey('f2b3-final-review-root');

      await tester.pumpWidget(
        f2bHost(
          child: const RepaintBoundary(
            key: rootKey,
            child: SizedBox(
              width: 390,
              height: height,
              child: ColoredBox(
                color: Fx.white,
                child: Material(
                  type: MaterialType.transparency,
                  child: _L1(),
                ),
              ),
            ),
          ),
          locale: const Locale('en'),
          theme: AppTheme.light,
          figmaStrings: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final boxes = <String, dynamic>{
        for (final key in ['f2b3-header', 'f2b3-banner', 'f2b3-continue'])
          key: () {
            final rect = tester.getRect(find.byKey(ValueKey(key)));
            return {
              'x': rect.left,
              'y': rect.top,
              'width': rect.width,
              'height': rect.height,
            };
          }(),
      };

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(rootKey),
      );
      final image = await boundary.toImage(pixelRatio: dpr);
      final byteData = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      if (byteData == null) {
        throw StateError('PNG encoding returned no data for f2b3 final-review');
      }
      outDir.createSync(recursive: true);
      File('${outDir.path}/render.png')
          .writeAsBytesSync(byteData.buffer.asUint8List());

      final strings = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      File('${outDir.path}/geometry.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'sample': 'f2b3-final-review-level1',
          'logicalSize': {'width': 390, 'height': height},
          'devicePixelRatio': dpr,
          'boxes': boxes,
        }),
        flush: true,
      );
      File('${outDir.path}/strings.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'sample': 'f2b3-final-review-level1',
          'locale': 'en',
          'direction': 'ltr',
          'theme': 'light',
          'textScale': 1,
          'strings': strings,
        }),
        flush: true,
      );
    } finally {
      restoreFidelityShadows(previous);
    }
  });
}
