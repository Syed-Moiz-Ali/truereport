import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Entry point for the Figma screen 6 sheet (Create Staff Account, 480
/// right-sheet layout) as sheet content only.
///
/// This file opens nothing by itself. The staff-list trigger is wired
/// elsewhere by calling [showCreateTechnicianSheet], which returns the
/// created member (or null when the sheet is dismissed without creating).
/// The existing `staff_tab.dart` dialog flow is untouched.
///
/// Slot-sheet scope (F3-B step 2, screen 6): Full Name → `displayName`,
/// Email → `email`, Temporary Password → `initialPassword` (12–128 policy),
/// fixed Technician row, Cancel/Create → existing `createTechnician` +
/// `accountCreated`/`actionFailed` (+ `emailAlreadyInUse` on EMAIL_EXISTS).
/// Deliberately omitted: role picker, station allocation, magic-link switch,
/// permissions, metrics.
///
/// Password handling (Q6): the password lives only in a local
/// [TextEditingController], is never logged, never embedded in error
/// strings, never echoed anywhere except the obscured field with an eye
/// toggle, and is cleared on dispose.
///
/// Idempotency: no header is set here — the existing `createTechnician`
/// path in `admin_api.dart` already sends `Idempotency-Key` per call.
abstract final class CreateTechnicianSheet {
  const CreateTechnicianSheet._();

  /// Opens the create-technician sheet and returns the created member, or
  /// null when dismissed without creating.
  ///
  /// On wide layouts this is a right-hand [WorkshopSideSheet]; below
  /// [AppBreakpoints.phone] it falls back to the bottom sheet automatically.
  static Future<PlatformAccount?> showCreateTechnicianSheet(
    BuildContext context,
  ) async {
    final l10n = AppLocalizations.of(context);
    final scope = _CreateTechnicianScope();
    try {
      final created = await WorkshopSideSheet.show<PlatformAccount>(
        context,
        title: l10n.createTechnicianTitle,
        subtitle: l10n.createTechnicianSubtitle,
        closeSemanticLabel: l10n.close,
        body: _CreateTechnicianBody(scope: scope),
        footer: _CreateTechnicianFooter(scope: scope),
      );
      if (created != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).accountCreated)),
        );
      }
      return created;
    } finally {
      scope.dispose();
    }
  }
}

/// Shared mutable state between the sheet body (the form) and the fixed
/// footer (the Cancel/Create actions), both built by
/// [WorkshopSideSheet.show].
class _CreateTechnicianScope {
  Future<void> Function()? submit;
  final ValueNotifier<bool> busy = ValueNotifier<bool>(false);

  void dispose() => busy.dispose();
}

/// Fixed footer: Cancel plus the Create action.
class _CreateTechnicianFooter extends StatelessWidget {
  const _CreateTechnicianFooter({required this.scope});

  final _CreateTechnicianScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: scope.busy,
      builder: (context, busy, _) {
        return Row(
          children: [
            AppButton(
              label: l10n.cancel,
              variant: AppButtonVariant.text,
              onPressed: busy
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
            SizedBox(width: context.spacing.sm),
            Expanded(
              child: AppButton(
                label: l10n.create,
                onPressed: busy
                    ? null
                    : () {
                        scope.submit?.call();
                      },
                isLoading: busy,
                expand: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Scrollable sheet body: full name, email, temporary password and a
/// fixed-Technician row. No role picker, no station allocation, no
/// magic-link switch, no permissions — none have a server counterpart
/// per the slot sheet.
class _CreateTechnicianBody extends ConsumerStatefulWidget {
  const _CreateTechnicianBody({required this.scope});

  final _CreateTechnicianScope scope;

  @override
  ConsumerState<_CreateTechnicianBody> createState() =>
      _CreateTechnicianBodyState();
}

class _CreateTechnicianBodyState extends ConsumerState<_CreateTechnicianBody> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();

  /// Password lives here only (Q6): never logged, never placed in error
  /// strings, cleared (then disposed) when this state is disposed.
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    widget.scope.submit = _submit;
  }

  @override
  void dispose() {
    if (widget.scope.submit == _submit) {
      widget.scope.submit = null;
    }
    // Clear secrets before disposal so no password survives in memory.
    _name.clear();
    _email.clear();
    _password.clear();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _name,
            label: l10n.displayName,
            hint: l10n.displayName,
            textInputAction: TextInputAction.next,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.requiredField
                : null,
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: _email,
            label: l10n.email,
            hint: l10n.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.requiredField;
              }
              if (!value.contains('@')) {
                return l10n.invalidEmail;
              }
              return null;
            },
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: _password,
            label: l10n.temporaryPassword,
            hint: l10n.temporaryPassword,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              tooltip: _obscurePassword
                  ? l10n.showPassword
                  : l10n.hidePassword,
              onPressed: () => setState(
                () => _obscurePassword = !_obscurePassword,
              ),
            ),
            validator: (value) => _passwordError(l10n, value),
          ),
          SizedBox(height: context.spacing.sm),
          // Role is fixed to Technician (own workshop is server-derived);
          // no picker is rendered per the slot sheet.
          AppListTile(
            title: l10n.roleTechnician,
            subtitle: l10n.role,
          ),
        ],
      ),
    );
  }

  /// Mirrors `staffPasswordError` in `staff_tab.dart` (empty/short → the
  /// closest existing ARB string), plus the 128 upper bound from the
  /// server `PasswordPolicy` 12–128 (same closest-existing-key message, no
  /// new ARB string).
  String? _passwordError(AppLocalizations l10n, String? value) {
    if (value == null || value.isEmpty) {
      return l10n.requiredField;
    }
    if (value.length < 12 || value.length > 128) {
      return l10n.requiredField;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    widget.scope.busy.value = true;
    try {
      // No Idempotency-Key here: the existing createTechnician path in
      // admin_api.dart already sends one per call. Payload mirrors the
      // existing dialog exactly (trimmed email/displayName, raw password).
      final created = await ref
          .read(adminApiProvider)
          .createTechnician(
            email: _email.text.trim(),
            displayName: _name.text.trim(),
            initialPassword: _password.text,
          );
      ref.invalidate(staffProvider);
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } on AppFailure catch (failure) {
      // Q6: the password is never embedded in user-facing strings; only
      // localized labels are shown.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.code == 'EMAIL_EXISTS'
                  ? l10n.emailAlreadyInUse
                  : l10n.actionFailed,
            ),
          ),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
        );
      }
    } finally {
      widget.scope.busy.value = false;
    }
  }
}
