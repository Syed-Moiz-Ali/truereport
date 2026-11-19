import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/jobs/detail/job_detail_states.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';

/// Real-font evidence for the rebuilt job detail (J1a).
///
/// Writes to `docs/evidence/jobs_j1/`. Fonts come from
/// `flutter_test_config.dart`; every test asserts no exception, so an overflow
/// fails the run rather than producing a misleading screenshot.
const String _outDir = 'docs/evidence/jobs_j1';

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    expect(boundary, isNotNull, reason: name);
    final image = await boundary!.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull, reason: name);
    final dir = Directory(_outDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('${dir.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  });
}

Future<GlobalKey> _pump(
  WidgetTester tester, {
  required AdminApi api,
  required Size size,
  required double height,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final key = GlobalKey();
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
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: RepaintBoundary(
          key: key,
          child: Material(
            color: AppTheme.light.scaffoldBackgroundColor,
            child: SizedBox(
              width: size.width,
              height: height,
              child: const JobDetailPage(jobId: 'job-1'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return key;
}

CleanJob _job({
  String status = 'DRAFT',
  String reviewStatus = 'NOT_SUBMITTED',
  String publicationStatus = 'UNPUBLISHED',
  bool consentGranted = true,
  int? version = 3,
}) => CleanJob(
  id: 'job-1',
  reference: 'JOB-2026-0107',
  status: status,
  reviewStatus: reviewStatus,
  publicationStatus: publicationStatus,
  templateVersionId: 'version-1',
  templateNameEn: 'Full inspection',
  templateNameAr: 'فحص شامل',
  templateVersionNo: 1,
  assignedTechnicianId: 'tech-1',
  assignedTechnicianName: 'Technician A',
  customerName: 'Rashid Al Mansoori',
  customerPhone: '+971500000000',
  customerEmail: 'customer@example.test',
  vehicleVin: 'WP0ZZZ99ZPS000000',
  vehicleMake: 'Porsche',
  vehicleModel: '911 GT3',
  vehicleYear: 2023,
  vehiclePlate: 'DXB 48291',
  odometerValue: 18240,
  odometerUnit: 'km',
  transmission: 'PDK',
  fuelType: 'PETROL',
  preferredLanguage: 'en',
  scheduledAt: '2026-11-18T10:00',
  startedAt: '2026-11-18T10:22',
  completedAt: '2026-11-18T11:40',
  approvedAt: null,
  publishedAt: null,
  cancelledAt: null,
  approvedBy: null,
  cancelledBy: null,
  cancelReason: null,
  score: 82,
  gradeCode: 'B',
  safetyCapApplied: false,
  safetyCapReason: null,
  consentGranted: consentGranted,
  createdAt: '2026-11-16T09:12',
  updatedAt: '2026-11-18T11:40',
  version: version,
);

/// Scripted clean job; `cancelConflict` raises a stale-version failure.
class _ScriptedApi extends FakeAdminApi {
  _ScriptedApi(this.job, {this.cancelConflict = false});

  CleanJob job;
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

void main() {
  for (final entry in const <String, (Size, double)>{
    'detail_1440': (Size(1440, 1150), 1150),
    'detail_1280': (Size(1280, 1120), 1120),
    'detail_1024': (Size(1024, 1200), 1200),
    'detail_768': (Size(768, 1600), 1600),
    'detail_390': (Size(390, 1600), 1600),
    'detail_360': (Size(360, 1600), 1600),
  }.entries) {
    testWidgets(entry.key, (tester) async {
      final key = await _pump(
        tester,
        api: FakeAdminApi(),
        size: entry.value.$1,
        height: entry.value.$2,
      );
      expect(tester.takeException(), isNull);
      await _capture(tester, key, entry.key);
    });
  }

  testWidgets('detail_1280_ar', (tester) async {
    final key = await _pump(
      tester,
      api: FakeAdminApi(),
      size: const Size(1280, 1100),
      height: 1100,
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);

    // F1: data values never leave the Latin numbering system. The scheduled
    // date is `d/M/y HH:mm` with the intl bidi marks pinned out.
    expect(
      find.textContaining(RegExp('[٠-٩۰-۹]')),
      findsNothing,
      reason: 'no Arabic-Indic digits in the detail tree',
    );
    expect(
      find.textContaining(
        RegExp('[\u200E\u200F\u061C\u202A-\u202E\u2066-\u2069]'),
      ),
      findsNothing,
      reason: 'no bidi controls in a rendered data value',
    );
    final schedule = find.text('5/11/2026 09:00');
    expect(schedule, findsWidgets, reason: 'Latin, date-first scheduledAt');
    expect(
      tester.widget<Text>(schedule.first).textDirection,
      TextDirection.ltr,
    );
    await _capture(tester, key, 'detail_1280_ar');
  });

  testWidgets('detail_consent_blocked_1280', (tester) async {
    final api = _ScriptedApi(
      _job(status: 'APPROVED', reviewStatus: 'APPROVED', consentGranted: false),
    );
    final key = await _pump(
      tester,
      api: api,
      size: const Size(1280, 1100),
      height: 1100,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(JobDetailPage)),
    );
    expect(find.text(l10n.jobsPublicationBlocked), findsOneWidget);
    expect(find.text(l10n.jobsPublicationBlockedBody), findsOneWidget);
    expect(find.text(l10n.jobsConsentMissing), findsOneWidget);
    // No direct publish promise: the only primary route is the checklist.
    expect(find.byKey(const Key('job-detail-primary-action')), findsNothing);
    // §5: the blocked state still offers the checklist link, and it routes.
    final checklist = find.byKey(const Key('job-detail-publish-checklist'));
    expect(checklist, findsOneWidget);
    expect(find.text(l10n.jobsViewChecklist), findsOneWidget);
    await tester.tap(checklist);
    await tester.pumpAndSettle();
    expect(find.byType(PublishChecklistPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(PublishChecklistPage))).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'detail_consent_blocked_1280');
  });

  for (final entry in const <String, (Size, double)>{
    'detail_text2x_1280': (Size(1280, 1120), 1120),
    'detail_text2x_390': (Size(390, 1600), 1600),
  }.entries) {
    testWidgets(entry.key, (tester) async {
      final key = await _pump(
        tester,
        api: FakeAdminApi(),
        size: entry.value.$1,
        height: entry.value.$2,
        textScaler: const TextScaler.linear(2),
      );
      expect(find.text('JOB-0001'), findsWidgets);
      expect(tester.takeException(), isNull);
      await _capture(tester, key, entry.key);
    });
  }

  testWidgets('detail_conflict_1280', (tester) async {
    final api = _ScriptedApi(_job(), cancelConflict: true);
    final key = await _pump(
      tester,
      api: api,
      size: const Size(1280, 1100),
      height: 1100,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(JobDetailPage)),
    );

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
    // N9: message-only banner; the sticky reload is the only explicit refresh.
    expect(find.text(l10n.refresh), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(JobDetailConflictBanner),
        matching: find.byType(WorkshopButton),
      ),
      findsNothing,
    );
    // N7: while the conflict is shown there is no saturated, dead primary;
    // the recovery control is an enabled reload.
    expect(find.byKey(const Key('job-detail-primary-action')), findsNothing);
    final reload = tester.widget<WorkshopButton>(
      find.byKey(const Key('job-detail-reload')),
    );
    expect(reload.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'detail_conflict_1280');
  });

  testWidgets('detail_terminal_1280', (tester) async {
    final api = _ScriptedApi(
      _job(
        status: 'PUBLISHED',
        reviewStatus: 'APPROVED',
        publicationStatus: 'PUBLISHED',
      ),
    );
    final key = await _pump(
      tester,
      api: api,
      size: const Size(1280, 1100),
      height: 1100,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(JobDetailPage)),
    );
    expect(find.text(l10n.jobsStatusPublished), findsWidgets);
    expect(find.byKey(const Key('job-detail-primary-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'detail_terminal_1280');
  });
}
