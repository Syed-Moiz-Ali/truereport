import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_fonts.dart';

/// Gate 6 F1: at the documented 360 px floor the dock must still *name* the
/// section. This lives in the app package because only the app's test config
/// loads the bundled fonts; under Ahem every glyph is a 14 px square and the
/// assertion would measure the test harness, not the product.
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
      label: 'Settings',
      icon: Icons.settings_outlined,
      key: Key('workshop-tab-settings'),
    ),
  ];

  Future<void> pump(WidgetTester tester, int selectedIndex) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: WorkshopAppShell(
          workshopName: 'Marina Workshop',
          sectionLabel: destinations[selectedIndex].label,
          selectedIndex: selectedIndex,
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
  }

  test('real fonts are loaded for the shell floor test', () {
    expect(RealFonts.isLoaded, isTrue);
    expect(RealFonts.missingFamilies, isEmpty);
  });

  for (final index in [0, 1, 4]) {
    testWidgets('at 360 the active label is readable: '
        '${destinations[index].label}', (tester) async {
      await pump(tester, index);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(destinations[index].label),
      );
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason:
            '${destinations[index].label} is clipped at 360 — the dock no '
            'longer names the current section (Gate 6 F1).',
      );
    });
  }
}
