/// Widget contract for the deck: header, tabs, board, primary and facts.
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
  _job(id: 'next', vehicle: 'Nissan Patrol 2022', time: '13:30'),
  _job(id: 'then', vehicle: 'Toyota Corolla 2024', time: '15:00'),
];

Widget _host(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  bool rtl = false,
  bool reduceMotion = false,
  double width = 390,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: textScaler, disableAnimations: reduceMotion),
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  group('DeckBoard', () {
    testWidgets('front card carries status, vehicle, progress and reference', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(DeckBoard(jobs: _three(), frontId: 'front', onSelect: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Toyota Land Cruiser 2023'), findsOneWidget);
      expect(find.text('AUD-354626'), findsOneWidget);
      expect(find.text('Ahmed Al Mansoori'), findsWidgets);
      expect(find.text('9 of 30 items'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('JOB-659515E0'), findsOneWidget);
    });

    testWidgets('next-up block shows only on the front card', (tester) async {
      await tester.pumpWidget(
        _host(DeckBoard(jobs: _three(), frontId: 'front', onSelect: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('10. Front brake pads'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          DeckBoard(
            jobs: _three()
                .map(
                  (job) =>
                      _job(id: job.id, vehicle: job.vehicle, time: job.time),
                )
                .toList(),
            frontId: 'front',
            onSelect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEXT UP'), findsNothing);
    });

    testWidgets('peeks label NEXT / THEN and select on tap', (tester) async {
      DeckJob? selected;
      await tester.pumpWidget(
        _host(
          DeckBoard(
            jobs: _three(),
            frontId: 'front',
            onSelect: (job) => selected = job,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEXT'), findsOneWidget);
      expect(find.text('THEN'), findsOneWidget);
      expect(find.text('Nissan Patrol 2022'), findsOneWidget);
      expect(find.text('Toyota Corolla 2024'), findsOneWidget);

      await tester.tap(find.text('Nissan Patrol 2022'));
      await tester.pumpAndSettle();
      expect(selected?.id, 'next');
    });

    testWidgets('a lone job renders no peeks', (tester) async {
      await tester.pumpWidget(
        _host(
          DeckBoard(
            jobs: <DeckJob>[_three().first],
            frontId: 'front',
            onSelect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEXT'), findsNothing);
      expect(find.text('THEN'), findsNothing);
      expect(find.text('Toyota Land Cruiser 2023'), findsOneWidget);
    });

    testWidgets('survives 1.5x in RTL without clipping identity', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          DeckBoard(jobs: _three(), frontId: 'front', onSelect: (_) {}),
          textScaler: const TextScaler.linear(1.5),
          rtl: true,
          width: 390,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Toyota Land Cruiser 2023'), findsOneWidget);
      expect(find.text('AUD-354626'), findsOneWidget);
    });

    testWidgets('see-all link exposes its label and tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(DeckSeeAllLink(onTap: () => tapped = true)),
      );

      await tester.tap(find.text('See all jobs'));
      expect(tapped, isTrue);
    });
  });

  group('DeckTabs', () {
    testWidgets('shows three sets with counts and reports selection', (
      tester,
    ) async {
      DeckTab? selected;
      await tester.pumpWidget(
        _host(
          DeckTabs(
            today: 4,
            upcoming: 2,
            unfinished: 2,
            selected: DeckTab.today,
            onSelect: (tab) => selected = tab,
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Unfinished'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('Upcoming'));
      expect(selected, DeckTab.upcoming);
    });

    testWidgets('survives 1.5x in RTL', (tester) async {
      await tester.pumpWidget(
        _host(
          DeckTabs(
            today: 12,
            upcoming: 2,
            unfinished: 2,
            selected: DeckTab.unfinished,
            onSelect: (_) {},
          ),
          textScaler: const TextScaler.linear(1.5),
          rtl: true,
          width: 390,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('DeckPrimaryButton', () {
    testWidgets('is 56 px, taps, and mirrors the arrow in RTL', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          DeckPrimaryButton(
            label: 'Continue inspection',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(tester.getSize(find.byType(DeckPrimaryButton)).height, 56);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      await tester.tap(find.byType(DeckPrimaryButton));
      expect(tapped, isTrue);

      await tester.pumpWidget(
        _host(
          DeckPrimaryButton(label: 'Continue inspection', onPressed: () {}),
          rtl: true,
        ),
      );
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });

  group('DeckHeader', () {
    testWidgets('renders eyebrow, title, counts and profile tap', (
      tester,
    ) async {
      var opened = false;
      await tester.pumpWidget(
        _host(
          DeckHeader(
            toStart: 4,
            inProgress: 1,
            technicianName: 'Omar',
            onProfile: () => opened = true,
          ),
        ),
      );

      expect(find.text('TRUEREPORT · TECHNICIAN'), findsOneWidget);
      expect(find.text('Your ramp'), findsOneWidget);
      expect(find.text('4 to start · 1 in progress'), findsOneWidget);

      final handle = tester.ensureSemantics();
      await tester.tap(find.bySemanticsLabel('Profile'));
      expect(opened, isTrue);
      handle.dispose();
    });
  });

  group('DeckFactsPane', () {
    testWidgets('renders facts and one open action', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        _host(
          DeckFactsPane(
            job: _three().first,
            scheduleLabel: 'Today, 11:50',
            onOpen: () => opened = true,
          ),
        ),
      );

      expect(find.text('Toyota Land Cruiser 2023'), findsOneWidget);
      expect(find.text('Open job'), findsOneWidget);

      await tester.tap(find.text('Open job'));
      expect(opened, isTrue);
    });
  });

  group('DeckSkeleton', () {
    testWidgets('honours reduce motion and survives 1.5x in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DeckSkeleton(),
          reduceMotion: true,
          textScaler: const TextScaler.linear(1.5),
          rtl: true,
          width: 390,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
