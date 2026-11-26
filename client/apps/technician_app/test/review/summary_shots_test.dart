/// Real-font screenshot evidence for the summary gate (round 1).
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/review/signoff_screen.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import '../support/fixtures.dart' as fixtures;

const Map<String, String> _bundle = <String, String>{
  'technicianQueueItems': '{done} of {total} items',
  'technicianItems': 'Items',
  'technicianItemsAssessed': '{done} of {total} assessed',
  'technicianSignatureTitle': 'Customer signature',
  'technicianSignatureCaptured': 'Signature captured',
  'technicianSyncConflictTitle': 'Sync conflict',
  'technicianNoConflicts': 'No sync conflicts.',
  'technicianDraftScore': 'Draft score',
  'technicianGradeLabel': 'Grade',
  'technicianSafetyCap': 'Safety cap',
  'technicianSummaryCapApplied': 'Applied',
  'technicianSummaryReadyBody': 'Complete the job to send it for review.',
  'technicianReadyToComplete': 'Everything is ready',
  'technicianBlockersToResolve': '{count, plural, =1{1 blocker to resolve} other{{count} blockers to resolve}}',
  'technicianWarningsTitle': 'Warnings',
  'technicianSummaryComplete': 'Complete job',
  'technicianSummaryAddSignature': 'Add signature',
  'technicianSummaryReviewItems': 'Review {count, plural, =1{1 item} other{{count} items}}',
  'technicianSummaryResolveConflicts': 'Resolve conflicts',
  'technicianSignature': 'Signature',
  'commonBack': 'Back',
  'offlineBanner': 'Offline. Work will be saved on this phone.',
  'error': 'Something went wrong',
  'genericError': 'Something went wrong. Try again.',
  'retryAction': 'Retry',
};

Summary _summary({
  List<Blocker> blockers = const [],
  List<Blocker> warnings = const [],
  int? score = 85,
  String? grade = 'A',
  bool cap = false,
  int done = 28,
  int total = 30,
  String status = 'IN_PROGRESS',
}) => Summary(
  jobId: 'job-1001',
  status: status,
  itemsAssessed: done,
  itemsTotal: total,
  score: score,
  gradeCode: grade,
  safetyCapApplied: cap,
  safetyCapReason: cap ? 'Safety cap applied.' : null,
  blockers: blockers,
  warnings: warnings,
);

Review _review({
  List<Blocker> blockers = const [],
  List<Blocker> warnings = const [],
}) => Review(
  jobId: 'job-1001',
  status: 'IN_PROGRESS',
  blockers: blockers,
  warnings: warnings,
  findings: const [],
);

SyncConflictRecord _conflict({String id = 'conflict-1', bool open = true}) =>
    SyncConflictRecord(
      id: id,
      jobId: 'job-1001',
      itemCode: 'brake_pads_front',
      clientRevision: 3,
      serverRevision: 4,
      serverPayloadJson: null,
      clientPayloadJson: null,
      state: open ? 'OPEN' : 'CLOSED',
      createdAt: DateTime.utc(2026, 3, 12),
    );

ProviderScope _scope({
  required Widget child,
  required Summary summary,
  Review? review,
  List<SyncConflictRecord> conflicts = const [],
  String jobStatus = 'IN_PROGRESS',
  bool online = true,
}) {
  return ProviderScope(
    overrides: [
      technicianSummaryProvider('job-1001')
          .overrideWith((ref) async => summary),
      technicianReviewProvider('job-1001')
          .overrideWith((ref) async => review ?? _review()),
      technicianConflictsProvider('job-1001')
          .overrideWith((ref) async => conflicts),
      technicianJobSummaryProvider('job-1001')
          .overrideWith((ref) async => fixtures.jobSummary(status: jobStatus)),
      statusesProvider('job').overrideWith((ref) async => <ReferenceRecord>[]),
      connectivityProvider.overrideWith(
        (ref) => Stream<bool>.fromIterable([online]),
      ),
    ],
    child: child,
  );
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  Summary summary, {
  required double width,
  required double height,
  Locale locale = const Locale('en'),
  TextDirection direction = TextDirection.ltr,
  TextScaler scaler = TextScaler.noScaling,
  List<SyncConflictRecord> conflicts = const [],
  String jobStatus = 'IN_PROGRESS',
  bool online = true,
}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _scope(
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: scaler, disableAnimations: true),
              child: Directionality(
                textDirection: direction,
                child: Scaffold(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerLow,
                  body: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: const TechnicianSummaryPage(jobId: 'job-1001'),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      summary: summary,
      conflicts: conflicts,
      jobStatus: jobStatus,
      online: online,
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

  testWidgets('summary_390_data', (tester) async {
    await _shot(
      tester,
      'summary_390_data',
      _summary(
        blockers: [
          fixtures.blocker(
            code: 'EVIDENCE_MISSING',
            itemCode: 'brake_pads_front',
            messageEn: 'Photo evidence is missing.',
          ),
        ],
      ),
      width: 390,
      height: 844,
    );
  });

  testWidgets('summary_768_data', (tester) async {
    await _shot(
      tester,
      'summary_768_data',
      _summary(
        blockers: [
          fixtures.blocker(
            code: 'EVIDENCE_MISSING',
            itemCode: 'brake_pads_front',
            messageEn: 'Photo evidence is missing.',
          ),
          fixtures.blocker(code: 'SIGNATURE_MISSING'),
        ],
      ),
      width: 768,
      height: 1024,
    );
  });

  testWidgets('summary_1024_data', (tester) async {
    await _shot(
      tester,
      'summary_1024_data',
      _summary(
        blockers: [
          fixtures.blocker(
            code: 'EVIDENCE_MISSING',
            itemCode: 'brake_pads_front',
            messageEn: 'Photo evidence is missing.',
          ),
        ],
        warnings: [
          fixtures.blocker(
            code: 'ATTENTION_ONLY',
            messageEn: 'Rear pads are wearing thin.',
          ),
        ],
      ),
      width: 1024,
      height: 768,
    );
  });

  testWidgets('summary_390_rtl', (tester) async {
    await _shot(
      tester,
      'summary_390_rtl',
      _summary(
        blockers: [
          fixtures.blocker(
            code: 'EVIDENCE_MISSING',
            itemCode: 'brake_pads_front',
            messageEn: 'Photo evidence is missing.',
          ),
        ],
      ),
      width: 390,
      height: 844,
      locale: const Locale('ar'),
      direction: TextDirection.rtl,
    );
  });

  testWidgets('summary_390_no_blockers', (tester) async {
    await _shot(
      tester,
      'summary_390_no_blockers',
      _summary(done: 30),
      width: 390,
      height: 844,
    );
  });

  testWidgets('summary_390_blockers', (tester) async {
    await _shot(
      tester,
      'summary_390_blockers',
      _summary(
        blockers: [
          fixtures.blocker(
            code: 'EVIDENCE_MISSING',
            itemCode: 'brake_pads_front',
            messageEn: 'Photo evidence is missing.',
          ),
          fixtures.blocker(
            code: 'EVIDENCE_MISSING',
            itemCode: 'brake_pads_rear',
            messageEn: 'Photo evidence is missing.',
          ),
          fixtures.blocker(code: 'SIGNATURE_MISSING'),
          fixtures.blocker(code: 'SYNC_CONFLICT'),
        ],
        warnings: [
          fixtures.blocker(
            code: 'ATTENTION_ONLY',
            messageEn: 'Rear pads are wearing thin.',
          ),
        ],
      ),
      width: 390,
      height: 844,
    );
  });

  testWidgets('summary_390_conflicts', (tester) async {
    await _shot(
      tester,
      'summary_390_conflicts',
      _summary(done: 30),
      width: 390,
      height: 844,
      conflicts: [
        _conflict(),
        _conflict(id: 'conflict-2'),
      ],
    );
  });

  testWidgets('summary_390_error', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        technicianSummaryProvider('job-1001').overrideWithValue(
          AsyncValue<Summary>.error(Exception('boom'), StackTrace.empty),
        ),
        technicianReviewProvider('job-1001')
            .overrideWith((ref) async => _review()),
        technicianConflictsProvider('job-1001')
            .overrideWith((ref) async => const <SyncConflictRecord>[]),
        technicianJobSummaryProvider('job-1001')
            .overrideWith((ref) async => fixtures.jobSummary()),
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: UncontrolledProviderScope(
          container: container,
          child: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 390,
                height: 844,
                child: TechnicianSummaryPage(jobId: 'job-1001'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/summary_390_error.png'),
    );
  });

  testWidgets('summary_390_read_only', (tester) async {
    await _shot(
      tester,
      'summary_390_read_only',
      _summary(),
      width: 390,
      height: 844,
      jobStatus: 'PENDING_REVIEW',
    );
  });

  testWidgets('summary_390_15x', (tester) async {
    await _shot(
      tester,
      'summary_390_15x',
      _summary(
        blockers: [
          fixtures.blocker(
            code: 'EVIDENCE_MISSING',
            itemCode: 'brake_pads_front',
            messageEn: 'Photo evidence is missing.',
          ),
        ],
      ),
      width: 390,
      height: 844,
      scaler: const TextScaler.linear(1.5),
    );
  });
}
