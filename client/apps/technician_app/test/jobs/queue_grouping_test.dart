/// Characterization tests for the queue day buckets.
///
/// These pin the contract the jobs queue renders: buckets follow the moment the
/// row prints, today comes first, upcoming days ascend, past days descend and
/// undated jobs trail the list.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/jobs/queue/jobs_queue_format.dart';
import 'package:technician_app/src/inspection_models.dart';

import '../support/fixtures.dart';

void main() {
  // 10:15 on Thursday 12 March 2026 in Asia/Dubai (UTC+4).
  final now = fixedNow();
  final today = fixedTodayKey();
  final yesterday = DateTime(2026, 3, 11);
  final tomorrow = DateTime(2026, 3, 13);

  group('queueDayKey', () {
    test('is the local midnight of the scheduled wall time', () {
      final job = jobSummary(scheduledAt: '2026-03-12T09:30:00');

      expect(queueDayKey(job), today);
      expect(queueDayKey(job)?.hour, 0);
      expect(queueDayKey(job)?.minute, 0);
    });

    test('uses the start time when the job carries no schedule', () {
      final job = jobSummary(
        scheduledAt: null,
        startedAt: '2026-03-12T08:10:00',
      );

      expect(queueDayKey(job), today);
    });

    test('is null when neither scheduled nor started time is present', () {
      final job = jobSummary(scheduledAt: null);

      expect(queueDayKey(job), isNull);
    });

    test('converts offset timestamps to the Dubai day', () {
      // 20:30 UTC on 11 March is 00:30 on 12 March in Dubai.
      final job = jobSummary(scheduledAt: '2026-03-11T20:30:00Z');

      expect(queueDayKey(job), today);
    });

    test(
      'a job scheduled yesterday but started today buckets PAST by schedule',
      () {
        final job = jobSummary(
          id: 'job-late-start',
          scheduledAt: '2026-03-11T09:00:00',
          startedAt: '2026-03-12T08:10:00',
        );

        // The bucket follows the moment the row prints (`scheduledAt` first).
        expect(queueDayKey(job), yesterday);
        expect(
          queueSlotLabel(job),
          '09:00',
          reason: 'the row prints the appointment time, not the late start',
        );

        final sections = groupQueueJobs(<JobSummary>[job], now: now);

        expect(sections, hasLength(1));
        expect(sections.single.day, yesterday);
        expect(sections.single.day!.isBefore(today), isTrue);
      },
    );
  });

  group('groupQueueJobs', () {
    test('orders today, upcoming ascending, past descending, undated last', () {
      final lastWeek = jobSummary(
        id: 'job-last-week',
        scheduledAt: '2026-03-10T11:00:00',
      );
      final yesterdayJob = jobSummary(
        id: 'job-yesterday',
        scheduledAt: '2026-03-11T15:00:00',
      );
      final todayJob = jobSummary(
        id: 'job-today',
        scheduledAt: '2026-03-12T14:00:00',
      );
      final tomorrowJob = jobSummary(
        id: 'job-tomorrow',
        scheduledAt: '2026-03-13T08:00:00',
      );
      final saturdayJob = jobSummary(
        id: 'job-saturday',
        scheduledAt: '2026-03-14T10:00:00',
      );
      final undatedJob = jobSummary(id: 'job-undated', scheduledAt: null);

      final sections = groupQueueJobs(<JobSummary>[
        lastWeek,
        tomorrowJob,
        todayJob,
        undatedJob,
        saturdayJob,
        yesterdayJob,
      ], now: now);

      expect(sections.map((section) => section.day).toList(), <DateTime?>[
        today,
        DateTime(2026, 3, 13),
        DateTime(2026, 3, 14),
        yesterday,
        DateTime(2026, 3, 10),
        null,
      ]);
      expect(sections.last.jobs.single.id, 'job-undated');
      expect(sections.first.jobs.single.id, 'job-today');
    });

    test('sorts the jobs inside one day by their displayed moment', () {
      final late = jobSummary(
        id: 'job-late',
        scheduledAt: '2026-03-12T16:30:00',
      );
      final early = jobSummary(
        id: 'job-early',
        scheduledAt: '2026-03-12T08:15:00',
      );
      final noon = jobSummary(
        id: 'job-noon',
        scheduledAt: '2026-03-12T12:00:00',
      );

      final sections = groupQueueJobs(<JobSummary>[
        late,
        early,
        noon,
      ], now: now);

      expect(sections.single.day, today);
      expect(sections.single.jobs.map((job) => job.id).toList(), <String>[
        'job-early',
        'job-noon',
        'job-late',
      ]);
    });

    test('omits the today section when the day is empty', () {
      final job = jobSummary(
        id: 'job-tomorrow',
        scheduledAt: '2026-03-13T08:00:00',
      );

      final sections = groupQueueJobs(<JobSummary>[job], now: now);

      expect(sections, hasLength(1));
      expect(sections.single.day, tomorrow);
    });

    test('returns no sections for an empty queue', () {
      expect(groupQueueJobs(const <JobSummary>[], now: now), isEmpty);
    });
  });
}
