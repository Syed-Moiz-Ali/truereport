/// Widget contract for the summary gate: header, score, blockers, warnings,
/// footer naming and read-only mode. The pure gate stays pinned in
/// `signoff_gate_test.dart`.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
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

SyncConflictRecord _conflict() => SyncConflictRecord(
  id: 'conflict-1',
  jobId: 'job-1001',
  itemCode: 'brake_pads_front',
  clientRevision: 3,
  serverRevision: 4,
  serverPayloadJson: null,
  clientPayloadJson: null,
  state: 'OPEN',
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
      connectivityProvider.overrideWith((ref) => Stream.value(online)),
    ],
    child: child,
  );
}

Widget _host(Widget child, {double width = 390}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      backgroundColor: AppTheme.light.colorScheme.surfaceContainerLow,
      body: Center(
        child: SizedBox(width: width, height: 844, child: child),
      ),
    ),
  );
}

Widget _page() => const TechnicianSummaryPage(jobId: 'job-1001');

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  group('header', () {
    testWidgets('shows vehicle, plate, reference, status and counts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scope(child: _host(_page()), summary: _summary()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Toyota Land Cruiser 2023'), findsOneWidget);
      expect(find.text('AUD-354626'), findsOneWidget);
      expect(find.text('TR-2026-0412'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('28 of 30 items'), findsOneWidget);
    });
  });

  group('score block', () {
    testWidgets('shows score, grade and the applied cap', (tester) async {
      await tester.pumpWidget(
        _scope(child: _host(_page()), summary: _summary(cap: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('85'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Applied'), findsOneWidget);
      expect(find.text('Safety cap applied.'), findsOneWidget);
    });

    testWidgets('omitted cleanly when the summary carries none', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scope(
          child: _host(_page()),
          summary: _summary(score: null, grade: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Draft score'), findsNothing);
      expect(find.text('Grade'), findsNothing);
    });
  });

  group('blockers', () {
    Blocker itemBlocker() => fixtures.blocker(
      code: 'EVIDENCE_MISSING',
      itemCode: 'brake_pads_front',
      messageEn: 'Photo evidence is missing.',
    );

    testWidgets('item rows jump to the item route', (tester) async {
      String? location;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => _scope(
              child: _host(_page()),
              summary: _summary(blockers: [itemBlocker()]),
            ),
          ),
          GoRoute(
            path: '/jobs/:jobId/items/:itemCode',
            builder: (context, state) {
              location =
                  '/jobs/${state.pathParameters['jobId']}/items/${state.pathParameters['itemCode']}';
              return const Scaffold(body: Text('item'));
            },
          ),
          GoRoute(
            path: '/jobs/:jobId/signature',
            builder: (context, state) => const Scaffold(body: Text('sign')),
          ),
          GoRoute(
            path: '/sync',
            builder: (context, state) => const Scaffold(body: Text('sync')),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 BLOCKER TO RESOLVE'), findsOneWidget);
      await tester.tap(find.text('Photo evidence is missing.'));
      await tester.pumpAndSettle();

      expect(location, '/jobs/job-1001/items/brake_pads_front');
    });

    testWidgets('signature rows jump to the signature route', (tester) async {
      String? location;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => _scope(
              child: _host(_page()),
              summary: _summary(
                done: 30,
                blockers: [fixtures.blocker(code: 'SIGNATURE_MISSING')],
              ),
            ),
          ),
          GoRoute(
            path: '/jobs/:jobId/signature',
            builder: (context, state) {
              location = '/jobs/${state.pathParameters['jobId']}/signature';
              return const Scaffold(body: Text('sign'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Customer signature is missing.'));
      await tester.pumpAndSettle();
      expect(location, '/jobs/job-1001/signature');
    });

    testWidgets('sync rows jump to /sync', (tester) async {
      String? location;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => _scope(
              child: _host(_page()),
              summary: _summary(
                blockers: [fixtures.blocker(code: 'SYNC_CONFLICT')],
              ),
            ),
          ),
          GoRoute(
            path: '/sync',
            builder: (context, state) {
              location = '/sync';
              return const Scaffold(body: Text('sync'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Customer signature is missing.'));
      await tester.pumpAndSettle();
      expect(location, '/sync');
    });
  });

  group('warnings', () {
    testWidgets('warnings list quietly without actions', (tester) async {
      await tester.pumpWidget(
        _scope(
          child: _host(_page()),
          summary: _summary(
            warnings: [
              fixtures.blocker(
                code: 'ATTENTION_ONLY',
                messageEn: 'Rear pads are wearing thin.',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WARNINGS'), findsOneWidget);
      expect(find.text('Rear pads are wearing thin.'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });

  group('footer', () {
    testWidgets('names the next fix: review items first', (tester) async {
      await tester.pumpWidget(
        _scope(
          child: _host(_page()),
          summary: _summary(
            blockers: [
              fixtures.blocker(
                code: 'EVIDENCE_MISSING',
                itemCode: 'brake_pads_front',
                messageEn: 'Photo evidence is missing.',
              ),
              fixtures.blocker(code: 'SIGNATURE_MISSING'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review 1 item'), findsOneWidget);
      expect(find.text('Signature'), findsOneWidget);
    });

    testWidgets('names the next fix: conflicts before signature', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scope(
          child: _host(_page()),
          summary: _summary(
            done: 30,
            blockers: [fixtures.blocker(code: 'SIGNATURE_MISSING')],
          ),
          conflicts: [_conflict()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resolve conflicts'), findsOneWidget);
      expect(find.text('Signature'), findsOneWidget);
    });

    testWidgets('names the next fix: signature when items are done', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scope(
          child: _host(_page()),
          summary: _summary(
            done: 30,
            blockers: [fixtures.blocker(code: 'SIGNATURE_MISSING')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add signature'), findsOneWidget);
      expect(find.text('Signature'), findsNothing);
    });

    testWidgets('clean queue completes the job', (tester) async {
      await tester.pumpWidget(
        _scope(child: _host(_page()), summary: _summary(done: 30)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete job'), findsOneWidget);
      expect(find.text('Everything is ready'), findsOneWidget);
      expect(
        find.text('Complete the job to send it for review.'),
        findsOneWidget,
      );
      expect(find.text('Signature'), findsNothing);
    });
  });

  group('read-only', () {
    testWidgets('one Back action, receipt style, no complete', (tester) async {
      await tester.pumpWidget(
        _scope(
          child: _host(_page()),
          summary: _summary(),
          jobStatus: 'PENDING_REVIEW',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Complete job'), findsNothing);
      expect(find.text('Review 1 item'), findsNothing);
      expect(find.text('Add signature'), findsNothing);
      expect(find.text('Signature'), findsNothing);
    });
  });

  group('states', () {
    testWidgets('conflicts show their panel and count', (tester) async {
      await tester.pumpWidget(
        _scope(
          child: _host(_page()),
          summary: _summary(done: 30),
          conflicts: [_conflict()],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resolve conflicts'), findsOneWidget);
    });

    testWidgets('offline shows the offline strip', (tester) async {
      await tester.pumpWidget(
        _scope(child: _host(_page()), summary: _summary(), online: false),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Offline. Work will be saved on this phone.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('error keeps retry', (tester) async {
      final container = ProviderContainer(
        overrides: [
          technicianSummaryProvider('job-1001').overrideWithValue(
            AsyncValue<Summary>.error(Exception('boom'), StackTrace.empty),
          ),
          technicianReviewProvider('job-1001')
              .overrideWith((ref) async => _review()),
          technicianConflictsProvider('job-1001')
              .overrideWith((ref) async => const <SyncConflictRecord>[]),
          technicianJobSummaryProvider('job-1001').overrideWith(
            (ref) async => fixtures.jobSummary(status: 'IN_PROGRESS'),
          ),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _host(const TechnicianSummaryPage(jobId: 'job-1001')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('resilience', () {
    testWidgets('survives 2x in RTL without clipping', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            technicianSummaryProvider('job-1001').overrideWith(
              (ref) async => _summary(
                blockers: [
                  fixtures.blocker(
                    code: 'EVIDENCE_MISSING',
                    itemCode: 'brake_pads_front',
                    messageEn: 'Photo evidence is missing.',
                  ),
                ],
              ),
            ),
            technicianReviewProvider('job-1001')
                .overrideWith((ref) async => _review()),
            technicianConflictsProvider('job-1001')
                .overrideWith((ref) async => const <SyncConflictRecord>[]),
            technicianJobSummaryProvider('job-1001').overrideWith(
              (ref) async => fixtures.jobSummary(status: 'IN_PROGRESS'),
            ),
            connectivityProvider.overrideWith((ref) => const Stream<bool>.empty()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('ar'),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  backgroundColor:
                      AppTheme.light.colorScheme.surfaceContainerLow,
                  body: Center(
                    child: SizedBox(width: 390, height: 844, child: _page()),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Front brake pads'), findsNothing);
      expect(find.text('Toyota Land Cruiser 2023'), findsOneWidget);
    });
  });
}
