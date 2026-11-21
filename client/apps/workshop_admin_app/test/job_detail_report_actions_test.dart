import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_review_publication.dart';
import 'package:workshop_admin_app/src/features/jobs/job_documents_page.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';
import 'support/job_builders.dart';
import 'support/ui_strings_harness.dart';

CleanJob _job() => cleanJob(
  overrides: <String, dynamic>{
    'id': 'job-3',
    'status': 'PUBLISHED',
    'reviewStatus': 'APPROVED',
    'publicationStatus': 'ACTIVE',
    'preferredLanguage': 'es',
  },
);

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(1280, 900),
  FakeAdminApi? api,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        adminApiProvider.overrideWithValue(api ?? FakeAdminApi()),
        statusesProvider('review')
            .overrideWith((ref) async => const <ReferenceRecord>[]),
        statusesProvider('publication')
            .overrideWith((ref) async => const <ReferenceRecord>[]),
        statusesProvider('consent')
            .overrideWith((ref) async => const <ReferenceRecord>[]),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) =>
            uiStringsScope(child: child ?? const SizedBox.shrink()),
        theme: AppTheme.light,
        home: Scaffold(body: JobDetailReviewPublication(job: _job())),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('Report opens ReportPage with the job language', (tester) async {
    await _pump(tester);
    final t = UiStrings.of(
      tester.element(find.byType(JobDetailReviewPublication)),
    );
    expect(find.text(t(WorkshopAdminKeys.report)), findsOneWidget);

    await tester.tap(find.byKey(const Key('job-detail-report-action')));
    await tester.pumpAndSettle();

    final page = tester.widget<ReportPage>(find.byType(ReportPage));
    expect(page.jobId, 'job-3');
    expect(page.preferredLanguage, 'es');
  });

  testWidgets('Documents opens DocumentsPage with the same job id', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('job-detail-documents-action')));
    await tester.pumpAndSettle();

    final page = tester.widget<DocumentsPage>(find.byType(DocumentsPage));
    expect(page.jobId, 'job-3');
  });

  testWidgets('action row stacks without overflow at 390', (tester) async {
    await _pump(tester, size: const Size(390, 844));

    final report = tester.getRect(
      find.byKey(const Key('job-detail-report-action')),
    );
    final documents = tester.getRect(
      find.byKey(const Key('job-detail-documents-action')),
    );

    expect(tester.takeException(), isNull);
    expect(documents.top, greaterThan(report.top));
    expect(report.width, greaterThan(300));
    expect(documents.width, closeTo(report.width, 0.5));
  });
}
