/// Smoke test for the shift queue page at phone and tablet widths.
///
/// The page must render from the same providers the app uses, so the layout is
/// exercised for real (tabs, NOW card, agenda) instead of only the composed
/// screenshot widgets.
library;

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/jobs/technician_jobs_clean_page.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import '../support/fixtures.dart' as fixtures;

class _SignedOut extends AuthController {
  @override
  Future<Session?> build() async => null;
}

const Map<String, String> _bundle = <String, String>{
  'technicianDeckEyebrow': 'TRUEREPORT · TECHNICIAN',
  'technicianQueueSummary': '{toStart} to start · {inProgress} in progress',
  'technicianJobSearch': 'Search jobs',
  'technicianJobSearchHint': 'Plate, customer, job or VIN',
  'technicianFilter': 'Filter',
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
  'roleTechnician': 'Technician',
};

JobSummary _job({
  required String id,
  required String status,
  required String scheduledAt,
  String model = 'Land Cruiser',
  int done = 0,
}) => fixtures.jobSummary(
  id: id,
  status: status,
  vehicleModel: model,
  scheduledAt: scheduledAt,
  startedAt: status == 'IN_PROGRESS' ? scheduledAt : null,
  completedItems: done,
  totalItems: 30,
);

JobSummaryPage _page({List<JobSummary>? items}) {
  final list =
      items ??
      <JobSummary>[
        _job(
          id: 'live',
          status: 'IN_PROGRESS',
          scheduledAt: '2026-03-12T09:00:00',
          done: 12,
        ),
        _job(
          id: 'soon',
          status: 'SCHEDULED',
          model: 'Patrol Platinum',
          scheduledAt: '2026-03-12T13:30:00',
        ),
      ];
  return JobSummaryPage(
    items: list,
    page: 0,
    size: 50,
    total: list.length,
    totalPages: 1,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required JobSummaryPage page,
  double scale = 1,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_SignedOut.new),
        connectivityProvider.overrideWith((ref) => Stream<bool>.value(false)),
        syncQueueStatusProvider.overrideWith(
          (ref) async =>
              const SyncQueueStatus(pending: 0, failed: 0, conflicts: 0),
        ),
        technicianJobPageProvider((page: 0, size: 50, status: null))
            .overrideWith((ref) async => page),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: scale == 1
            ? null
            : (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
        home: const TechnicianJobsCleanPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  testWidgets('renders the shift queue on a phone', (tester) async {
    await _pump(tester, size: const Size(390, 844), page: _page());
    expect(tester.takeException(), isNull);
    expect(find.text('Continue inspection'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('renders the master-detail layout on a tablet', (tester) async {
    await _pump(tester, size: const Size(1024, 768), page: _page());
    expect(tester.takeException(), isNull);
    expect(find.text('Continue inspection'), findsOneWidget);
    expect(find.text('Done today'), findsOneWidget);
  });

  testWidgets('shows one empty state when nothing is assigned', (tester) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      page: _page(items: const <JobSummary>[]),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('You are all caught up'), findsOneWidget);
    expect(find.textContaining('to start'), findsNothing);
  });

  testWidgets('holds at 130% text scaling on a phone', (tester) async {
    await _pump(tester, size: const Size(390, 844), page: _page(), scale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Continue inspection'), findsOneWidget);
  });

  testWidgets('a search with no match hides the NOW card', (tester) async {
    await _pump(tester, size: const Size(390, 844), page: _page());
    await tester.tap(find.bySemanticsLabel('Search jobs'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nothing-matches');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('No jobs match your search'), findsOneWidget);
    expect(find.text('Continue inspection'), findsNothing);
  });
}
