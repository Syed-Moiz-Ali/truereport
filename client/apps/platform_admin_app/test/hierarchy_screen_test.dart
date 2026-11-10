import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_header.dart';
import 'package:platform_admin_app/src/components/platform_sidebar.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/screens/hierarchy/hierarchy_screen.dart';
import 'package:platform_admin_app/src/screens/hierarchy/staff_board.dart';
import 'package:platform_admin_app/src/screens/hierarchy/tree_node_navigator.dart';
import 'support/fake_platform_api.dart';

Widget _buildTestApp({
  Locale locale = const Locale('en'),
  FakePlatformAdminApi? api,
}) {
  final fakeApi = api ?? FakePlatformAdminApi();
  return ProviderScope(
    overrides: [
      platformApiProvider.overrideWithValue(fakeApi),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: const HierarchyScreen(),
    ),
  );
}

void _setViewport(WidgetTester tester, {double width = 1280, double height = 1024}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('Screen 1 renders full desktop layout with sidebar, header, and split board', (tester) async {
    _setViewport(tester, width: 1280, height: 1196);
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // 1. Sidebar components
    expect(find.byType(PlatformSidebar), findsOneWidget);
    expect(find.text('CoreOS'), findsOneWidget);
    expect(find.text('Platform Admin'), findsOneWidget);
    expect(find.text('Workshops'), findsOneWidget);
    expect(find.text('Master Library'), findsOneWidget);
    expect(find.text('Data Catalogues'), findsOneWidget);
    expect(find.text('Equipment'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Audit Log'), findsOneWidget);
    expect(find.text('GRID V4.2 ONLINE'), findsOneWidget);

    // 2. Global Header components
    expect(find.byType(PlatformHeader), findsOneWidget);
    expect(find.text('Search platform assets, specs, workshop nodes...'), findsOneWidget);
    expect(find.text('Alex Vance'), findsOneWidget);
    expect(find.text('Principal Admin'), findsOneWidget);
    expect(find.text('AV'), findsOneWidget);

    // 3. Context Bar & Mode Switcher
    expect(find.text('HIERARCHY ROOT'), findsOneWidget);
    expect(find.text('EMEA INDUSTRIAL'), findsOneWidget);
    expect(find.text('Active Workshops'), findsOneWidget);
    expect(find.text('Directory View'), findsOneWidget);
    expect(find.text('Throughput'), findsOneWidget);

    // 4. Left Pane: TreeNodeNavigator
    expect(find.byType(TreeNodeNavigator), findsOneWidget);
    expect(find.text('Grid Facilities'), findsOneWidget);
    expect(find.text('FLEET INFRASTRUCTURE'), findsOneWidget);
    expect(find.text('Core Platform'), findsOneWidget);
    expect(find.text('v4.2'), findsOneWidget);
    expect(find.text('Workshop A'), findsOneWidget);
    expect(find.text('Workshop B'), findsOneWidget);
    expect(find.text('Workshop C'), findsOneWidget);
    expect(find.text('ASSIGNED BAY CAPACITY'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    expect(find.text('Filter Shift: Day Rotation'), findsOneWidget);

    // 5. Right Pane: StaffBoard
    expect(find.byType(StaffBoard), findsOneWidget);
    expect(find.text('Workshop A Staff'), findsOneWidget);
    expect(find.text('14 Active'), findsOneWidget);
    expect(find.byKey(const Key('btn-add-staff')), findsOneWidget);
    expect(find.text('Search staff by name, license ID, or bay role...'), findsOneWidget);

    // Filter tags
    expect(find.text('All (14)'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('Inspectors'), findsOneWidget);
    expect(find.text('Supervisors'), findsOneWidget);

    // Staff profiles
    expect(find.text('David Vance'), findsOneWidget);
    expect(find.text('Lead Inspector'), findsOneWidget);
    expect(find.text('Bay 01-04'), findsOneWidget);
    expect(find.text('Level 3 Master'), findsOneWidget);

    expect(find.text('Marcus Vance'), findsOneWidget);
    expect(find.text('Diagnostic Tech'), findsOneWidget);
    expect(find.text('Diagnostics Bay'), findsOneWidget);
    expect(find.text('CAN Bus / EV High-V'), findsOneWidget);

    expect(find.text('Sarah Jenkins'), findsOneWidget);
    expect(find.text('Shop Floor Supervisor'), findsOneWidget);
    expect(find.text('Floor Command'), findsOneWidget);
    expect(find.text('ISO-9001 Lead'), findsOneWidget);

    expect(find.text('Elena Rostova'), findsOneWidget);
    expect(find.text('Optics & Sensor Calibration'), findsOneWidget);
    expect(find.text('ADAS Align'), findsOneWidget);
    expect(find.text('Bosch / Hella ADAS'), findsOneWidget);

    // Footnote & Pagination
    expect(find.text('Showing 4 of 14 registered personnel in Workshop A'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Utility Metrics Strip
    expect(find.text('LIVE UTILIZATION'), findsOneWidget);
    expect(find.text('94.2%'), findsOneWidget);
    expect(find.text('+3.1%'), findsOneWidget);

    expect(find.text('AVG INSPECTION TIME'), findsOneWidget);
    expect(find.text('18.4m'), findsOneWidget);
    expect(find.text('-2.2m'), findsOneWidget);

    expect(find.text('PASS RATE VELOCITY'), findsOneWidget);
    expect(find.text('99.1%'), findsOneWidget);
  });

  testWidgets('Selecting a filter tag narrows the staff profiles stack', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // Tap "Diagnostics" tag
    await tester.tap(find.text('Diagnostics'));
    await tester.pumpAndSettle();

    // Only Marcus Vance should match
    expect(find.text('Marcus Vance'), findsOneWidget);
    expect(find.text('David Vance'), findsNothing);
    expect(find.text('Sarah Jenkins'), findsNothing);

    // Tap "All (14)" tag to restore
    await tester.tap(find.text('All (14)'));
    await tester.pumpAndSettle();
    expect(find.text('David Vance'), findsOneWidget);
    expect(find.text('Marcus Vance'), findsOneWidget);
  });

  testWidgets('Searching staff by text filters matching candidates', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    final searchField = find.widgetWithText(
      TextField,
      'Search staff by name, license ID, or bay role...',
    );
    await tester.enterText(searchField, 'Elena');
    await tester.pumpAndSettle();

    expect(find.text('Elena Rostova'), findsOneWidget);
    expect(find.text('David Vance'), findsNothing);
    expect(find.text('Marcus Vance'), findsNothing);
  });

  testWidgets('Clicking another workshop updates selection', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // Tap Workshop B
    await tester.tap(find.text('Workshop B'));
    await tester.pumpAndSettle();

    expect(find.text('Workshop B Staff'), findsOneWidget);
  });

  testWidgets('RTL and Arabic localization renders cleanly without overflows', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    await tester.pumpWidget(_buildTestApp(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Responsive layouts at 1024 and 800 width render without overflows', (tester) async {
    for (final width in [1280.0, 1024.0, 800.0]) {
      _setViewport(tester, width: width, height: 900);
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
