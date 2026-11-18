import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import 'signin/signin_form.dart';
import 'signin/signin_identity_band.dart';
import 'signin/signin_inspection_surface.dart';
import 'signin/signin_language_toggle.dart';
import 'signin/signin_mark.dart';

/// Workshop Admin sign-in — direction B, "The bay" (`docs/ui_brief.md`).
///
/// Composition, not paint: a flush-left door on the paper canvas and a
/// full-bleed inspection surface carrying one labelled example job, its vehicle
/// drawn top-down, and the checklist as 24 ticks. Below 900 px (or below
/// 1100 px at ≥1.5× text) the surface collapses to a 132 px identity band so
/// the first field stays above the fold.
///
/// This file owns behaviour only — validation, submit, failure mapping, locale
/// switching. Every region lives in its own widget under `signin/`, and every
/// colour, size, radius and space comes from [WorkshopTokens].
class WorkshopLoginPage extends ConsumerStatefulWidget {
  const WorkshopLoginPage({super.key});

  @override
  ConsumerState<WorkshopLoginPage> createState() => _WorkshopLoginPageState();
}

class _WorkshopLoginPageState extends ConsumerState<WorkshopLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _errorKey;
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorKey = null;
    });
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .signIn(_email.text, _password.text);
      if (!mounted) {
        return;
      }
      // The admin app deliberately has no code-entry surface (see
      // source_scan_test.dart), so a challenge must be explained instead of
      // silently swallowing the result.
      if (result is AuthChallenge) {
        setState(() => _errorKey = 'twoFactorRequired');
        return;
      }
      TextInput.finishAutofillContext();
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _errorKey = _messageFor(failure.code));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorKey = 'genericError');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _messageFor(String code) {
    return switch (code) {
      'AUTH_INVALID_CREDENTIALS' => 'invalidCredentials',
      'NETWORK' ||
      'CONNECTIONERROR' ||
      'CONNECTIONTIMEOUT' ||
      'RECEIVETIMEOUT' ||
      'SENDTIMEOUT' => 'networkError',
      _ => 'genericError',
    };
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final required = _required(value);
    if (required != null) {
      return required;
    }
    return Validators.email(value) == null
        ? null
        : AppLocalizations.of(context).invalidEmail;
  }

  void _toggleLanguage() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    ref.read(localeProvider.notifier).setLocale(Locale(isArabic ? 'en' : 'ar'));
  }

  String? _errorText(AppLocalizations l10n) {
    return switch (_errorKey) {
      'invalidCredentials' => l10n.invalidCredentials,
      'networkError' => l10n.networkError,
      'twoFactorRequired' => l10n.twoFactorRequired,
      'genericError' => l10n.genericError,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final errorText = _errorText(l10n);

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // At 1.5× text the two-up split stops fitting honest line lengths,
            // so it collapses earlier than the width-only breakpoint.
            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final splitAt = textScale >= 1.5 ? 1100.0 : 900.0;
            final split = constraints.maxWidth >= splitAt;

            final form = AutofillGroup(
              child: SigninForm(
                formKey: _formKey,
                emailController: _email,
                passwordController: _password,
                obscurePassword: _obscurePassword,
                submitting: _submitting,
                errorText: errorText,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _submit,
                validateEmail: _validateEmail,
                validatePassword: _required,
                autofocusEmail: split,
              ),
            );

            // One 180 ms settle on first paint (zero under reduced motion).
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

            if (!split) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SigninIdentityBand(onToggleLanguage: _toggleLanguage),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        spacing.lg,
                        spacing.xl,
                        spacing.lg,
                        spacing.lg,
                      ),
                      // Top-weighted at every size: a phone user is in a hurry,
                      // and a tablet should not float the door in the middle of
                      // the screen. The band and the form share one 520 column.
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

            // 46 / 54: the door is narrower than the work it opens onto.
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
                              // The portal label already appears as the accent
                              // eyebrow inside the form; printing it twice
                              // within 80 px read as a mistake.
                              const Row(
                                children: [
                                  Flexible(
                                    child: SigninMark(
                                      onAccent: false,
                                      showPortalLabel: false,
                                    ),
                                  ),
                                  Spacer(),
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
                      // Declared after the form so it is the last tab stop,
                      // while still sitting in the top-right corner.
                      PositionedDirectional(
                        top: spacing.xxl,
                        end: spacing.lg,
                        child: SigninLanguageToggle(
                          onAccent: false,
                          onPressed: _toggleLanguage,
                        ),
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
