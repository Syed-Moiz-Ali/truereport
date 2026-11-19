import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';

import 'support/fake_admin_api.dart';

/// The lifecycle rail is the spine of the job record. On a phone it must wrap,
/// not scroll sideways, so the current stage is always on screen — in both
/// directions.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Locale locale, {
    Size size = const Size(390, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminApiProvider.overrideWithValue(FakeAdminApi())],
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.build(isArabic: locale.languageCode == 'ar'),
          home: const JobDetailPage(jobId: 'job-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('job detail rail keeps Pending review on screen at 390 '
        '${locale.languageCode}', (tester) async {
      await pump(tester, locale);
      final rail = find.byType(JobStageRail);
      expect(rail, findsOneWidget);
      expect(
        find.descendant(of: rail, matching: find.byType(SingleChildScrollView)),
        findsNothing,
        reason: 'the rail must wrap on a phone, never scroll sideways',
      );
      final l10n = AppLocalizations.of(tester.element(rail));
      final current = tester.getRect(
        find.descendant(
          of: rail,
          matching: find.text(jobStatusLabel(l10n, 'PENDING_REVIEW')),
        ),
      );
      expect(current.left, greaterThanOrEqualTo(0));
      expect(current.right, lessThanOrEqualTo(390));
      expect(current.top, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('job detail rail stays a single row on desktop', (tester) async {
    await pump(tester, const Locale('en'), size: const Size(1440, 900));
    final rail = find.byType(JobStageRail);
    expect(
      find.descendant(of: rail, matching: find.byType(SingleChildScrollView)),
      findsOneWidget,
    );
  });
}
