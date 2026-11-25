import 'package:l10n/ui_strings.dart';

/// Field rules shared by the create and member pages.
///
/// Length and mismatch rules use the closest existing localized strings so no
/// new ARB keys are introduced by this screen.
String? staffNameError(UiStrings t, String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) {
    return t(WorkshopAdminKeys.requiredField);
  }
  if (name.length < 2) {
    return t(WorkshopAdminKeys.requiredField);
  }
  return null;
}

String? staffEmailError(UiStrings t, String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return t(WorkshopAdminKeys.requiredField);
  }
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  return valid ? null : t(WorkshopAdminKeys.invalidEmail);
}

/// Server policy is 12–128 with mixed case, a digit and a symbol.
String? staffPasswordError(UiStrings t, String? value) {
  if (value == null || value.isEmpty) {
    return t(WorkshopAdminKeys.requiredField);
  }
  if (!staffPasswordAcceptable(value)) {
    return t(WorkshopAdminKeys.passwordPolicy);
  }
  return null;
}

String? staffConfirmError(UiStrings t, String password, String? value) {
  if (value == null || value.isEmpty) {
    return t(WorkshopAdminKeys.requiredField);
  }
  if (value != password) {
    return t(WorkshopAdminKeys.passwordMismatch);
  }
  return null;
}

bool staffPasswordAcceptable(String value) {
  if (value.length < 12 || value.length > 128) {
    return false;
  }
  return RegExp('[A-Z]').hasMatch(value) &&
      RegExp('[a-z]').hasMatch(value) &&
      RegExp('[0-9]').hasMatch(value) &&
      RegExp('[^A-Za-z0-9]').hasMatch(value);
}
