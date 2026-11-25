/// Widget contract for the jobs-list primitives.
///
/// These are the pieces the page and the rows compose: a status chip whose word
/// survives colour loss, a plate that never clips, a progress bar that is absent
/// at zero, a search field with a real 44 px clear target, a skeleton shaped
/// like the rows, and the shared empty/error/note states.
library;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/jobs/queue/jobs_queue_primitives.dart';

Widget _host(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  bool rtl = false,
  bool reduceMotion = false,
  double width = 420,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: textScaler, disableAnimations: reduceMotion),
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  group('QueueStatusChip', () {
    testWidgets('is a 28 px tone pill that always carries its word', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const QueueStatusChip(
            label: 'Pending Review',
            tone: StatusTone.warning,
          ),
        ),
      );

      expect(find.text('Pending Review'), findsOneWidget);
      expect(
        tester.getSize(find.byType(QueueStatusChip)).height,
        inInclusiveRange(28, 30),
      );

      final surface = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(QueueStatusChip),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = surface.decoration! as BoxDecoration;
      expect(decoration.color, AppStatusColors.light.warning.background);
    });

    testWidgets('grows instead of clipping at 1.5x', (tester) async {
      await tester.pumpWidget(
        _host(
          const QueueStatusChip(
            label: 'Pending Review',
            tone: StatusTone.warning,
          ),
          textScaler: const TextScaler.linear(1.5),
          width: 300,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(
        tester.getSize(find.byType(QueueStatusChip)).height,
        greaterThan(28),
      );
    });
  });

  group('QueuePlate', () {
    testWidgets('keeps the LTR tabular run at 1.5x without clipping', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const QueuePlate('AUD-354626', large: true),
          textScaler: const TextScaler.linear(1.5),
          rtl: true,
          width: 260,
        ),
      );

      final plate = tester.widget<Text>(find.text('AUD-354626'));
      expect(plate.textDirection, TextDirection.ltr);
      expect(plate.maxLines, 1);
      expect(plate.softWrap, isFalse);
      expect(
        plate.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('QueueProgressBar', () {
    testWidgets('is absent at zero and 6 px with ink fill once started', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const QueueProgressBar(value: 0, total: 30)),
      );
      expect(
        find.descendant(
          of: find.byType(QueueProgressBar),
          matching: find.byType(ClipRRect),
        ),
        findsNothing,
      );

      await tester.pumpWidget(
        _host(const QueueProgressBar(value: 12, total: 30)),
      );
      expect(tester.getSize(find.byType(QueueProgressBar)).height, 6);
      expect(
        find.descendant(
          of: find.byType(QueueProgressBar),
          matching: find.byType(ClipRRect),
        ),
        findsOneWidget,
      );
    });
  });

  group('QueueSearchField', () {
    testWidgets('has a leading icon and a 44 px clear target', (tester) async {
      final controller = TextEditingController(text: 'land cruiser');
      addTearDown(controller.dispose);
      var changed = 'unchanged';
      var cleared = false;

      await tester.pumpWidget(
        _host(
          QueueSearchField(
            controller: controller,
            hint: 'Search jobs',
            onChanged: (value) => changed = value,
            onClear: () => cleared = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(
        tester.getSize(find.byType(QueueSearchField)).height,
        greaterThanOrEqualTo(48),
      );

      final clearTarget = find
          .ancestor(
            of: find.byIcon(Icons.close_rounded),
            matching: find.byType(SizedBox),
          )
          .first;
      expect(tester.getSize(clearTarget), const Size(44, 44));

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(cleared, isTrue);
      expect(changed, isEmpty);
      expect(controller.text, isEmpty);
    });
  });

  group('QueueSkeleton', () {
    testWidgets('honours reduce motion and survives 1.5x in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const QueueSkeleton(),
          reduceMotion: true,
          textScaler: const TextScaler.linear(1.5),
          rtl: true,
          width: 390,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'a reduced-motion shimmer must not keep a ticker running',
      );

      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });

  group('QueueEmptyPanel and QueueErrorPanel', () {
    testWidgets('share one illustration-free 18/700 + 13 px composition', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const QueueEmptyPanel(
            title: 'All caught up',
            body: 'No jobs are waiting on this day.',
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('All caught up'));
      expect(title.style?.fontSize, 18);
      expect(title.style?.fontWeight, FontWeight.w700);

      final body = tester.widget<Text>(
        find.text('No jobs are waiting on this day.'),
      );
      expect(body.style?.fontSize, 13);
      expect(
        find.descendant(
          of: find.byType(QueueEmptyPanel),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('error keeps the retry callback and one action', (
      tester,
    ) async {
      var retried = false;
      await tester.pumpWidget(
        _host(
          QueueErrorPanel(
            title: 'Could not load',
            body: 'Check the connection and try again.',
            retryLabel: 'Retry',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      final body = tester.widget<Text>(
        find.text('Check the connection and try again.'),
      );
      expect(body.style?.fontSize, 13);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('QueueNote', () {
    testWidgets('keeps a 44 px band and the tone foreground', (tester) async {
      await tester.pumpWidget(
        _host(
          const QueueNote(
            icon: Icons.cloud_off_rounded,
            label: 'Offline, changes are saved on this device',
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(QueueNote)).height,
        greaterThanOrEqualTo(44),
      );
      final text = tester.widget<Text>(
        find.text('Offline, changes are saved on this device'),
      );
      expect(text.style?.fontSize, 13);
      expect(text.style?.color, AppStatusColors.light.warning.foreground);
      expect(tester.takeException(), isNull);
    });
  });
}
