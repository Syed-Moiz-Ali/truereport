import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/preview/direction_c.dart';
import 'package:technician_app/preview/preview_data.dart';

Widget _app(PreviewScreen s) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.build(),
  home: DirectionC(screen: s),
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
          matchesGoldenFile('goldens/c_${screen.name}_${entry.key}.png'),
        );
      });
    }
  }

  group('rtl', () {
    testWidgets('job mirrors at 390 without errors', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: DirectionC(screen: PreviewScreen.job),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('queue mirrors at 390 without errors', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: DirectionC(screen: PreviewScreen.queue),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('interaction', () {
    Future<void> pumpJob(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(PreviewScreen.job));
      await tester.pumpAndSettle();
    }

    testWidgets('Pass clears the card and settles the next item', (
      tester,
    ) async {
      await pumpJob(tester);
      expect(find.text('Front brake pads'), findsOneWidget);
      await tester.tap(find.widgetWithText(InkWell, 'Pass'));
      await tester.pumpAndSettle();
      expect(find.text('Tyre condition & pressures'), findsOneWidget);
      expect(find.text('Front brake pads'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('swiping the card start-to-end clears it', (tester) async {
      await pumpJob(tester);
      await tester.drag(find.byType(Dismissible), const Offset(320, 0));
      await tester.pumpAndSettle();
      expect(find.text('Tyre condition & pressures'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('section chip opens the section sheet', (tester) async {
      await pumpJob(tester);
      await tester.tap(find.text('Suspension'));
      await tester.pumpAndSettle();
      expect(find.text('Sections'), findsOneWidget);
      expect(find.text('Powertrain & Mechanical'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/c_job_390_sections.png'),
      );
    });
  });
}
