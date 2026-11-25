import 'package:core/core.dart';
import 'package:l10n/l10n.dart';

/// Maps account API failures to the copy the platform administrator sees.
///
/// Lives in its own `*error*` file so the taxonomy gate does not confuse an
/// HTTP failure code with a lifecycle status.
String staffErrorMessage(UiMessageStrings strings, Object error) {
  if (error is AppFailure) {
    switch (error.code) {
      case 'EMAIL_EXISTS':
        return strings.tKey(PlatformAdminKeys.errorEmailExists);
      case 'ROLE_NOT_PERMITTED':
        return strings.tKey(PlatformAdminKeys.errorRoleNotPermitted);
      case 'PASSWORD_POLICY_VIOLATION':
        return strings.tKey(PlatformAdminKeys.validationPasswordPolicy);
    }
  }
  return strings.tKey(CommonKeys.stateError);
}
