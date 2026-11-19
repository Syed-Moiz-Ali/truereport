import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_fonts.dart';

/// Phase 5 gallery for the rebuilt app shell: every primitive, in every state it
/// can take, LTR and RTL, at 1x and 2x. Writes to `docs/evidence/gallery/`.
const String _outDir = 'docs/evidence/gallery';

const _destinations = <WorkshopNavDestination>[
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
    label: 'Settings',
    icon: Icons.settings_outlined,
    key: Key('workshop-tab-settings'),
  ),
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
  Widget child,
  Size size,
  GlobalKey key, {
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: RepaintBoundary(
            key: key,
            child: Material(
              color: AppTheme.light.scaffoldBackgroundColor,
              child: Directionality(
                textDirection: direction,
                child: SizedBox.fromSize(size: size, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _stage(Widget child) => Align(
  alignment: Alignment.center,
  child: Padding(padding: const EdgeInsets.all(24), child: child),
);

void main() {
  test('real fonts for the shell gallery', () {
    expect(RealFonts.isLoaded, isTrue);
    expect(RealFonts.missingFamilies, isEmpty);
  });

  testWidgets('dock default', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      _stage(
        WorkshopShellDock(
          destinations: _destinations,
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
      const Size(820, 140),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'shell_dock_default');
  });

  testWidgets('dock another section selected', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      _stage(
        WorkshopShellDock(
          destinations: _destinations,
          selectedIndex: 2,
          onSelected: (_) {},
        ),
      ),
      const Size(820, 140),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'shell_dock_staff');
  });

  testWidgets('dock narrow', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      SizedBox(
        width: 390,
        child: WorkshopShellDock(
          destinations: _destinations,
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
      const Size(390, 120),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'shell_dock_narrow');
  });

  testWidgets('dock 2x', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      SizedBox(
        width: 390,
        child: WorkshopShellDock(
          destinations: _destinations,
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
      const Size(390, 160),
      key,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'shell_dock_scale2');
  });

  testWidgets('dock RTL', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      _stage(
        WorkshopShellDock(
          destinations: const [
            WorkshopNavDestination(
              label: 'نظرة عامة',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
            ),
            WorkshopNavDestination(label: 'المهام', icon: Icons.work_outline),
            WorkshopNavDestination(
              label: 'الموظفون',
              icon: Icons.groups_outlined,
            ),
            WorkshopNavDestination(
              label: 'القوالب',
              icon: Icons.dashboard_customize_outlined,
            ),
            WorkshopNavDestination(
              label: 'الإعدادات',
              icon: Icons.settings_outlined,
            ),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
      const Size(820, 140),
      key,
      direction: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'shell_dock_rtl');
  });

  testWidgets('identity strip LTR', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShellIdentityStrip(
            workshopName: 'Marina Workshop',
            accountInitials: 'LH',
            accountName: 'Layla Haddad',
            accountEmail: 'layla@test.local',
            onSettings: () {},
            onSignOut: () {},
            onToggleLanguage: () {},
            languageLabel: 'العربية',
            settingsLabel: 'Settings',
            signOutLabel: 'Sign out',
            notificationsAction: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      const Size(900, 60),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'shell_strip_ltr');
  });

  testWidgets('identity strip RTL', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShellIdentityStrip(
            workshopName: 'ورشة المارينا',
            accountInitials: 'LH',
            accountName: 'ليلى حداد',
            accountEmail: 'layla@test.local',
            onSettings: () {},
            onSignOut: () {},
            onToggleLanguage: () {},
            languageLabel: 'English',
            settingsLabel: 'الإعدادات',
            signOutLabel: 'تسجيل الخروج',
            notificationsAction: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      const Size(900, 60),
      key,
      direction: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'shell_strip_rtl');
  });

  testWidgets('identity strip narrow', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShellIdentityStrip(
            workshopName: 'Marina Workshop',
            accountInitials: 'LH',
            accountName: 'Layla Haddad',
            accountEmail: 'layla@test.local',
            onSettings: () {},
            onSignOut: () {},
            onToggleLanguage: () {},
            languageLabel: 'العربية',
            settingsLabel: 'Settings',
            signOutLabel: 'Sign out',
            notificationsAction: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      const Size(390, 60),
      key,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'shell_strip_narrow');
  });

  // The account popup renders in the root overlay, which sits outside the
  // capture boundary, so it is proven by `workshop_kit_test` behaviour tests
  // rather than by a screenshot. Recorded in docs/shell_qa.md.
}
