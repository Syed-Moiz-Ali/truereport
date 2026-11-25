import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/preview/direction_b.dart';
import 'package:technician_app/preview/preview_data.dart';

Widget _app(PreviewScreen s) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.build(),
  home: DirectionB(screen: s),
);

void main() {
  for (final entry in <String, Size>{
    '390': const Size(390, 844),
    '768': const Size(768, 1024),
  }.entries) {
    for (final screen in PreviewScreen.values) {
      testWidgets('${entry.key} ${screen.name}', (tester) async {
        tester.view.physicalSize = entry.value * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(screen));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/b_${screen.name}_${entry.key}.png'),
        );
      });
    }
  }

  testWidgets('390 job: the active station and its current item are visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(PreviewScreen.job));
    await tester.pumpAndSettle();

    expect(find.text('Suspension, Steering & Underbody'), findsOneWidget);
    expect(find.text('Front brake pads'), findsOneWidget);
    expect(find.text('Safety critical'), findsOneWidget);
    expect(find.text('Photo required'), findsWidgets);
    expect(find.text('Finish job'), findsNothing);
  });

  testWidgets('390 job: tapping a station opens its items in place', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(PreviewScreen.job));
    await tester.pumpAndSettle();

    expect(find.text('Front discs'), findsNothing);
    await tester.tap(find.text('Braking Systems & Tyres'));
    await tester.pumpAndSettle();
    expect(find.text('Front discs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '390 queue: unfinished work is pinned and the resume bar is unique',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(PreviewScreen.queue));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('4 jobs'), findsOneWidget);
      expect(find.text('1 unfinished'), findsOneWidget);
      expect(find.text('Unfinished · 23 Nov'), findsOneWidget);
      expect(find.text('Continue · Land Cruiser'), findsOneWidget);
      expect(find.text('Item 10 · Front brake pads'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final screen in PreviewScreen.values) {
    testWidgets('390 ${screen.name}: RTL layout does not overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: DirectionB(screen: screen),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('390 job: summary sheet opens from the bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(PreviewScreen.job));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    expect(find.textContaining('items still to answer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final screen in PreviewScreen.values) {
    testWidgets('390 ${screen.name}: 1.3x text does not overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_app(screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
