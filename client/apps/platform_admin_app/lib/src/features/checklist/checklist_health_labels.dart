import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../reference_status_lookup.dart';

/// Served plain-language title for a health check (`labelKey`).
///
/// Falls back to the humanized code only when the backend key is absent or not
/// in the active bundle. There is no client check-code table.
String healthCheckTitle(UiMessageStrings strings, HealthCheck check) {
  final resolved = strings.resolveFlatKey(check.labelKey);
  if (resolved != null && resolved.trim().isNotEmpty) return resolved;
  final humanized = humanizeStatusCode(check.code);
  return humanized.isNotEmpty
      ? humanized
      : strings.tKey(PlatformAdminKeys.checklistHealthCheckGeneric);
}

/// Served description for a health check (`descriptionKey`); empty when absent.
String healthCheckDescription(UiMessageStrings strings, HealthCheck check) {
  final resolved = strings.resolveFlatKey(check.descriptionKey);
  return resolved?.trim() ?? '';
}

/// Served label for a health check severity.
///
/// Uses `statusesProvider('health')` so severity vocabulary stays backend-owned.
String healthSeverityLabel(WidgetRef ref, String severity) {
  final strings = ref.watch(uiStringsProvider);
  final record = referenceRecordForStatus(
    ref.watch(statusesProvider('health')).value,
    severity,
  );
  final label = referenceStatusLabelFrom(strings, record);
  if (label != null) return label;
  final humanized = humanizeStatusCode(severity);
  return humanized.isNotEmpty ? humanized : severity;
}

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
