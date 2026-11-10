import 'dart:convert';
import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/f2a_test_fonts.dart';
import 'support/f2a_views.dart';

void main() {
  setUpAll(() async {
    await loadF2AFonts();
  });

  for (final id in f2aScreenIds) {
    testWidgets('$id renders EN/AR at 360/390/600/900 and 1x/1.5x/2x', (
      tester,
    ) async {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        for (final width in const [360.0, 390.0, 600.0, 900.0]) {
          for (final scale in const [1.0, 1.5, 2.0]) {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            await tester.pumpWidget(
              f2aHost(
                child: f2aScreen(id),
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
            child: f2aScreen(id),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('primary technician action is 56 dp', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      f2aHost(
        child: f2aScreen('login'),
        locale: const Locale('en'),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('sign-in-submit'))).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('dock targets are at least 48 dp', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      f2aHost(
        child: f2aScreen('assigned-jobs'),
        locale: const Locale('en'),
        theme: AppTheme.light,
      ),
    );
    await tester.pumpAndSettle();
    final dock = find.byType(FxDock);
    expect(dock, findsOneWidget);
    expect(tester.getSize(dock).height, greaterThanOrEqualTo(48));
  });

  test('source scan: F2-A screens use tokens, not raw colours/sizes/endpoints', () {
    final root = repoRoot();
    const f2aFiles = [
      'jobs/assigned_jobs_view.dart',
      'jobs/consent_view.dart',
      'jobs/empty_jobs_view.dart',
      'jobs/equipment_view.dart',
      'jobs/job_intake_view.dart',
      'inspection/exterior_wireframe_view.dart',
      'inspection/inspection_hub_view.dart',
      'profile/profile_sheet.dart',
    ];
    final files = f2aFiles
        .map(
          (rel) => File(
            '${root.path}/client/apps/technician_app/lib/src/features/$rel',
          ),
        )
        .where((f) => f.existsSync());
    final patterns = <RegExp, String>{
      RegExp(r'https?://'): 'hardcoded URL',
      RegExp(r'/api/'): 'hardcoded API path',
      RegExp(r'fontSize\s*:'): 'raw fontSize',
    };
    final violations = <String>[];
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final entry in patterns.entries) {
        if (entry.key.hasMatch(source)) {
          violations.add('${file.path}: ${entry.value}');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
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
        .toList(growable: false);
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final matches = <String>[];
    for (final id in f2aScreenIds) {
      await tester.pumpWidget(
        f2aHost(
          child: f2aScreen(id, figma: false),
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
        for (final term in terms) {
          final pattern = RegExp(
            '(?<![a-z0-9])${RegExp.escape(term)}(?![a-z0-9])',
            caseSensitive: false,
          );
          if (pattern.hasMatch(text)) {
            matches.add('$term -> $text');
          }
        }
      }
    }
    expect(matches, isEmpty, reason: matches.join('\n'));
  });
}
