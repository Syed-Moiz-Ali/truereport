import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../platform_providers.dart';

/// Platform Administrator sign-in — the shared "bay" (`packages/auth`).
///
/// Same composition as the workshop and technician apps. Behaviour only:
/// validation, submit, failure mapping, the 2FA challenge, the backend-driven
/// language menu and the post-login navigation.
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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
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
                .verifyTwoFactor(_challengeToken!, _code.text.trim());
      if (!mounted) {
        return;
      }
      if (result is AuthChallenge) {
        setState(() => _challengeToken = result.challengeToken);
      } else {
        TextInput.finishAutofillContext();
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
      return ref
          .read(uiStringsProvider)
          .tKey(CommonKeys.validationRequiredField);
    }
    return null;
  }

  /// 6-digit TOTP or the server's 11-character recovery code.
  String? _validateCode(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return ref
          .read(uiStringsProvider)
          .tKey(CommonKeys.validationRequiredField);
    }
    final totp = RegExp(r'^\d{6}$').hasMatch(text);
    final recovery = RegExp(r'^[A-Za-z0-9]{5}-[A-Za-z0-9]{5}$').hasMatch(text);
    return totp || recovery
        ? null
        : ref.read(uiStringsProvider).tKey(CommonKeys.validationRequiredField);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final uiState = ref.watch(uiMessageControllerProvider);
    final manifest = uiState.manifest;
    final languages = manifest == null
        ? const <_LangChoice>[]
        : [
            for (final language in manifest.languages)
              _LangChoice(
                code: language.code,
                displayName: language.displayName,
              ),
          ];
    final selectedCode = uiState.activeLanguage;
    final errorText = switch (_errorKey) {
      'invalidCredentials' => strings.tKey(CommonKeys.errorInvalidCredentials),
      'networkError' => strings.tKey(CommonKeys.errorNetwork),
      'genericError' => strings.tKey(CommonKeys.errorGeneric),
      _ => null,
    };
    String read(UiMessageKey key) => strings.tKey(key);

    final copy = SignInBayCopy(
      portalLabel: read(PlatformAdminKeys.loginPortalBadge),
      title: read(PlatformAdminKeys.loginSignInTitle),
      subtitle: read(PlatformAdminKeys.loginSignInSubtitle),
      // The login screen has no help channel of its own, so the caption carries
      // the real support address (selectable, so it can be copied).
      help:
          '${read(PlatformAdminKeys.loginNeedHelp)} '
          '${read(PlatformAdminKeys.headerHelpContact)}',
      emailLabel: read(PlatformAdminKeys.loginEmailLabel),
      passwordLabel: read(PlatformAdminKeys.loginPasswordLabel),
      emailHint: read(PlatformAdminKeys.loginEmailHint),
      passwordHint: read(PlatformAdminKeys.loginPasswordHint),
      codeLabel: read(PlatformAdminKeys.loginCodeLabel),
      signInLabel: read(PlatformAdminKeys.loginSignInButton),
      verifyLabel: read(PlatformAdminKeys.loginVerifyButton),
      loadingLabel: read(PlatformAdminKeys.loginSignInButton),
    );

    return SignInBayView(
      copy: copy,
      formKey: _formKey,
      emailController: _email,
      passwordController: _password,
      codeController: _code,
      challenge: _challengeToken != null,
      emailEnabled: _challengeToken == null,
      obscurePassword: _obscurePassword,
      submitting: _submitting,
      errorText: errorText,
      onToggleObscure: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      onSubmit: _submit,
      validateEmail: (value) {
        final required = _required(value);
        if (required != null) {
          return required;
        }
        return Validators.email(value) == null
            ? null
            : ref
                  .read(uiStringsProvider)
                  .tKey(CommonKeys.validationInvalidEmail);
      },
      validatePassword: _required,
      validateCode: _validateCode,
      languageControl: (onAccent) => _LanguageMenu(
        languages: languages,
        selectedCode: selectedCode,
        onSelected: (code) =>
            ref.read(uiMessageSwitcherProvider).switchTo(code),
        onAccent: onAccent,
      ),
    );
  }
}

/// Compact language menu rendered in the same two places as the EN/AR toggle.
class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({
    required this.languages,
    required this.selectedCode,
    required this.onSelected,
    required this.onAccent,
  });

  final List<_LangChoice> languages;
  final String selectedCode;
  final ValueChanged<String> onSelected;
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }
    final foreground = onAccent ? ws.onAccent.withValues(alpha: 0.9) : ws.muted;
    var selected = languages.first;
    for (final option in languages) {
      if (option.code == selectedCode) {
        selected = option;
      }
    }
    return PopupMenuButton<String>(
      key: const Key('sign-in-language-menu'),
      onSelected: onSelected,
      tooltip: selected.displayName,
      itemBuilder: (menuContext) => [
        for (final option in languages)
          PopupMenuItem<String>(
            key: Key('sign-in-language-${option.code}'),
            value: option.code,
            child: Row(
              children: [
                Expanded(child: Text(option.displayName)),
                if (option.code == selected.code)
                  Icon(Icons.check_rounded, size: 16, color: ws.accent),
              ],
            ),
          ),
      ],
      child: SizedBox(
        height: ws.touchTarget,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                selected.displayName,
                style: ws.meta.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChoice {
  const _LangChoice({required this.code, required this.displayName});

  final String code;
  final String displayName;
}
