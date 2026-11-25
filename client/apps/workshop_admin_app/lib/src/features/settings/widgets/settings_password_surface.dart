import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/staff/staff_dossier.dart';
import 'package:workshop_admin_app/src/features/staff/staff_form_rules.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';

import 'settings_primitives.dart';

/// Self-service password change for the signed-in workshop administrator.
///
/// The server verifies the current password and revokes every other session,
/// so this card is the safe replacement for sharing a password over chat: the
/// administrator sets one only they know.
class SettingsPasswordSurface extends ConsumerStatefulWidget {
  const SettingsPasswordSurface({super.key});

  @override
  ConsumerState<SettingsPasswordSurface> createState() =>
      _SettingsPasswordSurfaceState();
}

class _SettingsPasswordSurfaceState
    extends ConsumerState<SettingsPasswordSurface> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _errorCode;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _current.addListener(_changed);
    _next.addListener(_changed);
    _confirm.addListener(_changed);
  }

  void _changed() => setState(() {
    _saved = false;
    _errorCode = null;
  });

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy &&
      _current.text.isNotEmpty &&
      staffPasswordAcceptable(_next.text) &&
      _confirm.text == _next.text;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || !_canSubmit) {
      return;
    }
    setState(() {
      _busy = true;
      _errorCode = null;
      _saved = false;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      _current.clear();
      _next.clear();
      _confirm.clear();
      _formKey.currentState?.reset();
      setState(() => _saved = true);
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

  String? _errorText(UiStrings t) {
    return switch (_errorCode) {
      'PASSWORD_CURRENT_INVALID' => t(WorkshopAdminKeys.passwordCurrentInvalid),
      'PASSWORD_UNCHANGED' => t(WorkshopAdminKeys.passwordUnchanged),
      'PASSWORD_POLICY_VIOLATION' => t(WorkshopAdminKeys.passwordPolicy),
      'GENERIC' => t(WorkshopAdminKeys.actionFailed),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final error = _errorText(t);

    return SettingsSurface(
      key: const Key('settings-password'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t(WorkshopAdminKeys.changePassword), style: ws.sectionTitle),
          const SizedBox(height: 8),
          Text(
            t(WorkshopAdminKeys.changePasswordSubtitle),
            style: ws.body.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                WorkshopTextField(
                  key: const Key('change-password-current'),
                  controller: _current,
                  label: t(WorkshopAdminKeys.currentPassword),
                  hint: t(WorkshopAdminKeys.currentPassword),
                  obscureText: _obscure,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value ?? '').isEmpty
                      ? t(WorkshopAdminKeys.requiredField)
                      : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    tooltip: _obscure
                        ? t(WorkshopAdminKeys.showPassword)
                        : t(WorkshopAdminKeys.hidePassword),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 14),
                WorkshopTextField(
                  key: const Key('change-password-new'),
                  controller: _next,
                  label: t(WorkshopAdminKeys.newPassword),
                  hint: t(WorkshopAdminKeys.newPassword),
                  obscureText: _obscure,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: (value) => staffPasswordError(t, value),
                ),
                const SizedBox(height: 8),
                StaffPasswordMeter(password: _next.text),
                const SizedBox(height: 14),
                WorkshopTextField(
                  key: const Key('change-password-confirm'),
                  controller: _confirm,
                  label: t(WorkshopAdminKeys.confirmPasswordLabel),
                  hint: t(WorkshopAdminKeys.confirmPasswordHint),
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) => staffConfirmError(t, _next.text, value),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: ws.body.copyWith(
                      color: ws.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_saved) ...[
                  const SizedBox(height: 12),
                  Text(
                    t(WorkshopAdminKeys.passwordUpdated),
                    style: ws.body.copyWith(
                      color: ws.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                SizedBox(height: spacing.lg),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TemplatePillButton(
                    label: t(WorkshopAdminKeys.save),
                    loading: _busy,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
