import 'package:admin_app/src/admin_providers.dart';
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
              SizedBox(width: context.spacing.sm),
              AppSelectableText(
                label: l10n.pending,
                selected: _status == 'PENDING',
                onTap: () => setState(() => _status = 'PENDING'),
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
          if (workshop.pendingInvitations.isNotEmpty)
            _AccountSection(
              title: l10n.pendingInvitations,
              accounts: workshop.pendingInvitations,
              workshops: workshops,
              currentWorkshop: workshop,
              onChanged: onChanged,
              pending: true,
            ),
          SizedBox(height: context.spacing.md),
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              AppButton(
                label: l10n.invite,
                onPressed: () => _showInviteDialog(context, ref, workshop),
                icon: Icons.mail_outline,
                variant: AppButtonVariant.tonal,
              ),
              AppButton(
                label: l10n.create,
                onPressed: () => _showCreateDialog(context, ref, workshop),
                icon: Icons.person_add_alt_1_outlined,
                variant: AppButtonVariant.text,
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
    this.pending = false,
  });

  final String title;
  final List<PlatformAccount> accounts;
  final List<HierarchyWorkshop> workshops;
  final HierarchyWorkshop currentWorkshop;
  final VoidCallback onChanged;
  final bool pending;

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
            pending: pending,
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
    required this.pending,
  });

  final PlatformAccount account;
  final List<HierarchyWorkshop> workshops;
  final HierarchyWorkshop currentWorkshop;
  final VoidCallback onChanged;
  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AppListTile(
      leading: CircleAvatar(
        child: Text(account.displayName.isEmpty ? '?' : account.displayName[0]),
      ),
      title: account.displayName,
      subtitle:
          '${account.email} · ${account.role}${pending ? ' · ${l10n.pending}' : ''}',
      trailing: pending
          ? Icon(Icons.schedule, color: context.statusColors.warning.foreground)
          : PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, ref, value),
              itemBuilder: (context) => [
                if (account.status == 'ACTIVE')
                  PopupMenuItem(value: 'disable', child: Text(l10n.disable))
                else
                  PopupMenuItem(
                    value: 'reactivate',
                    child: Text(l10n.reactivate),
                  ),
                PopupMenuItem(value: 'transfer', child: Text(l10n.transfer)),
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
  controller.dispose();
  return result == null || result.isEmpty ? null : result;
}

Future<void> _showInviteDialog(
  BuildContext context,
  WidgetRef ref,
  HierarchyWorkshop workshop,
) async {
  final l10n = AppLocalizations.of(context);
  final email = TextEditingController();
  final name = TextEditingController();
  var role = 'TECHNICIAN';
  String? token;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.invite),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: email, label: l10n.email),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: name, label: l10n.displayName),
              SizedBox(height: context.spacing.sm),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(labelText: l10n.role),
                items: [
                  DropdownMenuItem(
                    value: 'TECHNICIAN',
                    child: Text(l10n.roleTechnician),
                  ),
                  DropdownMenuItem(
                    value: 'WORKSHOP_ADMIN',
                    child: Text(l10n.roleWorkshopAdmin),
                  ),
                ],
                onChanged: (value) => setState(() => role = value ?? role),
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(),
            variant: AppButtonVariant.text,
          ),
          AppButton(
            label: l10n.invite,
            onPressed: () async {
              try {
                final result = await ref
                    .read(adminApiProvider)
                    .invite(
                      email: email.text.trim(),
                      displayName: name.text.trim(),
                      role: role,
                      workshopId: workshop.id,
                    );
                token = result['invitationToken'] as String?;
                if (context.mounted) {
                  Navigator.of(context).pop();
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
    ),
  );
  email.dispose();
  name.dispose();
  if (token != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.invitationCreated),
        content: SelectableText('${l10n.invitationToken}:\n$token'),
        actions: [
          AppButton(
            label: l10n.close,
            onPressed: () => Navigator.of(context).pop(),
            variant: AppButtonVariant.text,
          ),
        ],
      ),
    );
    ref.invalidate(hierarchyProvider);
    ref.invalidate(auditProvider);
  }
}

Future<void> _showCreateDialog(
  BuildContext context,
  WidgetRef ref,
  HierarchyWorkshop workshop,
) async {
  final l10n = AppLocalizations.of(context);
  final email = TextEditingController();
  final name = TextEditingController();
  final password = TextEditingController();
  var role = 'TECHNICIAN';
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.create),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: email, label: l10n.email),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: name, label: l10n.displayName),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: password,
                label: l10n.temporaryPassword,
                obscureText: true,
              ),
              SizedBox(height: context.spacing.sm),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(labelText: l10n.role),
                items: [
                  DropdownMenuItem(
                    value: 'TECHNICIAN',
                    child: Text(l10n.roleTechnician),
                  ),
                  DropdownMenuItem(
                    value: 'WORKSHOP_ADMIN',
                    child: Text(l10n.roleWorkshopAdmin),
                  ),
                ],
                onChanged: (value) => setState(() => role = value ?? role),
              ),
            ],
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
              try {
                await ref
                    .read(adminApiProvider)
                    .createUser(
                      email: email.text.trim(),
                      displayName: name.text.trim(),
                      temporaryPassword: password.text,
                      role: role,
                      workshopId: workshop.id,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
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
    ),
  );
  email.dispose();
  name.dispose();
  password.dispose();
}
