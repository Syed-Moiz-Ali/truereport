import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/pages/job_detail_page.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'support/fake_technician_api.dart';
import 'support/test_offline_store.dart';

Future<FakeTechnicianApi> _pumpConsent(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final api = FakeTechnicianApi();
  final store = createTestOfflineStore();
  addTearDown(store.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        technicianApiProvider.overrideWithValue(api),
        offlineStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: const JobDetailPage(jobId: 'job-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final consentButton = find.widgetWithText(AppButton, 'Consent');
  await tester.ensureVisible(consentButton);
  await tester.tap(consentButton);
  await tester.pumpAndSettle();

  return api;
}

void main() {
  testWidgets('consent starts unselected and records only after an action', (
    tester,
  ) async {
    final api = await _pumpConsent(tester);

    final granted = tester.widget<AppSelectableText>(
      find.byKey(const Key('consent-granted')),
    );
    final refused = tester.widget<AppSelectableText>(
      find.byKey(const Key('consent-refused')),
    );
    final save = tester.widget<AppButton>(
      find.byKey(const Key('consent-save')),
    );

    expect(granted.selected, isFalse);
    expect(refused.selected, isFalse);
    expect(save.onPressed, isNull);
    expect(api.consentRecords, 0);

    await tester.tap(find.byKey(const Key('consent-type-processing')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AppButton>(find.byKey(const Key('consent-save'))).onPressed,
      isNull,
    );
    expect(api.consentRecords, 0);

    await tester.tap(find.byKey(const Key('consent-granted')));
    await tester.pumpAndSettle();

    final enabledSave = tester.widget<AppButton>(
      find.byKey(const Key('consent-save')),
    );
    expect(enabledSave.onPressed, isNotNull);
    expect(api.consentRecords, 0);

    await tester.tap(find.byKey(const Key('consent-save')));
    await tester.pumpAndSettle();

    expect(api.consentRecords, 1);
    expect(api.lastConsentType, 'PROCESSING');
    expect(api.lastConsentStatus, 'GRANTED');
  });

  testWidgets('public-link refusal is separate and records only when saved', (
    tester,
  ) async {
    final api = await _pumpConsent(tester);

    await tester.tap(find.byKey(const Key('consent-type-public-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('consent-refused')));
    await tester.pumpAndSettle();

    expect(api.consentRecords, 0);
    await tester.tap(find.byKey(const Key('consent-save')));
    await tester.pumpAndSettle();

    expect(api.consentRecords, 1);
    expect(api.lastConsentType, 'PUBLIC_LINK');
    expect(api.lastConsentStatus, 'REFUSED');
  });
}
