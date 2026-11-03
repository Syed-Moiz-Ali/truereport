import 'package:auth/src/auth_controller.dart';
import 'package:auth/src/auth_repository.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  String? _challengeToken;
  String? _errorKey;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
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
      final result = _challengeToken == null
          ? await ref
                .read(authControllerProvider.notifier)
                .signIn(_email.text, _password.text)
          : await ref
                .read(authControllerProvider.notifier)
                .verifyTwoFactor(_challengeToken!, _code.text);
      if (!mounted) {
        return;
      }
      if (result is AuthChallenge) {
        setState(() => _challengeToken = result.challengeToken);
      }
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
      'AUTH_2FA_INVALID' => 'invalidCredentials',
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final errorText = switch (_errorKey) {
      'invalidCredentials' => l10n.invalidCredentials,
      'networkError' => l10n.networkError,
      'genericError' => l10n.genericError,
      _ => null,
    };

    return AppScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 900
              ? constraints.maxWidth * 0.38
              : constraints.maxWidth;
          return SingleChildScrollView(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: context.spacing.sm,
                      runSpacing: context.spacing.sm,
                      children: [
                        AppSelectableText(
                          key: const Key('sign-in-language-en'),
                          label: l10n.languageEnglish,
                          selected: locale.languageCode == 'en',
                          onTap: () => ref
                              .read(localeProvider.notifier)
                              .setLocale(const Locale('en')),
                        ),
                        AppSelectableText(
                          key: const Key('sign-in-language-ar'),
                          label: l10n.languageArabic,
                          selected: locale.languageCode == 'ar',
                          onTap: () => ref
                              .read(localeProvider.notifier)
                              .setLocale(const Locale('ar')),
                        ),
                      ],
                    ),
                    SizedBox(height: context.spacing.lg),
                    FadeInCard(
                      child: AppCard(
                        padding: EdgeInsetsDirectional.all(context.spacing.xl),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.appTitle,
                                style: context.texts.displaySmall,
                              ),
                              SizedBox(height: context.spacing.xl),
                              Text(
                                l10n.signInTitle,
                                style: context.texts.headlineMedium,
                              ),
                              SizedBox(height: context.spacing.xs),
                              Text(
                                l10n.signInSubtitle,
                                style: context.texts.bodyLarge?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: context.spacing.xl),
                              AppTextField(
                                key: const Key('sign-in-email'),
                                controller: _email,
                                label: l10n.emailLabel,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textDirection: TextDirection.ltr,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  final required = _required(value);
                                  if (required != null) {
                                    return required;
                                  }
                                  return Validators.email(value) == null
                                      ? null
                                      : AppLocalizations.of(context)
                                            .invalidEmail;
                                },
                              ),
                              SizedBox(height: context.spacing.lg),
                              AppTextField(
                                key: const Key('sign-in-password'),
                                controller: _password,
                                label: l10n.passwordLabel,
                                obscureText: true,
                                autofillHints: const [AutofillHints.password],
                                textDirection: TextDirection.ltr,
                                textInputAction: TextInputAction.done,
                                validator: _required,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              if (_challengeToken != null) ...[
                                SizedBox(height: context.spacing.lg),
                                AppTextField(
                                  key: const Key('sign-in-code'),
                                  controller: _code,
                                  label: l10n.twoFactorLabel,
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.ltr,
                                  validator: (value) =>
                                      (value ?? '').length == 6
                                      ? null
                                      : l10n.requiredField,
                                ),
                              ],
                              AnimatedSwitcher(
                                duration: context.motionDuration(
                                  context.motion.normal,
                                ),
                                switchInCurve: context.motion.enterCurve,
                                switchOutCurve: context.motion.exitCurve,
                                child: errorText == null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: EdgeInsetsDirectional.only(
                                          top: context.spacing.lg,
                                        ),
                                        child: Text(
                                          errorText,
                                          key: ValueKey(errorText),
                                          style: context.texts.bodyMedium
                                              ?.copyWith(
                                                color: context.colors.error,
                                              ),
                                        ),
                                      ),
                              ),
                              SizedBox(height: context.spacing.xl),
                              AppButton(
                                key: const Key('sign-in-submit'),
                                label: _challengeToken == null
                                    ? l10n.signInButton
                                    : l10n.verifyButton,
                                isLoading: _submitting,
                                onPressed: _submit,
                                expand: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
