/// Characterization tests for the queue labels.
///
/// Every expected string is written out, so a formatter, locale or weekday
/// change fails here before it reaches a technician's screen.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/jobs/queue/jobs_queue_format.dart';

import '../support/fixtures.dart';

void main() {
  // A bundle with just the two keys queueDayLabel reads. Unknown keys render
  // as an empty string by design, so a complete bundle is not required.
  final strings = UiStrings.fromMessages(<String, String>{
    'dashboardToday': 'Today, {date}',
    'technicianQueued': 'Job queue',
  });

  group('queueDayLabel', () {
    test('prints the weekday of the date it is given', () {
      // Monday 9 March 2026 through Sunday 15 March 2026.
      final days = <DateTime>[
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 10),
        DateTime(2026, 3, 11),
        DateTime(2026, 3, 12),
        DateTime(2026, 3, 13),
        DateTime(2026, 3, 14),
        DateTime(2026, 3, 15),
      ];
      const expected = <String>[
        'Mon 9 Mar',
        'Tue 10 Mar',
        'Wed 11 Mar',
        'Thu 12 Mar',
        'Fri 13 Mar',
        'Sat 14 Mar',
        'Sun 15 Mar',
      ];
      // Three weeks later, so every day above is in the past.
      final now = DateTime.utc(2026, 4, 2, 6);

      for (var index = 0; index < days.length; index += 1) {
        final day = days[index];
        expect(
          queueDayLabel(day, strings, 'en', now: now),
          expected[index],
          reason: 'weekday must match DateTime.weekday ${day.weekday}',
        );
        expect(
          queueWeekdayShort(day, 'en'),
          expected[index].substring(0, 3),
          reason: 'rail and label must not drift apart',
        );
      }
    });

    test('shows Today with the date, not a weekday, for the current day', () {
      final day = DateTime(2026, 3, 12);

      expect(
        queueDayLabel(day, strings, 'en', now: fixedNow()),
        'Today, 12 Mar',
      );
    });

    test('names the undated section from the bundle', () {
      expect(queueDayLabel(null, strings, 'en', now: fixedNow()), 'Job queue');
    });

    test('indexes dates by the Dubai day, not the UTC day', () {
      // 21:00 UTC on 11 March is 01:00 on 12 March in Dubai, so 12 March is
      // "today" for a technician working that shift.
      final now = DateTime.utc(2026, 3, 11, 21);

      expect(
        queueDayLabel(DateTime(2026, 3, 12), strings, 'en', now: now),
        'Today, 12 Mar',
      );
    });
  });

  group('queueSlotLabel', () {
    test('prefers the scheduled time over the actual start', () {
      final job = jobSummary(
        scheduledAt: '2026-03-12T09:30:00',
        startedAt: '2026-03-12T10:05:00',
      );

      expect(queueSlotLabel(job), '09:30');
    });

    test('falls back to the start time when there is no schedule', () {
      final job = jobSummary(
        scheduledAt: null,
        startedAt: '2026-03-12T10:05:00',
      );

      expect(queueSlotLabel(job), '10:05');
    });

    test('is empty when the job has no time at all', () {
      expect(queueSlotLabel(jobSummary(scheduledAt: null)), isEmpty);
    });

    test('prints offset timestamps on the Dubai wall clock', () {
      final job = jobSummary(scheduledAt: '2026-03-12T05:30:00Z');

      expect(queueSlotLabel(job), '09:30');
    });
  });

  group('queueVehicleLabel', () {
    test('joins make, model and year', () {
      expect(queueVehicleLabel(jobSummary()), 'Toyota Land Cruiser 2023');
    });

    test('omits the year when the vehicle has none', () {
      expect(
        queueVehicleLabel(jobSummary(vehicleYear: null)),
        'Toyota Land Cruiser',
      );
    });

    test('falls back to the plate when make and model are missing', () {
      final job = jobSummary(vehicleMake: '', vehicleModel: '');

      expect(queueVehicleLabel(job), 'AUD-354626');
    });

    test('falls back to the job reference when the plate is missing too', () {
      final job = jobSummary(
        reference: 'TR-2026-0412',
        vehicleMake: '',
        vehicleModel: '',
        vehiclePlate: null,
      );

      expect(queueVehicleLabel(job), 'TR-2026-0412');
    });
  });
}
