import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/archive/legacy_archive_page.dart';
import 'package:workshop_admin_app/src/models.dart';

class _ArchiveApi implements AdminApi {
  _ArchiveApi({this.fail = false});

  final bool fail;

  static const jobsData = [
    WorkshopJob(
      id: 'legacy-1',
      reference: 'LEG-0001',
      status: 'IN_PROGRESS',
      templateVersionId: 'version-1',
      templateName: 'Legacy inspection',
      templateVersionNo: 1,
      assignedTechnicianId: 'tech-1',
      assignedTechnicianName: 'Technician A',
      scheduledAt: '2026-11-05T09:00:00',
      customerName: 'Legacy Customer A',
      customerPhone: '+971500000001',
      customerEmail: 'legacy.a@test.local',
      vehicleMake: 'Toyota',
      vehicleModel: 'Land Cruiser',
      vehicleYear: 2020,
      vehicleVin: 'TESTVIN00000000001',
      vehiclePlate: 'L-100',
      scope: 'Legacy inspection',
    ),
    WorkshopJob(
      id: 'legacy-2',
      reference: 'LEG-0002',
      status: 'FINALIZED',
      templateVersionId: 'version-1',
      templateName: 'Legacy inspection',
      templateVersionNo: 1,
      assignedTechnicianId: null,
      assignedTechnicianName: null,
      scheduledAt: '2026-11-04T09:00:00',
      customerName: 'Legacy Customer B',
      customerPhone: '+971500000002',
      customerEmail: 'legacy.b@test.local',
      vehicleMake: 'Nissan',
      vehicleModel: 'Patrol',
      vehicleYear: 2021,
      vehicleVin: 'TESTVIN00000000002',
      vehiclePlate: 'L-200',
      scope: 'Legacy inspection',
    ),
  ];

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async {
    if (fail) {
      throw StateError('archive down');
    }
    return jobsData;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pump(
  WidgetTester tester,
  _ArchiveApi api, {
  Size size = const Size(1280, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: const LegacyArchivePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('archive is read-only: banner, rows, no actions', (tester) async {
    await _pump(tester, _ArchiveApi());
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LegacyArchivePage)),
    );

    expect(find.text(l10n.jobsArchiveTitle), findsOneWidget);
    expect(find.byKey(const Key('jobs-archive-banner')), findsOneWidget);
    expect(find.text(l10n.jobsArchiveBanner), findsOneWidget);
    expect(find.byKey(const Key('legacy-job-legacy-1')), findsOneWidget);
    expect(find.byKey(const Key('legacy-job-legacy-2')), findsOneWidget);
    expect(find.text('LEG-0001'), findsOneWidget);
    expect(find.text('Toyota Land Cruiser'), findsOneWidget);

    // No create, assign, cancel, report, publish or link controls.
    expect(find.byType(WorkshopButton), findsNothing);
    expect(find.text(l10n.assign), findsNothing);
    expect(find.text(l10n.reassign), findsNothing);
    expect(find.text(l10n.cancelJob), findsNothing);
    expect(find.text(l10n.jobsPublishNow), findsNothing);
    expect(find.text(l10n.jobsShare), findsNothing);
    expect(find.text(l10n.newJob), findsNothing);
  });

  testWidgets('archive local search filters without leaving the page', (
    tester,
  ) async {
    await _pump(tester, _ArchiveApi());

    await tester.enterText(
      find.byKey(const Key('jobs-archive-search')),
      'LEG-0002',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legacy-job-legacy-1')), findsNothing);
    expect(find.byKey(const Key('legacy-job-legacy-2')), findsOneWidget);
    expect(find.byType(WorkshopButton), findsNothing);
  });

  testWidgets('archive empty state stays read-only', (tester) async {
    final api = _ArchiveApi();
    await _pump(tester, api);
    await tester.enterText(
      find.byKey(const Key('jobs-archive-search')),
      'no such record',
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LegacyArchivePage)),
    );
    expect(find.text(l10n.jobsArchiveEmpty), findsOneWidget);
    expect(find.byType(WorkshopButton), findsNothing);
  });

  testWidgets('archive error is bounded and retryable', (tester) async {
    await _pump(tester, _ArchiveApi(fail: true));
    expect(find.byType(WorkshopErrorState), findsOneWidget);
    expect(
      find.text(
        AppLocalizations.of(tester.element(find.byType(LegacyArchivePage)))
            .commonLoadFailed,
      ),
      findsOneWidget,
    );
  });

  testWidgets('archive rows carry column labels in the brief §9 order', (
    tester,
  ) async {
    await _pump(tester, _ArchiveApi());
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LegacyArchivePage)),
    );

    final reference = find.text(l10n.jobsReference);
    final vehicle = find.text(l10n.jobsVehicle);
    final customer = find.text(l10n.jobsListColumnCustomer);
    final status = find.text(l10n.status);
    final scheduled = find.text(l10n.jobsListColumnScheduled);
    for (final label in [reference, vehicle, customer, status, scheduled]) {
      expect(label, findsOneWidget);
    }
    final left = [
      for (final label in [reference, vehicle, customer, status, scheduled])
        tester.getTopLeft(label).dx,
    ];
    for (var index = 1; index < left.length; index++) {
      expect(left[index], greaterThan(left[index - 1]));
    }
    // Still read-only.
    expect(find.byType(WorkshopButton), findsNothing);
  });

  testWidgets('archive has no overflow at phone and desktop widths', (
    tester,
  ) async {
    for (final size in const [
      Size(360, 800),
      Size(768, 900),
      Size(1280, 900),
    ]) {
      await _pump(tester, _ArchiveApi(), size: size);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('legacy-job-legacy-1')), findsOneWidget);
    }
  });
}
