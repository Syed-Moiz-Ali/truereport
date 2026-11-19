import 'package:l10n/l10n.dart';

/// Field rules shared by the create and member pages.
///
/// Length and mismatch rules use the closest existing localized strings so no
/// new ARB keys are introduced by this screen.
String? staffNameError(AppLocalizations l10n, String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) {
    return l10n.requiredField;
  }
  if (name.length < 2) {
    return l10n.requiredField;
  }
  return null;
}

String? staffEmailError(AppLocalizations l10n, String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return l10n.requiredField;
  }
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  return valid ? null : l10n.invalidEmail;
}

/// Server policy is 12–128. Empty is the only message we can name; a short
/// password is prevented by the disabled submit plus the strength read-out.
String? staffPasswordError(AppLocalizations l10n, String? value) {
  if (value == null || value.isEmpty) {
    return l10n.requiredField;
  }
  return null;
}

String? staffConfirmError(
  AppLocalizations l10n,
  String password,
  String? value,
) {
  if (value == null || value.isEmpty) {
    return l10n.requiredField;
  }
  if (value != password) {
    return l10n.passwordMismatch;
  }
  return null;
}

bool staffPasswordAcceptable(String value) =>
    value.length >= 12 && value.length <= 128;
