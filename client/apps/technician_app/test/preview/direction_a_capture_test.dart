import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/preview/direction_a.dart';
import 'package:technician_app/preview/preview_data.dart';

Widget _app(PreviewScreen s) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.build(),
  home: DirectionA(screen: s),
);

Widget _host(
  PreviewScreen s, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.build(),
  builder: (BuildContext context, Widget? child) => Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
  ),
  home: DirectionA(screen: s),
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
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/a_${screen.name}_${entry.key}.png'),
        );
      });
    }
  }

  testWidgets('answering settles the next item in', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(PreviewScreen.job));
    expect(find.text('Front brake pads'), findsOneWidget);
    await tester.tap(find.text('Pass'));
    await tester.pumpAndSettle();
    expect(find.text('Front brake pads'), findsNothing);
    expect(find.text('Tyre condition & pressures'), findsOneWidget);
  });

  testWidgets('section control opens the six-section sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(PreviewScreen.job));
    await tester.tap(find.text('Suspension · 2 of 6'));
    await tester.pumpAndSettle();
    expect(find.text('Sections'), findsOneWidget);
    expect(find.text('Braking Systems & Tyres'), findsOneWidget);
    expect(find.text('Road Test & Dynamic Performance'), findsOneWidget);
  });

  for (final screen in PreviewScreen.values) {
    testWidgets('rtl 390 ${screen.name} does not overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(screen, direction: TextDirection.rtl));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('200% text 390 ${screen.name} does not overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(screen, scale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
