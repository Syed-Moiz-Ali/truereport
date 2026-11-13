import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/features/settings/platform_settings_screen.dart';

import 'support/ui_message_fixtures.dart';

const _testLanguage = PlatformLanguage(
  code: 'en',
  nameEn: 'English',
  nameAr: 'الإنجليزية',
  nativeName: 'English',
  direction: 'LTR',
  active: true,
  isDefault: true,
  sortOrder: 1,
);

const _testCoverage = TranslationCoverage(
  languages: ['en', 'ar'],
  namespaces: {'common': CoverageNamespace(total: 12, missing: [])},
);

class _TestLocaleNotifier extends LocaleController {
  _TestLocaleNotifier(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

Widget _buildTestApp({Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(
        locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      platformLocaleProvider.overrideWith(() => _TestLocaleNotifier(locale)),
      platformLanguagesProvider.overrideWith(
        (ref) async => const [_testLanguage],
      ),
      translationCoverageProvider.overrideWith((ref) async => _testCoverage),
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
      home: const PlatformSettingsScreen(),
    ),
  );
}

void _setViewport(
  WidgetTester tester, {
  required double width,
  required double height,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

void main() {
  group('Screen 10: Global Platform Settings Tests', () {
    testWidgets(
      'renders all Figma header, environment badge, and 3 bento cards',
      (tester) async {
        _setViewport(tester, width: 1280, height: 1293);
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        // 1. Header & Environment Badge
        expect(find.text('CONFIGURATION SCOPE • GLOBAL ROOT'), findsOneWidget);
        expect(find.text('Platform Settings'), findsOneWidget);
        expect(
          find.text(
            'Global runtime policies, regional localizations, and system authentication rules',
          ),
          findsOneWidget,
        );
        expect(find.text('Production Cluster EU-West'), findsOneWidget);

        // 2. Card 1: Localization
        expect(find.text('Localization'), findsOneWidget);
        expect(
          find.text('Multilingual dictionary & typography sets'),
          findsOneWidget,
        );
        expect(find.text('3 Languages'), findsOneWidget);
        expect(find.text('Enable Arabic (RTL) Localization'), findsOneWidget);
        expect(find.text('Enable Spanish Support'), findsOneWidget);
        expect(find.text('Enable French Support'), findsOneWidget);
        expect(
          find.textContaining(
            'Activating a regional dialect dynamically triggers localized font subset packages',
          ),
          findsOneWidget,
        );

        // 3. Card 2: Security & Access
        expect(find.text('Security & Access'), findsOneWidget);
        expect(
          find.text('Zero-trust technician permissions & token life'),
          findsOneWidget,
        );
        expect(find.text('Admin Session Timeout'), findsOneWidget);
        expect(find.text('30 Minutes'), findsOneWidget);
        expect(find.text('Enforce 2FA (TOTP) for All Admins'), findsOneWidget);
        expect(find.text('IP Restriction Whitelist'), findsOneWidget);
        expect(find.text('Audit Token Encryption'), findsOneWidget);
        expect(find.text('ED25519-SHA512'), findsOneWidget);

        // 4. Card 3: Automated Fleet Dispatch & Webhooks
        expect(
          find.text('Automated Fleet Dispatch & Webhooks'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Webhooks Healthy • 99.98% SLA'),
          findsOneWidget,
        );
        expect(find.text('Real-Time Telematics Ingestion'), findsOneWidget);
        expect(find.text('WEBSOCKET STREAMING ACTIVE'), findsOneWidget);
        expect(find.text('Instant PDF Generation On Sign-Off'), findsOneWidget);
        expect(find.text('AUTO-DISTRIBUTION HOOK'), findsOneWidget);

        // 5. Action Bar
        expect(
          find.text('All changes sync immediately to edge nodes upon save'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('btn-discard-settings')), findsOneWidget);
        expect(find.byKey(const Key('btn-save-settings')), findsOneWidget);
      },
    );

    testWidgets('toggling switches and dropdowns updates preferences state', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1293);
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Toggle Spanish switch
      final spanishSwitch = find.byKey(const Key('switch-spanish'));
      expect(tester.widget<Switch>(spanishSwitch).value, isTrue);
      await tester.tap(spanishSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(spanishSwitch).value, isFalse);

      // Toggle IP Whitelist switch
      final ipSwitch = find.byKey(const Key('switch-ip-whitelist'));
      expect(tester.widget<Switch>(ipSwitch).value, isFalse);
      await tester.tap(ipSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(ipSwitch).value, isTrue);

      // Toggle Telematics Ingestion switch
      final telematicsSwitch = find.byKey(const Key('switch-telematics'));
      expect(tester.widget<Switch>(telematicsSwitch).value, isTrue);
      await tester.tap(telematicsSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(telematicsSwitch).value, isFalse);
    });

    testWidgets('discard button resets toggles and shows feedback snackbar', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1293);
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Flip Spanish switch to false
      await tester.tap(find.byKey(const Key('switch-spanish')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Switch>(find.byKey(const Key('switch-spanish'))).value,
        isFalse,
      );

      // Tap Discard (section added below webhooks; scroll into view first)
      await tester.ensureVisible(find.byKey(const Key('btn-discard-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn-discard-settings')));
      await tester.pumpAndSettle();

      // Spanish should be reset to true
      expect(
        tester.widget<Switch>(find.byKey(const Key('switch-spanish'))).value,
        isTrue,
      );
      expect(find.text('Preferences reset to default values.'), findsOneWidget);
    });

    testWidgets('save preferences button triggers success SnackBar feedback', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1293);
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap Save (section added below webhooks; scroll into view first)
      await tester.ensureVisible(find.byKey(const Key('btn-save-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn-save-settings')));
      await tester.pumpAndSettle();

      expect(
        find.text('Platform preferences saved and propagated to edge nodes!'),
        findsOneWidget,
      );
    });

    testWidgets('shows Languages & Coverage summary with link to sub-page', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1293);
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // New section title from ARB (plain language, no scoring UI).
      expect(find.text('Languages & Coverage'), findsOneWidget);
      expect(find.text('Translation coverage'), findsOneWidget);
      // Summary pills + single navigation action (existing keys only).
      expect(find.text('Language registry: 1'), findsOneWidget);
      expect(find.text('Language registry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'responsive layout on 400px compact mobile without RenderFlex overflow',
      (tester) async {
        _setViewport(tester, width: 400, height: 1000);
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Platform Settings'), findsOneWidget);
        expect(find.text('Production Cluster EU-West'), findsOneWidget);
        expect(find.text('Localization'), findsOneWidget);
        expect(find.text('Security & Access'), findsOneWidget);
        expect(
          find.text('Automated Fleet Dispatch & Webhooks'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders cleanly in Arabic RTL locale without overflow', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1293);
      await tester.pumpWidget(_buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('إعدادات المنصة'), findsOneWidget);
      expect(find.text('التوطين'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
