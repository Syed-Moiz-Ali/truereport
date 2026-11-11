import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class TemplateBuilderScreen extends ConsumerStatefulWidget {
  const TemplateBuilderScreen({super.key, required this.templateId});

  final String templateId;

  @override
  ConsumerState<TemplateBuilderScreen> createState() =>
      _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends ConsumerState<TemplateBuilderScreen> {
  final _searchController = TextEditingController();
  final List<String> _selectedVersionIds = [];
  final Map<String, _ItemInfo> _itemInfo = {};
  String? _selectedVersionId;
  String? _previewInitializedFor;
  String _search = '';
  bool _busy = false;
  bool _savingItems = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(templateDetailProvider(widget.templateId));
    final items = ref.watch(itemsProvider(ItemQuery(search: _search)));

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      appBar: AppBar(
        backgroundColor: PtTheme.white,
        foregroundColor: PtTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.templateBuilder,
          style: PtTheme.font(
            18,
            lineHeight: 24,
            weight: FontWeight.w800,
            color: PtTheme.ink,
          ),
        ),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PtTheme.deepGreen,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: detail.when(
          loading: () => const _CenteredLoading(),
          error: (error, stackTrace) => _CenteredError(
            onRetry: () =>
                ref.invalidate(templateDetailProvider(widget.templateId)),
          ),
          data: (template) => _buildBody(context, l10n, template, items),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    GlobalTemplate template,
    AsyncValue<List<PlatformItem>> items,
  ) {
    final versions = [...template.versions]
      ..sort((a, b) => b.versionNo.compareTo(a.versionNo));
    final selected =
        _findVersion(versions, _selectedVersionId) ??
        (versions.isEmpty ? null : versions.first);
    final versionId = selected?.id ?? '';
    final editing = selected?.status == 'DRAFT';
    final hasDraft = versions.any((version) => version.status == 'DRAFT');

    Widget? previewSection;
    if (versionId.isNotEmpty) {
      final preview = ref.watch(
        weightPreviewProvider(ItemVersionKey(widget.templateId, versionId)),
      );
      _reconcilePreview(preview, versionId);
      previewSection = _WeightPreviewSection(
        preview: preview,
        onRetry: () => ref.invalidate(
          weightPreviewProvider(ItemVersionKey(widget.templateId, versionId)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final expanded = constraints.maxWidth > 1024;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 28,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TemplateHeader(template: template),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: _VersionSelector(
                      versions: versions,
                      selected: selected,
                      enabled: !_busy,
                      onChanged: (id) {
                        setState(() {
                          _selectedVersionId = id;
                          _previewInitializedFor = null;
                          _selectedVersionIds.clear();
                          _itemInfo.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!hasDraft)
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _createDraft,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l10n.createTemplate),
                          ),
                        if (selected?.status == 'DRAFT')
                          FilledButton.icon(
                            onPressed: _busy ? null : () => _publish(versionId),
                            icon: const Icon(Icons.publish_rounded, size: 18),
                            label: Text(l10n.publishTemplate),
                            style: FilledButton.styleFrom(
                              backgroundColor: PtTheme.deepGreen,
                            ),
                          ),
                        if (selected?.status == 'PENDING_APPROVAL') ...[
                          FilledButton.icon(
                            onPressed: _busy ? null : () => _approve(versionId),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(l10n.approveTemplate),
                            style: FilledButton.styleFrom(
                              backgroundColor: PtTheme.deepGreen,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : () => _reject(versionId),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(l10n.rejectTemplate),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PtTheme.rose,
                            ),
                          ),
                        ],
                        if (selected != null && !editing)
                          _InfoChip(
                            label: l10n.versionImmutable,
                            color: PtTheme.muted,
                          ),
                      ],
                    ),
                  ),
                  if (selected?.status == 'PENDING_APPROVAL') ...[
                    const SizedBox(height: 12),
                    _PendingBanner(message: l10n.pendingApproval),
                  ],
                  const SizedBox(height: 20),
                  _ItemsSection(
                    expanded: expanded,
                    editing: editing,
                    itemList: items,
                    searchController: _searchController,
                    search: _search,
                    selectedIds: _selectedVersionIds,
                    infoFor: (id) => _itemInfo[id],
                    onSearchChanged: (value) => setState(() => _search = value),
                    onAdd: _addItem,
                    onRemove: (id) => setState(() {
                      _selectedVersionIds.remove(id);
                      _itemInfo.remove(id);
                    }),
                    onMove: _move,
                    onSave: editing && !_savingItems
                        ? () => _saveItems(versionId)
                        : null,
                    saving: _savingItems,
                  ),
                  if (previewSection != null) ...[
                    const SizedBox(height: 16),
                    previewSection,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _reconcilePreview(AsyncValue<WeightPreview> preview, String versionId) {
    final data = preview.asData?.value;
    if (data == null || _previewInitializedFor == versionId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _previewInitializedFor == versionId) return;
      setState(() {
        _previewInitializedFor = versionId;
        _selectedVersionIds
          ..clear()
          ..addAll(data.rows.map((row) => row.itemVersionId));
        _itemInfo
          ..clear()
          ..addEntries(
            data.rows.map(
              (row) => MapEntry(
                row.itemVersionId,
                _ItemInfo(
                  code: row.itemCode,
                  labelEn: row.labelEn,
                  labelAr: row.labelAr,
                  category: row.categoryCode,
                ),
              ),
            ),
          );
      });
    });
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _selectedVersionIds.length) return;
    setState(() {
      final id = _selectedVersionIds.removeAt(index);
      _selectedVersionIds.insert(target, id);
    });
  }

  Future<void> _addItem(PlatformItem item) async {
    try {
      final detail = await ref
          .read(platformConfigApiProvider)
          .itemDetail(item.id);
      if (!mounted) return;
      final version = detail.draftVersion ?? detail.publishedVersion;
      if (version == null) {
        _snack(AppLocalizations.of(context).noData);
        return;
      }
      if (_selectedVersionIds.contains(version.id)) return;
      setState(() {
        _selectedVersionIds.add(version.id);
        _itemInfo[version.id] = _ItemInfo(
          code: item.code,
          labelEn: item.labelEn,
          labelAr: item.labelAr,
          category: item.categoryLabelEn.isNotEmpty
              ? item.categoryLabelEn
              : item.categoryLabelAr,
        );
      });
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey);
    } catch (_) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context).genericError);
    }
  }

  Future<void> _saveItems(String versionId) async {
    if (_savingItems) return;
    setState(() => _savingItems = true);
    try {
      await ref.read(platformConfigActionsProvider).replaceTemplateItems(
        widget.templateId,
        versionId,
        [
          for (var index = 0; index < _selectedVersionIds.length; index++)
            {
              'itemVersionId': _selectedVersionIds[index],
              'included': true,
              'sortOrder': index + 1,
            },
        ],
      );
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey);
    } catch (_) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context).genericError);
    } finally {
      if (mounted) setState(() => _savingItems = false);
    }
  }

  Future<void> _createDraft() async {
    await _run(() async {
      final updated = await ref
          .read(platformConfigActionsProvider)
          .createTemplateDraft(widget.templateId);
      if (!mounted) return;
      TemplateVersionSummary? draft;
      for (final version in updated.versions) {
        if (version.status == 'DRAFT') {
          draft = version;
          break;
        }
      }
      if (draft != null) {
        setState(() {
          _selectedVersionId = draft!.id;
          _previewInitializedFor = null;
          _selectedVersionIds.clear();
          _itemInfo.clear();
        });
      }
    });
  }

  Future<void> _publish(String versionId) async {
    await _run(() async {
      await ref
          .read(platformConfigActionsProvider)
          .publishTemplate(widget.templateId, versionId);
    }, successMessage: AppLocalizations.of(context).pendingApproval);
  }

  Future<void> _approve(String versionId) async {
    await _run(() async {
      await ref
          .read(platformConfigActionsProvider)
          .approveTemplate(widget.templateId, versionId);
    }, successMessage: AppLocalizations.of(context).published);
  }

  Future<void> _reject(String versionId) async {
    await _run(() async {
      await ref
          .read(platformConfigActionsProvider)
          .rejectTemplate(widget.templateId, versionId);
    }, successMessage: AppLocalizations.of(context).draft);
  }

  Future<void> _run(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (successMessage != null) _snack(successMessage);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey);
    } catch (_) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context).genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

TemplateVersionSummary? _findVersion(
  List<TemplateVersionSummary> versions,
  String? id,
) {
  if (id == null) return null;
  for (final version in versions) {
    if (version.id == id) return version;
  }
  return null;
}

class _ItemInfo {
  const _ItemInfo({
    required this.code,
    required this.labelEn,
    required this.labelAr,
    required this.category,
  });

  final String code;
  final String labelEn;
  final String labelAr;
  final String category;
}

class _TemplateHeader extends StatelessWidget {
  const _TemplateHeader({required this.template});

  final GlobalTemplate template;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoChip(label: template.code, color: PtTheme.deepGreen),
              _InfoChip(label: template.status, color: PtTheme.muted),
              Text(
                '${template.versionCount} ${l10n.versions}',
                style: PtTheme.font(12, color: PtTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            template.nameEn.isEmpty ? template.nameAr : template.nameEn,
            style: PtTheme.font(
              22,
              lineHeight: 28,
              weight: FontWeight.w800,
              color: PtTheme.ink,
            ),
          ),
          if (template.nameAr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              template.nameAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(14, color: PtTheme.muted),
            ),
          ],
          if (template.descriptionEn.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              template.descriptionEn,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          ],
          if (template.descriptionAr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              template.descriptionAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _VersionSelector extends StatelessWidget {
  const _VersionSelector({
    required this.versions,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final List<TemplateVersionSummary> versions;
  final TemplateVersionSummary? selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (versions.isEmpty) {
      return Text(l10n.noData, style: PtTheme.font(13, color: PtTheme.muted));
    }
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DropdownButtonFormField<String>(
            initialValue: selected?.id,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.versions,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final version in versions)
                DropdownMenuItem(
                  value: version.id,
                  child: Text(
                    'v${version.versionNo} · ${_statusLabel(l10n, version.status)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: enabled
                ? (value) {
                    if (value != null) onChanged(value);
                  }
                : null,
          ),
        ),
        if (selected != null)
          _InfoChip(
            label: _statusLabel(l10n, selected!.status),
            color: _statusColor(selected!.status),
          ),
      ],
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({
    required this.expanded,
    required this.editing,
    required this.itemList,
    required this.searchController,
    required this.search,
    required this.selectedIds,
    required this.infoFor,
    required this.onSearchChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onMove,
    required this.onSave,
    required this.saving,
  });

  final bool expanded;
  final bool editing;
  final AsyncValue<List<PlatformItem>> itemList;
  final TextEditingController searchController;
  final String search;
  final List<String> selectedIds;
  final _ItemInfo? Function(String id) infoFor;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PlatformItem> onAdd;
  final ValueChanged<String> onRemove;
  final void Function(int index, int delta) onMove;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final picker = _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addItems,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.search,
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          itemList.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PtTheme.deepGreen,
                ),
              ),
            ),
            error: (error, stackTrace) => Text(
              l10n.noData,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
            data: (items) {
              final filtered = items
                  .where(
                    (item) =>
                        search.isEmpty ||
                        item.code.toLowerCase().contains(
                          search.toLowerCase(),
                        ) ||
                        item.labelEn.toLowerCase().contains(
                          search.toLowerCase(),
                        ) ||
                        item.labelAr.contains(search),
                  )
                  .toList(growable: false);
              if (filtered.isEmpty) {
                return Text(
                  l10n.noData,
                  style: PtTheme.font(13, color: PtTheme.muted),
                );
              }
              return Column(
                children: [
                  for (final item in filtered)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: editing ? () => onAdd(item) : null,
                      title: Text(
                        '${item.code} · ${item.labelEn}',
                        style: PtTheme.font(
                          13,
                          weight: FontWeight.w600,
                          color: PtTheme.ink,
                        ),
                      ),
                      subtitle: Text(
                        item.categoryLabelEn.isEmpty
                            ? item.categoryLabelAr
                            : item.categoryLabelEn,
                        style: PtTheme.font(11, color: PtTheme.muted),
                      ),
                      trailing: IconButton(
                        onPressed: editing ? () => onAdd(item) : null,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: PtTheme.deepGreen,
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

    final selectedCard = _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                l10n.itemsTab,
                style: PtTheme.font(
                  16,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              FilledButton.icon(
                onPressed: onSave,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PtTheme.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 17),
                label: Text(l10n.save),
                style: FilledButton.styleFrom(
                  backgroundColor: PtTheme.deepGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (selectedIds.isEmpty)
            Text(l10n.noData, style: PtTheme.font(13, color: PtTheme.muted))
          else
            Column(
              children: [
                for (var index = 0; index < selectedIds.length; index++)
                  _SelectedItemRow(
                    index: index,
                    enabled: editing,
                    info: infoFor(selectedIds[index]),
                    fallbackId: selectedIds[index],
                    canMoveUp: index > 0,
                    canMoveDown: index < selectedIds.length - 1,
                    onUp: () => onMove(index, -1),
                    onDown: () => onMove(index, 1),
                    onRemove: () => onRemove(selectedIds[index]),
                  ),
              ],
            ),
        ],
      ),
    );

    if (expanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: picker),
          const SizedBox(width: 16),
          Expanded(child: selectedCard),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [picker, const SizedBox(height: 12), selectedCard],
    );
  }
}

class _SelectedItemRow extends StatelessWidget {
  const _SelectedItemRow({
    required this.index,
    required this.enabled,
    required this.info,
    required this.fallbackId,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
  });

  final int index;
  final bool enabled;
  final _ItemInfo? info;
  final String fallbackId;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}',
            style: PtTheme.font(
              12,
              weight: FontWeight.w700,
              color: PtTheme.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info == null
                      ? fallbackId
                      : '${info!.code} · ${info!.labelEn}',
                  style: PtTheme.font(
                    13,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                ),
                if (info != null && info!.category.isNotEmpty)
                  Text(
                    info!.category,
                    style: PtTheme.font(11, color: PtTheme.muted),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Up',
            onPressed: enabled && canMoveUp ? onUp : null,
            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Down',
            onPressed: enabled && canMoveDown ? onDown : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: enabled ? onRemove : null,
            icon: const Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: PtTheme.rose,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightPreviewSection extends StatelessWidget {
  const _WeightPreviewSection({required this.preview, required this.onRetry});

  final AsyncValue<WeightPreview> preview;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      child: preview.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: PtTheme.deepGreen,
            ),
          ),
        ),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.unhealthy,
              style: PtTheme.font(
                14,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
        data: (data) {
          final groups = <String, List<WeightPreviewRow>>{};
          for (final row in data.rows) {
            final key = row.categoryCode.isEmpty ? '-' : row.categoryCode;
            groups.putIfAbsent(key, () => []).add(row);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.weightPreview,
                style: PtTheme.font(
                  16,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    label: '${l10n.categoryWeightMode}: ${data.mode}',
                    color: PtTheme.deepGreen,
                  ),
                  _InfoChip(
                    label:
                        '${l10n.weightTotal}: ${data.categoryWeightTotal.toStringAsFixed(2)}',
                    color: PtTheme.muted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (data.rows.isEmpty)
                Text(l10n.noData, style: PtTheme.font(13, color: PtTheme.muted))
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.itemCode,
                        style: PtTheme.font(
                          11,
                          weight: FontWeight.w700,
                          color: PtTheme.muted,
                        ),
                      ),
                    ),
                    Text(
                      l10n.normalizedWeight,
                      style: PtTheme.font(
                        11,
                        weight: FontWeight.w700,
                        color: PtTheme.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final entry in groups.entries) ...[
                  Text(
                    '${l10n.category}: ${entry.key}',
                    style: PtTheme.font(
                      12,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final row in entry.value)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${row.itemCode} · ${row.labelEn}',
                              style: PtTheme.font(12, color: PtTheme.muted),
                            ),
                          ),
                          Text(
                            row.normalizedWeight.toStringAsFixed(2),
                            style: PtTheme.font(
                              12,
                              weight: FontWeight.w700,
                              color: PtTheme.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PtTheme.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.amber.withValues(alpha: 0.4)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: PtTheme.amber,
            size: 18,
          ),
          Text(
            message,
            style: PtTheme.font(
              13,
              weight: FontWeight.w700,
              color: PtTheme.amber,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: child,
    );
  }
}

class _CenteredLoading extends StatelessWidget {
  const _CenteredLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: PtTheme.deepGreen),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).loading,
            style: PtTheme.font(13, color: PtTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _CenteredError extends StatelessWidget {
  const _CenteredError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: PtTheme.rose, size: 34),
            const SizedBox(height: 12),
            Text(
              l10n.unhealthy,
              style: PtTheme.font(
                16,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: PtTheme.deepGreen),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    'DRAFT' => l10n.draft,
    'PENDING_APPROVAL' => l10n.pendingApproval,
    'PUBLISHED' => l10n.published,
    'RETIRED' => l10n.retired,
    _ => status,
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'DRAFT' => PtTheme.deepGreen,
    'PENDING_APPROVAL' => PtTheme.amber,
    'PUBLISHED' => PtTheme.emerald,
    'RETIRED' => PtTheme.rose,
    _ => PtTheme.muted,
  };
}
