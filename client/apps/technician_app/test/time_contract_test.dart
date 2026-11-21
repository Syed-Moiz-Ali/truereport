import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:technician_app/src/features/jobs/assigned_jobs_view.dart';
import 'package:technician_app/src/features/jobs/queue/jobs_queue_format.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/shared/technician_intl.dart';

JobSummary _job(String id, {String? scheduledAt, String? startedAt}) =>
    JobSummary.fromJson(<String, dynamic>{
      'id': id,
      'reference': 'JOB-$id',
      'status': 'ASSIGNED',
      'templateVersionId': 'version-1',
      'templateNameEn': 'Full inspection',
      'templateNameAr': 'فحص شامل',
      'customerName': 'Customer',
      'vehicleMake': 'Toyota',
      'vehicleModel': 'Camry',
      'scheduledAt': scheduledAt,
      'startedAt': startedAt,
    });

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('technician wall-clock contract', () {
    test('naive 22:00 stays 22:00 on the same day', () {
      final wall = parseWallTime('2026-11-21T22:00:00')!;

      expect(
        <int>[wall.year, wall.month, wall.day, wall.hour, wall.minute],
        <int>[2026, 11, 21, 22, 0],
      );
      final job = _job('naive', scheduledAt: '2026-11-21T22:00:00');
      expect(queueTimeLabel(job), '22:00');
      expect(
        scheduledTodayUtc4(
          '2026-11-21T22:00:00',
          DateTime.utc(2026, 11, 21, 10),
        ),
        isTrue,
      );
      expect(scheduledTimeUtc4('2026-11-21T22:00:00'), '22:00 UTC+4');
    });

    test('18:00Z converts to 22:00 on the same day', () {
      final wall = parseWallTime('2026-11-21T18:00:00Z')!;

      expect(
        <int>[wall.year, wall.month, wall.day, wall.hour, wall.minute],
        <int>[2026, 11, 21, 22, 0],
      );
      final job = _job('offset', scheduledAt: '2026-11-21T18:00:00Z');
      expect(queueTimeLabel(job), '22:00');
      expect(
        scheduledTodayUtc4(
          '2026-11-21T18:00:00Z',
          DateTime.utc(2026, 11, 21, 10),
        ),
        isTrue,
      );
      expect(scheduledTimeUtc4('2026-11-21T18:00:00Z'), '22:00 UTC+4');
    });
  });

  group('day board', () {
    test('a naive 23:30 job stays under today, not tomorrow', () {
      final job = _job('late', scheduledAt: '2026-11-21T23:30:00');

      expect(queueDayKey(job), DateTime(2026, 11, 21));
      final sections = groupQueueJobs(<JobSummary>[
        job,
      ], now: DateTime.utc(2026, 11, 21, 10));
      expect(sections, hasLength(1));
      expect(sections.single.day, DateTime(2026, 11, 21));
      expect(sections.single.jobs.single.id, 'late');
    });

    test('a job with no timestamp stays in the no-date section', () {
      final job = _job('undated');

      expect(queueMoment(job), isNull);
      expect(queueDayKey(job), isNull);
      final sections = groupQueueJobs(<JobSummary>[
        job,
      ], now: DateTime.utc(2026, 11, 21, 10));
      expect(sections, hasLength(1));
      expect(sections.single.day, isNull);
      expect(sections.single.jobs.single.id, 'undated');
    });
  });
}
