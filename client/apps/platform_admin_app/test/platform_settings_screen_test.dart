import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/settings/platform_settings_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

import 'support/ui_message_fixtures.dart';

const _testLanguage = PlatformLanguage(
  code: 'en',
  nativeName: 'English',
  direction: 'ltr',
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
      supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
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
  group('Platform settings', () {
    testWidgets('renders the real localization summary and seed action', (
      tester,
    ) async {
      _setViewport(tester, width: 1280, height: 1293);
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('CONFIGURATION SCOPE • GLOBAL ROOT'), findsOneWidget);
      expect(find.text('Platform Settings'), findsOneWidget);
      expect(find.text('Production Cluster EU-West'), findsOneWidget);
      expect(find.text('Languages & Coverage'), findsOneWidget);
      expect(find.text('Translation coverage'), findsOneWidget);
      expect(find.text('Language registry: 1'), findsOneWidget);
      expect(find.byKey(const Key('btn-developer-seed')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('removed settings controls no longer render', (tester) async {
      _setViewport(tester, width: 1280, height: 1293);
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('switch-telematics')), findsNothing);
      expect(find.byKey(const Key('switch-pdf-generation')), findsNothing);
      expect(find.byKey(const Key('switch-webhooks-enabled')), findsNothing);
      expect(find.byKey(const Key('switch-2fa')), findsNothing);
      expect(find.byKey(const Key('switch-ip-whitelist')), findsNothing);
      expect(find.byKey(const Key('dropdown-session-timeout')), findsNothing);
      expect(find.byKey(const Key('btn-save-settings')), findsNothing);
      expect(find.byKey(const Key('btn-discard-settings')), findsNothing);
      expect(find.textContaining('Admin Session Timeout'), findsNothing);
      expect(find.textContaining('Telematics'), findsNothing);
      expect(find.textContaining('Instant PDF'), findsNothing);
      expect(find.textContaining('Webhooks Healthy'), findsNothing);
      expect(find.textContaining('Enforce 2FA'), findsNothing);
      expect(find.textContaining('IP Restriction'), findsNothing);
    });

    testWidgets('compact layout has no overflow', (tester) async {
      _setViewport(tester, width: 400, height: 1000);
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Platform Settings'), findsOneWidget);
      expect(find.text('Languages & Coverage'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic RTL renders without overflow', (tester) async {
      _setViewport(tester, width: 1280, height: 1293);
      await tester.pumpWidget(_buildTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.text('إعدادات المنصة'), findsOneWidget);
      expect(find.text('اللغات والتغطية'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
