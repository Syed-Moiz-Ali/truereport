import 'package:l10n/ui_strings.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';

/// Resolves one option-set value label.
///
/// The backend key wins when it resolves to a non-empty string; otherwise the
/// served [OptionValue.labelEn] is used, then the code. There is no Dart
/// literal fallback: labels are backend data, not client copy.
String optionValueLabel(UiStrings t, OptionValue value) {
  final labelKey = value.labelKey;
  if (labelKey != null && labelKey.isNotEmpty) {
    final translated = t.raw(labelKey);
    if (translated.isNotEmpty) {
      return translated;
    }
  }
  return value.labelEn.isEmpty ? value.code : value.labelEn;
}
