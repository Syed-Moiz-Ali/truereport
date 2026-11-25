/// Real-font screenshot evidence for the deck (round 1).
///
/// Composed from the same widgets the page renders, with the same bundle
/// copy, at the required viewports and states. Run with `--update-goldens`
/// only after viewing the diff and confirming it is the intended deck.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/jobs/queue/deck/deck_board.dart';
import 'package:technician_app/src/features/jobs/queue/deck/deck_facts.dart';
import 'package:technician_app/src/features/jobs/queue/deck/deck_header.dart';
import 'package:technician_app/src/features/jobs/queue/deck/deck_primary.dart';
import 'package:technician_app/src/features/jobs/queue/deck/deck_sets.dart';
import 'package:technician_app/src/features/jobs/queue/deck/deck_skeleton.dart';
import 'package:technician_app/src/features/jobs/queue/deck/deck_tabs.dart';
import 'package:technician_app/src/features/jobs/queue/jobs_queue_primitives.dart';
import 'package:technician_app/src/features/jobs/queue/queue_model.dart';

const Map<String, String> _bundle = <String, String>{
  'technicianDeckEyebrow': 'TRUEREPORT · TECHNICIAN',
  'technicianDeckTitle': 'Your ramp',
  'technicianQueueSummary': '{toStart} to start · {inProgress} in progress',
  'technicianProfileTitle': 'Profile',
  'technicianQueueSectionToday': 'Today',
  'technicianQueueSectionUpcoming': 'Upcoming',
  'technicianQueueSectionUnfinished': 'Unfinished',
  'technicianDeckNext': 'Next',
  'technicianDeckThen': 'Then',
  'technicianNextUp': 'Next up',
  'technicianQueueItems': '{done} of {total} items',
  'technicianDeckSeeAll': 'See all jobs',
  'technicianVehicle': 'Vehicle',
  'technicianCustomer': 'Customer',
  'status': 'Status',
  'technicianScheduledAt': 'Scheduled',
  'jobReferenceLabel': 'Reference',
  'jobsOpenJob': 'Open job',
  'technicianQueueActionView': 'View',
  'technicianRefresh': 'Refresh',
  'technicianClear': 'Clear',
  'technicianAllCaughtUp': 'You are all caught up',
  'technicianJobListEmpty': 'No inspections are assigned to you.',
  'technicianRampNothingToday': 'Nothing scheduled for today',
  'technicianNoJobsThisDay': 'No jobs on this day',
  'technicianRampNothingTodayBody': 'Your next job is {date}.',
  'technicianPickAnotherDay': 'Pick another day or clear your filters.',
  'noResults': 'No results',
  'technicianNoSearchResults': 'No jobs match your search.',
  'error': 'Something went wrong',
  'genericError': 'Something went wrong. Try again.',
  'retryAction': 'Retry',
  'offlineBanner': 'Offline. Work will be saved on this phone.',
};

DeckJob _job({
  required String id,
  required String vehicle,
  String plate = 'AUD-354626',
  String customer = 'Ahmed Al Mansoori',
  String reference = 'JOB-659515E0',
  String time = '11:50',
  String status = 'In progress',
  StatusTone tone = StatusTone.success,
  int done = 9,
  int total = 30,
  QueueVerb verb = QueueVerb.continueJob,
  String? nextUp,
}) => DeckJob(
  id: id,
  vehicle: vehicle,
  plate: plate,
  customer: customer,
  reference: reference,
  time: time,
  statusLabel: status,
  tone: tone,
  done: done,
  total: total,
  verb: verb,
  nextUp: nextUp,
);

List<DeckJob> _three() => <DeckJob>[
  _job(
    id: 'front',
    vehicle: 'Toyota Land Cruiser 2023',
    time: '11:50',
    nextUp: '10. Front brake pads',
  ),
  _job(
    id: 'next',
    vehicle: 'Nissan Patrol 2022',
    time: '13:30',
    plate: 'AUD-771204',
    customer: 'Sara Al Farsi',
    reference: 'JOB-659516A1',
    status: 'Scheduled',
    tone: StatusTone.info,
  ),
  _job(
    id: 'then',
    vehicle: 'Toyota Corolla 2024',
    time: '15:00',
    plate: '',
    customer: 'Khalid Ibrahim',
    reference: 'JOB-659517B2',
    status: 'Scheduled',
    tone: StatusTone.info,
    done: 0,
    total: 30,
  ),
];

/// The narrow page column, as `TechnicianJobsCleanPage` renders it.
Widget _narrowColumn({bool offline = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      const DeckHeader(
        toStart: 4,
        inProgress: 1,
        technicianName: 'Omar Haddad',
        onProfile: null,
      ),
      const SizedBox(height: 12),
      DeckTabs(
        today: 4,
        upcoming: 2,
        unfinished: 2,
        selected: DeckTab.today,
        onSelect: (_) {},
      ),
      const SizedBox(height: 12),
      if (offline)
        const QueueNote(
          icon: Icons.cloud_off_rounded,
          label: 'Offline. Work will be saved on this phone.',
        ),
      if (offline) const SizedBox(height: 12),
      DeckBoard(jobs: _three(), frontId: 'front', onSelect: (_) {}),
      const SizedBox(height: 4),
      Center(child: DeckSeeAllLink(onTap: () {})),
      const SizedBox(height: 12),
      DeckPrimaryButton(label: 'Continue inspection', onPressed: () {}),
      const SizedBox(height: 16),
    ],
  );
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  Widget child, {
  required double width,
  required double height,
  Locale locale = const Locale('en'),
  TextScaler scaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: scaler, disableAnimations: true),
            child: Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Scaffold(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerLow,
                body: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: width >= 1024 ? 24 : 16,
                    vertical: 12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: width >= 1024 ? 1120 : 560,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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

  testWidgets('deck_390_data', (tester) async {
    await _shot(
      tester,
      'deck_390_data',
      _narrowColumn(),
      width: 390,
      height: 844,
    );
  });

  testWidgets('deck_768_data', (tester) async {
    await _shot(
      tester,
      'deck_768_data',
      _narrowColumn(),
      width: 768,
      height: 1024,
    );
  });

  testWidgets('deck_1024_data', (tester) async {
    final jobs = _three();
    await _shot(
      tester,
      'deck_1024_data',
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeckBoard(jobs: jobs, frontId: 'front', onSelect: (_) {}),
                const SizedBox(height: 4),
                Center(child: DeckSeeAllLink(onTap: () {})),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: DeckFactsPane(
              job: jobs.first,
              scheduleLabel: 'Today, 11:50',
              onOpen: () {},
            ),
          ),
        ],
      ),
      width: 1024,
      height: 768,
    );
  });

  testWidgets('deck_390_rtl', (tester) async {
    await _shot(
      tester,
      'deck_390_rtl',
      _narrowColumn(),
      width: 390,
      height: 844,
      locale: const Locale('ar'),
    );
  });

  testWidgets('deck_390_empty', (tester) async {
    await _shot(
      tester,
      'deck_390_empty',
      const QueueEmptyPanel(
        title: 'Nothing scheduled for today',
        body: 'Your next job is Tomorrow.',
      ),
      width: 390,
      height: 844,
    );
  });

  testWidgets('deck_390_no_results', (tester) async {
    await _shot(
      tester,
      'deck_390_no_results',
      QueueEmptyPanel(
        showRoute: false,
        title: 'No results',
        body: 'No jobs match your search.',
        action: QueueButton(
          label: 'Clear',
          variant: QueueButtonVariant.soft,
          onPressed: () {},
        ),
      ),
      width: 390,
      height: 844,
    );
  });

  testWidgets('deck_390_error', (tester) async {
    await _shot(
      tester,
      'deck_390_error',
      QueueErrorPanel(
        title: 'Something went wrong',
        body: 'Something went wrong. Try again.',
        retryLabel: 'Retry',
        onRetry: () {},
      ),
      width: 390,
      height: 844,
    );
  });

  testWidgets('deck_390_offline', (tester) async {
    await _shot(
      tester,
      'deck_390_offline',
      _narrowColumn(offline: true),
      width: 390,
      height: 844,
    );
  });

  testWidgets('deck_390_read_only', (tester) async {
    await _shot(
      tester,
      'deck_390_read_only',
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeckBoard(
            jobs: <DeckJob>[
              _job(
                id: 'done',
                vehicle: 'Toyota Land Cruiser 2023',
                status: 'Pending review',
                tone: StatusTone.warning,
                done: 30,
                total: 30,
                verb: QueueVerb.view,
              ),
            ],
            frontId: 'done',
            onSelect: (_) {},
          ),
          const SizedBox(height: 12),
          DeckPrimaryButton(label: 'View', onPressed: () {}),
        ],
      ),
      width: 390,
      height: 844,
    );
  });

  testWidgets('deck_390_loading', (tester) async {
    await _shot(
      tester,
      'deck_390_loading',
      const DeckSkeleton(),
      width: 390,
      height: 844,
    );
  });

  testWidgets('deck_390_15x', (tester) async {
    await _shot(
      tester,
      'deck_390_15x',
      _narrowColumn(),
      width: 390,
      height: 844,
      scaler: const TextScaler.linear(1.5),
    );
  });
}
