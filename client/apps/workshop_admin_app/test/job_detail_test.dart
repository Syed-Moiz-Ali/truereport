import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_states.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_summary.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';

/// Detail contract against the rebuilt regions: data honesty, the action
/// policy and the five flow proofs (assign, cancel, stale version, approval
/// without consent, published).
Future<void> _pumpDetail(
  WidgetTester tester,
  AdminApi api,
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
      overrides: [adminApiProvider.overrideWithValue(api)],
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

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(JobDetailPage)));

Finder _fact(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(JobFact));

Finder _factValue(String label, String value) =>
    find.descendant(of: _fact(label), matching: find.text(value));

CleanJob _job({
  String id = 'job-1',
  String status = 'DRAFT',
  String reviewStatus = 'NOT_SUBMITTED',
  String publicationStatus = 'UNPUBLISHED',
  bool consentGranted = true,
  int? version = 3,
  String? assignedTechnicianId,
  String? assignedTechnicianName,
}) => CleanJob(
  id: id,
  reference: 'JOB-0001',
  status: status,
  reviewStatus: reviewStatus,
  publicationStatus: publicationStatus,
  templateVersionId: 'version-1',
  templateNameEn: 'Full inspection',
  templateNameAr: 'فحص شامل',
  templateVersionNo: 1,
  assignedTechnicianId: assignedTechnicianId,
  assignedTechnicianName: assignedTechnicianName,
  customerName: 'Workshop Customer',
  customerPhone: '+971500000100',
  customerEmail: 'jobs@test.local',
  vehicleVin: 'TESTVIN00000000002',
  vehicleMake: 'Toyota',
  vehicleModel: 'Camry',
  vehicleYear: 2022,
  vehiclePlate: 'JOB-100',
  odometerValue: 45000,
  odometerUnit: 'KM',
  transmission: 'AUTOMATIC',
  fuelType: 'PETROL',
  preferredLanguage: 'en',
  scheduledAt: '2026-11-05T09:00:00',
  startedAt: '2026-11-05T09:15:00',
  completedAt: '2026-11-05T10:00:00',
  approvedAt: null,
  publishedAt: null,
  cancelledAt: null,
  approvedBy: null,
  cancelledBy: null,
  cancelReason: null,
  score: 88,
  gradeCode: 'B',
  safetyCapApplied: false,
  safetyCapReason: null,
  consentGranted: consentGranted,
  createdAt: '2026-11-04T08:00:00',
  updatedAt: '2026-11-05T10:00:00',
  version: version,
);

/// Fake with a scripted clean job; mutations update that job in place so the
/// flow proofs observe the real post-mutation state.
class _ScriptedApi extends FakeAdminApi {
  _ScriptedApi(
    this.job, {
    this.assignConflict = false,
    this.cancelConflict = false,
  });

  CleanJob job;
  final bool assignConflict;
  final bool cancelConflict;

  @override
  Future<CleanJob> cleanJob(String id) async => job;

  @override
  Future<CleanJob> assignCleanJob(
    String jobId,
    String technicianId,
    String? reason, {
    int? version,
  }) async {
    assignRequests.add(<String, Object?>{
      'jobId': jobId,
      'technicianId': technicianId,
      'reason': reason,
      'version': version,
    });
    if (assignConflict) {
      throw const FakeVersionConflict('JOB_VERSION_CONFLICT');
    }
    job = job.copyWith(
      status: 'ASSIGNED',
      assignedTechnicianId: technicianId,
      assignedTechnicianName: 'Technician A',
      version: (job.version ?? 0) + 1,
    );
    return job;
  }

  @override
  Future<CleanJob> cancelCleanJob(
    String jobId,
    String reason, {
    int? version,
  }) async {
    cancelRequests.add(<String, Object?>{
      'jobId': jobId,
      'reason': reason,
      'version': version,
    });
    if (cancelConflict) {
      throw const FakeVersionConflict('JOB_VERSION_CONFLICT');
    }
    job = job.copyWith(
      status: 'CANCELLED',
      cancelReason: reason,
      version: (job.version ?? 0) + 1,
    );
    return job;
  }
}

class _LoadErrorApi extends FakeAdminApi {
  _LoadErrorApi(this.failure);

  final Object failure;

  @override
  Future<CleanJob> cleanJob(String id) async => throw failure;
}

void main() {
  testWidgets('identity band renders vehicle, reference and status badges', (
    tester,
  ) async {
    await _pumpDetail(tester, FakeAdminApi(), 'job-1');
    final l10n = _l10n(tester);

    expect(find.text('Toyota Camry'), findsWidgets);
    expect(find.text('JOB-0001'), findsWidgets);
    expect(find.text(l10n.jobsStatusPendingReview), findsWidgets);
    expect(find.text(l10n.notPublished), findsWidgets);
    // Review status equals the job status, so no duplicate review chip.
    expect(
      find.text('${l10n.jobsReviewTitle}: ${l10n.jobsStatusPendingReview}'),
      findsNothing,
    );
    for (final label in [
      l10n.scheduledAt,
      l10n.jobsAssignedTechnician,
      l10n.template,
      l10n.jobsScore,
    ]) {
      expect(_fact(label), findsWidgets, reason: label);
    }
    expect(find.text('PENDING_REVIEW'), findsNothing);
    expect(find.text('NOT_PUBLISHED'), findsNothing);
  });

  testWidgets('customer, vehicle and inspection show honest fields only', (
    tester,
  ) async {
    await _pumpDetail(tester, FakeAdminApi(), 'job-1');
    final l10n = _l10n(tester);

    for (final label in [
      l10n.customerName,
      l10n.customerPhone,
      l10n.customerEmail,
      l10n.vehiclePlate,
      l10n.vehicleVin,
      l10n.jobsFieldOdometer,
      l10n.jobsFieldTransmission,
      l10n.jobsFieldFuelType,
      l10n.jobsFieldPreferredLanguage,
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('Body panel check'), findsOneWidget);
    expect(find.text('JOB-EXT-001'), findsOneWidget);
    expect(find.text(l10n.noIssueObserved), findsOneWidget);

    // CR-7 / CR-8: no evidence counts, issue values or server instants.
    expect(find.text(l10n.jobsEvidencePhotos), findsNothing);
    expect(find.text(l10n.jobsEvidenceVideos), findsNothing);
    expect(find.text(l10n.jobsCompletedAt), findsNothing);
    expect(find.text('4.2'), findsNothing);
    expect(find.text('DEFECT_FOUND'), findsNothing);
  });

  testWidgets('stale ACTIVE publication status is never presented as live', (
    tester,
  ) async {
    await _pumpDetail(tester, FakeAdminApi(), 'job-3');
    final l10n = _l10n(tester);

    expect(find.text(l10n.jobsStatusPublished), findsWidgets);
    expect(_factValue(l10n.jobsPublicationStatus, l10n.notPublished), findsOne);
    expect(
      _factValue(l10n.jobsPublicationStatus, l10n.jobsStatusPublished),
      findsNothing,
    );
  });

  testWidgets(
    'PUBLISHED publication status reads Published with no mutations',
    (tester) async {
      final api = _ScriptedApi(
        _job(
          status: 'PUBLISHED',
          reviewStatus: 'APPROVED',
          publicationStatus: 'PUBLISHED',
        ),
      );
      await _pumpDetail(tester, api, 'job-1');
      final l10n = _l10n(tester);

      expect(
        _factValue(l10n.jobsPublicationStatus, l10n.jobsStatusPublished),
        findsOne,
      );
      // PUBLISHED is terminal: the primary is the public link, and cancel is gone.
      expect(
        find.byKey(const Key('job-detail-primary-action')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('job-detail-top-more')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.cancelJob), findsNothing);
    },
  );

  testWidgets('APPROVED without consent promises no publish and says why', (
    tester,
  ) async {
    final api = _ScriptedApi(
      _job(status: 'APPROVED', reviewStatus: 'APPROVED', consentGranted: false),
    );
    await _pumpDetail(tester, api, 'job-1');
    final l10n = _l10n(tester);

    expect(find.text(l10n.jobsPublicationBlocked), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlockedBody), findsOneWidget);
    expect(find.text(l10n.jobsConsentMissing), findsOneWidget);
    expect(find.byKey(const Key('job-detail-primary-action')), findsNothing);
    // The checklist link is required even when publication is blocked (§5).
    final checklist = find.byKey(const Key('job-detail-publish-checklist'));
    expect(checklist, findsOneWidget);
    expect(find.text(l10n.jobsViewChecklist), findsOneWidget);
    await tester.tap(checklist);
    await tester.pumpAndSettle();
    expect(find.byType(PublishChecklistPage), findsOneWidget);
  });

  testWidgets('a null version blocks every mutation and says so', (
    tester,
  ) async {
    final api = _ScriptedApi(_job(status: 'DRAFT', version: null));
    await _pumpDetail(tester, api, 'job-1');
    final l10n = _l10n(tester);

    expect(find.text(l10n.jobsNoVersion), findsOneWidget);
    // No deceptive saturated primary: the recovery action is a real reload.
    expect(find.byKey(const Key('job-detail-primary-action')), findsNothing);
    final reload = tester.widget<WorkshopButton>(
      find.byKey(const Key('job-detail-reload')),
    );
    expect(reload.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('job-detail-top-more')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.cancelJob), findsNothing);
    expect(find.text(l10n.reassign), findsNothing);
  });

  testWidgets('assign sends the version and the region shows the name', (
    tester,
  ) async {
    final api = _ScriptedApi(_job(status: 'DRAFT'));
    await _pumpDetail(tester, api, 'job-1');

    await tester.tap(find.byKey(const Key('job-detail-primary-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('job-assign-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('assign-confirm')));
    await tester.pumpAndSettle();

    expect(api.assignRequests, hasLength(1));
    expect(api.assignRequests.single['version'], 3);
    expect(api.job.status, 'ASSIGNED');
    expect(find.text('Technician A'), findsWidgets);
    expect(find.text('tech-1'), findsNothing);
  });

  testWidgets('cancel with a reason terminates the job and removes actions', (
    tester,
  ) async {
    final api = _ScriptedApi(_job(status: 'DRAFT'));
    await _pumpDetail(tester, api, 'job-1');
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const Key('job-detail-top-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancelJob).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('job-reason-field')),
      'Customer cancelled',
    );
    await tester.tap(find.byKey(const Key('job-reason-confirm')));
    await tester.pumpAndSettle();

    expect(api.cancelRequests, hasLength(1));
    expect(api.cancelRequests.single['reason'], 'Customer cancelled');
    expect(api.cancelRequests.single['version'], 3);
    expect(api.job.status, 'CANCELLED');
    expect(find.text(l10n.statusCancelled), findsWidgets);
    expect(find.text('Customer cancelled'), findsWidgets);
    expect(find.byKey(const Key('job-detail-primary-action')), findsNothing);
    await tester.tap(find.byKey(const Key('job-detail-top-more')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.cancelJob), findsNothing);
  });

  testWidgets(
    'a stale version shows the conflict copy and does not overwrite',
    (tester) async {
      final api = _ScriptedApi(_job(status: 'DRAFT'), assignConflict: true);
      await _pumpDetail(tester, api, 'job-1');
      final l10n = _l10n(tester);

      await tester.tap(find.byKey(const Key('job-detail-primary-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assign-confirm')));
      await tester.pumpAndSettle();

      expect(api.assignRequests.single['version'], 3);
      expect(find.text(l10n.jobsConflictReload), findsOneWidget);
      expect(api.job.status, 'DRAFT');
    },
  );

  testWidgets(
    'a page conflict replaces the dead primary with an enabled reload',
    (tester) async {
      final api = _ScriptedApi(_job(status: 'DRAFT'), cancelConflict: true);
      await _pumpDetail(tester, api, 'job-1');
      final l10n = _l10n(tester);

      await tester.tap(find.byKey(const Key('job-detail-top-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.cancelJob).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('job-reason-field')),
        'Customer cancelled',
      );
      await tester.tap(find.byKey(const Key('job-reason-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.jobsConflictReload), findsOneWidget);
      // N9: the banner is message-only; the sticky reload is the one explicit
      // refresh control (the top bar keeps only its standard icon).
      expect(find.text(l10n.refresh), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(JobDetailConflictBanner),
          matching: find.byType(WorkshopButton),
        ),
        findsNothing,
      );
      // N7: no saturated primary that does nothing; a real reload instead.
      expect(find.byKey(const Key('job-detail-primary-action')), findsNothing);
      final reload = tester.widget<WorkshopButton>(
        find.byKey(const Key('job-detail-reload')),
      );
      expect(reload.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('job-detail-reload')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.jobsConflictReload), findsNothing);
      expect(
        find.byKey(const Key('job-detail-primary-action')),
        findsOneWidget,
      );
    },
  );

  testWidgets('403 and 404 load states have distinct copy', (tester) async {
    await _pumpDetail(
      tester,
      _LoadErrorApi(
        const AppFailure(
          code: 'FORBIDDEN',
          messageKey: 'error.forbidden',
          statusCode: 403,
        ),
      ),
      'job-1',
    );
    expect(find.text(_l10n(tester).jobsForbidden), findsOneWidget);

    await _pumpDetail(
      tester,
      _LoadErrorApi(
        const AppFailure(
          code: 'JOB_NOT_FOUND',
          messageKey: 'error.notFound',
          statusCode: 404,
        ),
      ),
      'job-1',
    );
    expect(find.text(_l10n(tester).jobsNotFound), findsOneWidget);
  });

  testWidgets('Arabic detail keeps the schedule Latin and date-first', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      FakeAdminApi(),
      'job-1',
      locale: const Locale('ar'),
    );

    // Gate 6 F1: `DateFormat` for `ar` used to render `٩:٠٠ ٢٠٢٦/١١/٥`.
    expect(
      find.textContaining(RegExp('[٠-٩۰-۹]')),
      findsNothing,
      reason: 'no Arabic-Indic digits in a data value',
    );
    final schedule = find.text('5/11/2026 09:00');
    expect(schedule, findsWidgets);
    expect(
      tester.widget<Text>(schedule.first).textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('Arabic identity keeps the reference on the start edge', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      FakeAdminApi(),
      'job-1',
      locale: const Locale('ar'),
    );
    final reference = find.descendant(
      of: find.byType(JobDetailSummary),
      matching: find.text('JOB-0001'),
    );
    final card = find.descendant(
      of: find.byType(JobDetailSummary),
      matching: find.byType(WorkshopCard),
    );
    expect(reference, findsOneWidget);
    final referenceRect = tester.getRect(reference);
    final cardRect = tester.getRect(card);
    // F8: in RTL the reference belongs next to the vehicle title (start/right),
    // not alone at the physical left of the card.
    expect(referenceRect.left, greaterThan(cardRect.center.dx));
  });

  testWidgets('1024 customer and vehicle facts keep two columns', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      FakeAdminApi(),
      'job-1',
      size: const Size(1024, 1200),
    );
    final l10n = _l10n(tester);
    final name = _fact(l10n.customerName);
    final phone = _fact(l10n.customerPhone);
    expect(name, findsOneWidget);
    expect(phone, findsOneWidget);
    final nameRect = tester.getRect(name);
    final phoneRect = tester.getRect(phone);
    // F11: ten facts in one column pushed Inspection under the sticky bar.
    expect(phoneRect.top, nameRect.top, reason: 'same run');
    expect(phoneRect.left, isNot(nameRect.left), reason: 'two columns');
  });

  testWidgets('detail renders at 360 without overflow', (tester) async {
    await _pumpDetail(
      tester,
      FakeAdminApi(),
      'job-1',
      size: const Size(360, 800),
    );
    expect(find.text('JOB-0001'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2x text at 390 does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpDetail(
      tester,
      FakeAdminApi(),
      'job-1',
      size: const Size(390, 900),
    );
    expect(find.text('JOB-0001'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
