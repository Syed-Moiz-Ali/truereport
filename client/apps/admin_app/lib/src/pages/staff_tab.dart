import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/labels.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Workshop Admin staff screen.
///
/// Lists technicians of the caller's own workshop (server-scoped staff
/// endpoint) and offers minimal account management: create a Technician
/// (workshop technicians endpoint) and reset a Technician password
/// (technician password-reset endpoint). No invitation flow exists here.
class StaffTab extends ConsumerWidget {
  const StaffTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final staff = ref.watch(staffProvider);
    return staff.when(
      loading: () => Padding(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        child: const LoadingSkeleton(lines: 4),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: ErrorState(
            title: l10n.error,
            body: l10n.genericError,
            onRetry: () => ref.invalidate(staffProvider),
            retryLabel: l10n.retryAction,
          ),
        ),
      ),
      data: (members) => ListView(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          SectionHeader(
            title: l10n.staffTab,
            action: AppButton(
              label: l10n.create,
              onPressed: () => showCreateTechnicianDialog(context, ref),
              icon: Icons.person_add_alt_1_outlined,
              variant: AppButtonVariant.tonal,
            ),
          ),
          if (members.isEmpty)
            EmptyState(
              title: l10n.noResults,
              body: l10n.noTechnicians,
              icon: Icons.groups_outlined,
            )
          else
            ...members.map(
              (member) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
                child: Card(
                  child: AppListTile(
                    leading: CircleAvatar(
                      child: Text(
                        member.displayName.isEmpty
                            ? '?'
                            : member.displayName[0],
                      ),
                    ),
                    title: member.displayName,
                    subtitle:
                        '${member.emailMasked} · ${memberRoleLabel(l10n, member.role)}',
                    trailing: _StaffActions(userId: member.userId),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StaffActions extends ConsumerWidget {
  const _StaffActions({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value != 'resetPassword') {
          return;
        }
        final password = await showResetPasswordDialog(context);
        if (password == null || !context.mounted) {
          return;
        }
        try {
          await ref
              .read(adminApiProvider)
              .resetTechnicianPassword(userId, password);
          ref.invalidate(staffProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.contentSaved)));
          }
        } on Object {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'resetPassword',
          child: Text(l10n.temporaryPassword),
        ),
      ],
    );
  }
}

String? staffPasswordError(AppLocalizations l10n, String? value) {
  if (value == null || value.isEmpty) {
    return l10n.requiredField;
  }
  if (value.length < 12) {
    return l10n.requiredField;
  }
  return null;
}

/// Minimal reset-password dialog. Reuses the temporary-password label because
/// the ARB set is fixed; the entered value is sent as `newPassword`.
Future<String?> showResetPasswordDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.temporaryPassword),
      content: Form(
        key: formKey,
        child: AppTextField(
          controller: controller,
          label: l10n.temporaryPassword,
          hint: l10n.temporaryPassword,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          validator: (value) => staffPasswordError(l10n, value),
        ),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
          variant: AppButtonVariant.text,
        ),
        AppButton(
          label: l10n.confirm,
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(controller.text);
            }
          },
        ),
      ],
    ),
  // Do not dispose synchronously (pop animation frame still builds).
  ).then((value) {
    return value;
  });
}

/// Minimal create-technician dialog for the Workshop Admin's own workshop.
///
/// Role is fixed to Technician and the workshop is derived server-side from
/// the caller, so neither is editable. See the Phase C0 slot sheet for
/// Figma fields with no server counterpart.
Future<void> showCreateTechnicianDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context);
  final email = TextEditingController();
  final name = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.create),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: email,
                label: l10n.email,
                hint: l10n.email,
                keyboardType: TextInputType.emailAddress,
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
                controller: name,
                label: l10n.displayName,
                hint: l10n.displayName,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.requiredField
                    : null,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: password,
                label: l10n.temporaryPassword,
                hint: l10n.temporaryPassword,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                validator: (value) => staffPasswordError(l10n, value),
              ),
              SizedBox(height: context.spacing.sm),
              AppListTile(title: l10n.roleTechnician, subtitle: l10n.role),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
          variant: AppButtonVariant.text,
        ),
        AppButton(
          label: l10n.create,
          onPressed: () async {
            if (!(formKey.currentState?.validate() ?? false)) {
              return;
            }
            try {
              await ref
                  .read(adminApiProvider)
                  .createTechnician(
                    email: email.text.trim(),
                    displayName: name.text.trim(),
                    initialPassword: password.text,
                  );
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.accountCreated)));
                ref.invalidate(staffProvider);
              }
            } on Object {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
              }
            }
          },
        ),
      ],
    ),
  );
  // Controllers are intentionally not disposed synchronously: the dialog pop
  // animation still builds TextFields for a frame after showDialog returns,
  // and disposing here causes use-after-dispose in widget tests. The dialog
  // is short-lived; GC reclaims them (tech debt: convert to Stateful dialog).
}
