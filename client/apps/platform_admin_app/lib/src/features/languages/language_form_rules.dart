import 'package:l10n/l10n.dart';

/// Local, pre-flight rules for the Add-language dialog.
///
/// The server still validates the body (422 `LANGUAGE_INVALID` /
/// `LANGUAGE_DEFAULT`); these rules only stop obviously wrong input before the
/// round trip. The messages come from the backend catalog, so the dialog never
/// invents copy.
const String languageCodePattern = r'^[a-z]{2,3}(-[a-z0-9]{2,8})*$';

final RegExp _languageCode = RegExp(languageCodePattern);

/// Codes are stored lowercase; the dialog also lowercases as the admin types.
String normalizeLanguageCode(String raw) => raw.trim().toLowerCase();

String? validateLanguageCode(UiMessageStrings strings, String? raw) {
  final value = normalizeLanguageCode(raw ?? '');
  if (value.isEmpty) {
    return strings.tKey(PlatformAdminKeys.languagesAddErrorCodeRequired);
  }
  if (!_languageCode.hasMatch(value)) {
    return strings.tKey(PlatformAdminKeys.languagesAddErrorCodeInvalid);
  }
  if (value == 'en') {
    return strings.tKey(PlatformAdminKeys.languagesAddErrorCodeDefault);
  }
  return null;
}

String? validateLanguageNativeName(UiMessageStrings strings, String? raw) {
  if ((raw ?? '').trim().isEmpty) {
    return strings.tKey(PlatformAdminKeys.languagesAddErrorNameRequired);
  }
  return null;
}
