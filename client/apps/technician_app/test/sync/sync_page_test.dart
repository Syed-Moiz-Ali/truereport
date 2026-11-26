/// Widget tests for the sync outbox and conflict screens.
///
/// These pump the real pages with the app's providers overridden, so the
/// layout, states and single-primary rule are exercised as shipped.
library;

import 'dart:convert';

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/sync/sync_conflict_page.dart';
import 'package:technician_app/src/features/sync/sync_providers.dart';
import 'package:technician_app/src/features/sync/sync_screen.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

class _SignedIn extends AuthController {
  @override
  Future<Session?> build() async => const Session(
    accessToken: 'test-token',
    refreshToken: 'test-refresh',
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
  'technicianSyncTitle': 'Sync',
  'technicianSyncChangesOnPhone': '{count, plural, =1{1 change on this phone} other{{count} changes on this phone}}',
  'technicianAllSynced': 'No changes waiting to sync',
  'technicianSyncAllSafe': 'Everything on this phone has reached the server.',
  'technicianSyncSavedHint':
      'Saved safely. They upload as soon as you are back online.',
  'technicianSyncOnline': 'Online',
  'technicianSyncOffline': 'Offline',
  'technicianSyncQueuedChanges': 'Queued changes',
  'technicianConflicts': 'Conflicts',
  'technicianSyncServerChanges': '{count, plural, =1{1 item changed on the server} other{{count} items changed on the server}}',
  'technicianSyncConflictHint':
      'Review each one before this job can be completed.',
  'technicianSyncConflictTitle': 'Sync conflict',
  'technicianConflictJob': 'Job {jobId}',
  'syncJobRef': 'Job #{jobId}',
  'technicianSyncPendingCount': '{count} waiting to sync',
  'syncNow': 'Sync now',
  'technicianSyncLastError': 'Last error',
  'technicianSyncAttempts':
      '{count, plural, =1{1 attempt} other{{count} attempts}}',
  'technicianOpAssessment': 'Inspection answer',
  'technicianOpEvidence': 'Photos',
  'technicianOpCustomer': 'Customer details',
  'technicianOpVehicle': 'Vehicle details',
  'technicianOpConsent': 'Consent',
  'technicianConflictUseServer': 'Use the server version',
  'technicianConflictPhoneHint':
      'Reloading the server version discards the change made on this phone.',
  'technicianConflictRevalidate': 'After reloading, revalidate this item.',
  'technicianConflictCompare': 'What differs',
  'technicianConflictPhone': 'On this phone',
  'technicianConflictServer': 'On the server',
  'technicianConflictOnlyPhone': 'Only on this phone',
  'technicianConflictOnlyServer': 'Only on the server',
  'technicianConflictPhoneRev': 'Phone rev',
  'technicianConflictServerRev': 'Server rev',
  'technicianConflictUnavailable': 'This conflict is no longer open.',
  'technicianSyncNothing': 'Nothing waiting to sync.',
  'technicianConflictReloaded':
      'Server state reloaded. Revalidate the affected items.',
  'error': 'Something went wrong',
  'genericError': 'Something went wrong. Try again.',
  'retryAction': 'Retry',
  'shotPending': 'Pending',
  'shotFailed': 'Failed',
  'shotSyncing': 'Syncing',
};

List<SyncOperation> _operations() => <SyncOperation>[
  SyncOperation(
    id: 'op-1',
    jobId: 'job-10485',
    type: 'assessment',
    payload: const <String, dynamic>{'itemCode': 'BRK-FRONT-01'},
    state: 'PENDING',
    attempts: 1,
    lastError: null,
    createdAt: DateTime(2020, 1, 2, 9, 12),
  ),
  SyncOperation(
    id: 'op-2',
    jobId: 'job-10485',
    type: 'evidence',
    payload: const <String, dynamic>{'itemCode': 'BRK-FRONT-01'},
    state: 'SYNCING',
    attempts: 1,
    lastError: null,
    createdAt: DateTime(2020, 1, 2, 9, 18),
  ),
  SyncOperation(
    id: 'op-3',
    jobId: 'job-10485',
    type: 'assessment',
    payload: const <String, dynamic>{'itemCode': 'TIRE-REAR-L'},
    state: 'FAILED',
    attempts: 3,
    lastError: 'Server rejected the answer (422)',
    createdAt: DateTime(2020, 1, 2, 9, 26),
  ),
  SyncOperation(
    id: 'op-4',
    jobId: 'job-10485',
    type: 'customer',
    payload: const <String, dynamic>{},
    state: 'PENDING',
    attempts: 1,
    lastError: null,
    createdAt: DateTime(2020, 1, 2, 9, 31),
  ),
  SyncOperation(
    id: 'op-5',
    jobId: 'job-10462',
    type: 'vehicle',
    payload: const <String, dynamic>{},
    state: 'PENDING',
    attempts: 1,
    lastError: null,
    createdAt: DateTime(2020, 1, 2, 10, 4),
  ),
];

List<SyncConflictRecord> _conflicts() => <SyncConflictRecord>[
  SyncConflictRecord(
    id: 'conflict-1',
    jobId: 'job-10485',
    itemCode: 'BRK-FRONT-01',
    clientRevision: 3,
    serverRevision: 4,
    clientPayloadJson: jsonEncode(<String, dynamic>{
      'condition': 'Worn - 4 mm remaining',
      'severity': 'Medium',
      'technicianNote': 'Customer reported squealing at low speed.',
      'wearReading': '4.1 mm',
    }),
    serverPayloadJson: jsonEncode(<String, dynamic>{
      'condition': 'Worn - 3 mm remaining',
      'severity': 'High',
      'technicianNote':
          'Customer reported squealing and vibration at low speed.',
      'serverInspectionId': 'INS-88213',
    }),
    state: 'OPEN',
    createdAt: DateTime(2020, 1, 2, 10),
  ),
  SyncConflictRecord(
    id: 'conflict-2',
    jobId: 'job-10462',
    itemCode: 'TIRE-REAR-L',
    clientRevision: 1,
    serverRevision: 2,
    clientPayloadJson: jsonEncode(<String, dynamic>{'condition': 'Worn'}),
    serverPayloadJson: jsonEncode(<String, dynamic>{'condition': 'Worn'}),
    state: 'OPEN',
    createdAt: DateTime(2020, 1, 2, 10, 5),
  ),
];

Future<void> _pumpSync(
  WidgetTester tester, {
  required Size size,
  List<SyncOperation>? operations,
  List<SyncConflictRecord>? conflicts,
  bool online = true,
  bool rtl = false,
  double scale = 1,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_SignedIn.new),
        connectivityProvider.overrideWith((ref) => Stream<bool>.value(online)),
        pendingOperationsProvider.overrideWith(
          (ref) async => operations ?? _operations(),
        ),
        allTechnicianConflictsProvider.overrideWith(
          (ref) async => conflicts ?? _conflicts(),
        ),
        statusesProvider('sync').overrideWith(
          (ref) async => const <ReferenceRecord>[
            ReferenceRecord(
              code: 'PENDING',
              labelKey: 'shotPending',
              tone: 'warning',
            ),
            ReferenceRecord(
              code: 'FAILED',
              labelKey: 'shotFailed',
              tone: 'danger',
            ),
            ReferenceRecord(
              code: 'SYNCING',
              labelKey: 'shotSyncing',
              tone: 'info',
            ),
          ],
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) {
          var content = child!;
          if (scale != 1) {
            content = MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: content,
            );
          }
          if (rtl) {
            content = Directionality(
              textDirection: TextDirection.rtl,
              child: content,
            );
          }
          return content;
        },
        home: const TechnicianSyncPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpConflict(
  WidgetTester tester, {
  required Size size,
  String id = 'conflict-1',
  List<SyncConflictRecord>? conflicts,
  bool rtl = false,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allTechnicianConflictsProvider.overrideWith(
          (ref) async => conflicts ?? _conflicts(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: rtl
            ? (context, child) => Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              )
            : null,
        home: TechnicianConflictPage(conflictId: id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  testWidgets('outbox renders on a phone', (tester) async {
    await _pumpSync(tester, size: const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('Omar Haddad'), findsOneWidget);
    expect(find.text('5 changes on this phone'), findsOneWidget);
    expect(find.text('2 items changed on the server'), findsOneWidget);
    expect(find.text('Job #10485'), findsOneWidget);
    expect(find.text('BRK-FRONT-01'), findsWidgets);
    expect(find.text('Server rejected the answer (422)'), findsNothing);
    expect(
      find.text('Last error: Server rejected the answer (422)'),
      findsOneWidget,
    );
    expect(find.text('Sync now'), findsOneWidget);
  });

  testWidgets('outbox keeps one primary on a tablet', (tester) async {
    await _pumpSync(tester, size: const Size(1024, 768));
    expect(tester.takeException(), isNull);
    expect(find.text('5 changes on this phone'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
  });

  testWidgets('empty outbox shows the all-clear composition', (tester) async {
    await _pumpSync(
      tester,
      size: const Size(390, 844),
      operations: const <SyncOperation>[],
      conflicts: const <SyncConflictRecord>[],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('No changes waiting to sync'), findsNWidgets(2));
    expect(
      find.text('Everything on this phone has reached the server.'),
      findsOneWidget,
    );
    expect(find.text('Sync now'), findsNothing);
  });

  testWidgets('offline shows the saved promise once and disables sync', (
    tester,
  ) async {
    await _pumpSync(tester, size: const Size(390, 844), online: false);
    expect(tester.takeException(), isNull);
    expect(find.text('Offline'), findsOneWidget);
    expect(
      find.text('Saved safely. They upload as soon as you are back online.'),
      findsOneWidget,
    );
    expect(find.text('Sync now'), findsOneWidget);
  });

  testWidgets('outbox holds at 130% text scaling', (tester) async {
    await _pumpSync(tester, size: const Size(390, 844), scale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Sync'), findsOneWidget);
  });

  testWidgets('outbox mirrors in RTL without overflowing', (tester) async {
    await _pumpSync(tester, size: const Size(390, 844), rtl: true);
    expect(tester.takeException(), isNull);
    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
  });

  testWidgets('conflict compares phone and server on a phone', (tester) async {
    await _pumpConflict(tester, size: const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.text('BRK-FRONT-01'), findsOneWidget);
    expect(find.text('Job #10485'), findsOneWidget);
    expect(find.text('ON THIS PHONE'), findsOneWidget);
    expect(find.text('ON THE SERVER'), findsOneWidget);
    expect(find.text('Worn - 4 mm remaining'), findsOneWidget);
    expect(find.text('Worn - 3 mm remaining'), findsOneWidget);
    expect(find.text('Only on this phone'), findsOneWidget);
    expect(find.text('Only on the server'), findsOneWidget);
    expect(find.text('Use the server version'), findsOneWidget);
  });

  testWidgets('conflict table aligns both payloads on a tablet', (
    tester,
  ) async {
    await _pumpConflict(tester, size: const Size(1024, 768));
    expect(tester.takeException(), isNull);
    expect(find.text('What differs'.toUpperCase()), findsOneWidget);
    expect(find.text('Use the server version'), findsOneWidget);
  });

  testWidgets('conflict mirrors in RTL without overflowing', (tester) async {
    await _pumpConflict(tester, size: const Size(390, 844), rtl: true);
    expect(tester.takeException(), isNull);
    expect(find.text('ON THIS PHONE'), findsOneWidget);
    expect(find.text('Use the server version'), findsOneWidget);
  });

  testWidgets('a resolved or unknown conflict is a designed dead end', (
    tester,
  ) async {
    await _pumpConflict(tester, size: const Size(390, 844), id: 'missing');
    expect(tester.takeException(), isNull);
    expect(find.text('This conflict is no longer open.'), findsOneWidget);
    expect(find.text('Use the server version'), findsNothing);
  });
}
