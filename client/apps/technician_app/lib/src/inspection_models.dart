// Clean technician inspection API models.
//
// These models mirror the `/api/v1/technician` contract exactly. Every
// `fromJson` parser is defensive so malformed or missing optional fields never
// crash the technician app while offline/cached payloads are replayed.

import 'package:api_client/api_client.dart';

String _string(dynamic value, [String fallback = '']) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

String? _stringOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value is String ? value : value.toString();
  return text.isEmpty ? null : text;
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
    final decimal = double.tryParse(value.trim());
    if (decimal != null) {
      return decimal.toInt();
    }
  }
  return fallback;
}

int? _intOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
    return double.tryParse(value.trim())?.toInt();
  }
  return null;
}

double? _doubleOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

bool _bool(dynamic value, [bool fallback = false]) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'n':
        return false;
    }
  }
  return fallback;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<dynamic> _list(dynamic value) {
  if (value is List) {
    return value;
  }
  return <dynamic>[];
}

List<String> _strings(dynamic value) =>
    _list(value).map((item) => _string(item)).toList(growable: false);

List<T> _mapped<T>(dynamic value, T Function(Map<String, dynamic>) parse) =>
    _list(value).map((item) => parse(_map(item))).toList(growable: false);

Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
  values.removeWhere((_, value) => value == null);
  return values;
}

class JobSummary {
  const JobSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.reviewStatus,
    required this.templateVersionId,
    required this.templateNameEn,
    required this.templateNameAr,
    required this.templateVersionNo,
    required this.assignedTechnicianId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.vehicleVin,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehiclePlate,
    required this.odometerValue,
    required this.odometerUnit,
    required this.transmission,
    required this.fuelType,
    required this.vehicleType,
    required this.preferredLanguage,
    required this.scheduledAt,
    required this.startedAt,
    required this.assessmentState,
    required this.completedItems,
    required this.totalItems,
    required this.version,
  });

  final String id;
  final String reference;
  final String status;
  final String? reviewStatus;
  final String templateVersionId;
  final String templateNameEn;
  final String templateNameAr;
  final int? templateVersionNo;
  final String? assignedTechnicianId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? vehicleVin;
  final String vehicleMake;
  final String vehicleModel;
  final int? vehicleYear;
  final String? vehiclePlate;
  final int? odometerValue;
  final String? odometerUnit;
  final String? transmission;
  final String? fuelType;
  final String? vehicleType;
  final String? preferredLanguage;
  final String? scheduledAt;
  final String? startedAt;
  final String? assessmentState;
  final int completedItems;
  final int totalItems;
  final int version;

  factory JobSummary.fromJson(Map<String, dynamic> json) => JobSummary(
    id: _string(json['id']),
    reference: _string(json['reference']),
    status: _string(json['status']),
    reviewStatus: _stringOrNull(json['reviewStatus']),
    templateVersionId: _string(json['templateVersionId']),
    templateNameEn: _string(json['templateNameEn']),
    templateNameAr: _string(json['templateNameAr']),
    templateVersionNo: _intOrNull(json['templateVersionNo']),
    assignedTechnicianId: _stringOrNull(json['assignedTechnicianId']),
    customerName: _string(json['customerName']),
    customerPhone: _stringOrNull(json['customerPhone']),
    customerEmail: _stringOrNull(json['customerEmail']),
    vehicleVin: _stringOrNull(json['vehicleVin']),
    vehicleMake: _string(json['vehicleMake']),
    vehicleModel: _string(json['vehicleModel']),
    vehicleYear: _intOrNull(json['vehicleYear']),
    vehiclePlate: _stringOrNull(json['vehiclePlate']),
    odometerValue: _intOrNull(json['odometerValue']),
    odometerUnit: _stringOrNull(json['odometerUnit']),
    transmission: _stringOrNull(json['transmission']),
    fuelType: _stringOrNull(json['fuelType']),
    vehicleType: _stringOrNull(json['vehicleType']),
    preferredLanguage: _stringOrNull(json['preferredLanguage']),
    scheduledAt: _stringOrNull(json['scheduledAt']),
    startedAt: _stringOrNull(json['startedAt']),
    assessmentState: _stringOrNull(json['assessmentState']),
    completedItems: _int(json['completedItems']),
    totalItems: _int(json['totalItems']),
    version: _int(json['version']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'status': status,
    'reviewStatus': reviewStatus,
    'templateVersionId': templateVersionId,
    'templateNameEn': templateNameEn,
    'templateNameAr': templateNameAr,
    'templateVersionNo': templateVersionNo,
    'assignedTechnicianId': assignedTechnicianId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'vehicleVin': vehicleVin,
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
    'vehicleYear': vehicleYear,
    'vehiclePlate': vehiclePlate,
    'odometerValue': odometerValue,
    'odometerUnit': odometerUnit,
    'transmission': transmission,
    'fuelType': fuelType,
    'vehicleType': vehicleType,
    'preferredLanguage': preferredLanguage,
    'scheduledAt': scheduledAt,
    'startedAt': startedAt,
    'assessmentState': assessmentState,
    'completedItems': completedItems,
    'totalItems': totalItems,
    'version': version,
  };

  String templateNameFor(String languageCode) =>
      languageCode == 'ar' ? templateNameAr : templateNameEn;
}

class JobSummaryPage {
  const JobSummaryPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
  });

  final List<JobSummary> items;
  final int page;
  final int size;
  final int total;
  final int totalPages;

  factory JobSummaryPage.fromJson(Map<String, dynamic> json) => JobSummaryPage(
    items: _mapped(json['items'], JobSummary.fromJson),
    page: _int(json['page']),
    size: _int(json['size']),
    total: _int(json['total']),
    totalPages: _int(json['totalPages']),
  );

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'page': page,
    'size': size,
    'total': total,
    'totalPages': totalPages,
  };
}

class PinnedTemplate {
  const PinnedTemplate({
    required this.templateVersionId,
    required this.templateVersionNo,
    required this.snapshotHash,
  });

  final String templateVersionId;
  final int? templateVersionNo;
  final String? snapshotHash;

  factory PinnedTemplate.fromJson(Map<String, dynamic> json) => PinnedTemplate(
    templateVersionId: _string(json['templateVersionId']),
    templateVersionNo: _intOrNull(json['templateVersionNo']),
    snapshotHash: _stringOrNull(json['snapshotHash']),
  );

  Map<String, dynamic> toJson() => {
    'templateVersionId': templateVersionId,
    'templateVersionNo': templateVersionNo,
    'snapshotHash': snapshotHash,
  };
}

class Category {
  const Category({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.iconCode,
    required this.sortOrder,
  });

  final String code;
  final String nameEn;
  final String nameAr;
  final String? iconCode;
  final int sortOrder;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    code: _string(json['code']),
    nameEn: _string(json['nameEn']),
    nameAr: _string(json['nameAr']),
    iconCode: _stringOrNull(json['iconCode']),
    sortOrder: _int(json['sortOrder']),
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'nameEn': nameEn,
    'nameAr': nameAr,
    'iconCode': iconCode,
    'sortOrder': sortOrder,
  };

  String nameFor(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;
}

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
    resultCode: _string(json['resultCode']),
    minScore: _int(json['minScore']),
    maxScore: _int(json['maxScore']),
    defaultScore: _int(json['defaultScore']),
    criteriaEn: _string(json['criteriaEn']),
    criteriaAr: _string(json['criteriaAr']),
  );

  Map<String, dynamic> toJson() => {
    'resultCode': resultCode,
    'minScore': minScore,
    'maxScore': maxScore,
    'defaultScore': defaultScore,
    'criteriaEn': criteriaEn,
    'criteriaAr': criteriaAr,
  };
}

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
  final String? requiredEvidenceType;

  factory EvidenceRule.fromJson(Map<String, dynamic> json) => EvidenceRule(
    resultCode: _string(json['resultCode']),
    minPhotos: _int(json['minPhotos']),
    minVideos: _int(json['minVideos']),
    minNotesChars: _int(json['minNotesChars']),
    requiredEvidenceType: _stringOrNull(json['requiredEvidenceType']),
  );

  Map<String, dynamic> toJson() => {
    'resultCode': resultCode,
    'minPhotos': minPhotos,
    'minVideos': minVideos,
    'minNotesChars': minNotesChars,
    'requiredEvidenceType': requiredEvidenceType,
  };
}

class IssueOption {
  const IssueOption({
    required this.code,
    required this.labelEn,
    required this.labelAr,
    required this.sortOrder,
  });

  final String code;
  final String labelEn;
  final String labelAr;
  final int sortOrder;

  factory IssueOption.fromJson(Map<String, dynamic> json) => IssueOption(
    code: _string(json['code']),
    labelEn: _string(json['labelEn']),
    labelAr: _string(json['labelAr']),
    sortOrder: _int(json['sortOrder']),
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'labelEn': labelEn,
    'labelAr': labelAr,
    'sortOrder': sortOrder,
  };

  String labelFor(String languageCode) =>
      languageCode == 'ar' ? labelAr : labelEn;
}

class IssueField {
  const IssueField({
    required this.fieldCode,
    required this.labelEn,
    required this.labelAr,
    required this.inputType,
    required this.optionSetCode,
    required this.options,
    required this.allowedOptionCodes,
    required this.required,
    required this.requiredForStatuses,
    required this.minValue,
    required this.maxValue,
    required this.decimalPlaces,
    required this.unitSetCode,
    required this.dependsOnFieldCode,
    required this.dependsOnValueCode,
    required this.allowMultiple,
    required this.allowFreeText,
    required this.sortOrder,
  });

  final String fieldCode;
  final String labelEn;
  final String labelAr;
  final String inputType;
  final String? optionSetCode;
  final List<IssueOption> options;
  final List<String> allowedOptionCodes;
  final bool required;
  final List<String> requiredForStatuses;
  final double? minValue;
  final double? maxValue;
  final int? decimalPlaces;
  final String? unitSetCode;
  final String? dependsOnFieldCode;
  final String? dependsOnValueCode;
  final bool allowMultiple;
  final bool allowFreeText;
  final int sortOrder;

  factory IssueField.fromJson(Map<String, dynamic> json) => IssueField(
    fieldCode: _string(json['fieldCode']),
    labelEn: _string(json['labelEn']),
    labelAr: _string(json['labelAr']),
    inputType: _string(json['inputType']),
    optionSetCode: _stringOrNull(json['optionSetCode']),
    options: _mapped(json['options'], IssueOption.fromJson),
    allowedOptionCodes: _strings(json['allowedOptionCodes']),
    required: _bool(json['required']),
    requiredForStatuses: _strings(json['requiredForStatuses']),
    minValue: _doubleOrNull(json['minValue']),
    maxValue: _doubleOrNull(json['maxValue']),
    decimalPlaces: _intOrNull(json['decimalPlaces']),
    unitSetCode: _stringOrNull(json['unitSetCode']),
    dependsOnFieldCode: _stringOrNull(json['dependsOnFieldCode']),
    dependsOnValueCode: _stringOrNull(json['dependsOnValueCode']),
    allowMultiple: _bool(json['allowMultiple']),
    allowFreeText: _bool(json['allowFreeText']),
    sortOrder: _int(json['sortOrder']),
  );

  Map<String, dynamic> toJson() => {
    'fieldCode': fieldCode,
    'labelEn': labelEn,
    'labelAr': labelAr,
    'inputType': inputType,
    'optionSetCode': optionSetCode,
    'options': options.map((option) => option.toJson()).toList(growable: false),
    'allowedOptionCodes': allowedOptionCodes,
    'required': required,
    'requiredForStatuses': requiredForStatuses,
    'minValue': minValue,
    'maxValue': maxValue,
    'decimalPlaces': decimalPlaces,
    'unitSetCode': unitSetCode,
    'dependsOnFieldCode': dependsOnFieldCode,
    'dependsOnValueCode': dependsOnValueCode,
    'allowMultiple': allowMultiple,
    'allowFreeText': allowFreeText,
    'sortOrder': sortOrder,
  };

  String labelFor(String languageCode) =>
      languageCode == 'ar' ? labelAr : labelEn;

  bool isAllowed(String optionCode) {
    if (allowedOptionCodes.isNotEmpty) {
      return allowedOptionCodes.contains(optionCode);
    }
    return options.isEmpty ||
        options.any((option) => option.code == optionCode);
  }
}

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
  });

  final String fieldCode;
  final String? unitCode;
  final String? direction;
  final double? minValue;
  final double? maxValue;
  final String resultCode;
  final int defaultScore;
  final String labelEn;
  final String labelAr;

  factory MeasurementBand.fromJson(Map<String, dynamic> json) =>
      MeasurementBand(
        fieldCode: _string(json['fieldCode']),
        unitCode: _stringOrNull(json['unitCode']),
        direction: _stringOrNull(json['direction']),
        minValue: _doubleOrNull(json['minValue']),
        maxValue: _doubleOrNull(json['maxValue']),
        resultCode: _string(json['resultCode']),
        defaultScore: _int(json['defaultScore']),
        labelEn: _string(json['labelEn']),
        labelAr: _string(json['labelAr']),
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
  };

  String labelFor(String languageCode) =>
      languageCode == 'ar' ? labelAr : labelEn;

  bool contains(double value) {
    final low = minValue;
    final high = maxValue;
    if (low != null && value < low) {
      return false;
    }
    if (high != null && value > high) {
      return false;
    }
    return true;
  }
}

class IssueValue {
  const IssueValue({
    required this.fieldCode,
    required this.valueIndex,
    required this.optionValueCode,
    required this.numericValue,
    required this.unitCode,
    required this.textValue,
  });

  final String fieldCode;
  final String? valueIndex;
  final String? optionValueCode;
  final double? numericValue;
  final String? unitCode;
  final String? textValue;

  factory IssueValue.fromJson(Map<String, dynamic> json) => IssueValue(
    fieldCode: _string(json['fieldCode']),
    valueIndex: _stringOrNull(json['valueIndex']),
    optionValueCode: _stringOrNull(json['optionValueCode']),
    numericValue: _doubleOrNull(json['numericValue']),
    unitCode: _stringOrNull(json['unitCode']),
    textValue: _stringOrNull(json['textValue']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'fieldCode': fieldCode,
    'valueIndex': valueIndex,
    'optionValueCode': optionValueCode,
    'numericValue': numericValue,
    'unitCode': unitCode,
    'textValue': textValue,
  });
}

class Measurement {
  const Measurement({
    required this.fieldCode,
    required this.valueIndex,
    required this.numericValue,
    required this.unitCode,
  });

  final String fieldCode;
  final String? valueIndex;
  final double? numericValue;
  final String? unitCode;

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
    fieldCode: _string(json['fieldCode']),
    valueIndex: _stringOrNull(json['valueIndex']),
    numericValue: _doubleOrNull(json['numericValue']),
    unitCode: _stringOrNull(json['unitCode']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'fieldCode': fieldCode,
    'valueIndex': valueIndex,
    'numericValue': numericValue,
    'unitCode': unitCode,
  });
}

class Assessment {
  const Assessment({
    required this.id,
    required this.itemCode,
    required this.itemVersionId,
    required this.resultCode,
    required this.severityCode,
    required this.score,
    required this.suggestedResultCode,
    required this.suggestedScore,
    required this.bandResultCode,
    required this.state,
    required this.clientRevision,
    required this.serverRevision,
    required this.notesEn,
    required this.notesAr,
    required this.reasonCode,
    required this.version,
    required this.issueValues,
    required this.measurements,
    required this.evidence,
  });

  final String? id;
  final String itemCode;
  final String? itemVersionId;
  final String? resultCode;
  final String? severityCode;
  final int? score;
  final String? suggestedResultCode;
  final int? suggestedScore;
  final String? bandResultCode;
  final String? state;
  final int clientRevision;
  final int serverRevision;
  final String? notesEn;
  final String? notesAr;
  final String? reasonCode;
  final int version;
  final List<IssueValue> issueValues;
  final List<Measurement> measurements;
  final List<Evidence> evidence;

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
    id: _stringOrNull(json['id']),
    itemCode: _string(json['itemCode']),
    itemVersionId: _stringOrNull(json['itemVersionId']),
    resultCode: _stringOrNull(json['resultCode']),
    severityCode: _stringOrNull(json['severityCode']),
    score: _intOrNull(json['score']),
    suggestedResultCode: _stringOrNull(json['suggestedResultCode']),
    suggestedScore: _intOrNull(json['suggestedScore']),
    bandResultCode: _stringOrNull(json['bandResultCode']),
    state: _stringOrNull(json['state']),
    clientRevision: _int(json['clientRevision']),
    serverRevision: _int(json['serverRevision']),
    notesEn: _stringOrNull(json['notesEn']),
    notesAr: _stringOrNull(json['notesAr']),
    reasonCode: _stringOrNull(json['reasonCode']),
    version: _int(json['version']),
    issueValues: _mapped(json['issueValues'], IssueValue.fromJson),
    measurements: _mapped(json['measurements'], Measurement.fromJson),
    evidence: _mapped(json['evidence'], Evidence.fromJson),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemCode': itemCode,
    'itemVersionId': itemVersionId,
    'resultCode': resultCode,
    'severityCode': severityCode,
    'score': score,
    'suggestedResultCode': suggestedResultCode,
    'suggestedScore': suggestedScore,
    'bandResultCode': bandResultCode,
    'state': state,
    'clientRevision': clientRevision,
    'serverRevision': serverRevision,
    'notesEn': notesEn,
    'notesAr': notesAr,
    'reasonCode': reasonCode,
    'version': version,
    'issueValues': issueValues
        .map((value) => value.toJson())
        .toList(growable: false),
    'measurements': measurements
        .map((value) => value.toJson())
        .toList(growable: false),
    'evidence': evidence.map((value) => value.toJson()).toList(growable: false),
  };
}

class ChecklistItem {
  const ChecklistItem({
    required this.itemCode,
    required this.itemVersionId,
    required this.categoryCode,
    required this.sortOrder,
    required this.labelEn,
    required this.labelAr,
    required this.instructionEn,
    required this.instructionAr,
    required this.standardSpecEn,
    required this.standardSpecAr,
    required this.measurementUnit,
    required this.sensorTool,
    required this.safetyCritical,
    required this.multiPoint,
    required this.multiPointIndexes,
    required this.allowFreeTextNote,
    required this.noteRequirement,
    required this.resultOptions,
    required this.scoreBands,
    required this.evidenceRules,
    required this.issueFields,
    required this.measurementBands,
    required this.assessment,
  });

  final String itemCode;
  final String itemVersionId;
  final String categoryCode;
  final int sortOrder;
  final String labelEn;
  final String labelAr;
  final String? instructionEn;
  final String? instructionAr;
  final String? standardSpecEn;
  final String? standardSpecAr;
  final String? measurementUnit;
  final String? sensorTool;
  final bool safetyCritical;
  final bool multiPoint;
  final List<String> multiPointIndexes;
  final bool allowFreeTextNote;
  final String? noteRequirement;
  final List<String> resultOptions;
  final List<ScoreBand> scoreBands;
  final List<EvidenceRule> evidenceRules;
  final List<IssueField> issueFields;
  final List<MeasurementBand> measurementBands;
  final Assessment? assessment;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    itemCode: _string(json['itemCode']),
    itemVersionId: _string(json['itemVersionId']),
    categoryCode: _string(json['categoryCode']),
    sortOrder: _int(json['sortOrder']),
    labelEn: _string(json['labelEn']),
    labelAr: _string(json['labelAr']),
    instructionEn: _stringOrNull(json['instructionEn']),
    instructionAr: _stringOrNull(json['instructionAr']),
    standardSpecEn: _stringOrNull(json['standardSpecEn']),
    standardSpecAr: _stringOrNull(json['standardSpecAr']),
    measurementUnit: _stringOrNull(json['measurementUnit']),
    sensorTool: _stringOrNull(json['sensorTool']),
    safetyCritical: _bool(json['safetyCritical']),
    multiPoint: _bool(json['multiPoint']),
    multiPointIndexes: _strings(json['multiPointIndexes']),
    allowFreeTextNote: _bool(json['allowFreeTextNote']),
    noteRequirement: _stringOrNull(json['noteRequirement']),
    resultOptions: _strings(json['resultOptions']),
    scoreBands: _mapped(json['scoreBands'], ScoreBand.fromJson),
    evidenceRules: _mapped(json['evidenceRules'], EvidenceRule.fromJson),
    issueFields: _mapped(json['issueFields'], IssueField.fromJson),
    measurementBands: _mapped(
      json['measurementBands'],
      MeasurementBand.fromJson,
    ),
    assessment: json['assessment'] == null
        ? null
        : Assessment.fromJson(_map(json['assessment'])),
  );

  Map<String, dynamic> toJson() => {
    'itemCode': itemCode,
    'itemVersionId': itemVersionId,
    'categoryCode': categoryCode,
    'sortOrder': sortOrder,
    'labelEn': labelEn,
    'labelAr': labelAr,
    'instructionEn': instructionEn,
    'instructionAr': instructionAr,
    'standardSpecEn': standardSpecEn,
    'standardSpecAr': standardSpecAr,
    'measurementUnit': measurementUnit,
    'sensorTool': sensorTool,
    'safetyCritical': safetyCritical,
    'multiPoint': multiPoint,
    'multiPointIndexes': multiPointIndexes,
    'allowFreeTextNote': allowFreeTextNote,
    'noteRequirement': noteRequirement,
    'resultOptions': resultOptions,
    'scoreBands': scoreBands
        .map((band) => band.toJson())
        .toList(growable: false),
    'evidenceRules': evidenceRules
        .map((rule) => rule.toJson())
        .toList(growable: false),
    'issueFields': issueFields
        .map((field) => field.toJson())
        .toList(growable: false),
    'measurementBands': measurementBands
        .map((band) => band.toJson())
        .toList(growable: false),
    'assessment': assessment?.toJson(),
  };

  String labelFor(String languageCode) =>
      languageCode == 'ar' ? labelAr : labelEn;

  String? instructionFor(String languageCode) =>
      languageCode == 'ar' ? instructionAr : instructionEn;

  String? standardSpecFor(String languageCode) =>
      languageCode == 'ar' ? standardSpecAr : standardSpecEn;

  IssueField? field(String fieldCode) {
    for (final field in issueFields) {
      if (field.fieldCode == fieldCode) {
        return field;
      }
    }
    return null;
  }

  MeasurementBand? bandForValue(double value) {
    for (final band in measurementBands) {
      if (band.contains(value)) {
        return band;
      }
    }
    return null;
  }
}

class ChecklistProgress {
  const ChecklistProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  factory ChecklistProgress.fromJson(Map<String, dynamic> json) =>
      ChecklistProgress(
        completed: _int(json['completed']),
        total: _int(json['total']),
      );

  Map<String, dynamic> toJson() => {'completed': completed, 'total': total};
}

class Checklist {
  const Checklist({
    required this.job,
    required this.pinned,
    required this.categories,
    required this.items,
    required this.progress,
    required this.serverRevision,
  });

  final JobSummary job;
  final PinnedTemplate? pinned;
  final List<Category> categories;
  final List<ChecklistItem> items;
  final ChecklistProgress progress;
  final int serverRevision;

  factory Checklist.fromJson(Map<String, dynamic> json) => Checklist(
    job: JobSummary.fromJson(_map(json['job'])),
    pinned: json['pinned'] == null
        ? null
        : PinnedTemplate.fromJson(_map(json['pinned'])),
    categories: _mapped(json['categories'], Category.fromJson),
    items: _mapped(json['items'], ChecklistItem.fromJson),
    progress: ChecklistProgress.fromJson(_map(json['progress'])),
    serverRevision: _int(json['serverRevision']),
  );

  Map<String, dynamic> toJson() => {
    'job': job.toJson(),
    'pinned': pinned?.toJson(),
    'categories': categories
        .map((category) => category.toJson())
        .toList(growable: false),
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'progress': progress.toJson(),
    'serverRevision': serverRevision,
  };

  int get completed => progress.completed;
  int get total => progress.total;

  List<ChecklistItem> itemsForCategory(String categoryCode) => items
      .where((item) => item.categoryCode == categoryCode)
      .toList(growable: false);

  ChecklistItem? item(String itemCode) {
    for (final item in items) {
      if (item.itemCode == itemCode) {
        return item;
      }
    }
    return null;
  }
}

class AssessmentRequest {
  const AssessmentRequest({
    required this.baseVersion,
    required this.clientRevision,
    required this.resultCode,
    this.score,
    this.severityCode,
    this.notesEn,
    this.notesAr,
    this.reasonCode,
    this.issueValues = const <IssueValue>[],
    this.measurements = const <Measurement>[],
  });

  final int baseVersion;
  final int clientRevision;
  final String resultCode;
  final int? score;
  final String? severityCode;
  final String? notesEn;
  final String? notesAr;
  final String? reasonCode;
  final List<IssueValue> issueValues;
  final List<Measurement> measurements;

  Map<String, dynamic> toJson() => {
    'baseVersion': baseVersion,
    'clientRevision': clientRevision,
    'resultCode': resultCode,
    'score': score,
    'severityCode': severityCode,
    'notesEn': notesEn,
    'notesAr': notesAr,
    'reasonCode': reasonCode,
    'issueValues': issueValues
        .map((value) => value.toJson())
        .toList(growable: false),
    'measurements': measurements
        .map((value) => value.toJson())
        .toList(growable: false),
  };
}

class Blocker {
  const Blocker({
    required this.code,
    required this.itemCode,
    required this.messageEn,
    required this.messageAr,
  });

  final String code;
  final String? itemCode;
  final String messageEn;
  final String messageAr;

  factory Blocker.fromJson(Map<String, dynamic> json) => Blocker(
    code: _string(json['code']),
    itemCode: _stringOrNull(json['itemCode']),
    messageEn: _string(json['messageEn']),
    messageAr: _string(json['messageAr']),
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'itemCode': itemCode,
    'messageEn': messageEn,
    'messageAr': messageAr,
  };

  String messageFor(String languageCode) =>
      languageCode == 'ar' && messageAr.isNotEmpty ? messageAr : messageEn;
}

List<Blocker> _blockers(dynamic value) => _list(value)
    .map((item) {
      if (item is Map) {
        return Blocker.fromJson(_map(item));
      }
      final message = _string(item);
      return Blocker(
        code: '',
        itemCode: null,
        messageEn: message,
        messageAr: message,
      );
    })
    .toList(growable: false);

class Summary {
  const Summary({
    required this.jobId,
    required this.status,
    required this.itemsAssessed,
    required this.itemsTotal,
    required this.score,
    required this.gradeCode,
    required this.safetyCapApplied,
    required this.safetyCapReason,
    required this.blockers,
    required this.warnings,
  });

  final String jobId;
  final String status;
  final int itemsAssessed;
  final int itemsTotal;
  final int? score;
  final String? gradeCode;
  final bool safetyCapApplied;
  final String? safetyCapReason;
  final List<Blocker> blockers;
  final List<Blocker> warnings;

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    jobId: _string(json['jobId']),
    status: _string(json['status']),
    itemsAssessed: _int(json['itemsAssessed']),
    itemsTotal: _int(json['itemsTotal']),
    score: _intOrNull(json['score']),
    gradeCode: _stringOrNull(json['gradeCode']),
    safetyCapApplied: _bool(json['safetyCapApplied']),
    safetyCapReason: _stringOrNull(json['safetyCapReason']),
    blockers: _blockers(json['blockers']),
    warnings: _blockers(json['warnings']),
  );

  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'status': status,
    'itemsAssessed': itemsAssessed,
    'itemsTotal': itemsTotal,
    'score': score,
    'gradeCode': gradeCode,
    'safetyCapApplied': safetyCapApplied,
    'safetyCapReason': safetyCapReason,
    'blockers': blockers.map((value) => value.toJson()).toList(growable: false),
    'warnings': warnings.map((value) => value.toJson()).toList(growable: false),
  };

  bool get isComplete => itemsTotal > 0 && itemsAssessed >= itemsTotal;
}

class Review {
  const Review({
    required this.jobId,
    required this.status,
    required this.blockers,
    required this.warnings,
    required this.findings,
  });

  final String jobId;
  final String status;
  final List<Blocker> blockers;
  final List<Blocker> warnings;
  final List<Map<String, dynamic>> findings;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    jobId: _string(json['jobId']),
    status: _string(json['status']),
    blockers: _blockers(json['blockers']),
    warnings: _blockers(json['warnings']),
    findings: _list(json['findings'])
        .map((item) => _map(item))
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'status': status,
    'blockers': blockers.map((value) => value.toJson()).toList(growable: false),
    'warnings': warnings.map((value) => value.toJson()).toList(growable: false),
    'findings': findings,
  };

  bool get ready => blockers.isEmpty;
}

class Evidence {
  const Evidence({
    required this.id,
    required this.jobId,
    required this.itemCode,
    required this.type,
    required this.status,
    required this.mime,
    required this.bytes,
    required this.sha256,
    required this.capturedAt,
    required this.captureSource,
    required this.deviceId,
    required this.width,
    required this.height,
    required this.durationMs,
    required this.captionEn,
    required this.captionAr,
    required this.posterAvailable,
    required this.qualityStatus,
    required this.contentUrl,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String itemCode;
  final String type;
  final String status;
  final String? mime;
  final int bytes;
  final String? sha256;
  final String? capturedAt;
  final String? captureSource;
  final String? deviceId;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? captionEn;
  final String? captionAr;
  final bool posterAvailable;
  final String? qualityStatus;
  final String? contentUrl;
  final String? createdAt;

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: _string(json['id']),
    jobId: _string(json['jobId']),
    itemCode: _string(json['itemCode']),
    type: _string(json['type']),
    status: _string(json['status']),
    mime: _stringOrNull(json['mime']),
    bytes: _int(json['bytes']),
    sha256: _stringOrNull(json['sha256']),
    capturedAt: _stringOrNull(json['capturedAt']),
    captureSource: _stringOrNull(json['captureSource']),
    deviceId: _stringOrNull(json['deviceId']),
    width: _intOrNull(json['width']),
    height: _intOrNull(json['height']),
    durationMs: _intOrNull(json['durationMs']),
    captionEn: _stringOrNull(json['captionEn']),
    captionAr: _stringOrNull(json['captionAr']),
    posterAvailable: _bool(json['posterAvailable']),
    qualityStatus: _stringOrNull(json['qualityStatus']),
    contentUrl: _stringOrNull(json['contentUrl']),
    createdAt: _stringOrNull(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'jobId': jobId,
    'itemCode': itemCode,
    'type': type,
    'status': status,
    'mime': mime,
    'bytes': bytes,
    'sha256': sha256,
    'capturedAt': capturedAt,
    'captureSource': captureSource,
    'deviceId': deviceId,
    'width': width,
    'height': height,
    'durationMs': durationMs,
    'captionEn': captionEn,
    'captionAr': captionAr,
    'posterAvailable': posterAvailable,
    'qualityStatus': qualityStatus,
    'contentUrl': contentUrl,
    'createdAt': createdAt,
  };

  String? captionFor(String languageCode) =>
      languageCode == 'ar' && (captionAr?.isNotEmpty ?? false)
      ? captionAr
      : captionEn;

  bool get isPhoto => type == 'PHOTO';
  bool get isVideo => type == 'VIDEO';
  bool get isDocument => type == 'DOCUMENT';
}

class EvidenceInitRequest {
  const EvidenceInitRequest({
    required this.type,
    required this.mime,
    required this.bytes,
    required this.sha256,
    this.capturedAt,
    this.captureSource,
    this.deviceId,
    this.width,
    this.height,
    this.durationMs,
    this.captionEn,
    this.captionAr,
    this.posterBase64,
  });

  final String type;
  final String mime;
  final int bytes;
  final String sha256;
  final String? capturedAt;
  final String? captureSource;
  final String? deviceId;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? captionEn;
  final String? captionAr;
  final String? posterBase64;

  Map<String, dynamic> toJson() => {
    'type': type,
    'mime': mime,
    'bytes': bytes,
    'sha256': sha256,
    'capturedAt': capturedAt,
    'captureSource': captureSource,
    'deviceId': deviceId,
    'width': width,
    'height': height,
    'durationMs': durationMs,
    'captionEn': captionEn,
    'captionAr': captionAr,
    'posterBase64': posterBase64,
  };
}

class EvidenceCompleteRequest {
  const EvidenceCompleteRequest({
    this.captionEn,
    this.captionAr,
    this.posterBase64,
  });

  final String? captionEn;
  final String? captionAr;
  final String? posterBase64;

  Map<String, dynamic> toJson() => {
    'captionEn': captionEn,
    'captionAr': captionAr,
    'posterBase64': posterBase64,
  };
}

class SignatureRequest {
  const SignatureRequest({
    required this.signerName,
    required this.signatureBase64,
    this.deviceId,
    this.method,
    this.mime,
  });

  final String signerName;
  final String? deviceId;
  final String? method;
  final String signatureBase64;
  final String? mime;

  Map<String, dynamic> toJson() => {
    'signerName': signerName,
    'deviceId': deviceId,
    'method': method,
    'signatureBase64': signatureBase64,
    'mime': mime,
  };
}

class Signature {
  const Signature({
    required this.jobId,
    required this.signerName,
    required this.signedAt,
    required this.deviceId,
    required this.method,
    required this.signatureHash,
  });

  final String jobId;
  final String signerName;
  final String? signedAt;
  final String? deviceId;
  final String? method;
  final String? signatureHash;

  factory Signature.fromJson(Map<String, dynamic> json) => Signature(
    jobId: _string(json['jobId']),
    signerName: _string(json['signerName']),
    signedAt: _stringOrNull(json['signedAt']),
    deviceId: _stringOrNull(json['deviceId']),
    method: _stringOrNull(json['method']),
    signatureHash: _stringOrNull(json['signatureHash']),
  );

  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'signerName': signerName,
    'signedAt': signedAt,
    'deviceId': deviceId,
    'method': method,
    'signatureHash': signatureHash,
  };
}

class CompleteRequest {
  const CompleteRequest({required this.clientRevision});

  final int clientRevision;

  Map<String, dynamic> toJson() => {'clientRevision': clientRevision};
}

class CompleteResult {
  const CompleteResult({
    required this.jobId,
    required this.status,
    required this.completedAt,
    required this.score,
    required this.gradeCode,
    required this.safetyCapApplied,
    required this.blockers,
  });

  final String jobId;
  final String status;
  final String? completedAt;
  final int? score;
  final String? gradeCode;
  final bool safetyCapApplied;
  final List<Blocker> blockers;

  factory CompleteResult.fromJson(Map<String, dynamic> json) => CompleteResult(
    jobId: _string(json['jobId']),
    status: _string(json['status']),
    completedAt: _stringOrNull(json['completedAt']),
    score: _intOrNull(json['score']),
    gradeCode: _stringOrNull(json['gradeCode']),
    safetyCapApplied: _bool(json['safetyCapApplied']),
    blockers: _blockers(json['blockers']),
  );

  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'status': status,
    'completedAt': completedAt,
    'score': score,
    'gradeCode': gradeCode,
    'safetyCapApplied': safetyCapApplied,
    'blockers': blockers.map((value) => value.toJson()).toList(growable: false),
  };
}

class SyncMutation {
  const SyncMutation({
    required this.idempotencyKey,
    required this.itemCode,
    required this.baseVersion,
    required this.clientRevision,
    required this.resultCode,
    this.score,
    this.severityCode,
    this.notesEn,
    this.notesAr,
    this.reasonCode,
    this.issueValues = const <IssueValue>[],
    this.measurements = const <Measurement>[],
  });

  final String idempotencyKey;
  final String itemCode;
  final int baseVersion;
  final int clientRevision;
  final String resultCode;
  final int? score;
  final String? severityCode;
  final String? notesEn;
  final String? notesAr;
  final String? reasonCode;
  final List<IssueValue> issueValues;
  final List<Measurement> measurements;

  factory SyncMutation.fromJson(Map<String, dynamic> json) => SyncMutation(
    idempotencyKey: _string(json['idempotencyKey']),
    itemCode: _string(json['itemCode']),
    baseVersion: _int(json['baseVersion']),
    clientRevision: _int(json['clientRevision']),
    resultCode: _string(json['resultCode']),
    score: _intOrNull(json['score']),
    severityCode: _stringOrNull(json['severityCode']),
    notesEn: _stringOrNull(json['notesEn']),
    notesAr: _stringOrNull(json['notesAr']),
    reasonCode: _stringOrNull(json['reasonCode']),
    issueValues: _mapped(json['issueValues'], IssueValue.fromJson),
    measurements: _mapped(json['measurements'], Measurement.fromJson),
  );

  Map<String, dynamic> toJson() => {
    'idempotencyKey': idempotencyKey,
    'itemCode': itemCode,
    'baseVersion': baseVersion,
    'clientRevision': clientRevision,
    'resultCode': resultCode,
    'score': score,
    'severityCode': severityCode,
    'notesEn': notesEn,
    'notesAr': notesAr,
    'reasonCode': reasonCode,
    'issueValues': issueValues
        .map((value) => value.toJson())
        .toList(growable: false),
    'measurements': measurements
        .map((value) => value.toJson())
        .toList(growable: false),
  };

  factory SyncMutation.fromRequest({
    required String idempotencyKey,
    required String itemCode,
    required AssessmentRequest request,
  }) => SyncMutation(
    idempotencyKey: idempotencyKey,
    itemCode: itemCode,
    baseVersion: request.baseVersion,
    clientRevision: request.clientRevision,
    resultCode: request.resultCode,
    score: request.score,
    severityCode: request.severityCode,
    notesEn: request.notesEn,
    notesAr: request.notesAr,
    reasonCode: request.reasonCode,
    issueValues: request.issueValues,
    measurements: request.measurements,
  );
}

class SyncRequest {
  const SyncRequest({required this.clientRevision, required this.mutations});

  final int clientRevision;
  final List<SyncMutation> mutations;

  Map<String, dynamic> toJson() => {
    'clientRevision': clientRevision,
    'mutations': mutations
        .map((mutation) => mutation.toJson())
        .toList(growable: false),
  };
}

class Conflict {
  const Conflict({
    required this.itemCode,
    required this.clientRevision,
    required this.serverRevision,
    required this.serverPayloadJson,
    required this.clientPayloadJson,
  });

  final String itemCode;
  final int clientRevision;
  final int serverRevision;
  final String? serverPayloadJson;
  final String? clientPayloadJson;

  factory Conflict.fromJson(Map<String, dynamic> json) => Conflict(
    itemCode: _string(json['itemCode']),
    clientRevision: _int(json['clientRevision']),
    serverRevision: _int(json['serverRevision']),
    serverPayloadJson: _stringOrNull(json['serverPayloadJson']),
    clientPayloadJson: _stringOrNull(json['clientPayloadJson']),
  );

  Map<String, dynamic> toJson() => {
    'itemCode': itemCode,
    'clientRevision': clientRevision,
    'serverRevision': serverRevision,
    'serverPayloadJson': serverPayloadJson,
    'clientPayloadJson': clientPayloadJson,
  };
}

class SyncResult {
  const SyncResult({
    required this.applied,
    required this.conflicts,
    required this.jobVersion,
  });

  final int applied;
  final List<Conflict> conflicts;
  final int jobVersion;

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
    applied: _int(json['applied']),
    conflicts: _mapped(json['conflicts'], Conflict.fromJson),
    jobVersion: _int(json['jobVersion']),
  );

  Map<String, dynamic> toJson() => {
    'applied': applied,
    'conflicts': conflicts
        .map((conflict) => conflict.toJson())
        .toList(growable: false),
    'jobVersion': jobVersion,
  };

  bool get hasConflicts => conflicts.isNotEmpty;
}

/// Inline field error returned by the localized ProblemDetails payload.
class ApiFieldError {
  const ApiFieldError({
    required this.field,
    required this.code,
    required this.messageEn,
    required this.messageAr,
  });

  final String field;
  final String code;
  final String messageEn;
  final String messageAr;

  factory ApiFieldError.fromJson(Map<String, dynamic> json) => ApiFieldError(
    field: _string(json['field']),
    code: _string(json['code']),
    messageEn: _string(json['messageEn']),
    messageAr: _string(json['messageAr']),
  );

  Map<String, dynamic> toJson() => {
    'field': field,
    'code': code,
    'messageEn': messageEn,
    'messageAr': messageAr,
  };

  String messageFor(String languageCode) =>
      languageCode == 'ar' && messageAr.isNotEmpty ? messageAr : messageEn;

  /// Parses the `errors` array from a ProblemDetails JSON map.
  static List<ApiFieldError> listFromProblem(Map<String, dynamic> problem) =>
      _mapped(problem['errors'], ApiFieldError.fromJson);

  /// Defensive parser for any decoded response body.
  static List<ApiFieldError> listFromBody(dynamic body) {
    if (body is Map) {
      return listFromProblem(_map(body));
    }
    return const <ApiFieldError>[];
  }

  /// Extracts inline field errors from an API failure thrown by [ApiClient].
  static List<ApiFieldError> fromFailure(Object failure) {
    if (failure is ApiFailure) {
      return _mapped(failure.errors, ApiFieldError.fromJson);
    }
    return const <ApiFieldError>[];
  }
}
