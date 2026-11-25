import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

/// Self-service password change for the signed-in platform admin.
///
/// The server verifies the current password and revokes the other sessions, so
/// this is the safe replacement for sharing a password. Returns `true` when the
/// password actually changed.
Future<bool?> showProfilePasswordDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => const _ProfilePasswordDialog(),
  );
}

class _ProfilePasswordDialog extends ConsumerStatefulWidget {
  const _ProfilePasswordDialog();

  @override
  ConsumerState<_ProfilePasswordDialog> createState() =>
      _ProfilePasswordDialogState();
}

class _ProfilePasswordDialogState
    extends ConsumerState<_ProfilePasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;
  String? _errorCode;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _errorCode = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _errorCode = failure.code);
    } on Object {
      if (!mounted) return;
      setState(() => _errorCode = 'GENERIC');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final error = _errorText(strings);
    return PlatformDialogShell(
      title: strings.tKey(PlatformAdminKeys.pageProfilePasswordTitle),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformTextField(
              key: const Key('profile-password-current'),
              controller: _current,
              autofocus: true,
              obscureText: true,
              label: strings.tKey(PlatformAdminKeys.pageProfilePasswordCurrent),
              validator: (value) => (value == null || value.isEmpty)
                  ? strings.tKey(PlatformAdminKeys.pageProfilePasswordRequired)
                  : null,
            ),
            const SizedBox(height: 14),
            PlatformTextField(
              key: const Key('profile-password-new'),
              controller: _next,
              obscureText: true,
              label: strings.tKey(PlatformAdminKeys.pageProfilePasswordNew),
              helperText: strings.tKey(
                PlatformAdminKeys.pageProfilePasswordRule,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return strings.tKey(
                    PlatformAdminKeys.pageProfilePasswordRequired,
                  );
                }
                if (!_meetsPolicy(value)) {
                  return strings.tKey(
                    PlatformAdminKeys.pageProfilePasswordPolicy,
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            PlatformTextField(
              key: const Key('profile-password-confirm'),
              controller: _confirm,
              obscureText: true,
              label: strings.tKey(PlatformAdminKeys.pageProfilePasswordConfirm),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => value == _next.text
                  ? null
                  : strings.tKey(PlatformAdminKeys.pageProfilePasswordMismatch),
            ),
            if (error != null) ...[
              const SizedBox(height: 14),
              Container(
                key: const Key('profile-password-error'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: PtTheme.rose.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: PtTheme.rose.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  error,
                  style: PtTheme.font(12, lineHeight: 17, color: PtTheme.ink),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        PlatformGhostButton(
          key: const Key('profile-password-cancel'),
          label: strings.tKey(CommonKeys.buttonCancel),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        PlatformPrimaryButton(
          key: const Key('profile-password-submit'),
          label: strings.tKey(PlatformAdminKeys.pageProfilePasswordSubmit),
          isLoading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }

  String? _errorText(UiMessageStrings strings) {
    // Server failure codes map to plain copy; they are not lifecycle states.
    return switch (_errorCode) {
      // gate-allow: behaviour
      'PASSWORD_CURRENT_INVALID' => strings.tKey(
        PlatformAdminKeys.pageProfilePasswordCurrentInvalid,
      ),
      // gate-allow: behaviour
      'PASSWORD_UNCHANGED' => strings.tKey(
        PlatformAdminKeys.pageProfilePasswordUnchanged,
      ),
      // gate-allow: behaviour
      'PASSWORD_POLICY_VIOLATION' => strings.tKey(
        PlatformAdminKeys.pageProfilePasswordPolicy,
      ),
      // gate-allow: behaviour
      'GENERIC' => strings.tKey(PlatformAdminKeys.pageProfilePasswordFailed),
      _ => null,
    };
  }
}

/// Mirrors the server policy: 12–128 chars, upper + lower + digit + symbol.
bool _meetsPolicy(String value) {
  if (value.length < 12 || value.length > 128) return false;
  var upper = false;
  var lower = false;
  var digit = false;
  var special = false;
  for (final code in value.codeUnits) {
    final char = String.fromCharCode(code);
    if (char.toLowerCase() != char) {
      upper = true;
    } else if (char.toUpperCase() != char) {
      lower = true;
    } else if (code >= 0x30 && code <= 0x39) {
      digit = true;
    } else {
      special = true;
    }
  }
  return upper && lower && digit && special;
}
