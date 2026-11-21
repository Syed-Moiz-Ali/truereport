// Proves the master-library surfaces read their options from reference data.
//
// The item editor's result/input/evidence/direction pickers and the
// master-library status filter must follow whatever the served taxonomy
// contains, including a value added after the app shipped. These tests use
// fake providers and never touch the network.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/components/platform_form.dart';
import 'package:platform_admin_app/src/features/master_library/master_item_editor_screen.dart';
import 'package:platform_admin_app/src/features/master_library/master_library_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

/// The live result taxonomy plus the V135 `selectable=false` markers and one
/// brand-new assessment code. A served value must reach the editor without a
/// client release.
final List<ReferenceRecord> _resultEnums = <ReferenceRecord>[
  record('NO_ISSUE_OBSERVED', labelKey: 'noIssueObserved', order: 1),
  record('ATTENTION_RECOMMENDED', labelKey: 'attentionRecommended', order: 2),
  record('DEFECT_FOUND', labelKey: 'defectFound', order: 3),
  record('NOT_CHECKED', labelKey: 'notChecked', order: 4, selectable: false),
  record(
    'NOT_APPLICABLE',
    labelKey: 'notApplicable',
    order: 5,
    selectable: false,
  ),
  record(
    'COULD_NOT_VERIFY',
    labelKey: 'couldNotVerify',
    order: 6,
    selectable: false,
  ),
  record('TIRE_CRACK_DETECTED', labelKey: 'tyreCrackDetected', order: 7),
];

const List<String> _selectableResultCodes = <String>[
  'NO_ISSUE_OBSERVED',
  'ATTENTION_RECOMMENDED',
  'DEFECT_FOUND',
  'TIRE_CRACK_DETECTED',
];

PlatformItemDetail _detail() => const PlatformItemDetail(
  item: PlatformItem(
    id: 'item-1',
    code: 'BRAKE_PAD',
    categoryId: 'cat-1',
    categoryLabelEn: 'Brakes',
    status: 'PUBLISHED',
    currentVersion: 1,
    sampleData: false,
    updatedAt: '2026-01-01T00:00:00Z',
    measurementUnit: 'mm',
    sensorTool: '',
    safetyCritical: true,
    multiPoint: false,
    maxTyreAgeYears: null,
    allowFreeTextNote: false,
    sortOrder: 0,
    guideImageId: '',
    label: 'Brake pad',
  ),
  versions: <PlatformItemVersion>[
    PlatformItemVersion(
      id: 'version-2',
      versionNo: 2,
      status: 'DRAFT',
      resultOptions: <String>[],
      noteRequirement: 'OPTIONAL',
      evidenceRequirement: 'REQUIRED_MIN_N',
      minPhotos: 1,
      publishedAt: '',
      label: 'Brake pad',
    ),
  ],
);

ItemConfig _config({List<EvidenceRule> evidenceRules = const []}) => ItemConfig(
  metadata: const ItemMetadata(
    itemId: 'item-1',
    measurementUnit: 'mm',
    sensorTool: '',
    safetyCritical: true,
    multiPoint: false,
    maxTyreAgeYears: null,
    allowFreeTextNote: false,
    sortOrder: 0,
    guideImageId: '',
  ),
  evidenceRules: evidenceRules,
  issueFields: const <IssueField>[],
  measurementBands: const <MeasurementBand>[],
);

List<Override> _editorOverrides({
  List<EvidenceRule> evidenceRules = const [],
  List<ReferenceRecord>? results,
  Future<List<ReferenceRecord>>? pendingResults,
}) {
  final detail = _detail();
  final config = _config(evidenceRules: evidenceRules);
  return <Override>[
    uiStringsProvider.overrideWithValue(loadReferenceStrings()),
    itemDetailProvider.overrideWith((ref, id) async => detail),
    itemConfigProvider.overrideWith((ref, key) async => config),
    optionSetsProvider.overrideWith((ref) async => const <OptionSet>[]),
    if (pendingResults != null)
      enumsProvider('result').overrideWith((ref) => pendingResults)
    else
      enumsProvider('result')
          .overrideWith((ref) async => results ?? _resultEnums),
    enumsProvider('evidence-type').overrideWith(
      (ref) async => <ReferenceRecord>[
        record('PHOTO', labelKey: 'attachments', order: 1),
        record('VIDEO', labelKey: 'technicianVideo', order: 2),
        record('DOCUMENT', labelKey: 'technicianDocument', order: 3),
      ],
    ),
    enumsProvider('input-type').overrideWith(
      (ref) async => <ReferenceRecord>[
        record('SELECT', labelKey: 'label.inputType.select', order: 1),
        record(
          'MULTI_SELECT',
          labelKey: 'label.inputType.multiSelect',
          order: 2,
        ),
        record('NUMBER', labelKey: 'label.inputType.number', order: 3),
        record('BOOLEAN', labelKey: 'label.inputType.boolean', order: 4),
        record('TEXT', labelKey: 'label.inputType.text', order: 5),
      ],
    ),
    enumsProvider('measurement-direction').overrideWith(
      (ref) async => <ReferenceRecord>[
        record(
          'HIGHER_IS_BETTER',
          labelKey: 'label.measureDirection.higherIsBetter',
          order: 1,
        ),
        record(
          'LOWER_IS_BETTER',
          labelKey: 'label.measureDirection.lowerIsBetter',
          order: 2,
        ),
      ],
    ),
    statusesProvider('checklist')
        .overrideWith((ref) async => const <ReferenceRecord>[]),
  ];
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  List<EvidenceRule> evidenceRules = const [],
  List<ReferenceRecord>? results,
  Future<List<ReferenceRecord>>? pendingResults,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(880, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: _editorOverrides(
        evidenceRules: evidenceRules,
        results: results,
        pendingResults: pendingResults,
      ),
      child: const MaterialApp(
        home: MasterItemEditorScreen(itemId: 'item-1', initialStep: 3),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

PlatformDropdown<String> _resultDropdown(WidgetTester tester, int index) =>
    tester.widget<PlatformDropdown<String>>(
      find.byKey(Key('evidence-rule-result-$index')),
    );

void main() {
  group('item editor pickers follow the served enum', () {
    testWidgets(
      'default evidence rules use only selectable results, in order',
      (tester) async {
        await _pumpEditor(tester);

        for (var index = 0; index < _selectableResultCodes.length; index++) {
          expect(
            find.byKey(Key('evidence-rule-result-$index')),
            findsOneWidget,
            reason: 'one default rule per selectable result',
          );
        }
        expect(
          find.byKey(const Key('evidence-rule-result-4')),
          findsNothing,
          reason: 'report-only results get no default rule',
        );

        final first = _resultDropdown(tester, 0);
        expect(first.value, 'NO_ISSUE_OBSERVED');
        expect(
          first.items.map((item) => item.value).toList(),
          _selectableResultCodes,
          reason: 'served order, selectable only, new value included',
        );

        final labels = first.items
            .map((item) => (item.child as Text).data)
            .toList(growable: false);
        expect(labels, contains('Tire Crack Detected'));
        expect(labels, isNot(contains('Could Not Verify')));
      },
    );

    testWidgets('a stored non-selectable result code stays visible', (
      tester,
    ) async {
      await _pumpEditor(
        tester,
        evidenceRules: const <EvidenceRule>[
          EvidenceRule(
            resultCode: 'COULD_NOT_VERIFY',
            minPhotos: 0,
            minVideos: 0,
            minNotesChars: 0,
            requiredEvidenceType: '',
          ),
        ],
      );

      final dropdown = _resultDropdown(tester, 0);
      expect(dropdown.value, 'COULD_NOT_VERIFY');
      expect(
        dropdown.items.map((item) => item.value),
        contains('COULD_NOT_VERIFY'),
        reason: 'opening the editor must not rewrite the stored code',
      );
      expect(
        dropdown.items.map((item) => (item.child as Text).data),
        contains('Could Not Verify'),
      );
    });

    testWidgets(
      'an empty served enum keeps the stored code and does not crash',
      (tester) async {
        await _pumpEditor(
          tester,
          results: const <ReferenceRecord>[],
          evidenceRules: const <EvidenceRule>[
            EvidenceRule(
              resultCode: 'LEGACY_RESULT',
              minPhotos: 0,
              minVideos: 0,
              minNotesChars: 0,
              requiredEvidenceType: '',
            ),
          ],
        );

        expect(tester.takeException(), isNull);
        final dropdown = _resultDropdown(tester, 0);
        expect(dropdown.value, 'LEGACY_RESULT');
        expect(dropdown.items.map((item) => item.value), ['LEGACY_RESULT']);
        expect(
          find.byKey(const Key('evidence-rule-result-1')),
          findsNothing,
          reason: 'no defaults are invented without a served enum',
        );
      },
    );

    testWidgets(
      'defaults seed when the served enum arrives after first frame',
      (tester) async {
        final pending = Completer<List<ReferenceRecord>>();
        await _pumpEditor(
          tester,
          pendingResults: pending.future,
          settle: false,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('evidence-rule-result-0')), findsNothing);

        pending.complete(_resultEnums);
        await tester.pumpAndSettle();

        expect(
          _resultDropdown(tester, 0).items.map((item) => item.value),
          _selectableResultCodes,
        );
        expect(find.byKey(const Key('evidence-rule-result-3')), findsOneWidget);
      },
    );
  });

  group('master library status filter', () {
    testWidgets('labels resolve from the API and stay item-lifecycle only', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            uiStringsProvider.overrideWithValue(loadReferenceStrings()),
            categoriesProvider.overrideWith(
              (ref) async => const <PlatformCategory>[],
            ),
            itemsProvider.overrideWith(
              (ref, query) async => const <PlatformItem>[],
            ),
            configHealthProvider.overrideWith(
              (ref) async =>
                  const ConfigHealth(healthy: true, checks: <HealthCheck>[]),
            ),
            statusesProvider('checklist').overrideWith(
              (ref) async => <ReferenceRecord>[
                // Distinct served label on PUBLISHED proves the pill text is
                // not a local map.
                record(
                  'PUBLISHED',
                  labelKey: 'checklist.status.review',
                  order: 3,
                ),
                record('DRAFT', labelKey: 'checklist.status.draft', order: 2),
                record(
                  'RETIRED',
                  labelKey: 'checklist.status.retired',
                  order: 4,
                ),
                // A served status that is not an item lifecycle state must not
                // become a filter.
                record(
                  'REVIEW',
                  labelKey: 'checklist.status.published',
                  order: 1,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MasterLibraryScreen(embedded: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget, reason: 'served label');
      expect(find.text('Retired'), findsOneWidget);
      expect(
        find.text('Published'),
        findsNothing,
        reason: 'REVIEW is served but is not an item lifecycle filter',
      );
    });
  });
}
