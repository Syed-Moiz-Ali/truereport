import 'package:l10n/ui_strings.dart';

/// Backend keys used by the developer gallery.
///
/// The gallery ships no bundle, so these resolve to empty strings outside an
/// app shell - exactly like the generated accessors did before they were
/// removed. Keys are addressed by name from whichever bundle is installed.
abstract final class GalleryKeys {
  static const appTitle = UiMessageKey.common('appTitle');

  static const create = UiMessageKey.common('create');

  static const invalidEmail = UiMessageKey.common('invalidEmail');

  static const requiredField = UiMessageKey.common('requiredField');

  static const minor = UiMessageKey.common('minor');

  static const moderate = UiMessageKey.common('moderate');

  static const major = UiMessageKey.common('major');

  static const safetyCritical = UiMessageKey.common('safetyCritical');

  static const noIssueObserved = UiMessageKey.common('noIssueObserved');

  static const attentionRecommended = UiMessageKey.common(
    'attentionRecommended',
  );

  static const defectFound = UiMessageKey.common('defectFound');

  static const notChecked = UiMessageKey.common('notChecked');

  static const notApplicable = UiMessageKey.common('notApplicable');

  static const couldNotVerify = UiMessageKey.common('couldNotVerify');

  static const coverage = UiMessageKey.common('coverage');
}
