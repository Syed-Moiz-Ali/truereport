/// Widget contract for the Fieldwork hub: run sheet, focus card, up next and
/// the pinned primary. It never saves — the primary opens the current item.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_ui.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_workspace.dart';

const _copy = WorkspaceCopy(
  runSheetLabel: 'IN ORDER OF THE CHECKLIST',
  upNextLabel: 'NEXT ITEM',
  upNextHeading: 'Brakes',
  upNextSubheading: '5 of 8 items',
  upNextEmpty: 'All 30 items answered',
  summaryLabel: 'Summary',
  openLabel: 'Continue',
  allAnsweredTitle: 'All 30 items answered',
  allAnsweredBody: 'Complete the job to send it for review.',
  noCategoriesTitle: 'This checklist has no categories.',
  noCategoriesBody: 'Nothing has been served for this job yet.',
  noItemsTitle: 'No items in this category.',
  noItemsBody: 'Start the inspection when the vehicle and customer details are confirmed.',
  noItemsHint: '',
  stepSemanticLabel: 'Checklist order',
  progressSemanticLabel: '15 of 30 items',
  safetyLabel: 'Safety critical',
);

const _header = WorkspaceHeader(
  title: 'Inspection hub',
  reference: 'TR-2026-0412',
  vehicle: 'Toyota Land Cruiser 2023',
  plate: 'AUD-354626',
  statusLabel: 'Scheduled',
  statusTone: StatusTone.info,
  slotLabel: '09:30',
  done: 15,
  total: 30,
);

const _stations = <WorkspaceStation>[
  WorkspaceStation(
    code: 'BRAKES',
    label: 'Brakes',
    icon: Icons.disc_full_outlined,
    done: 5,
    total: 8,
  ),
  WorkspaceStation(
    code: 'ENGINE',
    label: 'Engine bay',
    icon: Icons.settings_outlined,
    done: 3,
    total: 6,
  ),
  WorkspaceStation(
    code: 'TIRES',
    label: 'Tires & wheels',
    icon: Icons.trip_origin_outlined,
    done: 4,
    total: 4,
  ),
];

const _focus = WorkspaceFocus(
  number: 6,
  total: 30,
  categoryLabel: 'Brakes',
  label: 'Front brake pads',
  instruction: 'Measure pad thickness at both front wheels.',
  spec: 'Minimum 3.0 mm',
  safety: true,
  safetyLabel: 'Safety critical',
  facts: [FieldworkFact(label: '2 required', icon: Icons.tune_rounded)],
);

const _upNext = <WorkspaceNext>[
  WorkspaceNext(
    itemCode: 'BRK-07',
    number: 7,
    label: 'ABS sensors',
    metaLabel: 'Not checked',
    safety: false,
  ),
  WorkspaceNext(
    itemCode: 'BRK-08',
    number: 8,
    label: 'Master cylinder',
    metaLabel: 'Safety critical',
    safety: true,
  ),
];

const _sectionItems = <WorkspaceSectionItem>[
  WorkspaceSectionItem(
    itemCode: 'BRK-01',
    number: 1,
    label: 'Front brake discs',
    statusLabel: 'Pass',
    statusTone: StatusTone.success,
    safety: true,
  ),
  WorkspaceSectionItem(
    itemCode: 'BRK-02',
    number: 2,
    label: 'Rear brake pads',
    statusLabel: 'Attention',
    statusTone: StatusTone.warning,
    safety: false,
  ),
  WorkspaceSectionItem(
    itemCode: 'BRK-07',
    number: 7,
    label: 'ABS sensors',
    statusLabel: 'Not checked',
    statusTone: StatusTone.neutral,
    safety: false,
  ),
  WorkspaceSectionItem(
    itemCode: 'BRK-08',
    number: 8,
    label: 'Master cylinder',
    statusLabel: 'Not checked',
    statusTone: StatusTone.neutral,
    safety: true,
    current: true,
  ),
];

List<FieldworkTick> _ticks() => [
  for (var index = 0; index < 8; index++)
    FieldworkTick(
      label: index == 5
          ? 'Item 6 of 30 · Not checked · Safety critical'
          : 'Item ${index + 1} of 30 · Not checked',
      categoryCode: 'BRAKES',
      answered: index < 5,
      current: index == 5,
      safety: index == 5,
    ),
];

Widget _host(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double height = 844,
}) {
  tester.view.physicalSize = Size(width * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      backgroundColor: AppTheme.light.colorScheme.surfaceContainerLow,
      body: Center(
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

FieldworkWorkspace _hub({
  WorkspaceHeader header = _header,
  List<WorkspaceStation> stations = _stations,
  WorkspaceFocus? focus = _focus,
  List<WorkspaceNext> upNext = _upNext,
  List<WorkspaceSectionItem> sectionItems = _sectionItems,
  bool readOnly = false,
  bool sectionEmpty = false,
  String openLabel = 'Continue',
  ValueChanged<String>? onStation,
  ValueChanged<String>? onTick,
  VoidCallback? onOpenCurrent,
  ValueChanged<WorkspaceNext>? onOpenItem,
  ValueChanged<WorkspaceSectionItem>? onOpenSectionItem,
  VoidCallback? onSummary,
  VoidCallback? onBack,
}) {
  return FieldworkWorkspace(
    copy: WorkspaceCopy(
      runSheetLabel: _copy.runSheetLabel,
      upNextLabel: _copy.upNextLabel,
      upNextHeading: _copy.upNextHeading,
      upNextSubheading: _copy.upNextSubheading,
      upNextEmpty: _copy.upNextEmpty,
      summaryLabel: _copy.summaryLabel,
      openLabel: openLabel,
      allAnsweredTitle: _copy.allAnsweredTitle,
      allAnsweredBody: _copy.allAnsweredBody,
      noCategoriesTitle: _copy.noCategoriesTitle,
      noCategoriesBody: _copy.noCategoriesBody,
      noItemsTitle: _copy.noItemsTitle,
      noItemsBody: _copy.noItemsBody,
      noItemsHint: _copy.noItemsHint,
      stepSemanticLabel: _copy.stepSemanticLabel,
      progressSemanticLabel: _copy.progressSemanticLabel,
      safetyLabel: _copy.safetyLabel,
    ),
    header: header,
    stations: stations,
    ticks: _ticks(),
    tickSemanticLabel: '15 of 30 items',
    focus: focus,
    upNext: upNext,
    sectionItems: sectionItems,
    readOnly: readOnly,
    sectionEmpty: sectionEmpty,
    onBack: onBack ?? () {},
    onStation: onStation ?? (_) {},
    onTick: onTick ?? (_) {},
    onOpenCurrent: onOpenCurrent ?? () {},
    onOpenItem: onOpenItem ?? (_) {},
    onOpenSectionItem: onOpenSectionItem ?? (_) {},
    onSummary: onSummary ?? () {},
  );
}

void main() {
  group('header', () {
    testWidgets('shows vehicle, plate, reference, status, time and progress', (
      tester,
    ) async {
      await tester.pumpWidget(_host(tester, _hub(), width: 1020));
      await tester.pumpAndSettle();

      expect(find.text('Inspection hub'), findsOneWidget);
      expect(find.text('Toyota Land Cruiser 2023'), findsOneWidget);
      expect(find.text('AUD-354626'), findsOneWidget);
      expect(find.text('TR-2026-0412'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget);
      // One LTR run per count: top bar "15/30", run sheet "15 / 30".
      expect(find.text('15/30'), findsOneWidget);
      expect(find.text('15 / 30'), findsOneWidget);
    });
  });

  group('run sheet', () {
    testWidgets('stations carry their served count and report taps', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _host(tester, _hub(onStation: (code) => selected = code), width: 1020),
      );
      await tester.pumpAndSettle();

      expect(find.text('IN ORDER OF THE CHECKLIST'), findsOneWidget);
      expect(find.text('5/8'), findsOneWidget);
      expect(find.text('3/6'), findsOneWidget);
      expect(find.text('4/4'), findsOneWidget);

      await tester.tap(find.text('Engine bay'));
      await tester.pumpAndSettle();
      expect(selected, 'ENGINE');
    });

    testWidgets('a tick jumps to its category', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _host(tester, _hub(onTick: (code) => selected = code)),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsLabel('Item 6 of 30 · Not checked · Safety critical'),
      );
      await tester.pumpAndSettle();
      expect(selected, 'BRAKES');
    });

    testWidgets('an empty section names itself', (tester) async {
      await tester.pumpWidget(
        _host(tester, _hub(focus: null, upNext: const [], sectionEmpty: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No items in this category.'), findsOneWidget);
      expect(find.text('All 30 items answered'), findsNothing);
    });

    testWidgets('no stations is a designed empty state', (tester) async {
      await tester.pumpWidget(
        _host(tester, _hub(stations: const [], focus: null, upNext: const [])),
      );
      await tester.pumpAndSettle();

      expect(find.text('This checklist has no categories.'), findsOneWidget);
    });
  });

  group('focus', () {
    testWidgets('hero carries the item, instruction, spec and safety', (
      tester,
    ) async {
      await tester.pumpWidget(_host(tester, _hub()));
      await tester.pumpAndSettle();

      expect(find.text('Front brake pads'), findsOneWidget);
      expect(
        find.text('Measure pad thickness at both front wheels.'),
        findsOneWidget,
      );
      expect(find.text('Minimum 3.0 mm'), findsOneWidget);
      expect(find.text('Safety critical'), findsWidgets);
      expect(find.text('2 required'), findsOneWidget);
    });

    testWidgets('the primary opens the current item and never saves', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(tester, _hub(onOpenCurrent: () => opened++)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('the wide card secondary action opens the summary', (
      tester,
    ) async {
      var summarized = 0;
      await tester.pumpWidget(
        _host(tester, _hub(onSummary: () => summarized++), width: 1020),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Summary').first);
      await tester.pumpAndSettle();
      expect(summarized, 1);
    });

    testWidgets('all answered finishes to the summary', (tester) async {
      var summarized = 0;
      await tester.pumpWidget(
        _host(
          tester,
          _hub(
            focus: null,
            upNext: const [],
            openLabel: 'Finish',
            onSummary: () => summarized++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All 30 items answered'), findsWidgets);
      expect(
        find.text('Complete the job to send it for review.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(summarized, 1);
    });

    testWidgets('read-only offers one summary action', (tester) async {
      var summarized = 0;
      await tester.pumpWidget(
        _host(
          tester,
          _hub(readOnly: true, onSummary: () => summarized++),
          width: 1020,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsNothing);
      await tester.tap(find.text('Summary').first);
      await tester.pumpAndSettle();
      expect(summarized, 1);
    });
  });

  group('up next', () {
    testWidgets('lists the next unchecked items and reports a tap', (
      tester,
    ) async {
      WorkspaceNext? opened;
      await tester.pumpWidget(
        _host(tester, _hub(onOpenItem: (item) => opened = item)),
      );
      await tester.pumpAndSettle();

      expect(find.text('NEXT ITEM'), findsOneWidget);
      expect(find.text('ABS sensors'), findsOneWidget);
      await tester.tap(find.text('ABS sensors'));
      await tester.pumpAndSettle();
      expect(opened?.itemCode, 'BRK-07');
    });
  });

  group('section', () {
    testWidgets('the wide section list carries every item and reports a tap', (
      tester,
    ) async {
      WorkspaceSectionItem? opened;
      await tester.pumpWidget(
        _host(
          tester,
          _hub(onOpenSectionItem: (item) => opened = item),
          width: 1020,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Front brake discs'), findsOneWidget);
      expect(find.text('Rear brake pads'), findsOneWidget);
      expect(find.text('ABS sensors'), findsOneWidget);
      expect(find.text('Master cylinder'), findsOneWidget);
      expect(find.text('5 of 8 items'), findsOneWidget);

      await tester.tap(find.text('ABS sensors'));
      await tester.pumpAndSettle();
      expect(opened?.itemCode, 'BRK-07');
    });

    testWidgets('read-only section rows are not buttons', (tester) async {
      WorkspaceSectionItem? opened;
      await tester.pumpWidget(
        _host(
          tester,
          _hub(readOnly: true, onOpenSectionItem: (item) => opened = item),
          width: 1020,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ABS sensors'));
      await tester.pumpAndSettle();
      expect(opened, isNull);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
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
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: _hub()),
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
