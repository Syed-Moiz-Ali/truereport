import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/features/hierarchy/workshop_details_screen.dart';

import 'support/fake_platform_api.dart';

Widget _buildTestApp({
  required FakePlatformAdminApi fakeApi,
  Size screenSize = const Size(1280, 1024),
  Locale locale = const Locale('en'),
  String? workshopId,
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
        child: WorkshopDetailsScreen(workshopId: workshopId),
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

  group('Screen 4: Workshop Details & Settings Tests', () {
    testWidgets('renders all Figma header, metric chips, and form fields faithfully',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      // Eyebrow and telematics
      expect(find.text('WORKSPACE HIERARCHY'), findsOneWidget);
      expect(find.text('Live Telematics Sync'), findsOneWidget);

      // Metrics
      expect(find.text('WORKFORCE'), findsOneWidget);
      expect(find.text('THROUGHPUT'), findsOneWidget);
      expect(find.text('OPERATIONAL STATE'), findsOneWidget);

      // Left Validation Protocol
      expect(find.text('VALIDATION PROTOCOL'), findsOneWidget);
      expect(find.textContaining('ISO 26262'), findsOneWidget);

      // Tabs
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Permissions'), findsOneWidget);
      expect(find.text('Audit'), findsOneWidget);

      // Form Fields
      expect(find.byKey(const Key('input-workshop-admin-name')), findsOneWidget);
      expect(find.byKey(const Key('input-workshop-contact-phone')), findsOneWidget);
      expect(find.byKey(const Key('switch-enable-workshop')), findsOneWidget);
      expect(find.byKey(const Key('btn-discard-workshop-details')), findsOneWidget);
      expect(find.byKey(const Key('btn-save-workshop-details')), findsOneWidget);
    });

    testWidgets('allows editing form inputs and toggling the enable switch',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final adminInput = find.byKey(const Key('input-workshop-admin-name'));
      await tester.enterText(adminInput, 'Elena Rostova');
      expect(find.text('Elena Rostova'), findsOneWidget);

      final phoneInput = find.byKey(const Key('input-workshop-contact-phone'));
      await tester.enterText(phoneInput, '+1 (555) 999-0000');
      expect(find.text('+1 (555) 999-0000'), findsOneWidget);

      final switchWidget = find.byKey(const Key('switch-enable-workshop'));
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      expect(find.text('Enable/Disable Workshop (Muted)'), findsOneWidget);
    });

    testWidgets('switches between General, Permissions, and Audit tabs',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      // Tap Permissions tab
      await tester.tap(find.text('Permissions'));
      await tester.pumpAndSettle();
      expect(find.text('Role-Based Access Control (RBAC)'), findsOneWidget);
      expect(find.text('Technician Dispatch Clearance'), findsOneWidget);

      // Tap Audit tab
      await tester.tap(find.text('Audit'));
      await tester.pumpAndSettle();
      expect(find.text('Node Lifecycle & Telematics Audit Log'), findsOneWidget);
      expect(find.text('Diagnostic Telematics Link Verified'), findsOneWidget);

      // Return to General tab
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('input-workshop-admin-name')), findsOneWidget);
    });

    testWidgets('submitting save changes triggers feedback SnackBar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('btn-save-workshop-details'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Workshop settings updated successfully.'), findsOneWidget);
    });

    testWidgets('responsive layout on 400px mobile without RenderFlex overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(
        _buildTestApp(fakeApi: fakeApi, screenSize: const Size(400, 900)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('input-workshop-admin-name')), findsOneWidget);
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
