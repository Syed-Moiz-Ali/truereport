/// Pure queue logic for the technician jobs list.
///
/// Grouping, verbs and counts live here so the widget tree has no date
/// arithmetic and every rule can be pinned by a unit test. There are no
/// widget imports: the only dependencies are the API model and the shared
/// queue formatters (`queueMoment`/`queueDayKey`), so the day a job prints
/// and the day it is bucketed under can never disagree.
library;

import '../../../inspection_models.dart';
import 'jobs_queue_format.dart';

/// The primary action a row offers for its job.
enum QueueVerb {
  /// Assigned but not started yet.
  start,

  /// Already running and not every item is assessed.
  continueJob,

  /// Every item is assessed; the next step is the summary/sign-off.
  finish,

  /// Read-only: waiting on review, completed, cancelled or an unknown state.
  view,
}

/// The three agenda views of the shift board. Pure presentation state, kept
/// here so the page and its widgets share one enum.
enum ShiftTab { today, upcoming, unfinished }

/// The queue split into the five sections the screen renders.
///
/// Cancelled jobs are deliberately absent from every section: they are still
/// carried in [cancelled] so the filter can show `Cancelled · n` and no work
/// is silently lost. Ordering inside each list is the order the screen paints:
/// live/soonest first, unfinished latest-first, done-today latest-first.
class QueueBuckets {
  const QueueBuckets({
    required this.now,
    required this.today,
    required this.upcoming,
    required this.unfinished,
    required this.doneToday,
    required this.cancelled,
  });

  /// Jobs in progress right now, regardless of their scheduled day.
  final List<JobSummary> now;
  final List<JobSummary> today;
  final List<JobSummary> upcoming;

  /// Assigned work dated before today, plus undated work.
  final List<JobSummary> unfinished;
  final List<JobSummary> doneToday;
  final List<JobSummary> cancelled;

  /// Every job this screen can render, in section order.
  List<JobSummary> get visible => <JobSummary>[
    ...now,
    ...today,
    ...upcoming,
    ...unfinished,
    ...doneToday,
  ];

  /// True when every section is empty (cancelled jobs do not count).
  bool get isEmpty =>
      now.isEmpty &&
      today.isEmpty &&
      upcoming.isEmpty &&
      unfinished.isEmpty &&
      doneToday.isEmpty;

  int get cancelledCount => cancelled.length;

  /// Jobs whose next step is [QueueVerb.start].
  int get toStartCount =>
      visible.where((job) => verbFor(job) == QueueVerb.start).length;

  /// Jobs already started (including ones whose items are all assessed).
  int get inProgressCount => visible.where((job) {
    final verb = verbFor(job);
    return verb == QueueVerb.continueJob || verb == QueueVerb.finish;
  }).length;
}

/// A cancelled job never appears in NOW/TODAY/UPCOMING/UNFINISHED.
bool isCancelledJob(JobSummary job) => job.status == 'CANCELLED';

/// True for jobs waiting on review or already finalized.
///
/// Item completion alone does not make a job done: an `IN_PROGRESS` job whose
/// items are all assessed still needs its summary/signature, so it stays
/// actionable until the status itself moves on.
bool isDoneJob(JobSummary job) {
  switch (job.status) {
    case 'PENDING_REVIEW':
    case 'APPROVED':
    case 'PUBLISHED':
    case 'COMPLETED':
    case 'REJECTED':
      return true;
    default:
      return false;
  }
}

/// What the row's (and the Now card's) primary action does.
///
/// This is behaviour, never copy: the label is resolved from the served
/// taxonomy/bundle by the widgets. An unknown status is treated as read-only
/// rather than implying the job can still be edited.
// gate-allow: behaviour — status -> verb is behaviour, not a label or tone.
QueueVerb verbFor(JobSummary job) {
  switch (job.status) {
    case 'IN_PROGRESS':
      final allAssessed =
          job.totalItems > 0 && job.completedItems >= job.totalItems;
      return allAssessed ? QueueVerb.finish : QueueVerb.continueJob;
    case 'ASSIGNED':
    case 'SCHEDULED':
    case 'DRAFT':
      return QueueVerb.start;
    default:
      return QueueVerb.view;
  }
}

/// The job the Now card should show.
///
/// Priority: an in-progress job (the technician is already on it, even when a
/// scheduled job is due earlier), then the earliest job due today, then the
/// earliest overdue job (or an undated job). Overdue work is what "now" means
/// when today is empty — the old day rail made those jobs unreachable, and
/// they are still the technician's responsibility. A future-only queue has no
/// Now card at all.
JobSummary? nowJob(List<JobSummary> jobs, {DateTime? now}) {
  final today = queueTodayKey(now);
  JobSummary? live;
  JobSummary? next;
  JobSummary? overdue;

  for (final job in jobs) {
    if (isCancelledJob(job) || isDoneJob(job)) {
      continue;
    }
    final moment = queueMoment(job);

    if (job.status == 'IN_PROGRESS') {
      if (live == null || _isEarlier(moment, queueMoment(live))) {
        live = job;
      }
      continue;
    }

    final day = queueDayKey(job);
    if (day == null) {
      overdue ??= job;
      continue;
    }
    if (_isSameDay(day, today)) {
      if (next == null || _isEarlier(moment, queueMoment(next))) {
        next = job;
      }
      continue;
    }
    if (day.isAfter(today)) {
      continue;
    }
    if (overdue == null || _isEarlier(moment, queueMoment(overdue))) {
      overdue = job;
    }
  }

  return live ?? next ?? overdue;
}

/// The closest day that still has actionable work, or null.
///
/// Cancelled and finished jobs are not work. A tie between a past and a future
/// day prefers the future day, because that is what comes next. Undated jobs
/// are skipped: they cannot be navigated to by date.
DateTime? nearestDayWithWork(List<JobSummary> jobs, {DateTime? now}) {
  final today = queueTodayKey(now);
  DateTime? best;
  var bestDistance = 0;

  for (final job in jobs) {
    if (isCancelledJob(job) || isDoneJob(job)) {
      continue;
    }
    final day = queueDayKey(job);
    if (day == null) {
      continue;
    }
    final distance = _dayDistance(day, today);
    final future = day.isAfter(today);
    final bestFuture = best != null && best.isAfter(today);
    if (best == null ||
        distance < bestDistance ||
        (distance == bestDistance && future && !bestFuture)) {
      best = day;
      bestDistance = distance;
    }
  }

  return best;
}

/// Splits [jobs] into the queue sections, excluding and counting cancellations.
///
/// [now] is an instant (defaults to `DateTime.now()`); the Dubai day is derived
/// from it, so pass an instant rather than a local-midnight key.
///
/// A job lands in exactly one section:
/// * cancelled -> [QueueBuckets.cancelled] only;
/// * in progress -> [QueueBuckets.now] (even if it is dated in the past);
/// * done today -> [QueueBuckets.doneToday] (done on another day is not shown);
/// * dated before today or undated -> [QueueBuckets.unfinished];
/// * dated today -> [QueueBuckets.today];
/// * dated after today -> [QueueBuckets.upcoming].
QueueBuckets groupJobs(List<JobSummary> jobs, {DateTime? now}) {
  final today = queueTodayKey(now);
  final live = <JobSummary>[];
  final todayJobs = <JobSummary>[];
  final upcoming = <JobSummary>[];
  final unfinished = <JobSummary>[];
  final done = <JobSummary>[];
  final cancelled = <JobSummary>[];

  for (final job in jobs) {
    if (isCancelledJob(job)) {
      cancelled.add(job);
      continue;
    }
    if (isDoneJob(job)) {
      final day = queueDayKey(job);
      if (day != null && _isSameDay(day, today)) {
        done.add(job);
      }
      continue;
    }
    if (job.status == 'IN_PROGRESS') {
      live.add(job);
      continue;
    }

    final day = queueDayKey(job);
    if (day == null) {
      unfinished.add(job);
    } else if (_isSameDay(day, today)) {
      todayJobs.add(job);
    } else if (day.isAfter(today)) {
      upcoming.add(job);
    } else {
      unfinished.add(job);
    }
  }

  live.sort(_ascendingMoment);
  todayJobs.sort(_ascendingMoment);
  upcoming.sort(_ascendingMoment);
  unfinished.sort(_descendingMoment);
  done.sort(_descendingMoment);
  cancelled.sort(_descendingMoment);

  return QueueBuckets(
    now: List<JobSummary>.unmodifiable(live),
    today: List<JobSummary>.unmodifiable(todayJobs),
    upcoming: List<JobSummary>.unmodifiable(upcoming),
    unfinished: List<JobSummary>.unmodifiable(unfinished),
    doneToday: List<JobSummary>.unmodifiable(done),
    cancelled: List<JobSummary>.unmodifiable(cancelled),
  );
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int _dayDistance(DateTime a, DateTime b) => DateTime.utc(
  a.year,
  a.month,
  a.day,
).difference(DateTime.utc(b.year, b.month, b.day)).inDays.abs();

bool _isEarlier(DateTime? a, DateTime? b) {
  if (a == null) {
    return false;
  }
  if (b == null) {
    return true;
  }
  return a.isBefore(b);
}

int _ascendingMoment(JobSummary left, JobSummary right) =>
    _compareMoment(left, right);

int _descendingMoment(JobSummary left, JobSummary right) =>
    _compareMoment(left, right, descending: true);

/// Compares by the moment the row prints. Undated jobs always trail, whichever
/// direction the section is sorted in.
int _compareMoment(
  JobSummary left,
  JobSummary right, {
  bool descending = false,
}) {
  final a = queueMoment(left);
  final b = queueMoment(right);
  if (a == null || b == null) {
    if (a == null && b == null) {
      return 0;
    }
    return a == null ? 1 : -1;
  }
  final result = a.compareTo(b);
  return descending ? -result : result;
}
