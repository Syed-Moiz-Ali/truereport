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
import 'workshop_status.dart';

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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _statusFilter = '';
    });
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
    final hasActiveFilter = query.isNotEmpty || _statusFilter.isNotEmpty;
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
                  DropdownMenuItem(
                    value: status,
                    child: Text(workshopStatusLabel(strings, status)),
                  ),
              ],
              onChanged: (value) => setState(() => _statusFilter = value ?? ''),
            ),
          ],
          countLabel: strings.tArgsKey(
            PlatformAdminKeys.pageWorkshopsResultCount,
            {'count': filtered.length},
          ),
          trailing: hasActiveFilter
              ? TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: Text(
                    strings.tKey(PlatformAdminKeys.buttonClearFilters),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: PtTheme.muted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          PlatformEmptyView(
            icon: Icons.business_outlined,
            title: workshops.isEmpty
                ? strings.tKey(PlatformAdminKeys.emptyWorkshopsTitle)
                : strings.tKey(PlatformAdminKeys.emptyWorkshopsFilteredTitle),
            body: workshops.isEmpty
                ? strings.tKey(PlatformAdminKeys.emptyWorkshopsBody)
                : strings.tKey(PlatformAdminKeys.emptyWorkshopsFilteredBody),
            actionLabel: workshops.isEmpty
                ? strings.tKey(PlatformAdminKeys.pageWorkshopsAdd)
                : strings.tKey(PlatformAdminKeys.buttonClearFilters),
            onAction: workshops.isEmpty
                ? () => context.go('/workshops/new')
                : _clearFilters,
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
              const spacing = 16.0;
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
                    PlatformStatusChip(
                      status: workshop.status,
                      label: workshopStatusLabel(strings, workshop.status),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Bays / capacity with progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${workshop.bayCount} ${strings.tKey(PlatformAdminKeys.fieldWorkshopBays)}',
                          style: PtTheme.font(
                            12,
                            lineHeight: 16,
                            weight: FontWeight.w600,
                            color: PtTheme.ink,
                          ),
                        ),
                        Text(
                          '${workshop.assignedCapacityPercent}%',
                          style: PtTheme.font(
                            12,
                            lineHeight: 16,
                            weight: FontWeight.w700,
                            color: workshop.assignedCapacityPercent >= 90
                                ? PtTheme.amber
                                : PtTheme.deepGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (workshop.assignedCapacityPercent / 100.0).clamp(
                          0.0,
                          1.0,
                        ),
                        minHeight: 6,
                        backgroundColor: PtTheme.canvas,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          workshop.assignedCapacityPercent >= 90
                              ? PtTheme.amber
                              : PtTheme.deepGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 4 metrics: Staff, Technicians, Admins, Pending
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlatformPrimaryButton(
                          label: strings.tKey(
                            PlatformAdminKeys.buttonViewDetails,
                          ),
                          icon: Icons.visibility_outlined,
                          onPressed: () => onOpen(workshop),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: strings.tKey(
                            PlatformAdminKeys.pageWorkshopsEdit,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: PtTheme.muted,
                          onPressed: () => onEdit(workshop),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        PopupMenuButton<String>(
                          tooltip: strings.tKey(CommonKeys.tableActions),
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: PtTheme.muted,
                          ),
                          onSelected: (action) {
                            if (action == 'edit') {
                              onEdit(workshop);
                            } else if (action == 'toggleStatus') {
                              onToggleStatus(workshop);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: PtTheme.ink,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    strings.tKey(CommonKeys.buttonEdit),
                                    style: PtTheme.font(
                                      13,
                                      color: PtTheme.ink,
                                      weight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggleStatus',
                              child: Row(
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.block_outlined
                                        : Icons.check_circle_outlined,
                                    size: 18,
                                    color: isActive
                                        ? PtTheme.rose
                                        : PtTheme.deepGreen,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isActive
                                        ? strings.tKey(
                                            PlatformAdminKeys
                                                .buttonWorkshopDeactivate,
                                          )
                                        : strings.tKey(
                                            PlatformAdminKeys
                                                .buttonWorkshopReactivate,
                                          ),
                                    style: PtTheme.font(
                                      13,
                                      color: isActive
                                          ? PtTheme.rose
                                          : PtTheme.deepGreen,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
