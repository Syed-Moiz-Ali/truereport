import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'signin_submit_button.dart';

/// The door: title block, two labelled fields, the inline failure banner and
/// the single primary action.
///
/// Behaviour lives in `WorkshopLoginPage` (validation, submit, failure mapping);
/// this file owns layout and the stable widget keys the characterization suite
/// pins.
class SigninForm extends StatelessWidget {
  const SigninForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.submitting,
    required this.errorText,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.validateEmail,
    required this.validatePassword,
    required this.autofocusEmail,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool submitting;
  final String? errorText;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
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
            l10n.signInPortalLabel.toUpperCase(),
            style: ws.eyebrow.copyWith(
              color: ws.accent,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.sm),
          Text(
            l10n.signInTitle,
            style: ws.heroNumber.copyWith(letterSpacing: -1.2),
          ),
          SizedBox(height: spacing.xs),
          Text(l10n.signInSubtitle, style: ws.body.copyWith(color: ws.muted)),
          SizedBox(height: spacing.xxl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              WorkshopTextField(
                key: const Key('sign-in-email'),
                controller: emailController,
                label: l10n.emailLabel,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofocus: autofocusEmail,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: validateEmail,
              ),
              SizedBox(height: spacing.md),
              WorkshopTextField(
                key: const Key('sign-in-password'),
                controller: passwordController,
                label: l10n.passwordLabel,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: validatePassword,
                suffixIcon: IconButton(
                  // Icon-only controls need an accessible name; the tooltip is
                  // also the label screen readers announce.
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
                label: l10n.signInButton,
                loadingLabel: l10n.signingIn,
                isLoading: submitting,
                onPressed: onSubmit,
              ),
              SizedBox(height: spacing.md),
              Text(l10n.signInHelp, style: ws.meta.copyWith(color: ws.muted)),
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
