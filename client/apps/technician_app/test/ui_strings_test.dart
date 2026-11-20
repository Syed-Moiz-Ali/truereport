import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';

import 'support/figma_l10n_override.dart';
import 'support/ui_strings_harness.dart';

void main() {
  group('UiStrings', () {
    test('resolves backend keys through the flat bundle', () {
      final strings = baseStrings();

      expect(
        strings(TechnicianKeys.technicianCapturePoster),
        'Capture poster frame',
      );
      expect(strings(TechnicianKeys.technicianAssessmentState), 'Assessment');
    });

    test('formats placeholders and ICU counts with the shared formatter', () {
      final strings = baseStrings();

      expect(
        strings(TechnicianKeys.technicianJobsInQueue, {'count': 3}),
        '3 in queue',
      );
      expect(
        strings(TechnicianKeys.technicianChecksCount, {'done': 2, 'total': 4}),
        '2/4 checks',
      );
    });

    test('unknown keys resolve to an empty string, never to English', () {
      final strings = UiStrings.fromMessages(const <String, String>{});

      expect(strings(TechnicianKeys.technicianAssessmentState), '');
      expect(strings.raw('technician.notAKey'), '');
    });

    test('figma copy overrides backend text and falls back for the rest', () {
      final strings = figmaStringsBundle();

      expect(strings(TechnicianKeys.appTitle), FigmaTestStrings.brand);
      expect(
        strings(TechnicianKeys.technicianJobsInQueue, {'count': 4}),
        '4 In Queue',
      );
      expect(
        strings(TechnicianKeys.technicianAssessmentState),
        'Assessment',
        reason: 'keys outside the override keep the backend copy',
      );
    });

    testWidgets('scope serves the active bundle to descendants', (
      tester,
    ) async {
      late UiStrings resolved;
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: testLocalizationsDelegates,
          home: UiStringsScope(
            strings: figmaStringsBundle(),
            child: Builder(
              builder: (context) {
                resolved = UiStrings.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved(TechnicianKeys.appTitle), FigmaTestStrings.brand);
    });

    testWidgets('missing scope falls back to the backend bundle', (
      tester,
    ) async {
      late UiStrings resolved;
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: testLocalizationsDelegates,
          home: Builder(
            builder: (context) {
              resolved = UiStrings.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved(TechnicianKeys.technicianAssessmentState), 'Assessment');
    });
  });
}
