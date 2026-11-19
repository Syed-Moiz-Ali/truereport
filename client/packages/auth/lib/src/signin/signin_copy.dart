/// Every string the shared sign-in bay renders.
///
/// The workshop page resolves these from `AppLocalizations`; the technician
/// page does the same with its own keys; the platform page passes its backend
/// UI strings. The bay itself never hardcodes product copy.
class SignInBayCopy {
  const SignInBayCopy({
    required this.portalLabel,
    required this.title,
    required this.subtitle,
    required this.help,
    required this.emailLabel,
    required this.passwordLabel,
    required this.codeLabel,
    required this.signInLabel,
    required this.verifyLabel,
    required this.loadingLabel,
    this.emailHint,
    this.passwordHint,
    this.appName = 'TrueReport',
  });

  final String portalLabel;
  final String title;
  final String subtitle;
  final String help;
  final String emailLabel;
  final String passwordLabel;
  final String codeLabel;
  final String signInLabel;
  final String verifyLabel;
  final String loadingLabel;
  final String? emailHint;
  final String? passwordHint;
  final String appName;
}
