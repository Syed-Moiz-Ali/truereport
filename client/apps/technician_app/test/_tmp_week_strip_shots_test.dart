import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/jobs/queue/jobs_queue_week.dart';

const String _outDir = r'C:\Users\sanja\AppData\Local\Temp\opencode\week_strip';

void main() {
  final today = DateTime(2026, 3, 12);
  final days = List<DateTime>.generate(
    7,
    (index) => today.add(Duration(days: index)),
  );
  final withJobs = <String>{_key(days[0]), _key(days[2]), _key(days[5])};

  Future<void> pumpStrip(
    WidgetTester tester, {
    required Locale locale,
    required double textScale,
    ValueChanged<DateTime>? onSelect,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 240)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        locale: locale,
        supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: UiStringsScope(
          strings: UiStrings.fromRemoteEnglish(),
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: ColoredBox(
                color: context.colors.surfaceContainerLow,
                child: RepaintBoundary(
                  key: const ValueKey('shot'),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: QueueWeekStrip(
                            days: days,
                            selected: days[0],
                            daysWithJobs: withJobs,
                            onSelect: onSelect ?? (_) {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 64,
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: context.colors.outlineVariant,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('shot')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_outDir\\$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('ltr 1x, scroll end, focus', (tester) async {
    await pumpStrip(tester, locale: const Locale('en'), textScale: 1);
    await capture(tester, 'ltr_1x');

    // Keyboard focus on the selected first cell.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await capture(tester, 'ltr_1x_focus_selected');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await capture(tester, 'ltr_1x_focus_next');

    // Scroll to the end: the trailing cell must be fully visible with its gap.
    await tester.drag(find.byType(QueueWeekStrip), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await capture(tester, 'ltr_1x_end');
  });

  testWidgets('ltr 1.5x', (tester) async {
    await pumpStrip(tester, locale: const Locale('en'), textScale: 1.5);
    await capture(tester, 'ltr_1_5x');
  });

  testWidgets('ltr 2x', (tester) async {
    await pumpStrip(tester, locale: const Locale('en'), textScale: 2);
    await capture(tester, 'ltr_2x');
  });

  testWidgets('rtl 1x', (tester) async {
    await pumpStrip(tester, locale: const Locale('ar'), textScale: 1);
    await capture(tester, 'rtl_1x');
  });

  testWidgets('semantics and selection callback', (tester) async {
    final selected = <DateTime>[];
    await pumpStrip(
      tester,
      locale: const Locale('en'),
      textScale: 1,
      onSelect: selected.add,
    );
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);

    final node = tester.getSemantics(find.bySemanticsLabel('Thu 12 Mar'));
    expect(node.hasFlag(ui.SemanticsFlag.isButton), isTrue);
    expect(node.hasFlag(ui.SemanticsFlag.isSelected), isTrue);
    expect(node.hint, 'Queued');

    final empty = tester.getSemantics(find.bySemanticsLabel('Fri 13 Mar'));
    expect(empty.hint, 'No jobs on this day');

    await tester.tap(find.bySemanticsLabel('Sat 14 Mar'));
    await tester.pumpAndSettle();
    expect(selected, <DateTime>[DateTime(2026, 3, 14)]);
  });
}

String _key(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
