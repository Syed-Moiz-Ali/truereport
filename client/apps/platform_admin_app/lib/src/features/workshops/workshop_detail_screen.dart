import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_catalogue_models.dart';
import '../../platform_config_models.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'workshop_form.dart';

import 'package:l10n/l10n.dart';

class WorkshopDetailScreen extends ConsumerStatefulWidget {
  const WorkshopDetailScreen({super.key, required this.workshopId});

  final String workshopId;

  @override
  ConsumerState<WorkshopDetailScreen> createState() =>
      _WorkshopDetailScreenState();
}

class _WorkshopDetailScreenState extends ConsumerState<WorkshopDetailScreen> {
  late Future<HierarchyWorkshop> _future;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = ref.read(platformApiProvider).workshopDetail(widget.workshopId);
  }

  @override
  void didUpdateWidget(covariant WorkshopDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workshopId != widget.workshopId) {
      _refresh();
    }
  }

  void _refresh() {
    setState(() {
      _future = ref.read(platformApiProvider).workshopDetail(widget.workshopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformShell(
      currentRoute: '/workshops',
      onNavigate: (route) => context.go(route),
      child: PlatformPage(
        child: FutureBuilder<HierarchyWorkshop>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const PlatformLoadingView();
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return PlatformErrorView(
                message: strings.tKey(CommonKeys.stateError),
                onRetry: _refresh,
              );
            }
            return _buildDetail(context, snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, HierarchyWorkshop workshop) {
    final strings = ref.watch(uiStringsProvider);
    final tabs = [
      strings.tKey(PlatformAdminKeys.tabWorkshopOverview),
      strings.tKey(PlatformAdminKeys.tabWorkshopStaff),
      strings.tKey(PlatformAdminKeys.tabWorkshopTemplates),
      strings.tKey(PlatformAdminKeys.tabWorkshopActivity),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(
          workshop: workshop,
          tabs: tabs,
          selectedTab: _tab,
          onTabSelected: (index) => setState(() => _tab = index),
          onEdit: () => _editWorkshop(workshop),
          onToggleStatus: () => _toggleStatus(workshop),
        ),
        const SizedBox(height: 16),
        _SummaryStrip(workshop: workshop),
        const SizedBox(height: 16),
        switch (_tab) {
          0 => _OverviewTab(workshop: workshop),
          1 => _StaffTab(workshop: workshop, onChanged: _refresh),
          2 => const _TemplatesTab(),
          _ => _ActivityTab(workshopId: workshop.id),
        },
      ],
    );
  }

  void _editWorkshop(HierarchyWorkshop workshop) {
    final strings = ref.watch(uiStringsProvider);
    showPlatformDialog<void>(
      context: context,
      title: strings.tKey(PlatformAdminKeys.pageWorkshopsEdit),
      body: WorkshopForm(
        workshop: workshop,
        onSaved: (_) {
          Navigator.of(context).pop();
          _refresh();
          ref.invalidate(hierarchyStateProvider);
        },
      ),
    );
  }

  Future<void> _toggleStatus(HierarchyWorkshop workshop) async {
    final strings = ref.watch(uiStringsProvider);
    final isActive = workshop.status.toUpperCase() == 'ACTIVE';
    final reason = await showReasonDialog(
      context: context,
      title: isActive
          ? strings.tKey(PlatformAdminKeys.buttonWorkshopDeactivate)
          : strings.tKey(PlatformAdminKeys.buttonWorkshopReactivate),
      body: isActive
          ? strings.tKey(PlatformAdminKeys.dialogWorkshopDeactivateConfirm)
          : null,
      confirmLabel: isActive
          ? strings.tKey(PlatformAdminKeys.buttonWorkshopDeactivate)
          : strings.tKey(PlatformAdminKeys.buttonWorkshopReactivate),
      destructive: isActive,
    );
    if (reason == null || !mounted) return;
    try {
      final api = ref.read(platformApiProvider);
      if (isActive) {
        await api.deactivateWorkshop(workshop.id, reason);
      } else {
        await api.reactivateWorkshop(workshop.id, reason);
      }
      ref.invalidate(hierarchyStateProvider);
      _refresh();
    } catch (_) {
      if (!mounted) return;
      await showPlatformDialog<void>(
        context: context,
        title: strings.tKey(CommonKeys.stateError),
        body: Text(strings.tKey(CommonKeys.stateError)),
        actionsBuilder: (dialogContext) => [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.tKey(CommonKeys.buttonClose)),
          ),
        ],
      );
    }
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({
    required this.workshop,
    required this.tabs,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final HierarchyWorkshop workshop;
  final List<String> tabs;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return parts.isEmpty ? '—' : parts;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final isActive = workshop.status.toUpperCase() == 'ACTIVE';
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;
              final titleBlock = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: PtTheme.deepGreen.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PtTheme.deepGreen.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials(workshop.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PtTheme.font(
                          19,
                          lineHeight: 24,
                          weight: FontWeight.w800,
                          color: PtTheme.deepGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                workshop.name,
                                style: PtTheme.pageTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            PlatformStatusChip(status: workshop.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (workshop.branchName ?? '').isEmpty
                              ? '—'
                              : workshop.branchName!,
                          style: PtTheme.bodyMuted,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );
              final actions = Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: compact ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  PlatformSecondaryButton(
                    label: strings.tKey(PlatformAdminKeys.pageWorkshopsEdit),
                    icon: Icons.edit_outlined,
                    onPressed: onEdit,
                  ),
                  if (isActive)
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonWorkshopDeactivate,
                      ),
                      icon: Icons.block_outlined,
                      destructive: true,
                      onPressed: onToggleStatus,
                    )
                  else
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonWorkshopReactivate,
                      ),
                      icon: Icons.check_circle_outlined,
                      onPressed: onToggleStatus,
                    ),
                ],
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [titleBlock, const SizedBox(height: 14), actions],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 20),
                  Flexible(child: actions),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < tabs.length; i++)
                PlatformFilterChip(
                  label: tabs[i],
                  selected: selectedTab == i,
                  onTap: () => onTabSelected(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends ConsumerWidget {
  const _SummaryStrip({required this.workshop});

  final HierarchyWorkshop workshop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final stats = <_SummaryStat>[
      _SummaryStat(
        label: strings.tKey(PlatformAdminKeys.tabWorkshopStaff),
        value: '${workshop.memberCount}',
        icon: Icons.groups_rounded,
        accent: PtTheme.deepGreen,
        tint: PtTheme.emerald,
      ),
      _SummaryStat(
        label: strings.tKey(PlatformAdminKeys.sectionWorkshopTechnicians),
        value: '${workshop.technicians.length}',
        icon: Icons.engineering_rounded,
        accent: const Color(0xFF1D4ED8),
        tint: const Color(0xFF3B82F6),
      ),
      _SummaryStat(
        label: strings.tKey(PlatformAdminKeys.sectionWorkshopAdmins),
        value: '${workshop.admins.length}',
        icon: Icons.manage_accounts_rounded,
        accent: PtTheme.gold,
        tint: PtTheme.amber,
      ),
      _SummaryStat(
        label: strings.tKey(
          PlatformAdminKeys.sectionWorkshopPendingInvitations,
        ),
        value: '${workshop.pendingInvitations.length}',
        icon: Icons.mail_outline_rounded,
        accent: PtTheme.gold,
        tint: PtTheme.amber,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in stats)
              SizedBox(
                width: cardWidth,
                child: PlatformSectionCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: stat.tint.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: stat.tint.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Icon(stat.icon, size: 20, color: stat.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              stat.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PtTheme.font(
                                18,
                                lineHeight: 24,
                                weight: FontWeight.w800,
                                color: PtTheme.ink,
                              ),
                            ),
                            Text(
                              stat.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PtTheme.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

@immutable
class _SummaryStat {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color tint;
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.workshop});

  final HierarchyWorkshop workshop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final email = (workshop.contactEmail ?? '').trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final cards = [
          _InfoCard(
            icon: Icons.business_rounded,
            title: strings.tKey(PlatformAdminKeys.tabWorkshopOverview),
            rows: [
              _InfoRow(
                label: strings.tKey(PlatformAdminKeys.fieldWorkshopName),
                value: workshop.name,
              ),
              _InfoRow(
                label: strings.tKey(PlatformAdminKeys.fieldWorkshopBranch),
                value: (workshop.branchName ?? '').isEmpty
                    ? '—'
                    : workshop.branchName!,
              ),
              _InfoRow(
                label: strings.tKey(CommonKeys.tableStatus),
                value: workshop.status,
              ),
            ],
          ),
          _InfoCard(
            icon: Icons.groups_rounded,
            title: strings.tKey(PlatformAdminKeys.fieldWorkshopCapacity),
            rows: [
              _InfoRow(
                label: strings.tKey(PlatformAdminKeys.tabWorkshopStaff),
                value: '${workshop.memberCount}',
              ),
              _InfoRow(
                label: strings.tKey(PlatformAdminKeys.sectionWorkshopAdmins),
                value: '${workshop.admins.length}',
              ),
              _InfoRow(
                label: strings.tKey(
                  PlatformAdminKeys.sectionWorkshopTechnicians,
                ),
                value: '${workshop.technicians.length}',
              ),
            ],
          ),
          _InfoCard(
            icon: Icons.mail_outline_rounded,
            title: strings.tKey(PlatformAdminKeys.sectionWorkshopContact),
            rows: [
              _InfoRow(
                label: strings.tKey(
                  PlatformAdminKeys.fieldWorkshopContactEmail,
                ),
                value: email.isNotEmpty
                    ? email
                    : strings.tKey(CommonKeys.emptyTitle),
              ),
              _InfoRow(
                label: strings.tKey(PlatformAdminKeys.fieldWorkshopCreatedOn),
                value: '—',
              ),
            ],
          ),
        ];
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 16),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final card in cards) ...[card, const SizedBox(height: 12)],
          ],
        );
      },
    );
  }
}

class _InfoCard extends ConsumerWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: PtTheme.deepGreen.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: PtTheme.deepGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: PtTheme.sectionTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    row.label,
                    style: PtTheme.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    row.value,
                    style: PtTheme.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;
}

class _StaffTab extends ConsumerWidget {
  const _StaffTab({required this.workshop, required this.onChanged});

  final HierarchyWorkshop workshop;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PtTheme.deepGreen.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 20,
                  color: PtTheme.deepGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.tKey(PlatformAdminKeys.tabWorkshopStaff),
                      style: PtTheme.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${workshop.memberCount}',
                      style: PtTheme.bodyMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PlatformSecondaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonWorkshopAddStaff),
                icon: Icons.person_add_alt_1_outlined,
                onPressed: () => _addStaff(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StaffGroup(
          title: strings.tKey(PlatformAdminKeys.sectionWorkshopAdmins),
          accounts: workshop.admins,
          workshopId: workshop.id,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        _StaffGroup(
          title: strings.tKey(PlatformAdminKeys.sectionWorkshopTechnicians),
          accounts: workshop.technicians,
          workshopId: workshop.id,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _addStaff(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    showPlatformDialog<void>(
      context: context,
      title: strings.tKey(PlatformAdminKeys.buttonWorkshopAddStaff),
      body: _AddStaffForm(
        workshopId: workshop.id,
        onSaved: () {
          Navigator.of(context).pop();
          onChanged();
          ref.invalidate(hierarchyStateProvider);
        },
      ),
    );
  }
}

class _StaffGroup extends ConsumerWidget {
  const _StaffGroup({
    required this.title,
    required this.accounts,
    required this.workshopId,
    required this.onChanged,
  });

  final String title;
  final List<PlatformAccount> accounts;
  final String workshopId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title (${accounts.length})',
                  style: PtTheme.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (accounts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PtTheme.border),
              ),
              child: Text(
                strings.tKey(CommonKeys.emptyTitle),
                textAlign: TextAlign.center,
                style: PtTheme.bodyMuted,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 700;
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final account in accounts) ...[
                        _StaffTile(
                          account: account,
                          onToggleStatus: () =>
                              _toggleStaffStatus(context, ref, account),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                }
                const spacing = 10.0;
                final tileWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: 8,
                  children: [
                    for (final account in accounts)
                      SizedBox(
                        width: tileWidth,
                        child: _StaffTile(
                          account: account,
                          onToggleStatus: () =>
                              _toggleStaffStatus(context, ref, account),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _toggleStaffStatus(
    BuildContext context,
    WidgetRef ref,
    PlatformAccount account,
  ) async {
    final strings = ref.watch(uiStringsProvider);
    final isActive = account.status.toUpperCase() == 'ACTIVE';
    final reason = await showReasonDialog(
      context: context,
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
      await showPlatformDialog<void>(
        context: context,
        title: strings.tKey(CommonKeys.stateError),
        body: Text(strings.tKey(CommonKeys.stateError)),
        actionsBuilder: (dialogContext) => [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.tKey(CommonKeys.buttonClose)),
          ),
        ],
      );
    }
  }
}

class _StaffTile extends ConsumerWidget {
  const _StaffTile({required this.account, required this.onToggleStatus});

  final PlatformAccount account;
  final VoidCallback onToggleStatus;

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return parts.isEmpty ? '—' : parts;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final isActive = account.status.toUpperCase() == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PtTheme.deepGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _initials(account.displayName),
                style: PtTheme.font(
                  14,
                  lineHeight: 18,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  account.email.isNotEmpty
                      ? account.email
                      : strings.tKey(CommonKeys.emptyTitle),
                  style: PtTheme.bodyMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PlatformMetaPill(
                      label: strings.tKey(CommonKeys.tableRole),
                      value: account.role,
                    ),
                    PlatformStatusChip(status: account.status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: isActive
                ? strings.tKey(CommonKeys.buttonDisable)
                : strings.tKey(CommonKeys.buttonReactivate),
            icon: Icon(
              isActive
                  ? Icons.person_off_outlined
                  : Icons.person_add_alt_1_outlined,
              size: 20,
            ),
            color: isActive ? PtTheme.rose : PtTheme.deepGreen,
            onPressed: onToggleStatus,
          ),
        ],
      ),
    );
  }
}

class _AddStaffForm extends ConsumerStatefulWidget {
  const _AddStaffForm({required this.workshopId, required this.onSaved});

  final String workshopId;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AddStaffForm> createState() => _AddStaffFormState();
}

class _AddStaffFormState extends ConsumerState<_AddStaffForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'WORKSHOP_ADMIN';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.watch(uiStringsProvider);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(platformApiProvider)
          .createUser(
            email: _emailController.text.trim(),
            displayName: _nameController.text.trim(),
            temporaryPassword: _passwordController.text.trim(),
            role: _role,
            workshopId: widget.workshopId,
          );
      if (!mounted) return;
      widget.onSaved();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = strings.tKey(CommonKeys.stateError));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
            const SizedBox(height: 12),
          ],
          PlatformTextField(
            key: const Key('input-staff-name'),
            controller: _nameController,
            label: strings.tKey(CommonKeys.fieldDisplayName),
            hint: strings.tKey(CommonKeys.fieldDisplayName),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? strings.tKey(CommonKeys.stateError)
                : null,
          ),
          const SizedBox(height: 14),
          PlatformTextField(
            key: const Key('input-staff-email'),
            controller: _emailController,
            label: strings.tKey(CommonKeys.fieldEmail),
            hint: strings.tKey(CommonKeys.fieldEmail),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty || !text.contains('@')) {
                return strings.tKey(CommonKeys.stateError);
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          PlatformTextField(
            key: const Key('input-staff-password'),
            controller: _passwordController,
            label: strings.tKey(CommonKeys.fieldTemporaryPassword),
            hint: strings.tKey(CommonKeys.fieldTemporaryPassword),
            validator: (value) {
              if ((value?.trim() ?? '').length < 6) {
                return strings.tKey(CommonKeys.stateError);
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          PlatformDropdown<String>(
            label: strings.tKey(CommonKeys.tableRole),
            value: _role,
            items: [
              DropdownMenuItem(
                value: 'WORKSHOP_ADMIN',
                child: Text(strings.tKey(CommonKeys.roleWorkshopAdmin)),
              ),
              DropdownMenuItem(
                value: 'TECHNICIAN',
                child: Text(strings.tKey(CommonKeys.roleTechnician)),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _role = value);
              }
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformSecondaryButton(
                label: strings.tKey(CommonKeys.buttonCancel),
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              PlatformPrimaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonWorkshopAddStaff),
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final templates = ref.watch(templatesProvider);
    return templates.when(
      loading: () => const PlatformLoadingView(),
      error: (_, _) => PlatformErrorView(
        message: strings.tKey(CommonKeys.stateError),
        onRetry: () => ref.invalidate(templatesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return PlatformEmptyView(
            icon: Icons.description_outlined,
            title: strings.tKey(CommonKeys.emptyTitle),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 2 : 1;
            const spacing = 12.0;
            final cardWidth = constraints.maxWidth <= 0
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in items)
                  SizedBox(
                    width: columns == 1 ? double.infinity : cardWidth,
                    child: _TemplateCard(template: item),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template});

  final GlobalTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final title = template.nameEn.isNotEmpty ? template.nameEn : template.code;
    final categoryCount = template.categories.length;
    var itemCount = 0;
    for (final category in template.categories) {
      itemCount += category.items.isNotEmpty
          ? category.items.length
          : (category.includedCount > 0
                ? category.includedCount
                : category.itemCount);
    }
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/checklist/templates/${template.id}'),
          borderRadius: BorderRadius.circular(14),
          child: PlatformSectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: PtTheme.deepGreen.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 21,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: PtTheme.font(
                              15,
                              lineHeight: 21,
                              weight: FontWeight.w800,
                              color: PtTheme.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            template.code,
                            style: PtTheme.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PlatformStatusChip(status: template.status),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PlatformMetaPill(
                      label: strings.tKey(CommonKeys.labelCategories),
                      value: '$categoryCount',
                    ),
                    PlatformMetaPill(
                      label: strings.tKey(CommonKeys.labelItems),
                      value: '$itemCount',
                    ),
                  ],
                ),
                if (template.descriptionEn.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.descriptionEn,
                          style: PtTheme.bodyMuted,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: PtTheme.muted,
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: PtTheme.muted,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab({required this.workshopId});

  final String workshopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final events = ref.watch(auditEventsProvider);
    return events.when(
      loading: () => const PlatformLoadingView(),
      error: (_, _) => PlatformErrorView(
        message: strings.tKey(CommonKeys.stateError),
        onRetry: () => ref.invalidate(auditEventsProvider),
      ),
      data: (all) {
        final filtered = all
            .where(
              (event) =>
                  event.entityId == workshopId ||
                  event.metadataJson.contains(workshopId),
            )
            .toList(growable: false);
        if (filtered.isEmpty) {
          return PlatformEmptyView(
            icon: Icons.history_toggle_off_rounded,
            title: strings.tKey(CommonKeys.emptyTitle),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final event in filtered) ...[
              _AuditTile(event: event),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _AuditTile extends ConsumerWidget {
  const _AuditTile({required this.event});

  final PlatformAuditEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PtTheme.border),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 18,
              color: PtTheme.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.action,
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.occurredAt.isNotEmpty
                      ? event.occurredAt
                      : strings.tKey(CommonKeys.emptyTitle),
                  style: PtTheme.bodyMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    PlatformMetaPill(
                      label: strings.tKey(CommonKeys.tableRole),
                      value: event.actorRole.isNotEmpty ? event.actorRole : '—',
                    ),
                    PlatformMetaPill(
                      label: strings.tKey(CommonKeys.fieldReason),
                      value: event.reasonCode.isNotEmpty
                          ? event.reasonCode
                          : '—',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
