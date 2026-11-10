import 'dart:convert';
import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/shared/technician_kit.dart';

import 'support/f2a_test_fonts.dart';
import 'support/f2b_views.dart';
import 'support/f2a_fidelity_harness.dart';

void main() {
  setUpAll(() async {
    await loadF2AFonts();
  });

  for (final id in f2bScreenIds) {
    testWidgets('$id renders EN/AR at 360/390/600/900 and 1x/1.5x/2x', (
      tester,
    ) async {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        for (final width in const [360.0, 390.0, 600.0, 900.0]) {
          for (final scale in const [1.0, 1.5, 2.0]) {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            await tester.pumpWidget(
              f2bHost(
                child: f2bScreen(id, figma: false),
                locale: locale,
                theme: AppTheme.build(isArabic: locale.languageCode == 'ar'),
                textScale: scale,
              ),
            );
            await tester.pump(const Duration(milliseconds: 50));
            expect(
              tester.takeException(),
              isNull,
              reason: '$id $locale ${width}px ${scale}x',
            );
          }
        }
      }
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('$id renders with reduce motion', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 900),
              disableAnimations: true,
            ),
            child: f2bScreen(id, figma: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });

    testWidgets('$id focus traversal moves without exception', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        f2bHost(
          child: f2bScreen(id, figma: false),
          locale: const Locale('en'),
          theme: AppTheme.light,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      // Tab through the first few focus scopes; screens expose semantic
      // buttons (segmented options, chips, slide thumb) so traversal must not
      // throw even when nothing has focus yet.
      for (var i = 0; i < 5; i++) {
        FocusScope.of(tester.element(find.byType(MaterialApp))).nextFocus();
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.takeException(), isNull, reason: '$id focus traversal');
    });

    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets('$id golden-ready ${locale.languageCode} light', (
        tester,
      ) async {
        // Golden readiness: light-only EN+AR render with real shadows. PNG
        // masters live under test/goldens/ and are approved separately via
        // --update-goldens; this gate pins the render path (shadows enabled,
        // 390 width, light theme) without committing binary masters here.
        final previous = enableFidelityShadows();
        try {
          tester.view.physicalSize = Size(390, f2bHeights[id]!);
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          await tester.pumpWidget(
            f2bHost(
              child: f2bScreen(id, figma: false),
              locale: locale,
              theme: AppTheme.build(isArabic: locale.languageCode == 'ar'),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          assertFidelityShadows();
          expect(tester.takeException(), isNull);
        } finally {
          restoreFidelityShadows(previous);
        }
      });
    }
  }

  testWidgets('primary actions meet minimum heights', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // Defect-detail save is a 56 dp FxButton (Figma slot 1:8130).
    await tester.pumpWidget(
      f2bHost(
        child: f2bScreen('defect-detail', figma: false),
        locale: const Locale('en'),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FxButton), findsWidgets);
    expect(
      tester.getSize(find.byType(FxButton).last).height,
      greaterThanOrEqualTo(56),
    );
    // Finalize confirm is the 64 dp slide control (Figma slot 1:8912).
    await tester.pumpWidget(
      f2bHost(
        child: f2bScreen('finalize', figma: false),
        locale: const Locale('en'),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(F2bSlideToConfirm), findsOneWidget);
    expect(
      tester.getSize(find.byType(F2bSlideToConfirm)).height,
      greaterThanOrEqualTo(56),
    );
  });

  test('slide control duration is documented (reduce-motion gap)', () {
    // F2-B.1 L8 slot-sheet: the slide thumb uses a hardcoded
    // `Duration(milliseconds: 120)` in lib/src/shared/technician_kit.dart
    // (AnimatedPositioned) instead of ReduceMotion.duration. Screens still
    // render with disableAnimations:true (see reduce-motion tests above), but
    // the thumb snap-back animation is NOT reduced. lib/ cannot be edited by
    // this workstream; documenting here so the owner can switch to
    // ReduceMotion.duration(context, const Duration(milliseconds: 120)).
    var dir = Directory.current;
    for (var i = 0; i < 12; i++) {
      final candidate = File(
        '${dir.path}/lib/src/shared/technician_kit.dart',
      );
      if (candidate.existsSync()) {
        final source = candidate.readAsStringSync();
        expect(
          source.contains('Duration(milliseconds: 120)'),
          isTrue,
          reason:
              'documents hardcoded 120ms slide duration in f2b_kit.dart '
              '(reduce-motion gap, see comment)',
        );
        expect(
          source.contains('ReduceMotion'),
          isFalse,
          reason:
              'f2b_kit.dart does not honour ReduceMotion yet (documented gap)',
        );
        return;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    fail('could not locate lib/src/shared/technician_kit.dart');
  });

  testWidgets('product fixtures contain no forbidden terms', (tester) async {
    final root = repoRoot();
    final deny = jsonDecode(
      File(
        '${root.path}/docs/ui/figma/fidelity/forbidden-terms-technician-product.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final terms = (deny['terms'] as List<dynamic>)
        .cast<String>()
        .map((term) => term.toLowerCase())
        // F2-B exception: `technicianQueued` ("Queued") is legitimate ARB
        // product copy for pending sync operations (OfflineSyncView renders it
        // for every non-conflict op). The F2-A list targets Figma-only wording;
        // in F2-A no product screen renders that key.
        .where((term) => term != 'queued')
        .toList(growable: false);
    // Precompile one pattern per term (mirrors f2a_screens_test.dart).
    final patterns = terms
        .map(
          (term) => MapEntry(
            term,
            RegExp(
              '(?<![a-z0-9])${RegExp.escape(term)}(?![a-z0-9])',
              caseSensitive: false,
            ),
          ),
        )
        .toList(growable: false);
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final matches = <String>[];
    for (final id in f2bScreenIds) {
      await tester.pumpWidget(
        f2bHost(
          child: f2bScreen(id, figma: false),
          locale: const Locale('en'),
          theme: AppTheme.light,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final strings = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>();
      for (final text in strings) {
        for (final entry in patterns) {
          if (entry.value.hasMatch(text)) {
            matches.add('${entry.key} -> $text');
          }
        }
      }
    }
    expect(matches, isEmpty, reason: matches.join('\n'));
  });
}
