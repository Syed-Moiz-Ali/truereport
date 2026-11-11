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
    required this.weightPercentage,
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
  final double weightPercentage;
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
      weightPercentage: _num(json['weightPercentage']),
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
    'weightPercentage': weightPercentage,
    'sortOrder': sortOrder,
    'active': active,
    'status': status,
  };
}

@immutable
class CategoryWeightRow {
  const CategoryWeightRow({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.status,
    required this.weight,
  });

  final String id;
  final String code;
  final String nameEn;
  final String nameAr;
  final String status;
  final double weight;

  factory CategoryWeightRow.fromJson(Map<String, dynamic> json) =>
      CategoryWeightRow(
        id: _str(json['id']),
        code: _str(json['code']),
        nameEn: _str(json['nameEn']),
        nameAr: _str(json['nameAr']),
        status: _str(json['status']),
        weight: _num(json['weight']),
      );
}

@immutable
class CategoryWeightCheck {
  const CategoryWeightCheck({
    required this.valid,
    required this.total,
    required this.expected,
    required this.categories,
  });

  final bool valid;
  final double total;
  final double expected;
  final List<CategoryWeightRow> categories;

  factory CategoryWeightCheck.fromJson(Map<String, dynamic> json) =>
      CategoryWeightCheck(
        valid: json['valid'] as bool? ?? false,
        total: _num(json['total']),
        expected: _num(json['expected']),
        categories: (json['categories'] as List<dynamic>? ?? const [])
            .map((e) => CategoryWeightRow.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
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
        translations: (json['translations'] as Map<String, dynamic>? ?? {})
            .map(
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
class ScoreBand {
  const ScoreBand({
    required this.resultCode,
    required this.minScore,
    required this.maxScore,
    required this.defaultScore,
    required this.criteriaEn,
    required this.criteriaAr,
  });

  final String resultCode;
  final int minScore;
  final int maxScore;
  final int defaultScore;
  final String criteriaEn;
  final String criteriaAr;

  factory ScoreBand.fromJson(Map<String, dynamic> json) => ScoreBand(
    resultCode: _str(json['resultCode']),
    minScore: _int(json['minScore']),
    maxScore: _int(json['maxScore']),
    defaultScore: _int(json['defaultScore']),
    criteriaEn: _str(json['criteriaEn']),
    criteriaAr: _str(json['criteriaAr']),
  );

  Map<String, dynamic> toJson() => {
    'resultCode': resultCode,
    'minScore': minScore,
    'maxScore': maxScore,
    'defaultScore': defaultScore,
    'criteriaEn': criteriaEn,
    'criteriaAr': criteriaAr,
  };

  ScoreBand copyWith({
    String? resultCode,
    int? minScore,
    int? maxScore,
    int? defaultScore,
    String? criteriaEn,
    String? criteriaAr,
  }) => ScoreBand(
    resultCode: resultCode ?? this.resultCode,
    minScore: minScore ?? this.minScore,
    maxScore: maxScore ?? this.maxScore,
    defaultScore: defaultScore ?? this.defaultScore,
    criteriaEn: criteriaEn ?? this.criteriaEn,
    criteriaAr: criteriaAr ?? this.criteriaAr,
  );
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
    required this.defaultScore,
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
  final int defaultScore;
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
        defaultScore: _int(json['defaultScore']),
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
    'defaultScore': defaultScore,
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
    required this.scoreBands,
    required this.evidenceRules,
    required this.issueFields,
    required this.measurementBands,
  });

  final ItemMetadata metadata;
  final List<ScoreBand> scoreBands;
  final List<EvidenceRule> evidenceRules;
  final List<IssueField> issueFields;
  final List<MeasurementBand> measurementBands;

  factory ItemConfig.fromJson(Map<String, dynamic> json) => ItemConfig(
    metadata: ItemMetadata.fromJson(
      json['metadata'] as Map<String, dynamic>? ?? const {},
    ),
    scoreBands: (json['scoreBands'] as List<dynamic>? ?? const [])
        .map((e) => ScoreBand.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
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
  );
}

@immutable
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
    required this.itemWeight,
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
  final double? itemWeight;
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
    itemWeight: json['itemWeight'] == null ? null : _num(json['itemWeight']),
    sortOrder: _int(json['sortOrder']),
    included: json['included'] as bool? ?? true,
    itemStatus: _str(json['itemStatus']),
  );
}

@immutable
class WeightPreviewRow {
  const WeightPreviewRow({
    required this.itemVersionId,
    required this.itemCode,
    required this.labelEn,
    required this.labelAr,
    required this.categoryId,
    required this.categoryCode,
    required this.categoryWeight,
    required this.itemWeight,
    required this.normalizedWeight,
  });

  final String itemVersionId;
  final String itemCode;
  final String labelEn;
  final String labelAr;
  final String categoryId;
  final String categoryCode;
  final double categoryWeight;
  final double? itemWeight;
  final double normalizedWeight;

  factory WeightPreviewRow.fromJson(Map<String, dynamic> json) =>
      WeightPreviewRow(
        itemVersionId: _str(json['itemVersionId']),
        itemCode: _str(json['itemCode']),
        labelEn: _str(json['labelEn']),
        labelAr: _str(json['labelAr']),
        categoryId: _str(json['categoryId']),
        categoryCode: _str(json['categoryCode']),
        categoryWeight: _num(json['categoryWeight']),
        itemWeight: json['itemWeight'] == null ? null : _num(json['itemWeight']),
        normalizedWeight: _num(json['normalizedWeight']),
      );
}

@immutable
class WeightPreview {
  const WeightPreview({
    required this.mode,
    required this.itemCount,
    required this.categoryWeightTotal,
    required this.rows,
  });

  final String mode;
  final int itemCount;
  final double categoryWeightTotal;
  final List<WeightPreviewRow> rows;

  factory WeightPreview.fromJson(Map<String, dynamic> json) => WeightPreview(
    mode: _str(json['mode']),
    itemCount: _int(json['itemCount']),
    categoryWeightTotal: _num(json['categoryWeightTotal']),
    rows: (json['rows'] as List<dynamic>? ?? const [])
        .map((e) => WeightPreviewRow.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

@immutable
class ScoringRule {
  const ScoringRule({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.active,
    required this.categoryWeightMode,
    required this.hardFailCapEnabled,
    required this.hardFailCapGrade,
    required this.pendingApproval,
    required this.version,
  });

  final String id;
  final String code;
  final String nameEn;
  final String nameAr;
  final bool active;
  final String categoryWeightMode;
  final bool hardFailCapEnabled;
  final String hardFailCapGrade;
  final bool pendingApproval;
  final int version;

  factory ScoringRule.fromJson(Map<String, dynamic> json) => ScoringRule(
    id: _str(json['id']),
    code: _str(json['code']),
    nameEn: _str(json['nameEn']),
    nameAr: _str(json['nameAr']),
    active: json['active'] as bool? ?? true,
    categoryWeightMode: _str(json['categoryWeightMode']),
    hardFailCapEnabled: json['hardFailCapEnabled'] as bool? ?? true,
    hardFailCapGrade: _str(json['hardFailCapGrade']),
    pendingApproval: json['pendingApproval'] as bool? ?? false,
    version: _int(json['version']),
  );
}

@immutable
class GradeBoundary {
  const GradeBoundary({
    required this.gradeCode,
    required this.minScore,
    required this.maxScore,
    required this.labelEn,
    required this.labelAr,
    required this.sortOrder,
    required this.approved,
  });

  final String gradeCode;
  final int minScore;
  final int maxScore;
  final String labelEn;
  final String labelAr;
  final int sortOrder;
  final bool approved;

  factory GradeBoundary.fromJson(Map<String, dynamic> json) => GradeBoundary(
    gradeCode: _str(json['gradeCode']),
    minScore: _int(json['minScore']),
    maxScore: _int(json['maxScore']),
    labelEn: _str(json['labelEn']),
    labelAr: _str(json['labelAr']),
    sortOrder: _int(json['sortOrder']),
    approved: json['approved'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'gradeCode': gradeCode,
    'minScore': minScore,
    'maxScore': maxScore,
    'labelEn': labelEn,
    'labelAr': labelAr,
    'sortOrder': sortOrder,
    'approved': approved,
  };
}

@immutable
class ScoringRuleDetail {
  const ScoringRuleDetail({
    required this.rule,
    required this.gradeBoundaries,
  });

  final ScoringRule rule;
  final List<GradeBoundary> gradeBoundaries;

  factory ScoringRuleDetail.fromJson(Map<String, dynamic> json) =>
      ScoringRuleDetail(
        rule: ScoringRule.fromJson(json['rule'] as Map<String, dynamic>),
        gradeBoundaries: (json['gradeBoundaries'] as List<dynamic>? ?? const [])
            .map((e) => GradeBoundary.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
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
  });

  final String code;
  final String nameEn;
  final String nameAr;
  final String nativeName;
  final String direction;
  final bool active;
  final bool isDefault;
  final int sortOrder;

  factory PlatformLanguage.fromJson(Map<String, dynamic> json) =>
      PlatformLanguage(
        code: _str(json['code']),
        nameEn: _str(json['nameEn']),
        nameAr: _str(json['nameAr']),
        nativeName: _str(json['nativeName']),
        direction: _str(json['direction']),
        active: json['active'] as bool? ?? true,
        isDefault: json['default'] as bool? ?? json['isDefault'] as bool? ?? false,
        sortOrder: _int(json['sortOrder']),
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
