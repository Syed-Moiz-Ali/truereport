import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/templates/templates_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

import 'support/ui_message_fixtures.dart';

Widget _app() {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
      templatesProvider.overrideWith((ref) async => const <GlobalTemplate>[]),
      platformLanguagesProvider.overrideWith(
        (ref) async => const <PlatformLanguage>[],
      ),
    ],
    child: const MaterialApp(
      supportedLocales: <Locale>[Locale('en')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(size: Size(1280, 900)),
        child: TemplatesScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('template create form is English-only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create template').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('template-name')), findsOneWidget);
    expect(find.byKey(const Key('template-description')), findsOneWidget);
    expect(find.byKey(const Key('template-name-ar')), findsNothing);
    expect(find.byKey(const Key('template-description-ar')), findsNothing);
    expect(find.text('Template name (Arabic)'), findsNothing);
    expect(find.text('Description (Arabic)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
