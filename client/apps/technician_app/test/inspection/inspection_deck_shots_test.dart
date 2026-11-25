/// Real-font screenshot evidence for the detail deck (round 1).
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/inspection/inspection_deck.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/technician_providers.dart';

import '../support/fixtures.dart' as fixtures;

const Map<String, String> _bundle = <String, String>{
  'technicianChecklistOrder': 'IN ORDER OF THE CHECKLIST',
  'technicianQueueItems': '{done} of {total} items',
  'technicianDeckSummaryAction': 'Summary',
  'technicianSyncPending': 'Pending sync',
  'technicianSyncOffline': 'Offline',
  'technicianNoCategories': 'This checklist has no categories.',
  'technicianNoItems': 'No items in this category.',
  'technicianStartHint': 'Start the inspection when confirmed.',
  'startInspection': 'Start inspection',
  'technicianQueueActionContinue': 'Continue',
  'technicianQueueActionFinish': 'Finish',
  'technicianSessionItemOf': 'Item {number} of {total}',
  'notChecked': 'Not checked',
  'technicianSafetyCritical': 'Safety critical',
};

Assessment _answer(String itemCode, String itemVersionId) => Assessment(
  id: null,
  itemCode: itemCode,
  itemVersionId: itemVersionId,
  resultCode: 'NO_ISSUE_OBSERVED',
  severityCode: null,
  score: null,
  suggestedResultCode: null,
  suggestedScore: null,
  bandResultCode: null,
  state: null,
  clientRevision: 1,
  serverRevision: 1,
  notesEn: null,
  notesAr: null,
  reasonCode: null,
  version: 1,
  issueValues: const [],
  measurements: const [],
  evidence: const [],
);

ChecklistItem _withAssessment(ChecklistItem item) => ChecklistItem(
  itemCode: item.itemCode,
  itemVersionId: item.itemVersionId,
  categoryCode: item.categoryCode,
  sortOrder: item.sortOrder,
  labelEn: item.labelEn,
  labelAr: item.labelAr,
  instructionEn: item.instructionEn,
  instructionAr: item.instructionAr,
  standardSpecEn: item.standardSpecEn,
  standardSpecAr: item.standardSpecAr,
  measurementUnit: item.measurementUnit,
  sensorTool: item.sensorTool,
  safetyCritical: item.safetyCritical,
  multiPoint: item.multiPoint,
  multiPointIndexes: item.multiPointIndexes,
  allowFreeTextNote: item.allowFreeTextNote,
  noteRequirement: item.noteRequirement,
  resultOptions: item.resultOptions,
  scoreBands: item.scoreBands,
  evidenceRules: item.evidenceRules,
  issueFields: item.issueFields,
  measurementBands: item.measurementBands,
  assessment: _answer(item.itemCode, item.itemVersionId),
);

Checklist _checklist({required int answered, String status = 'SCHEDULED'}) {
  final base = fixtures.checklist(job: fixtures.jobSummary(status: status));
  final items = <ChecklistItem>[
    for (var index = 0; index < base.items.length; index++)
      index < answered ? _withAssessment(base.items[index]) : base.items[index],
  ];
  return Checklist(
    job: base.job,
    pinned: base.pinned,
    categories: base.categories,
    items: items,
    progress: ChecklistProgress(completed: answered, total: items.length),
    serverRevision: base.serverRevision,
  );
}

Widget _deck(Checklist checklist, {String? selectedCategory}) {
  return InspectionDeck(
    checklist: checklist,
    jobId: checklist.job.id,
    selectedCategory: selectedCategory,
    focusedItemCode: null,
    onCategory: (_) {},
    onFocus: (_) {},
    onOpen: (_) {},
    onSummary: () {},
    onBack: () {},
  );
}

Future<void> _shot(
  WidgetTester tester,
  String name,
  Widget child, {
  required double width,
  required double height,
  Locale locale = const Locale('en'),
  TextScaler scaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        enumsProvider('result')
            .overrideWith((ref) async => <ReferenceRecord>[]),
        statusesProvider('job')
            .overrideWith((ref) async => <ReferenceRecord>[]),
        pendingOperationsProvider.overrideWith(
          (ref) async => const <SyncOperation>[],
        ),
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: scaler, disableAnimations: true),
              child: Directionality(
                textDirection: locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerLow,
                  body: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/$name.png'),
  );
}

Widget _sized(Widget child, double height) =>
    SizedBox(height: height, child: child);

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  testWidgets('detail_390_data', (tester) async {
    await _shot(
      tester,
      'detail_390_data',
      _sized(_deck(_checklist(answered: 9)), 844),
      width: 390,
      height: 844,
    );
  });

  testWidgets('detail_768_data', (tester) async {
    await _shot(
      tester,
      'detail_768_data',
      _sized(_deck(_checklist(answered: 9)), 1024),
      width: 768,
      height: 1024,
    );
  });

  testWidgets('detail_1024_data', (tester) async {
    await _shot(
      tester,
      'detail_1024_data',
      _sized(_deck(_checklist(answered: 9)), 768),
      width: 1024,
      height: 768,
    );
  });

  testWidgets('detail_390_rtl', (tester) async {
    await _shot(
      tester,
      'detail_390_rtl',
      _sized(_deck(_checklist(answered: 9)), 844),
      width: 390,
      height: 844,
      locale: const Locale('ar'),
    );
  });

  testWidgets('detail_390_read_only', (tester) async {
    await _shot(
      tester,
      'detail_390_read_only',
      _sized(_deck(_checklist(answered: 30, status: 'PENDING_REVIEW')), 844),
      width: 390,
      height: 844,
    );
  });

  testWidgets('detail_390_section_empty', (tester) async {
    const empty = Category(
      code: 'empty',
      nameEn: 'Empty section',
      nameAr: 'قسم فارغ',
      iconCode: null,
      sortOrder: 99,
    );
    final base = fixtures.checklist();
    final checklist = Checklist(
      job: base.job,
      pinned: base.pinned,
      categories: [...base.categories, empty],
      items: base.items,
      progress: base.progress,
      serverRevision: base.serverRevision,
    );
    await _shot(
      tester,
      'detail_390_section_empty',
      _sized(_deck(checklist, selectedCategory: 'empty'), 844),
      width: 390,
      height: 844,
    );
  });

  testWidgets('detail_390_all_answered', (tester) async {
    await _shot(
      tester,
      'detail_390_all_answered',
      _sized(_deck(_checklist(answered: 30)), 844),
      width: 390,
      height: 844,
    );
  });

  testWidgets('detail_390_15x', (tester) async {
    await _shot(
      tester,
      'detail_390_15x',
      _sized(_deck(_checklist(answered: 9)), 844),
      width: 390,
      height: 844,
      scaler: const TextScaler.linear(1.5),
    );
  });
}
