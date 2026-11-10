import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/screens/catalogues/data_catalogues_screen.dart';

class _TestLocaleNotifier extends LocaleNotifier {
  _TestLocaleNotifier(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

Widget _buildTestApp({
  Locale locale = const Locale('en'),
  Size screenSize = const Size(1280, 1024),
}) {
  return ProviderScope(
    overrides: [
      platformLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      home: MediaQuery(
        data: MediaQueryData(
          size: screenSize,
        ),
        child: const DataCataloguesScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen 7: Master Dropdowns & Data Catalogues Tests', () {
    testWidgets('renders all Figma headers, segmented tabs, and catalogues',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Breadcrumb and headings
      expect(find.text('PLATFORM DICTIONARIES & TAXONOMIES'), findsOneWidget);
      expect(find.text('System Data Catalogues'), findsOneWidget);
      expect(find.text('Global Standard'), findsOneWidget);
      expect(find.text('Workshop Overrides'), findsOneWidget);

      // Left Catalogues list
      expect(find.text('Catalogues'), findsOneWidget);
      expect(find.text('5 Entities'), findsOneWidget);
      expect(find.text('Vehicle Makes'), findsOneWidget);
      expect(find.text('Defect Severities'), findsOneWidget);
      expect(find.text('Not-Checked Reasons'), findsOneWidget);
      expect(find.text('Fuel & Powertrain Types'), findsOneWidget);
      expect(find.text('Fluid Specifications'), findsOneWidget);

      // OEM Sync Pipeline
      expect(find.text('OEM Sync Pipeline'), findsOneWidget);

      // Active catalogue entries
      expect(find.text('Vehicle Makes (Active)'), findsOneWidget);
      expect(find.text('11 Catalogued'), findsOneWidget);
      expect(find.text('Toyota'), findsOneWidget);
      expect(find.text('Porsche'), findsOneWidget);
      expect(find.text('Mercedes-Benz'), findsOneWidget);

      // Quick index & actions
      expect(find.text('QUICK INDEX'), findsOneWidget);
      expect(find.text('Revert to OEM Preset'), findsOneWidget);
      expect(find.text('Publish Catalogue'), findsOneWidget);
    });

    testWidgets('switching catalogue updates details card entries',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap Defect Severities catalogue
      final severitiesBtn =
          find.byKey(const Key('catalogue-entity-severities'));
      await tester.ensureVisible(severitiesBtn);
      await tester.tap(severitiesBtn);
      await tester.pumpAndSettle();

      expect(find.text('Defect Severities (Active)'), findsOneWidget);
      expect(find.text('4 Catalogued'), findsOneWidget);
      expect(find.textContaining('P0 - Critical'), findsOneWidget);
      expect(find.text('Immediate Stop'), findsOneWidget);
    });

    testWidgets('adding and removing items dynamically updates list',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Add "Genesis" make
      final input = find.byKey(const Key('input-add-catalogue-item'));
      await tester.enterText(input, 'Genesis');
      final addBtn = find.byKey(const Key('btn-add-catalogue-item'));
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Genesis'), findsOneWidget);
      expect(find.text('12 Catalogued'), findsOneWidget);

      // Delete "Toyota"
      final removeToyota = find.byKey(const Key('btn-remove-item-1'));
      await tester.tap(removeToyota);
      await tester.pumpAndSettle();

      expect(find.text('Toyota'), findsNothing);
      expect(find.text('11 Catalogued'), findsOneWidget);
    });

    testWidgets('filtering by quick index reduces displayed list',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Click "T-Z" filter
      final tzFilter = find.byKey(const Key('filter-alpha-T-Z'));
      await tester.tap(tzFilter);
      await tester.pumpAndSettle();

      expect(find.text('Toyota'), findsOneWidget);
      expect(find.text('Tesla'), findsOneWidget);
      expect(find.text('Volvo'), findsOneWidget);
      expect(find.text('BMW'), findsNothing);
      expect(find.text('Ford'), findsNothing);
    });

    testWidgets('Revert to OEM Preset and Publish Catalogue actions trigger SnackBars',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Remove an item first
      final removeToyota = find.byKey(const Key('btn-remove-item-1'));
      await tester.tap(removeToyota);
      await tester.pumpAndSettle();
      expect(find.text('Toyota'), findsNothing);

      // Revert to OEM
      final revertBtn = find.byKey(const Key('btn-revert-oem-preset'));
      await tester.ensureVisible(revertBtn);
      await tester.tap(revertBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Toyota'), findsOneWidget);
      expect(
        find.textContaining('Reverted Vehicle Makes to OEM factory default'),
        findsOneWidget,
      );

      // Publish Catalogue
      final publishBtn = find.byKey(const Key('btn-publish-catalogue'));
      await tester.tap(publishBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Vehicle Makes catalogue published and broadcasted'),
        findsOneWidget,
      );
    });

    testWidgets('responsive layout on 400px mobile without RenderFlex overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(
        _buildTestApp(screenSize: const Size(400, 900)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('System Data Catalogues'), findsOneWidget);
    });

    testWidgets('renders cleanly in Arabic RTL without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(
        _buildTestApp(locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
