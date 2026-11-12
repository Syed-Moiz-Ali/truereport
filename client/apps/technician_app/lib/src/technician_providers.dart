import 'package:auth/auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:technician_app/src/inspection_models.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/offline/offline_store.dart';
import 'package:technician_app/src/offline/sync_service.dart';
import 'package:technician_app/src/technician_api.dart';

final technicianApiProvider = Provider<TechnicianApi>((ref) {
  return HttpTechnicianApi(
    ref.watch(apiClientProvider),
    ref.watch(apiEndpointsProvider),
  );
});

final offlineStoreProvider = Provider<OfflineStore>((ref) {
  final store = DriftOfflineStore();
  ref.onDispose(store.close);
  return store;
});

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (results) => results.any((result) => result != ConnectivityResult.none),
  );
});

final pendingSyncCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(offlineStoreProvider).pendingCount();
});

final pendingOperationsProvider =
    FutureProvider.autoDispose<List<SyncOperation>>((ref) {
      return ref.watch(offlineStoreProvider).pendingOperations();
    });

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(technicianApiProvider),
    ref.watch(offlineStoreProvider),
  );
});

final technicianJobsProvider = FutureProvider.autoDispose<List<TechnicianJob>>((
  ref,
) async {
  final store = ref.watch(offlineStoreProvider);
  try {
    final jobs = await ref.watch(technicianApiProvider).jobs();
    await store.saveJobs(jobs);
    return jobs;
  } on Object {
    final cached = await store.loadJobs();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    rethrow;
  }
});

final technicianJobProvider = FutureProvider.autoDispose
    .family<TechnicianJob, String>((ref, id) async {
      final store = ref.watch(offlineStoreProvider);
      try {
        final job = await ref.watch(technicianApiProvider).job(id);
        await store.saveJob(job);
        return job;
      } on Object {
        final cached = await store.loadJob(id);
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    });

final technicianTemplateVersionsProvider =
    FutureProvider.autoDispose<List<TemplateVersionOption>>((ref) {
      return ref.watch(technicianApiProvider).templateVersions();
    });

final inspectionChecklistProvider = FutureProvider.autoDispose
    .family<InspectionChecklist, String>((ref, id) async {
      final store = ref.watch(offlineStoreProvider);
      try {
        final checklist = await ref.watch(technicianApiProvider).checklist(id);
        await store.saveChecklist(checklist);
        return checklist;
      } on Object {
        final cached = await store.loadChecklist(id);
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    });

final inspectionReviewProvider = FutureProvider.autoDispose
    .family<ReviewResult, String>((ref, id) {
      return ref.watch(technicianApiProvider).review(id);
    });

final technicianReportProvider = FutureProvider.autoDispose
    .family<TechnicianReportStatus, String>((ref, jobId) {
      return ref.watch(technicianApiProvider).reportStatus(jobId);
    });

final technicianDeliveriesProvider = FutureProvider.autoDispose
    .family<List<TechnicianDelivery>, String>((ref, jobId) {
      return ref.watch(technicianApiProvider).deliveries(jobId);
    });

// ------------------------------------------------- clean technician API
typedef TechnicianJobsQuery = ({int page, int size, String? status});

typedef TechnicianEvidenceQuery = ({String jobId, String itemCode});

final technicianJobPageProvider = FutureProvider.autoDispose
    .family<JobSummaryPage, TechnicianJobsQuery>((ref, query) {
      return ref
          .watch(technicianApiProvider)
          .technicianJobs(
            page: query.page,
            size: query.size,
            status: query.status,
          );
    });

final technicianJobSummaryProvider = FutureProvider.autoDispose
    .family<JobSummary, String>((ref, id) {
      return ref.watch(technicianApiProvider).technicianJob(id);
    });

final technicianChecklistProvider = FutureProvider.autoDispose
    .family<Checklist, String>((ref, jobId) {
      return ref.watch(technicianApiProvider).cleanChecklist(jobId);
    });

final technicianSummaryProvider = FutureProvider.autoDispose
    .family<Summary, String>((ref, jobId) {
      return ref.watch(technicianApiProvider).summary(jobId);
    });

final technicianReviewProvider = FutureProvider.autoDispose
    .family<Review, String>((ref, jobId) {
      return ref.watch(technicianApiProvider).cleanReview(jobId);
    });

final technicianEvidenceListProvider = FutureProvider.autoDispose
    .family<List<Evidence>, TechnicianEvidenceQuery>((ref, query) {
      return ref
          .watch(technicianApiProvider)
          .evidenceList(query.jobId, query.itemCode);
    });

final syncQueueStatusProvider = FutureProvider.autoDispose<SyncQueueStatus>((
  ref,
) {
  return ref.watch(offlineStoreProvider).syncQueueStatus();
});
