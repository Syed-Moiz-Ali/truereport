import 'package:intl/intl.dart';
import 'package:l10n/ui_strings.dart';

import '../../../inspection_models.dart';
import '../../../shared/technician_intl.dart';

/// Moment shown for a job: actual start when present, otherwise the schedule.
/// Displayed on the Dubai wall clock used across the technician app.
DateTime? queueMoment(JobSummary job) {
  final started = job.startedAt;
  final raw = started != null && started.isNotEmpty
      ? started
      : (job.scheduledAt ?? '');
  return parseWallTime(raw);
}

/// Local-midnight key for grouping, or null when the job has no date.
DateTime? queueDayKey(JobSummary job) {
  final moment = queueMoment(job);
  if (moment == null) {
    return null;
  }
  return DateTime(moment.year, moment.month, moment.day);
}

String _localeName(String locale) {
  final language = locale.split(RegExp(r'[_-]')).first.toLowerCase();
  return language == 'ar' ? 'ar' : 'en';
}

DateFormat _format(String pattern, String locale) {
  try {
    return DateFormat(pattern, _localeName(locale));
  } on Exception {
    return DateFormat(pattern, 'en');
  }
}

String queueTimeLabel(JobSummary job) {
  final moment = queueMoment(job);
  if (moment == null) {
    return '';
  }
  // Western digits for times, matching the app's Arabic digit convention.
  return _format('HH:mm', 'en').format(moment);
}

String queueDateFormat(DateTime day, String locale, {bool weekday = true}) =>
    _format(weekday ? 'EEE d MMM' : 'd MMM', locale).format(day);

DateTime queueTodayKey([DateTime? now]) {
  final dubai = (now ?? DateTime.now()).toUtc().add(technicianDubaiOffset);
  return DateTime(dubai.year, dubai.month, dubai.day);
}

String queueWeekdayShort(DateTime day, String locale) =>
    _format('EEE', locale).format(day);

String queueDayNumber(DateTime day) => _format('d', 'en').format(day);

String queueDayLabel(
  DateTime? day,
  UiStrings t,
  String locale, {
  DateTime? now,
}) {
  if (day == null) {
    return t(TechnicianKeys.technicianQueued);
  }
  final todayKey = queueTodayKey(now);
  final difference = day.difference(todayKey).inDays;
  if (difference == 0) {
    return t(TechnicianKeys.dashboardToday, {
      'date': queueDateFormat(day, locale, weekday: false),
    });
  }
  return queueDateFormat(day, locale);
}

/// Group order: today, upcoming (ascending), past (descending), no date.
List<QueueDaySection> groupQueueJobs(List<JobSummary> jobs, {DateTime? now}) {
  final todayKey = queueTodayKey(now);
  final buckets = <DateTime, List<JobSummary>>{};
  final undated = <JobSummary>[];

  for (final job in jobs) {
    final key = queueDayKey(job);
    if (key == null) {
      undated.add(job);
    } else {
      buckets.putIfAbsent(key, () => <JobSummary>[]).add(job);
    }
  }

  final upcoming = buckets.keys.where((key) => key.isAfter(todayKey)).toList()
    ..sort();
  final past = buckets.keys.where((key) => key.isBefore(todayKey)).toList()
    ..sort((a, b) => b.compareTo(a));
  final ordered = <DateTime>[
    if (buckets.containsKey(todayKey)) todayKey,
    ...upcoming,
    ...past,
  ];

  return [
    for (final key in ordered)
      QueueDaySection(
        day: key,
        jobs: buckets[key]!
          ..sort((a, b) {
            final left = queueMoment(a);
            final right = queueMoment(b);
            if (left == null || right == null) {
              return 0;
            }
            return left.compareTo(right);
          }),
      ),
    if (undated.isNotEmpty) QueueDaySection(day: null, jobs: undated),
  ];
}

class QueueDaySection {
  const QueueDaySection({required this.day, required this.jobs});

  final DateTime? day;
  final List<JobSummary> jobs;
}
