import 'package:auth/auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/features/inspection/evidence_capture_service.dart';
import 'package:technician_app/src/inspection_models.dart';
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

/// The client slice of the one shared UI-message system.
const String technicianUiMessageClient = UiMessageClients.technician;

/// Thin wiring: turns the shared `ApiClient` into the shared fetcher.
///
/// All language state lives in `packages/t`; this app owns no language
/// provider, list or selector of its own.
final technicianUiMessageFetcherProvider = Provider<UiMessageFetcher>((ref) {
  final client = ref.watch(apiClientProvider);
  return (String path, Map<String, String> query) async {
    final data = await client.getDynamic(path, query: query);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('UI message payload is not an object');
  };
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

// ------------------------------------------------- clean technician API
typedef TechnicianJobsQuery = ({int page, int size, String? status});

typedef TechnicianEvidenceQuery = ({String jobId, String itemCode});

final technicianJobPageProvider = FutureProvider.autoDispose
    .family<JobSummaryPage, TechnicianJobsQuery>((ref, query) async {
      final store = ref.watch(offlineStoreProvider);
      final key = '${query.page}:${query.size}:${query.status ?? ''}';
      try {
        final page = await ref
            .watch(technicianApiProvider)
            .technicianJobs(
              page: query.page,
              size: query.size,
              status: query.status,
            );
        await store.saveCleanJobsPage(key, page);
        return page;
      } on Object catch (error) {
        if (!isNetworkFailure(error)) {
          rethrow;
        }
        final cached = await store.loadCleanJobsPage(key);
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    });

final technicianJobSummaryProvider = FutureProvider.autoDispose
    .family<JobSummary, String>((ref, id) {
      return ref.watch(technicianApiProvider).technicianJob(id);
    });

final technicianChecklistProvider = FutureProvider.autoDispose
    .family<Checklist, String>((ref, jobId) async {
      final store = ref.watch(offlineStoreProvider);
      try {
        final checklist = await ref
            .watch(technicianApiProvider)
            .cleanChecklist(jobId);
        await store.saveCleanChecklist(checklist);
        return checklist;
      } on Object catch (error) {
        if (!isNetworkFailure(error)) {
          rethrow;
        }
        final cached = await store.loadCleanChecklist(jobId);
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    });

/// Capture service used by the vehicle-photo gate.
///
/// Overridden in tests so the gate never touches a platform image picker.
final evidenceCaptureServiceProvider = Provider<EvidenceCaptureService>(
  (ref) => EvidenceCaptureService(),
);

/// The job's single report-cover photo, or null when the server answers 404.
final vehiclePhotoProvider = FutureProvider.autoDispose
    .family<VehiclePhoto?, String>((ref, jobId) {
      return ref.watch(technicianApiProvider).getVehiclePhoto(jobId);
    });

/// Bytes for the hub thumbnail. Only read when [vehiclePhotoProvider] has one.
final vehiclePhotoContentProvider = FutureProvider.autoDispose
    .family<List<int>, String>((ref, jobId) {
      return ref.watch(technicianApiProvider).vehiclePhotoContent(jobId);
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
    .family<List<Evidence>, TechnicianEvidenceQuery>((ref, query) async {
      final store = ref.watch(offlineStoreProvider);
      List<Evidence> server;
      try {
        server = await ref
            .watch(technicianApiProvider)
            .evidenceList(query.jobId, query.itemCode);
        await store.saveCleanEvidence(query.jobId, query.itemCode, server);
      } on Object catch (error) {
        if (!isNetworkFailure(error)) {
          rethrow;
        }
        server =
            await store.loadCleanEvidence(query.jobId, query.itemCode) ??
            const <Evidence>[];
      }
      final local = await store.evidenceForItem(query.jobId, query.itemCode);
      final queued = local
          .where((value) => value.state != 'RECEIVED')
          .map(
            (value) => Evidence(
              id: 'local-${value.id}',
              jobId: value.jobId,
              itemCode: value.itemId,
              type: value.type,
              status: 'PENDING',
              mime: value.mimeType,
              bytes: value.bytes.length,
              sha256: value.sha256,
              capturedAt: value.createdAt.toUtc().toIso8601String(),
              captureSource: value.captureSource,
              deviceId: value.deviceId,
              width: value.width,
              height: value.height,
              durationMs: value.durationMs,
              captionEn: value.captionEn,
              captionAr: value.captionAr,
              posterAvailable: value.posterBase64 != null,
              qualityStatus: null,
              contentUrl: null,
              createdAt: value.createdAt.toUtc().toIso8601String(),
            ),
          )
          .toList(growable: false);
      final seen = server
          .map((value) => value.sha256)
          .whereType<String>()
          .toSet();
      return <Evidence>[
        ...server,
        ...queued.where((value) => !seen.contains(value.sha256)),
      ];
    });

final syncQueueStatusProvider = FutureProvider.autoDispose<SyncQueueStatus>((
  ref,
) {
  return ref.watch(offlineStoreProvider).syncQueueStatus();
});
