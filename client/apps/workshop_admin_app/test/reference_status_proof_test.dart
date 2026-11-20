// ignore_for_file: prefer_const_constructors

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_status_badge.dart';

import 'support/ui_strings_harness.dart';

void main() {
  testWidgets(
    'job badge renders the backend status record, not the local map',
    (tester) async {
      final referenceLabel = remoteEnglish('statusCancelled');
      expect(referenceLabel, isNotEmpty);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statusesProvider('job').overrideWith(
              (ref) async => const <ReferenceRecord>[
                ReferenceRecord(
                  code: 'ASSIGNED',
                  labelKey: 'statusCancelled',
                  tone: 'danger',
                ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.build(),
            locale: const Locale('en'),
            supportedLocales: const <Locale>[Locale('en')],
            localizationsDelegates: testLocalizationsDelegates,
            builder: (context, child) =>
                uiStringsScope(child: child ?? const SizedBox.shrink()),
            home: Scaffold(
              body: Center(child: JobStatusBadge(status: 'ASSIGNED')),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(referenceLabel), findsOneWidget);
      expect(find.text(remoteEnglish('statusAssigned')), findsNothing);
    },
  );

  testWidgets('job badge humanizes a code the taxonomy does not serve', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statusesProvider('job')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          locale: const Locale('en'),
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: testLocalizationsDelegates,
          builder: (context, child) =>
              uiStringsScope(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
            body: Center(child: JobStatusBadge(status: 'ASSIGNED')),
          ),
        ),
      ),
    );
    await tester.pump();

    // No local map: the code is humanized, never looked up in a table.
    expect(find.text('Assigned'), findsOneWidget);
  });
}
