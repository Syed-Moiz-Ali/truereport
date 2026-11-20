import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_clock.dart';

import 'support/ui_strings_harness.dart';

/// T1 / G5: one time policy.
///
/// A value **without** an offset is a Dubai wall time and must not be shifted;
/// a value **with** an offset is a real instant and converts to Asia/Dubai.
void main() {
  group('WorkshopClock.wallTime — naive values are Dubai wall time', () {
    test('2026-11-18T10:00 stays 10:00 (the old code made it 14:00)', () {
      final wall = WorkshopClock.wallTime('2026-11-18T10:00')!;
      expect([wall.hour, wall.minute], [10, 0]);
      expect([wall.year, wall.month, wall.day], [2026, 11, 18]);
      expect(wall.isUtc, isFalse);
    });

    test('a naive value with seconds and millis keeps them verbatim', () {
      final wall = WorkshopClock.wallTime('2026-11-18T10:00:30.250')!;
      expect(
        [wall.hour, wall.minute, wall.second, wall.millisecond],
        [10, 0, 30, 250],
      );
    });

    test('a date-only value is midnight, unchanged', () {
      final wall = WorkshopClock.wallTime('2026-11-18')!;
      expect([wall.day, wall.hour, wall.minute], [18, 0, 0]);
    });
  });

  group('WorkshopClock.wallTime — offset values convert to Asia/Dubai', () {
    test('2026-11-18T06:00Z renders 10:00', () {
      final wall = WorkshopClock.wallTime('2026-11-18T06:00Z')!;
      expect([wall.hour, wall.minute], [10, 0]);
      expect(wall.isUtc, isTrue);
    });

    test('an explicit +04:00 offset is already Dubai wall time', () {
      final wall = WorkshopClock.wallTime('2026-11-18T10:00+04:00')!;
      expect([wall.hour, wall.minute], [10, 0]);
    });

    test('an offset in another zone converts, e.g. -01:00 → 10:00 Dubai', () {
      final wall = WorkshopClock.wallTime('2026-11-18T05:00-01:00')!;
      expect([wall.hour, wall.minute], [10, 0]);
    });

    test('a UTC value crossing midnight moves the date forward', () {
      final wall = WorkshopClock.wallTime('2026-11-18T22:30Z')!;
      expect([wall.day, wall.hour, wall.minute], [19, 2, 30]);
    });

    test('lower-case z is an offset too', () {
      final wall = WorkshopClock.wallTime('2026-11-18T06:00z')!;
      expect(wall.hour, 10);
    });
  });

  group('WorkshopClock.wallTime — empty and unparseable', () {
    test('empty and whitespace are null, never "now"', () {
      expect(WorkshopClock.wallTime(''), isNull);
      expect(WorkshopClock.wallTime('   '), isNull);
      expect(WorkshopClock.wallTime(null), isNull);
    });

    test('unparseable text is null so the caller can fall back', () {
      expect(WorkshopClock.wallTime('tomorrow morning'), isNull);
      expect(WorkshopClock.wallTime('18/11/2026 10:00'), isNull);
    });
  });

  group('formatting through the one helper', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: testLocalizationsDelegates,
          home: Scaffold(body: Builder(builder: (_) => child)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('naive 10:00 and offset 06:00Z render the same 10:00', (
      tester,
    ) async {
      late BuildContext context;
      await pump(
        tester,
        Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.shrink();
          },
        ),
      );

      final naive = WorkshopClock.formatInstant(context, '2026-11-18T10:00');
      final offset = WorkshopClock.formatInstant(context, '2026-11-18T06:00Z');
      expect(naive, '11/18/2026 10:00');
      expect(offset, naive);
      expect(naive.contains('14:00'), isFalse);
    });

    testWidgets('formatDate keeps the date and drops the clock', (
      tester,
    ) async {
      late BuildContext context;
      await pump(
        tester,
        Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(
        WorkshopClock.formatDate(context, '2026-11-18T06:00Z'),
        '11/18/2026',
      );
    });

    testWidgets('empty renders the caller fallback, unparseable keeps raw', (
      tester,
    ) async {
      late BuildContext context;
      await pump(
        tester,
        Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(WorkshopClock.formatInstant(context, ''), '');
      expect(WorkshopClock.formatInstant(context, null), '');
      expect(
        WorkshopClock.formatInstant(
          context,
          'not-a-date',
          fallback: 'not-a-date',
        ),
        'not-a-date',
      );
      expect(WorkshopClock.formatDate(context, '', fallback: 'Raw'), 'Raw');
    });

    testWidgets('job_widgets.formatInstant delegates to the one policy', (
      tester,
    ) async {
      late BuildContext context;
      await pump(
        tester,
        Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(formatInstant(context, '2026-11-18T10:00'), '11/18/2026 10:00');
      expect(formatInstant(context, '2026-11-18T06:00Z'), '11/18/2026 10:00');
      // Empty stays empty; unparseable is shown verbatim, never invented.
      expect(formatInstant(context, ''), '');
      expect(formatInstant(context, 'broken'), 'broken');
    });
  });
}
