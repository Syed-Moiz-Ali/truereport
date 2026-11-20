import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';

import 'support/ui_strings_harness.dart';

import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_sheet.dart';

void main() {
  testWidgets('video sheet states the 15-30 second window before recording', (
    tester,
  ) async {
    EvidenceCaptureRequest? submitted;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        home: Scaffold(
          body: EvidenceCaptureSheet(
            evidenceType: 'VIDEO',
            evidenceTypes: const <ReferenceRecord>[],
            onSubmit: (request) => submitted = request,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Record 15-30 seconds.'), findsOneWidget);
    expect(find.byKey(const Key('evidence-capture-camera')), findsOneWidget);
    expect(find.byKey(const Key('evidence-capture-files')), findsOneWidget);
    expect(
      find.text(
        UiStrings.of(tester.element(find.byType(EvidenceCaptureSheet)))(
          TechnicianKeys.technicianCapturePoster,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('evidence-capture-files')));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.captionEn, isNull);
    expect(submitted!.source, EvidenceSource.file);
  });

  testWidgets('camera choice is tagged CAMERA', (tester) async {
    EvidenceCaptureRequest? submitted;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        home: Scaffold(
          body: EvidenceCaptureSheet(
            evidenceType: 'VIDEO',
            evidenceTypes: const <ReferenceRecord>[],
            onSubmit: (request) => submitted = request,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('evidence-capture-camera')));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.source, EvidenceSource.camera);
  });

  testWidgets(
    'photo sheet states the minimum resolution and offers both sources',
    (tester) async {
      EvidenceCaptureRequest? submitted;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: testLocalizationsDelegates,
          home: Scaffold(
            body: EvidenceCaptureSheet(
              evidenceType: 'PHOTO',
              evidenceTypes: const <ReferenceRecord>[],
              onSubmit: (request) => submitted = request,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Use the camera at 640 x 480 or larger.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('evidence-capture-camera')), findsOneWidget);
      expect(find.byKey(const Key('evidence-capture-files')), findsOneWidget);

      await tester.tap(find.byKey(const Key('evidence-capture-camera')));
      await tester.pump();
      expect(submitted!.source, EvidenceSource.camera);
    },
  );

  testWidgets('document sheet keeps the file picker only', (tester) async {
    EvidenceCaptureRequest? submitted;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        home: Scaffold(
          body: EvidenceCaptureSheet(
            evidenceType: 'DOCUMENT',
            evidenceTypes: const <ReferenceRecord>[],
            onSubmit: (request) => submitted = request,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('evidence-capture-camera')), findsNothing);
    expect(find.byKey(const Key('evidence-capture-files')), findsNothing);
    expect(find.byKey(const Key('evidence-capture-document')), findsOneWidget);

    await tester.tap(find.byKey(const Key('evidence-capture-document')));
    await tester.pump();
    expect(submitted!.source, EvidenceSource.file);
  });
}
