/// Pins the deck tab bucketing: what lands in Today / Upcoming / Unfinished.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:technician_app/src/features/jobs/queue/deck/deck_sets.dart';
import 'package:technician_app/src/inspection_models.dart';

import '../support/fixtures.dart';

void main() {
  final today = fixedTodayKey();

  JobSummary job({
    required String id,
    required String status,
    String? scheduledAt,
    int completedItems = 0,
    int totalItems = 30,
  }) => jobSummary(
    id: id,
    reference: 'TR-$id',
    status: status,
    scheduledAt: scheduledAt,
    startedAt: status == 'IN_PROGRESS' ? '2026-03-12T08:00:00' : null,
    completedItems: completedItems,
    totalItems: totalItems,
  );

  group('bucketDeckSets', () {
    test('splits today, upcoming and past by Dubai day', () {
      final sets = bucketDeckSets(<JobSummary>[
        job(
          id: 'today',
          status: 'ASSIGNED',
          scheduledAt: '2026-03-12T09:30:00',
        ),
        job(
          id: 'future',
          status: 'SCHEDULED',
          scheduledAt: '2026-03-14T09:30:00',
        ),
        job(id: 'past', status: 'ASSIGNED', scheduledAt: '2026-03-10T09:30:00'),
      ], today);

      expect(sets.today.map((item) => item.id), ['today']);
      expect(sets.upcoming.map((item) => item.id), ['future']);
      expect(sets.unfinished.map((item) => item.id), ['past']);
    });

    test('cancelled jobs land in no bucket', () {
      final sets = bucketDeckSets(<JobSummary>[
        job(
          id: 'gone',
          status: 'CANCELLED',
          scheduledAt: '2026-03-12T09:30:00',
        ),
        job(id: 'kept', status: 'ASSIGNED', scheduledAt: '2026-03-12T09:30:00'),
      ], today);

      expect(sets.today.map((item) => item.id), ['kept']);
      expect(sets.upcoming, isEmpty);
      expect(sets.unfinished, isEmpty);
    });

    test('done jobs stay only when done today', () {
      final sets = bucketDeckSets(<JobSummary>[
        job(
          id: 'done-today',
          status: 'COMPLETED',
          scheduledAt: '2026-03-12T09:30:00',
        ),
        job(
          id: 'done-old',
          status: 'APPROVED',
          scheduledAt: '2026-03-05T09:30:00',
        ),
      ], today);

      expect(sets.today.map((item) => item.id), ['done-today']);
      expect(sets.unfinished, isEmpty);
    });

    test('undated work waits in unfinished', () {
      final sets = bucketDeckSets(<JobSummary>[
        job(id: 'nodate', status: 'ASSIGNED', scheduledAt: null),
      ], today);

      expect(sets.unfinished.map((item) => item.id), ['nodate']);
    });

    test('in-progress work stays actionable in its bucket', () {
      final sets = bucketDeckSets(<JobSummary>[
        job(
          id: 'live',
          status: 'IN_PROGRESS',
          scheduledAt: '2026-03-12T08:00:00',
          completedItems: 9,
        ),
      ], today);

      expect(sets.today.map((item) => item.id), ['live']);
    });
  });

  group('orderDeckJobs', () {
    test('sorts ascending with undated trailing', () {
      final ordered = orderDeckJobs(<JobSummary>[
        job(id: 'late', status: 'ASSIGNED', scheduledAt: '2026-03-12T15:00:00'),
        job(id: 'nodate', status: 'ASSIGNED', scheduledAt: null),
        job(
          id: 'early',
          status: 'ASSIGNED',
          scheduledAt: '2026-03-12T09:30:00',
        ),
      ]);

      expect(ordered.map((item) => item.id), ['early', 'late', 'nodate']);
    });
  });

  group('deckFrontId', () {
    test('keeps an explicit selection inside the set', () {
      final ordered = orderDeckJobs(<JobSummary>[
        job(id: 'a', status: 'ASSIGNED', scheduledAt: '2026-03-12T09:30:00'),
        job(id: 'b', status: 'ASSIGNED', scheduledAt: '2026-03-12T13:30:00'),
      ]);

      expect(deckFrontId(ordered, 'b'), 'b');
    });

    test('prefers the live job then the earliest', () {
      final ordered = orderDeckJobs(<JobSummary>[
        job(id: 'a', status: 'ASSIGNED', scheduledAt: '2026-03-12T09:30:00'),
        job(
          id: 'live',
          status: 'IN_PROGRESS',
          scheduledAt: '2026-03-12T13:30:00',
          completedItems: 9,
        ),
      ]);

      expect(deckFrontId(ordered, null), 'live');
      expect(
        deckFrontId(ordered, 'missing'),
        'live',
        reason: 'a stale selection falls back to the live job',
      );
    });
  });
}
