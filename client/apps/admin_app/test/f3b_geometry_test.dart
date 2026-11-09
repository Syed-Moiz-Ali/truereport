import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/pages/staff_tab.dart';
import 'package:admin_app/src/pages/templates_tab.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fake_admin_api.dart';

void main() {
  testWidgets('staff management geometry within 1 logical px (1280 EN)', (tester) async {
    const width = 1280.0;
    const height = 1048.0;

    tester.view.physicalSize = const Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        adminApiProvider.overrideWithValue(FakeAdminApi()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          home: const Scaffold(
            body: StaffTab(),
          ),
        ),
      ),
    );
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
      final actual = tester.getRect(finder.first);
      final dx = (actual.left - expected.left).abs();
      final dy = (actual.top - expected.top).abs();
      final dw = (actual.width - expected.width).abs();
      final dh = (actual.height - expected.height).abs();
      if (dx > 1.0 || dy > 1.0 || dw > 1.0 || dh > 1.0) {
        failures.add(
          '$label: actual $actual != expected $expected '
          '(dx=$dx, dy=$dy, dw=$dw, dh=$dh)',
        );
      } else {
        passed++;
      }
    }

    Rect box(double x, double y, double w, double h) => Rect.fromLTWH(x, y, w, h);

    // Header: 1184 x 80 at (96, 0).
    check(
      'staff header',
      find.byKey(const ValueKey('f3b-header')),
      box(96, 0, 1184, 80),
    );

    // Add Staff CTA: 149.47 x 56 at (1090.53, 100).
    check(
      'add staff button',
      find.byKey(const ValueKey('f3b-add')),
      box(1090.53, 100, 149.47, 56),
    );

    // Metric 1: 352 x 132 at (136, 264).
    check(
      'metric 1',
      find.byKey(const ValueKey('f3b-metric-1')),
      box(136, 264, 352, 132),
    );

    // First card: 346.67 x 190 at (136, 428).
    check(
      'first staff card',
      find.byKey(const ValueKey('f3b-card-1')),
      box(136, 428, 346.67, 190),
    );

    // Banner: 1104 x 112 at (136, 840).
    check(
      'nfc banner',
      find.byKey(const ValueKey('f3b-banner')),
      box(136, 840, 1104, 112),
    );

    expect(
      failures,
      isEmpty,
      reason: 'staff: $passed/$checked key nodes within 1 px\n'
          '${failures.join('\n')}',
    );
  });

  testWidgets('templates list geometry within 1 logical px (1280 EN)', (tester) async {
    const width = 1280.0;
    const height = 1586.0;

    tester.view.physicalSize = const Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        adminApiProvider.overrideWithValue(FakeAdminApi()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          home: const Scaffold(
            body: TemplatesTab(),
          ),
        ),
      ),
    );
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
      final actual = tester.getRect(finder.first);
      final dx = (actual.left - expected.left).abs();
      final dy = (actual.top - expected.top).abs();
      final dw = (actual.width - expected.width).abs();
      final dh = (actual.height - expected.height).abs();
      if (dx > 1.0 || dy > 1.0 || dw > 1.0 || dh > 1.0) {
        failures.add(
          '$label: actual $actual != expected $expected '
          '(dx=$dx, dy=$dy, dw=$dw, dh=$dh)',
        );
      } else {
        passed++;
      }
    }

    Rect box(double x, double y, double w, double h) => Rect.fromLTWH(x, y, w, h);

    // Header: 1184 x 80 at (96, 0).
    check(
      'templates header',
      find.byKey(const ValueKey('f3b-header')),
      box(96, 0, 1184, 80),
    );

    // Add Template CTA: 190.56 x 56 at (1049.44, 94).
    check(
      'add template button',
      find.byKey(const ValueKey('f3b-add')),
      box(1049.44, 94, 190.56, 56),
    );

    // Metric 1: 258 x 130 at (136, 212).
    check(
      'metric 1',
      find.byKey(const ValueKey('f3b-metric-1')),
      box(136, 212, 258, 130),
    );

    // First card: 346.67 x 437.13 at (136, 471.25).
    check(
      'first template card',
      find.byKey(const ValueKey('f3b-card-1')),
      box(136, 471.25, 346.67, 437.13),
    );

    // Banner: 1104 x 88 at (136, 1450).
    check(
      'validation banner',
      find.byKey(const ValueKey('f3b-banner')),
      box(136, 1450, 1104, 88),
    );

    expect(
      failures,
      isEmpty,
      reason: 'templates: $passed/$checked key nodes within 1 px\n'
          '${failures.join('\n')}',
    );
  });
}
