import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

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
    final l10n = AppLocalizations.of(context);
    final hierarchy = ref.watch(hierarchyStateProvider);
    return PlatformShell(
      currentRoute: '/workshops',
      onNavigate: (route) => context.go(route),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: l10n.workshops,
              subtitle: l10n.wsSubtitle,
              actions: [
                PlatformPrimaryButton(
                  label: l10n.wsAdd,
                  icon: Icons.add_rounded,
                  onPressed: () => context.go('/workshops/new'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            hierarchy.when(
              loading: () => const PlatformLoadingView(),
              error: (_, _) => PlatformErrorView(
                message: l10n.error,
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
    final l10n = AppLocalizations.of(context);
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
          searchHint: l10n.wsSearchHint,
          onSearchChanged: (value) => setState(() => _query = value),
          filters: [
            PlatformDropdown<String>(
              label: l10n.status,
              value: _statusFilter,
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.filterAll)),
                for (final status in statuses)
                  DropdownMenuItem(value: status, child: Text(status)),
              ],
              onChanged: (value) => setState(() => _statusFilter = value ?? ''),
            ),
          ],
          countLabel: l10n.wsResultCount(filtered.length),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          PlatformEmptyView(
            icon: Icons.business_outlined,
            title: workshops.isEmpty ? l10n.wsEmpty : l10n.noData,
            body: workshops.isEmpty ? l10n.wsEmptyBody : null,
            actionLabel: workshops.isEmpty ? l10n.wsAdd : null,
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
    final l10n = AppLocalizations.of(context);
    showPlatformDialog<void>(
      context: context,
      title: l10n.wsEdit,
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
    final l10n = AppLocalizations.of(context);
    final isActive = workshop.status.toUpperCase() == 'ACTIVE';
    final reason = await showReasonDialog(
      context: context,
      title: isActive ? l10n.wsDeactivate : l10n.wsReactivate,
      body: isActive ? l10n.wsDeactivateConfirm : null,
      confirmLabel: isActive ? l10n.wsDeactivate : l10n.wsReactivate,
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
        title: l10n.error,
        body: Text(l10n.error),
        actionsBuilder: (dialogContext) => [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      );
    }
  }
}

class _WorkshopCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                      label: l10n.wsStaff,
                      value: '${workshop.memberCount}',
                    ),
                    PlatformMetaPill(
                      label: l10n.technicians,
                      value: '${workshop.technicians.length}',
                    ),
                    PlatformMetaPill(
                      label: l10n.admins,
                      value: '${workshop.admins.length}',
                    ),
                    PlatformMetaPill(
                      label: l10n.pendingInvitations,
                      value: '${workshop.pendingInvitations.length}',
                    ),
                    PlatformMetaPill(
                      label: l10n.wsCapacity,
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
                      tooltip: l10n.details,
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      color: PtTheme.muted,
                      onPressed: () => onOpen(workshop),
                    ),
                    IconButton(
                      tooltip: l10n.wsEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: PtTheme.muted,
                      onPressed: () => onEdit(workshop),
                    ),
                    IconButton(
                      tooltip: isActive ? l10n.wsDeactivate : l10n.wsReactivate,
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
                      tooltip: l10n.details,
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
