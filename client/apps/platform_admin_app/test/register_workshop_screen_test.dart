import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/features/hierarchy/register_workshop_screen.dart';

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
        child: const RegisterWorkshopScreen(),
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

  group('Screen 3: Register New Workshop Tests', () {
    testWidgets('renders all Figma header, breadcrumb, and form fields faithfully',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      // Breadcrumbs
      expect(find.text('PLATFORM'), findsOneWidget);
      expect(find.text('WORKSHOPS'), findsOneWidget);
      expect(find.text('NEW ENTITY'), findsOneWidget);

      // Page Title & Subtitle
      expect(find.text('Register New Workshop'), findsOneWidget);
      expect(
        find.textContaining('Deploy a new operational node to your inspection grid'),
        findsOneWidget,
      );

      // Form Field Labels & Badges
      expect(find.text('Workshop Business Name'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
      expect(find.text('Location / Region'), findsOneWidget);
      expect(find.text('Primary Contact Email'), findsOneWidget);

      // Template Assignment Card
      expect(find.text('Assign Initial Template'), findsOneWidget);
      expect(find.text('100-Point Standard Check v2.0'), findsOneWidget);

      // Sync Switch Card
      expect(find.text('Automatic Master Catalog Sync'), findsOneWidget);
      expect(find.byKey(const Key('switch-master-catalog-sync')), findsOneWidget);

      // Action Buttons
      expect(find.text('Discard & Return'), findsOneWidget);
      expect(find.text('Create Workshop'), findsOneWidget);
      expect(find.text('DEMO FILL'), findsOneWidget);
    });

    testWidgets('validates required business name on submission', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final createBtn = find.byKey(const Key('btn-create-workshop'));
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Workshop business name is required.'), findsOneWidget);
    });

    testWidgets('validates invalid contact email format', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      // Enter valid name but invalid email
      await tester.enterText(
        find.byKey(const Key('input-workshop-name')),
        'Metro Hub One',
      );
      await tester.enterText(
        find.byKey(const Key('input-workshop-email')),
        'invalid-email-no-at',
      );

      final createBtn = find.byKey(const Key('btn-create-workshop'));
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid contact email address.'),
        findsOneWidget,
      );
    });

    testWidgets('demo quick fill populates all standard test fields',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final demoBtn = find.byKey(const Key('btn-demo-quick-fill'));
      await tester.ensureVisible(demoBtn);
      await tester.tap(demoBtn);
      await tester.pumpAndSettle();

      expect(find.text('Apex Fleet Central'), findsOneWidget);
      expect(find.text('San Francisco Bay Area'), findsOneWidget);
      expect(find.text('operations@apexfleet.com'), findsOneWidget);
    });

    testWidgets('template picker allows selecting alternative templates',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final templateCard = find.byKey(const Key('template-selector-card'));
      await tester.ensureVisible(templateCard);
      await tester.tap(templateCard);
      await tester.pumpAndSettle();

      expect(find.text('Select Initial Inspection Template'), findsOneWidget);
      expect(find.text('Heavy Commercial Powertrain Audit'), findsOneWidget);

      // Select Heavy Commercial Powertrain Audit
      await tester.tap(find.text('Heavy Commercial Powertrain Audit'));
      await tester.pumpAndSettle();

      // Verified template updated on the card
      expect(find.text('Heavy Commercial Powertrain Audit'), findsOneWidget);
    });

    testWidgets('switch toggles master catalog sync state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('switch-master-catalog-sync'));
      await tester.ensureVisible(switchFinder);
      expect(switchFinder, findsOneWidget);

      // Toggle switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('successful creation provisions workshop in API and shows snackbar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(_buildTestApp(fakeApi: fakeApi));
      await tester.pumpAndSettle();

      final initialWorkshopCount = fakeApi.workshops.length;

      // Fill in demo data
      final demoBtn = find.byKey(const Key('btn-demo-quick-fill'));
      await tester.ensureVisible(demoBtn);
      await tester.tap(demoBtn);
      await tester.pumpAndSettle();

      // Tap Create Workshop
      final createBtn = find.byKey(const Key('btn-create-workshop'));
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify API received new workshop
      expect(fakeApi.workshops.length, initialWorkshopCount + 1);
      expect(fakeApi.workshops.last.name, 'Apex Fleet Central');
      expect(fakeApi.workshops.last.branchName, 'San Francisco Bay Area');

      // Verify success snackbar
      expect(
        find.textContaining('Workshop "Apex Fleet Central" provisioned successfully.'),
        findsOneWidget,
      );
    });

    testWidgets('renders cleanly on mobile viewport without overflow',
        (tester) async {
      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
        originalOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(_buildTestApp(
        fakeApi: fakeApi,
        screenSize: const Size(400, 800),
      ));
      await tester.pumpAndSettle();

      if (errorDetails != null) {
        debugPrint('DIAGNOSTIC ERROR: ${errorDetails!.summary}');
      }
      expect(errorDetails, isNull);
      expect(find.text('Register New Workshop'), findsOneWidget);
      expect(find.byKey(const Key('btn-create-workshop')), findsOneWidget);
    });

    testWidgets('renders cleanly in RTL Arabic locale without overflow',
        (tester) async {
      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
        originalOnError?.call(details);
      };

      await tester.binding.setSurfaceSize(const Size(1024, 800));
      await tester.pumpWidget(_buildTestApp(
        fakeApi: fakeApi,
        screenSize: const Size(1024, 800),
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      if (errorDetails != null) {
        debugPrint('DIAGNOSTIC ERROR: ${errorDetails!.summary}');
      }
      expect(errorDetails, isNull);
      expect(find.text('Register New Workshop'), findsOneWidget);
    });
  });
}
