import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';

/// Mapping of known health check codes to strongly typed localization keys.
const Map<String, UiMessageKey> _knownCheckTitleKeys = {
  'TRANSLATIONS': PlatformAdminKeys.checklistHealthCheckTranslations,
  'MEASUREMENT_BANDS': PlatformAdminKeys.checklistHealthCheckMeasurementBands,
  'RETIRED_OPTIONS': PlatformAdminKeys.checklistHealthCheckRetiredOptions,
  'SAFETY_EVIDENCE': PlatformAdminKeys.checklistHealthCheckSafetyEvidence,
  'TEMPLATE_ITEMS': PlatformAdminKeys.checklistHealthCheckTemplateItems,
  'NUMERIC_MEASUREMENTS':
      PlatformAdminKeys.checklistHealthCheckNumericMeasurements,
};

/// Returns a human-friendly plain-language title for a health check.
///
/// Falls back to a localized generic title or humanized code if unknown.
String healthCheckTitle(UiMessageStrings strings, HealthCheck check) {
  final normalized = check.code.trim().toUpperCase();
  final key = _knownCheckTitleKeys[normalized];
  if (key != null) {
    return strings.tKey(key);
  }
  // If unknown, humanize the code rather than showing raw uppercase snake_case
  final words = normalized.replaceAll(RegExp(r'[\s_-]+'), ' ').split(' ');
  final humanized = words
      .map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + w.substring(1).toLowerCase();
      })
      .join(' ');
  return humanized.isNotEmpty
      ? humanized
      : strings.tKey(PlatformAdminKeys.checklistHealthCheckGeneric);
}

/// Returns a localized display label for health check severity.
///
/// E.g.
/// - OK / HEALTHY -> Healthy / سليم
/// - WARNING -> Warning / تحذير
/// - ERROR / UNHEALTHY -> Error / خطأ
String healthSeverityLabel(
  UiMessageStrings strings,
  String severity, {
  bool isOk = false,
}) {
  if (isOk) {
    return strings.tKey(PlatformAdminKeys.checklistHealthSeverityBadgeHealthy);
  }
  final normalized = severity.trim().toUpperCase();
  switch (normalized) {
    case 'OK':
    case 'HEALTHY':
      return strings.tKey(
        PlatformAdminKeys.checklistHealthSeverityBadgeHealthy,
      );
    case 'WARNING':
      return strings.tKey(
        PlatformAdminKeys.checklistHealthSeverityBadgeWarning,
      );
    case 'ERROR':
    case 'UNHEALTHY':
    default:
      return strings.tKey(PlatformAdminKeys.checklistHealthSeverityBadgeError);
  }
}

/// Returns plain-language affected items count text (e.g. "3 affected" / "3 متأثر").
/// Returns the single active-language health message.
///
/// A backend `messageKey` wins when it resolves through the UI catalog.
/// Otherwise only the active-language legacy message is returned, never both.
String healthCheckMessage(UiMessageStrings strings, HealthCheck check) {
  if (check.messageKey.isNotEmpty) {
    final resolved = strings.resolveQualifiedKey(check.messageKey);
    if (resolved != null && resolved.isNotEmpty) return resolved;
  }
  final active = strings.pickBilingual(
    en: check.messageEn,
    ar: check.messageAr,
  );
  if (active.isNotEmpty) return active;
  return strings.pickBilingual(en: check.messageAr, ar: check.messageEn);
}

String healthAffectedCountLabel(UiMessageStrings strings, int affected) {
  return strings.tArgsKey(PlatformAdminKeys.checklistHealthAffectedCount, {
    'count': '$affected',
  });
}
