import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import 'signin_tokens.dart';
import 'widgets/signin_dock.dart';
import 'widgets/signin_hero.dart';

/// Presentational sign-in screen for the technician app — direction C "The dock".
///
/// Business state (submit, challenge, error mapping) stays in
/// `TechnicianSignInPage`. This widget owns only the reveal toggle and the
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainer,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: true,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final wide = width >= SignInDims.wide;
            final gutter = width >= SignInDims.wide
                ? SignInDims.gutterWide
                : width >= SignInDims.stacked
                ? SignInDims.gutterTablet
                : SignInDims.gutterPhone;
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final pinned =
                constraints.maxHeight >= SignInDims.pinnedHeight &&
                textScale < 1.4;

            final hero = SignInHero(
              title: t(TechnicianKeys.appTitle),
              statement: t(TechnicianKeys.signInSubtitle),
              tagline: t(TechnicianKeys.technicianSignInTagline),
              wide: wide,
              gutter: gutter,
            );
            final dock = SignInDock(
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
              accessPrompt: t(TechnicianKeys.technicianNeedTechnicianAccess),
              helpLabel: t(TechnicianKeys.technicianContactAdmin),
              securityLine: t(TechnicianKeys.technicianSecurityLine),
              emailValidator: widget.onValidateEmail,
              passwordValidator: widget.onValidateRequired,
              codeValidator: widget.onValidateCode,
              obscure: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onSubmit: widget.onSubmit,
              challenge: widget.challenge,
              busy: widget.submitting,
              autofocusEmail: wide && !widget.challenge,
              errorText: widget.errorText,
              submitKey: const Key('sign-in-submit'),
              accessKey: const Key('sign-in-access-prompt'),
              securityKey: const Key('sign-in-security-line'),
              emailFieldKey: const Key('sign-in-email'),
              passwordFieldKey: const Key('sign-in-password'),
              codeFieldKey: const Key('sign-in-code'),
            );

            final body = pinned
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: hero),
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: _Rise(
                          child: Form(key: widget.formKey, child: dock),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: textScale >= 1.8 ? 540 : 400,
                          child: hero,
                        ),
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: _Rise(
                            child: Form(key: widget.formKey, child: dock),
                          ),
                        ),
                      ],
                    ),
                  );

            return body;
          },
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
