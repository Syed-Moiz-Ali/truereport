import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/report_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

class _ReportFakeApi implements AdminApi {
  @override
  Future<ReportAdmin> report(String jobId) async => const ReportAdmin(
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
      },
      'coverage': {'completed': 20, 'applicable': 20},
      'keyFindings': [
        {
          'labelEn': 'Full vehicle safety check',
          'note': 'Visible wear on the component with a long note that wraps on a narrow telephone screen.',
        },
      ],
      'categories': [
        {
          'labelEn': 'Brakes and suspension',
          'items': [
            {
              'labelEn': 'Full vehicle safety check',
              'resultEn': 'Defect found',
              'severityEn': 'Major',
            },
          ],
        },
      ],
    },
  );

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

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('report page ${locale.languageCode} phone has no overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminApiProvider.overrideWithValue(_ReportFakeApi())],
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: buildAppTheme(),
            home: const ReportPage(jobId: 'job-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('TR-0001 - v1'), findsOneWidget);
      expect(find.text('READY'), findsWidgets);
    });
  }
}
