import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';

import 'support/fake_admin_api.dart';

/// Job detail presentation contract (summary size, status chips, moved facts).
/// Behaviour/API coverage lives in the existing adaptive and report suites.
Future<void> _pumpDetail(
  WidgetTester tester,
  String jobId, {
  Size size = const Size(1280, 900),
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
      overrides: [adminApiProvider.overrideWithValue(FakeAdminApi())],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: JobDetailPage(jobId: jobId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('summary keeps five facts and the detail groups hold the rest', (
    tester,
  ) async {
    await _pumpDetail(tester, 'job-1');
    final l10n = AppLocalizations.of(
      tester.element(find.byType(JobDetailPage)),
    );

    final summary = find
        .ancestor(
          of: find.text(l10n.jobsSummary),
          matching: find.byType(WorkshopCard),
        )
        .first;
    expect(
      find.descendant(of: summary, matching: find.byType(JobFact)),
      findsNWidgets(5),
    );
    // Moved out of the summary into Customer & vehicle.
    for (final label in [
      l10n.customerEmail,
      l10n.vehiclePlate,
      l10n.vehicleVin,
      l10n.jobsFieldOdometer,
      l10n.jobsFieldTransmission,
      l10n.jobsFieldFuelType,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    // Template lives in Inspection only.
    expect(find.text(l10n.template), findsOneWidget);
  });

  testWidgets('not-published job shows two chips, no duplicate review', (
    tester,
  ) async {
    await _pumpDetail(tester, 'job-1');
    final l10n = AppLocalizations.of(
      tester.element(find.byType(JobDetailPage)),
    );

    // Job status + publication status, and the review chip is suppressed
    // because reviewStatus equals the job status.
    expect(find.text(l10n.jobsStatusPendingReview), findsWidgets);
    expect(find.text(l10n.notPublished), findsWidgets);
    expect(
      find.text('${l10n.jobsReviewTitle}: ${l10n.jobsStatusPendingReview}'),
      findsNothing,
    );
  });

  testWidgets('published job shows the review chip when it differs', (
    tester,
  ) async {
    await _pumpDetail(tester, 'job-3');
    final l10n = AppLocalizations.of(
      tester.element(find.byType(JobDetailPage)),
    );

    expect(find.text(l10n.jobsStatusPublished), findsWidgets);
    expect(
      find.text('${l10n.jobsReviewTitle}: ${l10n.jobsStatusApproved}'),
      findsOneWidget,
    );
    expect(find.text(l10n.notPublished), findsNothing);
  });

  testWidgets('detail renders at 360 without overflow', (tester) async {
    await _pumpDetail(tester, 'job-1', size: const Size(360, 800));
    expect(find.textContaining('JOB-0001'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assignment history shows the technician name, never the id', (
    tester,
  ) async {
    await _pumpDetail(tester, 'job-1');
    final l10n = AppLocalizations.of(
      tester.element(find.byType(JobDetailPage)),
    );

    // FakeAdminApi: assignment.technicianId == 'tech-1' and the staff
    // directory resolves it to "Technician A".
    expect(find.text('Technician A'), findsWidgets);
    expect(find.text('tech-1'), findsNothing);
    expect(find.textContaining('8f3d2c11'), findsNothing);

    // assignedBy is an id the directory does not know -> em dash, not the id.
    final assignedByFact = find.ancestor(
      of: find.text(l10n.assignTechnicianTitle),
      matching: find.byType(JobFact),
    );
    expect(assignedByFact, findsOneWidget);
    expect(
      find.descendant(of: assignedByFact, matching: find.text('—')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: assignedByFact, matching: find.text('admin-1')),
      findsNothing,
    );
  });
}
