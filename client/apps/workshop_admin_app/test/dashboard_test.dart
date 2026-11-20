import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_style.dart';
import 'package:workshop_admin_app/src/features/dashboard/dashboard_tab.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_atlas.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_groups.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_hero.dart';
import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';
import 'package:workshop_admin_app/src/features/jobs/jobs_tab.dart';
import 'package:workshop_admin_app/src/features/staff/staff_tab.dart';
import 'package:workshop_admin_app/src/features/templates/templates_tab.dart';

import 'support/fake_admin_api.dart';

import 'support/ui_strings_harness.dart';

/// Structure and shell contract for the rebuilt dashboard (direction B).
///
/// Behaviour (counts, failures, empty, RTL, overflow, source rules) lives in
/// `dashboard_invariants_test.dart`. This file pins the *composition*: which
/// regions exist at which width, which old widgets are gone, and that the shell
/// still navigates.
///
/// Replaces the previous structural assertions (metric strip, 8 px 4-segment
/// pipeline bar, greeting header) — those widgets are deleted by the rebuild.
/// No behaviour case from the previous file was dropped: each one is either
/// here or stronger in `dashboard_invariants_test.dart`.
Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(1440, 900),
  bool withSession = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final container = ProviderContainer(
    overrides: [adminApiProvider.overrideWithValue(FakeAdminApi())],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        theme: AppTheme.light,
        builder: (context, child) => uiStringsScope(
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: const WorkshopAdminHomePage(),
      ),
    ),
  );
  if (withSession) {
    container.read(authControllerProvider.notifier).state =
        const AsyncData<Session?>(_session);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1440 composes hero, partition, three groups, one action', (
    tester,
  ) async {
    await _pump(tester);
    expect(tester.takeException(), isNull);

    final t = UiStrings.of(tester.element(find.byType(WorkshopAdminHomePage)));

    // Regions, in order.
    expect(find.byType(DashboardHero), findsOneWidget);
    expect(find.byType(DashboardAtlas), findsOneWidget);
    expect(find.byType(DashboardGroup), findsNWidgets(3));

    // The partition is the nine real buckets. The legend always carries all
    // nine, even when a bucket is zero.
    for (final status in dashboardStatusOrder) {
      expect(
        find.byKey(Key('dashboard-legend-$status')),
        findsOneWidget,
        reason: 'legend entry $status',
      );
    }

    // Group titles.
    expect(find.text(t(WorkshopAdminKeys.dashGroupWaiting)), findsOneWidget);
    expect(find.text(t(WorkshopAdminKeys.dashGroupInBay)), findsOneWidget);
    expect(find.text(t(WorkshopAdminKeys.dashGroupReady)), findsOneWidget);

    // The footer states the meaning of the partition.
    expect(
      find.text(t(WorkshopAdminKeys.dashFooterSum, {'total': 3})),
      findsOneWidget,
    );

    // Exactly one filled primary action on the page.
    expect(find.text(t(WorkshopAdminKeys.newJob)), findsOneWidget);
  });

  testWidgets('1024 keeps the horizontal atlas at the mid scale', (
    tester,
  ) async {
    await _pump(tester, size: const Size(1024, 900));
    expect(tester.takeException(), isNull);

    // With the dock shell the page gets the full window width (no sidebar), so
    // a 1024 window is the "wide" band: 76 px numeral, 64 px atlas.
    final scale = DashboardScale.byWidth(1024);
    expect(scale.horizontalAtlas, isTrue);
    final bar = tester.getSize(find.byKey(const Key('dashboard-atlas-bar')));
    expect(bar.height, scale.atlasHeight);
    expect(bar.height, 64);
    expect(scale.totalSize, 76);
  });

  testWidgets('390 uses the spine instead of the bar', (tester) async {
    await _pump(tester, size: const Size(390, 844));
    expect(tester.takeException(), isNull);

    expect(DashboardScale.byWidth(390).horizontalAtlas, isFalse);
    expect(find.byKey(const Key('dashboard-atlas-bar')), findsNothing);
    // Every stage still gets a row with its count.
    for (final status in dashboardStatusOrder) {
      expect(find.byKey(Key('dashboard-segment-$status')), findsOneWidget);
    }
    // Groups stack: one DashboardGroup per row is expected, and the first group
    // is wider than half the viewport.
    final waiting = tester.getSize(find.byType(DashboardGroup).first);
    expect(waiting.width, greaterThan(300));
  });

  testWidgets('the old dashboard widgets are gone', (tester) async {
    await _pump(tester);
    expect(find.byType(WorkshopMetricStrip), findsNothing);
    expect(find.byType(WorkshopPageHeader), findsNothing);
    expect(find.byType(WorkshopStatCard), findsNothing);
    // The metric-strip keys from the previous composition must not survive.
    for (final key in const [
      'dashboard-stat-active',
      'dashboard-stat-new-scheduled',
      'dashboard-stat-in-progress',
      'dashboard-stat-ready',
      'dashboard-stat-finalized-today',
      'dashboard-pipeline-bar',
      'dashboard-search',
    ]) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    // And no legacy vocabulary on screen.
    expect(find.text('Active jobs'), findsNothing);
    expect(find.text('Finalized today'), findsNothing);
    expect(find.text('Next up'), findsNothing);
    expect(find.text('Quick actions'), findsNothing);
  });

  testWidgets('rows expose stable keys per group', (tester) async {
    await _pump(tester);
    // The shared fake has one PENDING_REVIEW job (job-1).
    expect(
      find.byKey(const Key('dashboard-job-waiting-job-1')),
      findsOneWidget,
    );
  });

  testWidgets('tab navigation still reaches every tab', (tester) async {
    await _pump(tester, size: const Size(1280, 900));
    expect(find.byType(DashboardTab), findsOneWidget);

    for (final entry in <String, Type>{
      'jobs': JobsTab,
      'staff': StaffTab,
      'templates': TemplatesTab,
      'overview': DashboardTab,
    }.entries) {
      final tab = find.byKey(Key('workshop-tab-${entry.key}')).first;
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(entry.value), findsOneWidget);
    }
  });

  testWidgets('the shell names the workshop exactly once', (tester) async {
    await _pump(tester, withSession: true);
    // The identity strip carries it; the page itself no longer repeats it.
    expect(find.text('Marina Workshop'), findsOneWidget);
  });
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
