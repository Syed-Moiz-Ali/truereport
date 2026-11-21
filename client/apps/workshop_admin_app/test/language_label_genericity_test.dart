import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_customer_vehicle.dart';
import 'package:workshop_admin_app/src/features/jobs/job_documents_page.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';
import 'support/job_builders.dart';
import 'support/ui_strings_harness.dart';

List<WorkshopLanguage> _registry() => const <WorkshopLanguage>[
  WorkshopLanguage(
    code: 'en',
    nativeName: 'English',
    direction: 'ltr',
    status: 'LIVE',
    active: true,
  ),
  WorkshopLanguage(
    code: 'es',
    nativeName: 'Español',
    direction: 'ltr',
    status: 'LIVE',
    active: true,
  ),
  WorkshopLanguage(
    code: 'de',
    nativeName: 'Deutsch',
    direction: 'ltr',
    status: 'LIVE',
    active: true,
  ),
];

class _DocumentsApi extends FakeAdminApi {
  _DocumentsApi(this.documents);

  final List<JobDocument> documents;

  @override
  Future<List<JobDocument>> jobDocuments(String jobId) async => documents;
}

JobDocument _document(String id, String language) => JobDocument(
  id: id,
  documentTypeCode: 'REPORT',
  nameEn: 'Inspection report $id',
  nameAr: 'تقرير الفحص $id',
  language: language,
  status: 'READY',
  bytes: 1024,
  generatedAt: '2026-11-21T09:00:00',
  error: null,
  downloadUrl: 'https://reports.test.local/docs/$id',
);

Future<void> _pumpDocuments(
  WidgetTester tester,
  List<JobDocument> documents,
) async {
  tester.view.physicalSize = const Size(1280, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminApiProvider.overrideWithValue(_DocumentsApi(documents)),
        workshopLanguagesProvider.overrideWith((ref) async => _registry()),
        statusesProvider('document')
            .overrideWith((ref) async => const <ReferenceRecord>[]),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) =>
            uiStringsScope(child: child ?? const SizedBox.shrink()),
        theme: AppTheme.light,
        home: const DocumentsPage(jobId: 'job-3'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpJobDetail(
  WidgetTester tester,
  String preferredLanguage, {
  bool registryFails = false,
}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final job = cleanJob(
    overrides: <String, dynamic>{'preferredLanguage': preferredLanguage},
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (registryFails)
          workshopLanguagesProvider.overrideWith(
            (ref) => Future<List<WorkshopLanguage>>.error(
              StateError('registry offline'),
            ),
          )
        else
          workshopLanguagesProvider.overrideWith((ref) async => _registry()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) =>
            uiStringsScope(child: child ?? const SizedBox.shrink()),
        theme: AppTheme.light,
        home: Scaffold(body: JobDetailCustomerVehicle(job: job)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('document language labels', () {
    testWidgets('registry names, unknown codes and blank are honest', (
      tester,
    ) async {
      await _pumpDocuments(tester, <JobDocument>[
        _document('es', 'es'),
        _document('de', 'de'),
        _document('ru', 'ru'),
        _document('blank', ''),
      ]);
      final t = UiStrings.of(tester.element(find.byType(DocumentsPage)));

      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('RU'), findsOneWidget);
      expect(
        find.text(t(WorkshopAdminKeys.commonNotAvailable)),
        findsOneWidget,
      );
      expect(find.text('English'), findsNothing);
    });
  });

  group('preferred language fact', () {
    testWidgets('es renders the registry native name', (tester) async {
      await _pumpJobDetail(tester, 'es');
      final t = UiStrings.of(
        tester.element(find.byType(JobDetailCustomerVehicle)),
      );

      expect(
        find.text(t(WorkshopAdminKeys.jobsFieldPreferredLanguage)),
        findsOneWidget,
      );
      expect(find.text('Español'), findsOneWidget);
    });

    testWidgets('de renders the registry native name', (tester) async {
      await _pumpJobDetail(tester, 'de');

      expect(find.text('Deutsch'), findsOneWidget);
    });

    testWidgets('registry failure falls back to the upper-case code', (
      tester,
    ) async {
      await _pumpJobDetail(tester, 'de', registryFails: true);

      expect(find.text('DE'), findsOneWidget);
    });

    testWidgets('blank preferred language hides the fact', (tester) async {
      await _pumpJobDetail(tester, '');
      final t = UiStrings.of(
        tester.element(find.byType(JobDetailCustomerVehicle)),
      );

      expect(
        find.text(t(WorkshopAdminKeys.jobsFieldPreferredLanguage)),
        findsNothing,
      );
    });
  });
}
