import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/job_counts.dart';
import 'package:admin_app/src/models.dart';
import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminApiProvider = Provider<AdminApi>((ref) {
  return HttpAdminApi(
    ref.watch(apiClientProvider),
    ref.watch(apiEndpointsProvider),
  );
});

/// Release guard (Step 2a): the Figma showcase views under `screens/f3a`
/// and `screens/f3b` still carry fixture copy and unwired actions. They
/// render only when this is true: debug/test builds, or release builds
/// started with `--dart-define=ADMIN_FIGMA_SHOWCASE=true` (used by the
/// fidelity capture tests). The default release build renders
/// provider-driven states instead, so no sample-data screen is reachable
/// in release. Each per-screen step removes its own guard row.
final adminShowcaseProvider = Provider<bool>((ref) {
  var debug = false;
  assert(() {
    debug = true;
    return true;
  }());
  if (debug) {
    return true;
  }
  return const bool.fromEnvironment('ADMIN_FIGMA_SHOWCASE');
});

final hierarchyProvider = FutureProvider.autoDispose
    .family<HierarchyResponse, String>((ref, key) {
      final parts = key.split('\u0001');
      return ref
          .watch(adminApiProvider)
          .hierarchy(
            search: parts.isEmpty ? '' : parts[0],
            status: parts.length > 1 ? parts[1] : '',
          );
    });

final workshopDetailProvider = FutureProvider.autoDispose
    .family<HierarchyWorkshop, String>((ref, id) {
      return ref.watch(adminApiProvider).workshopDetail(id);
    });

final auditProvider = FutureProvider.autoDispose<List<AuditEvent>>((ref) {
  return ref.watch(adminApiProvider).auditEvents();
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(adminApiProvider).categories();
});

final itemsProvider = FutureProvider.autoDispose
    .family<List<ItemSummary>, String>((ref, key) {
      final parts = key.split('\u0001');
      return ref
          .watch(adminApiProvider)
          .items(
            search: parts.isEmpty ? '' : parts[0],
            categoryId: parts.length > 1 ? parts[1] : '',
            status: parts.length > 2 ? parts[2] : '',
          );
    });

final itemDetailProvider = FutureProvider.autoDispose
    .family<ItemDetail, String>((ref, id) {
      return ref.watch(adminApiProvider).itemDetail(id);
    });

final reasonsProvider = FutureProvider.autoDispose<List<Reason>>((ref) {
  return ref.watch(adminApiProvider).reasons();
});

final equipmentProvider = FutureProvider.autoDispose<List<Equipment>>((ref) {
  return ref.watch(adminApiProvider).equipment();
});

final guideImagesProvider = FutureProvider.autoDispose<List<GuideImage>>((ref) {
  return ref.watch(adminApiProvider).guideImages();
});

final staffProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) {
  return ref.watch(adminApiProvider).staff();
});

final jobsProvider = FutureProvider.autoDispose
    .family<List<WorkshopJob>, String>((ref, key) {
      final parts = key.split('\u0001');
      return ref
          .watch(adminApiProvider)
          .jobs(
            search: parts.isEmpty ? '' : parts[0],
            status: parts.length > 1 ? parts[1] : '',
          );
    });

final jobCountsProvider = FutureProvider.autoDispose<JobCounts>((ref) {
  return ref.watch(adminApiProvider).jobCounts();
});

final workshopCategoriesProvider = FutureProvider.autoDispose<List<Category>>((
  ref,
) {
  return ref.watch(adminApiProvider).workshopCategories();
});

final publishedItemsProvider = FutureProvider.autoDispose
    .family<List<PublishedItem>, String>((ref, key) {
      final parts = key.split('\u0001');
      return ref
          .watch(adminApiProvider)
          .publishedItems(
            search: parts.isEmpty ? '' : parts[0],
            categoryId: parts.length > 1 ? parts[1] : '',
          );
    });

final templatesProvider = FutureProvider.autoDispose<List<TemplateSummary>>((
  ref,
) {
  return ref.watch(adminApiProvider).templates();
});

final templateDetailProvider = FutureProvider.autoDispose
    .family<TemplateDetail, String>((ref, id) {
      return ref.watch(adminApiProvider).templateDetail(id);
    });

final templateVersionOptionsProvider =
    FutureProvider.autoDispose<List<TemplateVersionOption>>((ref) {
      return ref.watch(adminApiProvider).templateVersionOptions();
    });

final templateVersionProvider = FutureProvider.autoDispose
    .family<TemplateVersionView, String>((ref, key) {
      final parts = key.split('\u0001');
      return ref
          .watch(adminApiProvider)
          .templateVersion(parts[0], parts.length > 1 ? parts[1] : '');
    });

final reportProvider = FutureProvider.autoDispose.family<ReportAdmin, String>((
  ref,
  jobId,
) {
  return ref.watch(adminApiProvider).report(jobId);
});

final reportDeliveriesProvider = FutureProvider.autoDispose
    .family<List<ReportDelivery>, String>((ref, jobId) {
      return ref.watch(adminApiProvider).deliveries(jobId);
    });
