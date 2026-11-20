import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

/// Maps a reference-write failure to a backend-catalog message.
///
/// The server answers 403 `FORBIDDEN`, 409 `REFERENCE_IN_USE` /
/// `REFERENCE_EXISTS` / `REFERENCE_STATE_INVALID` and 422 `LABEL_KEY_UNKNOWN`,
/// `CODE_INVALID`, `TONE_INVALID`, `ORDER_INVALID`, `TRANSITION_INVALID`.
String referenceErrorText(UiMessageStrings strings, Object error) {
  if (error is AppFailure) {
    if (error.statusCode == 403) {
      return strings.tKey(PlatformAdminKeys.referenceErrorForbidden);
    }
    switch (error.code) {
      case 'LABEL_KEY_UNKNOWN':
        return strings.tKey(PlatformAdminKeys.referenceErrorLabelKeyUnknown);
      case 'REFERENCE_EXISTS':
        return strings.tKey(PlatformAdminKeys.referenceErrorExists);
      case 'REFERENCE_STATE_INVALID':
        return strings.tKey(PlatformAdminKeys.referenceErrorStateInvalid);
      case 'CODE_INVALID':
        return strings.tKey(PlatformAdminKeys.referenceErrorCodeInvalid);
      case 'TRANSITION_INVALID':
        return strings.tKey(PlatformAdminKeys.referenceErrorTransitionInvalid);
    }
  }
  return strings.tKey(PlatformAdminKeys.referenceErrorGeneric);
}

/// Fallback counts parsed from the server's `REFERENCE_IN_USE` detail text.
///
/// The retire flow always fetches `/{domain}/{key}/impact` first, so this is
/// only used when that snapshot was empty and the conflict came from a later
/// change. Returns null when the detail is not in the known shape.
ReferenceImpact? impactFromDetail(String? detail) {
  if (detail == null || detail.isEmpty) return null;
  final match = RegExp(
    r'(\d+)\s+items,\s*(\d+)\s+jobs,\s*(\d+)\s+templates,\s*(\d+)\s+documents',
  ).firstMatch(detail);
  if (match == null) return null;
  int at(int index) => int.tryParse(match.group(index) ?? '') ?? 0;
  return ReferenceImpact(
    items: at(1),
    jobs: at(2),
    templates: at(3),
    documents: at(4),
  );
}
