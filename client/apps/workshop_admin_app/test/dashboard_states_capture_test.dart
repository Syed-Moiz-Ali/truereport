import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Phase 6 evidence for the rebuilt dashboard: every state the page can be in,
/// plus the text-scale extremes. Widths are covered by
/// `workshop_real_font_screenshot_test.dart` (1440/1280/1024/768/390/360 + AR).
///
/// Writes to `docs/evidence/dashboard_states/`. Real fonts come from
/// `flutter_test_config.dart`; a missing family would fail the first test.
const String _outDir = 'docs/evidence/dashboard_states';

const _counts = CleanJobCounts(
  draft: 1,
  scheduled: 4,
  assigned: 3,
  inProgress: 5,
  pendingReview: 4,
  approved: 2,
  published: 3,
  rejected: 1,
  cancelled: 1,
  total: 24,
);

CleanJob _job(String id, String status, String make, String model) => CleanJob(
  id: id,
  reference: 'JOB-10$id',
  status: status,
  reviewStatus: status,
  publicationStatus: 'NOT_PUBLISHED',
  templateVersionId: 'v1',
  templateNameEn: 'Full inspection',
  templateNameAr: 'فحص شامل',
  templateVersionNo: 1,
  assignedTechnicianId: 'tech-1',
  assignedTechnicianName: 'Rashid K.',
  customerName: 'Ahmed Al Mansoori',
  customerPhone: '+971500000100',
  customerEmail: 'a@test.local',
  vehicleVin: 'TESTVIN00000000002',
  vehicleMake: make,
  vehicleModel: model,
  vehicleYear: 2022,
  vehiclePlate: 'A12345',
  odometerValue: 45000,
  odometerUnit: 'KM',
  transmission: 'AUTOMATIC',
  fuelType: 'PETROL',
  preferredLanguage: 'en',
  scheduledAt: '2026-11-05T09:00:00',
  startedAt: null,
  completedAt: null,
  approvedAt: null,
  publishedAt: null,
  cancelledAt: null,
  approvedBy: null,
  cancelledBy: null,
  cancelReason: null,
  score: null,
  gradeCode: null,
  safetyCapApplied: false,
  safetyCapReason: null,
  consentGranted: true,
  createdAt: '2026-11-04T08:00:00',
  updatedAt: '2026-11-05T10:00:00',
  version: 1,
);

final _jobs = <CleanJob>[
  _job('482', 'PENDING_REVIEW', 'Nissan', 'Patrol'),
  _job('479', 'PENDING_REVIEW', 'Toyota', 'Land Cruiser'),
  _job('477', 'PENDING_REVIEW', 'Lexus', 'LX 600'),
  _job('471', 'PENDING_REVIEW', 'Ford', 'F-150'),
  _job('485', 'IN_PROGRESS', 'Mercedes', 'G 63'),
  _job('480', 'IN_PROGRESS', 'BMW', 'X5'),
  _job('476', 'IN_PROGRESS', 'Toyota', 'Hilux'),
  _job('465', 'APPROVED', 'Porsche', 'Macan'),
  _job('463', 'APPROVED', 'Land Rover', 'Defender'),
];

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    expect(boundary, isNotNull, reason: name);
    final image = await boundary!.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull, reason: name);
    final dir = Directory(_outDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('${dir.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  });
}

Future<void> _pump(
  WidgetTester tester,
  GlobalKey key, {
  required AdminApi api,
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(1280, 900),
  double height = 900,
  Session? session = _session,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final container = ProviderContainer(
    overrides: [
      adminApiProvider.overrideWithValue(api),
      authControllerProvider.overrideWith(() => _FixedAuth(session)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: RepaintBoundary(
          key: key,
          child: Material(
            color: AppTheme.light.scaffoldBackgroundColor,
            child: SizedBox(
              width: size.width,
              height: height,
              child: const WorkshopAdminHomePage(),
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // A never-resolving fake keeps the page in its loading state; settle would
    // time out, so pump a few frames instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }
  container.read(authControllerProvider.notifier).state = AsyncData<Session?>(
    session,
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('ready 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: _jobs),
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'ready_1280');
  });

  testWidgets('empty workshop 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(
        counts: const CleanJobCounts(
          draft: 0,
          scheduled: 0,
          assigned: 0,
          inProgress: 0,
          pendingReview: 0,
          approved: 0,
          published: 0,
          rejected: 0,
          cancelled: 0,
          total: 0,
        ),
        fixtures: const [],
      ),
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'empty_1280');
  });

  testWidgets('counts failure 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: _jobs, countsError: true),
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'counts_error_1280');
  });

  testWidgets('one group fails 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(
        counts: _counts,
        fixtures: _jobs,
        errorStatus: 'PENDING_REVIEW',
      ),
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'group_error_1280');
  });

  testWidgets('unaccounted remainder 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(
        counts: const CleanJobCounts(
          draft: 1,
          scheduled: 4,
          assigned: 3,
          inProgress: 5,
          pendingReview: 4,
          approved: 2,
          published: 3,
          rejected: 1,
          cancelled: 1,
          total: 26,
        ),
        fixtures: _jobs,
      ),
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'remainder_1280');
  });

  testWidgets('Arabic 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: _jobs),
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'ready_1280_ar');
  });

  testWidgets('1.5x text 390', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: _jobs),
      size: const Size(390, 844),
      height: 1200,
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'scale150_390');
  });

  testWidgets('2x text 390', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: _jobs),
      size: const Size(390, 844),
      height: 1400,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'scale200_390');
  });

  testWidgets('2x text 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: _jobs),
      size: const Size(1280, 900),
      height: 1500,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'scale200_1280');
  });

  testWidgets('loading 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: _jobs, pending: true),
      settle: false,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'loading_1280');
  });

  testWidgets('both counts and lists fail 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(
        counts: _counts,
        fixtures: _jobs,
        countsError: true,
        allGroupsError: true,
      ),
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'both_error_1280');
  });

  testWidgets('groups empty while counts are healthy 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: const []),
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'groups_empty_1280');
  });

  testWidgets('no session 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: _jobs),
      session: null,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'no_session_1280');
  });

  testWidgets('1.5x text 1280', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      key,
      api: _Api(counts: _counts, fixtures: _jobs),
      size: const Size(1280, 900),
      height: 1400,
      textScale: 1.5,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'scale150_1280');
  });

  for (final entry in const {
    'ready_768': Size(768, 900),
    'ready_360': Size(360, 800),
  }.entries) {
    testWidgets(entry.key, (tester) async {
      final key = GlobalKey();
      await _pump(
        tester,
        key,
        api: _Api(counts: _counts, fixtures: _jobs),
        size: entry.value,
        height: entry.value.height * 2,
      );
      expect(tester.takeException(), isNull);
      await _capture(tester, key, entry.key);
    });
  }
}

const _session = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(
    id: 'user-1',
    email: 'layla@test.local',
    displayName: 'Layla Haddad',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    Membership(
      workshopId: 'workshop-1',
      workshopName: 'Marina Workshop',
      role: Role.workshopAdmin,
    ),
  ],
);

class _FixedAuth extends AuthController {
  _FixedAuth(this.value);

  final Session? value;

  @override
  Future<Session?> build() async => value;
}

class _Api implements AdminApi {
  _Api({
    required this.counts,
    required this.fixtures,
    this.countsError = false,
    this.errorStatus,
    this.allGroupsError = false,
    this.pending = false,
  });

  final CleanJobCounts counts;
  final List<CleanJob> fixtures;
  final bool countsError;
  final String? errorStatus;

  /// Every group list fails (both-error state).
  final bool allGroupsError;

  /// Never resolves (loading state).
  final bool pending;

  final Completer<void> _never = Completer<void>();

  @override
  Future<CleanJobCounts> cleanJobCounts() async {
    if (pending) {
      return _never.future.then((_) => counts);
    }
    if (countsError) {
      throw StateError('counts failed');
    }
    return counts;
  }

  @override
  Future<JobPage> cleanJobs({
    int page = 0,
    int size = 20,
    String status = '',
    String search = '',
    String from = '',
    String to = '',
  }) async {
    if (pending) {
      return _never.future.then(
        (_) => JobPage(
          items: const [],
          page: page,
          size: size,
          total: 0,
          totalPages: 0,
        ),
      );
    }
    if (allGroupsError || (errorStatus != null && status == errorStatus)) {
      throw StateError('jobs failed');
    }
    final filtered = status.isEmpty
        ? fixtures
        : fixtures.where((job) => job.status == status).toList(growable: false);
    return JobPage(
      items: filtered.take(size).toList(growable: false),
      page: page,
      size: size,
      total: filtered.length,
      totalPages: filtered.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<CleanJob> cleanJob(String id) async =>
      fixtures.firstWhere((job) => job.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
