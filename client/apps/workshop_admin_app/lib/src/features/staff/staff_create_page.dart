import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/staff/staff_dossier.dart';
import 'package:workshop_admin_app/src/features/staff/staff_form_rules.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';

/// Create a technician account — a full page, not a sheet, and not a wizard:
/// there are only three fields, so the page is one screen with two cards.
///
/// Same contract as before: full name, email and a temporary password (12–128)
/// via `createTechnician`, with `EMAIL_EXISTS` surfaced on the email field,
/// plus the confirmation field and the live strength read-out.
class StaffCreatePage extends ConsumerStatefulWidget {
  const StaffCreatePage({super.key});

  @override
  ConsumerState<StaffCreatePage> createState() => _StaffCreatePageState();
}

class _StaffCreatePageState extends ConsumerState<StaffCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  bool _obscure = true;
  bool _busy = false;
  String? _emailServerError;

  @override
  void initState() {
    super.initState();
    _name.addListener(_changed);
    _email.addListener(_changed);
    _password.addListener(_changed);
    _confirm.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    // Dispose without clearing: notifying listeners while the form is being
    // torn down asserts inside TextFormField. The values go with the
    // controllers, so nothing is retained.
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_busy) {
      return false;
    }
    final l10n = AppLocalizations.of(context);
    return staffNameError(l10n, _name.text) == null &&
        staffEmailError(l10n, _email.text) == null &&
        staffPasswordAcceptable(_password.text) &&
        _confirm.text == _password.text;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _emailServerError = null);
    if (!(_formKey.currentState?.validate() ?? false) || !_canSubmit) {
      if (staffNameError(l10n, _name.text) != null) {
        _nameFocus.requestFocus();
      } else {
        _emailFocus.requestFocus();
      }
      return;
    }
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(adminApiProvider)
          .createTechnician(
            email: _email.text.trim(),
            displayName: _name.text.trim(),
            initialPassword: _password.text,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(created);
    } on AppFailure catch (failure) {
      if (!mounted) {
        return;
      }
      if (failure.code == 'EMAIL_EXISTS') {
        setState(() => _emailServerError = l10n.emailAlreadyInUse);
        _formKey.currentState?.validate();
        _emailFocus.requestFocus();
      } else {
        _notify(l10n.actionFailed);
      }
    } on Object {
      if (mounted) {
        _notify(l10n.actionFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The bar names the section; the page heading below owns the task.
            StaffPageBar(title: l10n.workshopStaffTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: ws.pagePadding(width),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            l10n.createTechnicianTitle,
                            style: ws.pageTitle.copyWith(
                              fontSize: width < 520 ? 26 : 30,
                              letterSpacing: -0.6,
                              color: ws.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.createTechnicianSubtitle,
                            style: ws.meta.copyWith(color: ws.muted),
                          ),
                          const SizedBox(height: 18),
                          WorkshopSectionHeader(title: l10n.details),
                          SizedBox(height: spacing.sm),
                          WorkshopCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _fields(context, l10n),
                                SizedBox(height: spacing.lg),
                                Row(
                                  children: [
                                    Text(
                                      l10n.role,
                                      style: ws.meta.copyWith(color: ws.muted),
                                    ),
                                    SizedBox(width: spacing.lg),
                                    Text(
                                      l10n.roleTechnician,
                                      style: ws.bodyStrong.copyWith(
                                        color: ws.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: spacing.xl),
                          WorkshopSectionHeader(title: l10n.passwordLabel),
                          SizedBox(height: spacing.sm),
                          WorkshopCard(child: _passwords(context, l10n)),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _footer(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _fields(BuildContext context, AppLocalizations l10n) {
    final name = WorkshopTextField(
      key: const Key('staff-create-name'),
      controller: _name,
      label: l10n.fullNameLabel,
      hint: l10n.fullNameHint,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      validator: (value) => staffNameError(l10n, value),
    );
    final email = WorkshopTextField(
      key: const Key('staff-create-email'),
      controller: _email,
      label: l10n.emailLabel,
      hint: l10n.technicianEmailHint,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      validator: (value) => _emailServerError ?? staffEmailError(l10n, value),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [name, const SizedBox(height: 14), email],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: name),
            SizedBox(width: context.spacing.lg),
            Expanded(child: email),
          ],
        );
      },
    );
  }

  Widget _passwords(BuildContext context, AppLocalizations l10n) {
    final password = WorkshopTextField(
      key: const Key('staff-create-password'),
      controller: _password,
      label: l10n.temporaryPassword,
      hint: l10n.temporaryPassword,
      obscureText: _obscure,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.next,
      validator: (value) => staffPasswordError(l10n, value),
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 18,
        ),
        tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
    final confirm = WorkshopTextField(
      key: const Key('staff-create-confirm'),
      controller: _confirm,
      label: l10n.confirmPasswordLabel,
      hint: l10n.confirmPasswordHint,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      validator: (value) => staffConfirmError(l10n, _password.text, value),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [password, const SizedBox(height: 14), confirm],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: password),
                SizedBox(width: context.spacing.lg),
                Expanded(child: confirm),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        StaffPasswordMeter(password: _password.text),
      ],
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n) {
    final ws = context.ws;
    final wide = MediaQuery.sizeOf(context).width >= 620;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
        vertical: 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Row(
            mainAxisAlignment: wide
                ? MainAxisAlignment.end
                : MainAxisAlignment.spaceBetween,
            children: [
              if (wide) ...[
                TemplatePillButton(
                  label: l10n.cancel,
                  variant: TemplatePillVariant.ghost,
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                TemplatePillButton(
                  label: l10n.create,
                  loading: _busy,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ] else ...[
                Expanded(
                  child: TemplatePillButton(
                    label: l10n.cancel,
                    variant: TemplatePillVariant.outline,
                    expand: true,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TemplatePillButton(
                    label: l10n.create,
                    loading: _busy,
                    expand: true,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
