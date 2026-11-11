import 'package:auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
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

class SelectedWorkshopNotifier extends Notifier<String> {
  @override
  String build() => 'workshop-1';

  void select(String id) => state = id;
}

final selectedWorkshopIdProvider =
    NotifierProvider<SelectedWorkshopNotifier, String>(
      SelectedWorkshopNotifier.new,
    );

class StaffSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final staffSearchQueryProvider =
    NotifierProvider<StaffSearchNotifier, String>(
      StaffSearchNotifier.new,
    );

class StaffFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setFilter(String filter) => state = filter;
}

final staffRoleFilterProvider =
    NotifierProvider<StaffFilterNotifier, String>(
      StaffFilterNotifier.new,
    );

/// Shared language state. The platform app no longer owns a locale provider.
final platformLocaleProvider = localeProvider;

class AddStaffPanelNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

final addStaffPanelOpenProvider =
    NotifierProvider<AddStaffPanelNotifier, bool>(
      AddStaffPanelNotifier.new,
    );

class MasterCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All Categories';

  void setCategory(String category) => state = category;
}

final masterCategoryFilterProvider =
    NotifierProvider<MasterCategoryFilterNotifier, String>(
      MasterCategoryFilterNotifier.new,
    );

class MasterItemSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final masterItemSearchQueryProvider =
    NotifierProvider<MasterItemSearchNotifier, String>(
      MasterItemSearchNotifier.new,
    );

final hierarchyStateProvider =
    FutureProvider.autoDispose<HierarchyResponse>(
      (ref) => ref.watch(platformApiProvider).hierarchy(),
    );

// --------------------------------------------------------------------------
// Platform configuration providers (Phase 1)
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

final categoryWeightCheckProvider =
    FutureProvider.autoDispose<CategoryWeightCheck>(
      (ref) => ref.watch(platformConfigApiProvider).categoryWeightCheck(),
    );

final itemsProvider =
    FutureProvider.autoDispose.family<List<PlatformItem>, ItemQuery>(
      (ref, query) => ref.watch(platformConfigApiProvider).items(
        search: query.search,
        categoryId: query.categoryId,
        status: query.status,
      ),
    );

final itemDetailProvider =
    FutureProvider.autoDispose.family<PlatformItemDetail, String>(
      (ref, itemId) =>
          ref.watch(platformConfigApiProvider).itemDetail(itemId),
    );

final itemConfigProvider =
    FutureProvider.autoDispose.family<ItemConfig, ItemVersionKey>(
      (ref, key) => ref
          .watch(platformConfigApiProvider)
          .itemConfig(key.itemId, key.versionId),
    );

final optionSetsProvider = FutureProvider.autoDispose<List<OptionSet>>(
  (ref) => ref.watch(platformConfigApiProvider).optionSets(),
);

final templatesProvider = FutureProvider.autoDispose<List<GlobalTemplate>>(
  (ref) => ref.watch(platformConfigApiProvider).templates(),
);

final templateDetailProvider =
    FutureProvider.autoDispose.family<GlobalTemplate, String>(
      (ref, id) => ref.watch(platformConfigApiProvider).templateDetail(id),
    );

final weightPreviewProvider =
    FutureProvider.autoDispose.family<WeightPreview, ItemVersionKey>(
      (ref, key) => ref
          .watch(platformConfigApiProvider)
          .templateWeightPreview(key.itemId, key.versionId),
    );

final scoringRuleProvider = FutureProvider.autoDispose<ScoringRuleDetail>(
  (ref) => ref.watch(platformConfigApiProvider).scoringRule(),
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

final configHealthProvider = FutureProvider.autoDispose<ConfigHealth>(
  (ref) => ref.watch(platformConfigApiProvider).configHealth(),
);

final configReleasesProvider = FutureProvider.autoDispose<List<ConfigRelease>>(
  (ref) => ref.watch(platformConfigApiProvider).releases(),
);

final impactProvider =
    FutureProvider.autoDispose.family<ImpactAnalysis, ImpactKey>(
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
    _ref.invalidate(categoryWeightCheckProvider);
    _ref.invalidate(itemsProvider);
    _ref.invalidate(itemDetailProvider);
    _ref.invalidate(itemConfigProvider);
    _ref.invalidate(optionSetsProvider);
    _ref.invalidate(templatesProvider);
    _ref.invalidate(templateDetailProvider);
    _ref.invalidate(weightPreviewProvider);
    _ref.invalidate(scoringRuleProvider);
    _ref.invalidate(documentTypesProvider);
    _ref.invalidate(platformLanguagesProvider);
    _ref.invalidate(translationCoverageProvider);
    _ref.invalidate(configHealthProvider);
    _ref.invalidate(configReleasesProvider);
    _ref.invalidate(impactProvider);
  }

  Future<SeedResult> seed() async {
    final result = await _api.seedDefaultChecklist();
    _invalidateAll();
    return result;
  }

  Future<PlatformCategory> saveCategory({
    String? id,
    required String code,
    required String nameEn,
    required String nameAr,
    required double weightPercentage,
    required int sortOrder,
    bool active = true,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'weightPercentage': weightPercentage,
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

  Future<void> saveTranslations(
    String itemId,
    String versionId, {
    required String labelEn,
    required String instructionEn,
    required String labelAr,
    required String instructionAr,
  }) async {
    await _api.updateTranslation(
      itemId,
      versionId,
      'en',
      label: labelEn,
      instruction: instructionEn,
    );
    await _api.updateTranslation(
      itemId,
      versionId,
      'ar',
      label: labelAr,
      instruction: instructionAr,
    );
    _invalidateAll();
  }

  Future<void> saveConfig({
    required String itemId,
    required String versionId,
    List<ScoreBand>? scoreBands,
    List<EvidenceRule>? evidenceRules,
    List<IssueField>? issueFields,
    List<MeasurementBand>? measurementBands,
  }) async {
    if (scoreBands != null) {
      await _api.replaceScoreBands(itemId, versionId, scoreBands);
    }
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

  Future<GlobalTemplate> createTemplate(Map<String, dynamic> body) async {
    final result = await _api.createTemplate(body);
    _invalidateAll();
    return result;
  }

  Future<GlobalTemplate> createTemplateDraft(String id) async {
    final result = await _api.createTemplateDraft(id);
    _invalidateAll();
    return result;
  }

  Future<GlobalTemplate> replaceTemplateItems(
    String id,
    String versionId,
    List<Map<String, dynamic>> items,
  ) async {
    final result = await _api.replaceTemplateItems(id, versionId, items);
    _invalidateAll();
    return result;
  }

  Future<GlobalTemplate> publishTemplate(String id, String versionId) async {
    final result = await _api.publishTemplate(id, versionId);
    _invalidateAll();
    return result;
  }

  Future<GlobalTemplate> approveTemplate(String id, String versionId) async {
    final result = await _api.approveTemplate(id, versionId);
    _invalidateAll();
    return result;
  }

  Future<GlobalTemplate> rejectTemplate(
    String id,
    String versionId, {
    String reason = '',
  }) async {
    final result = await _api.rejectTemplate(id, versionId, reason: reason);
    _invalidateAll();
    return result;
  }

  Future<void> retireTemplate(String id) async {
    await _api.retireTemplate(id);
    _invalidateAll();
  }

  Future<ScoringRule> updateScoringRule(
    String id,
    Map<String, dynamic> body,
  ) async {
    final result = await _api.updateScoringRule(id, body);
    _invalidateAll();
    return result;
  }

  Future<ScoringRule> approveScoringRule(String id) async {
    final result = await _api.approveScoringRule(id);
    _invalidateAll();
    return result;
  }

  Future<List<GradeBoundary>> saveGradeBoundaries(
    String id,
    List<GradeBoundary> boundaries,
  ) async {
    final result = await _api.replaceGradeBoundaries(id, boundaries);
    _invalidateAll();
    return result;
  }

  Future<List<GradeBoundary>> approveGradeBoundaries(String id) async {
    final result = await _api.approveGradeBoundaries(id);
    _invalidateAll();
    return result;
  }

  Future<ReportDocumentType> saveDocumentType({
    String? id,
    required String code,
    required String nameEn,
    required String nameAr,
    required bool required,
    required int sortOrder,
  }) async {
    final body = <String, dynamic>{
      'code': code,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'required': required,
      'sortOrder': sortOrder,
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

  Future<PlatformLanguage> saveLanguage({
    required String code,
    required String nameEn,
    required String nameAr,
    required String nativeName,
    required String direction,
    required bool active,
    required int sortOrder,
    bool isNew = false,
  }) async {
    final body = <String, dynamic>{
      'nameEn': nameEn,
      'nameAr': nameAr,
      'nativeName': nativeName,
      'direction': direction,
      'active': active,
      'sortOrder': sortOrder,
    };
    final result = isNew
        ? await _api.createLanguage({...body, 'code': code})
        : await _api.updateLanguage(code, body);
    _invalidateAll();
    return result;
  }

  Future<void> setDefaultLanguage(String code) async {
    await _api.setDefaultLanguage(code);
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

final reasonsProvider =
    FutureProvider.autoDispose<List<PlatformCatalogueEntry>>(
      (ref) => ref.watch(platformConfigApiProvider).reasons(),
    );

final equipmentProvider =
    FutureProvider.autoDispose<List<PlatformCatalogueEntry>>(
      (ref) => ref.watch(platformConfigApiProvider).equipment(),
    );

final dropdownsProvider =
    FutureProvider.autoDispose<List<PlatformCatalogueEntry>>(
      (ref) => ref.watch(platformConfigApiProvider).dropdowns(),
    );

final auditEventsProvider =
    FutureProvider.autoDispose<List<PlatformAuditEvent>>(
      (ref) => ref.watch(platformConfigApiProvider).auditEvents(),
    );
