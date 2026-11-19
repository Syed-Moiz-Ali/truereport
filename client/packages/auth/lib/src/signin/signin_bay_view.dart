import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'signin_copy.dart';
import 'signin_form.dart';
import 'signin_identity_band.dart';
import 'signin_inspection_surface.dart';
import 'signin_language_toggle.dart';
import 'signin_mark.dart';

/// The shared sign-in composition — "the bay".
///
/// A flush-left door on the paper canvas and a full-bleed inspection surface
/// carrying one labelled example job, its vehicle drawn top-down, and the
/// checklist as 24 ticks. Below 900 px (or below 1100 px at >= 1.5x text) the
/// surface collapses to a 132 px identity band so the first field stays above
/// the fold.
///
/// Behaviour (validation, submit, failure mapping, challenge, locale) stays in
/// each app's page. This widget owns composition only. It is used by the
/// workshop, technician and platform sign-in pages so the three cannot drift.
class SignInBayView extends StatelessWidget {
  const SignInBayView({
    required this.copy,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.codeController,
    required this.obscurePassword,
    required this.submitting,
    required this.errorText,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateCode,
    required this.onToggleLanguage,
    this.challenge = false,
    this.emailEnabled = true,
    this.autofocusEmail,
    this.languageControl,
    super.key,
  });

  final SignInBayCopy copy;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController codeController;
  final bool obscurePassword;
  final bool submitting;
  final String? errorText;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateCode;
  final VoidCallback onToggleLanguage;

  /// Challenge state: the password cell is replaced by the code cell and the
  /// primary label becomes "Verify".
  final bool challenge;

  /// The account cell stays visible but read-only during a challenge.
  final bool emailEnabled;

  /// `null` lets the view decide from the split (email autofocus on desktop).
  final bool? autofocusEmail;

  /// Platform Admin needs its own multi-language selector. It is rendered in
  /// the same two places as the default EN/AR toggle.
  final Widget Function(bool onAccent)? languageControl;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final splitAt = textScale >= 1.5 ? 1100.0 : 900.0;
            final split = constraints.maxWidth >= splitAt;

            final form = AutofillGroup(
              child: SigninForm(
                formKey: formKey,
                copy: copy,
                emailController: emailController,
                passwordController: passwordController,
                codeController: codeController,
                challenge: challenge,
                emailEnabled: emailEnabled,
                obscurePassword: obscurePassword,
                submitting: submitting,
                errorText: errorText,
                onToggleObscure: onToggleObscure,
                onSubmit: onSubmit,
                validateEmail: validateEmail,
                validatePassword: validatePassword,
                validateCode: validateCode,
                autofocusEmail: autofocusEmail ?? split,
              ),
            );

            final settle = TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: context.motionDuration(
                const Duration(milliseconds: 180),
              ),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - t)),
                  child: child,
                ),
              ),
              child: form,
            );

            Widget language(bool onAccent) =>
                languageControl?.call(onAccent) ??
                SigninLanguageToggle(
                  onAccent: onAccent,
                  onPressed: onToggleLanguage,
                );

            if (!split) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SigninIdentityBand(
                    portalLabel: copy.portalLabel,
                    appName: copy.appName,
                    languageControl: language,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        spacing.lg,
                        spacing.xl,
                        spacing.lg,
                        spacing.lg,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: settle,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final gutter = constraints.maxWidth >= 1200
                ? spacing.massive + spacing.xl
                : spacing.massive;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 46,
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          gutter,
                          spacing.xxl,
                          spacing.massive,
                          spacing.xxl,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: SigninMark(
                                      onAccent: false,
                                      portalLabel: copy.portalLabel,
                                      appName: copy.appName,
                                      showPortalLabel: false,
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const SizedBox(height: 96),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 372,
                                ),
                                child: settle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: spacing.xxl,
                        end: spacing.lg,
                        child: language(false),
                      ),
                    ],
                  ),
                ),
                const Expanded(flex: 54, child: SigninInspectionSurface()),
              ],
            );
          },
        ),
      ),
    );
  }
}
