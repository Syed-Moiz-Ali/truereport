/// Tests for the Fieldwork shell navigation: dock below 900, rail at or above
/// 900, active state, RTL mirroring and text scaling.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/inspection/fieldwork/fieldwork_ui.dart';
import 'package:technician_app/src/features/shell/fieldwork/shell_nav.dart';

const _data = TechnicianNavData(
  jobsLabel: 'Jobs',
  profileLabel: 'Profile',
  markLabel: 'TrueReport',
);

class _Harness extends StatefulWidget {
  const _Harness({required this.data, this.initialIndex = 0});

  final TechnicianNavData data;
  final int initialIndex;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return TechnicianShellFrame(
      index: _index,
      data: widget.data,
      onSelected: (next) => setState(() => _index = next),
      body: const ColoredBox(
        key: Key('sample-body'),
        color: Colors.white,
        child: Center(child: Text('body')),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  TechnicianNavData data = _data,
  int index = 0,
  bool rtl = false,
  double scale = 1,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: _Harness(data: data, initialIndex: index),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('899 is the dock, 900 is the rail', (tester) async {
    await _pump(tester, size: const Size(899, 800));
    expect(find.byType(FieldworkDock), findsOneWidget);
    expect(find.byType(FieldworkRail), findsNothing);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await _pump(tester, size: const Size(900, 800));
    expect(find.byType(FieldworkDock), findsNothing);
    expect(find.byType(FieldworkRail), findsOneWidget);
    expect(find.text('TR'), findsOneWidget);
    expect(find.byIcon(Icons.work_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dock changes the active destination', (tester) async {
    await _pump(tester, size: const Size(390, 844));
    expect(find.byIcon(Icons.work_rounded), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rail changes the active destination', (tester) async {
    await _pump(tester, size: const Size(1024, 768));
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL mirrors the dock order and puts the rail on the right', (
    tester,
  ) async {
    await _pump(tester, size: const Size(390, 844), rtl: true);
    final jobs = tester.getCenter(find.text('Jobs'));
    final profile = tester.getCenter(find.text('Profile'));
    expect(jobs.dx, greaterThan(profile.dx));

    await _pump(tester, size: const Size(1024, 768), rtl: true);
    final mark = tester.getCenter(find.text('TR'));
    expect(mark.dx, greaterThan(512));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rail always leaves at least the 760 board width', (
    tester,
  ) async {
    for (final width in <double>[900, 1024, 1440]) {
      await _pump(tester, size: Size(width, 800));
      final body = tester.getSize(find.byKey(const Key('sample-body')));
      expect(body.width, greaterThanOrEqualTo(760));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('long labels hold at 130% text scaling', (tester) async {
    const long = TechnicianNavData(
      jobsLabel: 'Dashboard and jobs',
      profileLabel: 'My technician profile',
      markLabel: 'TrueReport',
    );
    await _pump(tester, size: const Size(390, 844), data: long, scale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Dashboard and jobs'), findsOneWidget);
    expect(find.text('My technician profile'), findsOneWidget);
  });

  testWidgets('navigation targets meet the 44 px floor', (tester) async {
    await _pump(tester, size: const Size(390, 844));
    final dockTab = tester.getSize(find.byType(FieldworkPress).first);
    expect(dockTab.height, greaterThanOrEqualTo(44));

    await _pump(tester, size: const Size(1024, 768));
    final railItem = tester.getSize(find.byType(FieldworkPress).first);
    expect(railItem.width, greaterThanOrEqualTo(44));
    expect(railItem.height, greaterThanOrEqualTo(44));
  });

  testWidgets('navigation introduces no second primary action', (tester) async {
    await _pump(tester, size: const Size(1024, 768));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
