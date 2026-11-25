import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_models.dart';
import '../../../platform_providers.dart';
import '../../../platform_theme.dart';
import '../workshop_form.dart';
import '../workshop_status.dart';
import 'atlas_ui.dart';
import 'password_policy.dart';
import 'staff_error_messages.dart';
import 'workshop_record_parts.dart';

String _roleLabel(UiMessageStrings strings, String role) {
  final normalized = role.trim().toUpperCase();
  if (normalized == 'WORKSHOP_ADMIN') {
    return strings.tKey(CommonKeys.roleWorkshopAdmin);
  }
  if (normalized == 'TECHNICIAN') {
    return strings.tKey(CommonKeys.roleTechnician);
  }
  return role.trim().isEmpty ? '—' : role;
}

/// Staff tab: grouped rows for admins, technicians and pending invitations.
class WorkshopStaffSection extends ConsumerWidget {
  const WorkshopStaffSection({
    super.key,
    required this.workshop,
    required this.onChanged,
  });

  final HierarchyWorkshop workshop;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.tKey(PlatformAdminKeys.tabWorkshopStaff),
                    style: Atlas.sectionTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${workshopStaffTotal(workshop)}',
                    key: const Key('workshop_staff_total'),
                    style: Atlas.text(
                      12,
                      weight: FontWeight.w600,
                      tabular: true,
                      color: PtTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            AtlasButton(
              label: strings.tKey(PlatformAdminKeys.buttonWorkshopAddStaff),
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () => showWorkshopAddStaffDialog(
                context: context,
                strings: strings,
                workshopId: workshop.id,
                onSaved: () {
                  onChanged();
                  ref.invalidate(hierarchyStateProvider);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AtlasSurface(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StaffGroup(
                strings: strings,
                title: strings.tKey(PlatformAdminKeys.sectionWorkshopAdmins),
                accounts: workshop.admins,
                emptyTitle: strings.tKey(
                  PlatformAdminKeys.emptyWorkshopAdminsTitle,
                ),
                emptyBody: strings.tKey(
                  PlatformAdminKeys.emptyWorkshopAdminsBody,
                ),
                onToggle: (account) =>
                    _toggleStaffStatus(context, ref, strings, account),
                onResetPassword: (account) =>
                    _resetStaffPassword(context, ref, strings, account),
              ),
              const Divider(height: 1, color: PtTheme.border),
              _StaffGroup(
                strings: strings,
                title: strings.tKey(
                  PlatformAdminKeys.sectionWorkshopTechnicians,
                ),
                accounts: workshop.technicians,
                emptyTitle: strings.tKey(
                  PlatformAdminKeys.emptyWorkshopTechniciansTitle,
                ),
                emptyBody: strings.tKey(
                  PlatformAdminKeys.emptyWorkshopTechniciansBody,
                ),
                onToggle: (account) =>
                    _toggleStaffStatus(context, ref, strings, account),
              ),
              const Divider(height: 1, color: PtTheme.border),
              _StaffGroup(
                strings: strings,
                title: strings.tKey(
                  PlatformAdminKeys.sectionWorkshopPendingInvitations,
                ),
                accounts: workshop.pendingInvitations,
                pending: true,
                emptyTitle: strings.tKey(
                  PlatformAdminKeys.emptyWorkshopPendingInvitationsTitle,
                ),
                emptyBody: strings.tKey(
                  PlatformAdminKeys.emptyWorkshopPendingInvitationsBody,
                ),
                onToggle: (account) =>
                    _toggleStaffStatus(context, ref, strings, account),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _resetStaffPassword(
    BuildContext context,
    WidgetRef ref,
    UiMessageStrings strings,
    PlatformAccount account,
  ) async {
    final password = await showResetPasswordDialog(
      context: context,
      strings: strings,
      account: account,
    );
    if (password == null || !context.mounted) return;
    try {
      await ref
          .read(platformApiProvider)
          .resetUserPassword(account.userId, password);
      ref.invalidate(hierarchyStateProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(strings.tKey(PlatformAdminKeys.resetPasswordSuccess)),
          ),
        );
    } catch (error) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AtlasDialogShell(
          title: strings.tKey(CommonKeys.stateError),
          body: Text(staffErrorMessage(strings, error), style: Atlas.body),
          actions: [
            AtlasButton(
              label: strings.tKey(CommonKeys.buttonClose),
              variant: AtlasButtonVariant.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _toggleStaffStatus(
    BuildContext context,
    WidgetRef ref,
    UiMessageStrings strings,
    PlatformAccount account,
  ) async {
    final isActive = account.status.toUpperCase() == 'ACTIVE';
    final reason = await showReasonDialog(
      context: context,
      strings: strings,
      title: isActive
          ? strings.tKey(CommonKeys.buttonDisable)
          : strings.tKey(CommonKeys.buttonReactivate),
      body: account.displayName,
      confirmLabel: isActive
          ? strings.tKey(CommonKeys.buttonDisable)
          : strings.tKey(CommonKeys.buttonReactivate),
      destructive: isActive,
    );
    if (reason == null || !context.mounted) return;
    try {
      final api = ref.read(platformApiProvider);
      if (isActive) {
        await api.disableUser(account.userId, reason);
      } else {
        await api.reactivateUser(account.userId, reason);
      }
      onChanged();
      ref.invalidate(hierarchyStateProvider);
    } catch (_) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AtlasDialogShell(
          title: strings.tKey(CommonKeys.stateError),
          body: Text(strings.tKey(CommonKeys.stateError), style: Atlas.body),
          actions: [
            AtlasButton(
              label: strings.tKey(CommonKeys.buttonClose),
              variant: AtlasButtonVariant.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      );
    }
  }
}

class _StaffGroup extends StatelessWidget {
  const _StaffGroup({
    required this.strings,
    required this.title,
    required this.accounts,
    required this.emptyTitle,
    required this.emptyBody,
    required this.onToggle,
    this.onResetPassword,
    this.pending = false,
  });

  final UiMessageStrings strings;
  final String title;
  final List<PlatformAccount> accounts;
  final String emptyTitle;
  final String emptyBody;
  final ValueChanged<PlatformAccount> onToggle;
  final ValueChanged<PlatformAccount>? onResetPassword;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Atlas.eyebrow)),
              Text(
                '${accounts.length}',
                style: Atlas.text(
                  11,
                  weight: FontWeight.w700,
                  tabular: true,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emptyTitle,
                    style: Atlas.text(12.5, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    emptyBody,
                    style: Atlas.text(11.5, height: 1.45, color: PtTheme.muted),
                  ),
                ],
              ),
            )
          else
            for (final account in accounts)
              _StaffRow(
                strings: strings,
                account: account,
                pending: pending,
                onToggle: () => onToggle(account),
                onResetPassword: onResetPassword == null
                    ? null
                    : () => onResetPassword!(account),
              ),
        ],
      ),
    );
  }
}

class _StaffRow extends ConsumerWidget {
  const _StaffRow({
    required this.strings,
    required this.account,
    required this.pending,
    required this.onToggle,
    this.onResetPassword,
  });

  final UiMessageStrings strings;
  final PlatformAccount account;
  final bool pending;
  final VoidCallback onToggle;
  final VoidCallback? onResetPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = account.status.toUpperCase() == 'ACTIVE';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pending ? Atlas.amberTint : Atlas.neutralTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              Atlas.initials(account.displayName),
              style: Atlas.text(
                12,
                weight: FontWeight.w800,
                color: pending ? PtTheme.amber : PtTheme.deepGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.displayName,
                  style: Atlas.text(13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Tooltip(
                  message: account.email,
                  child: Text(
                    account.email.isEmpty
                        ? strings.tKey(CommonKeys.emptyTitle)
                        : account.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Atlas.text(11, color: PtTheme.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!pending) ...[
            Text(
              _roleLabel(strings, account.role),
              style: Atlas.text(
                11,
                weight: FontWeight.w600,
                color: PtTheme.muted,
              ),
            ),
            const SizedBox(width: 10),
            AtlasPill(
              label: workshopMemberStatusLabel(ref, account.status),
              tone: workshopTone(account.status),
            ),
            if (onResetPassword != null) ...[
              const SizedBox(width: 6),
              AtlasIconButton(
                icon: Icons.key_outlined,
                tooltip: strings.tKey(
                  PlatformAdminKeys.buttonWorkshopResetPassword,
                ),
                onPressed: onResetPassword,
              ),
            ],
            const SizedBox(width: 6),
            AtlasIconButton(
              icon: isActive
                  ? Icons.person_off_outlined
                  : Icons.person_add_alt_1_outlined,
              tooltip: isActive
                  ? strings.tKey(CommonKeys.buttonDisable)
                  : strings.tKey(CommonKeys.buttonReactivate),
              danger: isActive,
              onPressed: onToggle,
            ),
          ] else
            Text(
              strings.tKey(PlatformAdminKeys.sectionWorkshopPendingInvitations),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Atlas.text(11, color: PtTheme.muted),
            ),
        ],
      ),
    );
  }
}

Future<void> showWorkshopAddStaffDialog({
  required BuildContext context,
  required UiMessageStrings strings,
  required String workshopId,
  required VoidCallback onSaved,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AddStaffDialog(
      strings: strings,
      workshopId: workshopId,
      title: strings.tKey(PlatformAdminKeys.buttonWorkshopAddStaff),
      onSaved: () {
        Navigator.of(dialogContext).pop();
        onSaved();
      },
    ),
  );
}

class _AddStaffDialog extends ConsumerStatefulWidget {
  const _AddStaffDialog({
    required this.strings,
    required this.workshopId,
    required this.title,
    required this.onSaved,
  });

  final UiMessageStrings strings;
  final String workshopId;
  final String title;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends ConsumerState<_AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _emailError(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return widget.strings.tKey(CommonKeys.validationRequiredField);
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return widget.strings.tKey(CommonKeys.validationInvalidEmail);
    }
    return null;
  }

  String? _passwordError(String value) =>
      accountPasswordError(widget.strings, value);

  String? _confirmError(String value) =>
      accountPasswordConfirmError(widget.strings, _password.text, value);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      if ((_name.text.trim()).isEmpty) {
        _nameFocus.requestFocus();
      } else if (_emailError(_email.text) != null) {
        _emailFocus.requestFocus();
      } else if (_passwordError(_password.text) != null) {
        _passwordFocus.requestFocus();
      } else {
        _confirmFocus.requestFocus();
      }
      return;
    }
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformApiProvider)
          .createUser(
            email: _email.text.trim(),
            displayName: _name.text.trim(),
            temporaryPassword: _password.text,
            role: 'WORKSHOP_ADMIN',
            workshopId: widget.workshopId,
          );
      if (!mounted) return;
      widget.onSaved();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = staffErrorMessage(widget.strings, error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AtlasDialogShell(
      title: widget.title,
      maxWidth: 560,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: Atlas.text(
                  12.5,
                  weight: FontWeight.w600,
                  color: PtTheme.rose,
                ),
              ),
              const SizedBox(height: 12),
            ],
            AtlasTextField(
              key: const Key('input-staff-name'),
              controller: _name,
              focusNode: _nameFocus,
              label: strings.tKey(CommonKeys.fieldDisplayName),
              hint: strings.tKey(CommonKeys.fieldDisplayName),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? strings.tKey(CommonKeys.validationRequiredField)
                  : null,
            ),
            const SizedBox(height: 14),
            AtlasTextField(
              key: const Key('input-staff-email'),
              controller: _email,
              focusNode: _emailFocus,
              label: strings.tKey(CommonKeys.fieldEmail),
              hint: strings.tKey(CommonKeys.fieldEmail),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (value) => _emailError(value ?? ''),
            ),
            const SizedBox(height: 14),
            AtlasTextField(
              key: const Key('input-staff-password'),
              controller: _password,
              focusNode: _passwordFocus,
              label: strings.tKey(CommonKeys.fieldTemporaryPassword),
              hint: strings.tKey(CommonKeys.fieldTemporaryPassword),
              obscureText: _obscure,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                tooltip: strings.tKey(CommonKeys.buttonShowPassword),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (value) => _passwordError(value ?? ''),
            ),
            const SizedBox(height: 14),
            AtlasTextField(
              key: const Key('input-staff-password-confirm'),
              controller: _confirm,
              focusNode: _confirmFocus,
              label: strings.tKey(CommonKeys.fieldConfirmPassword),
              hint: strings.tKey(CommonKeys.fieldConfirmPassword),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => _confirmError(value ?? ''),
            ),
            const SizedBox(height: 14),
            Text(
              strings.tKey(PlatformAdminKeys.addStaffHelperTemporaryPassword),
              style: Atlas.text(11.5, height: 1.45, color: PtTheme.muted),
            ),
            const SizedBox(height: 12),
            Text(
              strings.tKey(PlatformAdminKeys.addStaffRoleAdminDescription),
              style: Atlas.text(11.5, height: 1.45, color: PtTheme.muted),
            ),
          ],
        ),
      ),
      actions: [
        AtlasButton(
          label: strings.tKey(CommonKeys.buttonCancel),
          variant: AtlasButtonVariant.secondary,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
        AtlasButton(
          label: strings.tKey(PlatformAdminKeys.buttonWorkshopAddStaff),
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

Future<String?> showResetPasswordDialog({
  required BuildContext context,
  required UiMessageStrings strings,
  required PlatformAccount account,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _ResetPasswordDialog(
      strings: strings,
      account: account,
      onSaved: (password) => Navigator.of(dialogContext).pop(password),
    ),
  );
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({
    required this.strings,
    required this.account,
    required this.onSaved,
  });

  final UiMessageStrings strings;
  final PlatformAccount account;
  final ValueChanged<String> onSaved;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _passwordError(String value) =>
      accountPasswordError(widget.strings, value);

  String? _confirmError(String value) =>
      accountPasswordConfirmError(widget.strings, _password.text, value);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (_passwordError(_password.text) != null) {
        _passwordFocus.requestFocus();
      } else {
        _confirmFocus.requestFocus();
      }
      return;
    }
    widget.onSaved(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AtlasDialogShell(
      title: strings.tKey(PlatformAdminKeys.resetPasswordTitle),
      maxWidth: 480,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.account.displayName,
              style: Atlas.text(13, weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.account.email,
              style: Atlas.text(11.5, color: PtTheme.muted),
            ),
            const SizedBox(height: 14),
            Text(
              strings.tKey(PlatformAdminKeys.resetPasswordHelper),
              style: Atlas.text(11.5, height: 1.45, color: PtTheme.muted),
            ),
            const SizedBox(height: 14),
            AtlasTextField(
              key: const Key('input-reset-password'),
              controller: _password,
              focusNode: _passwordFocus,
              label: strings.tKey(CommonKeys.fieldTemporaryPassword),
              hint: strings.tKey(CommonKeys.fieldTemporaryPassword),
              obscureText: _obscure,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                tooltip: strings.tKey(CommonKeys.buttonShowPassword),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (value) => _passwordError(value ?? ''),
            ),
            const SizedBox(height: 14),
            AtlasTextField(
              key: const Key('input-reset-password-confirm'),
              controller: _confirm,
              focusNode: _confirmFocus,
              label: strings.tKey(CommonKeys.fieldConfirmPassword),
              hint: strings.tKey(CommonKeys.fieldConfirmPassword),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => _confirmError(value ?? ''),
            ),
          ],
        ),
      ),
      actions: [
        AtlasButton(
          label: strings.tKey(CommonKeys.buttonCancel),
          variant: AtlasButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AtlasButton(
          label: strings.tKey(PlatformAdminKeys.resetPasswordSubmit),
          onPressed: _submit,
        ),
      ],
    );
  }
}
