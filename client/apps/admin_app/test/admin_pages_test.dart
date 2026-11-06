import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/platform_admin_home.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

class _FakeAdminApi implements AdminApi {
  @override
  Future<HierarchyResponse> hierarchy({
    String search = '',
    String status = '',
  }) async {
    const admin = PlatformAccount(
      userId: 'admin-1',
      displayName: 'Admin A',
      email: 'admin.a@test.local',
      emailMasked: 'a***@test.local',
      role: 'WORKSHOP_ADMIN',
      status: 'ACTIVE',
      workshopId: 'workshop-1',
      primary: true,
      invitationExpiresAt: null,
    );
    const technician = PlatformAccount(
      userId: 'tech-1',
      displayName: 'Technician A',
      email: 'tech.a@test.local',
      emailMasked: 't***@test.local',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
      workshopId: 'workshop-1',
      primary: true,
      invitationExpiresAt: null,
    );
    return const HierarchyResponse(
      workshops: [
        HierarchyWorkshop(
          id: 'workshop-1',
          name: 'Workshop A',
          branchName: 'Dubai',
          status: 'ACTIVE',
          memberCount: 2,
          admins: [admin],
          technicians: [technician],
          pendingInvitations: [],
        ),
      ],
      totalWorkshops: 1,
      totalAccounts: 2,
    );
  }

  @override
  Future<List<Category>> categories() async => const [
    Category(
      id: 'cat-1',
      slug: 'sample-exterior',
      status: 'ACTIVE',
      sortOrder: 1,
      labelEn: 'Sample exterior',
      labelAr: 'هيكل تجريبي',
      itemCount: 1,
    ),
  ];

  @override
  Future<List<ItemSummary>> items({
    String search = '',
    String categoryId = '',
    String status = '',
  }) async => const [
    ItemSummary(
      id: 'item-1',
      stableCode: 'SAMPLE-EXT-001',
      categoryId: 'cat-1',
      categoryLabelEn: 'Sample exterior',
      categoryLabelAr: 'هيكل تجريبي',
      status: 'DRAFT',
      currentVersion: 1,
      labelEn: 'Sample body panel check',
      labelAr: 'فحص لوحة الهيكل التجريبي',
      sampleData: true,
      updatedAt: '2026-11-03T10:00:00',
    ),
  ];

  @override
  Future<ItemDetail> itemDetail(String id) async => const ItemDetail(
    item: ItemSummary(
      id: 'item-1',
      stableCode: 'SAMPLE-EXT-001',
      categoryId: 'cat-1',
      categoryLabelEn: 'Sample exterior',
      categoryLabelAr: 'هيكل تجريبي',
      status: 'DRAFT',
      currentVersion: 1,
      labelEn: 'Sample body panel check',
      labelAr: 'فحص لوحة الهيكل التجريبي',
      sampleData: true,
      updatedAt: '2026-11-03T10:00:00',
    ),
    versions: [
      ItemVersion(
        id: 'version-1',
        versionNo: 1,
        status: 'DRAFT',
        resultOptions: ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
        severityPolicy: '{}',
        applicability: '{}',
        reasonCodes: [],
        noteRequirement: 'OPTIONAL',
        evidenceRequirement: 'NONE',
        minPhotos: 0,
        equipmentIds: [],
        guideImageId: null,
        publishedAt: null,
        translations: {
          'en': Translation(
            locale: 'en',
            label: 'Sample body panel check',
            instruction: 'Inspect the panel.',
          ),
          'ar': Translation(
            locale: 'ar',
            label: 'فحص لوحة الهيكل التجريبي',
            instruction: 'افحص اللوحة.',
          ),
        },
      ),
    ],
  );

  @override
  Future<List<Reason>> reasons() async => const [];

  @override
  Future<List<Equipment>> equipment() async => const [];

  @override
  Future<List<GuideImage>> guideImages() async => const [];

  @override
  Future<List<AuditEvent>> auditEvents() async => const [
    AuditEvent(
      id: 'audit-1',
      action: 'MASTER_ITEM_PUBLISHED',
      actorRole: 'PLATFORM_ADMIN',
      entityType: 'MASTER_ITEM',
      occurredAt: '2026-11-03T10:00:00',
      reasonCode: null,
      metadataJson: '{}',
    ),
  ];

  @override
  Future<ReportAdmin> report(String jobId) async => const ReportAdmin(
    reportId: 'report-1',
    jobId: 'job-1',
    reportNumber: 'TR-0001',
    version: 1,
    generationStatus: 'READY',
    generationError: null,
    attempts: 1,
    reportReady: true,
    pdfReady: true,
    pdfDownloadEnabled: false,
    linkState: 'PENDING_CONSENT',
    consentState: 'GRANTED',
    publicUrl: null,
    finalizedAt: '2026-11-04T10:30:00',
    snapshotHash: 'abc123',
  );

  @override
  Future<ReportAdmin> retryReport(String jobId) => report(jobId);

  @override
  Future<ReportLinkResult> activateReportLink(String jobId) async =>
      const ReportLinkResult(
        state: 'ACTIVE',
        publicUrl: 'http://localhost:8080/r/test-token',
        pdfDownloadEnabled: false,
      );

  @override
  Future<ReportLinkResult> revokeReportLink(
    String jobId,
    String reasonCode,
    String? note,
  ) async => const ReportLinkResult(
    state: 'REVOKED',
    publicUrl: null,
    pdfDownloadEnabled: false,
  );

  @override
  Future<ReportLinkResult> setPdfDownload(String jobId, bool enabled) async =>
      ReportLinkResult(
        state: 'ACTIVE',
        publicUrl: null,
        pdfDownloadEnabled: enabled,
      );

  @override
  Future<List<int>> reportPdf(String jobId) async => const [1, 2, 3];

  @override
  Future<PlatformAccount> createUser({
    required String email,
    required String displayName,
    required String temporaryPassword,
    required String role,
    required String workshopId,
  }) async => PlatformAccount(
    userId: 'user-new',
    displayName: displayName,
    email: email,
    emailMasked: email,
    role: role,
    status: 'ACTIVE',
    workshopId: workshopId,
    primary: false,
    invitationExpiresAt: null,
  );

  @override
  Future<PlatformAccount> createTechnician({
    required String email,
    required String displayName,
    required String initialPassword,
  }) async => PlatformAccount(
    userId: 'tech-new',
    displayName: displayName,
    email: email,
    emailMasked: email,
    role: 'TECHNICIAN',
    status: 'ACTIVE',
    workshopId: 'workshop-1',
    primary: false,
    invitationExpiresAt: null,
  );

  @override
  Future<PlatformAccount> resetPlatformPassword(
    String userId,
    String newPassword,
  ) async => const PlatformAccount(
    userId: 'admin-1',
    displayName: 'Admin A',
    email: 'admin.a@test.local',
    emailMasked: 'a***@test.local',
    role: 'WORKSHOP_ADMIN',
    status: 'ACTIVE',
    workshopId: 'workshop-1',
    primary: true,
    invitationExpiresAt: null,
  );

  @override
  Future<PlatformAccount> resetTechnicianPassword(
    String userId,
    String newPassword,
  ) async => const PlatformAccount(
    userId: 'tech-1',
    displayName: 'Technician A',
    email: 'tech.a@test.local',
    emailMasked: 't***@test.local',
    role: 'TECHNICIAN',
    status: 'ACTIVE',
    workshopId: 'workshop-1',
    primary: true,
    invitationExpiresAt: null,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AdminTestApp extends ConsumerStatefulWidget {
  const _AdminTestApp({required this.locale});

  final Locale locale;

  @override
  ConsumerState<_AdminTestApp> createState() => _AdminTestAppState();
}

class _AdminTestAppState extends ConsumerState<_AdminTestApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(widget.locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      home: const PlatformAdminHomePage(),
    );
  }
}

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('Platform Admin hierarchy and master tabs render in English', (
    tester,
  ) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminApiProvider.overrideWithValue(_FakeAdminApi())],
        child: const _AdminTestApp(locale: Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Workshop A'), findsOneWidget);
    await tester.tap(find.text('Workshop A'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Admin A'), findsOneWidget);
    expect(find.text('Technician A'), findsOneWidget);

    await tester.tap(find.text('Master content'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sample exterior'), findsWidgets);
    expect(find.text('Sample body panel check'), findsWidgets);
    await tester.tap(find.text('Sample body panel check').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sample body panel check'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Audit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audit'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('MASTER_ITEM_PUBLISHED'), findsOneWidget);
  });

  testWidgets('Platform Admin hierarchy and master tabs render in Arabic RTL', (
    tester,
  ) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminApiProvider.overrideWithValue(_FakeAdminApi())],
        child: const _AdminTestApp(locale: Locale('ar')),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('الهيكل'), findsWidgets);
    expect(find.text('Workshop A'), findsOneWidget);

    await tester.tap(find.text('المحتوى الرئيسي'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('الفئات'), findsOneWidget);
    expect(find.textContaining('هيكل تجريبي'), findsWidgets);
    await tester.tap(find.text('Sample body panel check').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
