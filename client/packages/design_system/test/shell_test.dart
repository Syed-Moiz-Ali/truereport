import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract tests for the rebuilt app shell (direction C "The dock").
///
/// These replace the previous sidebar/rail/More-sheet assertions, which
/// described a composition that no longer exists. What is pinned here is the
/// behaviour the rest of the app depends on:
///   - all six destinations exist and are reachable at every width;
///   - the host's `workshop-tab-*` keys ride on the tappable item;
///   - the workshop is named exactly once;
///   - the language control is visible without opening a menu;
///   - the content can never be trapped behind the dock;
///   - RTL mirrors the dock.
void main() {
  const destinations = <WorkshopNavDestination>[
    WorkshopNavDestination(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      key: Key('workshop-tab-overview'),
    ),
    WorkshopNavDestination(
      label: 'Jobs',
      icon: Icons.work_outline,
      key: Key('workshop-tab-jobs'),
    ),
    WorkshopNavDestination(
      label: 'Staff',
      icon: Icons.groups_outlined,
      key: Key('workshop-tab-staff'),
    ),
    WorkshopNavDestination(
      label: 'Templates',
      icon: Icons.dashboard_customize_outlined,
      key: Key('workshop-tab-templates'),
    ),
    WorkshopNavDestination(
      label: 'Job board',
      icon: Icons.assignment_outlined,
      key: Key('workshop-tab-job-board'),
    ),
    WorkshopNavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      key: Key('workshop-tab-settings'),
    ),
  ];

  Future<void> pumpShell(
    WidgetTester tester, {
    required Size size,
    ValueChanged<int>? onSelected,
    int selectedIndex = 0,
    TextDirection direction = TextDirection.ltr,
    Widget child = const SizedBox.expand(),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Directionality(
          textDirection: direction,
          child: WorkshopAppShell(
            workshopName: 'Marina Workshop',
            sectionLabel: 'Overview',
            selectedIndex: selectedIndex,
            onSelected: onSelected ?? (_) {},
            destinations: destinations,
            accountInitials: 'LH',
            accountName: 'Layla Haddad',
            accountEmail: 'layla@example.test',
            onSettings: () {},
            onSignOut: () {},
            onToggleLanguage: () {},
            languageLabel: 'Arabic',
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every destination is reachable at 1280 and selects', (
    tester,
  ) async {
    var selected = -1;
    await pumpShell(
      tester,
      size: const Size(1280, 800),
      onSelected: (index) => selected = index,
    );

    for (final destination in destinations) {
      expect(
        find.byKey(destination.key!),
        findsOneWidget,
        reason: '${destination.label} must be in the dock',
      );
    }
    // The selected item carries its label; the rest are icons.
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Jobs'), findsNothing);

    await tester.tap(find.byKey(const Key('workshop-tab-jobs')));
    expect(selected, 1);
  });

  testWidgets('every destination is reachable at 390 (no More sheet)', (
    tester,
  ) async {
    var selected = -1;
    await pumpShell(
      tester,
      size: const Size(390, 844),
      onSelected: (index) => selected = index,
    );

    for (final destination in destinations) {
      expect(find.byKey(destination.key!), findsOneWidget);
    }
    expect(find.byKey(const Key('workshop-tab-more')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('workshop-tab-settings')));
    expect(selected, 5);
  });

  testWidgets('the workshop is named exactly once', (tester) async {
    await pumpShell(tester, size: const Size(1280, 800));
    expect(find.text('Marina Workshop'), findsOneWidget);
    expect(find.text('TrueReport'), findsOneWidget);
    // The old breadcrumb is gone.
    expect(find.textContaining('/ Overview'), findsNothing);
  });

  testWidgets('the language control is visible without opening a menu', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(390, 844));
    expect(find.text('Arabic'), findsOneWidget);
    expect(find.byIcon(Icons.translate), findsOneWidget);
  });

  testWidgets('content can never be trapped behind the dock', (tester) async {
    await pumpShell(tester, size: const Size(1280, 800));
    final content = tester.getRect(find.byType(SizedBox).first);
    final dock = tester.getRect(find.byType(WorkshopShellDock));
    // The content area ends above the dock's top edge (the dock floats in the
    // reserved band, it does not overlay the scroll viewport).
    expect(content.bottom, lessThanOrEqualTo(dock.top + 1));
  });

  testWidgets('RTL mirrors the dock order', (tester) async {
    await pumpShell(
      tester,
      size: const Size(1280, 800),
      direction: TextDirection.rtl,
    );
    final overview = tester.getCenter(
      find.byKey(const Key('workshop-tab-overview')),
    );
    final jobs = tester.getCenter(find.byKey(const Key('workshop-tab-jobs')));
    // In RTL the first destination sits to the right of the second.
    expect(overview.dx, greaterThan(jobs.dx));
  });

  testWidgets('a long workshop name ellipsizes instead of wrapping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: WorkshopAppShell(
          workshopName: 'Marina Automatic Transmission and General Mechanical Workshop LLC',
          sectionLabel: 'Overview',
          selectedIndex: 0,
          onSelected: (_) {},
          destinations: destinations,
          accountInitials: 'LH',
          accountName: 'Layla Haddad',
          accountEmail: 'layla@example.test',
          onSettings: () {},
          onSignOut: () {},
          onToggleLanguage: () {},
          languageLabel: 'Arabic',
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final strip = tester.getSize(find.byType(ShellIdentityStrip));
    expect(strip.height, 44);
  });

  testWidgets('2x text scale keeps the dock on screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: WorkshopAppShell(
          workshopName: 'Marina Workshop',
          sectionLabel: 'Overview',
          selectedIndex: 0,
          onSelected: (_) {},
          destinations: destinations,
          accountInitials: 'LH',
          accountName: 'Layla Haddad',
          accountEmail: 'layla@example.test',
          onSettings: () {},
          onSignOut: () {},
          onToggleLanguage: () {},
          languageLabel: 'Arabic',
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final dock = tester.getRect(find.byType(WorkshopShellDock));
    expect(dock.left, greaterThanOrEqualTo(0));
    expect(dock.right, lessThanOrEqualTo(390));
  });
}
