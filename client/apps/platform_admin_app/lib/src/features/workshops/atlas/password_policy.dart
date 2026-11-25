import 'package:l10n/l10n.dart';

/// The server's password policy, mirrored for the platform admin forms.
///
/// Server rule (`PasswordPolicy`): 12–128 characters with at least one
/// uppercase letter, one lowercase letter, one digit and one symbol.
String? accountPasswordError(UiMessageStrings strings, String value) {
  if (value.isEmpty) {
    return strings.tKey(CommonKeys.validationRequiredField);
  }
  if (value.length < 12) {
    return strings.tKey(PlatformAdminKeys.validationPasswordMinLength);
  }
  final hasUpper = RegExp('[A-Z]').hasMatch(value);
  final hasLower = RegExp('[a-z]').hasMatch(value);
  final hasDigit = RegExp('[0-9]').hasMatch(value);
  final hasSymbol = RegExp('[^A-Za-z0-9]').hasMatch(value);
  if (!hasUpper || !hasLower || !hasDigit || !hasSymbol) {
    return strings.tKey(PlatformAdminKeys.validationPasswordPolicy);
  }
  return null;
}

String? accountPasswordConfirmError(
  UiMessageStrings strings,
  String password,
  String value,
) {
  if (value.isEmpty) {
    return strings.tKey(CommonKeys.validationRequiredField);
  }
  if (value != password) {
    return strings.tKey(PlatformAdminKeys.validationPasswordMismatch);
  }
  return null;
}
