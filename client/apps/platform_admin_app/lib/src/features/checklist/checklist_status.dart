import 'package:l10n/l10n.dart';

/// Canonical checklist statuses normalized across items, categories, option sets,
/// option values, and templates.
const Map<String, UiMessageKey> _checklistStatusKeys = {
  'ACTIVE': PlatformAdminKeys.checklistStatusActive,
  'DRAFT': PlatformAdminKeys.checklistStatusDraft,
  'PUBLISHED': PlatformAdminKeys.checklistStatusPublished,
  'RETIRED': PlatformAdminKeys.checklistStatusRetired,
  'REVIEW': PlatformAdminKeys.checklistStatusReview,
  'IN REVIEW': PlatformAdminKeys.checklistStatusReview,
  'PENDING': PlatformAdminKeys.checklistStatusReview,
};

/// Normalizes a status string by collapsing spaces/underscores/hyphens to single spaces and uppercasing.
String normalizeChecklistStatus(String status) {
  return status.trim().replaceAll(RegExp(r'[\s_-]+'), ' ').toUpperCase();
}

/// Returns a localized display label for a checklist status.
///
/// Known statuses:
/// - ACTIVE -> Active / نشط
/// - DRAFT -> Draft / مسودة
/// - PUBLISHED -> Published / منشور
/// - RETIRED -> Retired / متقاعد
/// - REVIEW / IN_REVIEW -> In review / قيد المراجعة
///
/// Unknown statuses are humanized (e.g. `PENDING_APPROVAL` -> `Pending Approval`)
/// rather than leaking raw uppercase snake_case to the user.
String checklistStatusLabel(UiMessageStrings strings, String status) {
  final normalized = normalizeChecklistStatus(status);
  if (normalized.isEmpty) return '—';

  final key = _checklistStatusKeys[normalized];
  if (key != null) {
    return strings.tKey(key);
  }

  return humanizeStatus(status);
}

/// Converts raw snake_case or SCREAMING_SNAKE to Title Case words.
String humanizeStatus(String status) {
  final cleaned = status.trim().replaceAll(RegExp(r'[\s_-]+'), ' ');
  if (cleaned.isEmpty) return '—';
  return cleaned.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}
