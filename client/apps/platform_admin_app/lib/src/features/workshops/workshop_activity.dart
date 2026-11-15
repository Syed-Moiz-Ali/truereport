import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

const Map<String, UiMessageKey> _actionKeys = {
  'WORKSHOP_REGISTERED': PlatformAdminKeys.activityActionWorkshopRegistered,
};

const Map<String, UiMessageKey> _roleKeys = {
  'PLATFORM_ADMIN': PlatformAdminKeys.activityRolePlatformAdmin,
};

const Map<String, UiMessageKey> _reasonKeys = {
  'INITIAL_SETUP': PlatformAdminKeys.activityReasonInitialSetup,
};

/// Localized audit action label. Unknown snake_case codes are humanized.
String auditActionLabel(UiMessageStrings strings, String code) {
  return _auditCodeLabel(strings, code, _actionKeys);
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

/// Humanizes unknown audit codes: `WORKSHOP_UPDATED` -> `Workshop Updated`.
String humanizeAuditCode(String code) {
  final words = code
      .trim()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  if (words.isEmpty) return '—';

  return words
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
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
