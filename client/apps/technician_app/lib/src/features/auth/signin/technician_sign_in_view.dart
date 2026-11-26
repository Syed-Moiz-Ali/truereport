import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l10n/ui_strings.dart';

import 'signin_tokens.dart';
import 'widgets/signin_backdrop.dart';
import 'widgets/signin_sheet.dart';
import 'widgets/signin_statement.dart';

/// Presentational sign-in screen for the technician app — direction A
/// "Bay Door".
///
/// One photograph fills the screen. The statement sits on it (bottom-left on
/// desktop, top on phones) and the credentials live in a translucent sheet:
/// floating beside the statement on desktop, pinned to the bottom edge on
/// phones. Business state (submit, challenge, error mapping) stays in
/// `TechnicianSignInPage`; this widget owns only the reveal toggle and the
/// responsive composition.
class TechnicianSignInView extends StatefulWidget {
  const TechnicianSignInView({
    required this.emailController,
    required this.passwordController,
    required this.codeController,
    required this.formKey,
    required this.onSubmit,
    required this.onValidateEmail,
    required this.onValidateRequired,
    required this.onValidateCode,
    required this.emailFocus,
    required this.passwordFocus,
    required this.codeFocus,
    this.challenge = false,
    this.submitting = false,
    this.errorText,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController codeController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> onValidateEmail;
  final FormFieldValidator<String> onValidateRequired;
  final FormFieldValidator<String> onValidateCode;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final FocusNode codeFocus;
  final bool challenge;
  final bool submitting;
  final String? errorText;

  @override
  State<TechnicianSignInView> createState() => _TechnicianSignInViewState();
}

class _TechnicianSignInViewState extends State<TechnicianSignInView> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0A1A16),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1A16),
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const SignInBackdrop(),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  final wide =
                      width >= SignInDims.sheetRow &&
                      scale < SignInDims.sheetStackScale;

                  final statement = SignInStatement(
                    title: t(TechnicianKeys.technicianSignInHeadline),
                    tagline: t(TechnicianKeys.technicianSignInTagline),
                    wide: wide,
                  );

                  final sheet = SignInSheet(
                    emailController: widget.emailController,
                    passwordController: widget.passwordController,
                    codeController: widget.codeController,
                    emailFocus: widget.emailFocus,
                    passwordFocus: widget.passwordFocus,
                    codeFocus: widget.codeFocus,
                    emailLabel: t(TechnicianKeys.emailLabel),
                    passwordLabel: t(TechnicianKeys.passwordLabel),
                    codeLabel: t(TechnicianKeys.twoFactorLabel),
                    emailHint: t(TechnicianKeys.technicianEmailHint),
                    passwordHint: t(TechnicianKeys.technicianPasswordHint),
                    primaryLabel: widget.challenge
                        ? t(TechnicianKeys.verifyButton)
                        : t(TechnicianKeys.signInButton),
                    busyLabel: t(TechnicianKeys.signingIn),
                    accessPrompt: t(
                      TechnicianKeys.technicianNeedTechnicianAccess,
                    ),
                    helpLabel: t(TechnicianKeys.technicianContactAdmin),
                    securityLine: t(TechnicianKeys.technicianSecurityLine),
                    emailValidator: widget.onValidateEmail,
                    passwordValidator: widget.onValidateRequired,
                    codeValidator: widget.onValidateCode,
                    obscure: _obscurePassword,
                    revealLabel: _obscurePassword
                        ? t(TechnicianKeys.showPassword)
                        : t(TechnicianKeys.hidePassword),
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: widget.onSubmit,
                    heading: t(TechnicianKeys.technicianSignInSheetTitle),
                    subheading: t(TechnicianKeys.technicianSignInSheetBody),
                    challenge: widget.challenge,
                    busy: widget.submitting,
                    pinned: !wide,
                    autofocusEmail: wide && !widget.challenge,
                    errorText: widget.errorText,
                    submitKey: const Key('sign-in-submit'),
                    accessKey: const Key('sign-in-access-prompt'),
                    securityKey: const Key('sign-in-security-line'),
                    emailFieldKey: const Key('sign-in-email'),
                    passwordFieldKey: const Key('sign-in-password'),
                    codeFieldKey: const Key('sign-in-code'),
                  );

                  if (wide) {
                    return Padding(
                      padding: const EdgeInsets.all(48),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: statement),
                          const SizedBox(width: 48),
                          SizedBox(
                            width: SignInDims.sheetWidth,
                            child: _Rise(
                              child: Form(key: widget.formKey, child: sheet),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Phone/tablet: the statement holds the top of the photograph
                  // and the sheet is pinned to the bottom edge. The statement
                  // scrolls when the keyboard or a large text scale squeezes it.
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            SignInDims.gutterPhone,
                            28,
                            SignInDims.gutterPhone,
                            24,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: statement,
                          ),
                        ),
                      ),
                      _Rise(
                        child: Form(key: widget.formKey, child: sheet),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rise extends StatelessWidget {
  const _Rise({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = ReduceMotion.duration(context, SignInDims.riseDuration);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, SignInDims.riseOffset * t),
        child: child,
      ),
      child: child,
    );
  }
}
