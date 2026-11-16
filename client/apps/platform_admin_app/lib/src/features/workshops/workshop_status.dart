import 'package:l10n/l10n.dart';

/// Canonical workshop statuses, normalized before lookup so backend values such
/// as `active`, `DEPOT_HUB`, or ` depot hub ` resolve to the same label.
const Map<String, UiMessageKey> _workshopStatusKeys = {
  'ACTIVE': PlatformAdminKeys.statusWorkshopActive,
  'INACTIVE': PlatformAdminKeys.statusWorkshopInactive,
  'STANDBY': PlatformAdminKeys.statusWorkshopStandby,
  'RETIRED': PlatformAdminKeys.statusWorkshopRetired,
  'DEPOT HUB': PlatformAdminKeys.statusWorkshopDepotHub,
};

const Map<String, UiMessageKey> _relatedStatusKeys = {
  'ACTIVE': CommonKeys.statusActive,
  'INACTIVE': CommonKeys.statusInactive,
  'DISABLED': CommonKeys.statusDisabled,
  'DRAFT': CommonKeys.statusDraft,
  'PUBLISHED': PlatformAdminKeys.statusPublished,
  'RETIRED': CommonKeys.statusRetired,
};

/// Converts a backend workshop status into its localized display label.
///
/// Unknown free-form values are humanized instead of leaking raw uppercase
/// snake case. For example, `OUT_OF_SERVICE` becomes `Out Of Service`.
String workshopStatusLabel(UiMessageStrings strings, String status) {
  final normalized = normalizeWorkshopStatus(status);
  if (normalized.isEmpty) return '—';

  final key = _workshopStatusKeys[normalized];
  if (key != null) return strings.tKey(key);

  return _humanizeWorkshopStatus(status);
}

/// Uppercase, trim, and collapse spaces, underscores, and hyphens.
String normalizeWorkshopStatus(String status) {
  return status.trim().replaceAll(RegExp(r'[\s_-]+'), ' ').toUpperCase();
}

/// Localized staff-account status used inside workshop detail.
String workshopMemberStatusLabel(UiMessageStrings strings, String status) {
  return _relatedStatusLabel(strings, status);
}

String _relatedStatusLabel(UiMessageStrings strings, String status) {
  final normalized = normalizeWorkshopStatus(status);
  if (normalized.isEmpty) return '—';

  final key = _relatedStatusKeys[normalized];
  if (key != null) return strings.tKey(key);

  return _humanizeWorkshopStatus(status);
}

String _humanizeWorkshopStatus(String status) {
  final words = status
      .trim()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  if (words.isEmpty) return '—';

  return words
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}
