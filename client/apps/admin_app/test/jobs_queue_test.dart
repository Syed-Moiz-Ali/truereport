import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/jobs_tab.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

/// Server-like fake: honours `search` + `status` exactly like the real
/// workshop jobs endpoint contract so the tab's existing provider
/// keys (`search\u0001status`) keep working unchanged.
class _QueueFakeApi implements AdminApi {
  static const _jobs = [
    WorkshopJob(
      id: 'job-1',
      reference: 'JOB-0001',
      status: 'IN_PROGRESS',
      templateVersionId: 'version-1',
      templateName: 'Full inspection',
      templateVersionNo: 1,
      assignedTechnicianId: 'tech-1',
      assignedTechnicianName: 'Technician A',
      scheduledAt: '2026-11-05T09:00:00',
      customerName: 'Customer A',
      customerPhone: '+971500000001',
      customerEmail: 'customer.a@test.local',
      vehicleMake: 'Toyota',
      vehicleModel: 'Camry',
      vehicleYear: 2022,
      vehicleVin: 'TESTVIN00000000001',
      vehiclePlate: 'A12345',
      scope: 'Full inspection',
    ),
    WorkshopJob(
      id: 'job-2',
      reference: 'JOB-0002',
      status: 'READY_TO_FINALIZE',
      templateVersionId: 'version-1',
      templateName: 'Full inspection',
      templateVersionNo: 1,
      assignedTechnicianId: 'tech-1',
      assignedTechnicianName: 'Technician A',
      scheduledAt: '2026-11-05T10:00:00',
      customerName: 'Customer B',
      customerPhone: '+971500000002',
      customerEmail: 'customer.b@test.local',
      vehicleMake: 'Honda',
      vehicleModel: 'Civic',
      vehicleYear: 2023,
      vehicleVin: 'TESTVIN00000000002',
      vehiclePlate: 'B67890',
      scope: 'Full inspection',
    ),
    WorkshopJob(
      id: 'job-3',
      reference: 'JOB-0003',
      status: 'FINALIZED',
      templateVersionId: 'version-1',
      templateName: 'Full inspection',
      templateVersionNo: 1,
      assignedTechnicianId: null,
      assignedTechnicianName: null,
      scheduledAt: '2026-11-04T09:00:00',
      customerName: 'Customer C',
      customerPhone: '+971500000003',
      customerEmail: 'customer.c@test.local',
      vehicleMake: 'Ford',
      vehicleModel: 'Transit',
      vehicleYear: 2021,
      vehicleVin: 'TESTVIN00000000003',
      vehiclePlate: 'C13579',
      scope: 'Full inspection',
    ),
  ];

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async {
    final query = search.trim().toLowerCase();
    return _jobs.where((job) {
      if (status.isNotEmpty && job.status != status) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return [
        job.reference,
        job.customerName,
        job.vehicleMake,
        job.vehicleModel,
        job.assignedTechnicianName ?? '',
      ].any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Future<List<StaffMember>> staff() async => const [
    StaffMember(
      userId: 'tech-1',
      displayName: 'Technician A',
      emailMasked: 't***@test.local',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _QueueTestApp extends ConsumerStatefulWidget {
  const _QueueTestApp({required this.locale});

  final Locale locale;

  @override
  ConsumerState<_QueueTestApp> createState() => _QueueTestAppState();
}

class _QueueTestAppState extends ConsumerState<_QueueTestApp> {
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
      home: const Scaffold(body: JobsTab()),
    );
  }
}

Future<void> _pumpQueue(
  WidgetTester tester,
  Locale locale, {
  Size size = const Size(1280, 800),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(_QueueFakeApi())],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: _QueueTestApp(locale: locale),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('queue renders header, counted chips and job cards', (tester) async {
    await _pumpQueue(tester, const Locale('en'));

    // Figma header slot: neutral queue title + existing search + New Job.
    expect(find.text('Job queue'), findsOneWidget);
    expect(find.byKey(const Key('jobs-search')), findsOneWidget);
    expect(find.text('New job'), findsOneWidget);

    // Four slot-sheet chips with client-side counts.
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('In progress (1)'), findsOneWidget);
    expect(find.text('Ready to finalize (1)'), findsOneWidget);
    expect(find.text('Finalized (1)'), findsOneWidget);

    // Rows come from WorkshopJob only: vehicle title, reference,
    // customer, template, assignee — never invented numbers.
    expect(find.byType(WorkshopJobCard), findsNWidgets(3));
    expect(find.text('JOB-0001'), findsOneWidget);
    expect(find.text('Toyota Camry'), findsOneWidget);
    expect(find.text('Customer B'), findsWidgets);
    expect(find.text('Full inspection v1'), findsNWidgets(3));
    expect(find.text('Technician A'), findsWidgets);
    expect(find.text('Unassigned'), findsOneWidget);
    expect(find.byType(StatusChip), findsWidgets);

    // Omitted per slot sheet P2/P3: bays, progress, flags, review copy,
    // live sync, turnaround, slot times.
    expect(find.textContaining('Bay'), findsNothing);
    expect(find.textContaining('bay'), findsNothing);
    expect(find.textContaining('Progress'), findsNothing);
    expect(find.textContaining('Flag'), findsNothing);
    expect(find.textContaining('Review'), findsNothing);
    expect(find.textContaining('Live sync'), findsNothing);
    expect(find.textContaining('Turnaround'), findsNothing);
    expect(find.textContaining('Slot'), findsNothing);
    expect(find.textContaining('Export Daily Log'), findsNothing);
    expect(find.textContaining('Batch Reassign'), findsNothing);
  });

  testWidgets('status chips filter the queue server-side', (tester) async {
    await _pumpQueue(tester, const Locale('en'));

    await tester.tap(find.text('In progress (1)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('JOB-0001'), findsOneWidget);
    expect(find.text('JOB-0002'), findsNothing);
    expect(find.text('JOB-0003'), findsNothing);
    // Counts stay derived from the unfiltered, search-scoped snapshot.
    expect(find.text('All (3)'), findsOneWidget);

    await tester.tap(find.text('Finalized (1)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('JOB-0003'), findsOneWidget);
    expect(find.text('JOB-0001'), findsNothing);
  });

  testWidgets('search narrows the queue and rescopes chip counts', (
    tester,
  ) async {
    await _pumpQueue(tester, const Locale('en'));

    await tester.enterText(find.byKey(const Key('jobs-search')), 'Customer B');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('JOB-0002'), findsOneWidget);
    expect(find.text('JOB-0001'), findsNothing);
    expect(find.text('All (1)'), findsOneWidget);
    expect(find.text('Ready to finalize (1)'), findsOneWidget);
    expect(find.text('In progress (0)'), findsOneWidget);
  });

  testWidgets('tapping a card opens the existing detail sheet', (tester) async {
    await _pumpQueue(tester, const Locale('en'));

    await tester.tap(find.byKey(const Key('job-job-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Existing bottom-sheet content is unchanged (customer contact line).
    expect(find.text('+971500000001'), findsOneWidget);
  });

  testWidgets('finalized rows stay read-only', (tester) async {
    await _pumpQueue(tester, const Locale('en'));

    await tester.ensureVisible(find.byKey(const Key('job-job-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('job-job-3')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Assign'), findsNothing);
    expect(find.text('Reassign'), findsNothing);
    expect(find.text('Cancel job'), findsNothing);
  });

  testWidgets('queue renders in Arabic RTL without exceptions', (tester) async {
    await _pumpQueue(tester, const Locale('ar'));

    expect(find.text('قائمة المهام'), findsOneWidget);
    expect(find.text('JOB-0001'), findsOneWidget);
    expect(find.text('JOB-0003'), findsOneWidget);
  });

  testWidgets('queue has no overflow at 390 and 1280 up to 2.0x', (
    tester,
  ) async {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        for (final locale in const [Locale('en'), Locale('ar')]) {
          await _pumpQueue(
            tester,
            locale,
            size: size,
            textScale: scale,
          );
        }
      }
    }
  });
}
