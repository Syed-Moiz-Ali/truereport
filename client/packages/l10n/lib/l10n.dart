/// Compatibility entry point.
///
/// The generated accessor no longer exists. Prefer
/// `package:l10n/ui_strings.dart`; this file only forwards to it so existing
/// imports (for example the gallery and Platform Admin preview fixtures) keep
/// resolving the shared key classes, providers and `UiStrings`.
library;

export 'ui_strings.dart';
