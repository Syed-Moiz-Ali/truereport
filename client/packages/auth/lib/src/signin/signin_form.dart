import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'signin_copy.dart';
import 'signin_submit_button.dart';

/// The door: title block, labelled fields, the inline failure banner and the
/// single primary action.
///
/// Behaviour lives in each app's page (validation, submit, failure mapping);
/// this file owns layout and the stable widget keys the three suites pin.
///
/// [challenge] swaps the password cell for the code cell and the primary label
/// for "Verify". The workshop app never sets it (its source scan forbids TOTP
/// UI); the technician and platform apps do.
class SigninForm extends StatelessWidget {
  const SigninForm({
    super.key,
    required this.formKey,
    required this.copy,
    required this.emailController,
    required this.passwordController,
    required this.codeController,
    required this.challenge,
    required this.emailEnabled,
    required this.obscurePassword,
    required this.submitting,
    required this.errorText,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateCode,
    required this.autofocusEmail,
  });

  final GlobalKey<FormState> formKey;
  final SignInBayCopy copy;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController codeController;
  final bool challenge;
  final bool emailEnabled;
  final bool obscurePassword;
  final bool submitting;
  final String? errorText;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateCode;
  final bool autofocusEmail;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            copy.portalLabel.toUpperCase(),
            style: ws.eyebrow.copyWith(
              color: ws.accent,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.sm),
          Text(copy.title, style: ws.heroNumber.copyWith(letterSpacing: -1.2)),
          SizedBox(height: spacing.xs),
          Text(copy.subtitle, style: ws.body.copyWith(color: ws.muted)),
          SizedBox(height: spacing.xxl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: emailEnabled ? 1 : 0.55,
                child: WorkshopTextField(
                  key: const Key('sign-in-email'),
                  controller: emailController,
                  label: copy.emailLabel,
                  enabled: emailEnabled,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofocus: autofocusEmail,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  validator: validateEmail,
                ),
              ),
              SizedBox(height: spacing.md),
              if (challenge)
                WorkshopTextField(
                  key: const Key('sign-in-code'),
                  controller: codeController,
                  label: copy.codeLabel,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  validator: validateCode,
                  onFieldSubmitted: (_) {
                    if (!submitting) {
                      onSubmit();
                    }
                  },
                )
              else
                WorkshopTextField(
                  key: const Key('sign-in-password'),
                  controller: passwordController,
                  label: copy.passwordLabel,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: validatePassword,
                  suffixIcon: IconButton(
                    tooltip: obscurePassword
                        ? l10n.showPassword
                        : l10n.hidePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: ws.muted,
                    ),
                    onPressed: onToggleObscure,
                  ),
                  onFieldSubmitted: (_) {
                    if (!submitting) {
                      onSubmit();
                    }
                  },
                ),
              if (errorText != null) ...[
                SizedBox(height: spacing.md),
                _FailureBanner(message: errorText!),
              ],
              SizedBox(height: spacing.lg),
              SigninSubmitButton(
                label: challenge ? copy.verifyLabel : copy.signInLabel,
                loadingLabel: copy.loadingLabel,
                isLoading: submitting,
                onPressed: onSubmit,
              ),
              SizedBox(height: spacing.md),
              Text(copy.help, style: ws.meta.copyWith(color: ws.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inline failure banner. Announced once, never colour-only, and it sits above
/// the action so the eye finds it before retrying.
class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: context.motionDuration(const Duration(milliseconds: 180)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - t)),
          child: child,
        ),
      ),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: EdgeInsetsDirectional.all(spacing.sm),
          decoration: BoxDecoration(
            color: ws.dangerSoft,
            borderRadius: BorderRadius.circular(ws.controlRadius),
            border: Border.all(color: ws.danger.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 16, color: ws.danger),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: ws.body.copyWith(
                    color: ws.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
