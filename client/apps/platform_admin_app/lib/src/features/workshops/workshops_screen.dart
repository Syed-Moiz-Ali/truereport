import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../components/platform_toolbar.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'workshop_form.dart';

import 'package:l10n/l10n.dart';

class WorkshopsScreen extends ConsumerStatefulWidget {
  const WorkshopsScreen({super.key});

  @override
  ConsumerState<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends ConsumerState<WorkshopsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final hierarchy = ref.watch(hierarchyStateProvider);
    return PlatformShell(
      currentRoute: '/workshops',
      onNavigate: (route) => context.go(route),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: strings.tKey(PlatformAdminKeys.navWorkshops),
              subtitle: strings.tKey(PlatformAdminKeys.pageWorkshopsSubtitle),
              actions: [
                PlatformPrimaryButton(
                  label: strings.tKey(PlatformAdminKeys.pageWorkshopsAdd),
                  icon: Icons.add_rounded,
                  onPressed: () => context.go('/workshops/new'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            hierarchy.when(
              loading: () => const PlatformLoadingView(),
              error: (_, _) => PlatformErrorView(
                message: strings.tKey(CommonKeys.stateError),
                onRetry: () => ref.invalidate(hierarchyStateProvider),
              ),
              data: (response) => _buildData(context, response),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildData(BuildContext context, HierarchyResponse response) {
    final strings = ref.watch(uiStringsProvider);
    final workshops = response.workshops;
    final statuses = <String>{
      for (final workshop in workshops) workshop.status.toUpperCase(),
    }.toList()..sort();
    final query = _query.trim().toLowerCase();
    final filtered = workshops
        .where((workshop) {
          if (_statusFilter.isNotEmpty &&
              workshop.status.toUpperCase() != _statusFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          return workshop.name.toLowerCase().contains(query) ||
              (workshop.branchName ?? '').toLowerCase().contains(query) ||
              workshop.status.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformToolbar(
          searchController: _searchController,
          searchHint: strings.tKey(PlatformAdminKeys.filterWorkshopsSearch),
          onSearchChanged: (value) => setState(() => _query = value),
          filters: [
            PlatformDropdown<String>(
              label: strings.tKey(CommonKeys.tableStatus),
              value: _statusFilter,
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(strings.tKey(CommonKeys.filterAll)),
                ),
                for (final status in statuses)
                  DropdownMenuItem(value: status, child: Text(status)),
              ],
              onChanged: (value) => setState(() => _statusFilter = value ?? ''),
            ),
          ],
          countLabel: strings.tArgsKey(
            PlatformAdminKeys.pageWorkshopsResultCount,
            {'count': filtered.length},
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          PlatformEmptyView(
            icon: Icons.business_outlined,
            title: workshops.isEmpty
                ? strings.tKey(PlatformAdminKeys.emptyWorkshopsTitle)
                : strings.tKey(CommonKeys.emptyTitle),
            body: workshops.isEmpty
                ? strings.tKey(PlatformAdminKeys.emptyWorkshopsBody)
                : null,
            actionLabel: workshops.isEmpty
                ? strings.tKey(PlatformAdminKeys.pageWorkshopsAdd)
                : null,
            onAction: workshops.isEmpty
                ? () => context.go('/workshops/new')
                : null,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = maxWidth >= 1024
                  ? 3
                  : maxWidth >= 700
                  ? 2
                  : 1;
              const spacing = 14.0;
              final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final workshop in filtered)
                    SizedBox(
                      width: cardWidth,
                      child: _WorkshopCard(
                        workshop: workshop,
                        onOpen: _openDetail,
                        onEdit: _editWorkshop,
                        onToggleStatus: _toggleStatus,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  void _openDetail(HierarchyWorkshop workshop) {
    context.go('/workshops/${workshop.id}');
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

class _WorkshopCard extends ConsumerWidget {
  const _WorkshopCard({
    required this.workshop,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final HierarchyWorkshop workshop;
  final ValueChanged<HierarchyWorkshop> onOpen;
  final ValueChanged<HierarchyWorkshop> onEdit;
  final ValueChanged<HierarchyWorkshop> onToggleStatus;

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
    final email = (workshop.contactEmail ?? '').trim();
    return Semantics(
      button: true,
      label: workshop.name,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onOpen(workshop),
          child: PlatformSectionCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: PtTheme.deepGreen.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(14),
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
                            16,
                            lineHeight: 22,
                            weight: FontWeight.w800,
                            color: PtTheme.deepGreen,
                          ),
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
                            workshop.name,
                            style: PtTheme.font(
                              16,
                              lineHeight: 22,
                              weight: FontWeight.w800,
                              color: PtTheme.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (workshop.branchName ?? '').isEmpty
                                ? '—'
                                : workshop.branchName!,
                            style: PtTheme.bodyMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PlatformStatusChip(status: workshop.status),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PlatformMetaPill(
                      label: strings.tKey(PlatformAdminKeys.tabWorkshopStaff),
                      value: '${workshop.memberCount}',
                    ),
                    PlatformMetaPill(
                      label: strings.tKey(
                        PlatformAdminKeys.sectionWorkshopTechnicians,
                      ),
                      value: '${workshop.technicians.length}',
                    ),
                    PlatformMetaPill(
                      label: strings.tKey(
                        PlatformAdminKeys.sectionWorkshopAdmins,
                      ),
                      value: '${workshop.admins.length}',
                    ),
                    PlatformMetaPill(
                      label: strings.tKey(
                        PlatformAdminKeys.sectionWorkshopPendingInvitations,
                      ),
                      value: '${workshop.pendingInvitations.length}',
                    ),
                    PlatformMetaPill(
                      label: strings.tKey(
                        PlatformAdminKeys.fieldWorkshopCapacity,
                      ),
                      value:
                          '${workshop.bayCount} • ${workshop.assignedCapacityPercent}%',
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        size: 15,
                        color: PtTheme.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          style: PtTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      tooltip: strings.tKey(CommonKeys.labelDetails),
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      color: PtTheme.muted,
                      onPressed: () => onOpen(workshop),
                    ),
                    IconButton(
                      tooltip: strings.tKey(
                        PlatformAdminKeys.pageWorkshopsEdit,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: PtTheme.muted,
                      onPressed: () => onEdit(workshop),
                    ),
                    IconButton(
                      tooltip: isActive
                          ? strings.tKey(
                              PlatformAdminKeys.buttonWorkshopDeactivate,
                            )
                          : strings.tKey(
                              PlatformAdminKeys.buttonWorkshopReactivate,
                            ),
                      icon: Icon(
                        isActive
                            ? Icons.block_outlined
                            : Icons.check_circle_outlined,
                        size: 20,
                      ),
                      color: isActive ? PtTheme.rose : PtTheme.deepGreen,
                      onPressed: () => onToggleStatus(workshop),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: strings.tKey(CommonKeys.labelDetails),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      color: PtTheme.deepGreen,
                      onPressed: () => onOpen(workshop),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
