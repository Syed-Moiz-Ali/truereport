import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/reports/report_language_options.dart';
import 'package:workshop_admin_app/src/features/reports/report_page.dart';
import 'package:workshop_admin_app/src/models.dart';

import 'support/fake_admin_api.dart';
import 'support/ui_strings_harness.dart';

UiMessageLanguage _manifestLanguage(String code, String nativeName) =>
    UiMessageLanguage(code: code, direction: 'ltr', nativeName: nativeName);

UiMessageManifest _manifest() => UiMessageManifest(
  defaultLanguage: 'en',
  namespaceVersions: const <String, int>{'common': 1, 'workshop_admin': 1},
  languages: <UiMessageLanguage>[
    _manifestLanguage('en', 'English'),
    _manifestLanguage('es', 'Español'),
  ],
);

class _ManifestController extends UiMessageController {
  _ManifestController() : super(adminUiMessageClient);

  @override
  UiMessageState build() => UiMessageState(
    manifest: _manifest(),
    activeLanguage: 'en',
    defaultLanguage: 'en',
    ready: true,
    revision: 1,
  );
}

List<WorkshopLanguage> _registry({bool includeRetired = true}) =>
    <WorkshopLanguage>[
      const WorkshopLanguage(
        code: 'en',
        nativeName: 'English',
        direction: 'ltr',
        status: 'LIVE',
        active: true,
      ),
      const WorkshopLanguage(
        code: 'es',
        nativeName: 'Español',
        direction: 'ltr',
        status: 'LIVE',
        active: true,
      ),
      const WorkshopLanguage(
        code: 'de',
        nativeName: 'Deutsch',
        direction: 'ltr',
        status: 'LIVE',
        active: true,
      ),
      if (includeRetired)
        const WorkshopLanguage(
          code: 'fr',
          nativeName: 'Français',
          direction: 'ltr',
          status: 'RETIRED',
          active: false,
        ),
    ];

ReportDelivery _delivery(String language) => ReportDelivery(
  id: 'delivery-1',
  channel: 'WHATSAPP',
  recipientMasked: '+971•••••0100',
  language: language,
  status: 'QUEUED',
  attempts: 0,
  maxAttempts: 3,
  pdfAttached: true,
  linkState: 'ACTIVE',
  lastErrorCode: null,
  lastErrorMessage: null,
  nextAttemptAt: '',
  createdAt: '2026-11-21T09:00:00',
  updatedAt: '2026-11-21T09:00:00',
  attemptHistory: const <ReportDeliveryAttempt>[],
);

class _RecordingApi extends FakeAdminApi {
  _RecordingApi() : super(languages: _registry());

  String? sentLanguage;

  @override
  Future<ReportDelivery> sendDelivery(
    String jobId, {
    required String channel,
    required String language,
    required String idempotencyKey,
  }) async {
    sentLanguage = language;
    return _delivery(language);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeAdminApi api,
  String? preferredLanguage,
  bool languagesFail = false,
}) async {
  tester.view.physicalSize = const Size(1440, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminApiProvider.overrideWithValue(api),
        languageSelectionProvider(adminUiMessageClient)
            .overrideWith(_ManifestController.new),
        if (languagesFail)
          workshopLanguagesProvider.overrideWith(
            (ref) => Future<List<WorkshopLanguage>>.error(
              StateError('registry offline'),
            ),
          ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) =>
            uiStringsScope(child: child ?? const SizedBox.shrink()),
        theme: AppTheme.light,
        home: ReportPage(jobId: 'job-3', preferredLanguage: preferredLanguage),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('delivery language options', () {
    test('retired languages never become options', () {
      final options = reportLanguageOptions(
        _registry(),
        preferred: 'fr',
        manifest: _manifest(),
      );

      expect(options.map((option) => option.code), <String>['en', 'es', 'de']);
      expect(reportDeliveryLanguage(options, preferred: 'fr'), 'en');
    });

    test('unavailable registry falls back to the manifest, then English', () {
      final options = reportLanguageOptions(
        null,
        preferred: 'de',
        manifest: _manifest(),
      );

      expect(options.map((option) => option.code), <String>['en', 'es']);
      expect(reportDeliveryLanguage(options, preferred: 'de'), 'en');

      final empty = reportLanguageOptions(
        null,
        preferred: 'de',
        manifest: null,
      );
      expect(empty.single.code, 'en');
      expect(reportDeliveryLanguage(empty, preferred: 'de'), 'en');
    });

    test('delivery history labels resolve from the registry', () {
      expect(reportLanguageLabel(_registry(), 'de'), 'Deutsch');
      expect(reportLanguageLabel(_registry(), 'ru'), 'RU');
    });
  });

  testWidgets('registry language outside the manifest is selectable and sent', (
    tester,
  ) async {
    final api = _RecordingApi();
    await _pump(tester, api: api, preferredLanguage: 'de');
    final t = UiStrings.of(tester.element(find.byType(ReportPage)));

    await tester.tap(find.text(t(WorkshopAdminKeys.sendReport)).last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('report-delivery-language-de')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppSelectableText>(
            find.byKey(const Key('report-delivery-language-de')),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.byKey(const Key('report-delivery-language-fr')), findsNothing);
    expect(find.text('Français'), findsNothing);

    await tester.tap(find.text(t(WorkshopAdminKeys.sendReport)).last);
    await tester.pumpAndSettle();

    expect(api.sentLanguage, 'de');
  });

  testWidgets('registry failure falls back to English without crashing', (
    tester,
  ) async {
    await _pump(
      tester,
      api: FakeAdminApi(),
      preferredLanguage: 'de',
      languagesFail: true,
    );
    final t = UiStrings.of(tester.element(find.byType(ReportPage)));

    await tester.tap(find.text(t(WorkshopAdminKeys.sendReport)).last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<AppSelectableText>(
            find.byKey(const Key('report-delivery-language-en')),
          )
          .selected,
      isTrue,
    );
  });
}
