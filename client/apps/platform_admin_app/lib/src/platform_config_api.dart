import 'package:api_client/api_client.dart';
import 'platform_catalogue_models.dart';
import 'platform_config_models.dart';

/// Typed Platform Admin configuration API backed by `/api/v1/platform`.
class PlatformConfigApi {
  PlatformConfigApi(this._api, this._endpoints);

  final ApiClient _api;
  final ApiEndpoints _endpoints;

  Map<String, dynamic> _map(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  List<dynamic> _list(dynamic value) =>
      value is List<dynamic> ? value : const <dynamic>[];

  // -------------------------------------------------------------- languages

  Future<List<PlatformLanguage>> platformLanguages() async {
    final data = await _api.getDynamic(_endpoints.platformLanguages);
    return _list(data)
        .map((item) => PlatformLanguage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<PlatformLanguage>> i18nLanguages() async {
    final data = await _api.getDynamic(_endpoints.i18nLanguages);
    return _list(data)
        .map((item) => PlatformLanguage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<MeLanguage> meLanguage() async {
    final data = await _api.getDynamic(_endpoints.i18nMe);
    return MeLanguage.fromJson(_map(data));
  }

  Future<MeLanguage> setMeLanguage(String code) async {
    final data = await _api.putDynamic(
      _endpoints.i18nMe,
      body: {'language': code},
    );
    return MeLanguage.fromJson(_map(data));
  }

  Future<PlatformLanguage> createLanguage(Map<String, dynamic> body) async {
    final data = await _api.postDynamic(
      _endpoints.platformLanguages,
      body: body,
    );
    return PlatformLanguage.fromJson(_map(data));
  }

  Future<PlatformLanguage> updateLanguage(
    String code,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.platformLanguage(code),
      body: body,
    );
    return PlatformLanguage.fromJson(_map(data));
  }

  Future<PlatformLanguage> activateLanguage(String code) async {
    final data = await _api.postDynamic(
      _endpoints.platformLanguageActivate(code),
    );
    return PlatformLanguage.fromJson(_map(data));
  }

  Future<PlatformLanguage> deactivateLanguage(String code) async {
    final data = await _api.postDynamic(
      _endpoints.platformLanguageDeactivate(code),
    );
    return PlatformLanguage.fromJson(_map(data));
  }

  Future<List<PlatformLanguage>> reorderLanguages(List<String> codes) async {
    final data = await _api.putDynamic(
      _endpoints.platformLanguagesReorder,
      body: {'orderedCodes': codes},
    );
    return _list(data)
        .map((item) => PlatformLanguage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PlatformLanguage> setDefaultLanguage(String code) async {
    final data = await _api.putDynamic(
      _endpoints.platformLanguagesDefault,
      body: {'language': code},
    );
    return PlatformLanguage.fromJson(_map(data));
  }

  Future<TranslationCoverage> translationCoverage() async {
    final data = await _api.getDynamic(_endpoints.platformLanguageCoverage);
    return TranslationCoverage.fromJson(_map(data));
  }

  // ------------------------------------------------------------- categories

  Future<List<PlatformCategory>> categories() async {
    final data = await _api.getDynamic(_endpoints.categories);
    return _list(data)
        .map((item) => PlatformCategory.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PlatformCategory> createCategory(Map<String, dynamic> body) async {
    final data = await _api.postDynamic(_endpoints.categories, body: body);
    return PlatformCategory.fromJson(_map(data));
  }

  Future<PlatformCategory> updateCategory(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.putDynamic(_endpoints.category(id), body: body);
    return PlatformCategory.fromJson(_map(data));
  }

  Future<PlatformCategory> retireCategory(String id) async {
    final data = await _api.postDynamic(_endpoints.retireCategory(id));
    return PlatformCategory.fromJson(_map(data));
  }

  Future<List<CategoryWeightRow>> reorderCategories(List<String> ids) async {
    final data = await _api.putDynamic(
      _endpoints.categoriesReorder,
      body: {'orderedIds': ids},
    );
    return _list(data)
        .map((item) => CategoryWeightRow.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<CategoryWeightCheck> categoryWeightCheck() async {
    final data = await _api.getDynamic(_endpoints.categoryWeightCheck);
    return CategoryWeightCheck.fromJson(_map(data));
  }

  // ------------------------------------------------------------------ items

  Future<List<PlatformItem>> items({
    String search = '',
    String categoryId = '',
    String status = '',
  }) async {
    final data = await _api.getDynamic(
      _endpoints.items,
      query: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (categoryId.isNotEmpty) 'categoryId': categoryId,
        if (status.isNotEmpty) 'status': status,
      },
    );
    return _list(data)
        .map((item) => PlatformItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PlatformItemDetail> itemDetail(String id) async {
    final data = await _api.getDynamic(_endpoints.item(id));
    return PlatformItemDetail.fromJson(_map(data));
  }

  Future<PlatformItemDetail> createItem(Map<String, dynamic> body) async {
    final data = await _api.postDynamic(_endpoints.items, body: body);
    return PlatformItemDetail.fromJson(_map(data));
  }

  Future<PlatformItemDetail> createItemDraft(String itemId) async {
    final data = await _api.postDynamic(_endpoints.itemDraft(itemId));
    return PlatformItemDetail.fromJson(_map(data));
  }

  Future<PlatformItemDetail> createItemVersion(String itemId) async {
    final data = await _api.postDynamic(_endpoints.itemVersions(itemId));
    return PlatformItemDetail.fromJson(_map(data));
  }

  Future<PlatformItemDetail> updateTranslation(
    String itemId,
    String versionId,
    String locale, {
    required String label,
    required String instruction,
  }) async {
    final data = await _api.putDynamic(
      _endpoints.itemVersionTranslation(itemId, versionId, locale),
      body: {'label': label, 'instruction': instruction},
    );
    // Translation endpoint returns a version DTO; re-fetch the detail.
    if (_map(data).containsKey('item')) {
      return PlatformItemDetail.fromJson(_map(data));
    }
    return itemDetail(itemId);
  }

  Future<ItemMetadata> itemMetadata(String itemId) async {
    final data = await _api.getDynamic(_endpoints.itemMetadata(itemId));
    return ItemMetadata.fromJson(_map(data));
  }

  Future<ItemMetadata> updateItemMetadata(
    String itemId,
    ItemMetadata metadata,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.itemMetadata(itemId),
      body: metadata.toJson(),
    );
    return ItemMetadata.fromJson(_map(data));
  }

  Future<ItemConfig> itemConfig(String itemId, String versionId) async {
    final data = await _api.getDynamic(
      _endpoints.itemVersionConfig(itemId, versionId),
    );
    return ItemConfig.fromJson(_map(data));
  }

  Future<List<ScoreBand>> replaceScoreBands(
    String itemId,
    String versionId,
    List<ScoreBand> bands,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.itemVersionBands(itemId, versionId),
      body: {'bands': bands.map((band) => band.toJson()).toList()},
    );
    return _list(data)
        .map((item) => ScoreBand.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<EvidenceRule>> replaceEvidenceRules(
    String itemId,
    String versionId,
    List<EvidenceRule> rules,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.itemVersionEvidenceRules(itemId, versionId),
      body: {'rules': rules.map((rule) => rule.toJson()).toList()},
    );
    return _list(data)
        .map((item) => EvidenceRule.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<IssueField>> replaceIssueFields(
    String itemId,
    String versionId,
    List<IssueField> fields,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.itemVersionIssueFields(itemId, versionId),
      body: {'fields': fields.map((field) => field.toJson()).toList()},
    );
    return _list(data)
        .map((item) => IssueField.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<MeasurementBand>> replaceMeasurementBands(
    String itemId,
    String versionId,
    List<MeasurementBand> bands,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.itemVersionMeasurementBands(itemId, versionId),
      body: {'bands': bands.map((band) => band.toJson()).toList()},
    );
    return _list(data)
        .map((item) => MeasurementBand.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PlatformItemVersion> publishItemVersion(
    String itemId,
    String versionId,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.publishItemVersion(itemId, versionId),
    );
    return PlatformItemVersion.fromJson(_map(data));
  }

  Future<PlatformItem> retireItem(String itemId) async {
    final data = await _api.postDynamic(_endpoints.retireItem(itemId));
    return PlatformItem.fromJson(_map(data));
  }

  Future<void> reorderItems(List<String> ids) async {
    await _api.putDynamic(
      _endpoints.itemsReorder,
      body: {'orderedIds': ids},
    );
  }

  // ------------------------------------------------------------- option sets

  Future<List<OptionSet>> optionSets() async {
    final data = await _api.getDynamic(_endpoints.optionSets);
    return _list(data)
        .map((item) => OptionSet.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<OptionSet> createOptionSet(Map<String, dynamic> body) async {
    final data = await _api.postDynamic(_endpoints.optionSets, body: body);
    return OptionSet.fromJson(_map(data));
  }

  Future<OptionSet> updateOptionSet(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.putDynamic(_endpoints.optionSet(id), body: body);
    return OptionSet.fromJson(_map(data));
  }

  Future<OptionSet> retireOptionSet(String id) async {
    final data = await _api.postDynamic(_endpoints.retireOptionSet(id));
    return OptionSet.fromJson(_map(data));
  }

  Future<OptionValue> addOptionValue(
    String setId,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.optionSetValues(setId),
      body: body,
    );
    return OptionValue.fromJson(_map(data));
  }

  Future<OptionValue> updateOptionValue(
    String setId,
    String valueId,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.optionSetValue(setId, valueId),
      body: body,
    );
    return OptionValue.fromJson(_map(data));
  }

  Future<OptionValue> retireOptionValue(
    String setId,
    String valueId, {
    String? replacementCode,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.retireOptionSetValue(setId, valueId),
      body: {
        if (replacementCode != null && replacementCode.isNotEmpty)
          'replacementCode': replacementCode,
      },
    );
    return OptionValue.fromJson(_map(data));
  }

  Future<List<OptionValue>> reorderOptionValues(
    String setId,
    List<String> ids,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.reorderOptionSetValues(setId),
      body: {'orderedCodes': ids},
    );
    return _list(data)
        .map((item) => OptionValue.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  // --------------------------------------------------------------- templates

  Future<List<GlobalTemplate>> templates() async {
    final data = await _api.getDynamic(_endpoints.masterTemplates);
    return _list(data)
        .map((item) => GlobalTemplate.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<GlobalTemplate> templateDetail(String id) async {
    final data = await _api.getDynamic(_endpoints.masterTemplate(id));
    return GlobalTemplate.fromJson(_map(data));
  }

  Future<GlobalTemplate> createTemplate(Map<String, dynamic> body) async {
    final data = await _api.postDynamic(_endpoints.masterTemplates, body: body);
    return GlobalTemplate.fromJson(_map(data));
  }

  Future<GlobalTemplate> updateTemplate(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.putDynamic(_endpoints.masterTemplate(id), body: body);
    return GlobalTemplate.fromJson(_map(data));
  }

  Future<GlobalTemplate> createTemplateDraft(String id) async {
    final data = await _api.postDynamic(_endpoints.masterTemplateVersions(id));
    return GlobalTemplate.fromJson(_map(data));
  }

  Future<GlobalTemplate> replaceTemplateItems(
    String id,
    String versionId,
    List<Map<String, dynamic>> items,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.masterTemplateVersionItems(id, versionId),
      body: {'items': items},
    );
    return GlobalTemplate.fromJson(_map(data));
  }

  Future<WeightPreview> templateWeightPreview(
    String id,
    String versionId,
  ) async {
    final data = await _api.getDynamic(
      _endpoints.masterTemplateWeightPreview(id, versionId),
    );
    return WeightPreview.fromJson(_map(data));
  }

  Future<GlobalTemplate> publishTemplate(String id, String versionId) async {
    final data = await _api.postDynamic(
      _endpoints.publishMasterTemplate(id, versionId),
    );
    return GlobalTemplate.fromJson(_map(data));
  }

  Future<GlobalTemplate> approveTemplate(String id, String versionId) async {
    final data = await _api.postDynamic(
      _endpoints.approveMasterTemplate(id, versionId),
    );
    return GlobalTemplate.fromJson(_map(data));
  }

  Future<GlobalTemplate> rejectTemplate(
    String id,
    String versionId, {
    String reason = '',
  }) async {
    final data = await _api.postDynamic(
      _endpoints.rejectMasterTemplate(id, versionId),
      body: {'reason': reason},
    );
    return GlobalTemplate.fromJson(_map(data));
  }

  Future<GlobalTemplate> retireTemplate(String id) async {
    final data = await _api.postDynamic(_endpoints.retireMasterTemplate(id));
    return GlobalTemplate.fromJson(_map(data));
  }

  // ----------------------------------------------------------------- scoring

  Future<ScoringRuleDetail> scoringRule() async {
    final data = await _api.getDynamic(_endpoints.scoringRules);
    return ScoringRuleDetail.fromJson(_map(data));
  }

  Future<ScoringRule> updateScoringRule(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.scoringRule(id),
      body: body,
    );
    return ScoringRule.fromJson(_map(data));
  }

  Future<ScoringRule> approveScoringRule(String id) async {
    final data = await _api.postDynamic(_endpoints.approveScoringRule(id));
    return ScoringRule.fromJson(_map(data));
  }

  Future<ScoringRule> rejectScoringRule(String id, {String reason = ''}) async {
    final data = await _api.postDynamic(
      _endpoints.rejectScoringRule(id),
      body: {'reason': reason},
    );
    return ScoringRule.fromJson(_map(data));
  }

  Future<List<GradeBoundary>> gradeBoundaries(String id) async {
    final data = await _api.getDynamic(_endpoints.gradeBoundaries(id));
    return _list(data)
        .map((item) => GradeBoundary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<GradeBoundary>> replaceGradeBoundaries(
    String id,
    List<GradeBoundary> boundaries,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.gradeBoundaries(id),
      body: {
        'boundaries': boundaries.map((item) => item.toJson()).toList(),
      },
    );
    return _list(data)
        .map((item) => GradeBoundary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<GradeBoundary>> approveGradeBoundaries(String id) async {
    final data = await _api.postDynamic(_endpoints.approveGradeBoundaries(id));
    return _list(data)
        .map((item) => GradeBoundary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ------------------------------------------------------------ doc types

  Future<List<ReportDocumentType>> documentTypes() async {
    final data = await _api.getDynamic(_endpoints.reportDocumentTypes);
    return _list(data)
        .map(
          (item) => ReportDocumentType.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<ReportDocumentType> createDocumentType(
    Map<String, dynamic> body,
  ) async {
    final data = await _api.postDynamic(
      _endpoints.reportDocumentTypes,
      body: body,
    );
    return ReportDocumentType.fromJson(_map(data));
  }

  Future<ReportDocumentType> updateDocumentType(
    String id,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.putDynamic(
      _endpoints.reportDocumentType(id),
      body: body,
    );
    return ReportDocumentType.fromJson(_map(data));
  }

  Future<ReportDocumentType> retireDocumentType(String id) async {
    final data = await _api.postDynamic(
      _endpoints.retireReportDocumentType(id),
    );
    return ReportDocumentType.fromJson(_map(data));
  }

  Future<void> reorderDocumentTypes(List<String> ids) async {
    await _api.putDynamic(
      _endpoints.reportDocumentTypesReorder,
      body: {'orderedIds': ids},
    );
  }

  // ------------------------------------------------------------- governance

  Future<SeedResult> seedDefaultChecklist() async {
    final data = await _api.postDynamic(_endpoints.seedDefaultChecklist);
    return SeedResult.fromJson(_map(data));
  }

  Future<ConfigHealth> configHealth() async {
    final data = await _api.getDynamic(_endpoints.configHealth);
    return ConfigHealth.fromJson(_map(data));
  }

  Future<ConfigHealth> configHealthFor(String entityType) async {
    final data = await _api.getDynamic(
      _endpoints.configHealthEntity(entityType),
    );
    return ConfigHealth.fromJson(_map(data));
  }

  Future<ImpactAnalysis> impact(String entityType, String id) async {
    final data = await _api.getDynamic(
      _endpoints.impactAnalysis(entityType, id),
    );
    return ImpactAnalysis.fromJson(_map(data));
  }

  Future<List<ConfigRelease>> releases() async {
    final data = await _api.getDynamic(_endpoints.configReleases);
    return _list(data)
        .map((item) => ConfigRelease.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ConfigRelease> createRelease(Map<String, dynamic> body) async {
    final data = await _api.postDynamic(_endpoints.configReleases, body: body);
    return ConfigRelease.fromJson(_map(data));
  }

  Future<ConfigRelease> transitionRelease(String id, String action) async {
    final data = await _api.postDynamic(
      _endpoints.configReleaseTransition(id, action),
    );
    return ConfigRelease.fromJson(_map(data));
  }

  // ----------------------------------------------------- catalogues / audit

  Future<List<PlatformCatalogueEntry>> reasons() async {
    final data = await _api.getDynamic(_endpoints.reasons);
    return _list(data)
        .map(
          (item) => PlatformCatalogueEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<List<PlatformCatalogueEntry>> equipment() async {
    final data = await _api.getDynamic(_endpoints.equipment);
    return _list(data)
        .map(
          (item) => PlatformCatalogueEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<List<PlatformCatalogueEntry>> dropdowns() async {
    final data = await _api.getDynamic(_endpoints.dropdowns);
    return _list(data)
        .map(
          (item) => PlatformCatalogueEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<List<PlatformAuditEvent>> auditEvents() async {
    final data = await _api.getDynamic(_endpoints.auditEvents);
    return _list(data)
        .map((item) => PlatformAuditEvent.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
