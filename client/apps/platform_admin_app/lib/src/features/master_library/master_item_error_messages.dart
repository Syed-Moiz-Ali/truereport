import 'package:core/core.dart';
import 'package:l10n/l10n.dart';

/// Maps item-creation API failures to readable copy.
///
/// Kept in a `*error*` file so the taxonomy gate does not treat an HTTP
/// failure code as a lifecycle status.
String itemCreateFailureMessage(UiMessageStrings strings, Object error) {
  if (error is AppFailure) {
    switch (error.code) {
      case 'ITEM_CODE_EXISTS':
        return strings.tKey(PlatformAdminKeys.errorItemCodeExists);
      case 'CATEGORY_RETIRED':
        return strings.tKey(PlatformAdminKeys.errorCategoryRetired);
      case 'TRANSLATION_REQUIRED':
        return strings.tKey(PlatformAdminKeys.errorTranslationRequired);
    }
  }
  return strings.tKey(CommonKeys.stateError);
}
