import 'package:api_client/api_client.dart';

import 'platform_catalogue_models.dart';
import 'features/languages/manual_translation_models.dart';
import 'features/localization/translation_review_models.dart';
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

  /// The closed list the Add-language picker offers (code, name, direction).
  Future<List<LanguageCatalogEntry>> languageCatalog() async {
    final data = await _api.getDynamic(_endpoints.platformLanguageCatalog);
    return _list(data)
        .map(
          (item) => LanguageCatalogEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  /// Interface-text coverage of one language per app namespace.
  Future<List<AppCoverageRow>> appCoverage(String code) async {
    final data = await _api.getDynamic(_endpoints.platformLanguageApps(code));
    return _list(data)
        .map((item) => AppCoverageRow.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Registers a language in the backend registry.
  ///
  /// The server answers 201 for a new language and 200 when a retired one is
  /// reactivated; both return the stored [PlatformLanguage]. 409
  /// `LANGUAGE_EXISTS` means the language is already live, 422
  /// `LANGUAGE_INVALID` / `LANGUAGE_DEFAULT` reject the body.
  Future<PlatformLanguage> createLanguage({
    required String code,
    required String nativeName,
    required String direction,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.platformLanguages,
      body: <String, dynamic>{
        'code': code,
        'nativeName': nativeName,
        'direction': direction,
      },
    );
    return PlatformLanguage.fromJson(_map(data));
  }

  /// Retires a language (status RETIRED, inactive) without deleting content.
  ///
  /// 422 rejects the default language, 404 an unknown code.
  Future<PlatformLanguage> retireLanguage(String code) async {
    final data = await _api.deleteDynamic(_endpoints.platformLanguage(code));
    return PlatformLanguage.fromJson(_map(data));
  }

  /// Languages that actually carry content translations. This is deliberately
  /// not [platformLanguages]: that is the UI-message registry and can be
  /// English-only while content exists in other languages.
  Future<List<PlatformLanguage>> contentLanguages() async {
    final data = await _api.getDynamic(_endpoints.platformContentLanguages);
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

  Future<TranslationCoverage> translationCoverage() async {
    final data = await _api.getDynamic(_endpoints.platformLanguageCoverage);
    return TranslationCoverage.fromJson(_map(data));
  }

  Future<LanguageReadiness> readiness(String code) async {
    final data = await _api.getDynamic(
      _endpoints.platformLanguageReadiness(code),
    );
    return LanguageReadiness.fromJson(_map(data));
  }

  // -------------------------------------------------------- content review

  Future<List<TranslationReviewItem>> contentReview({
    required String lang,
    String? state,
    String? entityType,
    int page = 0,
    int size = 50,
  }) async {
    final data = await _api.getDynamic(
      _endpoints.contentReview,
      query: <String, dynamic>{
        'lang': lang,
        if (state != null && state.isNotEmpty) 'state': state,
        if (entityType != null && entityType.isNotEmpty)
          'entityType': entityType,
        'page': '$page',
        'size': '$size',
      },
    );
    return _list(data)
        .whereType<Map>()
        .map(
          (item) => TranslationReviewItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }

  Future<TranslationReviewSummary> contentReviewSummary(
    String lang, {
    String? entityType,
  }) async {
    final data = await _api.getDynamic(
      _endpoints.contentReviewSummary,
      query: <String, dynamic>{
        'lang': lang,
        if (entityType != null && entityType.isNotEmpty)
          'entityType': entityType,
      },
    );
    return TranslationReviewSummary.fromJson(_map(data));
  }

  /// Machine-translation jobs the provider could not finish, with their reason.
  Future<List<FailedTranslationJob>> contentFailedJobs({
    required String lang,
    String? entityType,
  }) async {
    final data = await _api.getDynamic(
      _endpoints.contentFailedJobs,
      query: <String, dynamic>{
        'lang': lang,
        if (entityType != null && entityType.isNotEmpty)
          'entityType': entityType,
      },
    );
    return _list(data)
        .whereType<Map>()
        .map(
          (item) => FailedTranslationJob.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }

  /// Puts failed jobs back in the queue; returns how many were requeued.
  Future<int> retryFailedJobs({
    required String lang,
    String? entityType,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.contentRetryFailed,
      body: <String, dynamic>{
        'lang': lang,
        if (entityType != null && entityType.isNotEmpty)
          'entityType': entityType,
      },
    );
    final map = _map(data);
    final value = map['retried'];
    return value is num ? value.toInt() : 0;
  }

  /// Approves pending non-safety translations. With [dryRun] it only counts.
  Future<BulkApproveResult> bulkApproveContent({
    required String lang,
    bool dryRun = false,
    List<String>? entityTypes,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.contentReviewBulkApprove,
      body: <String, dynamic>{
        'lang': lang,
        'dryRun': dryRun,
        if (entityTypes != null && entityTypes.isNotEmpty)
          'entityTypes': entityTypes,
      },
    );
    return BulkApproveResult.fromJson(_map(data));
  }

  /// Approves exactly the rows the reviewer checked, safety-critical included.
  Future<BulkApproveResult> approveSelectedContent({
    required String lang,
    required List<TranslationReviewItem> items,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.contentReviewApproveSelected,
      body: <String, dynamic>{
        'lang': lang,
        'items': <Map<String, String>>[
          for (final item in items)
            <String, String>{
              'entityType': item.entityType,
              'entityId': item.entityId,
              'field': item.field,
            },
        ],
      },
    );
    return BulkApproveResult.fromJson(_map(data));
  }

  /// Queues machine translations for a language that has no content rows yet.
  Future<ContentBackfillResult> backfillContent({
    required String lang,
    bool dryRun = false,
    List<String>? entityTypes,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.contentBackfill,
      body: <String, dynamic>{
        'languages': <String>[lang],
        'dryRun': dryRun,
        if (entityTypes != null && entityTypes.isNotEmpty)
          'entityTypes': entityTypes,
      },
    );
    return ContentBackfillResult.fromJson(_map(data));
  }

  Future<TranslationReviewItem> reviewContent({
    required String entityType,
    required String entityId,
    required String field,
    required String lang,
    required String action,
    String? body,
    String? note,
  }) async {
    final data = await _api.postDynamic(
      _endpoints.contentReviewAction(entityType, entityId, field),
      query: <String, dynamic>{'lang': lang},
      body: <String, dynamic>{'action': action, 'body': ?body, 'note': ?note},
    );
    final payload = _map(data);
    return TranslationReviewItem.fromJson(payload);
  }

  // ------------------------------------------------- manual translations

  /// Every canonical field for [lang], including untranslated ones.
  ///
  /// [filter] is `all` or `missing`; [total] on the page is the server total
  /// for the current filter, so callers must never derive counts from
  /// `items.length`.
  Future<ManualTranslationPage> contentUnits({
    required String lang,
    String? entityType,
    String filter = ManualTranslationFilter.all,
    String query = '',
    int page = 0,
    int size = 50,
  }) async {
    final data = await _api.getDynamic(
      _endpoints.platformContentUnits,
      query: <String, dynamic>{
        'lang': lang,
        if (entityType != null && entityType.isNotEmpty)
          'entityType': entityType,
        'filter': filter,
        if (query.trim().isNotEmpty) 'query': query.trim(),
        'page': '$page',
        'size': '$size',
      },
    );
    return ManualTranslationPage.fromJson(_map(data));
  }

  /// Saves one manually authored translation and returns the stored row.
  Future<ManualTranslationUnit> writeContentTranslation({
    required String entityType,
    required String entityId,
    required String field,
    required String lang,
    required String text,
  }) async {
    final data = await _api.putDynamic(
      _endpoints.platformContentTranslation(entityType, entityId, field),
      query: <String, dynamic>{'lang': lang},
      body: <String, dynamic>{'body': text.trim()},
    );
    return ManualTranslationUnit.fromJson(_map(data));
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

  Future<void> reorderCategories(List<String> ids) async {
    await _api.putDynamic(
      _endpoints.categoriesReorder,
      body: {'orderedIds': ids},
    );
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
    await _api.putDynamic(_endpoints.itemsReorder, body: {'orderedIds': ids});
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

  /// Values for one set, used when the catalogue returns summaries only.
  Future<List<OptionValue>> optionSetValues(String id) async {
    final data = await _api.getDynamic(_endpoints.optionSetValues(id));
    return _list(data)
        .map((item) => OptionValue.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
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

  // ------------------------------------------------------------------ audit

  Future<List<PlatformAuditEvent>> auditEvents() async {
    final data = await _api.getDynamic(_endpoints.auditEvents);
    return _list(data)
        .map(
          (item) => PlatformAuditEvent.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<AuditEventPage> auditEventsPage({
    String? action,
    String? entityType,
    String? actor,
    String? dateFrom,
    String? dateTo,
    String? search,
    String sort = 'occurredAt,desc',
    int page = 0,
    int size = 25,
  }) async {
    final data = await _api.getDynamic(
      _endpoints.auditEvents,
      query: {
        if (action != null && action.isNotEmpty) 'action': action,
        if (entityType != null && entityType.isNotEmpty)
          'entityType': entityType,
        if (actor != null && actor.isNotEmpty) 'actor': actor,
        if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
        if (search != null && search.isNotEmpty) 'search': search,
        'sort': sort,
        'page': page,
        'size': size,
      },
    );
    return AuditEventPage.fromJson(_map(data));
  }

  Future<List<int>> exportAuditEvents({
    required String format,
    String? action,
    String? entityType,
    String? actor,
    String? dateFrom,
    String? dateTo,
    String? search,
    String sort = 'occurredAt,desc',
  }) {
    return _api.getBytes(
      _endpoints.auditEventsExport,
      query: {
        'format': format,
        if (action != null && action.isNotEmpty) 'action': action,
        if (entityType != null && entityType.isNotEmpty)
          'entityType': entityType,
        if (actor != null && actor.isNotEmpty) 'actor': actor,
        if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
        if (search != null && search.isNotEmpty) 'search': search,
        'sort': sort,
      },
    );
  }

  // --------------------------------------------------------------- overview

  Future<OverviewSummary> overview() async {
    final data = await _api.getDynamic(_endpoints.platformOverview);
    return OverviewSummary.fromJson(_map(data));
  }
}
