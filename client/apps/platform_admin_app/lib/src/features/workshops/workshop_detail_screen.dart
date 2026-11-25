import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import 'atlas/atlas_ui.dart';
import 'atlas/workshop_activity_section.dart';
import 'atlas/workshop_record_parts.dart';
import 'atlas/workshop_staff_section.dart';
import 'workshop_form.dart';

/// Atlas record page: the same instrument band as the workspace, with the
/// staff and activity depth that does not fit in the index pane.
class WorkshopDetailScreen extends ConsumerStatefulWidget {
  const WorkshopDetailScreen({
    super.key,
    required this.workshopId,
    this.initialTab,
  });

  final String workshopId;
  final String? initialTab;

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
    _tab = widget.initialTab == 'staff' ? 1 : 0;
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
      child: FutureBuilder<HierarchyWorkshop>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _RecordLoading();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _RecordError(
              strings: strings,
              message: strings.tKey(CommonKeys.stateError),
              onRetry: _refresh,
            );
          }
          return _buildRecord(context, strings, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildRecord(
    BuildContext context,
    UiMessageStrings strings,
    HierarchyWorkshop workshop,
  ) {
    final tabs = [
      strings.tKey(PlatformAdminKeys.tabWorkshopOverview),
      strings.tKey(PlatformAdminKeys.tabWorkshopStaff),
      strings.tKey(PlatformAdminKeys.tabWorkshopActivity),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AtlasButton(
                  label: strings.tKey(PlatformAdminKeys.navWorkshops),
                  icon: Icons.arrow_back_rounded,
                  variant: AtlasButtonVariant.ghost,
                  compact: true,
                  onPressed: () => context.go('/workshops'),
                ),
              ),
              const SizedBox(height: 14),
              AtlasSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkshopRecordHeader(
                      strings: strings,
                      workshop: workshop,
                      onEdit: () => _edit(strings, workshop),
                      onToggleStatus: () => _toggleStatus(strings, workshop),
                    ),
                    const SizedBox(height: 22),
                    WorkshopInstrumentBand(
                      strings: strings,
                      workshop: workshop,
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: PtTheme.border),
                    const SizedBox(height: 14),
                    AtlasTabs(
                      labels: tabs,
                      selected: _tab,
                      onSelected: (index) => setState(() => _tab = index),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Atlas.panelGap),
              switch (_tab) {
                0 => AtlasSurface(
                  child: WorkshopOverview(strings: strings, workshop: workshop),
                ),
                1 => WorkshopStaffSection(
                  workshop: workshop,
                  onChanged: _refresh,
                ),
                _ => WorkshopActivitySection(workshopId: workshop.id),
              },
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(
    UiMessageStrings strings,
    HierarchyWorkshop workshop,
  ) async {
    await showWorkshopFormDialog(
      context: context,
      strings: strings,
      workshop: workshop,
      onSaved: () {
        _refresh();
        ref.invalidate(hierarchyStateProvider);
      },
    );
  }

  Future<void> _toggleStatus(
    UiMessageStrings strings,
    HierarchyWorkshop workshop,
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
      _refresh();
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

class _RecordLoading extends StatelessWidget {
  const _RecordLoading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: const AtlasSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AtlasSkeletonRows(rows: 1, height: 72),
                SizedBox(height: 18),
                AtlasSkeletonRows(rows: 3, height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordError extends StatelessWidget {
  const _RecordError({
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
