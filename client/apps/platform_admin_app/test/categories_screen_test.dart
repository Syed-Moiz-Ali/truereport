import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/master_library/categories_screen.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
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

class _FakeConfigApi extends PlatformConfigApi {
  _FakeConfigApi()
    : super(
        ApiClient(
          config: const ApiConfig(
            baseUrl: 'http://localhost',
            environment: 'test',
          ),
        ),
        const ApiEndpoints(baseUrl: 'http://localhost'),
      );

  Map<String, dynamic>? lastBody;

  @override
  Future<PlatformCategory> createCategory(Map<String, dynamic> body) async {
    lastBody = body;
    return PlatformCategory(
      id: 'cat-created',
      code: body['code'] as String? ?? '',
      name: body['name'] as String? ?? '',
      status: 'ACTIVE',
      sortOrder: body['sortOrder'] as int? ?? 0,
      active: true,
      itemCount: 0,
    );
  }
}

Widget _app(_FakeConfigApi api) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
      platformConfigApiProvider.overrideWithValue(api),
      categoriesProvider.overrideWith((ref) async => const [_category]),
      itemsProvider.overrideWith((ref, query) async => const <PlatformItem>[]),
      configHealthProvider.overrideWith(
        (ref) async => const ConfigHealth(healthy: true, checks: []),
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
        child: CategoriesScreen(),
      ),
    ),
  );
}

Future<void> _openAddDialog(WidgetTester tester) async {
  await tester.tap(find.text('Add category'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('category form is English-only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(_FakeConfigApi()));
    await tester.pumpAndSettle();

    await _openAddDialog(tester);

    expect(find.byKey(const Key('category-name')), findsOneWidget);
    expect(find.byKey(const Key('category-name-ar')), findsNothing);
    expect(find.text('Category name (Arabic)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category create sends the plain source name', (tester) async {
    final api = _FakeConfigApi();
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await _openAddDialog(tester);
    await tester.enterText(find.byKey(const Key('category-code')), 'CAT-NEW');
    await tester.enterText(
      find.byKey(const Key('category-name')),
      'New Category',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(api.lastBody, isNotNull);
    expect(api.lastBody!['name'], 'New Category');
    expect(api.lastBody!['code'], 'CAT-NEW');
    expect(api.lastBody!.containsKey('nameEn'), isFalse);
    expect(api.lastBody!.containsKey('nameAr'), isFalse);
  });
}
