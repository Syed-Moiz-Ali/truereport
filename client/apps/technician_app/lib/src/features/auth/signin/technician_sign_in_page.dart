import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import 'technician_sign_in_view.dart';

/// Technician sign-in — behaviour owner for direction C "The dock".
///
/// Preserves the audited contract (`docs/invariants.md`): AuthController calls,
/// 2FA challenge, error-code mapping, role/locale providers and widget keys.
/// The rebuild fixes three audited defects at the root: no page-level PII
/// logging, no keyboard double-submit, and recovery codes are accepted.
class TechnicianSignInPage extends ConsumerStatefulWidget {
  const TechnicianSignInPage({super.key});

  @override
  ConsumerState<TechnicianSignInPage> createState() =>
      _TechnicianSignInPageState();
}

class _TechnicianSignInPageState extends ConsumerState<TechnicianSignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _codeFocus = FocusNode();

  String? _challengeToken;
  String? _errorKey;
  bool _submitting = false;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Guards the keyboard path too: `onSubmitted` must not issue a second
    // request while one is in flight (audit S12).
    if (_submitting) {
      return;
    }
    _hasSubmitted = true;
    if (!(_formKey.currentState?.validate() ?? false)) {
      _focusFirstInvalid();
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
                .verifyTwoFactor(_challengeToken!, _code.text.trim());
      if (!mounted) {
        return;
      }
      if (result is AuthChallenge) {
        setState(() => _challengeToken = result.challengeToken);
        _codeFocus.requestFocus();
      } else {
        TextInput.finishAutofillContext();
      }
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      setState(() => _errorKey = _messageFor(failure.code));
      // Keep the retry close to the field: the password keeps focus unless the
      // failure happened in the code step.
      if (_challengeToken == null) {
        _passwordFocus.requestFocus();
      } else {
        _codeFocus.requestFocus();
      }
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

  void _focusFirstInvalid() {
    if (_validateEmail(_email.text) != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (_validateRequired(_password.text) != null) {
      _passwordFocus.requestFocus();
      return;
    }
    if (_challengeToken != null && _validateCode(_code.text) != null) {
      _codeFocus.requestFocus();
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

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final required = _validateRequired(value);
    if (required != null) {
      return required;
    }
    return Validators.email(value) == null
        ? null
        : AppLocalizations.of(context).invalidEmail;
  }

  /// The server accepts a 6-digit TOTP or its 11-character recovery code
  /// (`XXXXX-XXXXX`). Accepting only 6 characters made recovery impossible
  /// (audit G4).
  String? _validateCode(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    final totp = RegExp(r'^\d{6}$').hasMatch(text);
    final recovery = RegExp(r'^[A-Za-z0-9]{5}-[A-Za-z0-9]{5}$').hasMatch(text);
    return totp || recovery ? null : AppLocalizations.of(context).requiredField;
  }

  void _changeLocale(bool isArabic) {
    ref.read(localeProvider.notifier).setLocale(Locale(isArabic ? 'ar' : 'en'));
    // A previously shown validation message must re-render in the new locale;
    // the FormField caches the string returned by the validator.
    if (_hasSubmitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _formKey.currentState?.validate();
        }
      });
    }
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

    return TechnicianSignInView(
      emailController: _email,
      passwordController: _password,
      codeController: _code,
      formKey: _formKey,
      isArabic: locale.languageCode == 'ar',
      onLocaleChanged: _changeLocale,
      onSubmit: _submit,
      onValidateEmail: _validateEmail,
      onValidateRequired: _validateRequired,
      onValidateCode: _validateCode,
      emailFocus: _emailFocus,
      passwordFocus: _passwordFocus,
      codeFocus: _codeFocus,
      challenge: _challengeToken != null,
      submitting: _submitting,
      errorText: errorText,
    );
  }
}
