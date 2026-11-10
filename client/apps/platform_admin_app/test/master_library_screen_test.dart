import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/features/master_library/master_library_screen.dart';

import 'support/fake_platform_api.dart';

Widget _buildTestApp({
  required FakePlatformAdminApi fakeApi,
  Size screenSize = const Size(1280, 1024),
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      platformApiProvider.overrideWithValue(fakeApi),
      platformLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: const MasterLibraryScreen(),
      ),
    ),
  );
}

class _TestLocaleNotifier extends LocaleNotifier {
  _TestLocaleNotifier(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePlatformAdminApi fakeApi;

  setUp(() {
    fakeApi = FakePlatformAdminApi();
  });

  group('Screen 5: Shared Master Inspection-Item Library Tests', () {
    testWidgets('renders all Figma headers, category pills, and checkpoint cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      // Eyebrow & Title
      expect(find.text('ACTIVE CANONICAL REPO'), findsOneWidget);
      expect(find.text('Global Master Library'), findsOneWidget);
      expect(
        find.text(
          'Centrally governed diagnostic checkpoints deployed across all workshop nodes',
        ),
        findsOneWidget,
      );

      // Header Buttons
      expect(find.byKey(const Key('btn-rules-matrix')), findsOneWidget);
      expect(find.byKey(const Key('btn-new-master-item')), findsOneWidget);

      // Category filter pills
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Brakes & Calipers'), findsOneWidget);
      expect(find.text('Powertrain'), findsOneWidget);
      expect(find.text('Tires & Axles'), findsOneWidget);
      expect(find.text('Chassis Integrity'), findsOneWidget);

      // Sync indicator
      expect(find.text('SYNCED:'), findsOneWidget);
      expect(find.text('48 Workshop Clusters'), findsOneWidget);

      // Checkpoint card sample texts
      expect(find.text('CHK-BRK-001'), findsOneWidget);
      expect(find.text('Brake Pad Thickness & Disc Runout'), findsOneWidget);
      expect(find.text('CHK-PWR-014'), findsOneWidget);
      expect(find.text('Engine Oil Level & Viscosity Grade'), findsOneWidget);
      expect(find.text('CHK-TIR-004'), findsOneWidget);
      expect(find.text('Tread Depth All Axles'), findsOneWidget);

      // Bottom Sync Banner
      expect(find.text('Master Fleet Sync Policy'), findsOneWidget);
      expect(find.byKey(const Key('btn-instant-push')), findsOneWidget);
    });

    testWidgets('filtering by category updates displayed checkpoint cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      // Tap 'Brakes & Calipers'
      await tester.tap(find.byKey(const Key('filter-cat-Brakes & Calipers')));
      await tester.pumpAndSettle();

      // Brakes item should be present
      expect(find.text('CHK-BRK-001'), findsOneWidget);
      expect(find.text('Brake Pad Thickness & Disc Runout'), findsOneWidget);

      // Powertrain and Tires items should NOT be present
      expect(find.text('CHK-PWR-014'), findsNothing);
      expect(find.text('CHK-TIR-004'), findsNothing);

      // Tap 'Powertrain'
      await tester.tap(find.byKey(const Key('filter-cat-Powertrain')));
      await tester.pumpAndSettle();

      expect(find.text('CHK-PWR-014'), findsOneWidget);
      expect(find.text('CHK-BRK-001'), findsNothing);

      // Switch back to 'All Categories'
      await tester.tap(find.byKey(const Key('filter-cat-All Categories')));
      await tester.pumpAndSettle();

      expect(find.text('CHK-BRK-001'), findsOneWidget);
      expect(find.text('CHK-PWR-014'), findsOneWidget);
    });

    testWidgets('tapping Rules Matrix opens dialog with governance policies',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn-rules-matrix')));
      await tester.pumpAndSettle();

      expect(find.text('Master Rules Governance Matrix'), findsOneWidget);
      expect(find.text('1. Mandatory Signoff'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Master Rules Governance Matrix'), findsNothing);
    });

    testWidgets('instant push button triggers broadcast feedback',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final pushButton = find.byKey(const Key('btn-instant-push'));
      await tester.ensureVisible(pushButton);
      await tester.tap(pushButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Fleet sync successfully broadcast to 48 workshop clusters.'),
        findsOneWidget,
      );
    });

    testWidgets('responsive layout on 400px mobile without RenderFlex overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(
        _buildTestApp(fakeApi: fakeApi, screenSize: const Size(400, 900)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Global Master Library'), findsOneWidget);
    });

    testWidgets('renders cleanly in Arabic RTL without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(
        _buildTestApp(fakeApi: fakeApi, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
