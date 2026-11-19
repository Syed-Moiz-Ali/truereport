import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/staff/staff_dossier.dart';
import 'package:workshop_admin_app/src/features/staff/staff_form_rules.dart';

/// `02 Reset password` — set a temporary password for one member.
///
/// Writes through the existing `resetTechnicianPassword` call. The password
/// lives in local controllers only: never logged, never echoed in a message,
/// cleared on success and when the page is disposed.
class StaffCredentialsSection extends StatefulWidget {
  const StaffCredentialsSection({
    required this.title,
    required this.onSubmit,
    super.key,
  });

  /// Section heading, e.g. `02  RESET PASSWORD`.
  final String title;

  /// Performs the reset. Returning normally means success; throwing means the
  /// caller already reported the failure.
  final Future<void> Function(String password) onSubmit;

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
    _password
      ..clear()
      ..dispose();
    _confirm
      ..clear()
      ..dispose();
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
    final l10n = AppLocalizations.of(context);
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
        ..showSnackBar(SnackBar(content: Text(l10n.contentSaved)));
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        StaffSectionHead(number: '02', title: widget.title),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 620;
              final password = WorkshopTextField(
                controller: _password,
                label: l10n.temporaryPassword,
                obscureText: _obscure,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.next,
                validator: (value) => staffPasswordError(l10n, value),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              );
              final confirm = WorkshopTextField(
                key: const Key('staff-confirm-password'),
                controller: _confirm,
                label: l10n.confirmPasswordLabel,
                hint: l10n.confirmPasswordHint,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) =>
                    staffConfirmError(l10n, _password.text, value),
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
                        const SizedBox(width: 16),
                        Expanded(child: confirm),
                      ],
                    )
                  else ...[
                    password,
                    const SizedBox(height: 14),
                    confirm,
                  ],
                  const SizedBox(height: 10),
                  StaffPasswordMeter(password: _password.text),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (MediaQuery.sizeOf(context).width < 520)
                        Expanded(
                          child: WorkshopButton(
                            label: l10n.save,
                            isLoading: _busy,
                            onPressed: _canSubmit ? _submit : null,
                          ),
                        )
                      else
                        WorkshopButton(
                          label: l10n.save,
                          isLoading: _busy,
                          onPressed: _canSubmit ? _submit : null,
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
