import 'package:l10n/l10n.dart';

/// Locale-aware category count label with explicit singular/dual/plural forms.
String checklistCategoryCountLabel(UiMessageStrings strings, int count) {
  return _countLabel(
    strings,
    count,
    zero: PlatformAdminKeys.pluralCategoriesZero,
    one: PlatformAdminKeys.pluralCategoriesOne,
    two: PlatformAdminKeys.pluralCategoriesTwo,
    other: PlatformAdminKeys.pluralCategoriesOther,
  );
}

/// Locale-aware item count label with explicit singular/dual/plural forms.
String checklistItemCountLabel(UiMessageStrings strings, int count) {
  return _countLabel(
    strings,
    count,
    zero: PlatformAdminKeys.pluralItemsZero,
    one: PlatformAdminKeys.pluralItemsOne,
    two: PlatformAdminKeys.pluralItemsTwo,
    other: PlatformAdminKeys.pluralItemsOther,
  );
}

String _countLabel(
  UiMessageStrings strings,
  int count, {
  required UiMessageKey zero,
  required UiMessageKey one,
  required UiMessageKey two,
  required UiMessageKey other,
}) {
  switch (count) {
    case 0:
      return strings.tKey(zero);
    case 1:
      return strings.tKey(one);
    case 2:
      return strings.tKey(two);
    default:
      return strings.tArgsKey(other, {'count': '$count'});
  }
}
