import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

final adminApiProvider = Provider<AdminApi>((ref) {
  return HttpAdminApi(
    ref.watch(apiClientProvider),
    ref.watch(apiEndpointsProvider),
  );
});

/// The client slice of the one shared UI-message system.
const String adminUiMessageClient = UiMessageClients.workshopAdmin;

/// Thin wiring: turns the shared `ApiClient` into the shared fetcher.
///
/// All language state lives in `packages/l10n`; this app owns no language
/// provider, list or selector of its own.
final adminUiMessageFetcherProvider = Provider<UiMessageFetcher>((ref) {
  final client = ref.watch(apiClientProvider);
  return (String path, Map<String, String> query) async {
    final data = await client.getDynamic(path, query: query);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('UI message payload is not an object');
  };
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

/// Customer delivery channels the server can actually deliver on.
///
/// The sheet must never offer a channel the backend cannot send (WhatsApp/SMS
/// dead-letter without a provider). Failure/loading falls back to EMAIL only.
final deliveryChannelsProvider = FutureProvider<List<DeliveryChannelOption>>((
  ref,
) {
  return ref.watch(adminApiProvider).deliveryChannels();
});

/// LIVE content languages from the registry, used for customer delivery.
///
/// The UI-message manifest only lists languages with a static catalog file;
/// delivery language must follow the registry so a newly live language works
/// before its UI catalog exists.
final workshopLanguagesProvider = FutureProvider<List<WorkshopLanguage>>((
  ref,
) async {
  final languages = await ref.watch(adminApiProvider).i18nLanguages();
  return languages
      .where((language) => language.active && language.isLive)
      .toList(growable: false);
});
