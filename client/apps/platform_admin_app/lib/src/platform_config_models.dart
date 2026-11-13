import 'package:flutter/foundation.dart';

double _num(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _str(dynamic value) => value == null ? '' : value.toString();

List<String> _strings(dynamic value) =>
    (value as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString())
        .toList(growable: false);

@immutable
class PlatformCategory {
  const PlatformCategory({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.labelEn,
    required this.labelAr,
    required this.status,
    required this.sortOrder,
    required this.active,
    required this.itemCount,
  });

  final String id;
  final String code;
  final String nameEn;
  final String nameAr;
  final String labelEn;
  final String labelAr;
  final String status;
  final int sortOrder;
  final bool active;
  final int itemCount;

  String get name => nameEn.isNotEmpty ? nameEn : labelEn;

  factory PlatformCategory.fromJson(Map<String, dynamic> json) {
    final nameEn = _str(json['nameEn']).isNotEmpty
        ? _str(json['nameEn'])
        : _str(json['labelEn']);
    final nameAr = _str(json['nameAr']).isNotEmpty
        ? _str(json['nameAr'])
        : _str(json['labelAr']);
    return PlatformCategory(
      id: _str(json['id']),
      code: _str(json['code']).isNotEmpty
          ? _str(json['code'])
          : _str(json['slug']),
      nameEn: nameEn,
      nameAr: nameAr,
      labelEn: _str(json['labelEn']),
      labelAr: _str(json['labelAr']),
      status: _str(json['status']),
      sortOrder: _int(json['sortOrder']),
      active: json['active'] as bool? ?? _str(json['status']) == 'ACTIVE',
      itemCount: _int(json['itemCount']),
    );
  }

  Map<String, dynamic> toRequestJson() => {
    'code': code,
    'nameEn': nameEn,
    'nameAr': nameAr,
    'sortOrder': sortOrder,
    'active': active,
    'status': status,
  };
}

@immutable
class PlatformItem {
  const PlatformItem({
    required this.id,
    required this.code,
    required this.categoryId,
    required this.categoryLabelEn,
    required this.categoryLabelAr,
    required this.status,
    required this.currentVersion,
    required this.labelEn,
    required this.labelAr,
    required this.sampleData,
    required this.updatedAt,
    required this.measurementUnit,
    required this.sensorTool,
    required this.standardSpecEn,
    required this.standardSpecAr,
    required this.safetyCritical,
    required this.multiPoint,
    required this.maxTyreAgeYears,
    required this.allowFreeTextNote,
    required this.sortOrder,
    required this.guideImageId,
  });

  final String id;
  final String code;
  final String categoryId;
  final String categoryLabelEn;
  final String categoryLabelAr;
  final String status;
  final int? currentVersion;
  final String labelEn;
  final String labelAr;
  final bool sampleData;
  final String updatedAt;
  final String measurementUnit;
  final String sensorTool;
  final String standardSpecEn;
  final String standardSpecAr;
  final bool safetyCritical;
  final bool multiPoint;
  final int? maxTyreAgeYears;
  final bool allowFreeTextNote;
  final int sortOrder;
  final String guideImageId;

  factory PlatformItem.fromJson(Map<String, dynamic> json) => PlatformItem(
    id: _str(json['id']),
    code: _str(json['stableCode']).isNotEmpty
        ? _str(json['stableCode'])
        : _str(json['code']),
    categoryId: _str(json['categoryId']),
    categoryLabelEn: _str(json['categoryLabelEn']),
    categoryLabelAr: _str(json['categoryLabelAr']),
    status: _str(json['status']),
    currentVersion: json['currentVersion'] == null
        ? null
        : _int(json['currentVersion']),
    labelEn: _str(json['labelEn']),
    labelAr: _str(json['labelAr']),
    sampleData: json['sampleData'] as bool? ?? false,
    updatedAt: _str(json['updatedAt']),
    measurementUnit: _str(json['measurementUnit']),
    sensorTool: _str(json['sensorTool']),
    standardSpecEn: _str(json['standardSpecEn']),
    standardSpecAr: _str(json['standardSpecAr']),
    safetyCritical: json['safetyCritical'] as bool? ?? false,
    multiPoint: json['multiPoint'] as bool? ?? false,
    maxTyreAgeYears: json['maxTyreAgeYears'] == null
        ? null
        : _int(json['maxTyreAgeYears']),
    allowFreeTextNote: json['allowFreeTextNote'] as bool? ?? false,
    sortOrder: _int(json['sortOrder']),
    guideImageId: _str(json['guideImageId']),
  );
}

@immutable
class ItemTranslation {
  const ItemTranslation({
    required this.locale,
    required this.label,
    required this.instruction,
  });

  final String locale;
  final String label;
  final String instruction;

  factory ItemTranslation.fromJson(Map<String, dynamic> json) =>
      ItemTranslation(
        locale: _str(json['locale']),
        label: _str(json['label']),
        instruction: _str(json['instruction']),
      );
}

@immutable
class PlatformItemVersion {
  const PlatformItemVersion({
    required this.id,
    required this.versionNo,
    required this.status,
    required this.resultOptions,
    required this.noteRequirement,
    required this.evidenceRequirement,
    required this.minPhotos,
    required this.publishedAt,
    required this.translations,
  });

  final String id;
  final int versionNo;
  final String status;
  final List<String> resultOptions;
  final String noteRequirement;
  final String evidenceRequirement;
  final int minPhotos;
  final String publishedAt;
  final Map<String, ItemTranslation> translations;

  factory PlatformItemVersion.fromJson(Map<String, dynamic> json) =>
      PlatformItemVersion(
        id: _str(json['id']),
        versionNo: _int(json['versionNo']),
        status: _str(json['status']),
        resultOptions: _strings(json['resultOptions']),
        noteRequirement: _str(json['noteRequirement']),
        evidenceRequirement: _str(json['evidenceRequirement']),
        minPhotos: _int(json['minPhotos']),
        publishedAt: _str(json['publishedAt']),
        translations: (json['translations'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            key,
            ItemTranslation.fromJson(value as Map<String, dynamic>),
          ),
        ),
      );
}

@immutable
class PlatformItemDetail {
  const PlatformItemDetail({required this.item, required this.versions});

  final PlatformItem item;
  final List<PlatformItemVersion> versions;

  PlatformItemVersion? get draftVersion {
    for (final version in versions) {
      if (version.status == 'DRAFT') return version;
    }
    return null;
  }

  PlatformItemVersion? get publishedVersion {
    for (final version in versions) {
      if (version.status == 'PUBLISHED') return version;
    }
    return versions.isEmpty ? null : versions.first;
  }

  factory PlatformItemDetail.fromJson(Map<String, dynamic> json) =>
      PlatformItemDetail(
        item: PlatformItem.fromJson(json['item'] as Map<String, dynamic>),
        versions: (json['versions'] as List<dynamic>? ?? const [])
            .map((e) => PlatformItemVersion.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

@immutable
class ItemMetadata {
  const ItemMetadata({
    required this.itemId,
    required this.measurementUnit,
    required this.sensorTool,
    required this.standardSpecEn,
    required this.standardSpecAr,
    required this.safetyCritical,
    required this.multiPoint,
    required this.maxTyreAgeYears,
    required this.allowFreeTextNote,
    required this.sortOrder,
    required this.guideImageId,
  });

  final String itemId;
  final String measurementUnit;
  final String sensorTool;
  final String standardSpecEn;
  final String standardSpecAr;
  final bool safetyCritical;
  final bool multiPoint;
  final int? maxTyreAgeYears;
  final bool allowFreeTextNote;
  final int sortOrder;
  final String guideImageId;

  factory ItemMetadata.fromJson(Map<String, dynamic> json) => ItemMetadata(
    itemId: _str(json['itemId']),
    measurementUnit: _str(json['measurementUnit']),
    sensorTool: _str(json['sensorTool']),
    standardSpecEn: _str(json['standardSpecEn']),
    standardSpecAr: _str(json['standardSpecAr']),
    safetyCritical: json['safetyCritical'] as bool? ?? false,
    multiPoint: json['multiPoint'] as bool? ?? false,
    maxTyreAgeYears: json['maxTyreAgeYears'] == null
        ? null
        : _int(json['maxTyreAgeYears']),
    allowFreeTextNote: json['allowFreeTextNote'] as bool? ?? false,
    sortOrder: _int(json['sortOrder']),
    guideImageId: _str(json['guideImageId']),
  );

  Map<String, dynamic> toJson() => {
    'measurementUnit': measurementUnit,
    'sensorTool': sensorTool,
    'standardSpecEn': standardSpecEn,
    'standardSpecAr': standardSpecAr,
    'safetyCritical': safetyCritical,
    'multiPoint': multiPoint,
    'maxTyreAgeYears': maxTyreAgeYears,
    'allowFreeTextNote': allowFreeTextNote,
    'sortOrder': sortOrder,
    'guideImageId': guideImageId,
  };
}

@immutable
class EvidenceRule {
  const EvidenceRule({
    required this.resultCode,
    required this.minPhotos,
    required this.minVideos,
    required this.minNotesChars,
    required this.requiredEvidenceType,
  });

  final String resultCode;
  final int minPhotos;
  final int minVideos;
  final int minNotesChars;
  final String requiredEvidenceType;

  factory EvidenceRule.fromJson(Map<String, dynamic> json) => EvidenceRule(
    resultCode: _str(json['resultCode']),
    minPhotos: _int(json['minPhotos']),
    minVideos: _int(json['minVideos']),
    minNotesChars: _int(json['minNotesChars']),
    requiredEvidenceType: _str(json['requiredEvidenceType']),
  );

  Map<String, dynamic> toJson() => {
    'resultCode': resultCode,
    'minPhotos': minPhotos,
    'minVideos': minVideos,
    'minNotesChars': minNotesChars,
    'requiredEvidenceType': requiredEvidenceType.isEmpty
        ? null
        : requiredEvidenceType,
  };
}

@immutable
class MeasurementBand {
  const MeasurementBand({
    required this.fieldCode,
    required this.unitCode,
    required this.direction,
    required this.minValue,
    required this.maxValue,
    required this.resultCode,
    required this.labelEn,
    required this.labelAr,
    required this.sortOrder,
  });

  final String fieldCode;
  final String unitCode;
  final String direction;
  final double minValue;
  final double maxValue;
  final String resultCode;
  final String labelEn;
  final String labelAr;
  final int sortOrder;

  factory MeasurementBand.fromJson(Map<String, dynamic> json) =>
      MeasurementBand(
        fieldCode: _str(json['fieldCode']),
        unitCode: _str(json['unitCode']),
        direction: _str(json['direction']),
        minValue: _num(json['minValue']),
        maxValue: _num(json['maxValue']),
        resultCode: _str(json['resultCode']),
        labelEn: _str(json['labelEn']),
        labelAr: _str(json['labelAr']),
        sortOrder: _int(json['sortOrder']),
      );

  Map<String, dynamic> toJson() => {
    'fieldCode': fieldCode,
    'unitCode': unitCode,
    'direction': direction,
    'minValue': minValue,
    'maxValue': maxValue,
    'resultCode': resultCode,
    'labelEn': labelEn,
    'labelAr': labelAr,
    'sortOrder': sortOrder,
  };
}

@immutable
class IssueField {
  const IssueField({
    this.id,
    required this.fieldCode,
    required this.labelEn,
    required this.labelAr,
    required this.inputType,
    required this.optionSetCode,
    required this.unitSetCode,
    required this.required,
    required this.requiredForStatuses,
    required this.minValue,
    required this.maxValue,
    required this.decimalPlaces,
    required this.dependsOnFieldCode,
    required this.dependsOnValueCode,
    required this.allowMultiple,
    required this.allowFreeText,
    required this.sortOrder,
    required this.allowedValues,
  });

  final String? id;
  final String fieldCode;
  final String labelEn;
  final String labelAr;
  final String inputType;
  final String optionSetCode;
  final String unitSetCode;
  final bool required;
  final List<String> requiredForStatuses;
  final double? minValue;
  final double? maxValue;
  final int decimalPlaces;
  final String dependsOnFieldCode;
  final String dependsOnValueCode;
  final bool allowMultiple;
  final bool allowFreeText;
  final int sortOrder;
  final List<String> allowedValues;

  factory IssueField.fromJson(Map<String, dynamic> json) => IssueField(
    id: json['id'] == null ? null : _str(json['id']),
    fieldCode: _str(json['fieldCode']),
    labelEn: _str(json['labelEn']),
    labelAr: _str(json['labelAr']),
    inputType: _str(json['inputType']),
    optionSetCode: _str(json['optionSetCode']),
    unitSetCode: _str(json['unitSetCode']),
    required: json['required'] as bool? ?? false,
    requiredForStatuses: _strings(json['requiredForStatuses']),
    minValue: json['minValue'] == null ? null : _num(json['minValue']),
    maxValue: json['maxValue'] == null ? null : _num(json['maxValue']),
    decimalPlaces: _int(json['decimalPlaces']),
    dependsOnFieldCode: _str(json['dependsOnFieldCode']),
    dependsOnValueCode: _str(json['dependsOnValueCode']),
    allowMultiple: json['allowMultiple'] as bool? ?? false,
    allowFreeText: json['allowFreeText'] as bool? ?? false,
    sortOrder: _int(json['sortOrder']),
    allowedValues: _strings(json['allowedValues']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fieldCode': fieldCode,
    'labelEn': labelEn,
    'labelAr': labelAr,
    'inputType': inputType,
    'optionSetCode': optionSetCode.isEmpty ? null : optionSetCode,
    'unitSetCode': unitSetCode.isEmpty ? null : unitSetCode,
    'required': required,
    'requiredForStatuses': requiredForStatuses,
    'minValue': minValue,
    'maxValue': maxValue,
    'decimalPlaces': decimalPlaces,
    'dependsOnFieldCode': dependsOnFieldCode.isEmpty
        ? null
        : dependsOnFieldCode,
    'dependsOnValueCode': dependsOnValueCode.isEmpty
        ? null
        : dependsOnValueCode,
    'allowMultiple': allowMultiple,
    'allowFreeText': allowFreeText,
    'sortOrder': sortOrder,
    'allowedValues': allowedValues,
  };
}

@immutable
class ItemConfig {
  const ItemConfig({
    required this.metadata,
    required this.evidenceRules,
    required this.issueFields,
    required this.measurementBands,
  });

  final ItemMetadata metadata;
  final List<EvidenceRule> evidenceRules;
  final List<IssueField> issueFields;
  final List<MeasurementBand> measurementBands;

  factory ItemConfig.fromJson(Map<String, dynamic> json) => ItemConfig(
    metadata: ItemMetadata.fromJson(
      json['metadata'] as Map<String, dynamic>? ?? const {},
    ),
    evidenceRules: (json['evidenceRules'] as List<dynamic>? ?? const [])
        .map((e) => EvidenceRule.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    issueFields: (json['issueFields'] as List<dynamic>? ?? const [])
        .map((e) => IssueField.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    measurementBands: (json['measurementBands'] as List<dynamic>? ?? const [])
        .map((e) => MeasurementBand.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

@immutable
class OptionValue {
  const OptionValue({
    required this.id,
    required this.code,
    required this.labelEn,
    required this.labelAr,
    required this.status,
    required this.sortOrder,
    required this.metadataJson,
  });

  final String id;
  final String code;
  final String labelEn;
  final String labelAr;
  final String status;
  final int sortOrder;
  final String metadataJson;

  factory OptionValue.fromJson(Map<String, dynamic> json) => OptionValue(
    id: _str(json['id']),
    code: _str(json['code']),
    labelEn: _str(json['labelEn']),
    labelAr: _str(json['labelAr']),
    status: _str(json['status']),
    sortOrder: _int(json['sortOrder']),
    metadataJson: _str(json['metadataJson']),
  );
}

@immutable
class OptionSet {
  const OptionSet({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.status,
    required this.sortOrder,
    required this.values,
  });

  final String id;
  final String code;
  final String nameEn;
  final String nameAr;
  final String status;
  final int sortOrder;
  final List<OptionValue> values;

  factory OptionSet.fromJson(Map<String, dynamic> json) => OptionSet(
    id: _str(json['id']),
    code: _str(json['code']),
    nameEn: _str(json['nameEn']),
    nameAr: _str(json['nameAr']),
    status: _str(json['status']),
    sortOrder: _int(json['sortOrder']),
    values: (json['values'] as List<dynamic>? ?? const [])
        .map((e) => OptionValue.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

@immutable
class TemplateVersionSummary {
  const TemplateVersionSummary({
    required this.id,
    required this.versionNo,
    required this.status,
    required this.publishedAt,
  });

  final String id;
  final int versionNo;
  final String status;
  final String publishedAt;

  factory TemplateVersionSummary.fromJson(Map<String, dynamic> json) =>
      TemplateVersionSummary(
        id: _str(json['id']),
        versionNo: _int(json['versionNo']),
        status: _str(json['status']),
        publishedAt: _str(json['publishedAt']),
      );
}

@immutable
class TemplateVersionDetail {
  const TemplateVersionDetail({
    required this.id,
    required this.templateId,
    required this.versionNo,
    required this.status,
    required this.categoryCount,
    required this.itemCount,
    required this.categories,
  });

  final String id;
  final String templateId;
  final int versionNo;
  final String status;
  final int categoryCount;
  final int itemCount;
  final List<TemplateCategory> categories;

  factory TemplateVersionDetail.fromJson(Map<String, dynamic> json) =>
      TemplateVersionDetail(
        id: _str(json['id']),
        templateId: _str(json['templateId']),
        versionNo: _int(json['versionNo']),
        status: _str(json['status']),
        categoryCount: _int(json['categoryCount']),
        itemCount: _int(json['itemCount']),
        categories: (json['categories'] as List<dynamic>? ?? const [])
            .map((e) => TemplateCategory.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

@immutable
class GlobalTemplate {
  const GlobalTemplate({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.status,
    required this.currentPublishedVersionId,
    required this.versionCount,
    required this.currentVersionNo,
    required this.versions,
    required this.categories,
  });

  final String id;
  final String code;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final String status;
  final String currentPublishedVersionId;
  final int versionCount;
  final int? currentVersionNo;
  final List<TemplateVersionSummary> versions;
  final List<TemplateCategory> categories;

  factory GlobalTemplate.fromJson(Map<String, dynamic> json) => GlobalTemplate(
    id: _str(json['id']),
    code: _str(json['code']),
    nameEn: _str(json['nameEn']),
    nameAr: _str(json['nameAr']),
    descriptionEn: _str(json['descriptionEn']),
    descriptionAr: _str(json['descriptionAr']),
    status: _str(json['status']),
    currentPublishedVersionId: _str(json['currentPublishedVersionId']),
    versionCount: _int(json['versionCount']),
    currentVersionNo: json['currentVersionNo'] == null
        ? null
        : _int(json['currentVersionNo']),
    versions: (json['versions'] as List<dynamic>? ?? const [])
        .map((e) => TemplateVersionSummary.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    categories: (json['categories'] as List<dynamic>? ?? const [])
        .map((e) => TemplateCategory.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

@immutable
@immutable
class TemplateCategory {
  const TemplateCategory({
    required this.categoryId,
    required this.categoryCode,
    required this.nameEn,
    required this.nameAr,
    required this.sortOrder,
    required this.itemCount,
    required this.includedCount,
    required this.included,
    required this.items,
  });

  final String categoryId;
  final String categoryCode;
  final String nameEn;
  final String nameAr;
  final int sortOrder;
  final int itemCount;
  final int includedCount;
  final bool included;
  final List<TemplateItem> items;

  factory TemplateCategory.fromJson(Map<String, dynamic> json) =>
      TemplateCategory(
        categoryId: _str(json['categoryId']),
        categoryCode: _str(json['categoryCode']),
        nameEn: _str(json['nameEn']),
        nameAr: _str(json['nameAr']),
        sortOrder: _int(json['sortOrder']),
        itemCount: _int(json['itemCount']),
        includedCount: _int(json['includedCount']),
        included: json['included'] as bool? ?? true,
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => TemplateItem.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class TemplateItem {
  const TemplateItem({
    required this.id,
    required this.itemId,
    required this.itemVersionId,
    required this.itemCode,
    required this.labelEn,
    required this.labelAr,
    required this.categoryId,
    required this.categoryCode,
    required this.categoryNameEn,
    required this.categoryNameAr,
    required this.sortOrder,
    required this.included,
    required this.itemStatus,
  });

  final String id;
  final String itemId;
  final String itemVersionId;
  final String itemCode;
  final String labelEn;
  final String labelAr;
  final String categoryId;
  final String categoryCode;
  final String categoryNameEn;
  final String categoryNameAr;
  final int sortOrder;
  final bool included;
  final String itemStatus;

  factory TemplateItem.fromJson(Map<String, dynamic> json) => TemplateItem(
    id: _str(json['id']),
    itemId: _str(json['itemId']),
    itemVersionId: _str(json['itemVersionId']),
    itemCode: _str(json['itemCode']),
    labelEn: _str(json['labelEn']),
    labelAr: _str(json['labelAr']),
    categoryId: _str(json['categoryId']),
    categoryCode: _str(json['categoryCode']),
    categoryNameEn: _str(json['categoryNameEn']),
    categoryNameAr: _str(json['categoryNameAr']),
    sortOrder: _int(json['sortOrder']),
    included: json['included'] as bool? ?? true,
    itemStatus: _str(json['itemStatus']),
  );
}

@immutable
class ReportDocumentType {
  const ReportDocumentType({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.status,
    required this.required,
    required this.sortOrder,
  });

  final String id;
  final String code;
  final String nameEn;
  final String nameAr;
  final String status;
  final bool required;
  final int sortOrder;

  factory ReportDocumentType.fromJson(Map<String, dynamic> json) =>
      ReportDocumentType(
        id: _str(json['id']),
        code: _str(json['code']),
        nameEn: _str(json['nameEn']),
        nameAr: _str(json['nameAr']),
        status: _str(json['status']),
        required: json['required'] as bool? ?? false,
        sortOrder: _int(json['sortOrder']),
      );
}

@immutable
class SeedResult {
  const SeedResult({
    required this.created,
    required this.skipped,
    required this.errors,
  });

  final int created;
  final int skipped;
  final List<String> errors;

  factory SeedResult.fromJson(Map<String, dynamic> json) => SeedResult(
    created: _int(json['created']),
    skipped: _int(json['skipped']),
    errors: _strings(json['errors']),
  );
}

@immutable
class HealthCheck {
  const HealthCheck({
    required this.code,
    required this.severity,
    required this.messageEn,
    required this.messageAr,
    required this.affected,
    required this.references,
  });

  final String code;
  final String severity;
  final String messageEn;
  final String messageAr;
  final int affected;
  final List<String> references;

  bool get ok => severity == 'OK';

  factory HealthCheck.fromJson(Map<String, dynamic> json) => HealthCheck(
    code: _str(json['code']),
    severity: _str(json['severity']),
    messageEn: _str(json['messageEn']),
    messageAr: _str(json['messageAr']),
    affected: _int(json['affected']),
    references: _strings(json['references']),
  );
}

@immutable
class ConfigHealth {
  const ConfigHealth({required this.healthy, required this.checks});

  final bool healthy;
  final List<HealthCheck> checks;

  factory ConfigHealth.fromJson(Map<String, dynamic> json) => ConfigHealth(
    healthy: json['healthy'] as bool? ?? false,
    checks: (json['checks'] as List<dynamic>? ?? const [])
        .map((e) => HealthCheck.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

@immutable
class ImpactAnalysis {
  const ImpactAnalysis({
    required this.entityType,
    required this.entityId,
    required this.blocked,
    required this.affectedTemplates,
    required this.affectedItems,
    required this.affectedJobs,
    required this.templateCodes,
    required this.itemCodes,
    required this.messageEn,
    required this.messageAr,
  });

  final String entityType;
  final String entityId;
  final bool blocked;
  final int affectedTemplates;
  final int affectedItems;
  final int affectedJobs;
  final List<String> templateCodes;
  final List<String> itemCodes;
  final String messageEn;
  final String messageAr;

  factory ImpactAnalysis.fromJson(Map<String, dynamic> json) => ImpactAnalysis(
    entityType: _str(json['entityType']),
    entityId: _str(json['entityId']),
    blocked: json['blocked'] as bool? ?? false,
    affectedTemplates: _int(json['affectedTemplates']),
    affectedItems: _int(json['affectedItems']),
    affectedJobs: _int(json['affectedJobs']),
    templateCodes: _strings(json['templateCodes']),
    itemCodes: _strings(json['itemCodes']),
    messageEn: _str(json['messageEn']),
    messageAr: _str(json['messageAr']),
  );
}

@immutable
class PlatformLanguage {
  const PlatformLanguage({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.nativeName,
    required this.direction,
    required this.active,
    required this.isDefault,
    required this.sortOrder,
    this.status = 'LIVE',
    this.uiMessagesPath = '',
  });

  final String code;
  final String nameEn;
  final String nameAr;
  final String nativeName;
  final String direction;
  final bool active;
  final bool isDefault;
  final int sortOrder;

  /// Lifecycle status: DRAFT → TRANSLATING → REVIEW → LIVE → RETIRED.
  /// Defaults to LIVE for backends that predate the lifecycle.
  final String status;

  /// Relative JSON path that stores this language's static UI text.
  final String uiMessagesPath;

  bool get isLive => status == 'LIVE';

  factory PlatformLanguage.fromJson(Map<String, dynamic> json) =>
      PlatformLanguage(
        code: _str(json['code']),
        nameEn: _str(json['nameEn']),
        nameAr: _str(json['nameAr']),
        nativeName: _str(json['nativeName']),
        direction: _str(json['direction']),
        active: json['active'] as bool? ?? true,
        isDefault:
            json['default'] as bool? ?? json['isDefault'] as bool? ?? false,
        sortOrder: _int(json['sortOrder']),
        status: _str(json['status']).isEmpty ? 'LIVE' : _str(json['status']),
        uiMessagesPath: _str(json['uiMessagesPath']),
      );
}

@immutable
class CoverageNamespace {
  const CoverageNamespace({required this.total, required this.missing});

  final int total;
  final List<String> missing;

  factory CoverageNamespace.fromJson(Map<String, dynamic> json) =>
      CoverageNamespace(
        total: _int(json['total']),
        missing: _strings(json['missing']),
      );
}

@immutable
class TranslationCoverage {
  const TranslationCoverage({
    required this.languages,
    required this.namespaces,
  });

  final List<String> languages;
  final Map<String, CoverageNamespace> namespaces;

  factory TranslationCoverage.fromJson(Map<String, dynamic> json) =>
      TranslationCoverage(
        languages: _strings(json['languages']),
        namespaces: (json['namespaces'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            key,
            CoverageNamespace.fromJson(value as Map<String, dynamic>),
          ),
        ),
      );
}

@immutable
class MeLanguage {
  const MeLanguage({
    required this.language,
    required this.direction,
    required this.fallback,
  });

  final String language;
  final String direction;
  final String fallback;

  factory MeLanguage.fromJson(Map<String, dynamic> json) => MeLanguage(
    language: _str(json['language']),
    direction: _str(json['direction']),
    fallback: _str(json['fallback']),
  );
}

@immutable
class ConfigRelease {
  const ConfigRelease({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.versionId,
    required this.status,
    required this.effectiveFrom,
    required this.notes,
    required this.createdBy,
    required this.approvedBy,
    required this.approvedAt,
    required this.createdAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String versionId;
  final String status;
  final String effectiveFrom;
  final String notes;
  final String createdBy;
  final String approvedBy;
  final String approvedAt;
  final String createdAt;

  factory ConfigRelease.fromJson(Map<String, dynamic> json) => ConfigRelease(
    id: _str(json['id']),
    entityType: _str(json['entityType']),
    entityId: _str(json['entityId']),
    versionId: _str(json['versionId']),
    status: _str(json['status']),
    effectiveFrom: _str(json['effectiveFrom']),
    notes: _str(json['notes']),
    createdBy: _str(json['createdBy']),
    approvedBy: _str(json['approvedBy']),
    approvedAt: _str(json['approvedAt']),
    createdAt: _str(json['createdAt']),
  );
}

// ------------------------------------------------------------------- overview
// Read-only Platform Admin dashboard aggregation served by
// `GET /api/v1/platform/overview`. Every field is optional with a 0/empty
// fallback so the UI stays useful while the backend is still being built.

bool _flag(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

Map<String, dynamic> _safeMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _safeList(dynamic value) =>
    value is List<dynamic> ? value : const <dynamic>[];

int _countOrLength(dynamic value) {
  if (value is List) return value.length;
  return _int(value);
}

/// Parses `{label: count}` maps as well as `[{label,status,month: ...,`
/// `count,value,total: ...}]` entry lists into an ordered count map.
Map<String, int> _countMap(dynamic value) {
  final counts = <String, int>{};
  if (value is Map) {
    value.forEach((key, item) {
      if (item is num) {
        counts[key.toString()] = item.toInt();
      } else if (item is Map) {
        final map = _safeMap(item);
        final label = _str(map['label']).isNotEmpty
            ? _str(map['label'])
            : key.toString();
        counts[label] = _int(map['count'] ?? map['value'] ?? map['total']);
      }
    });
    return counts;
  }
  for (final entry in _safeList(value)) {
    final map = _safeMap(entry);
    if (map.isEmpty) continue;
    final label = _str(map['label']).isNotEmpty
        ? _str(map['label'])
        : _str(map['status']).isNotEmpty
        ? _str(map['status'])
        : _str(map['month']).isNotEmpty
        ? _str(map['month'])
        : _str(map['name']);
    if (label.isEmpty) continue;
    counts[label] = _int(map['count'] ?? map['value'] ?? map['total']);
  }
  return counts;
}

@immutable
class OverviewWorkshops {
  const OverviewWorkshops({required this.total, required this.active});

  final int total;
  final int active;

  factory OverviewWorkshops.fromJson(Map<String, dynamic> json) =>
      OverviewWorkshops(
        total: _countOrLength(json['total']),
        active: _countOrLength(json['active']),
      );
}

@immutable
class OverviewStaff {
  const OverviewStaff({required this.technicians, required this.admins});

  final int technicians;
  final int admins;

  factory OverviewStaff.fromJson(Map<String, dynamic> json) => OverviewStaff(
    technicians: _countOrLength(json['technicians']),
    admins: _countOrLength(json['admins']),
  );
}

@immutable
class OverviewJobs {
  const OverviewJobs({
    required this.active,
    required this.pendingReview,
    required this.byStatus,
  });

  final int active;
  final int pendingReview;
  final Map<String, int> byStatus;

  factory OverviewJobs.fromJson(Map<String, dynamic> json) => OverviewJobs(
    active: _countOrLength(json['active']),
    pendingReview: _countOrLength(
      json['pendingReview'] ?? json['pending_review'],
    ),
    byStatus: _countMap(
      json['byStatus'] ?? json['by_status'] ?? json['statusBreakdown'],
    ),
  );
}

@immutable
class OverviewReports {
  const OverviewReports({required this.published, required this.byMonth});

  final int published;
  final Map<String, int> byMonth;

  factory OverviewReports.fromJson(Map<String, dynamic> json) =>
      OverviewReports(
        published: _countOrLength(json['published']),
        byMonth: _countMap(
          json['byMonth'] ?? json['by_month'] ?? json['monthly'],
        ),
      );
}

@immutable
class OverviewChecklist {
  const OverviewChecklist({
    required this.categories,
    required this.items,
    required this.templates,
    required this.healthy,
    required this.issues,
  });

  final int categories;
  final int items;
  final int templates;
  final bool healthy;
  final int issues;

  factory OverviewChecklist.fromJson(Map<String, dynamic> json) {
    final issues = _countOrLength(json['issues']);
    return OverviewChecklist(
      categories: _countOrLength(json['categories']),
      items: _countOrLength(json['items']),
      templates: _countOrLength(json['templates']),
      healthy: json.containsKey('healthy')
          ? _flag(json['healthy'])
          : issues == 0,
      issues: issues,
    );
  }
}

@immutable
class OverviewLanguages {
  const OverviewLanguages({required this.live, required this.translating});

  final int live;
  final int translating;

  factory OverviewLanguages.fromJson(Map<String, dynamic> json) =>
      OverviewLanguages(
        live: _countOrLength(json['live']),
        translating: _countOrLength(json['translating']),
      );
}

@immutable
class OverviewActivityEntry {
  const OverviewActivityEntry({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.actor,
    required this.occurredAt,
  });

  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final String actor;
  final String occurredAt;

  factory OverviewActivityEntry.fromJson(Map<String, dynamic> json) =>
      OverviewActivityEntry(
        id: _str(json['id']),
        action: _str(json['action']),
        entityType: _str(json['entityType']),
        entityId: _str(json['entityId']),
        actor: _str(json['actor']).isNotEmpty
            ? _str(json['actor'])
            : _str(json['actorRole']),
        occurredAt: _str(json['occurredAt']).isNotEmpty
            ? _str(json['occurredAt'])
            : _str(json['at']).isNotEmpty
            ? _str(json['at'])
            : _str(json['timestamp']),
      );
}

@immutable
class OverviewAlert {
  const OverviewAlert({
    required this.severity,
    required this.title,
    required this.body,
    required this.route,
  });

  final String severity;
  final String title;
  final String body;
  final String route;

  factory OverviewAlert.fromJson(Map<String, dynamic> json) => OverviewAlert(
    severity: _str(json['severity']),
    title: _str(json['title']),
    body: _str(json['body']),
    route: _str(json['route']).isNotEmpty
        ? _str(json['route'])
        : _str(json['link']).isNotEmpty
        ? _str(json['link'])
        : _str(json['path']),
  );
}

/// Read-only dashboard aggregation. All fields optional with 0/empty
/// fallbacks; no scoring or weight fields.
@immutable
class OverviewSummary {
  const OverviewSummary({
    required this.workshops,
    required this.staff,
    required this.jobs,
    required this.reports,
    required this.checklist,
    required this.languages,
    required this.recentActivity,
    required this.alerts,
  });

  final OverviewWorkshops workshops;
  final OverviewStaff staff;
  final OverviewJobs jobs;
  final OverviewReports reports;
  final OverviewChecklist checklist;
  final OverviewLanguages languages;
  final List<OverviewActivityEntry> recentActivity;
  final List<OverviewAlert> alerts;

  static const OverviewSummary empty = OverviewSummary(
    workshops: OverviewWorkshops(total: 0, active: 0),
    staff: OverviewStaff(technicians: 0, admins: 0),
    jobs: OverviewJobs(active: 0, pendingReview: 0, byStatus: {}),
    reports: OverviewReports(published: 0, byMonth: {}),
    checklist: OverviewChecklist(
      categories: 0,
      items: 0,
      templates: 0,
      healthy: true,
      issues: 0,
    ),
    languages: OverviewLanguages(live: 0, translating: 0),
    recentActivity: [],
    alerts: [],
  );

  /// True while no workshop exists yet, regardless of seeded master content
  /// (categories, items, live languages) which must not block onboarding.
  bool get isEmpty =>
      workshops.total == 0 && recentActivity.isEmpty && jobs.active == 0;

  factory OverviewSummary.fromJson(Map<String, dynamic> json) =>
      OverviewSummary(
        workshops: OverviewWorkshops.fromJson(_safeMap(json['workshops'])),
        staff: OverviewStaff.fromJson(_safeMap(json['staff'])),
        jobs: OverviewJobs.fromJson(_safeMap(json['jobs'])),
        reports: OverviewReports.fromJson(_safeMap(json['reports'])),
        checklist: OverviewChecklist.fromJson(_safeMap(json['checklist'])),
        languages: OverviewLanguages.fromJson(_safeMap(json['languages'])),
        recentActivity:
            _safeList(json['recentActivity'] ?? json['recent_activity'])
                .map((item) => OverviewActivityEntry.fromJson(_safeMap(item)))
                .toList(growable: false),
        alerts: _safeList(json['alerts'])
            .map((item) => OverviewAlert.fromJson(_safeMap(item)))
            .toList(growable: false),
      );
}
