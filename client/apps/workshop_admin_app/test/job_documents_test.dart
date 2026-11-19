import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_documents_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';

const _downloadUrl = '/documents/doc-1/content';

List<JobDocument> _documents() => const [
  JobDocument(
    id: 'doc-1',
    documentTypeCode: 'INSPECTION_REPORT',
    nameEn: 'Inspection report',
    nameAr: 'تقرير الفحص',
    language: 'en',
    status: 'READY',
    bytes: 20480,
    generatedAt: null,
    error: null,
    downloadUrl: _downloadUrl,
  ),
  JobDocument(
    id: 'doc-2',
    documentTypeCode: 'INSPECTION_REPORT',
    nameEn: 'Inspection report',
    nameAr: 'تقرير الفحص',
    language: 'ar',
    status: 'FAILED',
    bytes: null,
    generatedAt: null,
    error: 'Arabic font shaping failed',
    downloadUrl: null,
  ),
  JobDocument(
    id: 'doc-3',
    documentTypeCode: 'INSPECTION_REPORT',
    nameEn: 'Inspection report',
    nameAr: 'تقرير الفحص',
    language: 'en',
    status: 'GENERATING',
    bytes: null,
    generatedAt: null,
    error: null,
    downloadUrl: null,
  ),
];

class _DocsApi extends FakeAdminApi {
  _DocsApi(this.documents);

  List<JobDocument> documents;
  final retriedTypes = <String>[];

  @override
  Future<List<JobDocument>> jobDocuments(String jobId) async =>
      List<JobDocument>.unmodifiable(documents);

  @override
  Future<List<JobDocument>> retryJobDocument(String jobId, String type) async {
    retriedTypes.add(type);
    documents = [
      for (final document in documents)
        if (document.documentTypeCode == type)
          JobDocument(
            id: document.id,
            documentTypeCode: document.documentTypeCode,
            nameEn: document.nameEn,
            nameAr: document.nameAr,
            language: document.language,
            status: 'PENDING',
            bytes: document.bytes,
            generatedAt: document.generatedAt,
            error: null,
            downloadUrl: document.downloadUrl,
          )
        else
          document,
    ];
    return jobDocuments(jobId);
  }
}

Future<void> _pump(
  WidgetTester tester,
  AdminApi api, {
  Size size = const Size(1280, 1000),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: const DocumentsPage(jobId: 'job-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(DocumentsPage)));

void main() {
  testWidgets('documents use localized status labels, never raw enums', (
    tester,
  ) async {
    await _pump(tester, _DocsApi(_documents()));
    final l10n = _l10n(tester);

    expect(find.text(l10n.reportReady), findsOneWidget);
    expect(find.text(l10n.reportFailed), findsOneWidget);
    expect(find.text(l10n.generating), findsOneWidget);
    expect(find.text('READY'), findsNothing);
    expect(find.text('FAILED'), findsNothing);
    expect(find.text('GENERATING'), findsNothing);
  });

  testWidgets('a null size reads an em dash, not zero bytes', (tester) async {
    await _pump(tester, _DocsApi(_documents()));

    expect(find.text('20,480 B'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('0 B'), findsNothing);
  });

  testWidgets('copy link copies the relative content URL', (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await _pump(tester, _DocsApi(_documents()));
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const Key('jobs-copy-document-doc-1')));
    await tester.pumpAndSettle();

    final copied = calls.where((call) => call.method == 'Clipboard.setData');
    expect(copied, hasLength(1));
    expect((copied.single.arguments as Map)['text'], _downloadUrl);
    expect(find.text(l10n.linkCopied), findsOneWidget);
  });

  testWidgets('retry sends the document type and refreshes the row', (
    tester,
  ) async {
    final api = _DocsApi(_documents());
    await _pump(tester, api);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const Key('jobs-retry-document-doc-2')));
    await tester.pumpAndSettle();

    // Retry is by document type, so every row of that type is queued again.
    expect(api.retriedTypes, ['INSPECTION_REPORT']);
    expect(find.text(l10n.jobsDocumentRetried), findsOneWidget);
    expect(find.text(l10n.reportFailed), findsNothing);
    expect(find.text(l10n.technicianQueued), findsNWidgets(3));
  });

  testWidgets('empty state says documents are generated after publish', (
    tester,
  ) async {
    await _pump(tester, _DocsApi(const []));
    final l10n = _l10n(tester);

    expect(find.text(l10n.jobsDocumentsEmpty), findsOneWidget);
    expect(find.text(l10n.jobsDocsGeneratedAfterPublish), findsOneWidget);
    expect(find.byKey(const Key('jobs-retry-document-doc-2')), findsNothing);
  });

  testWidgets('documents render at 390 in Arabic without overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      _DocsApi(_documents()),
      size: const Size(390, 1400),
      locale: const Locale('ar'),
    );
    expect(find.text('20,480 B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
