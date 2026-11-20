import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/staff/staff_dossier.dart';
import 'package:workshop_admin_app/src/features/staff/staff_form_rules.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';

/// The password card on the member page — set a temporary password.
///
/// Writes through the existing `resetTechnicianPassword` call. The password
/// lives in local controllers only: never logged, never echoed in a message,
/// cleared on success and when the page is disposed. [highlighted] only tints
/// the card border for a moment when the page's primary action sends the admin
/// here; it never changes behaviour.
class StaffCredentialsSection extends StatefulWidget {
  const StaffCredentialsSection({
    required this.onSubmit,
    this.highlighted = false,
    super.key,
  });

  /// Performs the reset. Returning normally means success; throwing means the
  /// caller already reported the failure.
  final Future<void> Function(String password) onSubmit;
  final bool highlighted;

  @override
  State<StaffCredentialsSection> createState() =>
      _StaffCredentialsSectionState();
}

class _StaffCredentialsSectionState extends State<StaffCredentialsSection> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _confirmFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_changed);
    _confirm.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    // No clear() here: notifying listeners during teardown asserts inside the
    // still-unmounting TextFormFields. Disposing drops the values anyway.
    _password.dispose();
    _confirm.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy &&
      staffPasswordAcceptable(_password.text) &&
      _confirm.text == _password.text;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_canSubmit) {
      _confirmFocus.requestFocus();
      return;
    }
    final t = UiStrings.of(context);
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_password.text);
      if (!mounted) {
        return;
      }
      _password.clear();
      _confirm.clear();
      _formKey.currentState?.reset();
      setState(() => _submitted = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(t(WorkshopAdminKeys.contentSaved))),
        );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(t(WorkshopAdminKeys.actionFailed))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: t(WorkshopAdminKeys.passwordLabel)),
        SizedBox(height: spacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: ws.cardPaddingFor(MediaQuery.sizeOf(context).width),
          decoration: BoxDecoration(
            color: ws.surface,
            borderRadius: BorderRadius.circular(ws.cardLargeRadius),
            border: Border.all(
              color: widget.highlighted ? ws.accent : ws.border,
              width: widget.highlighted ? 2 : 1,
            ),
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 620;
                final password = WorkshopTextField(
                  key: const Key('staff-reset-password'),
                  controller: _password,
                  label: t(WorkshopAdminKeys.temporaryPassword),
                  hint: t(WorkshopAdminKeys.temporaryPassword),
                  obscureText: _obscure,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.next,
                  validator: (value) => staffPasswordError(t, value),
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
                );
                final confirm = WorkshopTextField(
                  key: const Key('staff-confirm-password'),
                  controller: _confirm,
                  label: t(WorkshopAdminKeys.confirmPasswordLabel),
                  hint: t(WorkshopAdminKeys.confirmPasswordHint),
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) =>
                      staffConfirmError(t, _password.text, value),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: password),
                          SizedBox(width: spacing.lg),
                          Expanded(child: confirm),
                        ],
                      )
                    else ...[
                      password,
                      SizedBox(height: spacing.md),
                      confirm,
                    ],
                    const SizedBox(height: 10),
                    StaffPasswordMeter(password: _password.text),
                    SizedBox(height: spacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (constraints.maxWidth < 320)
                          Expanded(
                            child: TemplatePillButton(
                              label: t(WorkshopAdminKeys.save),
                              loading: _busy,
                              expand: true,
                              onPressed: _canSubmit ? _submit : null,
                            ),
                          )
                        else
                          TemplatePillButton(
                            label: t(WorkshopAdminKeys.save),
                            loading: _busy,
                            onPressed: _canSubmit ? _submit : null,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
