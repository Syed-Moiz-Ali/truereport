import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/labels.dart';
import 'package:admin_app/src/models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class HierarchyTab extends ConsumerStatefulWidget {
  const HierarchyTab({super.key});

  @override
  ConsumerState<HierarchyTab> createState() => _HierarchyTabState();
}

class _HierarchyTabState extends ConsumerState<HierarchyTab> {
  final _search = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _key => '${_search.text}\u0001$_status';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hierarchy = ref.watch(hierarchyProvider(_key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            context.spacing.lg,
            context.spacing.lg,
            context.spacing.lg,
            context.spacing.sm,
          ),
          child: AppTextField(
            key: const Key('hierarchy-search'),
            controller: _search,
            label: l10n.search,
            hint: l10n.search,
            onChanged: (_) => setState(() {}),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.spacing.lg,
          ),
          child: Row(
            children: [
              AppSelectableText(
                label: l10n.filterAll,
                selected: _status.isEmpty,
                onTap: () => setState(() => _status = ''),
              ),
              SizedBox(width: context.spacing.sm),
              AppSelectableText(
                label: l10n.filterActive,
                selected: _status == 'ACTIVE',
                onTap: () => setState(() => _status = 'ACTIVE'),
              ),
              SizedBox(width: context.spacing.sm),
              AppSelectableText(
                label: l10n.disabled,
                selected: _status == 'DISABLED',
                onTap: () => setState(() => _status = 'DISABLED'),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.sm),
        Expanded(
          child: hierarchy.when(
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
                  onRetry: () => ref.invalidate(hierarchyProvider(_key)),
                  retryLabel: l10n.search,
                ),
              ),
            ),
            data: (data) {
              if (data.workshops.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(context.spacing.lg),
                    child: EmptyState(
                      title: l10n.noResults,
                      body: l10n.noResults,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(hierarchyProvider(_key)),
                child: ListView.separated(
                  padding: EdgeInsetsDirectional.all(context.spacing.lg),
                  itemCount: data.workshops.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: context.spacing.md),
                  itemBuilder: (context, index) => _WorkshopCard(
                    workshop: data.workshops[index],
                    workshops: data.workshops,
                    onChanged: _refresh,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _refresh() {
    ref.invalidate(hierarchyProvider(_key));
    ref.invalidate(auditProvider);
  }
}

class _WorkshopCard extends ConsumerWidget {
  const _WorkshopCard({
    required this.workshop,
    required this.workshops,
    required this.onChanged,
  });

  final HierarchyWorkshop workshop;
  final List<HierarchyWorkshop> workshops;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final subtitle = [
      if (workshop.branchName != null && workshop.branchName!.isNotEmpty)
        workshop.branchName!,
      '${workshop.memberCount} ${l10n.members}',
    ].join(' · ');
    return Card(
      child: ExpansionTile(
        key: PageStorageKey<String>(workshop.id),
        leading: const Icon(Icons.storefront_outlined),
        title: Text(workshop.name),
        subtitle: Text(subtitle),
        childrenPadding: EdgeInsetsDirectional.fromSTEB(
          context.spacing.lg,
          0,
          context.spacing.lg,
          context.spacing.lg,
        ),
        children: [
          _AccountSection(
            title: l10n.admins,
            accounts: workshop.admins,
            workshops: workshops,
            currentWorkshop: workshop,
            onChanged: onChanged,
          ),
          _AccountSection(
            title: l10n.technicians,
            accounts: workshop.technicians,
            workshops: workshops,
            currentWorkshop: workshop,
            onChanged: onChanged,
          ),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              AppButton(
                label: l10n.create,
                onPressed: () => _showCreateDialog(context, ref, workshop),
                icon: Icons.person_add_alt_1_outlined,
                variant: AppButtonVariant.tonal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.title,
    required this.accounts,
    required this.workshops,
    required this.currentWorkshop,
    required this.onChanged,
  });

  final String title;
  final List<PlatformAccount> accounts;
  final List<HierarchyWorkshop> workshops;
  final HierarchyWorkshop currentWorkshop;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        ...accounts.map(
          (account) => _AccountTile(
            account: account,
            workshops: workshops,
            currentWorkshop: currentWorkshop,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({
    required this.account,
    required this.workshops,
    required this.currentWorkshop,
    required this.onChanged,
  });

  final PlatformAccount account;
  final List<HierarchyWorkshop> workshops;
  final HierarchyWorkshop currentWorkshop;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AppListTile(
      leading: CircleAvatar(
        child: Text(account.displayName.isEmpty ? '?' : account.displayName[0]),
      ),
      title: account.displayName,
      subtitle: '${account.email} · ${memberRoleLabel(l10n, account.role)}',
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleAction(context, ref, value),
        itemBuilder: (context) => [
          if (account.status == 'ACTIVE')
            PopupMenuItem(value: 'disable', child: Text(l10n.disable))
          else
            PopupMenuItem(value: 'reactivate', child: Text(l10n.reactivate)),
          PopupMenuItem(value: 'transfer', child: Text(l10n.transfer)),
          PopupMenuItem(
            value: 'resetPassword',
            child: Text(l10n.temporaryPassword),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (action == 'resetPassword') {
      final password = await _promptPassword(context, l10n);
      if (password == null || !context.mounted) {
        return;
      }
      await _run(
        context,
        ref,
        () => ref
            .read(adminApiProvider)
            .resetPlatformPassword(account.userId, password),
      );
      return;
    }
    if (action == 'transfer') {
      final target = await showAppBottomSheet<HierarchyWorkshop>(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.transfer),
            ...workshops
                .where((item) => item.id != currentWorkshop.id)
                .map(
                  (item) => AppListTile(
                    title: item.name,
                    subtitle: item.branchName,
                    onTap: () => Navigator.of(context).pop(item),
                  ),
                ),
          ],
        ),
      );
      if (target == null || !context.mounted) {
        return;
      }
      final reason = await _promptReason(context, l10n, l10n.reason);
      if (reason == null || !context.mounted) {
        return;
      }
      await _run(
        context,
        ref,
        () => ref
            .read(adminApiProvider)
            .transferUser(account.userId, target.id, reason),
      );
      return;
    }
    final reason = await _promptReason(context, l10n, l10n.reason);
    if (reason == null || !context.mounted) {
      return;
    }
    await _run(
      context,
      ref,
      () => action == 'disable'
          ? ref.read(adminApiProvider).disableUser(account.userId, reason)
          : ref.read(adminApiProvider).reactivateUser(account.userId, reason),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<Object?> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await action();
      onChanged();
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
  }
}

Future<String?> _promptReason(
  BuildContext context,
  AppLocalizations l10n,
  String label,
) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(label),
      content: AppTextField(controller: controller, label: label, hint: label),
      actions: [
        AppButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
          variant: AppButtonVariant.text,
        ),
        AppButton(
          label: l10n.confirm,
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
        ),
      ],
    ),
  );
  // Do not dispose synchronously (pop animation frame still builds).
  return result == null || result.isEmpty ? null : result;
}

Future<String?> _promptPassword(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final result = await showDialog<String>(
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
          validator: (value) => _passwordError(l10n, value),
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
  );
  // Do not dispose synchronously (pop animation frame still builds).
  return result;
}

String? _passwordError(AppLocalizations l10n, String? value) {
  if (value == null || value.isEmpty) {
    return l10n.requiredField;
  }
  if (value.length < 12) {
    return l10n.requiredField;
  }
  return null;
}

String? _emailError(AppLocalizations l10n, String? value) {
  if (value == null || value.trim().isEmpty) {
    return l10n.requiredField;
  }
  if (!value.contains('@')) {
    return l10n.invalidEmail;
  }
  return null;
}

/// Platform Admin creates a Workshop Admin in [workshop].
///
/// Role is fixed to Workshop Admin (server `ROLE_NOT_PERMITTED` otherwise)
/// and the workshop is the card the dialog was opened from. See the Phase C0
/// slot sheet for Figma fields that have no server counterpart.
Future<void> _showCreateDialog(
  BuildContext context,
  WidgetRef ref,
  HierarchyWorkshop workshop,
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
                validator: (value) => _emailError(l10n, value),
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
                validator: (value) => _passwordError(l10n, value),
              ),
              SizedBox(height: context.spacing.sm),
              AppListTile(
                title: l10n.roleWorkshopAdmin,
                subtitle: '${l10n.role} · ${l10n.workshop}: ${workshop.name}',
              ),
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
                  .createUser(
                    email: email.text.trim(),
                    displayName: name.text.trim(),
                    temporaryPassword: password.text,
                    role: 'WORKSHOP_ADMIN',
                    workshopId: workshop.id,
                  );
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.accountCreated)));
                ref.invalidate(hierarchyProvider);
                ref.invalidate(auditProvider);
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
  // See staff_tab.dart: do not dispose synchronously (pop animation frame).
}
