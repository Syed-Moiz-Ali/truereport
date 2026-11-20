import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'atlas/atlas_ui.dart';
import 'atlas/workshop_index_pane.dart';
import 'atlas/workshop_record_parts.dart';
import 'workshop_form.dart';

/// Atlas workspace: the workshop index stays open while a record is inspected.
class WorkshopsScreen extends ConsumerStatefulWidget {
  const WorkshopsScreen({super.key});

  @override
  ConsumerState<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends ConsumerState<WorkshopsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = '';
  String? _selectedId;

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

  List<HierarchyWorkshop> _filtered(List<HierarchyWorkshop> workshops) {
    final query = _query.trim().toLowerCase();
    return workshops
        .where((workshop) {
          if (_statusFilter.isNotEmpty &&
              workshop.status.toUpperCase() != _statusFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          return workshop.name.toLowerCase().contains(query) ||
              (workshop.branchName ?? '').toLowerCase().contains(query) ||
              (workshop.contactEmail ?? '').toLowerCase().contains(query) ||
              workshop.status.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final hierarchy = ref.watch(hierarchyStateProvider);
    return PlatformShell(
      currentRoute: '/workshops',
      onNavigate: (route) => context.go(route),
      child: hierarchy.when(
        loading: () => const _WorkspaceLoading(),
        error: (_, _) => _WorkspaceError(
          strings: strings,
          message: strings.tKey(CommonKeys.stateError),
          onRetry: () => ref.invalidate(hierarchyStateProvider),
        ),
        data: (response) {
          final workshops = response.workshops;
          final statuses = <String>{
            for (final workshop in workshops) workshop.status.toUpperCase(),
          }.toList()..sort();
          final filtered = _filtered(workshops);
          final selected = filtered.isEmpty
              ? null
              : filtered.firstWhere(
                  (workshop) => workshop.id == _selectedId,
                  orElse: () => filtered.first,
                );

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              if (!wide) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PageHeader(
                        strings: strings,
                        count: filtered.length,
                        compact: true,
                        onAdd: () => context.go('/workshops/new'),
                      ),
                      const SizedBox(height: 18),
                      WorkshopIndexPane(
                        strings: strings,
                        workshops: workshops,
                        filtered: filtered,
                        searchController: _searchController,
                        query: _query,
                        statuses: statuses,
                        statusFilter: _statusFilter,
                        onSearchChanged: (value) =>
                            setState(() => _query = value),
                        onStatusChanged: (value) =>
                            setState(() => _statusFilter = value),
                        onOpen: (workshop) =>
                            context.go('/workshops/${workshop.id}'),
                        onClearFilters: _clearFilters,
                        inline: true,
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PageHeader(
                      strings: strings,
                      count: filtered.length,
                      onAdd: () => context.go('/workshops/new'),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 386,
                            child: WorkshopIndexPane(
                              strings: strings,
                              workshops: workshops,
                              filtered: filtered,
                              searchController: _searchController,
                              query: _query,
                              statuses: statuses,
                              statusFilter: _statusFilter,
                              onSearchChanged: (value) =>
                                  setState(() => _query = value),
                              onStatusChanged: (value) =>
                                  setState(() => _statusFilter = value),
                              onOpen: (workshop) =>
                                  setState(() => _selectedId = workshop.id),
                              onClearFilters: _clearFilters,
                              selectedId: selected?.id,
                            ),
                          ),
                          const SizedBox(width: Atlas.panelGap),
                          Expanded(
                            child: selected == null
                                ? AtlasSurface(
                                    child: AtlasEmpty(
                                      icon: Icons.storefront_outlined,
                                      title: strings.tKey(
                                        workshops.isEmpty
                                            ? PlatformAdminKeys
                                                  .emptyWorkshopsTitle
                                            : PlatformAdminKeys
                                                  .emptyWorkshopsFilteredTitle,
                                      ),
                                      body: strings.tKey(
                                        workshops.isEmpty
                                            ? PlatformAdminKeys
                                                  .emptyWorkshopsBody
                                            : PlatformAdminKeys
                                                  .emptyWorkshopsFilteredBody,
                                      ),
                                      actionLabel:
                                          _query.isNotEmpty ||
                                              _statusFilter.isNotEmpty
                                          ? strings.tKey(
                                              PlatformAdminKeys
                                                  .buttonClearFilters,
                                            )
                                          : null,
                                      onAction: _clearFilters,
                                    ),
                                  )
                                : _RecordPreview(
                                    strings: strings,
                                    workshop: selected,
                                    onOpen: () =>
                                        context.go('/workshops/${selected.id}'),
                                    onEdit: () => _edit(selected, strings),
                                    onToggleStatus: () =>
                                        _toggleStatus(selected, strings),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _edit(
    HierarchyWorkshop workshop,
    UiMessageStrings strings,
  ) async {
    await showWorkshopFormDialog(
      context: context,
      strings: strings,
      workshop: workshop,
      onSaved: () => ref.invalidate(hierarchyStateProvider),
    );
  }

  Future<void> _toggleStatus(
    HierarchyWorkshop workshop,
    UiMessageStrings strings,
  ) async {
    final isActive = workshop.status.toUpperCase() == 'ACTIVE';
    final reason = await showReasonDialog(
      context: context,
      strings: strings,
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

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.strings,
    required this.count,
    required this.onAdd,
    this.compact = false,
  });

  final UiMessageStrings strings;
  final int count;
  final VoidCallback onAdd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.tArgsKey(PlatformAdminKeys.pageWorkshopsResultCount, {
            'count': count,
          }),
          style: Atlas.eyebrow,
        ),
        const SizedBox(height: 8),
        Text(
          strings.tKey(PlatformAdminKeys.navWorkshops),
          style: Atlas.pageTitle,
        ),
        const SizedBox(height: 5),
        Text(
          strings.tKey(PlatformAdminKeys.pageWorkshopsSubtitle),
          style: Atlas.body.copyWith(color: PtTheme.muted),
        ),
      ],
    );
    final add = AtlasButton(
      label: strings.tKey(PlatformAdminKeys.pageWorkshopsAdd),
      icon: Icons.add_rounded,
      onPressed: onAdd,
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 16),
          Align(alignment: AlignmentDirectional.centerStart, child: add),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: title),
        add,
      ],
    );
  }
}

class _RecordPreview extends StatelessWidget {
  const _RecordPreview({
    required this.strings,
    required this.workshop,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final UiMessageStrings strings;
  final HierarchyWorkshop workshop;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return AtlasSurface(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkshopRecordHeader(
              strings: strings,
              workshop: workshop,
              onEdit: onEdit,
              onToggleStatus: onToggleStatus,
              onViewDetails: onOpen,
            ),
            const SizedBox(height: 22),
            WorkshopInstrumentBand(strings: strings, workshop: workshop),
            const SizedBox(height: 24),
            const Divider(height: 1, color: PtTheme.border),
            const SizedBox(height: 22),
            Text(
              strings.tKey(PlatformAdminKeys.tabWorkshopOverview),
              style: Atlas.sectionTitle,
            ),
            const SizedBox(height: 8),
            WorkshopOverview(strings: strings, workshop: workshop),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceLoading extends StatelessWidget {
  const _WorkspaceLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 386,
            child: AtlasSurface(
              padding: EdgeInsets.zero,
              child: AtlasSkeletonRows(rows: 7),
            ),
          ),
          SizedBox(width: Atlas.panelGap),
          Expanded(
            child: AtlasSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AtlasSkeletonRows(rows: 1, height: 90),
                  SizedBox(height: 20),
                  AtlasSkeletonRows(rows: 3, height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceError extends StatelessWidget {
  const _WorkspaceError({
    required this.strings,
    required this.message,
    required this.onRetry,
  });

  final UiMessageStrings strings;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AtlasSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Atlas.text(13, weight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            AtlasButton(
              label: strings.tKey(CommonKeys.buttonRetry),
              variant: AtlasButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
