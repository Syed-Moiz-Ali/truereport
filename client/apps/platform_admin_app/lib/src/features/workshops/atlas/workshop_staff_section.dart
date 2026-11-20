import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_models.dart';
import '../../../platform_providers.dart';
import '../../../platform_theme.dart';
import '../workshop_form.dart';
import '../workshop_status.dart';
import 'atlas_ui.dart';
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
    this.pending = false,
  });

  final UiMessageStrings strings;
  final String title;
  final List<PlatformAccount> accounts;
  final String emptyTitle;
  final String emptyBody;
  final ValueChanged<PlatformAccount> onToggle;
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
  });

  final UiMessageStrings strings;
  final PlatformAccount account;
  final bool pending;
  final VoidCallback onToggle;

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
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String _role = 'WORKSHOP_ADMIN';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      if ((_name.text.trim()).isEmpty) {
        _nameFocus.requestFocus();
      } else if (_emailError(_email.text) != null) {
        _emailFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
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
            temporaryPassword: _password.text.trim(),
            role: _role,
            workshopId: widget.workshopId,
          );
      if (!mounted) return;
      widget.onSaved();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = widget.strings.tKey(CommonKeys.stateError));
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
              helperText: strings.tKey(
                PlatformAdminKeys.addStaffHelperTemporaryPassword,
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) {
                  return strings.tKey(CommonKeys.validationRequiredField);
                }
                if (text.length < 6) {
                  return strings.tKey(
                    PlatformAdminKeys.validationPasswordMinLength,
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              strings.tKey(CommonKeys.tableRole),
              style: Atlas.text(12, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RoleOption(
                    label: strings.tKey(CommonKeys.roleWorkshopAdmin),
                    selected: _role == 'WORKSHOP_ADMIN',
                    onTap: () => setState(() => _role = 'WORKSHOP_ADMIN'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RoleOption(
                    label: strings.tKey(CommonKeys.roleTechnician),
                    selected: _role == 'TECHNICIAN',
                    onTap: () => setState(() => _role = 'TECHNICIAN'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              strings.tKey(
                _role == 'WORKSHOP_ADMIN'
                    ? PlatformAdminKeys.addStaffRoleAdminDescription
                    : PlatformAdminKeys.addStaffRoleTechnicianDescription,
              ),
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

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? Atlas.accentTint : PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? PtTheme.deepGreen : PtTheme.border,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Atlas.text(
                12,
                weight: FontWeight.w700,
                color: selected ? PtTheme.deepGreen : PtTheme.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
