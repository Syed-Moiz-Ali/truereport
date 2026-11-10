/// Aggregate job counts for the caller's workshop (P6 counts endpoint).
///
/// Mirrors the server `JobCountsDto` shape (`counts`, `WorkshopJobController`)
/// field-for-field: counts only, no PII. `newScheduled` is the sum of `draft`
/// and `scheduled` (jobs not yet started). `finalizedToday` counts finalized
/// jobs whose finalization date falls on the current date in Asia/Dubai.
///
/// `active` is derived client-side as `assigned + inProgress` (jobs with an
/// owner or work started). The endpoint exposes no `active` field, so the
/// derivation is documented here and in the F3-A Step 3 report.
class JobCounts {
  const JobCounts({
    required this.draft,
    required this.scheduled,
    required this.newScheduled,
    required this.assigned,
    required this.inProgress,
    required this.readyToFinalize,
    required this.finalized,
    required this.finalizedToday,
    required this.cancelled,
    required this.total,
  });

  final int draft;
  final int scheduled;
  final int newScheduled;
  final int assigned;
  final int inProgress;
  final int readyToFinalize;
  final int finalized;
  final int finalizedToday;
  final int cancelled;
  final int total;

  /// Jobs currently owned or being worked, derived from existing fields.
  int get active => assigned + inProgress;

  static int _asInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  factory JobCounts.fromJson(Map<String, dynamic> json) => JobCounts(
    draft: _asInt(json, 'draft'),
    scheduled: _asInt(json, 'scheduled'),
    newScheduled: _asInt(json, 'newScheduled'),
    assigned: _asInt(json, 'assigned'),
    inProgress: _asInt(json, 'inProgress'),
    readyToFinalize: _asInt(json, 'readyToFinalize'),
    finalized: _asInt(json, 'finalized'),
    finalizedToday: _asInt(json, 'finalizedToday'),
    cancelled: _asInt(json, 'cancelled'),
    total: _asInt(json, 'total'),
  );
}
