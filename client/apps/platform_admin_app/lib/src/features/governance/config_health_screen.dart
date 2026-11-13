import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../checklist/checklist_page_frame.dart';
import '../checklist/checklist_tab_bar.dart';
import 'impact_dialog.dart';

import 'package:l10n/l10n.dart';

class ConfigHealthScreen extends ConsumerStatefulWidget {
  const ConfigHealthScreen({super.key});

  @override
  ConsumerState<ConfigHealthScreen> createState() => _ConfigHealthScreenState();
}

class _ConfigHealthScreenState extends ConsumerState<ConfigHealthScreen> {
  final _entityIdController = TextEditingController();
  String _entityType = 'CATEGORY';

  @override
  void dispose() {
    _entityIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final health = ref.watch(configHealthProvider);

    return ChecklistPageFrame(
      currentRoute: '/checklist/health',
      currentTab: ChecklistTab.health,
      showSearch: false,
      actions: [
        PlatformPrimaryButton(
          label: strings.tKey(CommonKeys.buttonRefresh),
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(configHealthProvider),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          health.when(
            loading: () => const PlatformLoadingView(),
            error: (error, stackTrace) => PlatformErrorView(
              message: strings.tKey(CommonKeys.statusUnhealthy),
              retryLabel: strings.tKey(CommonKeys.buttonRetry),
              onRetry: () => ref.invalidate(configHealthProvider),
            ),
            data: (data) => _HealthContent(health: data),
          ),
          const SizedBox(height: 20),
          _ImpactHelper(
            entityType: _entityType,
            entityIdController: _entityIdController,
            onEntityTypeChanged: (value) => setState(() => _entityType = value),
            onEntityIdChanged: (_) => setState(() {}),
            onOpen: () => showImpactDialog(
              context,
              ref,
              entityType: _entityType,
              entityId: _entityIdController.text.trim(),
            ),
          ),
          const SizedBox(height: 20),
          const _ReleasesSection(),
        ],
      ),
    );
  }
}

class _HealthContent extends ConsumerWidget {
  const _HealthContent({required this.health});

  final ConfigHealth health;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final issueCount = health.checks.where((check) => !check.ok).length;
    final okCount = health.checks.length - issueCount;
    final groups = _groupBySeverity(health.checks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (health.healthy ? PtTheme.emerald : PtTheme.rose)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      health.healthy
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      color: health.healthy ? PtTheme.emerald : PtTheme.rose,
                      size: 24,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlatformStatusChip(
                          status: health.healthy
                              ? strings.tKey(CommonKeys.statusHealthy)
                              : strings.tKey(CommonKeys.statusUnhealthy),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.tKey(PlatformAdminKeys.pageHealthTitle),
                          style: PtTheme.font(
                            16,
                            lineHeight: 22,
                            weight: FontWeight.w700,
                            color: PtTheme.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final threeAcross = constraints.maxWidth >= 700;
                  Widget summaryTile(String label, String value, Color color) {
                    return Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        14,
                        12,
                        14,
                        12,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value,
                            style: PtTheme.font(
                              20,
                              lineHeight: 26,
                              weight: FontWeight.w800,
                              color: PtTheme.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: PtTheme.font(
                              12,
                              lineHeight: 17,
                              weight: FontWeight.w600,
                              color: PtTheme.muted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }

                  final tiles = [
                    summaryTile(
                      '${health.checks.length} ${strings.tKey(PlatformAdminKeys.pageHealthTitle)}',
                      '${health.checks.length}',
                      PtTheme.muted,
                    ),
                    summaryTile(
                      strings.tKey(CommonKeys.statusHealthy),
                      '$okCount',
                      PtTheme.emerald,
                    ),
                    summaryTile(
                      strings.tKey(CommonKeys.statusUnhealthy),
                      '$issueCount',
                      issueCount == 0 ? PtTheme.muted : PtTheme.rose,
                    ),
                  ];
                  if (!threeAcross) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in tiles) ...[
                          item,
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (var index = 0; index < tiles.length; index++) ...[
                        Expanded(child: tiles[index]),
                        if (index != tiles.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (health.checks.isEmpty)
          PlatformEmptyView(
            icon: Icons.inbox_outlined,
            title: strings.tKey(CommonKeys.emptyTitle),
          )
        else
          for (final entry in groups.entries) ...[
            PlatformSectionHeader(
              title: '${entry.key} · ${entry.value.length}',
            ),
            const SizedBox(height: 8),
            for (final check in entry.value) ...[
              _HealthCheckCard(check: check),
              const SizedBox(height: 12),
            ],
          ],
      ],
    );
  }
}

Map<String, List<HealthCheck>> _groupBySeverity(List<HealthCheck> checks) {
  final groups = <String, List<HealthCheck>>{};
  for (final check in checks) {
    groups.putIfAbsent(check.severity, () => []).add(check);
  }
  final entries = groups.entries.toList()
    ..sort((a, b) {
      final aOk = a.key == 'OK';
      final bOk = b.key == 'OK';
      if (aOk != bOk) return aOk ? 1 : -1;
      return a.key.compareTo(b.key);
    });
  return Map.fromEntries(entries);
}

class _HealthCheckCard extends ConsumerWidget {
  const _HealthCheckCard({required this.check});

  final HealthCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final severityColor = check.ok
        ? PtTheme.emerald
        : check.severity == 'WARNING'
        ? PtTheme.gold
        : PtTheme.rose;
    final severityIcon = check.ok
        ? Icons.check_circle_outline_rounded
        : check.severity == 'WARNING'
        ? Icons.warning_amber_rounded
        : Icons.error_outline_rounded;
    final preview = check.references.take(3).toList(growable: false);
    final remaining = check.references.length - preview.length;
    return PlatformSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(severityIcon, size: 18, color: severityColor),
                    Text(
                      check.code,
                      style: PtTheme.font(
                        12,
                        lineHeight: 17,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                        tracking: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    PlatformStatusChip(status: check.severity),
                    PlatformMetaPill(
                      label: strings.tKey(
                        PlatformAdminKeys.dialogImpactAffectedItems,
                      ),
                      value: '${check.affected}',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (check.messageEn.isNotEmpty)
                  Text(
                    check.messageEn,
                    style: PtTheme.font(
                      14,
                      lineHeight: 20,
                      weight: FontWeight.w600,
                      color: PtTheme.ink,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (check.messageAr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    check.messageAr,
                    textDirection: TextDirection.rtl,
                    style: PtTheme.font(
                      13,
                      lineHeight: 19,
                      color: PtTheme.muted,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: PtTheme.canvas,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PtTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final reference in preview)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              reference,
                              style: PtTheme.font(
                                12,
                                lineHeight: 17,
                                weight: FontWeight.w600,
                                color: PtTheme.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (remaining > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '+$remaining',
                              style: PtTheme.font(
                                11,
                                weight: FontWeight.w600,
                                color: PtTheme.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactHelper extends ConsumerWidget {
  const _ImpactHelper({
    required this.entityType,
    required this.entityIdController,
    required this.onEntityTypeChanged,
    required this.onEntityIdChanged,
    required this.onOpen,
  });

  final String entityType;
  final TextEditingController entityIdController;
  final ValueChanged<String> onEntityTypeChanged;
  final ValueChanged<String> onEntityIdChanged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final hasId = entityIdController.text.trim().isNotEmpty;
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.dialogImpactTitle),
            subtitle: strings.tKey(CommonKeys.statusBlocked),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 700;
              final fieldWidth = wide ? 320.0 : double.infinity;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: fieldWidth),
                    child: PlatformDropdown<String>(
                      label: strings.tKey(CommonKeys.labelCategory),
                      value: entityType,
                      items: [
                        DropdownMenuItem(
                          value: 'CATEGORY',
                          child: Text(
                            strings.tKey(
                              PlatformAdminKeys.labelEntityTypeCategory,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ITEM',
                          child: Text(
                            strings.tKey(PlatformAdminKeys.labelEntityTypeItem),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'TEMPLATE',
                          child: Text(
                            strings.tKey(
                              PlatformAdminKeys.labelEntityTypeTemplate,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) onEntityTypeChanged(value);
                      },
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: fieldWidth),
                    child: PlatformTextField(
                      controller: entityIdController,
                      label: strings.tKey(PlatformAdminKeys.fieldItemCode),
                      onChanged: onEntityIdChanged,
                    ),
                  ),
                  PlatformPrimaryButton(
                    label: strings.tKey(PlatformAdminKeys.dialogImpactTitle),
                    icon: Icons.travel_explore_rounded,
                    onPressed: hasId ? onOpen : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReleasesSection extends ConsumerStatefulWidget {
  const _ReleasesSection();

  @override
  ConsumerState<_ReleasesSection> createState() => _ReleasesSectionState();
}

class _ReleasesSectionState extends ConsumerState<_ReleasesSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_failureMessage(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: _CreateReleaseDialog(),
      ),
    );
    if (created == true) {
      ref.invalidate(configReleasesProvider);
    }
  }

  String _actionLabel(dynamic strings, String status) {
    switch (status) {
      case 'DRAFT':
        return strings.tKey(PlatformAdminKeys.buttonReleaseSubmit);
      case 'REVIEW':
        return strings.tKey(PlatformAdminKeys.buttonReleaseApprove);
      case 'APPROVED':
        return strings.tKey(PlatformAdminKeys.buttonReleasePublish);
      case 'PUBLISHED':
        return strings.tKey(PlatformAdminKeys.buttonReleaseDeprecate);
      default:
        return '';
    }
  }

  String _action(String status) {
    switch (status) {
      case 'DRAFT':
        return 'submit';
      case 'REVIEW':
        return 'approve';
      case 'APPROVED':
        return 'publish';
      default:
        return 'deprecate';
    }
  }

  bool _canTransition(String status) =>
      status == 'DRAFT' ||
      status == 'REVIEW' ||
      status == 'APPROVED' ||
      status == 'PUBLISHED';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final releases = ref.watch(configReleasesProvider);
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.pageReleasesTitle),
            action: PlatformPrimaryButton(
              label: strings.tKey(PlatformAdminKeys.buttonReleaseCreate),
              icon: Icons.add_rounded,
              onPressed: _busy ? null : _create,
            ),
          ),
          const SizedBox(height: 12),
          releases.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: PtTheme.deepGreen),
              ),
            ),
            error: (error, stackTrace) => Text(
              _failureMessage(error),
              style: PtTheme.font(12, color: PtTheme.rose),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  strings.tKey(CommonKeys.emptyTitle),
                  style: PtTheme.font(13, color: PtTheme.muted),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final release in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PtTheme.canvas,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PtTheme.border),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                PlatformStatusChip(status: release.status),
                                PlatformMetaPill(
                                  label: release.entityType,
                                  value: release.entityId,
                                ),
                                if (release.notes.isNotEmpty)
                                  Text(
                                    release.notes,
                                    style: PtTheme.font(
                                      12,
                                      color: PtTheme.muted,
                                    ),
                                  ),
                              ],
                            ),
                            if (_canTransition(release.status))
                              PlatformSecondaryButton(
                                label: _actionLabel(strings, release.status),
                                onPressed: _busy
                                    ? null
                                    : () => _run(
                                        () => ref
                                            .read(platformConfigActionsProvider)
                                            .transitionRelease(
                                              release.id,
                                              _action(release.status),
                                            ),
                                      ),
                              ),
                          ],
                        ),
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
}

class _CreateReleaseDialog extends ConsumerStatefulWidget {
  const _CreateReleaseDialog();

  @override
  ConsumerState<_CreateReleaseDialog> createState() =>
      _CreateReleaseDialogState();
}

class _CreateReleaseDialogState extends ConsumerState<_CreateReleaseDialog> {
  final _entityId = TextEditingController();
  final _notes = TextEditingController();
  String _entityType = 'TEMPLATE';
  bool _saving = false;

  @override
  void dispose() {
    _entityId.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_entityId.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(platformConfigActionsProvider).createRelease({
        'entityType': _entityType,
        'entityId': _entityId.text.trim(),
        'notes': _notes.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_failureMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformDialogShell(
      title: strings.tKey(PlatformAdminKeys.buttonReleaseCreate),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformDropdown<String>(
            label: strings.tKey(PlatformAdminKeys.fieldReleaseEntityType),
            value: _entityType,
            items: [
              DropdownMenuItem(
                value: 'TEMPLATE',
                child: Text(
                  strings.tKey(PlatformAdminKeys.labelEntityTypeTemplate),
                ),
              ),
              DropdownMenuItem(
                value: 'ITEM',
                child: Text(
                  strings.tKey(PlatformAdminKeys.labelEntityTypeItem),
                ),
              ),
              DropdownMenuItem(
                value: 'CATEGORY',
                child: Text(
                  strings.tKey(PlatformAdminKeys.labelEntityTypeCategory),
                ),
              ),
              DropdownMenuItem(
                value: 'SCORING_RULE',
                child: Text(
                  strings.tKey(PlatformAdminKeys.labelEntityTypeScoringRule),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _entityType = value);
            },
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            controller: _entityId,
            label: strings.tKey(PlatformAdminKeys.fieldReleaseEntityId),
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            controller: _notes,
            label: strings.tKey(PlatformAdminKeys.fieldReleaseNotes),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        PlatformSecondaryButton(
          label: strings.tKey(CommonKeys.buttonCancel),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PlatformPrimaryButton(
          label: strings.tKey(CommonKeys.buttonSave),
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}

String _failureMessage(Object error) {
  if (error is AppFailure) {
    return error.statusCode == null
        ? error.messageKey
        : '${error.messageKey} (${error.statusCode})';
  }
  return error.toString();
}
