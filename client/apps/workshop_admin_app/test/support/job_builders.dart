import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'job_fixtures.dart';

/// Builders for widget tests: every model still comes **from JSON**, so a test
/// can never silently depend on a constructor that production does not use.
CleanJob cleanJob({Map<String, dynamic> overrides = const {}}) =>
    CleanJob.fromJson(<String, dynamic>{...cleanJobJson, ...overrides});

/// A page whose totals default to its contents (override to simulate paging).
JobPage jobPage(
  List<CleanJob> items, {
  int page = 0,
  int? size,
  int? total,
  int? totalPages,
}) {
  final pageSize = size ?? (items.isEmpty ? 10 : items.length);
  final pageTotal = total ?? items.length;
  return JobPage(
    items: items,
    page: page,
    size: pageSize,
    total: pageTotal,
    totalPages:
        totalPages ?? (pageTotal == 0 ? 0 : (pageTotal / pageSize).ceil()),
  );
}

/// A counts payload that is a true partition: pass the nine statuses you care
/// about, the rest default to 0, and `total` is computed unless overridden.
CleanJobCounts cleanCounts({
  int draft = 0,
  int scheduled = 0,
  int assigned = 0,
  int inProgress = 0,
  int pendingReview = 0,
  int approved = 0,
  int published = 0,
  int rejected = 0,
  int cancelled = 0,
  int? total,
}) => CleanJobCounts.fromJson(<String, dynamic>{
  'draft': draft,
  'scheduled': scheduled,
  'assigned': assigned,
  'inProgress': inProgress,
  'pendingReview': pendingReview,
  'approved': approved,
  'published': published,
  'rejected': rejected,
  'cancelled': cancelled,
  'total':
      total ??
      draft +
          scheduled +
          assigned +
          inProgress +
          pendingReview +
          approved +
          published +
          rejected +
          cancelled,
});
