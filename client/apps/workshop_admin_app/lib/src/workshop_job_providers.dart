import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Key encoding for the clean jobs query: page\u0001size\u0001status\u0001
/// search\u0001from\u0001to. Missing trailing parts default to empty values.
String cleanJobsKey({
  int page = 0,
  int size = 10,
  String status = '',
  String search = '',
  String from = '',
  String to = '',
}) => '$page\u0001$size\u0001$status\u0001$search\u0001$from\u0001$to';

final availableTemplatesProvider = FutureProvider.autoDispose<
  List<AvailableTemplate>
>((ref) {
  return ref.watch(adminApiProvider).availableTemplates();
});

final jobTemplateDetailProvider = FutureProvider.autoDispose
    .family<JobTemplateDetail, String>((ref, versionId) {
      return ref.watch(adminApiProvider).templateVersionDetail(versionId);
    });

final cleanJobsProvider = FutureProvider.autoDispose.family<JobPage, String>((
  ref,
  key,
) {
  final parts = key.split('\u0001');
  int at(int index, int fallback) =>
      index < parts.length ? int.tryParse(parts[index]) ?? fallback : fallback;
  String text(int index) => index < parts.length ? parts[index] : '';
  return ref
      .watch(adminApiProvider)
      .cleanJobs(
        page: at(0, 0),
        size: at(1, 10),
        status: text(2),
        search: text(3),
        from: text(4),
        to: text(5),
      );
});

final cleanJobProvider = FutureProvider.autoDispose.family<CleanJob, String>((
  ref,
  id,
) {
  return ref.watch(adminApiProvider).cleanJob(id);
});

final cleanJobCountsProvider = FutureProvider.autoDispose<CleanJobCounts>((
  ref,
) {
  return ref.watch(adminApiProvider).cleanJobCounts();
});

final jobAssignmentsProvider = FutureProvider.autoDispose
    .family<List<JobAssignment>, String>((ref, jobId) {
      return ref.watch(adminApiProvider).jobAssignments(jobId);
    });

final jobReviewProvider = FutureProvider.autoDispose.family<JobReview, String>((
  ref,
  jobId,
) {
  return ref.watch(adminApiProvider).jobReview(jobId);
});

final publishChecklistProvider = FutureProvider.autoDispose
    .family<PublishChecklist, String>((ref, jobId) {
      return ref.watch(adminApiProvider).publishChecklist(jobId);
    });

final publicLinkProvider = FutureProvider.autoDispose.family<PublicLink, String>((
  ref,
  jobId,
) {
  return ref.watch(adminApiProvider).publicLink(jobId);
});

final jobQrProvider = FutureProvider.autoDispose.family<List<int>, String>((
  ref,
  jobId,
) {
  return ref.watch(adminApiProvider).jobQr(jobId);
});

final jobDocumentsProvider = FutureProvider.autoDispose
    .family<List<JobDocument>, String>((ref, jobId) {
      return ref.watch(adminApiProvider).jobDocuments(jobId);
    });

final notificationsProvider = FutureProvider.autoDispose
    .family<List<WorkshopNotification>, bool>((ref, unreadOnly) {
      return ref.watch(adminApiProvider).notifications(unreadOnly: unreadOnly);
    });
