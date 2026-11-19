import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/approve_job_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';
import 'support/job_builders.dart';

class _RecordingApi extends FakeAdminApi {
  final approveRequests = <Map<String, Object?>>[];
  final rejectRequests = <Map<String, Object?>>[];

  @override
  Future<CleanJob> approveJob(
    String jobId, {
    String? reason,
    String? safetyCapReason,
    int? version,
  }) async {
    approveRequests.add(<String, Object?>{
      'jobId': jobId,
      'reason': reason,
      'safetyCapReason': safetyCapReason,
      'version': version,
    });
    return super.approveJob(
      jobId,
      reason: reason,
      safetyCapReason: safetyCapReason,
      version: version,
    );
  }

  @override
  Future<CleanJob> rejectJob(
    String jobId,
    String reason, {
    int? version,
  }) async {
    rejectRequests.add(<String, Object?>{
      'jobId': jobId,
      'reason': reason,
      'version': version,
    });
    return super.rejectJob(jobId, reason, version: version);
  }
}

class _GuardApi extends FakeAdminApi {
  _GuardApi(this.failure);

  final Object failure;

  @override
  Future<CleanJob> approveJob(
    String jobId, {
    String? reason,
    String? safetyCapReason,
    int? version,
  }) async => throw failure;

  @override
  Future<CleanJob> rejectJob(
    String jobId,
    String reason, {
    int? version,
  }) async => throw failure;
}

class _ScriptedJobApi extends FakeAdminApi {
  _ScriptedJobApi(this.job);

  final CleanJob job;

  @override
  Future<CleanJob> cleanJob(String id) async => job;
}

class _LoadErrorApi extends FakeAdminApi {
  _LoadErrorApi(this.failure);

  final Object failure;

  @override
  Future<CleanJob> cleanJob(String id) async => throw failure;
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
        home: const ApproveIssuePage(jobId: 'job-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(ApproveIssuePage)));

void main() {
  testWidgets('approve sends the version and ends APPROVED', (tester) async {
    final api = _RecordingApi();
    await _pump(tester, api);
    final l10n = _l10n(tester);

    expect(api.statusOf('job-1'), 'PENDING_REVIEW');
    await tester.tap(find.byKey(const Key('jobs-approve-button')));
    await tester.pumpAndSettle();

    expect(api.approveRequests, hasLength(1));
    expect(api.approveRequests.single['version'], 3);
    expect(api.statusOf('job-1'), 'APPROVED');
    expect(find.text(l10n.jobsApproved), findsOneWidget);
    expect(find.text(l10n.jobsStatusApproved), findsWidgets);
  });

  testWidgets('reject needs a reason, sends the version and ends REJECTED', (
    tester,
  ) async {
    final api = _RecordingApi();
    await _pump(tester, api);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const Key('jobs-reject-button')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.commonReasonRequired), findsOneWidget);
    expect(api.statusOf('job-1'), 'PENDING_REVIEW');
    expect(api.rejectRequests, isEmpty);

    await tester.enterText(
      find.byKey(const Key('jobs-approve-reason')),
      'Customer cancelled',
    );
    await tester.tap(find.byKey(const Key('jobs-reject-button')));
    await tester.pumpAndSettle();

    expect(api.rejectRequests, hasLength(1));
    expect(api.rejectRequests.single['reason'], 'Customer cancelled');
    expect(api.rejectRequests.single['version'], 3);
    expect(api.statusOf('job-1'), 'REJECTED');
    expect(find.text(l10n.jobsRejected), findsOneWidget);
  });

  testWidgets('APPROVER_IS_TECHNICIAN has its own copy', (tester) async {
    final api = _GuardApi(
      const AppFailure(
        code: 'APPROVER_IS_TECHNICIAN',
        messageKey: 'error.approverIsTechnician',
        statusCode: 409,
      ),
    );
    await _pump(tester, api);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const Key('jobs-approve-button')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.jobsApproverIsTechnician), findsOneWidget);
    expect(find.text(l10n.commonActionFailed), findsNothing);
  });

  testWidgets('JOB_VERSION_CONFLICT has reload copy and a reload action', (
    tester,
  ) async {
    final api = _GuardApi(const FakeVersionConflict('JOB_VERSION_CONFLICT'));
    await _pump(tester, api);
    final l10n = _l10n(tester);

    await tester.tap(find.byKey(const Key('jobs-approve-button')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.jobsConflictReload), findsOneWidget);
    final reload = tester.widget<WorkshopButton>(
      find.byKey(const Key('jobs-approve-reload')),
    );
    expect(reload.onPressed, isNotNull);
  });

  testWidgets('a null version blocks approve and reject with a distinct note', (
    tester,
  ) async {
    final api = _ScriptedJobApi(
      cleanJob(overrides: <String, dynamic>{'version': null}),
    );
    await _pump(tester, api);
    final l10n = _l10n(tester);

    expect(find.text(l10n.jobsNoVersion), findsOneWidget);
    expect(
      tester
          .widget<WorkshopButton>(find.byKey(const Key('jobs-approve-button')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<WorkshopButton>(find.byKey(const Key('jobs-reject-button')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<WorkshopButton>(find.byKey(const Key('jobs-checklist-link')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('403 and 404 load failures have distinct copy', (tester) async {
    await _pump(
      tester,
      _LoadErrorApi(
        const AppFailure(
          code: 'FORBIDDEN',
          messageKey: 'error.forbidden',
          statusCode: 403,
        ),
      ),
    );
    expect(find.text(_l10n(tester).jobsForbidden), findsOneWidget);

    await _pump(
      tester,
      _LoadErrorApi(
        const AppFailure(
          code: 'JOB_NOT_FOUND',
          messageKey: 'error.notFound',
          statusCode: 404,
        ),
      ),
    );
    expect(find.text(_l10n(tester).jobsNotFound), findsOneWidget);
  });

  testWidgets('approve renders in Arabic at 390 without overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeAdminApi(),
      size: const Size(390, 1400),
      locale: const Locale('ar'),
    );
    expect(find.text('JOB-0001'), findsWidgets);
    expect(find.text('88'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
