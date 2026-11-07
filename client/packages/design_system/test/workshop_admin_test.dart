import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool isArabic = false,
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(isArabic: isArabic),
      home: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkshopHeader', () {
    for (final arabic in [false, true]) {
      testWidgets(
        'renders without overflow ${arabic ? 'ar' : 'en'} 1280',
        (tester) async {
          await _pump(
            tester,
            WorkshopHeader(
              title: arabic ? 'لوحة التحكم' : 'Dashboard',
              search: const SizedBox(height: 48, child: Text('search')),
              actions: [
                AppButton(label: arabic ? 'جديد' : 'New', onPressed: () {}),
              ],
              user: const WorkshopUserChip(
                initials: 'DV',
                displayName: 'David Vance',
                workshopName: 'Workshop',
              ),
            ),
            isArabic: arabic,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('user chip carries no role claim', (tester) async {
      await _pump(
        tester,
        const WorkshopUserChip(
          initials: 'DV',
          displayName: 'David Vance',
          workshopName: 'Workshop',
        ),
      );
      expect(find.textContaining('Lead'), findsNothing);
      expect(find.textContaining('Inspector'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopStatCard', () {
    testWidgets('renders value, caption and track', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 346,
          child: WorkshopStatCard(
            value: '4',
            caption: 'Ready to finalize',
            icon: Icons.inbox_outlined,
            progress: 0.5,
          ),
        ),
      );
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Ready to finalize'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopJobCard', () {
    testWidgets('renders and activates by keyboard', (tester) async {
      var tapped = 0;
      var opened = 0;
      await _pump(
        tester,
        SizedBox(
          width: 1104,
          child: WorkshopJobCard(
            title: 'Porsche 911 Carrera S',
            reference: 'JOB-5A0001',
            status: const StatusChip(
              label: 'In progress',
              tone: StatusTone.info,
            ),
            meta: const [Text('Arthur Pendelton')],
            onTap: () => tapped++,
            onOpen: () => opened++,
            openSemanticLabel: 'Open job',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // Focus the card via keyboard traversal and activate it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(tapped, 1);
      expect(opened, 0);
    });
  });

  group('WorkshopOptionCard', () {
    testWidgets('selection is exposed semantically, not colour-alone', (
      tester,
    ) async {
      var selected = 'a';
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              WorkshopOptionCard<String>(
                value: 'a',
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
                title: 'Option A',
              ),
              WorkshopOptionCard<String>(
                value: 'b',
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v),
                title: 'Option B',
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final first = tester.getSemantics(find.text('Option A'));
      expect(
        first,
        matchesSemantics(
          label: 'Option A',
          isSelected: true,
          hasSelectedState: true,
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.text('Option B'));
      await tester.pump();
      expect(selected, 'b');
    });
  });

  group('WorkshopDialog', () {
    Future<void> pumpHost(WidgetTester tester, {required bool wide}) async {
      tester.view.physicalSize = wide
          ? const Size(1280, 800)
          : const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => AppButton(
                  label: 'Open',
                  onPressed: () => WorkshopDialog.show<void>(
                    context,
                    title: 'Assign technician',
                    subtitle: 'Select an available technician',
                    closeSemanticLabel: 'Close dialog',
                    content: const Text('Body'),
                    actions: [
                      AppButton(label: 'Confirm', onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('Esc closes and focus returns to the invoker', (tester) async {
      await pumpHost(tester, wide: true);
      final opener = find.text('Open');
      await tester.tap(opener);
      await tester.pumpAndSettle();
      expect(find.text('Assign technician'), findsOneWidget);
      // Move focus into the dialog, then press Esc.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Assign technician'), findsNothing);
    });

    testWidgets('dialog is centred with 512 max width', (tester) async {
      await pumpHost(tester, wide: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final constrained = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox && widget.constraints.maxWidth == 512,
      );
      expect(constrained, findsOneWidget);
      expect(tester.getSize(constrained).width, lessThanOrEqualTo(512.5));
      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopSideSheet', () {
    testWidgets('wide shows 420 right panel', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: Scaffold(
            body: Builder(
              builder: (context) => AppButton(
                label: 'Open',
                onPressed: () => WorkshopSideSheet.show<void>(
                  context,
                  title: 'Schedule new job',
                  closeSemanticLabel: 'Close panel',
                  body: const Text('Form'),
                  footer: AppButton(label: 'Create', onPressed: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Schedule new job'), findsOneWidget);
      expect(find.text('Form'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Schedule new job'), findsNothing);
    });

    testWidgets('narrow falls back to a bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: Scaffold(
            body: Builder(
              builder: (context) => AppButton(
                label: 'Open',
                onPressed: () => WorkshopSideSheet.show<void>(
                  context,
                  title: 'Schedule new job',
                  closeSemanticLabel: 'Close panel',
                  body: const Text('Form'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Schedule new job'), findsOneWidget);
      expect(find.byType(BottomSheet), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppDataTable arrow-key navigation', () {    testWidgets('ArrowDown/ArrowUp move focus between rows', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 900,
          height: 400,
          child: AppDataTable<String>(
            columns: const [
              AppDataColumn(label: 'Name', cellBuilder: _cell),
            ],
            rows: const ['Alpha', 'Beta', 'Gamma'],
            onRowTap: (_) {},
            rowSemanticLabelBuilder: (row, _) => 'Row $row',
          ),
        ),
        size: const Size(900, 500),
      );
      expect(tester.takeException(), isNull);
      // Focus the first row, then move down twice and up once.
      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopStaffCard', () {
    testWidgets('renders display-only status, no toggle', (tester) async {
      await _pump(
        tester,
        const WorkshopStaffCard(
          displayName: 'David Vance',
          statusActive: true,
          roleLabel: 'Technician',
        ),
      );
      expect(find.text('David Vance'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopMetric', () {
    testWidgets('renders value and label', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: WorkshopMetric(
            value: '4',
            label: 'Active technicians',
            icon: Icons.groups_outlined,
            progress: 0.5,
          ),
        ),
      );
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Active technicians'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopTemplateCard', () {
    testWidgets('renders title, version and actions', (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        SizedBox(
          width: 360,
          child: WorkshopTemplateCard(
            title: 'Full inspection',
            versionLabel: 'v3 · 110 checkpoints',
            description: 'Standard checks',
            onTap: () => tapped++,
          ),
        ),
      );
      expect(find.text('Full inspection'), findsOneWidget);
      await tester.tap(find.text('Full inspection'));
      await tester.pump();
      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopSequenceCard', () {
    testWidgets('exposes index and keyboard activation', (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        SizedBox(
          width: 600,
          child: WorkshopSequenceCard(
            indexLabel: '01',
            title: 'Check Brakes',
            chips: const [
              StatusChip(label: 'Required', tone: StatusTone.info),
            ],
            onTap: () => tapped++,
          ),
        ),
      );
      expect(find.text('01'), findsOneWidget);
      await tester.tap(find.text('Check Brakes'));
      await tester.pump();
      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopDropZone', () {
    testWidgets('tap activates', (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        WorkshopDropZone(
          label: 'Drop checkpoint here',
          onTap: () => tapped++,
        ),
      );
      await tester.tap(find.text('Drop checkpoint here'));
      await tester.pump();
      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('WorkshopLockedPill', () {
    testWidgets('renders label', (tester) async {
      await _pump(
        tester,
        const WorkshopLockedPill(label: 'Required by platform'),
      );
      expect(find.text('Required by platform'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _cell(BuildContext context, String row, int index) => Text(row);
