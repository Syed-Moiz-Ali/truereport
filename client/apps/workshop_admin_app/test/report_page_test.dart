import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

/// Real `ReportSnapshot` shape: the admin payload has vehicle, coverage,
/// keyFindings, categories and verificationHash. No score, grade, customer or
/// plate is sent, so the certificate must not render one.
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
  snapshotHash: 'sha256:9f2c41ab77',
  content: {
    'vehicle': {
      'make': 'Toyota',
      'model': 'Land Cruiser',
      'year': 2022,
      'vinMasked': 'JTEBU5JR9N*******',
      'odometerValue': 82902,
      'odometerUnit': 'KM',
    },
    'coverage': {'total': 24, 'applicable': 20, 'completed': 20},
    'keyFindings': [
      {
        'labelEn': 'Front brake pads',
        'labelAr': 'أقراص الفرامل الأمامية',
        'resultCode': 'DEFECT_FOUND',
        'severityCode': 'MAJOR',
        'note': 'Pads at 3 mm. Replacement recommended.',
      },
      {
        'labelEn': 'Tyre tread depth',
        'labelAr': 'عمق مداس الإطار',
        'resultCode': 'ATTENTION_RECOMMENDED',
        'severityCode': 'SAFETY_CRITICAL',
        'note': 'Rear axle below 2 mm.',
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
            'resultCode': 'DEFECT_FOUND',
            'severityCode': 'MAJOR',
          },
          {
            'labelEn': 'Rear brake discs',
            'labelAr': 'أقراص الفرامل الخلفية',
            'resultCode': 'NO_ISSUE_OBSERVED',
            'severityCode': 'MINOR',
          },
        ],
      },
      {
        'labelEn': 'Tyres',
        'labelAr': 'الإطارات',
        'items': [
          {
            'labelEn': 'Tyre tread depth',
            'labelAr': 'عمق مداس الإطار',
            'resultCode': 'ATTENTION_RECOMMENDED',
            'severityCode': 'SAFETY_CRITICAL',
          },
          {
            'labelEn': 'Spare tyre',
            'labelAr': 'الإطار الاحتياطي',
            'resultCode': 'NO_ISSUE_OBSERVED',
            'severityCode': 'MINOR',
          },
        ],
      },
    ],
    'verificationHash': 'sha256:9f2c41ab77',
  },
);

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

const _sentDelivery = ReportDelivery(
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
);

const _failedDelivery = ReportDelivery(
  id: 'delivery-2',
  channel: 'SMS',
  recipientMasked: '+9715******42',
  language: 'ar',
  status: 'FAILED',
  attempts: 2,
  maxAttempts: 3,
  pdfAttached: true,
  linkState: 'PENDING_CONSENT',
  lastErrorCode: 'PROVIDER_TIMEOUT',
  lastErrorMessage: 'Provider timed out after 30 seconds.',
  nextAttemptAt: '2026-11-04T11:00:00',
  createdAt: '2026-11-04T10:40:00',
  updatedAt: '2026-11-04T10:41:00',
  attemptHistory: [],
);

class _ReportFakeApi implements AdminApi {
  _ReportFakeApi({
    ReportAdmin Function()? onReport,
    this.deliveryItems = const [_sentDelivery],
  }) : _onReport = onReport ?? (() => _readyReport);

  final ReportAdmin Function() _onReport;
  final List<ReportDelivery> deliveryItems;

  int sendCalls = 0;
  String? lastChannel;
  String? lastLanguage;
  int retryDeliveryCalls = 0;
  int activateCalls = 0;
  int revokeCalls = 0;
  bool? lastPdfDownloadEnabled;

  @override
  Future<ReportAdmin> report(String jobId) async => _onReport();

  @override
  Future<ReportAdmin> retryReport(String jobId) => report(jobId);

  @override
  Future<ReportLinkResult> activateReportLink(String jobId) async {
    activateCalls++;
    return const ReportLinkResult(
      state: 'ACTIVE',
      publicUrl: 'https://reports.test.local/r/token-1',
      pdfDownloadEnabled: false,
    );
  }

  @override
  Future<ReportLinkResult> revokeReportLink(
    String jobId,
    String reasonCode,
    String? note,
  ) async {
    revokeCalls++;
    return const ReportLinkResult(
      state: 'REVOKED',
      publicUrl: null,
      pdfDownloadEnabled: false,
    );
  }

  @override
  Future<ReportLinkResult> setPdfDownload(String jobId, bool enabled) async {
    lastPdfDownloadEnabled = enabled;
    return ReportLinkResult(
      state: 'ACTIVE',
      publicUrl: null,
      pdfDownloadEnabled: enabled,
    );
  }

  @override
  Future<ReportDelivery> sendDelivery(
    String jobId, {
    required String channel,
    required String language,
    required String idempotencyKey,
  }) async {
    sendCalls++;
    lastChannel = channel;
    lastLanguage = language;
    return deliveryItems.first;
  }

  @override
  Future<ReportDelivery> retryDelivery(
    String jobId,
    String deliveryId, {
    required String idempotencyKey,
  }) async {
    retryDeliveryCalls++;
    return deliveryItems.first;
  }

  @override
  Future<List<int>> reportPdf(String jobId) async => const [1, 2, 3];

  @override
  Future<List<ReportDelivery>> deliveries(String jobId) async => deliveryItems;

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
    testWidgets('certificate ${locale.languageCode} phone renders the sheet', (
      tester,
    ) async {
      await _pumpReport(tester, api: _ReportFakeApi(), locale: locale);

      expect(tester.takeException(), isNull);
      expect(find.text('TR-0001'), findsWidgets);
      expect(find.text('v1'), findsOneWidget);
      expect(find.text('20 / 20'), findsOneWidget);
      expect(find.text('Toyota Land Cruiser 2022'), findsOneWidget);
      expect(
        find.text('Pads at 3 mm. Replacement recommended.'),
        findsOneWidget,
      );
      if (locale.languageCode == 'ar') {
        expect(find.text('تقرير فحص المركبة'), findsOneWidget);
        expect(find.text('أقراص الفرامل الأمامية'), findsWidgets);
      } else {
        expect(find.text('Vehicle inspection report'), findsOneWidget);
        expect(find.text('Brakes and suspension'), findsOneWidget);
      }
      // The old joined heading must not survive the rebuild.
      expect(find.text('TR-0001 - v1'), findsNothing);
    });
  }

  testWidgets('certificate 1440 keeps the sheet and stub side by side', (
    tester,
  ) async {
    await _pumpReport(
      tester,
      api: _ReportFakeApi(),
      size: const Size(1440, 1000),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('DISTRIBUTION'), findsOneWidget);
    expect(find.text('20 / 20'), findsOneWidget);
    expect(find.text('Send report'), findsWidgets);
    expect(find.text('JTEBU5JR9N*******'), findsOneWidget);
  });

  testWidgets('certificate 1024 renders both zones without overflow', (
    tester,
  ) async {
    await _pumpReport(
      tester,
      api: _ReportFakeApi(),
      size: const Size(1024, 900),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Vehicle inspection report'), findsOneWidget);
    expect(find.text('Send report'), findsWidgets);
  });

  testWidgets('certificate survives 2.0 text scale on a phone', (tester) async {
    await _pumpReport(
      tester,
      api: _ReportFakeApi(),
      size: const Size(390, 844),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('20 / 20'), findsOneWidget);
    expect(find.text('Report not ready'), findsNothing);
  });

  testWidgets('not-ready report keeps the sheet and drops the stub', (
    tester,
  ) async {
    await _pumpReport(
      tester,
      api: _ReportFakeApi(onReport: () => _pendingReport),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Report not ready'), findsOneWidget);
    expect(find.text('Download PDF'), findsNothing);
    expect(find.text('Send report'), findsNothing);
    final l10n = AppLocalizations.of(tester.element(find.byType(ReportPage)));
    expect(find.text(l10n.generating), findsWidgets);
  });

  testWidgets('failed generation shows the real error and retry', (
    tester,
  ) async {
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
  });

  testWidgets('endpoint error is bounded, retryable and keeps the top bar', (
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
    expect(find.text('Jobs'), findsWidgets);
    expect(find.bySemanticsLabel('Back'), findsWidgets);
  });

  testWidgets('create link is available once consent is granted', (
    tester,
  ) async {
    final api = _ReportFakeApi();
    await _pumpReport(tester, api: api);

    final create = find.text('Create public link');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();

    expect(api.activateCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('send report keeps the channel and language sheet', (
    tester,
  ) async {
    final api = _ReportFakeApi();
    await _pumpReport(tester, api: api);

    final send = find.text('Send report').last;
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(find.text('SMS'), findsOneWidget);
    await tester.tap(find.text('SMS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report').last);
    await tester.pumpAndSettle();

    expect(api.sendCalls, 1);
    expect(api.lastChannel, 'SMS');
    expect(api.lastLanguage, 'en');
  });

  testWidgets('failed delivery offers retry and calls the API', (tester) async {
    final api = _ReportFakeApi(deliveryItems: const [_failedDelivery]);
    await _pumpReport(tester, api: api, size: const Size(1440, 1000));

    final retry = find.text('Retry delivery');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(api.retryDeliveryCalls, 1);
  });

  testWidgets('pdf download toggle is a pill and persists the call', (
    tester,
  ) async {
    final api = _ReportFakeApi();
    await _pumpReport(tester, api: api, size: const Size(1440, 1000));

    final toggle = find.textContaining('PDF download');
    await tester.ensureVisible(toggle.first);
    await tester.tap(toggle.first);
    await tester.pumpAndSettle();

    expect(api.lastPdfDownloadEnabled, isTrue);
  });
}
