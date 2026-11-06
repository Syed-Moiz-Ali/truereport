import 'package:auth/src/auth_controller.dart';
import 'package:auth/src/auth_repository.dart';
import 'package:auth/src/sign_in_view.dart';
import 'package:core/core.dart';
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
    return SignInView(
      emailController: _email,
      passwordController: _password,
      codeController: _code,
      formKey: _formKey,
      isArabic: locale.languageCode == 'ar',
      onLocaleChanged: (isArabic) => ref
          .read(localeProvider.notifier)
          .setLocale(Locale(isArabic ? 'ar' : 'en')),
      onSubmit: _submit,
      onValidateEmail: (value) {
        final required = _required(value);
        if (required != null) {
          return required;
        }
        return Validators.email(value) == null
            ? null
            : AppLocalizations.of(context).invalidEmail;
      },
      onValidateRequired: _required,
      challenge: _challengeToken != null,
      submitting: _submitting,
      errorText: errorText,
    );
  }
}

