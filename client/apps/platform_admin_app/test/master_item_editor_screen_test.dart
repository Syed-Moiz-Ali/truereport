import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/master_library/master_item_editor_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

import 'support/ui_message_fixtures.dart';

const _category = PlatformCategory(
  id: 'cat-1',
  code: 'CAT-BRK',
  name: 'Braking Systems & Tyres',
  status: 'ACTIVE',
  sortOrder: 1,
  active: true,
  itemCount: 5,
);

const _english = PlatformLanguage(
  code: 'en',
  nativeName: 'English',
  direction: 'ltr',
  active: true,
  isDefault: true,
  sortOrder: 1,
  status: 'LIVE',
);

const _arabic = PlatformLanguage(
  code: 'ar',
  nativeName: 'العربية',
  direction: 'rtl',
  active: true,
  isDefault: false,
  sortOrder: 2,
  status: 'LIVE',
);

const _chinese = PlatformLanguage(
  code: 'zh-Hans',
  nativeName: '中文',
  direction: 'ltr',
  active: true,
  isDefault: false,
  sortOrder: 3,
  status: 'DRAFT',
);

Widget _app({Locale locale = const Locale('en'), double width = 1280}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(
        locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
      categoriesProvider.overrideWith((ref) async => const [_category]),
      optionSetsProvider.overrideWith((ref) async => const []),
      platformLanguagesProvider.overrideWith(
        (ref) async => const [_english, _arabic, _chinese],
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: <Locale>[const Locale('en'), const Locale('ar')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: const MasterItemEditorScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders create mode stepper starting at basics', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Item code'), findsWidgets);
    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text('Basics'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('stepper blocks Next until basics are valid', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stepper-next')).hitTestable());
    await tester.pumpAndSettle();
    // Still on Basics: code/category are required.
    expect(find.text('Step 1 of 6'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item code'),
      'BRK-NEW-01',
    );
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<String>, 'Category'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Braking Systems & Tyres').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stepper-next')).hitTestable());
    await tester.pumpAndSettle();
    // Content step exposes only the English source label/instruction fields;
    // no Arabic or registry-driven dynamic language tabs/fields.
    expect(find.text('Step 2 of 6'), findsOneWidget);
    expect(find.byKey(const Key('item-label')), findsOneWidget);
    expect(find.byKey(const Key('item-instruction')), findsOneWidget);
    expect(find.text('中文'), findsNothing);
    expect(find.text('Arabic'), findsNothing);
    expect(find.text('English instruction'), findsOneWidget);
  });

  testWidgets('renders on compact width without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(_app(width: 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
