import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:l10n/ui_strings.dart';
import 'package:platform_admin_app/src/features/master_library/option_sets_screen.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_router.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

void main() {
  group('OptionSet merged taxonomy parsing', () {
    test('reads setKind, domainKey, codeLocked and valuesCount', () {
      final set = OptionSet.fromJson(<String, dynamic>{
        'id': 'set-1',
        'code': 'JOB_STATUS',
        'name': 'Job Status',
        'status': 'ACTIVE',
        'setKind': 'STATUS',
        'domainKey': 'job-status',
        'codeLocked': true,
        'sortOrder': 1,
        'valuesCount': 9,
      });

      expect(set.kind, OptionSetKind.status);
      expect(set.domainKey, 'job-status');
      expect(set.codeLocked, isTrue);
      expect(set.valuesCount, 9);
      expect(set.isStatusCatalog, isTrue);
      expect(set.isChecklistCatalog, isFalse);
    });

    test('legacy payload without setKind stays an editable checklist set', () {
      final set = OptionSet.fromJson(<String, dynamic>{
        'id': 'set-2',
        'code': 'ISSUE_TYPE',
        'name': 'Issue type',
        'status': 'ACTIVE',
        'sortOrder': 2,
      });

      expect(set.kind, OptionSetKind.checklist);
      expect(set.codeLocked, isFalse);
      expect(set.isChecklistCatalog, isTrue);
    });

    test('value presentation hints come from fields or metadataJson', () {
      final direct = OptionValue.fromJson(<String, dynamic>{
        'id': 'v-1',
        'code': 'OPEN',
        'label': 'Open',
        'status': 'ACTIVE',
        'sortOrder': 0,
        'tone': 'info',
        'icon': 'clock',
      });
      expect(direct.tone, 'info');
      expect(direct.icon, 'clock');

      final metadata = OptionValue.fromJson(<String, dynamic>{
        'id': 'v-2',
        'code': 'CLOSED',
        'label': 'Closed',
        'status': 'ACTIVE',
        'sortOrder': 1,
        'metadataJson': '{"tone":"success","icon":"check"}',
      });
      expect(metadata.tone, 'success');
      expect(metadata.icon, 'check');

      final broken = OptionValue.fromJson(<String, dynamic>{
        'id': 'v-3',
        'code': 'BROKEN',
        'label': 'Broken',
        'status': 'ACTIVE',
        'sortOrder': 2,
        'metadataJson': 'not-json',
      });
      expect(broken.tone, isEmpty);
      expect(broken.icon, isEmpty);
    });
  });

  group('tab filtering', () {
    final issueType = _set(
      code: 'ISSUE_TYPE',
      name: 'Issue type',
      kind: OptionSetKind.checklist,
    );
    final location = _set(
      code: 'LOCATION',
      name: 'Location',
      kind: OptionSetKind.checklist,
      codeLocked: true,
    );
    final jobStatus = _set(
      code: 'JOB_STATUS',
      name: 'Job Status',
      kind: OptionSetKind.status,
      codeLocked: true,
    );
    final role = _set(
      code: 'ROLE',
      name: 'Role',
      kind: OptionSetKind.enumeration,
    );
    final severity = _set(
      code: 'SEVERITY',
      name: 'Severity',
      kind: OptionSetKind.checklist,
      codeLocked: true,
    );
    final sets = <OptionSet>[issueType, location, jobStatus, role, severity];

    test('checklist tab excludes locked and non-checklist sets', () {
      expect(
        optionSetsForTab(sets, OptionSetTab.checklist).map((set) => set.code),
        <String>['ISSUE_TYPE'],
      );
    });

    test('statuses tab is setKind STATUS only', () {
      expect(
        optionSetsForTab(sets, OptionSetTab.statuses).map((set) => set.code),
        <String>['JOB_STATUS'],
      );
    });

    test('enums tab includes ENUM sets and locked backend enum codes', () {
      expect(
        optionSetsForTab(sets, OptionSetTab.enums).map((set) => set.code),
        <String>['ROLE', 'SEVERITY'],
      );
    });

    test('search reaches set identity and value labels', () {
      final withValue = _set(
        code: 'COMPONENT',
        name: 'Component',
        kind: OptionSetKind.checklist,
        values: <OptionValue>[_value('BRAKE_PAD', 'Brake pad')],
      );
      expect(
        searchOptionSets(<OptionSet>[withValue], 'brake').single.code,
        'COMPONENT',
      );
      expect(searchOptionSets(<OptionSet>[withValue], 'missing'), isEmpty);
    });
  });

  group('merged option-sets screen', () {
    testWidgets('checklist tab keeps add, edit and retire', (tester) async {
      final api = _FakeConfigApi(<OptionSet>[
        _set(
          code: 'ISSUE_TYPE',
          name: 'Issue type',
          kind: OptionSetKind.checklist,
          values: <OptionValue>[_value('WORN', 'Worn')],
        ),
        _set(
          code: 'JOB_STATUS',
          name: 'Job Status',
          kind: OptionSetKind.status,
          codeLocked: true,
          values: <OptionValue>[_value('OPEN', 'Open')],
        ),
      ]);

      await _pump(tester, api, OptionSetTab.checklist);

      expect(
        find.byKey(const Key('option-set-row-ISSUE_TYPE')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('option-set-row-JOB_STATUS')), findsNothing);
      expect(find.byKey(const Key('option-value-add')), findsOneWidget);
      expect(find.byKey(const Key('option-value-retire-WORN')), findsOneWidget);
    });

    testWidgets('add value still posts the catalogue body', (tester) async {
      final api = _FakeConfigApi(<OptionSet>[
        _set(
          code: 'ISSUE_TYPE',
          name: 'Issue type',
          kind: OptionSetKind.checklist,
          values: <OptionValue>[_value('WORN', 'Worn')],
        ),
      ]);

      await _pump(tester, api, OptionSetTab.checklist);
      await tester.tap(find.byKey(const Key('option-value-add')));
      await tester.pumpAndSettle();

      await tester.enterText(_field('option-value-code-field'), 'NEW_CODE');
      await tester.enterText(_field('option-value-label-field'), 'New label');
      await tester.tap(find.byKey(const Key('option-value-save')));
      await tester.pumpAndSettle();

      expect(api.addedValues, hasLength(1));
      expect(api.addedValues.single['code'], 'NEW_CODE');
      expect(api.addedValues.single['label'], 'New label');
      expect(api.addedValues.single['sortOrder'], 1);
    });

    testWidgets('locked status set hides add/retire and shows the badge', (
      tester,
    ) async {
      final api = _FakeConfigApi(<OptionSet>[
        _set(
          code: 'JOB_STATUS',
          name: 'Job Status',
          kind: OptionSetKind.status,
          codeLocked: true,
          values: <OptionValue>[
            _value('OPEN', 'Open', tone: 'info', icon: 'clock'),
          ],
        ),
      ]);

      await _pump(tester, api, OptionSetTab.statuses);

      expect(
        find.byKey(const Key('option-set-backend-defined-JOB_STATUS')),
        findsOneWidget,
      );
      expect(find.text('Backend-defined'), findsOneWidget);
      expect(find.byKey(const Key('option-value-add')), findsNothing);
      expect(find.byKey(const Key('option-value-retire-OPEN')), findsNothing);
      expect(find.byKey(const Key('option-value-edit-OPEN')), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('enums tab includes locked severity and hides mutations', (
      tester,
    ) async {
      final api = _FakeConfigApi(<OptionSet>[
        _set(
          code: 'ROLE',
          name: 'Role',
          kind: OptionSetKind.enumeration,
          values: <OptionValue>[_value('ADMIN', 'Admin')],
        ),
        _set(
          code: 'SEVERITY',
          name: 'Severity',
          kind: OptionSetKind.checklist,
          codeLocked: true,
          values: <OptionValue>[_value('HIGH', 'High')],
        ),
        _set(code: 'LOCATION', name: 'Location', kind: OptionSetKind.checklist),
      ]);

      await _pump(tester, api, OptionSetTab.enums);

      expect(find.byKey(const Key('option-set-row-ROLE')), findsOneWidget);
      expect(find.byKey(const Key('option-set-row-SEVERITY')), findsOneWidget);
      expect(find.byKey(const Key('option-set-row-LOCATION')), findsNothing);
      expect(find.byKey(const Key('option-value-add')), findsNothing);
      expect(find.byKey(const Key('option-value-retire-HIGH')), findsNothing);
    });

    testWidgets('compact width renders value actions without overflow', (
      tester,
    ) async {
      final api = _FakeConfigApi(<OptionSet>[
        _set(
          code: 'ISSUE_TYPE',
          name: 'Issue type',
          kind: OptionSetKind.checklist,
          values: <OptionValue>[
            _value('WORN', 'Worn'),
            _value('CRACKED', 'Cracked', order: 1),
          ],
        ),
      ]);

      await _pump(
        tester,
        api,
        OptionSetTab.checklist,
        size: const Size(360, 800),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('option-value-edit-WORN')), findsOneWidget);
    });

    testWidgets('summary-only sets fetch values lazily', (tester) async {
      final api = _FakeConfigApi(
        <OptionSet>[
          _set(
            code: 'JOB_STATUS',
            name: 'Job Status',
            kind: OptionSetKind.status,
            codeLocked: true,
            valuesCount: 2,
          ),
        ],
        valuesBySet: <String, List<OptionValue>>{
          'id-JOB_STATUS': <OptionValue>[
            _value('OPEN', 'Open'),
            _value('CLOSED', 'Closed', order: 1),
          ],
        },
      );

      await _pump(tester, api, OptionSetTab.statuses);
      await tester.pumpAndSettle();

      expect(api.fetchedValueSets, contains('id-JOB_STATUS'));
      expect(find.byKey(const Key('option-value-row-OPEN')), findsOneWidget);
      expect(find.byKey(const Key('option-value-row-CLOSED')), findsOneWidget);
    });

    testWidgets('catalog-managed labels are read-only with a helper', (
      tester,
    ) async {
      final api = _FakeConfigApi(<OptionSet>[
        _set(
          code: 'ISSUE_TYPE',
          name: 'Issue type',
          kind: OptionSetKind.checklist,
          values: <OptionValue>[
            _value('WORN', 'Worn', labelKey: 'optionSets.codeImmutable'),
          ],
        ),
      ]);

      await _pump(tester, api, OptionSetTab.checklist);
      await tester.tap(find.byKey(const Key('option-value-edit-WORN')));
      await tester.pumpAndSettle();

      expect(
        find.text('Label is managed by the language catalog.'),
        findsOneWidget,
      );
      final field = tester.widget<TextFormField>(
        _field('option-value-label-field'),
      );
      expect(field.enabled, isFalse);
    });

    testWidgets('unresolved label keys stay editable', (tester) async {
      final api = _FakeConfigApi(<OptionSet>[
        _set(
          code: 'ISSUE_TYPE',
          name: 'Issue type',
          kind: OptionSetKind.checklist,
          values: <OptionValue>[
            _value('WORN', 'Worn', labelKey: 'optionSets.notServedYet'),
          ],
        ),
      ]);

      await _pump(tester, api, OptionSetTab.checklist);
      await tester.tap(find.byKey(const Key('option-value-edit-WORN')));
      await tester.pumpAndSettle();

      expect(
        find.text('Label is managed by the language catalog.'),
        findsNothing,
      );
      final field = tester.widget<TextFormField>(
        _field('option-value-label-field'),
      );
      expect(field.enabled, isTrue);
    });
  });

  group('legacy taxonomy redirects', () {
    test('statuses routes open the statuses tab', () {
      expect(
        configurationOptionSetsRedirect(Uri.parse('/configuration/statuses')),
        '/checklist/option-sets?tab=statuses',
      );
      expect(
        configurationOptionSetsRedirect(Uri.parse('/configuration')),
        '/checklist/option-sets?tab=statuses',
      );
    });

    test('enums and dropdowns routes open the enums tab', () {
      expect(
        configurationOptionSetsRedirect(Uri.parse('/configuration/enums')),
        '/checklist/option-sets?tab=enums',
      );
      expect(
        configurationOptionSetsRedirect(Uri.parse('/configuration/dropdowns')),
        '/checklist/option-sets?tab=enums',
      );
    });

    test('the transitions editor is not redirected', () {
      expect(
        configurationOptionSetsRedirect(
          Uri.parse('/configuration/transitions'),
        ),
        isNull,
      );
    });
  });
}

Finder _field(String key) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.byType(TextFormField),
);

OptionSet _set({
  required String code,
  required String name,
  required OptionSetKind kind,
  bool codeLocked = false,
  List<OptionValue> values = const <OptionValue>[],
  int valuesCount = 0,
}) => OptionSet(
  id: 'id-$code',
  code: code,
  name: name,
  status: 'ACTIVE',
  sortOrder: 0,
  values: values,
  kind: kind,
  codeLocked: codeLocked,
  valuesCount: valuesCount,
);

OptionValue _value(
  String code,
  String label, {
  int order = 0,
  String tone = '',
  String icon = '',
  String? labelKey,
}) => OptionValue(
  id: 'value-$code',
  code: code,
  label: label,
  status: 'ACTIVE',
  sortOrder: order,
  metadataJson: '{}',
  labelKey: labelKey,
  tone: tone,
  icon: icon,
);

Future<void> _pump(
  WidgetTester tester,
  _FakeConfigApi api,
  OptionSetTab tab, {
  Size size = const Size(1280, 1800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final catalogs = loadReferenceStrings().catalogs['en']!;
  final bundle = <String, String>{
    ...catalogs['common']!,
    ...catalogs['platform_admin']!,
  };
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        uiStringsProvider.overrideWithValue(loadReferenceStrings()),
        platformConfigApiProvider.overrideWithValue(api),
        statusesProvider('checklist')
            .overrideWith((ref) async => const <ReferenceRecord>[]),
      ],
      child: MaterialApp(
        home: UiStringsScope(
          strings: UiStrings.fromMessages(bundle),
          child: Scaffold(
            body: OptionSetsScreen(embedded: true, initialTab: tab.slug),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeConfigApi extends PlatformConfigApi {
  _FakeConfigApi(
    this.sets, {
    this.valuesBySet = const <String, List<OptionValue>>{},
  }) : super(
         ApiClient(
           config: const ApiConfig(
             baseUrl: 'http://localhost',
             environment: 'test',
           ),
         ),
         const ApiEndpoints(baseUrl: 'http://localhost'),
       );

  final List<OptionSet> sets;
  final Map<String, List<OptionValue>> valuesBySet;
  final List<Map<String, dynamic>> addedValues = <Map<String, dynamic>>[];
  final List<String> fetchedValueSets = <String>[];

  @override
  Future<List<OptionSet>> optionSets() async => sets;

  @override
  Future<List<OptionValue>> optionSetValues(String id) async {
    fetchedValueSets.add(id);
    return valuesBySet[id] ?? const <OptionValue>[];
  }

  @override
  Future<OptionValue> addOptionValue(
    String setId,
    Map<String, dynamic> body,
  ) async {
    addedValues.add(body);
    return OptionValue(
      id: 'created',
      code: '${body['code']}',
      label: '${body['label']}',
      status: 'ACTIVE',
      sortOrder: body['sortOrder'] as int? ?? 0,
      metadataJson: '{}',
    );
  }
}
