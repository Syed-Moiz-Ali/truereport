import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

const _readyReport = ReportAdmin(
  reportId: 'report-1',
  jobId: 'job-1',
  reportNumber: 'TR-0001',
  version: 1,
  generationStatus: 'READY',
  generationError: null,
  attempts: 1,
  reportReady: true,
  pdfReady: true,
  pdfDownloadEnabled: false,
  linkState: 'PENDING_CONSENT',
  consentState: 'GRANTED',
  publicUrl: null,
  finalizedAt: '2026-11-04T10:30:00',
  snapshotHash: 'abc123',
  content: {
    'vehicle': {
      'make': 'Toyota',
      'model': 'Land Cruiser',
      'odometer': '82,902 KM',
      'plate': 'D-12345',
    },
    'coverage': {'completed': 20, 'applicable': 20},
    'keyFindings': [
      {
        'labelEn': 'Front brake pads',
        'labelAr': 'أقراص الفرامل الأمامية',
        'note': 'Pads at 3 mm. Replacement recommended.',
      },
    ],
    'categories': [
      {
        'labelEn': 'Brakes and suspension',
        'labelAr': 'الفرامل والتعليق',
        'items': [
          {
            'labelEn': 'Front brake pads',
            'labelAr': 'أقراص الفرامل الأمامية',
            'resultEn': 'Defect found',
            'resultAr': 'تم رصد عيب',
            'severityEn': 'Major',
            'severityAr': 'كبير',
          },
        ],
      },
    ],
  },
);

/// A report that has not been generated yet: the page must show the designed
/// empty state and no download action.
const _pendingReport = ReportAdmin(
  reportId: 'report-1',
  jobId: 'job-1',
  reportNumber: 'TR-0001',
  version: 1,
  generationStatus: 'PENDING',
  generationError: null,
  attempts: 0,
  reportReady: false,
  pdfReady: false,
  pdfDownloadEnabled: false,
  linkState: 'PENDING_CONSENT',
  consentState: 'GRANTED',
  publicUrl: null,
  finalizedAt: '',
  snapshotHash: '',
  content: null,
);

/// A report whose generation failed: the page shows the real generation error
/// plus Retry, and never a download action.
const _failedReport = ReportAdmin(
  reportId: 'report-1',
  jobId: 'job-1',
  reportNumber: 'TR-0001',
  version: 1,
  generationStatus: 'FAILED',
  generationError: 'Publishing failed: missing customer signature.',
  attempts: 2,
  reportReady: false,
  pdfReady: false,
  pdfDownloadEnabled: false,
  linkState: 'PENDING_CONSENT',
  consentState: 'GRANTED',
  publicUrl: null,
  finalizedAt: '',
  snapshotHash: '',
  content: null,
);

class _ReportFakeApi implements AdminApi {
  _ReportFakeApi({ReportAdmin Function()? onReport})
    : _onReport = onReport ?? (() => _readyReport);

  final ReportAdmin Function() _onReport;

  @override
  Future<ReportAdmin> report(String jobId) async => _onReport();

  @override
  Future<ReportAdmin> retryReport(String jobId) => report(jobId);

  @override
  Future<ReportLinkResult> activateReportLink(String jobId) async =>
      const ReportLinkResult(
        state: 'ACTIVE',
        publicUrl: 'http://localhost:8080/r/test-token',
        pdfDownloadEnabled: false,
      );

  @override
  Future<ReportLinkResult> revokeReportLink(
    String jobId,
    String reasonCode,
    String? note,
  ) async => const ReportLinkResult(
    state: 'REVOKED',
    publicUrl: null,
    pdfDownloadEnabled: false,
  );

  @override
  Future<ReportLinkResult> setPdfDownload(String jobId, bool enabled) async =>
      ReportLinkResult(
        state: 'ACTIVE',
        publicUrl: null,
        pdfDownloadEnabled: enabled,
      );

  @override
  Future<List<int>> reportPdf(String jobId) async => const [1, 2, 3];

  @override
  Future<List<ReportDelivery>> deliveries(String jobId) async => const [
    ReportDelivery(
      id: 'delivery-1',
      channel: 'EMAIL',
      recipientMasked: 'p***@example.test',
      language: 'en',
      status: 'SENT',
      attempts: 1,
      maxAttempts: 3,
      pdfAttached: true,
      linkState: 'ACTIVE',
      lastErrorCode: null,
      lastErrorMessage: null,
      nextAttemptAt: '',
      createdAt: '2026-11-04T10:35:00',
      updatedAt: '2026-11-04T10:35:00',
      attemptHistory: [
        ReportDeliveryAttempt(
          attemptNo: 1,
          provider: 'fake',
          status: 'SENT',
          errorCode: null,
          errorMessage: null,
          sentAt: '2026-11-04T10:35:00',
          deliveredAt: '',
        ),
      ],
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pumpReport(
  WidgetTester tester, {
  required _ReportFakeApi api,
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1,
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
        theme: buildAppTheme(isArabic: locale.languageCode == 'ar'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const ReportPage(jobId: 'job-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('report page ${locale.languageCode} phone renders ready report '
        'without overflow', (tester) async {
      await _pumpReport(tester, api: _ReportFakeApi(), locale: locale);

      expect(tester.takeException(), isNull);
      expect(find.text('TR-0001 - v1'), findsOneWidget);
      expect(
        find.text(
          AppLocalizations.of(tester.element(find.byType(ReportPage)))
              .reportReady,
        ),
        findsWidgets,
      );
      expect(find.text('Toyota'), findsOneWidget);
      expect(find.text('Land Cruiser'), findsOneWidget);
      expect(
        find.text('Pads at 3 mm. Replacement recommended.'),
        findsOneWidget,
      );
      if (locale.languageCode == 'ar') {
        expect(find.text('أقراص الفرامل الأمامية'), findsWidgets);
      }
    });
  }

  testWidgets('report page 1280 desktop renders the ready report', (
    tester,
  ) async {
    await _pumpReport(
      tester,
      api: _ReportFakeApi(),
      size: const Size(1280, 900),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('TR-0001 - v1'), findsOneWidget);
    expect(
      find.text(
        AppLocalizations.of(tester.element(find.byType(ReportPage)))
            .reportReady,
      ),
      findsWidgets,
    );
    expect(find.text('Toyota'), findsOneWidget);
    expect(find.text('20 / 20'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
  });

  testWidgets('report page survives 2.0 text scale on a phone', (tester) async {
    await _pumpReport(
      tester,
      api: _ReportFakeApi(),
      size: const Size(390, 844),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('TR-0001 - v1'), findsOneWidget);
    expect(find.text('Report not ready'), findsNothing);
  });

  testWidgets('report page shows designed not-ready state with no download', (
    tester,
  ) async {
    await _pumpReport(
      tester,
      api: _ReportFakeApi(onReport: () => _pendingReport),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Report not ready'), findsOneWidget);
    expect(find.text('Download PDF'), findsNothing);
    expect(find.text('TR-0001 - v1'), findsOneWidget);
    final l10n = AppLocalizations.of(tester.element(find.byType(ReportPage)));
    expect(find.text(l10n.generating), findsWidgets);
  });

  testWidgets(
    'report page shows a failed generation with real error and retry',
    (tester) async {
      await _pumpReport(
        tester,
        api: _ReportFakeApi(onReport: () => _failedReport),
      );

      expect(tester.takeException(), isNull);
      final l10n = AppLocalizations.of(tester.element(find.byType(ReportPage)));
      expect(find.text(l10n.reportFailed), findsWidgets);
      expect(
        find.text('Publishing failed: missing customer signature.'),
        findsOneWidget,
      );
      expect(find.text('Retry report'), findsOneWidget);
      expect(find.text('Download PDF'), findsNothing);
    },
  );

  testWidgets('report page shows bounded error, retry and keeps the top bar', (
    tester,
  ) async {
    await _pumpReport(
      tester,
      api: _ReportFakeApi(
        onReport: () => throw StateError('report endpoint offline'),
      ),
    );

    expect(find.byType(WorkshopErrorState), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Report'), findsWidgets);
    expect(find.bySemanticsLabel('Back'), findsWidgets);
  });
}
