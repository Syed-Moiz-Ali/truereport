/// Real-font screenshots of the sync outbox and conflict screens.
///
/// These pump the shipped pages with the app's providers overridden, so the
/// evidence shows the production layout, not a hand-composed approximation.
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

Widget _app({required Widget home}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_SignedIn.new),
      connectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
      pendingOperationsProvider.overrideWith((ref) async => _operations()),
      allTechnicianConflictsProvider.overrideWith((ref) async => _conflicts()),
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
      home: home,
    ),
  );
}

Widget _emptyApp() {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_SignedIn.new),
      connectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
      pendingOperationsProvider.overrideWith(
        (ref) async => const <SyncOperation>[],
      ),
      allTechnicianConflictsProvider.overrideWith(
        (ref) async => const <SyncConflictRecord>[],
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const TechnicianSyncPage(),
    ),
  );
}

Widget _offlineApp() {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_SignedIn.new),
      connectivityProvider.overrideWith((ref) => Stream<bool>.value(false)),
      pendingOperationsProvider.overrideWith((ref) async => _operations()),
      allTechnicianConflictsProvider.overrideWith((ref) async => _conflicts()),
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
      home: const TechnicianSyncPage(),
    ),
  );
}

Future<void> _shot(
  WidgetTester tester, {
  required double width,
  required double height,
  required String name,
  required Widget app,
}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  testWidgets('sync_390', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'sync_390',
      app: _app(home: const TechnicianSyncPage()),
    );
  });

  testWidgets('sync_1024', (tester) async {
    await _shot(
      tester,
      width: 1024,
      height: 768,
      name: 'sync_1024',
      app: _app(home: const TechnicianSyncPage()),
    );
  });

  testWidgets('sync_390_empty', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'sync_390_empty',
      app: _emptyApp(),
    );
  });

  testWidgets('sync_390_offline', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'sync_390_offline',
      app: _offlineApp(),
    );
  });

  testWidgets('conflict_390', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'conflict_390',
      app: _app(home: const TechnicianConflictPage(conflictId: 'conflict-1')),
    );
  });

  testWidgets('conflict_1024', (tester) async {
    await _shot(
      tester,
      width: 1024,
      height: 768,
      name: 'conflict_1024',
      app: _app(home: const TechnicianConflictPage(conflictId: 'conflict-1')),
    );
  });
}
