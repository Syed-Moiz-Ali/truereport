/// Pure set logic for the deck page's Today / Upcoming / Unfinished tabs.
///
/// Grouping, ordering and front-card resolution live here so the widget tree
/// carries no date arithmetic and every rule is pinned by a unit test. The
/// only dependencies are the shared queue rules (`isCancelledJob`,
/// `isDoneJob`, `verbFor`, `queueLiveJobId`) and the formatters, so the day a
/// job prints and the tab it lands in can never disagree.
library;

import 'package:technician_app/src/inspection_models.dart';

import '../jobs_queue_format.dart';
import '../queue_model.dart';

/// The deck set switcher: Today / Upcoming / Unfinished with counts.
///
/// The tabs re-bucket the already-loaded page; they never fetch. Cancelled
/// jobs never appear in any bucket.
enum DeckTab { today, upcoming, unfinished }

/// One bucket per tab, in paint order.
class DeckSets {
  const DeckSets({
    required this.today,
    required this.upcoming,
    required this.unfinished,
  });

  final List<JobSummary> today;
  final List<JobSummary> upcoming;
  final List<JobSummary> unfinished;

  List<JobSummary> forTab(DeckTab tab) {
    switch (tab) {
      case DeckTab.today:
        return today;
      case DeckTab.upcoming:
        return upcoming;
      case DeckTab.unfinished:
        return unfinished;
    }
  }
}

/// Splits [jobs] into the three deck buckets.
///
/// Cancelled jobs land nowhere. Done jobs stay visible only when they were
/// done today; older finished work is not anyone's ramp. Undated work needs
/// attention, so it waits in Unfinished with the overdue past.
DeckSets bucketDeckSets(List<JobSummary> jobs, DateTime today) {
  final dayJobs = <JobSummary>[];
  final upcoming = <JobSummary>[];
  final unfinished = <JobSummary>[];
  for (final job in jobs) {
    if (isCancelledJob(job)) {
      continue;
    }
    final day = queueDayKey(job);
    if (isDoneJob(job)) {
      if (day != null && _sameDay(day, today)) {
        dayJobs.add(job);
      }
      continue;
    }
    if (day == null) {
      unfinished.add(job);
    } else if (_sameDay(day, today)) {
      dayJobs.add(job);
    } else if (day.isAfter(today)) {
      upcoming.add(job);
    } else {
      unfinished.add(job);
    }
  }
  return DeckSets(today: dayJobs, upcoming: upcoming, unfinished: unfinished);
}

/// Time-ascending copy; undated jobs trail.
List<JobSummary> orderDeckJobs(List<JobSummary> jobs) {
  final ordered = List<JobSummary>.of(jobs);
  ordered.sort((a, b) {
    final left = queueMoment(a);
    final right = queueMoment(b);
    if (left == null || right == null) {
      return left == null && right == null ? 0 : (left == null ? 1 : -1);
    }
    return left.compareTo(right);
  });
  return ordered;
}

/// The card on top: the technician's explicit selection when it is still in
/// the set, otherwise the live job, otherwise the earliest.
String deckFrontId(List<JobSummary> ordered, String? selectedId) {
  assert(ordered.isNotEmpty);
  if (selectedId != null && ordered.any((job) => job.id == selectedId)) {
    return selectedId;
  }
  return queueLiveJobId(ordered) ?? ordered.first.id;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
