import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/features/master_library/option_sets_screen.dart';
import 'package:platform_admin_app/src/platform_config_api.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'support/ui_message_fixtures.dart';

// Local test double only. Production screens call the real API client;
// this fake keeps widget tests fast and deterministic.
class _FakeConfigApi extends PlatformConfigApi {
  _FakeConfigApi()
    : _sets = [_seedCondition(), _seedSeverity()],
      super(
        ApiClient(
          config: const ApiConfig(
            baseUrl: 'http://localhost',
            environment: 'test',
          ),
        ),
        const ApiEndpoints(baseUrl: 'http://localhost'),
      );

  List<OptionSet> _sets;
  final List<String> calls = [];
  String? lastReplacement;
  Object? optionSetsError;
  int _nextSet = 10;
  int _nextValue = 10;

  static OptionSet _seedCondition() => const OptionSet(
    id: 'set-1',
    code: 'CONDITION',
    nameEn: 'Overall Condition',
    nameAr: 'الحالة العامة',
    status: 'ACTIVE',
    sortOrder: 1,
    values: [
      OptionValue(
        id: 'value-1',
        code: 'GOOD',
        labelEn: 'Good',
        labelAr: 'جيد',
        status: 'ACTIVE',
        sortOrder: 0,
        metadataJson: '',
      ),
      OptionValue(
        id: 'value-2',
        code: 'WORN',
        labelEn: 'Worn',
        labelAr: 'بال',
        status: 'ACTIVE',
        sortOrder: 1,
        metadataJson: '{"note":"check"}',
      ),
    ],
  );

  static OptionSet _seedSeverity() => const OptionSet(
    id: 'set-2',
    code: 'SEVERITY',
    nameEn: 'Severity Level',
    nameAr: 'مستوى الخطورة',
    status: 'ACTIVE',
    sortOrder: 2,
    values: [
      OptionValue(
        id: 'value-3',
        code: 'LOW',
        labelEn: 'Low',
        labelAr: 'منخفض',
        status: 'ACTIVE',
        sortOrder: 0,
        metadataJson: '',
      ),
    ],
  );

  static OptionSet _copy(OptionSet set) => OptionSet(
    id: set.id,
    code: set.code,
    nameEn: set.nameEn,
    nameAr: set.nameAr,
    status: set.status,
    sortOrder: set.sortOrder,
    values: [
      for (final value in set.values)
        OptionValue(
          id: value.id,
          code: value.code,
          labelEn: value.labelEn,
          labelAr: value.labelAr,
          status: value.status,
          sortOrder: value.sortOrder,
          metadataJson: value.metadataJson,
        ),
    ],
  );

  @override
  Future<List<OptionSet>> optionSets() async {
    if (optionSetsError != null) throw optionSetsError!;
    return _sets.map(_copy).toList(growable: false);
  }

  @override
  Future<OptionSet> createOptionSet(Map<String, dynamic> body) async {
    calls.add('createOptionSet');
    final created = OptionSet(
      id: 'set-${_nextSet++}',
      code: (body['code'] as String? ?? '').trim(),
      nameEn: (body['nameEn'] as String? ?? '').trim(),
      nameAr: (body['nameAr'] as String? ?? '').trim(),
      status: 'ACTIVE',
      sortOrder: (body['sortOrder'] as int? ?? 0),
      values: const [],
    );
    _sets = [..._sets.map(_copy), created];
    return created;
  }

  @override
  Future<OptionSet> updateOptionSet(
    String id,
    Map<String, dynamic> body,
  ) async {
    calls.add('updateOptionSet');
    _sets = [
      for (final set in _sets)
        if (set.id == id)
          OptionSet(
            id: set.id,
            code: set.code,
            nameEn: (body['nameEn'] as String? ?? set.nameEn).trim(),
            nameAr: (body['nameAr'] as String? ?? set.nameAr).trim(),
            status: set.status,
            sortOrder: (body['sortOrder'] as int?) ?? set.sortOrder,
            values: set.values,
          )
        else
          _copy(set),
    ];
    return _copy(_sets.firstWhere((set) => set.id == id));
  }

  @override
  Future<OptionSet> retireOptionSet(String id) async {
    calls.add('retireOptionSet');
    _sets = [
      for (final set in _sets)
        if (set.id == id)
          OptionSet(
            id: set.id,
            code: set.code,
            nameEn: set.nameEn,
            nameAr: set.nameAr,
            status: 'RETIRED',
            sortOrder: set.sortOrder,
            values: set.values,
          )
        else
          _copy(set),
    ];
    return _copy(_sets.firstWhere((set) => set.id == id));
  }

  @override
  Future<OptionValue> addOptionValue(
    String setId,
    Map<String, dynamic> body,
  ) async {
    calls.add('addOptionValue');
    final created = OptionValue(
      id: 'value-${_nextValue++}',
      code: (body['code'] as String? ?? '').trim(),
      labelEn: (body['labelEn'] as String? ?? '').trim(),
      labelAr: (body['labelAr'] as String? ?? '').trim(),
      status: 'ACTIVE',
      sortOrder: (body['sortOrder'] as int? ?? 0),
      metadataJson: (body['metadataJson'] as String? ?? '').trim(),
    );
    _sets = [
      for (final set in _sets)
        if (set.id == setId)
          OptionSet(
            id: set.id,
            code: set.code,
            nameEn: set.nameEn,
            nameAr: set.nameAr,
            status: set.status,
            sortOrder: set.sortOrder,
            values: [...set.values.map(_copyValue), created],
          )
        else
          _copy(set),
    ];
    return created;
  }

  static OptionValue _copyValue(OptionValue value) => OptionValue(
    id: value.id,
    code: value.code,
    labelEn: value.labelEn,
    labelAr: value.labelAr,
    status: value.status,
    sortOrder: value.sortOrder,
    metadataJson: value.metadataJson,
  );

  @override
  Future<OptionValue> updateOptionValue(
    String setId,
    String valueId,
    Map<String, dynamic> body,
  ) async {
    calls.add('updateOptionValue');
    OptionValue? updated;
    _sets = [
      for (final set in _sets)
        if (set.id == setId)
          OptionSet(
            id: set.id,
            code: set.code,
            nameEn: set.nameEn,
            nameAr: set.nameAr,
            status: set.status,
            sortOrder: set.sortOrder,
            values: [
              for (final value in set.values)
                if (value.id == valueId)
                  OptionValue(
                    id: value.id,
                    code: value.code,
                    labelEn: (body['labelEn'] as String? ?? value.labelEn)
                        .trim(),
                    labelAr: (body['labelAr'] as String? ?? value.labelAr)
                        .trim(),
                    status: value.status,
                    sortOrder: (body['sortOrder'] as int?) ?? value.sortOrder,
                    metadataJson:
                        (body['metadataJson'] as String? ?? value.metadataJson)
                            .trim(),
                  )
                else
                  _copyValue(value),
            ],
          )
        else
          _copy(set),
    ];
    for (final set in _sets) {
      for (final value in set.values) {
        if (value.id == valueId) updated = value;
      }
    }
    return updated!;
  }

  @override
  Future<OptionValue> retireOptionValue(
    String setId,
    String valueId, {
    String? replacementCode,
  }) async {
    calls.add('retireOptionValue');
    lastReplacement = replacementCode;
    OptionValue? updated;
    _sets = [
      for (final set in _sets)
        if (set.id == setId)
          OptionSet(
            id: set.id,
            code: set.code,
            nameEn: set.nameEn,
            nameAr: set.nameAr,
            status: set.status,
            sortOrder: set.sortOrder,
            values: [
              for (final value in set.values)
                if (value.id == valueId)
                  OptionValue(
                    id: value.id,
                    code: value.code,
                    labelEn: value.labelEn,
                    labelAr: value.labelAr,
                    status: 'RETIRED',
                    sortOrder: value.sortOrder,
                    metadataJson: value.metadataJson,
                  )
                else
                  _copyValue(value),
            ],
          )
        else
          _copy(set),
    ];
    for (final set in _sets) {
      for (final value in set.values) {
        if (value.id == valueId) updated = value;
      }
    }
    return updated!;
  }

  @override
  Future<List<OptionValue>> reorderOptionValues(
    String setId,
    List<String> ids,
  ) async {
    calls.add('reorderOptionValues');
    List<OptionValue> reordered = const [];
    _sets = [
      for (final set in _sets)
        if (set.id == setId)
          () {
            final byCode = {for (final v in set.values) v.code: v};
            reordered = [
              for (var i = 0; i < ids.length; i++)
                if (byCode.containsKey(ids[i]))
                  OptionValue(
                    id: byCode[ids[i]]!.id,
                    code: byCode[ids[i]]!.code,
                    labelEn: byCode[ids[i]]!.labelEn,
                    labelAr: byCode[ids[i]]!.labelAr,
                    status: byCode[ids[i]]!.status,
                    sortOrder: i,
                    metadataJson: byCode[ids[i]]!.metadataJson,
                  ),
            ];
            return OptionSet(
              id: set.id,
              code: set.code,
              nameEn: set.nameEn,
              nameAr: set.nameAr,
              status: set.status,
              sortOrder: set.sortOrder,
              values: reordered,
            );
          }()
        else
          _copy(set),
    ];
    return reordered;
  }
}

Widget _app(
  _FakeConfigApi api, {
  Locale locale = const Locale('en'),
  Size size = const Size(1280, 900),
  List<Override> extra = const [],
}) {
  return ProviderScope(
    overrides: [uiStringsProvider.overrideWithValue(locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings()), platformConfigApiProvider.overrideWithValue(api), ...extra],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const OptionSetsScreen(),
      ),
    ),
  );
}

Future<void> _pump(
  _FakeConfigApi api,
  WidgetTester tester, {
  Size? size,
}) async {
  await tester.binding.setSurfaceSize(size ?? const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(api, size: size ?? const Size(1280, 900)));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders master list and detail with helper and searches', (
    tester,
  ) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    // Helper text explaining where options are used.
    expect(
      find.text(
        'Option sets define the choices technicians pick when reporting an issue. Values are shared across items.',
      ),
      findsOneWidget,
    );
    // Master list with counts + detail values panel.
    expect(find.byKey(const Key('opt-set-search')), findsOneWidget);
    expect(find.byKey(const Key('opt-value-search')), findsOneWidget);
    expect(find.text('CONDITION'), findsWidgets);
    expect(find.text('SEVERITY'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Worn'), findsOneWidget);
    expect(find.text('Values'), findsWidgets);
    expect(find.textContaining('Edit inline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('set search filters the master list', (tester) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('opt-set-search')), 'sev');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('opt-set-tile-set-2')), findsOneWidget);
    expect(find.byKey(const Key('opt-set-tile-set-1')), findsNothing);
  });

  testWidgets('set search with no match shows empty state with add CTA', (
    tester,
  ) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('opt-set-search')), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No results'), findsOneWidget);
    // CTA opens the in-page editor prefilled with the query.
    await _tap(tester, find.text('Add option set').last);
    expect(find.byKey(const Key('opt-set-editor')), findsOneWidget);
  });

  testWidgets('value search filters the detail values', (tester) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('opt-value-search')), 'worn');
    await tester.pumpAndSettle();

    expect(find.text('Worn'), findsOneWidget);
    expect(find.text('Good'), findsNothing);
  });

  testWidgets('add option set through the in-page editor panel', (
    tester,
  ) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('opt-set-editor')), findsNothing);
    await _tap(tester, find.byKey(const Key('btn-add-option-set')));
    expect(find.byKey(const Key('opt-set-editor')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('opt-set-code')), 'NEWSET');
    await tester.enterText(
      find.byKey(const Key('opt-set-name-en')),
      'New Set EN',
    );
    await tester.enterText(
      find.byKey(const Key('opt-set-name-ar')),
      'مجموعة جديدة',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('opt-set-save')));

    expect(api.calls, contains('createOptionSet'));
    expect(find.byKey(const Key('opt-set-editor')), findsNothing);
    expect(find.text('NEWSET'), findsWidgets);
  });

  testWidgets('edit option set through the in-page editor panel', (
    tester,
  ) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const Key('opt-set-edit')));
    expect(find.byKey(const Key('opt-set-editor')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('opt-set-name-en')),
      'Condition Updated',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('opt-set-save')));

    expect(api.calls, contains('updateOptionSet'));
    expect(find.text('Condition Updated'), findsWidgets);
  });

  testWidgets('add value through the inline row editor', (tester) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('opt-value-code')), 'POOR');
    await tester.enterText(find.byKey(const Key('opt-value-label-en')), 'Poor');
    await tester.enterText(find.byKey(const Key('opt-value-label-ar')), 'سيئ');
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('opt-value-save')));

    expect(api.calls, contains('addOptionValue'));
    expect(find.text('POOR'), findsOneWidget);
    expect(find.text('Poor'), findsOneWidget);
  });

  testWidgets('edit value through the inline row editor', (tester) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const Key('opt-value-edit-value-1')));
    // Save button switches to Save in edit mode with a cancel affordance.
    expect(find.byKey(const Key('opt-value-cancel')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('opt-value-label-en')),
      'Great',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('opt-value-save')));
    await _tap(tester, find.byKey(const Key('opt-value-save')));

    expect(api.calls, contains('updateOptionValue'));
    expect(find.text('Great'), findsOneWidget);
  });

  testWidgets('reorder value with move up/down', (tester) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    // WORN is second; move it up above GOOD.
    await _tap(tester, find.byKey(const Key('opt-value-up-value-2')));

    expect(api.calls, contains('reorderOptionValues'));
    final wornDy = tester.getCenter(find.text('Worn')).dy;
    final goodDy = tester.getCenter(find.text('Good')).dy;
    expect(wornDy, lessThan(goodDy));
  });

  testWidgets('retire value asks for a replacement mapping', (tester) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const Key('opt-value-retire-value-1')));

    // Retire-in-use dialog with replacement field.
    expect(find.byKey(const Key('opt-value-replacement')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('opt-value-replacement')),
      'WORN',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(FilledButton, 'Retire'));

    expect(api.calls, contains('retireOptionValue'));
    expect(api.lastReplacement, 'WORN');
  });

  testWidgets('retire option set through shared confirm dialog', (
    tester,
  ) async {
    final api = _FakeConfigApi();
    await _pump(api, tester);
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const Key('opt-set-retire')));
    await _tap(tester, find.widgetWithText(FilledButton, 'Retire'));

    expect(api.calls, contains('retireOptionSet'));
  });

  testWidgets('loading state uses the shared loading view', (tester) async {
    final api = _FakeConfigApi();
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final loading = Completer<List<OptionSet>>();
    await tester.pumpWidget(
      _app(
        api,
        extra: [optionSetsProvider.overrideWith((ref) => loading.future)],
      ),
    );
    await tester.pump();
    expect(find.text('Loading'), findsOneWidget);
  });

  testWidgets('error state uses the shared error view with retry', (
    tester,
  ) async {
    final api = _FakeConfigApi()
      ..optionSetsError = const AppFailure(code: 'E', messageKey: 'Boom');
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(find.text('Boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Retry refetches through the real provider wiring.
    api.optionSetsError = null;
    await _tap(tester, find.text('Retry'));
    expect(find.text('CONDITION'), findsWidgets);
  });

  testWidgets('renders on compact width without overflow', (tester) async {
    final api = _FakeConfigApi();
    await _pump(api, tester, size: const Size(360, 900));
    await tester.pumpAndSettle();

    expect(find.text('CONDITION'), findsWidgets);
    expect(find.byKey(const Key('opt-set-search')), findsOneWidget);
    expect(find.byKey(const Key('opt-value-editor')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Arabic RTL without overflow', (tester) async {
    final api = _FakeConfigApi();
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [uiStringsProvider.overrideWithValue(fakeArUiStrings()), platformConfigApiProvider.overrideWithValue(api)],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(size: Size(1280, 900)),
            child: OptionSetsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('opt-set-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders compact Arabic without overflow', (tester) async {
    final api = _FakeConfigApi();
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [uiStringsProvider.overrideWithValue(fakeArUiStrings()), platformConfigApiProvider.overrideWithValue(api)],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(size: Size(360, 900)),
            child: OptionSetsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
