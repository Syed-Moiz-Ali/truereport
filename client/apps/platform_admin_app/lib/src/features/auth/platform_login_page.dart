import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import '../../platform_providers.dart';

/// Dedicated enterprise web login page for Platform Administrators.
class PlatformLoginPage extends ConsumerStatefulWidget {
  const PlatformLoginPage({super.key});

  @override
  ConsumerState<PlatformLoginPage> createState() => _PlatformLoginPageState();
}

class _PlatformLoginPageState extends ConsumerState<PlatformLoginPage> {
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
      } else {
        context.go('/workshops');
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
    final locale = ref.watch(platformLocaleProvider);
    final errorText = switch (_errorKey) {
      'invalidCredentials' => l10n.invalidCredentials,
      'networkError' => l10n.networkError,
      'genericError' => l10n.genericError,
      _ => null,
    };

    return AdminSignInView(
      portalType: AdminPortalType.platform,
      emailController: _email,
      passwordController: _password,
      codeController: _code,
      formKey: _formKey,
      isArabic: locale.languageCode == 'ar',
      onLocaleChanged: (isArabic) => ref
          .read(platformLocaleProvider.notifier)
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
