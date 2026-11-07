import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/job_counts.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/assign_technician_dialog.dart';
import 'package:admin_app/src/pages/dashboard_tab.dart';
import 'package:admin_app/src/pages/jobs_tab.dart';
import 'package:admin_app/src/pages/schedule_job_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

// F3-A Step 4 geometry + text-style gate for the four product screens.
//
// Pumps the REAL product widgets at 1280x800, EN, text scale 1 (DPR 1) with
// small inline fakes (same harness shape as dashboard/jobs/schedule/assign
// tests; none of their private helpers are imported). Key product boxes are
// compared within 1 logical px; screen titles assert the design-token type
// (Plus Jakarta Sans, size/weight/line-height/tracking).
//
// This gates the PRODUCT layout (per the slot sheet), not Figma equality:
// boxes below were measured from the product widgets themselves. Geometry
// runs under the default test font (no font loading), matching the existing
// product tests; text styles come from the theme tokens, not font assets.
const _counts = JobCounts(
  draft: 10,
  scheduled: 24,
  newScheduled: 34,
  assigned: 14,
  inProgress: 9,
  readyToFinalize: 45,
  finalized: 60,
  finalizedToday: 56,
  cancelled: 3,
  total: 140,
);

const _jobOpen = WorkshopJob(
  id: 'job-1',
  reference: 'JOB-TEST0001',
  status: 'ASSIGNED',
  templateVersionId: 'version-1',
  templateName: 'Full inspection',
  templateVersionNo: 1,
  assignedTechnicianId: 'tech-1',
  assignedTechnicianName: 'Technician A',
  scheduledAt: '2026-11-05T09:00:00',
  customerName: 'Customer A',
  customerPhone: '+971500000000',
  customerEmail: 'customer@test.local',
  vehicleMake: 'Toyota',
  vehicleModel: 'Camry',
  vehicleYear: 2022,
  vehicleVin: 'TESTVIN00000000001',
  vehiclePlate: 'A12345',
  scope: 'Full inspection',
);

const _jobDone = WorkshopJob(
  id: 'job-2',
  reference: 'JOB-TEST0002',
  status: 'FINALIZED',
  templateVersionId: 'version-1',
  templateName: 'Full inspection',
  templateVersionNo: 1,
  assignedTechnicianId: null,
  assignedTechnicianName: null,
  scheduledAt: '2026-11-04T09:00:00',
  customerName: 'Customer B',
  customerPhone: null,
  customerEmail: null,
  vehicleMake: 'Toyota',
  vehicleModel: 'Corolla',
  vehicleYear: 2021,
  vehicleVin: 'TESTVIN00000000002',
  vehiclePlate: 'B67890',
  scope: 'Full inspection',
);

const _scheduleJob = WorkshopJob(
  id: 'job-7',
  reference: 'JOB-TEST0007',
  status: 'SCHEDULED',
  templateVersionId: 'version-1',
  templateName: 'Full inspection',
  templateVersionNo: 1,
  assignedTechnicianId: null,
  assignedTechnicianName: null,
  scheduledAt: '2026-11-05T09:00:00',
  customerName: 'Customer A',
  customerPhone: '+971500000000',
  customerEmail: 'customer@test.local',
  vehicleMake: 'Toyota',
  vehicleModel: 'Camry',
  vehicleYear: 2022,
  vehicleVin: 'TESTVIN00000000001',
  vehiclePlate: 'A12345',
  scope: 'Full inspection',
);

/// Dashboard/queue fake: counts plus two jobs spanning open + finalized.
class _BoardsFakeApi implements AdminApi {
  @override
  Future<JobCounts> jobCounts() async => _counts;

  @override
  Future<List<WorkshopJob>> jobs({
    String search = '',
    String status = '',
  }) async {
    final query = search.trim().toLowerCase();
    const all = [_jobOpen, _jobDone];
    return all.where((job) {
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
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Schedule-sheet fake: published template options plus their counts.
class _ScheduleFakeApi implements AdminApi {
  @override
  Future<List<TemplateVersionOption>> templateVersionOptions() async =>
      const [
        TemplateVersionOption(
          versionId: 'version-1',
          templateId: 'template-1',
          templateName: 'Full inspection',
          versionNo: 1,
          serviceType: 'FULL',
          vehicleType: 'CAR',
        ),
      ];

  @override
  Future<List<TemplateSummary>> templates() async => const [
    TemplateSummary(
      id: 'template-1',
      name: 'Full inspection',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'PUBLISHED',
      currentVersion: 1,
      itemCount: 1,
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Assign-dialog fake: two active technicians on the same workshop.
class _AssignFakeApi implements AdminApi {
  @override
  Future<List<StaffMember>> staff() async => const [
    StaffMember(
      userId: 'tech-1',
      displayName: 'Technician A',
      emailMasked: 't***@test.local',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
    ),
    StaffMember(
      userId: 'tech-2',
      displayName: 'Technician B',
      emailMasked: 'u***@test.local',
      role: 'TECHNICIAN',
      status: 'ACTIVE',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({required this.home, required this.api});

  final Widget home;
  final AdminApi api;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(const Locale('en'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: widget.home,
    );
  }
}

void _setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget home,
  AdminApi api,
) async {
  _setSize(tester);
  final container = ProviderContainer(
    overrides: [adminApiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _Harness(home: home, api: api),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('dashboard geometry within 1 logical px (1280 EN)', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      const Scaffold(body: DashboardTab()),
      _BoardsFakeApi(),
    );

    final failures = <String>[];
    var checked = 0;
    var passed = 0;
    void check(String label, Finder finder, Rect expected) {
      checked++;
      if (finder.evaluate().isEmpty) {
        failures.add('$label: not found');
        return;
      }
      final rect = tester.getRect(finder.first);
      final deltas = <String>[];
      if ((rect.left - expected.left).abs() > 1) {
        deltas.add('x ${rect.left.toStringAsFixed(2)} vs ${expected.left}');
      }
      if ((rect.top - expected.top).abs() > 1) {
        deltas.add('y ${rect.top.toStringAsFixed(2)} vs ${expected.top}');
      }
      if ((rect.width - expected.width).abs() > 1) {
        deltas.add('w ${rect.width.toStringAsFixed(2)} vs ${expected.width}');
      }
      if ((rect.height - expected.height).abs() > 1) {
        deltas.add('h ${rect.height.toStringAsFixed(2)} vs ${expected.height}');
      }
      if (deltas.isNotEmpty) {
        failures.add('$label: ${deltas.join(', ')}');
      } else {
        passed++;
      }
    }

    Rect box(double x, double y, double w, double h) =>
        Rect.fromLTWH(x, y, w, h);

    void checkStyle(String label, Finder finder) {
      checked++;
      if (finder.evaluate().isEmpty) {
        failures.add('$label style: not found');
        return;
      }
      final text = tester.widget<Text>(finder.first);
      final style = text.style;
      if (style == null) {
        failures.add('$label style: no explicit style');
        return;
      }
      const size = 16.0;
      const lineHeight = 22.0;
      const tracking = -0.16;
      final deltas = <String>[];
      if (style.fontSize != size) {
        deltas.add('size ${style.fontSize} vs $size');
      }
      if (style.fontWeight != FontWeight.w700) {
        deltas.add('weight ${style.fontWeight} vs w700');
      }
      final height = style.height;
      if (height == null || (height - lineHeight / size).abs() > 0.001) {
        deltas.add(
          'lineHeight ${height == null ? 'null' : (height * size).toStringAsFixed(2)} vs $lineHeight',
        );
      }
      final spacing = style.letterSpacing ?? 0;
      if ((spacing - tracking).abs() > 0.001) {
        deltas.add('tracking $spacing vs $tracking');
      }
      if (style.fontFamily != TrFonts.latin) {
        deltas.add('family ${style.fontFamily}');
      }
      if (deltas.isNotEmpty) {
        failures.add('$label style: ${deltas.join(', ')}');
      } else {
        passed++;
      }
    }

    // Header row: full-bleed floating header with the 80 dp product height.
    check(
      'header row',
      find.byType(WorkshopHeader),
      box(16, 16, 1248, 80),
    );
    // Stat card row: five across at 240 wide + 12 gaps; the second card pins
    // the row stride. Heights follow caption wrapping (120 vs 140).
    check(
      'stat card active',
      find.byKey(const Key('dashboard-stat-active')),
      box(16, 140, 240, 120),
    );
    check(
      'stat card new-scheduled',
      find.byKey(const Key('dashboard-stat-new-scheduled')),
      box(268, 140, 240, 140),
    );
    // Recent-jobs list: first product card below the section header.
    check(
      'first job card',
      find.byKey(const Key('dashboard-job-job-1')),
      box(16, 342, 1248, 154),
    );
    checkStyle('dashboard title', find.text('Overview'));

    expect(
      failures,
      isEmpty,
      reason: 'dashboard: $passed/$checked key nodes within 1 px\n'
          '${failures.join('\n')}',
    );
  });

  testWidgets('queue geometry within 1 logical px (1280 EN)', (tester) async {
    await _pumpScreen(
      tester,
      const Scaffold(body: JobsTab()),
      _BoardsFakeApi(),
    );

    final failures = <String>[];
    var checked = 0;
    var passed = 0;
    void check(String label, Finder finder, Rect expected) {
      checked++;
      if (finder.evaluate().isEmpty) {
        failures.add('$label: not found');
        return;
      }
      final rect = tester.getRect(finder.first);
      final deltas = <String>[];
      if ((rect.left - expected.left).abs() > 1) {
        deltas.add('x ${rect.left.toStringAsFixed(2)} vs ${expected.left}');
      }
      if ((rect.top - expected.top).abs() > 1) {
        deltas.add('y ${rect.top.toStringAsFixed(2)} vs ${expected.top}');
      }
      if ((rect.width - expected.width).abs() > 1) {
        deltas.add('w ${rect.width.toStringAsFixed(2)} vs ${expected.width}');
      }
      if ((rect.height - expected.height).abs() > 1) {
        deltas.add('h ${rect.height.toStringAsFixed(2)} vs ${expected.height}');
      }
      if (deltas.isNotEmpty) {
        failures.add('$label: ${deltas.join(', ')}');
      } else {
        passed++;
      }
    }

    Rect box(double x, double y, double w, double h) =>
        Rect.fromLTWH(x, y, w, h);

    void checkStyle(String label, Finder finder) {
      checked++;
      if (finder.evaluate().isEmpty) {
        failures.add('$label style: not found');
        return;
      }
      final text = tester.widget<Text>(finder.first);
      final style = text.style;
      if (style == null) {
        failures.add('$label style: no explicit style');
        return;
      }
      const size = 16.0;
      const lineHeight = 22.0;
      const tracking = -0.16;
      final deltas = <String>[];
      if (style.fontSize != size) {
        deltas.add('size ${style.fontSize} vs $size');
      }
      if (style.fontWeight != FontWeight.w700) {
        deltas.add('weight ${style.fontWeight} vs w700');
      }
      final height = style.height;
      if (height == null || (height - lineHeight / size).abs() > 0.001) {
        deltas.add(
          'lineHeight ${height == null ? 'null' : (height * size).toStringAsFixed(2)} vs $lineHeight',
        );
      }
      final spacing = style.letterSpacing ?? 0;
      if ((spacing - tracking).abs() > 0.001) {
        deltas.add('tracking $spacing vs $tracking');
      }
      if (style.fontFamily != TrFonts.latin) {
        deltas.add('family ${style.fontFamily}');
      }
      if (deltas.isNotEmpty) {
        failures.add('$label style: ${deltas.join(', ')}');
      } else {
        passed++;
      }
    }

    // Queue header row: same floating product header as the dashboard.
    check(
      'queue header',
      find.byType(WorkshopHeader),
      box(16, 16, 1248, 80),
    );
    // First job card below the filter-chip row.
    check(
      'first job card',
      find.byKey(const Key('job-job-1')),
      box(16, 176, 1248, 154),
    );
    checkStyle('queue title', find.text('Job queue'));

    expect(
      failures,
      isEmpty,
      reason: 'queue: $passed/$checked key nodes within 1 px\n'
          '${failures.join('\n')}',
    );
  });

  testWidgets('schedule drawer geometry within 1 logical px (1280 EN)', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      Scaffold(
        body: Center(
          child: Builder(
            builder: (sheetContext) => ElevatedButton(
              key: const Key('open-schedule-sheet'),
              onPressed: () async {
                await ScheduleJobSheet.showScheduleJobSheet(sheetContext);
              },
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
      _ScheduleFakeApi(),
    );
    await tester.tap(find.byKey(const Key('open-schedule-sheet')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final failures = <String>[];
    var checked = 0;
    var passed = 0;
    void check(String label, Finder finder, Rect expected) {
      checked++;
      if (finder.evaluate().isEmpty) {
        failures.add('$label: not found');
        return;
      }
      final rect = tester.getRect(finder.first);
      final deltas = <String>[];
      if ((rect.left - expected.left).abs() > 1) {
        deltas.add('x ${rect.left.toStringAsFixed(2)} vs ${expected.left}');
      }
      if ((rect.top - expected.top).abs() > 1) {
        deltas.add('y ${rect.top.toStringAsFixed(2)} vs ${expected.top}');
      }
      if ((rect.width - expected.width).abs() > 1) {
        deltas.add('w ${rect.width.toStringAsFixed(2)} vs ${expected.width}');
      }
      if ((rect.height - expected.height).abs() > 1) {
        deltas.add('h ${rect.height.toStringAsFixed(2)} vs ${expected.height}');
      }
      if (deltas.isNotEmpty) {
        failures.add('$label: ${deltas.join(', ')}');
      } else {
        passed++;
      }
    }

    Rect box(double x, double y, double w, double h) =>
        Rect.fromLTWH(x, y, w, h);

    void checkStyle(String label, Finder finder) {
      checked++;
      if (finder.evaluate().isEmpty) {
        failures.add('$label style: not found');
        return;
      }
      final text = tester.widget<Text>(finder.first);
      final style = text.style;
      if (style == null) {
        failures.add('$label style: no explicit style');
        return;
      }
      const size = 16.0;
      const lineHeight = 22.0;
      const tracking = -0.16;
      final deltas = <String>[];
      if (style.fontSize != size) {
        deltas.add('size ${style.fontSize} vs $size');
      }
      if (style.fontWeight != FontWeight.w700) {
        deltas.add('weight ${style.fontWeight} vs w700');
      }
      final height = style.height;
      if (height == null || (height - lineHeight / size).abs() > 0.001) {
        deltas.add(
          'lineHeight ${height == null ? 'null' : (height * size).toStringAsFixed(2)} vs $lineHeight',
        );
      }
      final spacing = style.letterSpacing ?? 0;
      if ((spacing - tracking).abs() > 0.001) {
        deltas.add('tracking $spacing vs $tracking');
      }
      if (style.fontFamily != TrFonts.latin) {
        deltas.add('family ${style.fontFamily}');
      }
      if (deltas.isNotEmpty) {
        failures.add('$label style: ${deltas.join(', ')}');
      } else {
        passed++;
      }
    }

    // Schedule drawer: right-hand 420 sheet docked at the viewport edge.
    check(
      'schedule drawer',
      find.byType(WorkshopSideSheet),
      box(860, 0, 420, 800),
    );
    checkStyle('schedule title', find.text('Schedule new job'));

    expect(
      failures,
      isEmpty,
      reason: 'schedule: $passed/$checked key nodes within 1 px\n'
          '${failures.join('\n')}',
    );
  });

  testWidgets('assign dialog geometry within 1 logical px (1280 EN)', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      Scaffold(
        body: Center(
          child: Builder(
            builder: (dialogContext) => ElevatedButton(
              key: const Key('open-assign-dialog'),
              onPressed: () async {
                await WorkshopAssignDialog.show(dialogContext, _scheduleJob);
              },
              child: const Text('Open dialog'),
            ),
          ),
        ),
      ),
      _AssignFakeApi(),
    );
    await tester.tap(find.byKey(const Key('open-assign-dialog')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final failures = <String>[];
    var checked = 0;
    var passed = 0;
    void check(String label, Finder finder, Rect expected) {
      checked++;
      if (finder.evaluate().isEmpty) {
        failures.add('$label: not found');
        return;
      }
      final rect = tester.getRect(finder.first);
      final deltas = <String>[];
      if ((rect.left - expected.left).abs() > 1) {
        deltas.add('x ${rect.left.toStringAsFixed(2)} vs ${expected.left}');
      }
      if ((rect.top - expected.top).abs() > 1) {
        deltas.add('y ${rect.top.toStringAsFixed(2)} vs ${expected.top}');
      }
      if ((rect.width - expected.width).abs() > 1) {
        deltas.add('w ${rect.width.toStringAsFixed(2)} vs ${expected.width}');
      }
      if ((rect.height - expected.height).abs() > 1) {
        deltas.add('h ${rect.height.toStringAsFixed(2)} vs ${expected.height}');
      }
      if (deltas.isNotEmpty) {
        failures.add('$label: ${deltas.join(', ')}');
      } else {
        passed++;
      }
    }

    Rect box(double x, double y, double w, double h) =>
        Rect.fromLTWH(x, y, w, h);

    void checkStyle(String label, Finder finder) {
      checked++;
      if (finder.evaluate().isEmpty) {
        failures.add('$label style: not found');
        return;
      }
      final text = tester.widget<Text>(finder.first);
      final style = text.style;
      if (style == null) {
        failures.add('$label style: no explicit style');
        return;
      }
      const size = 16.0;
      const lineHeight = 22.0;
      const tracking = -0.16;
      final deltas = <String>[];
      if (style.fontSize != size) {
        deltas.add('size ${style.fontSize} vs $size');
      }
      if (style.fontWeight != FontWeight.w700) {
        deltas.add('weight ${style.fontWeight} vs w700');
      }
      final height = style.height;
      if (height == null || (height - lineHeight / size).abs() > 0.001) {
        deltas.add(
          'lineHeight ${height == null ? 'null' : (height * size).toStringAsFixed(2)} vs $lineHeight',
        );
      }
      final spacing = style.letterSpacing ?? 0;
      if ((spacing - tracking).abs() > 0.001) {
        deltas.add('tracking $spacing vs $tracking');
      }
      if (style.fontFamily != TrFonts.latin) {
        deltas.add('family ${style.fontFamily}');
      }
      if (deltas.isNotEmpty) {
        failures.add('$label style: ${deltas.join(', ')}');
      } else {
        passed++;
      }
    }

    // Assign dialog: centred 512 sheet (384 = (1280 - 512) / 2).
    check(
      'assign dialog',
      find.byType(WorkshopDialog),
      box(384, 148.75, 512, 502.5),
    );
    checkStyle('assign title', find.text('Assign technician'));

    expect(
      failures,
      isEmpty,
      reason: 'assign: $passed/$checked key nodes within 1 px\n'
          '${failures.join('\n')}',
    );
  });
}
