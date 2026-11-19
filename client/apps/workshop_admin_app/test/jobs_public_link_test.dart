import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';

class _RevokedApi extends FakeAdminApi {
  @override
  Future<PublicLink> publicLink(String jobId) async => const PublicLink(
    jobId: 'job-3',
    status: 'REVOKED',
    publicUrl: 'https://reports.test.local/r/token-3',
    token: 'token-3',
    qrUrl: null,
    pdfDownloadEnabled: false,
    activatedAt: '2026-11-07T12:00:00',
    revokedAt: '2026-11-08T09:30:00',
    revocationReason: 'Customer asked to withdraw the report',
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeAdminApi api,
  Size size = const Size(1440, 1000),
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
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: const PublicLinkPage(jobId: 'job-3'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
    'public link keeps the URL, token and QR under the dispatch bar',
    (tester) async {
      await _pump(tester, api: FakeAdminApi());
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PublicLinkPage)),
      );

      expect(find.text(l10n.jobsPublicLinkTitle), findsOneWidget);
      expect(find.text('https://reports.test.local/r/token-3'), findsOneWidget);
      expect(find.text('token-3'), findsOneWidget);
      expect(find.text(l10n.pdfDownload), findsOneWidget);
      expect(find.text(l10n.jobsQrUnavailable), findsOneWidget);

      // Active actions, unchanged guards and keys.
      expect(find.byKey(const Key('jobs-share-button')), findsOneWidget);
      expect(find.byKey(const Key('jobs-unpublish-button')), findsOneWidget);
      expect(find.byKey(const Key('jobs-revoke-button')), findsOneWidget);
      expect(
        find.byKey(const Key('jobs-publish-checklist-button')),
        findsNothing,
      );
    },
  );

  testWidgets('copy writes the URL and confirms with the same toast', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pump(tester, api: FakeAdminApi());
    final l10n = AppLocalizations.of(
      tester.element(find.byType(PublicLinkPage)),
    );
    await tester.tap(find.text(l10n.copyLink));
    await tester.pumpAndSettle();

    expect(copied, 'https://reports.test.local/r/token-3');
    expect(find.text(l10n.linkCopied), findsOneWidget);
  });

  testWidgets('revoked link shows the reason and never offers revoke again', (
    tester,
  ) async {
    await _pump(tester, api: _RevokedApi());
    final l10n = AppLocalizations.of(
      tester.element(find.byType(PublicLinkPage)),
    );

    expect(find.text('REVOKED'), findsOneWidget);
    expect(find.text('Customer asked to withdraw the report'), findsOneWidget);
    expect(
      find.byKey(const Key('jobs-publish-checklist-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('jobs-revoke-button')), findsNothing);
    expect(find.byKey(const Key('jobs-unpublish-button')), findsNothing);
  });

  testWidgets('public link has no overflow on a phone', (tester) async {
    await _pump(tester, api: FakeAdminApi(), size: const Size(390, 844));
    expect(find.text('token-3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
