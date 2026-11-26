/// Real-font screenshots of the technician pass.
///
/// These pump `TechnicianProfilePage` with the app's providers overridden, so
/// the evidence shows the shipped layout, not a hand-composed approximation.
library;

import 'dart:async';

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/profile/profile_page.dart';
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
    memberships: <Membership>[
      Membership(
        workshopId: 'ws-1',
        workshopName: 'Al Quoz Auto Care',
        role: Role.technician,
      ),
    ],
  );
}

class _LongSignedIn extends AuthController {
  @override
  Future<Session?> build() async => const Session(
    accessToken: 'shot-token',
    refreshToken: 'shot-refresh',
    user: User(
      id: 'tech-18',
      email: 'abdulrahman.al.hashimi@truereport-workshops.ae',
      displayName: 'Abdulrahman Mohammed Al Hashimi',
      platformAdmin: false,
      totpEnabled: false,
    ),
    memberships: <Membership>[
      Membership(
        workshopId: 'ws-2',
        workshopName: 'Al Quoz Auto Care — Premium Diagnostics & Body Shop',
        role: Role.technician,
      ),
    ],
  );
}

class _TwoLanguages extends UiMessageController {
  _TwoLanguages(super.client);

  @override
  UiMessageState build() => const UiMessageState(
    manifest: UiMessageManifest(
      defaultLanguage: 'en',
      namespaceVersions: <String, int>{},
      languages: <UiMessageLanguage>[
        UiMessageLanguage(code: 'en', direction: 'ltr', nativeName: 'English'),
        UiMessageLanguage(code: 'ar', direction: 'rtl', nativeName: 'العربية'),
      ],
    ),
    activeLanguage: 'en',
    ready: true,
  );
}

const Map<String, String> _bundle = <String, String>{
  'technicianProfileTitle': 'Profile',
  'technicianProfileSubtitle': 'Signed in as',
  'roleTechnician': 'Technician',
  'technicianSyncTitle': 'Sync',
  'technicianSyncQueuedChanges': 'Queued changes',
  'technicianSyncConflictsCount': '{count} conflicts',
  'technicianSyncStateConflict': 'Conflict',
  'technicianSyncPending': 'Pending sync',
  'technicianSessionSyncPending': 'Sync pending',
  'technicianAllSynced': 'No changes waiting to sync',
  'successSynced': 'Synced',
  'technicianOfflineQueued': 'Saved on this phone. It will sync when online.',
  'technicianSyncOffline': 'Offline',
  'settingsLanguage': 'Language',
  'signOut': 'Sign out',
  'technicianSignOutBody': 'You will need to sign in again to open your queue.',
  'appTitle': 'TrueReport',
};

const _allSynced = SyncQueueStatus(pending: 0, failed: 0, conflicts: 0);

Widget _app({
  AuthController Function() auth = _SignedIn.new,
  SyncQueueStatus sync = _allSynced,
  bool online = true,
  bool twoLanguages = true,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(auth),
      connectivityProvider.overrideWith((ref) => Stream<bool>.value(online)),
      syncQueueStatusProvider.overrideWith((ref) async => sync),
      if (twoLanguages)
        languageSelectionProvider(technicianUiMessageClient)
            .overrideWith(() => _TwoLanguages(technicianUiMessageClient)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const TechnicianProfilePage(),
    ),
  );
}

Widget _unknownApp() {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_SignedIn.new),
      connectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
      syncQueueStatusProvider.overrideWith(
        (ref) => Completer<SyncQueueStatus>().future,
      ),
      languageSelectionProvider(technicianUiMessageClient)
          .overrideWith(() => _TwoLanguages(technicianUiMessageClient)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const TechnicianProfilePage(),
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

  testWidgets('profile_390', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'profile_390',
      app: _app(
        sync: const SyncQueueStatus(pending: 2, failed: 1, conflicts: 0),
      ),
    );
  });

  testWidgets('profile_1024', (tester) async {
    await _shot(
      tester,
      width: 1024,
      height: 768,
      name: 'profile_1024',
      app: _app(
        sync: const SyncQueueStatus(pending: 1, failed: 0, conflicts: 2),
      ),
    );
  });

  testWidgets('profile_1440', (tester) async {
    await _shot(
      tester,
      width: 1440,
      height: 900,
      name: 'profile_1440',
      app: _app(),
    );
  });

  testWidgets('profile_390_offline', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'profile_390_offline',
      app: _app(
        online: false,
        sync: const SyncQueueStatus(pending: 2, failed: 0, conflicts: 0),
      ),
    );
  });

  testWidgets('profile_390_long', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'profile_390_long',
      app: _app(auth: _LongSignedIn.new),
    );
  });

  testWidgets('profile_390_singlelang', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'profile_390_singlelang',
      app: _app(twoLanguages: false),
    );
  });

  testWidgets('profile_390_unknown', (tester) async {
    await _shot(
      tester,
      width: 390,
      height: 844,
      name: 'profile_390_unknown',
      app: _unknownApp(),
    );
  });
}
