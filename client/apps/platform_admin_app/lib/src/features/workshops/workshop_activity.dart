import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

const Map<String, UiMessageKey> _actionKeys = {
  'CATEGORY_CREATED': PlatformAdminKeys.activityActionCategoryCreated,
  'CONTENT_GENERATION_CANCELLED':
      PlatformAdminKeys.activityActionContentGenerationCancelled,
  'CONTENT_TRANSLATIONS_GENERATED':
      PlatformAdminKeys.activityActionContentTranslationsGenerated,
  'CREATE_CATEGORY': PlatformAdminKeys.activityActionCreateCategory,
  'DOCUMENT_TYPE_CREATED': PlatformAdminKeys.activityActionDocumentTypeCreated,
  'DOCUMENT_TYPE_REORDERED':
      PlatformAdminKeys.activityActionDocumentTypeReordered,
  'DOCUMENT_TYPE_RETIRED': PlatformAdminKeys.activityActionDocumentTypeRetired,
  'DOCUMENT_TYPE_UPDATED': PlatformAdminKeys.activityActionDocumentTypeUpdated,
  'JOB_APPROVED': PlatformAdminKeys.activityActionJobApproved,
  'JOB_ASSIGNED': PlatformAdminKeys.activityActionJobAssigned,
  'JOB_CANCELLED': PlatformAdminKeys.activityActionJobCancelled,
  'JOB_COMPLETED': PlatformAdminKeys.activityActionJobCompleted,
  'JOB_CREATED': PlatformAdminKeys.activityActionJobCreated,
  'JOB_EVIDENCE_DELETED': PlatformAdminKeys.activityActionJobEvidenceDeleted,
  'JOB_PUBLISHED': PlatformAdminKeys.activityActionJobPublished,
  'JOB_REJECTED': PlatformAdminKeys.activityActionJobRejected,
  'JOB_RESULT_PROJECTED': PlatformAdminKeys.activityActionJobResultProjected,
  'JOB_SIGNED': PlatformAdminKeys.activityActionJobSigned,
  'JOB_UNPUBLISHED': PlatformAdminKeys.activityActionJobUnpublished,
  'JOB_UPDATED': PlatformAdminKeys.activityActionJobUpdated,
  'LANGUAGE_DELETED': PlatformAdminKeys.activityActionLanguageDeleted,
  'LANGUAGE_PUBLISHED': PlatformAdminKeys.activityActionLanguagePublished,
  'LOGIN_2FA_REQUIRED': PlatformAdminKeys.activityActionLogin2faRequired,
  'LOGIN_FAILED': PlatformAdminKeys.activityActionLoginFailed,
  'LOGIN_LOCKED': PlatformAdminKeys.activityActionLoginLocked,
  'LOGOUT': PlatformAdminKeys.activityActionLogout,
  'LOGOUT_ALL': PlatformAdminKeys.activityActionLogoutAll,
  'MASTER_CATEGORY_CREATED':
      PlatformAdminKeys.activityActionMasterCategoryCreated,
  'MASTER_CATEGORY_REORDERED':
      PlatformAdminKeys.activityActionMasterCategoryReordered,
  'MASTER_CATEGORY_RETIRED':
      PlatformAdminKeys.activityActionMasterCategoryRetired,
  'MASTER_CATEGORY_UPDATED':
      PlatformAdminKeys.activityActionMasterCategoryUpdated,
  'MASTER_DROPDOWN_CREATED':
      PlatformAdminKeys.activityActionMasterDropdownCreated,
  'MASTER_DROPDOWN_VALUE_CREATED':
      PlatformAdminKeys.activityActionMasterDropdownValueCreated,
  'MASTER_EQUIPMENT_CREATED':
      PlatformAdminKeys.activityActionMasterEquipmentCreated,
  'MASTER_GUIDE_IMAGE_RETIRED':
      PlatformAdminKeys.activityActionMasterGuideImageRetired,
  'MASTER_GUIDE_IMAGE_UPLOADED':
      PlatformAdminKeys.activityActionMasterGuideImageUploaded,
  'MASTER_ITEM_CREATED': PlatformAdminKeys.activityActionMasterItemCreated,
  'MASTER_ITEM_DRAFT_CREATED':
      PlatformAdminKeys.activityActionMasterItemDraftCreated,
  'MASTER_ITEM_EVIDENCE_RULES_UPDATED':
      PlatformAdminKeys.activityActionMasterItemEvidenceRulesUpdated,
  'MASTER_ITEM_ISSUE_FIELDS_UPDATED':
      PlatformAdminKeys.activityActionMasterItemIssueFieldsUpdated,
  'MASTER_ITEM_MEASUREMENT_BANDS_UPDATED':
      PlatformAdminKeys.activityActionMasterItemMeasurementBandsUpdated,
  'MASTER_ITEM_METADATA_UPDATED':
      PlatformAdminKeys.activityActionMasterItemMetadataUpdated,
  'MASTER_ITEM_PUBLISHED': PlatformAdminKeys.activityActionMasterItemPublished,
  'MASTER_ITEM_RETIRED': PlatformAdminKeys.activityActionMasterItemRetired,
  'MASTER_ITEM_RULES_UPDATED':
      PlatformAdminKeys.activityActionMasterItemRulesUpdated,
  'MASTER_REASON_CREATED': PlatformAdminKeys.activityActionMasterReasonCreated,
  'MASTER_TRANSLATION_UPDATED':
      PlatformAdminKeys.activityActionMasterTranslationUpdated,
  'OPTION_SET_CREATED': PlatformAdminKeys.activityActionOptionSetCreated,
  'OPTION_SET_RETIRED': PlatformAdminKeys.activityActionOptionSetRetired,
  'OPTION_SET_UPDATED': PlatformAdminKeys.activityActionOptionSetUpdated,
  'OPTION_VALUE_CREATED': PlatformAdminKeys.activityActionOptionValueCreated,
  'OPTION_VALUE_RETIRED': PlatformAdminKeys.activityActionOptionValueRetired,
  'OPTION_VALUE_UPDATED': PlatformAdminKeys.activityActionOptionValueUpdated,
  'PUBLIC_LINK_REVOKED': PlatformAdminKeys.activityActionPublicLinkRevoked,
  'PUBLIC_LINK_ROTATED': PlatformAdminKeys.activityActionPublicLinkRotated,
  'PUBLISH_ITEM': PlatformAdminKeys.activityActionPublishItem,
  'REFRESH_REUSE_DETECTED':
      PlatformAdminKeys.activityActionRefreshReuseDetected,
  'REPORT_DOCUMENT_RETRIED':
      PlatformAdminKeys.activityActionReportDocumentRetried,
  'TEMPLATE_CATEGORIES_REPLACED':
      PlatformAdminKeys.activityActionTemplateCategoriesReplaced,
  'TEMPLATE_CREATED': PlatformAdminKeys.activityActionTemplateCreated,
  'TEMPLATE_DRAFT_CREATED':
      PlatformAdminKeys.activityActionTemplateDraftCreated,
  'TEMPLATE_ITEMS_REPLACED':
      PlatformAdminKeys.activityActionTemplateItemsReplaced,
  'TEMPLATE_PUBLISH_REJECTED':
      PlatformAdminKeys.activityActionTemplatePublishRejected,
  'TEMPLATE_PUBLISH_REQUESTED':
      PlatformAdminKeys.activityActionTemplatePublishRequested,
  'TEMPLATE_PUBLISHED': PlatformAdminKeys.activityActionTemplatePublished,
  'TEMPLATE_RETIRED': PlatformAdminKeys.activityActionTemplateRetired,
  'TEMPLATE_UPDATED': PlatformAdminKeys.activityActionTemplateUpdated,
  'TOTP_CONFIRM_FAILED': PlatformAdminKeys.activityActionTotpConfirmFailed,
  'TOTP_ENABLED': PlatformAdminKeys.activityActionTotpEnabled,
  'TOTP_ENROLLMENT_STARTED':
      PlatformAdminKeys.activityActionTotpEnrollmentStarted,
  'TOTP_FAILED': PlatformAdminKeys.activityActionTotpFailed,
  'TOTP_LOCKED': PlatformAdminKeys.activityActionTotpLocked,
  'TOTP_RECOVERY_CODES_REGENERATED':
      PlatformAdminKeys.activityActionTotpRecoveryCodesRegenerated,
  'TOTP_RECOVERY_SUCCEEDED':
      PlatformAdminKeys.activityActionTotpRecoverySucceeded,
  'TOTP_SUCCEEDED': PlatformAdminKeys.activityActionTotpSucceeded,
  'UI_MESSAGES_GENERATED': PlatformAdminKeys.activityActionUiMessagesGenerated,
  'UI_MESSAGES_GENERATION_CANCELLED':
      PlatformAdminKeys.activityActionUiMessagesGenerationCancelled,
  'UI_MESSAGES_REVIEW_APPROVED':
      PlatformAdminKeys.activityActionUiMessagesReviewApproved,
  'UI_MESSAGES_REVIEW_SAVED':
      PlatformAdminKeys.activityActionUiMessagesReviewSaved,
  'WORKSHOP_DEACTIVATED': PlatformAdminKeys.activityActionWorkshopDeactivated,
  'WORKSHOP_REACTIVATED': PlatformAdminKeys.activityActionWorkshopReactivated,
  'WORKSHOP_REGISTERED': PlatformAdminKeys.activityActionWorkshopRegistered,
  'WORKSHOP_UPDATED': PlatformAdminKeys.activityActionWorkshopUpdated,
};

const Map<String, UiMessageKey> _entityKeys = {
  'CATEGORY': PlatformAdminKeys.activityEntityCategory,
  'DOCUMENT_TYPE': PlatformAdminKeys.activityEntityDocumentType,
  'DROPDOWN': PlatformAdminKeys.activityEntityDropdown,
  'DROPDOWN_VALUE': PlatformAdminKeys.activityEntityDropdownValue,
  'EQUIPMENT': PlatformAdminKeys.activityEntityEquipment,
  'GUIDE_IMAGE': PlatformAdminKeys.activityEntityGuideImage,
  'ITEM': PlatformAdminKeys.activityEntityItem,
  'JOB': PlatformAdminKeys.activityEntityJob,
  'LANGUAGE': PlatformAdminKeys.activityEntityLanguage,
  'MASTER_ITEM': PlatformAdminKeys.activityEntityMasterItem,
  'MASTER_ITEM_VERSION': PlatformAdminKeys.activityEntityMasterItemVersion,
  'MASTER_TEMPLATE': PlatformAdminKeys.activityEntityMasterTemplate,
  'OPTION_SET': PlatformAdminKeys.activityEntityOptionSet,
  'OPTION_VALUE': PlatformAdminKeys.activityEntityOptionValue,
  'REASON': PlatformAdminKeys.activityEntityReason,
  'TEMPLATE': PlatformAdminKeys.activityEntityTemplate,
  'TEMPLATE_VERSION': PlatformAdminKeys.activityEntityTemplateVersion,
  'USER': PlatformAdminKeys.activityEntityUser,
  'WORKSHOP': PlatformAdminKeys.activityEntityWorkshop,
};

const Map<String, UiMessageKey> _roleKeys = {
  'PLATFORM_ADMIN': PlatformAdminKeys.activityRolePlatformAdmin,
  'TECHNICIAN': PlatformAdminKeys.activityRoleTechnician,
  'WORKSHOP_ADMIN': PlatformAdminKeys.activityRoleWorkshopAdmin,
};

const Map<String, UiMessageKey> _reasonKeys = {
  'EXPANSION': PlatformAdminKeys.activityReasonExpansion,
  'INITIAL_SETUP': PlatformAdminKeys.activityReasonInitialSetup,
  'INVALID_CODE': PlatformAdminKeys.activityReasonInvalidCode,
  'INVALID_CREDENTIALS': PlatformAdminKeys.activityReasonInvalidCredentials,
  'LOCKED': PlatformAdminKeys.activityReasonLocked,
  'MANUAL_CORRECTION': PlatformAdminKeys.activityReasonManualCorrection,
  'PUBLISH': PlatformAdminKeys.activityReasonPublish,
  'ROTATED_TOKEN_REUSED': PlatformAdminKeys.activityReasonRotatedTokenReused,
};

/// Localized audit action label. Unknown snake_case codes are humanized.
String auditActionLabel(UiMessageStrings strings, String code) {
  return _auditCodeLabel(strings, code, _actionKeys);
}

/// Localized audit entity label. Unknown snake_case codes are humanized.
String auditEntityLabel(UiMessageStrings strings, String code) {
  return _auditCodeLabel(strings, code, _entityKeys);
}

/// Localized audit actor-role label. Unknown snake_case codes are humanized.
String auditRoleLabel(UiMessageStrings strings, String code) {
  return _auditCodeLabel(strings, code, _roleKeys);
}

/// Localized audit reason label. Unknown snake_case codes are humanized.
String auditReasonLabel(UiMessageStrings strings, String code) {
  return _auditCodeLabel(strings, code, _reasonKeys);
}

/// Locale-aware audit timestamp. Offset-less ISO values are treated as UTC and
/// shown in the UTC+4 wall clock used by the workshop and technician apps.
/// Invalid values render as an em dash rather than leaking raw ISO text.
String auditTimestampLabel(String raw, String localeName) {
  final parsed = _parseUtc(raw);
  if (parsed == null) return '—';

  final wall = parsed.add(const Duration(hours: 4));
  final locale = localeName.trim().isEmpty ? 'en' : localeName.trim();
  try {
    return DateFormat.yMd(locale).add_Hm().format(wall);
  } on Exception {
    return DateFormat.yMd('en').add_Hm().format(wall);
  }
}

String _auditCodeLabel(
  UiMessageStrings strings,
  String code,
  Map<String, UiMessageKey> keys,
) {
  final normalized = code
      .trim()
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .toUpperCase();
  if (normalized.isEmpty) return '—';

  final key = keys[normalized];
  if (key != null) return strings.tKey(key);

  return humanizeAuditCode(code);
}

/// Humanizes unknown audit codes in sentence case:
/// `WORKSHOP_UPDATED` -> `Workshop updated`.
String humanizeAuditCode(String code) {
  final words = code
      .trim()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word.toLowerCase())
      .toList(growable: false);
  if (words.isEmpty) return '—';

  final sentence = words.join(' ');
  return sentence[0].toUpperCase() + sentence.substring(1);
}

DateTime? _parseUtc(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final hasOffset = RegExp(r'([zZ]|[+-]\d{2}:?\d{2})$').hasMatch(text);
  try {
    return DateTime.parse(hasOffset ? text : '${text}Z').toUtc();
  } on FormatException {
    return null;
  }
}
