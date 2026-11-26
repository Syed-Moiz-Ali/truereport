/// Real-font screenshots of the shift queue page itself (phone + tablet).
///
/// These pump `TechnicianJobsCleanPage` with the real providers overridden, so
/// the evidence shows the shipped layout, not a hand-composed approximation.
library;

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/jobs/queue/jobs_queue_format.dart';
import 'package:technician_app/src/features/jobs/technician_jobs_clean_page.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import '../support/fixtures.dart' as fixtures;

class _SignedIn extends AuthController {
  @override
  Future<Session?> build() async => const Session(
    accessToken: 'shot-token',
    refreshToken: 'shot-refresh',
    user: User(
      id: 'tech-17',
      email: 'omar.haddad@truereport.test',
      displayName: 'Omar Haddad',
      platformAdmin: false,
      totpEnabled: false,
    ),
    memberships: <Membership>[],
  );
}

const Map<String, String> _bundle = <String, String>{
  'technicianDeckEyebrow': 'TRUEREPORT · TECHNICIAN',
  'technicianQueueSummary': '{toStart} to start · {inProgress} in progress',
  'technicianJobSearch': 'Search jobs',
  'technicianJobSearchHint': 'Plate, customer, job or VIN',
  'technicianFilter': 'Filter',
  'filterAll': 'All',
  'technicianSyncOnline': 'Online',
  'technicianSyncOffline': 'Offline',
  'technicianSyncStateConflict': 'Conflict',
  'technicianSessionSyncPending': 'Sync pending',
  'technicianProfileTitle': 'Profile',
  'technicianQueueClearFilters': 'Clear filters',
  'technicianQueueSectionNow': 'Now',
  'technicianQueueSectionToday': 'Today',
  'technicianQueueSectionUpcoming': 'Upcoming',
  'technicianQueueSectionUnfinished': 'Unfinished',
  'technicianQueueSectionDoneToday': 'Done today',
  'technicianQueueNextAt': 'next at {time}',
  'technicianQueueItems': '{done} of {total} items',
  'technicianAllCaughtUp': 'You are all caught up',
  'technicianNoJobsBody': 'No pending inspections are assigned to you.',
  'startInspection': 'Start inspection',
  'start': 'Start',
  'technicianDeckContinueAction': 'Continue inspection',
  'technicianDeckFinishJob': 'Finish job',
  'technicianQueueActionView': 'View',
  'technicianQueueActionContinue': 'Continue',
  'technicianQueueActionFinish': 'Finish',
  'technicianNoJobsThisDay': 'No jobs on this day',
  'technicianNoSearchResults': 'No jobs match your search',
  'offlineBanner': 'Offline - changes are queued until you reconnect',
  'shotInProgress': 'In progress',
  'shotScheduled': 'Scheduled',
  'shotPendingReview': 'Pending review',
  'roleTechnician': 'Technician',
};

/// Dubai "today", so the sample jobs always bucket into the Today tab.
String _stamp(int hour, int minute) {
  final day = DateFormat('yyyy-MM-dd').format(queueTodayKey());
  final hh = hour.toString().padLeft(2, '0');
  final mm = minute.toString().padLeft(2, '0');
  return '${day}T$hh:$mm:00';
}

List<JobSummary> _jobs() => <JobSummary>[
  fixtures.jobSummary(
    id: 'live',
    reference: 'JOB-10485',
    status: 'IN_PROGRESS',
    vehicleModel: 'Land Cruiser',
    customerName: 'Ahmed Al Mansoori',
    vehiclePlate: 'AUD-354626',
    scheduledAt: _stamp(9, 0),
    startedAt: _stamp(9, 12),
    completedItems: 12,
    totalItems: 30,
  ),
  fixtures.jobSummary(
    id: 'soon',
    reference: 'JOB-10486',
    status: 'SCHEDULED',
    vehicleMake: 'Nissan',
    vehicleModel: 'Patrol Platinum',
    vehicleYear: 2024,
    customerName: 'Sara Al Farsi',
    vehiclePlate: 'AUD-771204',
    scheduledAt: _stamp(13, 30),
  ),
  fixtures.jobSummary(
    id: 'later',
    reference: 'JOB-10487',
    status: 'SCHEDULED',
    vehicleModel: 'Corolla',
    vehicleYear: 2024,
    customerName: 'Khalid Ibrahim',
    vehiclePlate: 'DXB-556210',
    scheduledAt: _stamp(15, 0),
  ),
  fixtures.jobSummary(
    id: 'review',
    reference: 'JOB-10470',
    status: 'PENDING_REVIEW',
    vehicleMake: 'Lexus',
    vehicleModel: 'LX 600',
    vehicleYear: 2024,
    customerName: 'Hessa Al Mazrouei',
    vehiclePlate: 'AUH-119042',
    scheduledAt: _stamp(11, 0),
    completedItems: 30,
    totalItems: 30,
  ),
];

JobSummaryPage _page({List<JobSummary>? items}) {
  final list = items ?? _jobs();
  return JobSummaryPage(
    items: list,
    page: 0,
    size: 50,
    total: list.length,
    totalPages: 1,
  );
}

Future<void> _shot(
  WidgetTester tester, {
  required double width,
  required double height,
  required String name,
  JobSummaryPage? page,
}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final data = page ?? _page();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_SignedIn.new),
        // Never emits, so the screen keeps its online default without the
        // reconnect listener kicking off a real sync in the test.
        connectivityProvider.overrideWith((ref) => const Stream<bool>.empty()),
        syncQueueStatusProvider.overrideWith(
          (ref) async =>
              const SyncQueueStatus(pending: 0, failed: 0, conflicts: 0),
        ),
        technicianJobPageProvider((page: 0, size: 50, status: null))
            .overrideWith((ref) async => data),
        statusesProvider('job').overrideWith(
          (ref) async => const <ReferenceRecord>[
            ReferenceRecord(
              code: 'IN_PROGRESS',
              labelKey: 'shotInProgress',
              tone: 'success',
            ),
            ReferenceRecord(
              code: 'SCHEDULED',
              labelKey: 'shotScheduled',
              tone: 'info',
            ),
            ReferenceRecord(
              code: 'PENDING_REVIEW',
              labelKey: 'shotPendingReview',
            ),
          ],
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const TechnicianJobsCleanPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  testWidgets('shift_390', (tester) async {
    await _shot(tester, width: 390, height: 844, name: 'shift_390');
  });

  testWidgets('shift_390_empty', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'shift_390_empty',
      page: _page(items: const <JobSummary>[]),
    );
  });

  testWidgets('shift_768', (tester) async {
    await _shot(tester, width: 768, height: 1024, name: 'shift_768');
  });

  testWidgets('shift_1024', (tester) async {
    await _shot(tester, width: 1024, height: 768, name: 'shift_1024');
  });
}
