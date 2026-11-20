import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'reference_admin_api.dart';
import 'reference_repository.dart';
import 'reference_store.dart';

/// The HTTP client used for reference data. Apps override this once with their
/// shared `ApiClient` (so auth/refresh/language headers apply).
final referenceApiProvider = Provider<ApiClient>((ref) {
  throw StateError(
    'referenceApiProvider must be overridden with the app ApiClient',
  );
});

/// Persistent cache. Defaults to in-memory; technician overrides it with
/// [SharedPreferencesReferenceStore] for offline work.
final referenceStoreProvider = Provider<ReferenceStore>((ref) {
  return InMemoryReferenceStore();
});

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepository(
    ref.watch(referenceApiProvider),
    store: ref.watch(referenceStoreProvider),
  );
});

final statusesProvider = FutureProvider.family<List<ReferenceRecord>, String>((
  ref,
  statusType,
) {
  return ref.watch(referenceRepositoryProvider).statuses(statusType);
});

final enumsProvider = FutureProvider.family<List<ReferenceRecord>, String>((
  ref,
  enumCode,
) {
  return ref.watch(referenceRepositoryProvider).enums(enumCode);
});

final transitionsProvider = FutureProvider.family<StatusTransitions, String>((
  ref,
  entity,
) {
  return ref.watch(referenceRepositoryProvider).transitions(entity);
});

final dropdownProvider = FutureProvider.family<List<ReferenceValue>, String>((
  ref,
  setCode,
) {
  return ref.watch(referenceRepositoryProvider).dropdown(setCode);
});

/// Platform-only reads that include drafts.
final adminStatusesProvider =
    FutureProvider.family<List<ReferenceRecord>, String>((ref, statusType) {
      return ref
          .watch(referenceRepositoryProvider)
          .statuses(statusType, includeDraft: true);
    });

final adminEnumsProvider = FutureProvider.family<List<ReferenceRecord>, String>(
  (ref, enumCode) {
    return ref
        .watch(referenceRepositoryProvider)
        .enums(enumCode, includeDraft: true);
  },
);

final transitionRulesProvider =
    FutureProvider.family<List<ReferenceTransition>, String>((ref, entity) {
      return ref.watch(referenceRepositoryProvider).transitionRules(entity);
    });

final referenceAdminProvider = Provider<ReferenceAdminActions>((ref) {
  return ReferenceAdminApi(ref.watch(referenceApiProvider));
});
