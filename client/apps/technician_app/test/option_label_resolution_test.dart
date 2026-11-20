import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/option_labels.dart';
import 'package:technician_app/src/features/inspection/technician_dynamic_item_page.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import 'support/test_offline_store.dart';
import 'support/test_reference_overrides.dart';
import 'support/ui_strings_harness.dart';

const _jobId = 'job-1';
const _itemCode = 'BRK-01';

/// Option labels come from the backend key first, the served label second.
void main() {
  group('IssueOption parsing', () {
    test('labelKey is optional and tolerated', () {
      final withKey = IssueOption.fromJson(<String, dynamic>{
        'code': 'WORN',
        'labelEn': 'Worn',
        'labelAr': '',
        'labelKey': 'option.issueType.worn',
        'sortOrder': 0,
      });
      expect(withKey.labelKey, 'option.issueType.worn');

      final withoutKey = IssueOption.fromJson(<String, dynamic>{
        'code': 'LOOSE',
        'labelEn': 'Loose',
        'labelAr': '',
        'sortOrder': 1,
      });
      expect(withoutKey.labelKey, isNull);
      expect(withoutKey.toJson()['labelKey'], isNull);
    });

    test('helper falls back to the served label when the key is absent', () {
      final option = IssueOption.fromJson(<String, dynamic>{
        'code': 'LOOSE',
        'labelEn': 'Loose',
        'labelAr': '',
        'sortOrder': 0,
      });
      expect(
        issueOptionLabel(UiStrings.fromMessages(const {}), option, 'en'),
        'Loose',
      );
    });
  });

  testWidgets('chip renders the bundle translation, the served label and the '
      'keyless fallback', (tester) async {
    // Backend English minus one key, plus one translated override.
    final bundle = <String, String>{
      ...remoteEnglishValues,
      'option.issueType.worn': 'Desgastado',
    }..remove('option.issueType.cracked');

    await _pumpItem(tester, UiStrings.fromMessages(bundle));

    await tester.scrollUntilVisible(
      find.text('Desgastado'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Desgastado'), findsOneWidget);
    expect(find.text('Cracked'), findsOneWidget);
    expect(find.text('Loose'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpItem(WidgetTester tester, UiStrings strings) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final store = createTestOfflineStore();
  addTearDown(store.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testReferenceStatusOverrides(),
        offlineStoreProvider.overrideWithValue(store),
        technicianChecklistProvider(_jobId)
            .overrideWith((ref) async => _checklist()),
        technicianEvidenceListProvider((jobId: _jobId, itemCode: _itemCode))
            .overrideWith((ref) async => const <Evidence>[]),
        connectivityProvider.overrideWith((ref) => Stream<bool>.value(true)),
      ],
      retry: (_, _) => null,
      child: MaterialApp(
        theme: AppTheme.light,
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) => UiStringsScope(
          strings: strings,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const TechnicianItemPage(jobId: _jobId, itemCode: _itemCode),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Map<String, dynamic> _option(
  String code,
  String labelEn, {
  String? labelKey,
  required int sortOrder,
}) => <String, dynamic>{
  'code': code,
  'labelEn': labelEn,
  'labelAr': '',
  'labelKey': ?labelKey,
  'sortOrder': sortOrder,
};

Checklist _checklist() => Checklist.fromJson(<String, dynamic>{
  'job': {
    'id': _jobId,
    'reference': 'JOB-7F3A21',
    'status': 'IN_PROGRESS',
    'customerName': 'Layla Hassan',
    'vehicleMake': 'Toyota',
    'vehicleModel': 'Hilux',
    'vehiclePlate': 'A 12345',
    'completedItems': 0,
    'totalItems': 1,
    'version': 1,
  },
  'categories': [
    {
      'code': 'BRAKES',
      'nameEn': 'Brakes',
      'nameAr': '',
      'iconCode': 'BRAKES',
      'sortOrder': 0,
    },
  ],
  'items': [
    {
      'itemCode': _itemCode,
      'itemVersionId': 'item-version-1',
      'categoryCode': 'BRAKES',
      'sortOrder': 0,
      'labelEn': 'Front brake pads',
      'labelAr': '',
      'instructionEn': 'Inspect the pads.',
      'resultOptions': ['NO_ISSUE_OBSERVED', 'DEFECT_FOUND'],
      'issueFields': [
        {
          'fieldCode': 'ISSUE_TYPE',
          'labelEn': 'Issue type',
          'labelAr': '',
          'inputType': 'SELECT',
          'optionSetCode': 'ISSUE_TYPE',
          'options': [
            _option(
              'WORN',
              'Worn',
              labelKey: 'option.issueType.worn',
              sortOrder: 0,
            ),
            _option(
              'CRACKED',
              'Cracked',
              labelKey: 'option.issueType.cracked',
              sortOrder: 1,
            ),
            _option('LOOSE', 'Loose', sortOrder: 2),
          ],
          'allowedOptionCodes': <String>[],
          'required': false,
          'requiredForStatuses': <String>[],
          'allowMultiple': false,
          'allowFreeText': false,
          'sortOrder': 0,
        },
      ],
      'assessment': null,
    },
  ],
  'progress': {'completed': 0, 'total': 1},
  'serverRevision': 4,
});
