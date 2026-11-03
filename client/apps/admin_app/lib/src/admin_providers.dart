import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/models.dart';
import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminApiProvider = Provider<AdminApi>((ref) {
  return HttpAdminApi(
    ref.watch(apiClientProvider),
    ref.watch(apiEndpointsProvider),
  );
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
