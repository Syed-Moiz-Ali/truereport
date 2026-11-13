import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_chips.dart';
import 'package:platform_admin_app/src/features/workshops/workshop_detail_screen.dart';
import 'package:platform_admin_app/src/features/workshops/workshop_form.dart';
import 'package:platform_admin_app/src/features/workshops/workshops_screen.dart';
import 'package:platform_admin_app/src/platform_api.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'support/ui_message_fixtures.dart';

// ---------------------------------------------------------------------------
// Local fakes only. test/support/fake_platform_api.dart is untouched.
// ---------------------------------------------------------------------------

PlatformAccount _account({
  required String userId,
  required String displayName,
  required String role,
  required String status,
  required String workshopId,
}) {
  return PlatformAccount(
    userId: userId,
    displayName: displayName,
    email: '$userId@example.test',
    emailMasked: '$userId@example.test',
    role: role,
    status: status,
    workshopId: workshopId,
    primary: false,
    invitationExpiresAt: null,
  );
}

HierarchyWorkshop _workshop({
  required String id,
  required String name,
  required String branch,
  required String status,
  List<PlatformAccount> admins = const [],
  List<PlatformAccount> technicians = const [],
  String contactEmail = '',
}) {
  return HierarchyWorkshop(
    id: id,
    name: name,
    branchName: branch,
    status: status,
    memberCount: admins.length + technicians.length,
    admins: admins,
    technicians: technicians,
    pendingInvitations: const [],
    contactEmail: contactEmail,
  );
}

class _LocalFakePlatformAdminApi implements PlatformAdminApi {
  _LocalFakePlatformAdminApi() {
    workshops = [
      _workshop(
        id: 'workshop-1',
        name: 'Workshop A',
        branch: 'EMEA Industrial Hub',
        status: 'ACTIVE',
        admins: [
          _account(
            userId: 'admin-1',
            displayName: 'Amina Admin',
            role: 'WORKSHOP_ADMIN',
            status: 'ACTIVE',
            workshopId: 'workshop-1',
          ),
        ],
        technicians: [
          _account(
            userId: 'tech-1',
            displayName: 'David Miller',
            role: 'TECHNICIAN',
            status: 'ACTIVE',
            workshopId: 'workshop-1',
          ),
          _account(
            userId: 'tech-2',
            displayName: 'Omar Haddad',
            role: 'TECHNICIAN',
            status: 'DISABLED',
            workshopId: 'workshop-1',
          ),
        ],
        contactEmail: 'ops-a@example.test',
      ),
      _workshop(
        id: 'workshop-2',
        name: 'Workshop B',
        branch: 'Dubai North Station',
        status: 'INACTIVE',
        contactEmail: 'ops-b@example.test',
      ),
    ];
  }

  late List<HierarchyWorkshop> workshops;

  final List<Map<String, String?>> registered = [];
  final List<Map<String, String?>> updated = [];
  final List<(String, String)> deactivated = [];
  final List<(String, String)> reactivated = [];
  final List<Map<String, String?>> createdUsers = [];
  final List<(String, String)> disabledUsers = [];
  final List<(String, String)> reactivatedUsers = [];

  int _indexOf(String id) =>
      workshops.indexWhere((workshop) => workshop.id == id);

  HierarchyWorkshop _replace(
    String id,
    HierarchyWorkshop Function(HierarchyWorkshop current) map,
  ) {
    final index = _indexOf(id);
    final next = map(workshops[index]);
    workshops[index] = next;
    return next;
  }

  @override
  Future<HierarchyResponse> hierarchy({
    String search = '',
    String status = '',
  }) async {
    return HierarchyResponse(
      workshops: List.of(workshops),
      totalWorkshops: workshops.length,
      totalAccounts: 3,
    );
  }

  @override
  Future<HierarchyWorkshop> workshopDetail(String workshopId) async {
    return workshops.firstWhere((workshop) => workshop.id == workshopId);
  }

  @override
  Future<HierarchyWorkshop> registerWorkshop({
    required String name,
    required String location,
    required String contactEmail,
    required String initialTemplate,
    bool autoSyncMasterCatalog = true,
  }) async {
    registered.add({
      'name': name,
      'location': location,
      'contactEmail': contactEmail,
      'initialTemplate': initialTemplate,
    });
    final workshop = _workshop(
      id: 'workshop-${workshops.length + 1}',
      name: name,
      branch: location,
      status: 'ACTIVE',
      contactEmail: contactEmail,
    );
    workshops = [...workshops, workshop];
    return workshop;
  }

  @override
  Future<HierarchyWorkshop> updateWorkshop(
    String id, {
    String? name,
    String? location,
    String? contactEmail,
  }) async {
    updated.add({'id': id, 'name': name, 'location': location});
    return _replace(
      id,
      (current) => _workshop(
        id: current.id,
        name: name ?? current.name,
        branch: location ?? current.branchName ?? '',
        status: current.status,
        admins: current.admins,
        technicians: current.technicians,
        contactEmail: contactEmail ?? current.contactEmail ?? '',
      ),
    );
  }

  @override
  Future<HierarchyWorkshop> deactivateWorkshop(String id, String reason) async {
    deactivated.add((id, reason));
    return _replace(
      id,
      (current) => _workshop(
        id: current.id,
        name: current.name,
        branch: current.branchName ?? '',
        status: 'INACTIVE',
        admins: current.admins,
        technicians: current.technicians,
        contactEmail: current.contactEmail ?? '',
      ),
    );
  }

  @override
  Future<HierarchyWorkshop> reactivateWorkshop(String id, String reason) async {
    reactivated.add((id, reason));
    return _replace(
      id,
      (current) => _workshop(
        id: current.id,
        name: current.name,
        branch: current.branchName ?? '',
        status: 'ACTIVE',
        admins: current.admins,
        technicians: current.technicians,
        contactEmail: current.contactEmail ?? '',
      ),
    );
  }

  @override
  Future<PlatformAccount> createUser({
    required String email,
    required String displayName,
    required String temporaryPassword,
    required String role,
    required String workshopId,
    String? bayAssignment,
    String? certifications,
  }) async {
    createdUsers.add({'email': email, 'role': role, 'workshop': workshopId});
    final account = _account(
      userId: 'user-${createdUsers.length}',
      displayName: displayName,
      role: role,
      status: 'ACTIVE',
      workshopId: workshopId,
    );
    _replace(
      workshopId,
      (current) => _workshop(
        id: current.id,
        name: current.name,
        branch: current.branchName ?? '',
        status: current.status,
        admins: role == 'WORKSHOP_ADMIN'
            ? [...current.admins, account]
            : current.admins,
        technicians: role == 'TECHNICIAN'
            ? [...current.technicians, account]
            : current.technicians,
        contactEmail: current.contactEmail ?? '',
      ),
    );
    return account;
  }

  PlatformAccount _withStatus(PlatformAccount account, String status) {
    return PlatformAccount(
      userId: account.userId,
      displayName: account.displayName,
      email: account.email,
      emailMasked: account.emailMasked,
      role: account.role,
      status: status,
      workshopId: account.workshopId,
      primary: account.primary,
      invitationExpiresAt: account.invitationExpiresAt,
    );
  }

  @override
  Future<PlatformAccount> disableUser(String userId, String reason) async {
    disabledUsers.add((userId, reason));
    for (final workshop in workshops) {
      for (final list in [workshop.admins, workshop.technicians]) {
        final match = list.where((a) => a.userId == userId).toList();
        if (match.isNotEmpty) {
          _replace(
            workshop.id,
            (current) => _workshop(
              id: current.id,
              name: current.name,
              branch: current.branchName ?? '',
              status: current.status,
              admins: current.admins
                  .map(
                    (a) => a.userId == userId ? _withStatus(a, 'DISABLED') : a,
                  )
                  .toList(),
              technicians: current.technicians
                  .map(
                    (a) => a.userId == userId ? _withStatus(a, 'DISABLED') : a,
                  )
                  .toList(),
              contactEmail: current.contactEmail ?? '',
            ),
          );
          return _withStatus(match.first, 'DISABLED');
        }
      }
    }
    return _account(
      userId: userId,
      displayName: userId,
      role: 'TECHNICIAN',
      status: 'DISABLED',
      workshopId: 'workshop-1',
    );
  }

  @override
  Future<PlatformAccount> reactivateUser(String userId, String reason) async {
    reactivatedUsers.add((userId, reason));
    for (final workshop in workshops) {
      final all = [...workshop.admins, ...workshop.technicians];
      final match = all.where((a) => a.userId == userId).toList();
      if (match.isNotEmpty) {
        _replace(
          workshop.id,
          (current) => _workshop(
            id: current.id,
            name: current.name,
            branch: current.branchName ?? '',
            status: current.status,
            admins: current.admins
                .map((a) => a.userId == userId ? _withStatus(a, 'ACTIVE') : a)
                .toList(),
            technicians: current.technicians
                .map((a) => a.userId == userId ? _withStatus(a, 'ACTIVE') : a)
                .toList(),
            contactEmail: current.contactEmail ?? '',
          ),
        );
        return _withStatus(match.first, 'ACTIVE');
      }
    }
    return _account(
      userId: userId,
      displayName: userId,
      role: 'TECHNICIAN',
      status: 'ACTIVE',
      workshopId: 'workshop-1',
    );
  }
}

const _template = GlobalTemplate(
  id: 'tpl-1',
  code: 'TPL-30-GCC',
  nameEn: 'GCC Standard',
  nameAr: 'GCC Standard',
  descriptionEn: '',
  descriptionAr: '',
  status: 'PUBLISHED',
  currentPublishedVersionId: 'v1',
  versionCount: 1,
  currentVersionNo: 1,
  versions: [],
  categories: [],
);

const _auditEvents = [
  PlatformAuditEvent(
    id: 'audit-1',
    action: 'WORKSHOP_REGISTERED',
    entityType: 'WORKSHOP',
    entityId: 'workshop-1',
    actorRole: 'PLATFORM_ADMIN',
    occurredAt: '2026-11-12T10:00:00Z',
    reasonCode: 'INITIAL_SETUP',
    metadataJson: '{"workshopId":"workshop-1"}',
  ),
  PlatformAuditEvent(
    id: 'audit-2',
    action: 'WORKSHOP_REGISTERED',
    entityType: 'WORKSHOP',
    entityId: 'workshop-9',
    actorRole: 'PLATFORM_ADMIN',
    occurredAt: '2026-11-12T10:00:00Z',
    reasonCode: 'INITIAL_SETUP',
    metadataJson: '{}',
  ),
];

Widget _buildListApp(
  _LocalFakePlatformAdminApi api, {
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [uiStringsProvider.overrideWithValue(locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings()), 
      platformApiProvider.overrideWithValue(api),
      platformLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: const WorkshopsScreen(),
    ),
  );
}

Widget _buildDetailApp(
  _LocalFakePlatformAdminApi api, {
  Locale locale = const Locale('en'),
  String workshopId = 'workshop-1',
}) {
  return ProviderScope(
    overrides: [uiStringsProvider.overrideWithValue(locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings()), 
      platformApiProvider.overrideWithValue(api),
      templatesProvider.overrideWith((ref) => Future.value([_template])),
      auditEventsProvider.overrideWith((ref) => Future.value(_auditEvents)),
      platformLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: WorkshopDetailScreen(workshopId: workshopId),
    ),
  );
}

Widget _buildFormApp(
  _LocalFakePlatformAdminApi api, {
  HierarchyWorkshop? workshop,
  Locale locale = const Locale('en'),
  void Function(HierarchyWorkshop saved)? onSaved,
}) {
  return ProviderScope(
    overrides: [uiStringsProvider.overrideWithValue(locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings()), 
      platformApiProvider.overrideWithValue(api),
      templatesProvider.overrideWith((ref) => Future.value([_template])),
      platformLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: WorkshopForm(workshop: workshop, onSaved: onSaved),
        ),
      ),
    ),
  );
}

class _TestLocaleNotifier extends LocaleController {
  _TestLocaleNotifier(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

void _setViewport(
  WidgetTester tester, {
  double width = 1280,
  double height = 1024,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _LocalFakePlatformAdminApi api;

  setUp(() {
    api = _LocalFakePlatformAdminApi();
  });

  group('Workshops list', () {
    testWidgets('renders header, toolbar, table and result count', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildListApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Workshops'), findsWidgets);
      expect(
        find.text('Manage workshops, staff, and their templates'),
        findsOneWidget,
      );
      expect(find.text('Add workshop'), findsOneWidget);
      expect(
        find.widgetWithText(
          TextField,
          'Search workshops by name, branch, or status',
        ),
        findsOneWidget,
      );
      expect(find.text('2 workshops'), findsOneWidget);
      expect(find.text('Workshop A'), findsOneWidget);
      expect(find.text('Workshop B'), findsOneWidget);
      expect(find.text('EMEA Industrial Hub'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search filters workshops by name', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildListApp(api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          TextField,
          'Search workshops by name, branch, or status',
        ),
        'Workshop B',
      );
      await tester.pumpAndSettle();

      expect(find.text('Workshop A'), findsNothing);
      expect(find.text('1 workshops'), findsOneWidget);
    });

    testWidgets('status dropdown filters workshops', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildListApp(api));
      await tester.pumpAndSettle();

      // Open the status dropdown and pick ACTIVE.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACTIVE').last);
      await tester.pumpAndSettle();

      expect(find.text('Workshop A'), findsOneWidget);
      expect(find.text('Workshop B'), findsNothing);
      expect(find.text('1 workshops'), findsOneWidget);
    });

    testWidgets('edit opens the form dialog and saves via updateWorkshop', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildListApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit workshop').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input-workshop-name')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('input-workshop-name')),
        'Workshop A Renamed',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(api.updated.single['name'], 'Workshop A Renamed');
      expect(find.text('Workshop A Renamed'), findsOneWidget);
    });

    testWidgets('deactivate asks for confirmation with reason', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildListApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Deactivate workshop').first);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Deactivate this workshop? Staff lose access until it is reactivated.',
        ),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Reason'),
        'Not paying invoices',
      );
      await tester.tap(find.text('Deactivate workshop').last);
      await tester.pumpAndSettle();

      expect(api.deactivated.single.$1, 'workshop-1');
      expect(api.deactivated.single.$2, 'Not paying invoices');
      expect(find.text('Workshop A'), findsOneWidget);
    });

    testWidgets('compact width renders cards without overflow', (tester) async {
      _setViewport(tester, width: 360, height: 900);
      await tester.pumpWidget(_buildListApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Workshop A'), findsOneWidget);
      expect(find.text('Workshop B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL Arabic renders without overflow', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildListApp(api, locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopForm', () {
    testWidgets('create validates and registers via registerWorkshop', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1024);
      HierarchyWorkshop? saved;
      await tester.pumpWidget(
        _buildFormApp(api, onSaved: (value) => saved = value),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('input-workshop-name')),
        'Workshop C',
      );
      await tester.enterText(
        find.byKey(const Key('input-workshop-branch')),
        'Central Depot Hub',
      );
      await tester.enterText(
        find.byKey(const Key('input-workshop-email')),
        'ops-c@example.test',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(api.registered.single['name'], 'Workshop C');
      expect(api.registered.single['location'], 'Central Depot Hub');
      expect(api.registered.single['initialTemplate'], 'tpl-1');
      expect(saved?.name, 'Workshop C');
    });

    testWidgets('create rejects an invalid email', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildFormApp(api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('input-workshop-name')),
        'Workshop C',
      );
      await tester.enterText(
        find.byKey(const Key('input-workshop-branch')),
        'Central Depot Hub',
      );
      await tester.enterText(
        find.byKey(const Key('input-workshop-email')),
        'not-an-email',
      );
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(api.registered, isEmpty);
    });
  });

  group('WorkshopDetailScreen', () {
    testWidgets('renders header and all four tabs', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildDetailApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Workshop A'), findsWidgets);
      expect(find.text('EMEA Industrial Hub'), findsWidgets);
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Staff'), findsWidgets);
      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Edit workshop'), findsOneWidget);
      expect(find.text('Deactivate workshop'), findsOneWidget);
      // Overview cards.
      expect(find.text('Capacity'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('ops-a@example.test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('staff tab lists admins and technicians', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildDetailApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PlatformFilterChip, 'Staff'));
      await tester.pumpAndSettle();

      expect(find.text('Workshop Admins (1)'), findsOneWidget);
      expect(find.text('Technicians (2)'), findsOneWidget);
      expect(find.text('Amina Admin'), findsOneWidget);
      expect(find.text('David Miller'), findsOneWidget);
      expect(find.text('Add staff'), findsOneWidget);
    });

    testWidgets('add staff creates a technician via createUser', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildDetailApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PlatformFilterChip, 'Staff'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add staff'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('input-staff-name')),
        'Sara Tech',
      );
      await tester.enterText(
        find.byKey(const Key('input-staff-email')),
        'sara@example.test',
      );
      await tester.enterText(
        find.byKey(const Key('input-staff-password')),
        'secret-123',
      );
      await tester.tap(find.text('Add staff').last);
      await tester.pumpAndSettle();

      expect(api.createdUsers.single['email'], 'sara@example.test');
      expect(api.createdUsers.single['role'], 'WORKSHOP_ADMIN');
      expect(find.text('Sara Tech'), findsOneWidget);
    });

    testWidgets('disable staff prompts for a reason', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildDetailApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PlatformFilterChip, 'Staff'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Disable').first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Reason'),
        'Left the workshop',
      );
      await tester.tap(find.text('Disable').last);
      await tester.pumpAndSettle();

      expect(api.disabledUsers.single.$1, 'admin-1');
      expect(api.disabledUsers.single.$2, 'Left the workshop');
    });

    testWidgets('templates tab lists templates with links', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildDetailApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PlatformFilterChip, 'Templates'));
      await tester.pumpAndSettle();

      expect(find.text('GCC Standard'), findsOneWidget);
      expect(find.text('TPL-30-GCC'), findsOneWidget);
    });

    testWidgets('activity tab filters events to this workshop', (tester) async {
      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildDetailApp(api));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PlatformFilterChip, 'Activity'));
      await tester.pumpAndSettle();

      expect(find.text('WORKSHOP_REGISTERED'), findsOneWidget);
      expect(find.text('workshop-9'), findsNothing);
    });

    testWidgets('compact and RTL render without overflow', (tester) async {
      _setViewport(tester, width: 360, height: 900);
      await tester.pumpWidget(_buildDetailApp(api));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      _setViewport(tester, width: 1280, height: 1024);
      await tester.pumpWidget(_buildDetailApp(api, locale: const Locale('ar')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
