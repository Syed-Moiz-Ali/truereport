import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/inspection_models.dart';

/// Resolves one checklist option label.
///
/// The backend key wins when it resolves to a non-empty string; otherwise the
/// served [IssueOption.labelFor] text is used. There is no Dart literal
/// fallback: `labelEn` is backend data, not client copy.
String issueOptionLabel(UiStrings t, IssueOption option, String language) {
  final labelKey = option.labelKey;
  if (labelKey != null && labelKey.isNotEmpty) {
    final translated = t.raw(labelKey);
    if (translated.isNotEmpty) {
      return translated;
    }
  }
  return option.labelFor(language);
}
