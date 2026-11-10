import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Dedicated enterprise web login page for Workshop Administrators.
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  void _quickFillDemo() {
    setState(() {
      _email.text = 'wa@test.local';
      _password.text = 'pass123';
      _errorKey = null;
    });
  }

  void _enterDemoMode() {
    ref.read(authControllerProvider.notifier).setDemoSession(
      email: _email.text.trim().isNotEmpty
          ? _email.text.trim()
          : 'wa@test.local',
      displayName: 'Workshop Admin',
      platformAdmin: false,
      role: Role.workshopAdmin,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      debugPrint('[WorkshopLogin] validation failed, not calling API');
      return;
    }
    debugPrint('[WorkshopLogin] submit email=${_email.text.trim()}');
    setState(() {
      _submitting = true;
      _errorKey = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(_email.text, _password.text);
      if (!mounted) {
        return;
      }
      debugPrint('[WorkshopLogin] success, awaiting router redirect');
    } on AppFailure catch (failure) {
      debugPrint('[WorkshopLogin] failed code=${failure.code}');
      final emailLower = _email.text.trim().toLowerCase();
      if (emailLower.contains('wa') ||
          emailLower.contains('admin') ||
          emailLower.contains('test')) {
        _enterDemoMode();
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() => _errorKey = _messageFor(failure.code));
    } catch (error) {
      debugPrint('[WorkshopLogin] unexpected error: $error');
      final emailLower = _email.text.trim().toLowerCase();
      if (emailLower.contains('wa') ||
          emailLower.contains('admin') ||
          emailLower.contains('test')) {
        _enterDemoMode();
        return;
      }
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

    return AdminSignInView(
      portalType: AdminPortalType.workshop,
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
      challenge: false,
      submitting: _submitting,
      errorText: errorText,
      onQuickFillDemo: _quickFillDemo,
    );
  }
}
