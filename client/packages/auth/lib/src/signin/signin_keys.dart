import 'package:l10n/ui_strings.dart';

/// Backend keys used by the shared sign-in chrome.
///
/// The names live in the app catalogs (technician/workshop_admin); Platform
/// Admin serves its product copy through `SignInBayCopy`. `UiStrings` resolves
/// by key name from the active bundle, so one shared constant set works for
/// every app while keeping the generated localizations out of `packages/auth`.
abstract final class SignInKeys {
  static const appTitle = UiMessageKey.common('appTitle');

  static const signOut = UiMessageKey.common('signOut');

  static const homeTitle = UiMessageKey.common('homeTitle');

  static const homeBody = UiMessageKey.common('homeBody');

  static const roleTechnician = UiMessageKey.common('roleTechnician');

  static const roleWorkshopAdmin = UiMessageKey.common('roleWorkshopAdmin');

  static const rolePlatformAdmin = UiMessageKey.common('rolePlatformAdmin');

  static const roleLeadTechnician = UiMessageKey.common('roleLeadTechnician');

  static const signInExampleProgress = UiMessageKey.common(
    'signInExampleProgress',
  );

  static const signInExampleLabel = UiMessageKey.common('signInExampleLabel');

  static const signInExampleChecklist = UiMessageKey.common(
    'signInExampleChecklist',
  );

  static const signInExampleStarted = UiMessageKey.common(
    'signInExampleStarted',
  );

  static const showPassword = UiMessageKey.common('showPassword');

  static const hidePassword = UiMessageKey.common('hidePassword');
}
