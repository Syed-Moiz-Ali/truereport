import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';

PublishChecklist _checklist({required bool ready, required bool consent}) =>
    PublishChecklist(
      jobId: 'job-1',
      ready: ready,
      items: [
        const ChecklistEntry(
          code: 'ALL_ITEMS_ASSESSED',
          passed: true,
          messageEn: 'All configured items are assessed',
          messageAr: 'تم تقييم جميع العناصر المهيأة',
        ),
        ChecklistEntry(
          code: 'CONSENT_GRANTED',
          passed: consent,
          messageEn: 'Public-link consent is granted',
          messageAr: 'تم منح الموافقة على الرابط العام',
        ),
        ChecklistEntry(
          code: 'SAFETY_CAP_EXPLAINED',
          passed: ready,
          messageEn: 'Safety cap explanation is provided when required',
          messageAr: 'تم تقديم تفسير حد السلامة عند الحاجة',
        ),
      ],
      itemsAssessed: 3,
      itemsTotal: 3,
      score: 82,
      gradeCode: 'B',
      safetyCapApplied: false,
      safetyCapReason: null,
      consentGranted: consent,
      signaturePresent: true,
      // The server sends this constant; the UI must never render it as a fact.
      documentsReady: true,
    );

class _ChecklistApi extends FakeAdminApi {
  _ChecklistApi(this.checklist, {this.publishFailure});

  final PublishChecklist checklist;
  final Object? publishFailure;
  final publishRequests = <Map<String, Object?>>[];

  @override
  Future<PublishChecklist> publishChecklist(String jobId) async => checklist;

  @override
  Future<PublicLink> publishJob(
    String jobId, {
    bool? pdfDownloadEnabled,
  }) async {
    publishRequests.add(<String, Object?>{
      'jobId': jobId,
      'pdfDownloadEnabled': pdfDownloadEnabled,
    });
    if (publishFailure != null) {
      throw publishFailure!;
    }
    return super.publishJob(jobId, pdfDownloadEnabled: pdfDownloadEnabled);
  }
}

Future<void> _pump(
  WidgetTester tester,
  AdminApi api, {
  Size size = const Size(1280, 1100),
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
        home: const PublishChecklistPage(jobId: 'job-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(PublishChecklistPage)));

void main() {
  testWidgets('ready checklist enables publish and never claims docs ready', (
    tester,
  ) async {
    final api = _ChecklistApi(_checklist(ready: true, consent: true));
    await _pump(tester, api);
    final l10n = _l10n(tester);

    expect(find.text(l10n.jobsChecklistReady), findsWidgets);
    expect(
      find.byKey(const Key('jobs-checklist-ALL_ITEMS_ASSESSED')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('jobs-checklist-CONSENT_GRANTED')),
      findsOneWidget,
    );
    expect(find.text(l10n.jobsDocumentsReady), findsNothing);
    expect(find.text(l10n.jobsDocsGeneratedAfterPublish), findsOneWidget);
    // Cleanup: the PDF option is a pill toggle, never a Material Switch.
    expect(find.byType(Switch), findsNothing);
    expect(find.text(l10n.commonYes), findsOneWidget);
    expect(
      tester
          .widget<JobPillButton>(find.byKey(const Key('jobs-publish-button')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('blocked checklist disables publish and states the reason', (
    tester,
  ) async {
    final api = _ChecklistApi(_checklist(ready: false, consent: false));
    await _pump(tester, api);
    final l10n = _l10n(tester);

    expect(find.text(l10n.jobsChecklistNotReady), findsWidgets);
    expect(find.text(l10n.jobsPublicationBlockedBody), findsOneWidget);
    expect(find.text(l10n.jobsConsentUnavailableNote), findsOneWidget);
    expect(
      tester
          .widget<JobPillButton>(find.byKey(const Key('jobs-publish-button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('consent missing disables publish even when ready', (
    tester,
  ) async {
    final api = _ChecklistApi(_checklist(ready: true, consent: false));
    await _pump(tester, api);
    final l10n = _l10n(tester);

    expect(find.text(l10n.jobsConsentMissing), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlockedBody), findsOneWidget);
    expect(find.text(l10n.jobsConsentUnavailableNote), findsOneWidget);
    expect(
      tester
          .widget<JobPillButton>(find.byKey(const Key('jobs-publish-button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('422 CONSENT_REQUIRED is mapped honestly', (tester) async {
    final api = _ChecklistApi(
      _checklist(ready: true, consent: true),
      publishFailure: const AppFailure(
        code: 'CONSENT_REQUIRED',
        messageKey: 'error.consentRequired',
        statusCode: 422,
      ),
    );
    await _pump(tester, api);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const Key('jobs-publish-button')));
    await tester.pumpAndSettle();

    expect(api.publishRequests, hasLength(1));
    expect(find.text(l10n.jobsPublicationBlockedBody), findsWidgets);
    expect(find.text(l10n.jobsPublishFailed), findsNothing);
  });

  testWidgets('checklist renders in Arabic at 390 without overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      _ChecklistApi(_checklist(ready: false, consent: false)),
      size: const Size(390, 1400),
      locale: const Locale('ar'),
    );
    expect(find.byKey(const Key('jobs-checklist-ready-chip')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
