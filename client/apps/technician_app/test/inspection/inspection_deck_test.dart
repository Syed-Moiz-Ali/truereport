/// Widget contract for the detail deck: header, ticks, pills, rows, footer.
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

/// A checklist with the first [answered] items (global order) assessed.
Checklist _checklist({
  required int answered,
  String status = 'SCHEDULED',
  List<Category>? categories,
  List<ChecklistItem>? items,
}) {
  final base = fixtures.checklist(job: fixtures.jobSummary(status: status));
  final all = items ?? base.items;
  final assessed = <ChecklistItem>[
    for (var index = 0; index < all.length; index++)
      index < answered ? _withAssessment(all[index]) : all[index],
  ];
  return Checklist(
    job: base.job,
    pinned: base.pinned,
    categories: categories ?? base.categories,
    items: assessed,
    progress: ChecklistProgress(completed: answered, total: assessed.length),
    serverRevision: base.serverRevision,
  );
}

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

ProviderScope _scope({
  required Widget child,
  List<SyncOperation> pending = const [],
  bool online = true,
}) {
  return ProviderScope(
    overrides: [
      enumsProvider('result').overrideWith((ref) async => <ReferenceRecord>[]),
      statusesProvider('job').overrideWith((ref) async => <ReferenceRecord>[]),
      pendingOperationsProvider.overrideWith((ref) async => pending),
      connectivityProvider.overrideWith((ref) => Stream.value(online)),
    ],
    child: child,
  );
}

Widget _host(Widget child, {double width = 390}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      backgroundColor: AppTheme.light.colorScheme.surfaceContainerLow,
      body: Center(
        child: SizedBox(width: width, height: 844, child: child),
      ),
    ),
  );
}

InspectionDeck _deck(
  Checklist checklist, {
  String? selectedCategory,
  ValueChanged<String>? onCategory,
  ValueChanged<ChecklistItem>? onFocus,
  ValueChanged<ChecklistItem>? onOpen,
  VoidCallback? onSummary,
}) {
  return InspectionDeck(
    checklist: checklist,
    jobId: checklist.job.id,
    selectedCategory: selectedCategory,
    focusedItemCode: null,
    onCategory: onCategory ?? (_) {},
    onFocus: onFocus ?? (_) {},
    onOpen: onOpen ?? (_) {},
    onSummary: onSummary ?? () {},
    onBack: () {},
  );
}

void main() {
  setUpAll(() => setRemoteEnglish(_bundle));

  group('header', () {
    testWidgets('shows vehicle, plate, reference, status and time', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scope(child: _host(_deck(_checklist(answered: 0)))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Toyota Land Cruiser 2023'), findsOneWidget);
      expect(find.text('AUD-354626'), findsOneWidget);
      expect(find.text('TR-2026-0412'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget);
    });

    testWidgets('shows the pending chip when operations wait', (tester) async {
      final op = SyncOperation(
        id: 'op-1',
        jobId: 'job-1001',
        type: 'assessment',
        payload: const {},
        state: 'PENDING',
        attempts: 0,
        lastError: null,
        createdAt: DateTime.utc(2026, 3, 12),
      );
      await tester.pumpWidget(
        _scope(pending: [op], child: _host(_deck(_checklist(answered: 0)))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending sync'), findsOneWidget);
    });
  });

  group('resume selection', () {
    testWidgets('opens on the category of the first unanswered item', (
      tester,
    ) async {
      // The five `ac` items are answered; the first gap is in `brakes`.
      await tester.pumpWidget(
        _scope(child: _host(_deck(_checklist(answered: 5)))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Front brake pads'), findsOneWidget);
      expect(find.text('AC cooling performance'), findsNothing);
    });

    testWidgets('an explicit selection wins over the resume default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(_checklist(answered: 5), selectedCategory: 'tyres'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Front tyre tread depth'), findsOneWidget);
      expect(find.text('Front brake pads'), findsNothing);
    });

    testWidgets('a pill tap reports its category', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(
              _checklist(answered: 0),
              onCategory: (code) => selected = code,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Brakes'));
      expect(selected, 'brakes');
    });
  });

  group('ticks', () {
    testWidgets('one tick per item; a tick jumps to its category', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(
              _checklist(answered: 5),
              onCategory: (code) => selected = code,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Item 6 of 30 is the first gap; its tick jumps to `brakes`.
      await tester.tap(
        find.bySemanticsLabel('Item 6 of 30 · Not checked · Safety critical'),
      );
      await tester.pumpAndSettle();
      expect(selected, 'brakes');
    });
  });

  group('rows', () {
    testWidgets('answered rows carry the served result chip', (tester) async {
      await tester.pumpWidget(
        _scope(
          child: _host(_deck(_checklist(answered: 5), selectedCategory: 'ac')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Issue Observed'), findsWidgets);
      // Unanswered rows carry no result chip at all.
      expect(find.text('Not checked'), findsNothing);
    });

    testWidgets('safety-critical rows carry the inline pill', (tester) async {
      await tester.pumpWidget(
        _scope(child: _host(_deck(_checklist(answered: 5)))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safety critical'), findsWidgets);
      final label = tester.widget<Text>(find.text('Front brake pads'));
      expect(label.maxLines, 2);
      expect(label.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('a row tap reports focus then open', (tester) async {
      final events = <String>[];
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(
              _checklist(answered: 5),
              onFocus: (item) => events.add('focus:${item.itemCode}'),
              onOpen: (item) => events.add('open:${item.itemCode}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Front brake pads'));
      await tester.pumpAndSettle();
      expect(events, ['focus:brake_pads_front', 'open:brake_pads_front']);
    });

    testWidgets('read-only rows are not tappable', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(
              _checklist(answered: 30, status: 'PENDING_REVIEW'),
              selectedCategory: 'brakes',
              onOpen: (_) => opened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Front brake pads'));
      await tester.pumpAndSettle();
      expect(opened, isFalse);
    });
  });

  group('footer', () {
    testWidgets('starts the first item when nothing is answered', (
      tester,
    ) async {
      ChecklistItem? opened;
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(_checklist(answered: 0), onOpen: (item) => opened = item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start inspection'), findsOneWidget);
      await tester.tap(find.text('Start inspection'));
      await tester.pumpAndSettle();
      expect(opened?.itemCode, 'ac_cooling');
    });

    testWidgets('continues at the first gap once started', (tester) async {
      ChecklistItem? opened;
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(_checklist(answered: 5), onOpen: (item) => opened = item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(opened?.itemCode, 'brake_pads_front');
    });

    testWidgets('all answered finishes to the summary alone', (tester) async {
      var summarized = false;
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(_checklist(answered: 30), onSummary: () => summarized = true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Finish'), findsOneWidget);
      expect(find.text('Summary'), findsNothing);
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(summarized, isTrue);
    });

    testWidgets('the secondary summary opens the summary', (tester) async {
      var summarized = false;
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(_checklist(answered: 5), onSummary: () => summarized = true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();
      expect(summarized, isTrue);
    });

    testWidgets('read-only jobs get one summary action', (tester) async {
      var summarized = false;
      await tester.pumpWidget(
        _scope(
          child: _host(
            _deck(
              _checklist(answered: 30, status: 'PENDING_REVIEW'),
              onSummary: () => summarized = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Finish'), findsNothing);
      expect(find.text('Continue'), findsNothing);
      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();
      expect(summarized, isTrue);
    });
  });

  group('states', () {
    testWidgets('an empty section names itself', (tester) async {
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
      await tester.pumpWidget(
        _scope(child: _host(_deck(checklist, selectedCategory: 'empty'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('No items in this category.'), findsOneWidget);
    });

    testWidgets('no categories is a designed empty state', (tester) async {
      await tester.pumpWidget(
        _scope(
          child: _host(_deck(_checklist(answered: 0, categories: const []))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This checklist has no categories.'), findsOneWidget);
    });
  });

  group('resilience', () {
    testWidgets('survives 1.5x in RTL without clipping identity', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 1688);
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
            locale: const Locale('ar'),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(body: _deck(_checklist(answered: 5))),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Toyota Land Cruiser 2023'), findsOneWidget);
      expect(find.text('AUD-354626'), findsOneWidget);
    });
  });
}
