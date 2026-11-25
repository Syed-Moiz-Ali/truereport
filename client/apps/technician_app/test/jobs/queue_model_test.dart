/// Unit tests for the pure queue model behind the jobs screen.
///
/// Every rule the UI relies on — which section a job lands in, which verb its
/// row offers, which job the Now card shows and which day the empty state
/// offers — is pinned here with a fixed Dubai clock.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/jobs/queue/queue_model.dart';
import 'package:technician_app/src/inspection_models.dart';

import '../support/fixtures.dart';

void main() {
  // 10:15 on Thursday 12 March 2026 in Asia/Dubai (UTC+4).
  final now = fixedNow();
  final today = fixedTodayKey();
  final yesterday = DateTime(2026, 3, 11);
  final tomorrow = DateTime(2026, 3, 13);

  JobSummary job({
    required String id,
    required String status,
    String? scheduledAt = '2026-03-12T09:30:00',
    int completedItems = 0,
    int totalItems = 30,
  }) => jobSummary(
    id: id,
    status: status,
    scheduledAt: scheduledAt,
    completedItems: completedItems,
    totalItems: totalItems,
  );

  group('groupJobs', () {
    test('puts a past-dated assigned job in unfinished', () {
      final past = job(
        id: 'job-past',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-11T09:00:00',
      );

      final buckets = groupJobs(<JobSummary>[past], now: now);

      expect(buckets.unfinished.map((value) => value.id), <String>['job-past']);
      expect(buckets.today, isEmpty);
      expect(buckets.upcoming, isEmpty);
      expect(buckets.now, isEmpty);
      expect(buckets.doneToday, isEmpty);
      expect(buckets.cancelledCount, 0);
    });

    test('excludes cancelled jobs from every section but counts them', () {
      final cancelled = job(
        id: 'job-cancelled',
        status: 'CANCELLED',
        scheduledAt: '2026-03-12T08:00:00',
      );

      final buckets = groupJobs(<JobSummary>[cancelled], now: now);

      expect(buckets.isEmpty, isTrue);
      expect(buckets.cancelledCount, 1);
      expect(buckets.cancelled.single.id, 'job-cancelled');
      expect(buckets.now, isEmpty);
      expect(buckets.today, isEmpty);
      expect(buckets.upcoming, isEmpty);
      expect(buckets.unfinished, isEmpty);
      expect(buckets.doneToday, isEmpty);
    });

    test('keeps an in-progress job in now even when dated in the past', () {
      final live = job(
        id: 'job-live',
        status: 'IN_PROGRESS',
        scheduledAt: '2026-03-11T08:00:00',
      );

      final buckets = groupJobs(<JobSummary>[live], now: now);

      expect(buckets.now.single.id, 'job-live');
      expect(buckets.unfinished, isEmpty);
      expect(buckets.today, isEmpty);
    });

    test('puts review and finalized jobs dated today in doneToday only', () {
      final reviewing = job(
        id: 'job-review',
        status: 'PENDING_REVIEW',
        scheduledAt: '2026-03-12T08:00:00',
      );
      final approved = job(
        id: 'job-approved',
        status: 'APPROVED',
        scheduledAt: '2026-03-12T10:00:00',
      );
      final publishedToday = job(
        id: 'job-published',
        status: 'PUBLISHED',
        scheduledAt: '2026-03-12T11:00:00',
      );

      final buckets = groupJobs(<JobSummary>[
        reviewing,
        approved,
        publishedToday,
      ], now: now);

      expect(buckets.doneToday.map((value) => value.id), <String>[
        'job-published',
        'job-approved',
        'job-review',
      ]);
      expect(buckets.today, isEmpty);
      expect(buckets.now, isEmpty);
    });

    test('orders today and upcoming ascending, unfinished latest first', () {
      final buckets = groupJobs(<JobSummary>[
        job(
          id: 'today-late',
          status: 'ASSIGNED',
          scheduledAt: '2026-03-12T16:30:00',
        ),
        job(
          id: 'today-early',
          status: 'ASSIGNED',
          scheduledAt: '2026-03-12T08:15:00',
        ),
        job(
          id: 'upcoming-far',
          status: 'ASSIGNED',
          scheduledAt: '2026-03-16T09:00:00',
        ),
        job(
          id: 'upcoming-near',
          status: 'ASSIGNED',
          scheduledAt: '2026-03-13T09:00:00',
        ),
        job(
          id: 'past-old',
          status: 'ASSIGNED',
          scheduledAt: '2026-03-09T09:00:00',
        ),
        job(
          id: 'past-new',
          status: 'ASSIGNED',
          scheduledAt: '2026-03-11T09:00:00',
        ),
      ], now: now);

      expect(buckets.today.map((value) => value.id), <String>[
        'today-early',
        'today-late',
      ]);
      expect(buckets.upcoming.map((value) => value.id), <String>[
        'upcoming-near',
        'upcoming-far',
      ]);
      expect(buckets.unfinished.map((value) => value.id), <String>[
        'past-new',
        'past-old',
      ]);
    });
  });

  group('verbFor', () {
    test('maps the job state to the row action', () {
      expect(verbFor(job(id: 'a', status: 'ASSIGNED')), QueueVerb.start);
      expect(verbFor(job(id: 's', status: 'SCHEDULED')), QueueVerb.start);
      expect(
        verbFor(job(id: 'i', status: 'IN_PROGRESS')),
        QueueVerb.continueJob,
      );
      expect(verbFor(job(id: 'r', status: 'PENDING_REVIEW')), QueueVerb.view);
      expect(verbFor(job(id: 'p', status: 'PUBLISHED')), QueueVerb.view);
      expect(verbFor(job(id: 'c', status: 'CANCELLED')), QueueVerb.view);
      expect(verbFor(job(id: 'u', status: 'SOMETHING_NEW')), QueueVerb.view);
    });

    test('offers finish once every item is assessed', () {
      final done = job(
        id: 'job-assessed',
        status: 'IN_PROGRESS',
        completedItems: 30,
        totalItems: 30,
      );

      expect(verbFor(done), QueueVerb.finish);
    });
  });

  group('nowJob', () {
    test('prefers an in-progress job over an earlier scheduled one', () {
      final scheduled = job(
        id: 'job-early',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-12T08:00:00',
      );
      final live = job(
        id: 'job-live',
        status: 'IN_PROGRESS',
        scheduledAt: '2026-03-12T11:00:00',
      );

      expect(nowJob(<JobSummary>[scheduled, live], now: now)?.id, 'job-live');
    });

    test('falls back to the earliest job due today', () {
      final late = job(
        id: 'job-late',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-12T15:00:00',
      );
      final early = job(
        id: 'job-early',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-12T09:15:00',
      );

      expect(nowJob(<JobSummary>[late, early], now: now)?.id, 'job-early');
    });

    test('falls back to the earliest overdue job when today is empty', () {
      final older = job(
        id: 'job-older',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-09T08:00:00',
      );
      final newer = job(
        id: 'job-newer',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-11T08:00:00',
      );

      expect(nowJob(<JobSummary>[newer, older], now: now)?.id, 'job-older');
    });

    test('ignores cancelled, finished and future jobs', () {
      final cancelled = job(id: 'c', status: 'CANCELLED');
      final finished = job(id: 'f', status: 'PUBLISHED');
      final future = job(
        id: 'u',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-13T09:00:00',
      );

      expect(
        nowJob(<JobSummary>[cancelled, finished, future], now: now),
        isNull,
      );
    });
  });

  group('nearestDayWithWork', () {
    test('skips cancelled days', () {
      final cancelledTomorrow = job(
        id: 'cancelled',
        status: 'CANCELLED',
        scheduledAt: '2026-03-13T09:00:00',
      );
      final workInTwoDays = job(
        id: 'work',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-14T09:00:00',
      );

      expect(
        nearestDayWithWork(<JobSummary>[
          cancelledTomorrow,
          workInTwoDays,
        ], now: now),
        DateTime(2026, 3, 14),
      );
    });

    test('prefers the future day when past and future tie', () {
      final past = job(
        id: 'past',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-11T09:00:00',
      );
      final future = job(
        id: 'future',
        status: 'ASSIGNED',
        scheduledAt: '2026-03-13T09:00:00',
      );

      expect(
        nearestDayWithWork(<JobSummary>[past, future], now: now),
        tomorrow,
      );
      expect(nearestDayWithWork(<JobSummary>[past], now: now), yesterday);
    });

    test('ignores finished and undated jobs', () {
      final done = job(
        id: 'done',
        status: 'APPROVED',
        scheduledAt: '2026-03-13T09:00:00',
      );
      final undated = job(id: 'undated', status: 'ASSIGNED', scheduledAt: null);

      expect(nearestDayWithWork(<JobSummary>[done, undated], now: now), isNull);
    });
  });

  group('QueueBuckets', () {
    test('counts to-start and in-progress jobs without counting cancelled', () {
      final buckets = groupJobs(<JobSummary>[
        job(
          id: 'assigned',
          status: 'ASSIGNED',
          scheduledAt: '2026-03-12T09:00:00',
        ),
        job(
          id: 'live',
          status: 'IN_PROGRESS',
          scheduledAt: '2026-03-12T10:00:00',
        ),
        job(
          id: 'assessed',
          status: 'IN_PROGRESS',
          scheduledAt: '2026-03-12T11:00:00',
          completedItems: 30,
          totalItems: 30,
        ),
        job(
          id: 'cancelled',
          status: 'CANCELLED',
          scheduledAt: '2026-03-12T12:00:00',
        ),
      ], now: now);

      expect(buckets.toStartCount, 1);
      expect(buckets.inProgressCount, 2);
      expect(buckets.cancelledCount, 1);
      expect(buckets.isEmpty, isFalse);
      expect(today, fixedTodayKey());
    });
  });
}
