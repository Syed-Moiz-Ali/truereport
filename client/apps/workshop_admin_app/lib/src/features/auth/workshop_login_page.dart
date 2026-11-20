import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';

/// Workshop Admin sign-in — the shared "bay" (`packages/auth`).
///
/// Behaviour only: validation, submit, failure mapping and locale switching.
/// Composition lives in [SignInBayView] so the workshop, technician and
/// platform sign-ins cannot drift. The workshop app has no code-entry surface
/// (`source_scan_test.dart`), so a challenge is explained instead of rendered.
class WorkshopLoginPage extends ConsumerStatefulWidget {
  const WorkshopLoginPage({super.key});

  @override
  ConsumerState<WorkshopLoginPage> createState() => _WorkshopLoginPageState();
}

class _WorkshopLoginPageState extends ConsumerState<WorkshopLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  String? _errorKey;
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        UiStrings.of(context)(WorkshopAdminKeys.signinCheckFields),
        Directionality.of(context),
      );
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
      return UiStrings.of(context)(WorkshopAdminKeys.requiredField);
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
        : UiStrings.of(context)(WorkshopAdminKeys.invalidEmail);
  }

  String? _errorText(UiStrings t) {
    return switch (_errorKey) {
      'invalidCredentials' => t(WorkshopAdminKeys.invalidCredentials),
      'networkError' => t(WorkshopAdminKeys.networkError),
      'twoFactorRequired' => t(WorkshopAdminKeys.twoFactorRequired),
      'genericError' => t(WorkshopAdminKeys.genericError),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final copy = SignInBayCopy(
      portalLabel: t(WorkshopAdminKeys.signInPortalLabel),
      title: t(WorkshopAdminKeys.signInTitle),
      subtitle: t(WorkshopAdminKeys.signInSubtitle),
      help: t(WorkshopAdminKeys.signInHelp),
      emailLabel: t(WorkshopAdminKeys.emailLabel),
      passwordLabel: t(WorkshopAdminKeys.passwordLabel),
      emailHint: t(WorkshopAdminKeys.signinEmailHint),
      passwordHint: t(WorkshopAdminKeys.signinPasswordHint),
      codeLabel: t(WorkshopAdminKeys.twoFactorLabel),
      signInLabel: t(WorkshopAdminKeys.signInButton),
      verifyLabel: t(WorkshopAdminKeys.signInButton),
      loadingLabel: t(WorkshopAdminKeys.signingIn),
    );

    return SignInBayView(
      copy: copy,
      formKey: _formKey,
      emailController: _email,
      passwordController: _password,
      codeController: _code,
      obscurePassword: _obscurePassword,
      submitting: _submitting,
      errorText: _errorText(t),
      onToggleObscure: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onSubmit: _submit,
      validateEmail: _validateEmail,
      validatePassword: _required,
      validateCode: (_) => null,
    );
  }
}
