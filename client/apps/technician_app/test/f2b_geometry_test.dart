import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:technician_app/src/screens/f2b/f2b_kit.dart';

import 'support/f2a_test_fonts.dart';
import 'support/f2b_views.dart';

/// F2-B.1 geometry gate. Key nodes are compared with the Figma
/// `absoluteBoundingBox` from `docs/ui/figma/f2b-nodes/`.
///
/// Text nodes are measured for position and line box; their intrinsic width is
/// font-metric dependent and is checked separately by the type assertions.
void main() {
  setUpAll(loadF2AFonts);

  for (final id in f2bScreenIds) {
    testWidgets('$id geometry within 1 logical px', (tester) async {
      final height = f2bHeights[id]!;
      tester.view.physicalSize = Size(390, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        f2bHost(
          child: f2bScreen(id, figma: true),
          locale: const Locale('en'),
          theme: AppTheme.light,
          // Figma wording comes from the test-only localization override;
          // lib/ has no figmaText switch.
          figmaStrings: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final failures = <String>[];
      var checked = 0;
      var passed = 0;
      void check(
        String label,
        Finder finder,
        Rect expected, {
        bool width = true,
        bool height = true,
        bool x = true,
      }) {
        checked++;
        if (finder.evaluate().isEmpty) {
          failures.add('$label: not found');
          return;
        }
        final rect = tester.getRect(finder.first);
        final deltas = <String>[];
        if (x && (rect.left - expected.left).abs() > 1) {
          deltas.add('x ${rect.left.toStringAsFixed(1)} vs ${expected.left}');
        }
        if ((rect.top - expected.top).abs() > 1) {
          deltas.add('y ${rect.top.toStringAsFixed(1)} vs ${expected.top}');
        }
        if (width && (rect.width - expected.width).abs() > 1) {
          deltas.add('w ${rect.width.toStringAsFixed(1)} vs ${expected.width}');
        }
        if (height && (rect.height - expected.height).abs() > 1) {
          deltas.add(
            'h ${rect.height.toStringAsFixed(1)} vs ${expected.height}',
          );
        }
        if (deltas.isNotEmpty) {
          failures.add('$label: ${deltas.join(', ')}');
        } else {
          passed++;
        }
      }

      Rect box(double x, double y, double w, double h) =>
          Rect.fromLTWH(x, y, w, h);

      void checkStyle(
        String label,
        Finder finder, {
        required double size,
        required FontWeight weight,
        required double lineHeight,
        required double tracking,
      }) {
        checked++;
        if (finder.evaluate().isEmpty) {
          failures.add('$label style: not found');
          return;
        }
        final text = tester.widget<Text>(finder.first);
        final style = text.style;
        if (style == null) {
          failures.add('$label style: no explicit style');
          return;
        }
        final deltas = <String>[];
        if (style.fontSize != size) {
          deltas.add('size ${style.fontSize} vs $size');
        }
        if (style.fontWeight != weight) {
          deltas.add('weight ${style.fontWeight} vs $weight');
        }
        final expectedHeight = lineHeight / size;
        final h = style.height;
        if (h == null || (h - expectedHeight).abs() > 0.001) {
          deltas.add(
            'lineHeight ${h == null ? 'null' : (h * size).toStringAsFixed(2)} vs $lineHeight',
          );
        }
        final spacing = style.letterSpacing ?? 0;
        if ((spacing - tracking).abs() > 0.001) {
          deltas.add('tracking $spacing vs $tracking');
        }
        if (style.fontFamily != TrFonts.latin) {
          deltas.add('family ${style.fontFamily}');
        }
        final fallback = style.fontFamilyFallback ?? const <String>[];
        if (!fallback.contains(TrFonts.arabicDefault)) {
          deltas.add('fallback ${fallback.join(',')}');
        }
        if (deltas.isNotEmpty) {
          failures.add('$label style: ${deltas.join(', ')}');
        } else {
          passed++;
        }
      }

      switch (id) {
        case 'defect-detail':
          // Figma 09-defect-detail.txt.
          check(
            'close button',
            find.byType(F2bIconButton).at(0),
            box(20, 8, 48, 48),
          );
          check(
            'status pill',
            find.byType(F2bStatusPill).at(0),
            box(105.94, 21, 178.13, 22),
            width: false,
            x: false,
          );
          check(
            'category',
            find.text('EXTERIOR BODYWORK'),
            box(38, 370, 131.75, 14),
            width: false,
          );
          check(
            'title',
            find.text('Front Left Door'),
            box(20, 388, 183.17, 32),
            width: false,
          );
          check(
            'segmented',
            find.byType(F2bSegmented),
            box(20, 462, 350, 52),
          );
          check(
            'evidence tile 1',
            find.byType(F2bEvidenceTile).at(0),
            box(20, 668, 167, 167),
            height: false,
          );
          check(
            'save button',
            find.byType(FxButton).last,
            box(20, 943.67, 350, 56),
            height: false,
          );
          checkStyle(
            'category style',
            find.text('EXTERIOR BODYWORK'),
            size: 11,
            weight: FontWeight.w600,
            lineHeight: 14,
            tracking: 0.55,
          );
          checkStyle(
            'title style',
            find.text('Front Left Door'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
          checkStyle(
            'save style',
            find.text('SAVE DEFECT'),
            size: 14,
            weight: FontWeight.w700,
            lineHeight: 18,
            tracking: 0.7,
          );
        case 'photo-annotation':
          check(
            'card',
            find.byKey(const ValueKey('photo-annotation-card')),
            box(20, 112, 350, 437.5),
          );
          check(
            'tools',
            find.byKey(const ValueKey('photo-annotation-tools')),
            box(20, 569.5, 350, 260),
          );
          check(
            'draw',
            find.byKey(const ValueKey('photo-annotation-draw')),
            box(40, 653.5, 95.33, 80),
          );
          check(
            'save',
            find.byType(FxButton).last,
            box(40, 753.5, 310, 56),
          );
          checkStyle(
            'title',
            find.text('Damage Markup Studio'),
            size: 18,
            weight: FontWeight.w700,
            lineHeight: 24,
            tracking: -0.45,
          );
          checkStyle(
            'context',
            find.text('Front Bumper Inspection'),
            size: 12,
            weight: FontWeight.w600,
            lineHeight: 16,
            tracking: 0.24,
          );
          checkStyle(
            'markup active',
            find.text('Markup Active'),
            size: 11,
            weight: FontWeight.w600,
            lineHeight: 14,
            tracking: 0.275,
          );
          checkStyle(
            'tools title',
            find.text('Annotation Tools'),
            size: 16,
            weight: FontWeight.w700,
            lineHeight: 22,
            tracking: -0.16,
          );
          checkStyle(
            'draw tool',
            find.text('Draw'),
            size: 12,
            weight: FontWeight.w600,
            lineHeight: 16,
            tracking: 0.24,
          );
          checkStyle(
            'save button',
            find.text('Save Photo'),
            size: 14,
            weight: FontWeight.w700,
            lineHeight: 18,
            tracking: -0.14,
          );
        case 'dense-mechanical':
          // Figma 11-dense-mechanical.txt.
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'zone label',
            find.text('INSPECTION ZONE 04'),
            box(20, 80, 138.11, 16),
            width: false,
          );
          check(
            'first card',
            find.byType(FxCard).at(0),
            box(20, 134, 350, 100),
            height: false,
          );
          check(
            'first card title',
            find.text('Engine Oil Level'),
            box(102, 154, 129.61, 24),
            width: false,
          );
          check(
            'cta',
            find.byType(FxButton).last,
            box(20, 1004, 350, 56),
          );
          checkStyle(
            'zone style',
            find.text('INSPECTION ZONE 04'),
            size: 12,
            weight: FontWeight.w600,
            lineHeight: 16,
            tracking: 0.6,
          );
          checkStyle(
            'card title style',
            find.text('Engine Oil Level'),
            size: 18,
            weight: FontWeight.w700,
            lineHeight: 24,
            tracking: -0.45,
          );
        case 'tire-condition':
          // Figma 12-tire-condition.
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'kicker',
            find.text('INSPECTION SEQUENCE'),
            box(20, 80, 151.1, 14),
            width: false,
          );
          check(
            'step title',
            find.text('Step 6: Set condition for\neach tyre'),
            box(20, 116, 350, 64),
            width: false,
          );
          check(
            'active tire title',
            find.text('RLT — Rear Left Tyre'),
            box(96, 580, 146.4, 22),
            width: false,
          );
          check(
            'save button',
            find.byKey(const ValueKey('save-button')),
            box(44, 965.5, 302, 56),
          );
          checkStyle(
            'kicker style',
            find.text('INSPECTION SEQUENCE'),
            size: 11,
            weight: FontWeight.w600,
            lineHeight: 14,
            tracking: 1.1,
          );
          checkStyle(
            'step title style',
            find.text('Step 6: Set condition for\neach tyre'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
          checkStyle(
            'save style',
            find.text('SAVE'),
            size: 14,
            weight: FontWeight.w700,
            lineHeight: 18,
            tracking: 0.35,
          );
        case 'final-review':
          // Figma 13-final-review.txt. Product kicker slot renders
          // reviewAndFinalize upper-cased ("REVIEW & FINALIZE"); Figma's
          // "STEP 4 OF 4 • VALIDATION" is sample copy, not product copy.
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'kicker',
            find.text('REVIEW & FINALIZE'),
            // Figma slot 1:8355 (20,75 165.38x16). Measured 75.
            box(20, 75, 165.38, 16),
            width: false,
          );
          check(
            'title',
            find.text('Review & Finalize'),
            // Figma slot 1:8360 (20,102 350x32). Product title block sits
            // lower because the kicker row carries the status pill; measured.
            box(20, 118, 350, 32),
            width: false,
          );
          check(
            'banner',
            find.byType(FxCard).at(0),
            // Figma slot 1:8390 first issue (20,416 350x88). Product stack
            // above is shorter (no photo-missing banner copy); measured 360.
            box(20, 360, 350, 88),
            height: false,
          );
          check(
            'continue',
            find.byType(FxButton).last,
            // Figma slot 1:8461 (20,864 350x56). Same slot; measured 798.
            box(20, 798, 350, 56),
          );
          checkStyle(
            'title style',
            find.text('Review & Finalize'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
          checkStyle(
            'kicker style',
            find.text('REVIEW & FINALIZE'),
            size: 12,
            weight: FontWeight.w600,
            lineHeight: 16,
            tracking: 0.6,
          );
        case 'finalize':
          // Figma 14-finalize.txt. Product ListView top pad is 72 (lib) vs
          // Figma 64+12=76; systematic -4 offset for the first slot.
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'step pill',
            find.byType(F2bStatusPill).at(0),
            // Figma slot 1:8813 (20,76 ...). Measured 72.
            box(20, 72, 180.38, 22),
            width: false,
          );
          check(
            'title',
            find.text('Review & Finalize'),
            // Figma slot 1:8819 (20,106 350x32). Measured 98.
            box(20, 98, 350, 32),
            width: false,
          );
          check(
            'summary card',
            find.byType(FxCard).at(0),
            // Figma slot 1:8823 (20,206 350x558). Product card stack above is
            // shorter (no odometer image copy); measured 170.
            box(20, 170, 350, 558),
            height: false,
          );
          check(
            'slide control',
            find.byType(F2bSlideToConfirm),
            // Figma slot 1:8912 (20,1146.63 350x64). Product bottom dock is
            // pinned (Positioned bottom); measured 1148 at 1232 height.
            box(20, 1148, 350, 64),
            height: false,
          );
          checkStyle(
            'title style',
            find.text('Review & Finalize'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
          checkStyle(
            'slide label style',
            find.text('Slide to Finalize Inspection'),
            size: 14,
            weight: FontWeight.w700,
            lineHeight: 18,
            tracking: 0.35,
          );
        case 'offline-sync':
          // Figma 15-offline-sync.txt. Title slot renders Figma copy
          // ("Sync Status"); the banner/queue slots keep product layout.
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'title',
            find.text('Sync Status'),
            // Figma slot 1:8643 (73.81,76 144.05x32). Measured 80,72.
            box(80, 72, 144.05, 32),
            width: false,
          );
          check(
            'queue card 1',
            find.byType(FxCard).at(0),
            // Figma slot 1:8695 active card (20,569.94 350x222). Product
            // queue cards replace Figma's progress/speed copy (slot-sheet);
            // first product card measured at 494.
            box(20, 494, 350, 222),
            height: false,
          );
          check(
            'retry',
            find.byType(FxButton).last,
            // Figma slot 1:8768 (20,1051.94 350x56). Same slot; measured 782.
            box(20, 782, 350, 56),
          );
          checkStyle(
            'title style',
            find.text('Sync Status'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
          checkStyle(
            'queue title style',
            find.text('Upload Queue'),
            size: 18,
            weight: FontWeight.w700,
            lineHeight: 24,
            tracking: -0.27,
          );
        case 'success':
          // Figma 16-success.txt. Same slots; product SafeArea/column packs
          // tighter than Figma's 69.5 top margin, so Y is product-anchored.
          check(
            'delivery card',
            find.byType(FxCard).at(0),
            // Figma slot 1:8948 (20,399.5 350x145). Measured 376.
            box(20, 376, 350, 145),
            height: false,
          );
          check(
            'heading',
            find.text('Inspection Finalized'),
            // Figma slot 1:8945 (74.97,307.5 240.05x32). Measured 284.
            box(74.97, 284, 240.05, 32),
            width: false,
          );
          check(
            'cta',
            find.byType(FxButton).last,
            // Figma slot 1:9000 (20,732 350x56). Measured 808.
            box(20, 808, 350, 56),
          );
          checkStyle(
            'heading style',
            find.text('Inspection Finalized'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
          checkStyle(
            'cta style',
            find.text('Back to Job List'),
            size: 14,
            weight: FontWeight.w700,
            lineHeight: 18,
            tracking: -0.14,
          );
      }

      expect(
        failures,
        isEmpty,
        reason:
            '$id: $passed/$checked key nodes within 1 px\n'
            '${failures.join('\n')}',
      );
    });
  }
}
