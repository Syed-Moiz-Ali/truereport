import 'dart:io';
import 'dart:ui' as ui;

import 'package:api_client/api_client.dart';
import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/master_library/categories_screen.dart';
import 'package:platform_admin_app/src/features/master_library/master_item_editor_screen.dart';
import 'package:platform_admin_app/src/features/master_library/master_library_screen.dart';
import 'package:platform_admin_app/src/features/master_library/option_sets_screen.dart';
import 'package:platform_admin_app/src/features/templates/template_builder_screen.dart';
import 'package:platform_admin_app/src/features/templates/templates_screen.dart';

final _baseUrl =
    Platform.environment['LIVE_BASE_URL'] ?? 'http://localhost:8080';
final _email = Platform.environment['LIVE_E2E_EMAIL'];
final _password = Platform.environment['LIVE_E2E_PASSWORD'];
final _secondEmail =
    Platform.environment['LIVE_E2E_SECOND_EMAIL'] ?? 'platform@truereport.test';
final _secondPassword =
    Platform.environment['LIVE_E2E_SECOND_PASSWORD'] ?? _password;
final _runLive = Platform.environment['LIVE_E2E'] == '1';

GlobalKey? _shotKey;

Widget _app(Widget home, ApiClient client, ApiEndpoints endpoints) {
  final shotKey = GlobalKey();
  _shotKey = shotKey;
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(client),
      apiEndpointsProvider.overrideWithValue(endpoints),
    ],
    child: RepaintBoundary(
      key: shotKey,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: <Locale>[const Locale('en'), const Locale('ar')],
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: home,
      ),
    ),
  );
}

Future<ApiClient> _login(String email, String password) async {
  final client = ApiClient(
    config: ApiConfig(baseUrl: _baseUrl, environment: 'dev'),
  );
  final response = await client.postDynamic(
    '/api/v1/auth/login',
    body: <String, dynamic>{'email': email, 'password': password},
  );
  client.accessToken =
      (response as Map<String, dynamic>)['accessToken'] as String;
  client.acceptLanguage = 'en';
  return client;
}

Future<void> _flush(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  });
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final context = _shotKey?.currentContext;
    final boundary = context?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final dir = Directory(
      Platform.environment['EVIDENCE_DIR'] ??
          '../../../docs/evidence/platform_admin',
    )..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

Future<T> _live<T>(WidgetTester tester, Future<T> Function() action) async {
  final result = await tester.runAsync(action);
  return result as T;
}

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  ApiClient client,
  ApiEndpoints endpoints,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await tester.pumpWidget(_app(home, client, endpoints));
  await _flush(tester);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _flush(tester);
}

Future<void> _tapButton(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _flush(tester);
}

Future<void> _selectDropdown(
  WidgetTester tester,
  Finder dropdown,
  String optionText,
) async {
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await _flush(tester);
  for (var attempt = 0; attempt < 8; attempt++) {
    if (find.text(optionText).hitTestable().evaluate().isNotEmpty) break;
    final lists = find.byType(ListView);
    if (lists.evaluate().isEmpty) break;
    await tester.drag(lists.last, const Offset(0, -260));
    await tester.pumpAndSettle();
  }
  final option = find.text(optionText).hitTestable();
  expect(option, findsWidgets);
  await tester.tap(option.last);
  await tester.pumpAndSettle();
}

Future<void> _enterByLabel(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.widgetWithText(TextFormField, label).last;
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<List<dynamic>> _list(
  WidgetTester tester,
  ApiClient client,
  String path,
) async {
  final value = await _live(tester, () => client.getDynamic(path));
  return value is List<dynamic> ? value : const <dynamic>[];
}

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();
  if (!_runLive) {
    test('platform admin live e2e (skipped)', () {}, skip: true);
    return;
  }

  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('Platform Admin UI -> API -> DB live flow', (tester) async {
    if (_email == null ||
        _email!.isEmpty ||
        _password == null ||
        _password!.isEmpty) {
      fail(
        'LIVE_E2E=1 requires LIVE_E2E_EMAIL and LIVE_E2E_PASSWORD. '
        'Optionally set LIVE_E2E_SECOND_EMAIL / LIVE_E2E_SECOND_PASSWORD '
        'for the maker-checker approver.',
      );
    }
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final client = await _live(tester, () => _login(_email!, _password!));
    final endpoints = ApiEndpoints(baseUrl: _baseUrl);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final categoryCode = 'LIVE-CAT-$stamp';
    final categoryName = 'Live Category $stamp';
    final itemCode = 'LIVE-ITEM-$stamp';
    final optionSetCode = 'LIVE-SET-$stamp';
    final optionSetName = 'Live Set $stamp';
    final templateCode = 'LIVE-TPL-$stamp';

    await _pump(tester, const MasterLibraryScreen(), client, endpoints);
    await _tapText(tester, 'Load default checklist');
    expect(find.byType(AlertDialog), findsOneWidget);
    await _tapButton(
      tester,
      find.widgetWithText(FilledButton, 'Load default checklist'),
    );
    expect(find.textContaining('Seed completed'), findsOneWidget);
    await _shot(tester, '01_master_library_seed');

    await _pump(tester, const CategoriesScreen(), client, endpoints);
    await _tapText(tester, 'Add category');
    expect(find.byType(AlertDialog), findsOneWidget);
    final categoryFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    expect(categoryFields, findsNWidgets(4));
    await tester.enterText(categoryFields.at(0), categoryCode);
    await tester.enterText(categoryFields.at(1), categoryName);
    await tester.enterText(categoryFields.at(2), 'فئة مباشرة $stamp');
    await tester.enterText(categoryFields.at(3), '9');
    await _tapText(tester, 'Save');

    final categories = await _list(
      tester,
      client,
      '/api/v1/platform/master/categories',
    );
    final category = categories.cast<Map<String, dynamic>>().firstWhere(
      (row) => row['code'] == categoryCode,
    );
    final categoryId = category['id'] as String;
    expect(categoryId, isNotEmpty);
    expect(category['labelEn'], categoryName);
    await _shot(tester, '02_category_created');

    await _pump(tester, const OptionSetsScreen(), client, endpoints);
    await _tapText(tester, 'Add option set');
    final setFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(setFields.at(0), optionSetCode);
    await tester.enterText(setFields.at(1), optionSetName);
    await tester.enterText(setFields.at(2), 'مجموعة مباشرة $stamp');
    await tester.enterText(setFields.at(3), '99');
    await _tapText(tester, 'Save');

    final sets = await _list(
      tester,
      client,
      '/api/v1/platform/master/option-sets',
    );
    final optionSet = sets.cast<Map<String, dynamic>>().firstWhere(
      (row) => row['code'] == optionSetCode,
    );
    expect(optionSet['id'], isNotEmpty);

    await _pump(tester, const MasterItemEditorScreen(), client, endpoints);
    await _selectDropdown(
      tester,
      find.byType(DropdownButtonFormField<String>).first,
      categoryName,
    );
    await _enterByLabel(tester, 'Item code', itemCode);
    await _enterByLabel(tester, 'Label (English)', 'Live item $stamp');
    await _enterByLabel(tester, 'Label (Arabic)', 'عنصر مباشر $stamp');
    await _enterByLabel(tester, 'English', 'Live EN instruction');
    await _enterByLabel(tester, 'Arabic', 'تعليمات مباشرة');
    await _enterByLabel(tester, 'Measurement unit', 'MM');
    await _enterByLabel(tester, 'Sensor / tool', 'Vernier');
    await _enterByLabel(tester, 'Standard spec (English)', 'Above 3 mm');
    await _enterByLabel(tester, 'Standard spec (Arabic)', 'أعلى من 3 مم');
    await _tapButton(tester, find.widgetWithText(ElevatedButton, 'Save'));

    final items = await _list(
      tester,
      client,
      '/api/v1/platform/master/items?search=$itemCode',
    );
    final item = items.cast<Map<String, dynamic>>().first;
    final itemId = item['id'] as String;
    expect(item['stableCode'], itemCode);
    await _shot(tester, '03_item_created');

    final detail = await _live(
      tester,
      () => client.getDynamic('/api/v1/platform/master/items/$itemId'),
    );
    final version =
        (detail as Map<String, dynamic>)['versions'][0] as Map<String, dynamic>;
    final versionId = version['id'] as String;
    expect(version['status'], 'DRAFT');

    await _tapText(tester, 'Evidence rules');
    await _tapButton(tester, find.widgetWithText(ElevatedButton, 'Save'));

    final config = await _live(
      tester,
      () => client.getDynamic(
        '/api/v1/platform/master/items/$itemId/versions/$versionId/config',
      ),
    );
    final configMap = config as Map<String, dynamic>;
    expect((configMap['evidenceRules'] as List<dynamic>), isNotEmpty);

    await _tapText(tester, 'Issue fields');
    await _tapText(tester, 'Add item');
    final issueFields = find.byType(TextFormField);
    await tester.enterText(issueFields.at(0), 'ISSUE_TYPE');
    await tester.enterText(issueFields.at(1), 'Issue type');
    await tester.enterText(issueFields.at(2), 'نوع العطل');
    await _selectDropdown(
      tester,
      find.byType(DropdownButtonFormField<String>).at(1),
      optionSetName,
    );
    await _tapButton(tester, find.widgetWithText(ElevatedButton, 'Save'));

    final configured = await _live(
      tester,
      () => client.getDynamic(
        '/api/v1/platform/master/items/$itemId/versions/$versionId/issue-fields',
      ),
    );
    expect((configured as List<dynamic>), isNotEmpty);

    await _tapText(tester, 'Measurement bands');
    await _tapText(tester, 'Add item');
    final bandFields = find.byType(TextFormField);
    await tester.enterText(bandFields.at(0), 'MEASUREMENT');
    await tester.enterText(bandFields.at(1), 'MM');
    await tester.enterText(bandFields.at(2), '0');
    await tester.enterText(bandFields.at(3), '100');
    await tester.enterText(bandFields.at(4), '100');
    await tester.enterText(bandFields.at(5), 'Within spec');
    await tester.enterText(bandFields.at(6), 'ضمن المواصفات');
    await _tapButton(tester, find.widgetWithText(ElevatedButton, 'Save'));
    final bandConfig = await _live(
      tester,
      () => client.getDynamic(
        '/api/v1/platform/master/items/$itemId/versions/$versionId/config',
      ),
    );
    expect(
      ((bandConfig as Map<String, dynamic>)['measurementBands']
          as List<dynamic>),
      isNotEmpty,
    );

    await _tapText(tester, 'Publish item');
    await _tapButton(tester, find.widgetWithText(FilledButton, 'Publish item'));
    final published = await _live(
      tester,
      () => client.getDynamic('/api/v1/platform/master/items/$itemId'),
    );
    final publishedVersion =
        (published as Map<String, dynamic>)['versions'][0]
            as Map<String, dynamic>;
    expect(publishedVersion['status'], 'PUBLISHED');
    await _shot(tester, '04_item_published');

    await _pump(tester, const TemplatesScreen(), client, endpoints);
    await _tapText(tester, 'Create template');
    await _enterByLabel(tester, 'Template code', templateCode);
    await _enterByLabel(tester, 'Template name (English)', 'Live template');
    await _enterByLabel(tester, 'Template name (Arabic)', 'قالب مباشر');
    await _enterByLabel(tester, 'Description (English)', 'Live flow');
    await _enterByLabel(tester, 'Description (Arabic)', 'تدفق مباشر');
    await _tapButton(tester, find.widgetWithText(FilledButton, 'Create'));

    final templates = await _list(
      tester,
      client,
      '/api/v1/platform/master/templates',
    );
    final template = templates.cast<Map<String, dynamic>>().firstWhere(
      (row) => row['code'] == templateCode,
    );
    final templateId = template['id'] as String;

    await _pump(
      tester,
      TemplateBuilderScreen(templateId: templateId),
      client,
      endpoints,
    );
    await _shot(tester, '05_template_builder');
    await _tapButton(tester, find.text(categoryName).last);
    await _tapButton(
      tester,
      find.widgetWithText(OutlinedButton, 'Add item').first,
    );
    await _tapButton(tester, find.textContaining(itemCode).last);
    await _tapButton(tester, find.widgetWithText(FilledButton, 'Save'));
    final grouped = await _live(
      tester,
      () => client.getDynamic('/api/v1/platform/master/templates/$templateId'),
    );
    final groupedCategories =
        (grouped as Map<String, dynamic>)['categories'] as List<dynamic>;
    expect(groupedCategories, isNotEmpty);
    expect(
      (groupedCategories.first as Map<String, dynamic>)['items'],
      isNotEmpty,
    );

    await _tapButton(
      tester,
      find.widgetWithText(FilledButton, 'Publish template'),
    );

    final secondClient = await _live(
      tester,
      () => _login(_secondEmail, _secondPassword!),
    );
    await _pump(
      tester,
      TemplateBuilderScreen(templateId: templateId),
      secondClient,
      endpoints,
    );
    await _tapButton(tester, find.widgetWithText(FilledButton, 'Approve'));

    final approved = await _live(
      tester,
      () => secondClient.getDynamic(
        '/api/v1/platform/master/templates/$templateId',
      ),
    );
    final approvedVersions =
        (approved as Map<String, dynamic>)['versions'] as List<dynamic>;
    expect(
      approvedVersions.cast<Map<String, dynamic>>().any(
        (row) => row['status'] == 'PUBLISHED',
      ),
      isTrue,
    );
    expect(approved['categories'], isNotEmpty);

    final finalItems = await _list(
      tester,
      client,
      '/api/v1/platform/master/items?search=$itemCode',
    );
    expect(finalItems, isNotEmpty);
    final audit = await _list(tester, client, '/api/v1/platform/audit-events');
    expect(audit, isNotEmpty);
    await _shot(tester, '06_template_approved');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
