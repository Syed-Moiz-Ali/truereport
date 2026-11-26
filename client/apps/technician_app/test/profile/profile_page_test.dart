/// Widget tests for the technician pass.
///
/// These pump the real page with its providers overridden, so the session,
/// sync states, language row and the sign-out confirmation are exercised as
/// shipped.
library;

import 'dart:async';

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/profile/profile_page.dart';
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
    accessToken: 'test-token',
    refreshToken: 'test-refresh',
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

/// A manifest with two languages, so the language row and picker render
/// without booting the network-backed controller.
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

Future<void> _pumpProfile(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  AuthController Function() auth = _SignedIn.new,
  SyncQueueStatus sync = _allSynced,
  bool syncUnknown = false,
  bool online = true,
  bool twoLanguages = true,
  double scale = 1,
  bool rtl = false,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authControllerProvider.overrideWith(auth),
        connectivityProvider.overrideWith((ref) => Stream<bool>.value(online)),
        syncQueueStatusProvider.overrideWith(
          (ref) => syncUnknown
              ? Completer<SyncQueueStatus>().future
              : Future<SyncQueueStatus>.value(sync),
        ),
        if (twoLanguages)
          languageSelectionProvider(technicianUiMessageClient)
              .overrideWith(() => _TwoLanguages(technicianUiMessageClient)),
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
        home: const TechnicianProfilePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  testWidgets('renders the pass, actions and footer', (tester) async {
    await _pumpProfile(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Signed in as'), findsOneWidget);
    expect(find.text('Omar Haddad'), findsOneWidget);
    expect(find.text('omar.haddad@truereport.test'), findsOneWidget);
    expect(find.text('Technician'), findsOneWidget);
    expect(find.text('Al Quoz Auto Care'), findsOneWidget);
    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('No changes waiting to sync'), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('TrueReport · Technician'), findsOneWidget);
  });

  testWidgets('pending and conflict counts are served states', (tester) async {
    await _pumpProfile(
      tester,
      sync: const SyncQueueStatus(pending: 2, failed: 1, conflicts: 0),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('3 · Pending sync'), findsOneWidget);
    expect(find.text('Sync pending'), findsOneWidget);

    await _pumpProfile(
      tester,
      sync: const SyncQueueStatus(pending: 1, failed: 0, conflicts: 2),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('2 conflicts'), findsOneWidget);
    expect(find.text('Conflict'), findsOneWidget);
  });

  testWidgets('unknown sync invents no count', (tester) async {
    await _pumpProfile(tester, syncUnknown: true);
    expect(tester.takeException(), isNull);
    expect(find.text('Queued changes'), findsOneWidget);
    expect(find.text('No changes waiting to sync'), findsNothing);
    expect(find.text('Synced'), findsNothing);
    expect(find.textContaining('Pending sync'), findsNothing);
    expect(find.textContaining('conflicts'), findsNothing);
  });

  testWidgets('offline shows the pill and the queued promise', (tester) async {
    await _pumpProfile(
      tester,
      online: false,
      sync: const SyncQueueStatus(pending: 2, failed: 0, conflicts: 0),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Offline'), findsOneWidget);
    expect(
      find.text('Saved on this phone. It will sync when online.'),
      findsOneWidget,
    );
    expect(find.text('2 · Pending sync'), findsOneWidget);
  });

  testWidgets('a single language hides the language row', (tester) async {
    await _pumpProfile(tester, twoLanguages: false);
    expect(tester.takeException(), isNull);
    expect(find.text('Language'), findsNothing);
    expect(find.text('English'), findsNothing);
  });

  testWidgets('language row opens the existing picker', (tester) async {
    await _pumpProfile(tester);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Language'), findsNWidgets(2));
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsNWidgets(2));
  });

  testWidgets('long identity and 130% text wrap without overflowing', (
    tester,
  ) async {
    await _pumpProfile(tester, auth: _LongSignedIn.new, scale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Abdulrahman Mohammed Al Hashimi'), findsOneWidget);
    expect(
      find.text('abdulrahman.al.hashimi@truereport-workshops.ae'),
      findsOneWidget,
    );
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('RTL mirrors without overflowing', (tester) async {
    await _pumpProfile(tester, rtl: true);
    expect(tester.takeException(), isNull);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Omar Haddad'), findsOneWidget);
  });

  testWidgets('sign out asks first and cancel keeps the session', (
    tester,
  ) async {
    await _pumpProfile(tester);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign out'), findsOneWidget);
    expect(
      find.text('You will need to sign in again to open your queue.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      find.text('You will need to sign in again to open your queue.'),
      findsNothing,
    );
    expect(find.text('Omar Haddad'), findsOneWidget);
  });

  testWidgets('sync row opens the sync route', (tester) async {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const TechnicianProfilePage(),
        ),
        GoRoute(
          path: '/sync',
          builder: (context, state) =>
              const Scaffold(body: Text('sync destination')),
        ),
      ],
    );
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_SignedIn.new),
          connectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
          syncQueueStatusProvider.overrideWith((ref) async => _allSynced),
        ],
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sync'));
    await tester.pumpAndSettle();
    expect(find.text('sync destination'), findsOneWidget);
  });
}
