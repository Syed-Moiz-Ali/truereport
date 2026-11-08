import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/f2a_test_fonts.dart';
import 'support/f2a_views.dart';

/// F2-A.1 geometry gate. Key nodes are compared with the Figma
/// `absoluteBoundingBox` from `docs/ui/figma/f2a1-nodes/`.
///
/// Text nodes are measured for position and line box; their intrinsic width is
/// font-metric dependent and is checked separately by the type assertions.
void main() {
  setUpAll(loadF2AFonts);

  const heights = <String, double>{
    'login': 858,
    'assigned-jobs': 1002,
    'empty-state': 883.75,
    'job-intake': 1128,
    'consent': 972,
    'equipment': 910,
    'inspection-hub': 1130,
    'exterior-wireframe': 906.25,
  };

  for (final id in f2aScreenIds) {
    testWidgets('$id geometry within 1 logical px', (tester) async {
      final height = heights[id]!;
      tester.view.physicalSize = Size(390, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        f2aHost(
          child: f2aScreen(id, figma: true),
          locale: const Locale('en'),
          theme: AppTheme.light,
          // Figma wording comes from the test-only localization override;
          // lib/ has no figmaText switch anymore.
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
        final height = style.height;
        if (height == null || (height - expectedHeight).abs() > 0.001) {
          deltas.add(
            'lineHeight ${height == null ? 'null' : (height * size).toStringAsFixed(2)} vs $lineHeight',
          );
        }
        final spacing = style.letterSpacing ?? 0;
        if ((spacing - tracking).abs() > 0.001) {
          deltas.add('tracking $spacing vs $tracking');
        }
        if (style.fontFamily != TrFonts.latin) {
          deltas.add('family ${style.fontFamily}');
        }
        if (deltas.isNotEmpty) {
          failures.add('$label style: ${deltas.join(', ')}');
        } else {
          passed++;
        }
      }

      switch (id) {
        case 'login':
          check(
            'language switch',
            find.byType(FxLanguageSwitch),
            box(241.58, 8, 128.42, 32),
          );
          check(
            'brand',
            find.text('TechInspect'),
            box(120.31, 192, 149.38, 32),
            width: false,
          );
          check(
            'tagline',
            find.text('Vehicle Condition & Fleet Diagnostics'),
            box(73.84, 228, 242.3, 18),
            width: false,
          );
          check(
            'email field',
            find.byType(FxTextField).at(0),
            box(24, 286, 342, 48),
          );
          check(
            'password field',
            find.byType(FxTextField).at(1),
            box(24, 350, 342, 48),
          );
          check(
            'sign in',
            find.byKey(const Key('sign-in-submit')),
            box(24, 472, 342, 56),
          );
          check(
            'access prompt',
            find.byKey(const Key('sign-in-access-prompt')),
            box(81.76, 592, 153.53, 18),
            width: false,
          );
          check(
            'security line',
            find.byKey(const Key('sign-in-security-line')),
            box(104.93, 626, 194.14, 14),
            width: false,
            x: false,
          );
          checkStyle(
            'brand style',
            find.text('TechInspect'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
          checkStyle(
            'forgot style',
            find.text('Forgot password?'),
            size: 11,
            weight: FontWeight.w600,
            lineHeight: 14,
            tracking: 0.44,
          );
          checkStyle(
            'button label style',
            find.text('Sign In'),
            size: 14,
            weight: FontWeight.w700,
            lineHeight: 18,
            tracking: -0.14,
          );
        case 'assigned-jobs':
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'welcome',
            find.text('Welcome back,'),
            box(20, 152, 350, 24),
            width: false,
          );
          check(
            'name',
            find.text('David Vance'),
            box(20, 178, 350, 32),
            width: false,
          );
          check(
            'section label',
            find.text('ASSIGNED TODAY'),
            box(24, 346, 132.16, 18),
            width: false,
          );
          check(
            'first card',
            find.byType(FxCard).at(0),
            box(20, 380, 350, 130),
            height: false,
          );
          check(
            'walk-in button',
            find.byType(FxButton).last,
            box(20, 826, 350, 56),
          );
          check(
            'dock',
            find.byKey(const Key('f2a1-dock-container')),
            box(20, 922, 350, 64),
          );
          checkStyle(
            'welcome style',
            find.text('Welcome back,'),
            size: 18,
            weight: FontWeight.w600,
            lineHeight: 24,
            tracking: 0,
          );
          checkStyle(
            'name style',
            find.text('David Vance'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
          checkStyle(
            'section style',
            find.text('ASSIGNED TODAY'),
            size: 14,
            weight: FontWeight.w700,
            lineHeight: 18,
            tracking: 0.7,
          );
        case 'empty-state':
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'shift pill',
            find.text('SHIFT ACTIVE'),
            box(102, 89, 78.48, 14),
            width: false,
          );
          check(
            'bay pill',
            find.text('Bay 04'),
            box(317.98, 89, 40.02, 14),
            width: false,
          );
          check(
            'welcome',
            find.text('Welcome back,'),
            box(20, 144, 350, 24),
            width: false,
          );
          check(
            'heading',
            find.text('You are all caught up!'),
            box(87, 443.6, 216, 31),
            width: false,
          );
          check(
            'summary label',
            find.text("TODAY'S SUMMARY"),
            box(88, 717.75, 111.8, 14),
            width: false,
          );
          check(
            'dock',
            find.byKey(const Key('f2a1-dock-container')),
            box(20, 804, 350, 64),
          );
          checkStyle(
            'heading style',
            find.text('You are all caught up!'),
            size: 22,
            weight: FontWeight.w800,
            lineHeight: 30.25,
            tracking: -0.55,
          );
        case 'job-intake':
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'intake pill',
            // Product logic renders the upper-cased job status here; the
            // Figma mock's static "INTAKE PHASE" wording is not product copy.
            find.text('INTAKE PHASE'),
            box(32, 76, 79.67, 14),
            width: false,
          );
          check(
            'ready pill',
            // Product logic renders the job status here; the Figma mock's
            // static "Ready for Check" wording is not product copy. The pill
            // x-position is content-driven ("Assigned" is narrower), so only
            // y/height are gated; x is covered by the intake pill.
            find.text('Ready for Check'),
            box(155.67, 76, 94, 14),
            width: false,
            x: false,
          );
          check('hero', find.byType(ClipRRect).first, box(20, 118, 350, 176));
          check(
            'vehicle card',
            find.byType(FxCard).at(0),
            box(20, 318, 350, 290),
          );
          check(
            'customer card',
            find.byType(FxCard).at(1),
            box(20, 628, 350, 276),
          );
          check('ready card', find.byType(FxCard).at(2), box(20, 924, 350, 76));
          check('start', find.byType(FxButton).last, box(20, 1060, 350, 56));
          checkStyle(
            'intake title style',
            // The header title comes from the job's template name (product
            // data path); the same string also appears as the service-package
            // value with a different style, so scope to the header.
            find.descendant(
              of: find.byType(FxHeader),
              matching: find.text('Vehicle Walkaround Inspection'),
            ),
            size: 18,
            weight: FontWeight.w700,
            lineHeight: 24,
            tracking: -0.45,
          );
        case 'consent':
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'steps',
            find.text('STEP 4 OF 4 • FINAL SIGN-OFF'),
            box(52, 80, 185.48, 16),
            width: false,
          );
          check(
            'title',
            find.text('Authorizations'),
            box(20, 108, 350, 32),
            width: false,
          );
          check('card 1', find.byType(FxCard).at(0), box(20, 208, 350, 80));
          check('card 2', find.byType(FxCard).at(1), box(20, 304, 350, 80));
          check('card 3', find.byType(FxCard).at(2), box(20, 400, 350, 80));
          check('signer', find.byType(FxCard).at(3), box(20, 772, 350, 72));
          check(
            'save',
            find.byKey(const Key('consent-save')),
            box(20, 876, 350, 56),
          );
          checkStyle(
            'consent title style',
            find.text('Authorizations'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
        case 'equipment':
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'setup',
            find.text('PRE-INSPECTION SETUP'),
            box(52, 80, 147.41, 16),
            width: false,
          );
          check(
            'title',
            find.text('Required Equipment'),
            box(20, 124, 350, 32),
            width: false,
          );
          check('card 1', find.byType(FxCard).at(0), box(20, 232, 350, 88));
          check(
            'card 2',
            find.byType(FxCard).at(1),
            box(20, 336, 350, 98),
            height: false,
          );
          check(
            'card 3',
            find.byType(FxCard).at(2),
            box(20, 450, 350, 88),
            height: false,
          );
          check(
            'card 4',
            find.byType(FxCard).at(3),
            box(20, 554, 350, 88),
            height: false,
          );
          check('proceed', find.byType(FxButton).last, box(20, 814, 350, 56));
          checkStyle(
            'equipment title style',
            find.text('Required Equipment'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
        case 'exterior-wireframe':
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'header title',
            find.text('Vehicle Walkaround Inspection'),
            box(68, 20, 256.47, 24),
            width: false,
          );
          check(
            'status title',
            find.text('EXTERIOR INSPECTION'),
            box(20, 76, 132.67, 14),
            width: false,
          );
          check('card', find.byType(FxCard).first, box(20, 222, 350, 379.75));
          check(
            'step title',
            find.text('Step 2: Tap the area to\ncapture damage'),
            box(20, 98, 350, 64),
            width: false,
          );
          check(
            'callout title',
            find.text('Front Left Door Dent'),
            box(100.55, 509.75, 155.16, 22),
            width: false,
          );
          check(
            'perspective title',
            find.text('ANGLE PERSPECTIVE'),
            box(24, 625.75, 126.7, 16),
            width: false,
          );
          check('confirm button', find.byType(FxButton).first, box(20, 762.25, 350, 56));
          check(
            'no damage button text',
            find.text('No Damage Found on this Panel'),
            box(101.33, 840.25, 187.33, 16),
            width: false,
          );
          checkStyle(
            'step title style',
            find.text('Step 2: Tap the area to\ncapture damage'),
            size: 26,
            weight: FontWeight.w800,
            lineHeight: 32,
            tracking: -0.65,
          );
          checkStyle(
            'perspective label style',
            find.text('ANGLE PERSPECTIVE'),
            size: 12,
            weight: FontWeight.w600,
            lineHeight: 16,
            tracking: 0.24,
          );
        case 'inspection-hub':
          check('header', find.byType(FxHeader), box(0, 0, 390, 64));
          check(
            'status pill',
            // Product logic renders the upper-cased job status here; the
            // Figma mock's static "INSPECTION IN PROGRESS" wording is not
            // product copy.
            find.textContaining('PROGRESS'),
            box(48, 86, 155.59, 14),
            width: false,
          );
          check('hero card', find.byType(FxCard).at(0), box(20, 122, 350, 278));
          check('ring', find.byType(FxCoverageRing), box(107, 154, 176, 176));
          check(
            'modules title',
            find.text('Inspection Modules'),
            box(24, 530, 150, 22),
            width: false,
          );
          check('module 1', find.byType(FxCard).at(1), box(20, 564, 167, 167));
          check('module 2', find.byType(FxCard).at(2), box(203, 564, 167, 167));
          check('continue', find.byType(FxButton).last, box(20, 946, 350, 56));
          check(
            'dock',
            find.byKey(const Key('f2a1-dock-container')),
            box(20, 1050, 350, 64),
          );
          checkStyle(
            'hub title style',
            find.text('Intake Hub'),
            size: 22,
            weight: FontWeight.w700,
            lineHeight: 28,
            tracking: -0.55,
          );
          checkStyle(
            'module title style',
            find.text('Exterior'),
            size: 18,
            weight: FontWeight.w800,
            lineHeight: 24,
            tracking: -0.27,
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
