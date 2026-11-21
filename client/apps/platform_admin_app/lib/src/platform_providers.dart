import 'package:auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import 'platform_api.dart';
import 'platform_catalogue_models.dart';
import 'platform_config_api.dart';
import 'platform_config_models.dart';
import 'platform_models.dart';

final platformApiProvider = Provider<PlatformAdminApi>((ref) {
  return HttpPlatformAdminApi(
    ref.watch(apiClientProvider),
    ref.watch(apiEndpointsProvider),
  );
});

final platformConfigApiProvider = Provider<PlatformConfigApi>((ref) {
  return PlatformConfigApi(
    ref.watch(apiClientProvider),
    ref.watch(apiEndpointsProvider),
  );
});

/// Shared language state. The platform app no longer owns a locale provider.
final platformLocaleProvider = localeProvider;

/// Remote-string wiring for [PlatformAdminApp].
///
/// Kept here (instead of `main.dart`) so the app entrypoint never imports
/// generated ARB accessors: only remote UI-message catalogs, the
/// Material/Widgets/Cupertino built-in delegates, and neutral placeholders.
Future<UiMessageStore> createPlatformUiMessageStore() => createUiMessageStore();

ProviderScope platformUiMessageScope({
  required UiMessageStore store,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      uiMessageStoreProvider.overrideWithValue(store),
      // Reference taxonomy uses the same authenticated client as the app.
      referenceApiProvider.overrideWith((ref) => ref.watch(apiClientProvider)),
      uiMessageFetcherProvider.overrideWith((ref) {
        final client = ref.watch(apiClientProvider);
        return (String path, Map<String, String> query) async {
          final data = await client.getDynamic(path, query: query);
          if (data is Map<String, dynamic>) return data;
          if (data is Map) return Map<String, dynamic>.from(data);
          throw const FormatException('UI message payload is not an object');
        };
      }),
    ],
    child: child,
  );
}

final platformUiReadyProvider = Provider<bool>((ref) {
  return ref.watch(uiMessageControllerProvider.select((state) => state.ready));
});

final platformUiManifestProvider = Provider<UiMessageManifest?>((ref) {
  return ref.watch(
    uiMessageControllerProvider.select((state) => state.manifest),
  );
});

final platformUiDefaultLanguageProvider = Provider<String>((ref) {
  return ref.watch(
    uiMessageControllerProvider.select((state) => state.defaultLanguage),
  );
});

const UiMessageKey _platformAppTitleKey = PlatformAdminKeys.headerTitle;

const String _platformAppIdTitle = 'truereport';

final platformAppTitleProvider = Provider<String>((ref) {
  if (!ref.watch(platformUiReadyProvider)) return _platformAppIdTitle;
  final resolved = ref.watch(uiStringsProvider).tKey(_platformAppTitleKey);
  if (resolved.isEmpty || resolved == _platformAppTitleKey.qualified) {
    return _platformAppIdTitle;
  }
  return resolved;
});

List<Locale> platformSupportedLocales(UiMessageManifest? manifest) {
  final codes = <String>[];
  if (manifest != null) {
    for (final code in manifest.codes) {
      if (!codes.contains(code)) codes.add(code);
    }
    if (!codes.contains(manifest.defaultLanguage)) {
      codes.add(manifest.defaultLanguage);
    }
  }
  if (codes.isEmpty) return const [Locale('en')];
  return codes.map(localeForLanguage).toList(growable: false);
}

Locale resolvePlatformLocale(
  Locale? device,
  Iterable<Locale> supported,
  String defaultLanguage,
) {
  final candidates = supported.toList(growable: false);
  final fallback = localeForLanguage(defaultLanguage);
  if (candidates.isEmpty) return fallback;
  if (device == null) {
    return _platformByCode(candidates, fallback) ?? candidates.first;
  }
  for (final candidate in candidates) {
    if (candidate.languageCode == device.languageCode &&
        candidate.scriptCode == device.scriptCode &&
        candidate.countryCode == device.countryCode) {
      return candidate;
    }
  }
  if (device.scriptCode != null) {
    for (final candidate in candidates) {
      if (candidate.languageCode == device.languageCode &&
          candidate.scriptCode == device.scriptCode) {
        return candidate;
      }
    }
  }
  for (final candidate in candidates) {
    if (candidate.languageCode == device.languageCode) return candidate;
  }
  return _platformByCode(candidates, fallback) ?? candidates.first;
}

Locale? _platformByCode(List<Locale> candidates, Locale fallback) {
  for (final candidate in candidates) {
    if (candidate.languageCode == fallback.languageCode &&
        candidate.scriptCode == fallback.scriptCode &&
        candidate.countryCode == fallback.countryCode) {
      return candidate;
    }
  }
  return null;
}

final uiStringsProvider = Provider<UiMessageStrings>((ref) {
  ref.watch(uiMessageControllerProvider);
  return ref.watch(uiMessageControllerProvider.notifier).strings();
});

final uiMessageSwitcherProvider = Provider<UiMessageSwitcher>((ref) {
  return UiMessageSwitcher(ref);
});

class UiMessageSwitcher {
  UiMessageSwitcher(this._ref);

  final Ref _ref;

  Future<bool> switchTo(String code) async {
    final controller = _ref.read(uiMessageControllerProvider.notifier);
    final switched = await controller.useLanguage(code);
    final active = _ref.read(uiMessageControllerProvider).activeLanguage;
    _ref.read(localeProvider.notifier).setLocale(localeForLanguage(active));
    _ref.read(apiClientProvider).acceptLanguage = active;
    return switched;
  }
}

final hierarchyStateProvider = FutureProvider.autoDispose<HierarchyResponse>(
  (ref) => ref.watch(platformApiProvider).hierarchy(),
);

// --------------------------------------------------------------------------
// Platform configuration providers
// --------------------------------------------------------------------------

@immutable
class ItemQuery {
  const ItemQuery({this.search = '', this.categoryId = '', this.status = ''});

  final String search;
  final String categoryId;
  final String status;

  @override
  bool operator ==(Object other) =>
      other is ItemQuery &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.status == status;

  @override
  int get hashCode => Object.hash(search, categoryId, status);
}

@immutable
class ItemVersionKey {
  const ItemVersionKey(this.itemId, this.versionId);

  final String itemId;
  final String versionId;

  @override
  bool operator ==(Object other) =>
      other is ItemVersionKey &&
      other.itemId == itemId &&
      other.versionId == versionId;

  @override
  int get hashCode => Object.hash(itemId, versionId);
}

@immutable
class ImpactKey {
  const ImpactKey(this.entityType, this.entityId);

  final String entityType;
  final String entityId;

  @override
  bool operator ==(Object other) =>
      other is ImpactKey &&
      other.entityType == entityType &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(entityType, entityId);
}

final categoriesProvider = FutureProvider.autoDispose<List<PlatformCategory>>(
  (ref) => ref.watch(platformConfigApiProvider).categories(),
);

final itemsProvider = FutureProvider.autoDispose
    .family<List<PlatformItem>, ItemQuery>(
      (ref, query) => ref
          .watch(platformConfigApiProvider)
          .items(
            search: query.search,
            categoryId: query.categoryId,
            status: query.status,
          ),
    );

final itemDetailProvider = FutureProvider.autoDispose
    .family<PlatformItemDetail, String>(
      (ref, itemId) => ref.watch(platformConfigApiProvider).itemDetail(itemId),
    );

final itemConfigProvider = FutureProvider.autoDispose
    .family<ItemConfig, ItemVersionKey>(
      (ref, key) => ref
          .watch(platformConfigApiProvider)
          .itemConfig(key.itemId, key.versionId),
    );

final optionSetsProvider = FutureProvider.autoDispose<List<OptionSet>>(
  (ref) => ref.watch(platformConfigApiProvider).optionSets(),
);

/// Per-set values, used when the catalogue summary omits the value rows.
final optionSetValuesProvider = FutureProvider.autoDispose
    .family<List<OptionValue>, String>(
      (ref, setId) =>
          ref.watch(platformConfigApiProvider).optionSetValues(setId),
    );

final documentTypesProvider =
    FutureProvider.autoDispose<List<ReportDocumentType>>(
      (ref) => ref.watch(platformConfigApiProvider).documentTypes(),
    );

final platformLanguagesProvider =
    FutureProvider.autoDispose<List<PlatformLanguage>>(
      (ref) => ref.watch(platformConfigApiProvider).platformLanguages(),
    );

final translationCoverageProvider =
    FutureProvider.autoDispose<TranslationCoverage>(
      (ref) => ref.watch(platformConfigApiProvider).translationCoverage(),
    );

/// Per-language publish readiness (UI text + dynamic content + blockers).
final readinessProvider = FutureProvider.autoDispose
    .family<LanguageReadiness, String>(
      (ref, code) => ref.watch(platformConfigApiProvider).readiness(code),
    );

final configHealthProvider = FutureProvider.autoDispose<ConfigHealth>(
  (ref) => ref.watch(platformConfigApiProvider).configHealth(),
);

final configReleasesProvider = FutureProvider.autoDispose<List<ConfigRelease>>(
  (ref) => ref.watch(platformConfigApiProvider).releases(),
);

final impactProvider = FutureProvider.autoDispose
    .family<ImpactAnalysis, ImpactKey>(
      (ref, key) => ref
          .watch(platformConfigApiProvider)
          .impact(key.entityType, key.entityId),
    );

class PlatformConfigActions {
  PlatformConfigActions(this._ref);

  final Ref _ref;

  PlatformConfigApi get _api => _ref.read(platformConfigApiProvider);

  void _invalidateAll() {
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(itemsProvider);
    _ref.invalidate(itemDetailProvider);
    _ref.invalidate(itemConfigProvider);
    _ref.invalidate(optionSetsProvider);
    _ref.invalidate(optionSetValuesProvider);
    _ref.invalidate(documentTypesProvider);
    _ref.invalidate(platformLanguagesProvider);
    _ref.invalidate(translationCoverageProvider);
    _ref.invalidate(readinessProvider);
    _ref.invalidate(configHealthProvider);
    _ref.invalidate(configReleasesProvider);
    _ref.invalidate(impactProvider);
  }

  /// Registry + coverage + readiness after a language registry write.
  ///
  /// The UI-message manifest is file-backed and cannot gain a language here,
  /// so the list must be refreshed from the registry, not the manifest.
  void _invalidateLanguages() {
    _ref.invalidate(platformLanguagesProvider);
    _ref.invalidate(translationCoverageProvider);
    _ref.invalidate(readinessProvider);
    _ref.invalidate(overviewProvider);
  }

  Future<PlatformLanguage> createLanguage({
    required String code,
    required String nativeName,
    required String direction,
  }) async {
    final result = await _api.createLanguage(
      code: code,
      nativeName: nativeName,
      direction: direction,
    );
    _invalidateLanguages();
    return result;
  }

  Future<PlatformLanguage> retireLanguage(String code) async {
    final result = await _api.retireLanguage(code);
    _invalidateLanguages();
    return result;
  }

  Future<SeedResult> seed() async {
    final result = await _api.seedDefaultChecklist();
    _invalidateAll();
    return result;
  }

  Future<PlatformCategory> saveCategory({
    String? id,
    required String code,
    required String name,
    required int sortOrder,
    bool active = true,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'name': name,
      'sortOrder': sortOrder,
      'active': active,
    };
    final result = id == null
        ? await _api.createCategory(body)
        : await _api.updateCategory(id, body);
    _invalidateAll();
    return result;
  }

  Future<void> retireCategory(String id) async {
    await _api.retireCategory(id);
    _invalidateAll();
  }

  Future<void> reorderCategories(List<String> ids) async {
    await _api.reorderCategories(ids);
    _invalidateAll();
  }

  Future<PlatformItemDetail> createItem(Map<String, dynamic> body) async {
    final result = await _api.createItem(body);
    _invalidateAll();
    return result;
  }

  Future<PlatformItemDetail> createDraft(String itemId) async {
    final result = await _api.createItemDraft(itemId);
    _invalidateAll();
    return result;
  }

  Future<ItemMetadata> saveMetadata(
    String itemId,
    ItemMetadata metadata,
  ) async {
    final result = await _api.updateItemMetadata(itemId, metadata);
    _invalidateAll();
    return result;
  }

  Future<void> saveSourceContent(
    String itemId,
    String versionId, {
    required String label,
    required String instruction,
  }) async {
    await _api.updateTranslation(
      itemId,
      versionId,
      'en',
      label: label,
      instruction: instruction,
    );
    _invalidateAll();
  }

  Future<void> saveConfig({
    required String itemId,
    required String versionId,
    List<EvidenceRule>? evidenceRules,
    List<IssueField>? issueFields,
    List<MeasurementBand>? measurementBands,
  }) async {
    if (evidenceRules != null) {
      await _api.replaceEvidenceRules(itemId, versionId, evidenceRules);
    }
    if (issueFields != null) {
      await _api.replaceIssueFields(itemId, versionId, issueFields);
    }
    if (measurementBands != null) {
      await _api.replaceMeasurementBands(itemId, versionId, measurementBands);
    }
    _invalidateAll();
  }

  Future<PlatformItemVersion> publishItem(
    String itemId,
    String versionId,
  ) async {
    final result = await _api.publishItemVersion(itemId, versionId);
    _invalidateAll();
    return result;
  }

  Future<void> retireItem(String itemId) async {
    await _api.retireItem(itemId);
    _invalidateAll();
  }

  Future<void> reorderItems(List<String> ids) async {
    await _api.reorderItems(ids);
    _invalidateAll();
  }

  Future<OptionSet> createOptionSet(Map<String, dynamic> body) async {
    final result = await _api.createOptionSet(body);
    _invalidateAll();
    return result;
  }

  Future<OptionSet> updateOptionSet(
    String id,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.updateOptionSet(id, body);
    _invalidateAll();
    return result;
  }

  Future<void> retireOptionSet(String id) async {
    await _api.retireOptionSet(id);
    _invalidateAll();
  }

  Future<OptionValue> addOptionValue(
    String setId,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.addOptionValue(setId, body);
    _invalidateAll();
    return result;
  }

  Future<OptionValue> updateOptionValue(
    String setId,
    String valueId,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.updateOptionValue(setId, valueId, body);
    _invalidateAll();
    return result;
  }

  Future<OptionValue> retireOptionValue(
    String setId,
    String valueId, {
    String? replacementCode,
  }) async {
    final result = await _api.retireOptionValue(
      setId,
      valueId,
      replacementCode: replacementCode,
    );
    _invalidateAll();
    return result;
  }

  Future<ReportDocumentType> saveDocumentType({
    String? id,
    required String code,
    required String name,
    required bool required,
    required int sortOrder,
    bool? active,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'name': name,
      'required': required,
      'sortOrder': sortOrder,
      'active': ?active,
    };
    final result = id == null
        ? await _api.createDocumentType(body)
        : await _api.updateDocumentType(id, body);
    _invalidateAll();
    return result;
  }

  Future<void> retireDocumentType(String id) async {
    await _api.retireDocumentType(id);
    _invalidateAll();
  }

  Future<ConfigRelease> createRelease(Map<String, dynamic> body) async {
    final result = await _api.createRelease(body);
    _invalidateAll();
    return result;
  }

  Future<ConfigRelease> transitionRelease(String id, String action) async {
    final result = await _api.transitionRelease(id, action);
    _invalidateAll();
    return result;
  }
}

final platformConfigActionsProvider = Provider<PlatformConfigActions>(
  (ref) => PlatformConfigActions(ref),
);

final auditEventsProvider =
    FutureProvider.autoDispose<List<PlatformAuditEvent>>(
      (ref) => ref.watch(platformConfigApiProvider).auditEvents(),
    );

@immutable
class AuditQuery {
  const AuditQuery({
    this.action = '',
    this.entityType = '',
    this.actor = '',
    this.dateFrom = '',
    this.dateTo = '',
    this.search = '',
    this.sort = 'occurredAt,desc',
    this.page = 0,
    this.size = 25,
  });

  final String action;
  final String entityType;
  final String actor;
  final String dateFrom;
  final String dateTo;
  final String search;
  final String sort;
  final int page;
  final int size;

  AuditQuery copyWith({
    String? action,
    String? entityType,
    String? actor,
    String? dateFrom,
    String? dateTo,
    String? search,
    String? sort,
    int? page,
    int? size,
  }) => AuditQuery(
    action: action ?? this.action,
    entityType: entityType ?? this.entityType,
    actor: actor ?? this.actor,
    dateFrom: dateFrom ?? this.dateFrom,
    dateTo: dateTo ?? this.dateTo,
    search: search ?? this.search,
    sort: sort ?? this.sort,
    page: page ?? this.page,
    size: size ?? this.size,
  );

  @override
  bool operator ==(Object other) =>
      other is AuditQuery &&
      other.action == action &&
      other.entityType == entityType &&
      other.actor == actor &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.search == search &&
      other.sort == sort &&
      other.page == page &&
      other.size == size;

  @override
  int get hashCode => Object.hash(
    action,
    entityType,
    actor,
    dateFrom,
    dateTo,
    search,
    sort,
    page,
    size,
  );
}

final auditEventsPageProvider = FutureProvider.autoDispose
    .family<AuditEventPage, AuditQuery>(
      (ref, query) => ref
          .watch(platformConfigApiProvider)
          .auditEventsPage(
            action: query.action,
            entityType: query.entityType,
            actor: query.actor,
            dateFrom: query.dateFrom,
            dateTo: query.dateTo,
            search: query.search,
            sort: query.sort,
            page: query.page,
            size: query.size,
          ),
    );

final overviewProvider = FutureProvider.autoDispose<OverviewSummary>(
  (ref) => ref.watch(platformConfigApiProvider).overview(),
);
