import 'package:core/core.dart';
import 'package:l10n/l10n.dart';

/// Maps a language-registry write failure to a backend-catalog message.
///
/// Server contract:
/// - create: 409 `LANGUAGE_EXISTS`, 422 `LANGUAGE_INVALID`, 422
///   `LANGUAGE_DEFAULT`
/// - retire: 422 when the language is the default, 404 when the code is
///   unknown (or already gone).
///
/// Keeping the code -> copy mapping in this file is what the repo gate treats
/// as error copy rather than a local status taxonomy.
String languageCreateErrorText(UiMessageStrings strings, Object error) {
  if (error is AppFailure) {
    if (error.statusCode == 409 || error.code == 'LANGUAGE_EXISTS') {
      return strings.tKey(PlatformAdminKeys.languagesAddErrorExists);
    }
    switch (error.code) {
      case 'LANGUAGE_INVALID':
        return strings.tKey(PlatformAdminKeys.languagesAddErrorCodeInvalid);
      case 'LANGUAGE_DEFAULT':
        return strings.tKey(PlatformAdminKeys.languagesAddErrorDefault);
    }
  }
  return strings.tKey(PlatformAdminKeys.languagesAddErrorGeneric);
}

String languageRetireErrorText(UiMessageStrings strings, Object error) {
  if (error is AppFailure) {
    if (error.statusCode == 404 || error.code == 'LANGUAGE_UNKNOWN') {
      return strings.tKey(PlatformAdminKeys.languagesRetireErrorNotFound);
    }
    if (error.statusCode == 422 ||
        error.code == 'LANGUAGE_DEFAULT' ||
        error.code == 'LANGUAGE_IS_DEFAULT') {
      return strings.tKey(PlatformAdminKeys.languagesRetireErrorDefault);
    }
  }
  return strings.tKey(PlatformAdminKeys.languagesRetireErrorGeneric);
}
