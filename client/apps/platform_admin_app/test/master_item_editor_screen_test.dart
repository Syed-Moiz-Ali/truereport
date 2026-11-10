import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/features/master_library/master_item_editor_screen.dart';

import 'support/fake_platform_api.dart';

Widget _buildTestApp({
  required FakePlatformAdminApi fakeApi,
  Size screenSize = const Size(1280, 1024),
  Locale locale = const Locale('en'),
  String? itemId = 'item-1',
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
        child: MasterItemEditorScreen(itemId: itemId),
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

  group('Screen 6: Master Item Content & Translation Editor Tests', () {
    testWidgets('renders all Figma headers, telemetry metrics, and dual-language inputs',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      // Eyebrow and Status
      expect(find.text('MASTER LIBRARY'), findsOneWidget);
      expect(find.text('Checkpoint #042'), findsOneWidget);
      expect(find.text('Active Specification'), findsOneWidget);

      // Title & Pill options
      expect(find.text('Edit Master Item: Brake Pad Thickness'), findsOneWidget);
      expect(find.text('Dual Language View'), findsOneWidget);
      expect(find.text('Audit Version 4.1'), findsOneWidget);

      // 4 Metric Cards
      expect(find.text('SUBSYSTEM'), findsOneWidget);
      expect(find.text('MEASUREMENT METRIC'), findsOneWidget);
      expect(find.text('OEM MINIMUM THRESHOLD'), findsOneWidget);
      expect(find.text('SYNC STATUS'), findsOneWidget);
      expect(find.text('Live across 18 Hubs'), findsOneWidget);

      // Dual language columns
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Primary Source'), findsOneWidget);
      expect(find.text('EN-US'), findsOneWidget);
      expect(find.text('عربي (Arabic)'), findsOneWidget);
      expect(find.text('Auto-synchronized'), findsOneWidget);
      expect(find.text('AR-SA (RTL)'), findsOneWidget);

      // Input keys
      expect(find.byKey(const Key('input-item-title-en')), findsOneWidget);
      expect(find.byKey(const Key('input-item-desc-en')), findsOneWidget);
      expect(find.byKey(const Key('input-item-title-ar')), findsOneWidget);
      expect(find.byKey(const Key('input-item-desc-ar')), findsOneWidget);

      // Schematic Upload & attached files
      expect(find.text('Visual Reference & Schematic'), findsOneWidget);
      expect(find.text('Upload Guide Image'), findsOneWidget);
      expect(find.byKey(const Key('btn-add-schematic-angle')), findsOneWidget);

      // Bottom Action Bar
      expect(find.byKey(const Key('btn-cancel-edit-item')), findsOneWidget);
      expect(find.byKey(const Key('btn-save-master-item')), findsOneWidget);
    });

    testWidgets('allows editing English and Arabic text fields',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final enTitle = find.byKey(const Key('input-item-title-en'));
      await tester.enterText(enTitle, 'Custom Brake Rotor Runout');
      expect(find.text('Custom Brake Rotor Runout'), findsOneWidget);

      final arTitle = find.byKey(const Key('input-item-title-ar'));
      await tester.enterText(arTitle, 'انحراف قرص الفرامل المعدل');
      expect(find.text('انحراف قرص الفرامل المعدل'), findsOneWidget);
    });

    testWidgets('adding secondary angle schematic increases attached files',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const Key('btn-add-schematic-angle'));
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('caliper_secondary_angle_'), findsOneWidget);
    });

    testWidgets('submitting Save Changes triggers confirmation SnackBar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('btn-save-master-item'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.text('Master checkpoint specification saved and broadcasted.'),
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
      expect(find.text('MASTER LIBRARY'), findsOneWidget);
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
