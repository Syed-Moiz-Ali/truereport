import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_category_picker.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../components/platform_toolbar.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../checklist/checklist_page_frame.dart';
import '../checklist/checklist_tab_bar.dart';
import 'master_item_editor_screen.dart';

const _itemStatuses = <String>['ACTIVE', 'DRAFT', 'PUBLISHED', 'RETIRED'];

class MasterLibraryScreen extends ConsumerStatefulWidget {
  const MasterLibraryScreen({super.key});

  @override
  ConsumerState<MasterLibraryScreen> createState() =>
      _MasterLibraryScreenState();
}

class _MasterLibraryScreenState extends ConsumerState<MasterLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';
  String _categoryId = '';
  String _status = '';
  bool _acting = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _search = value);
    });
  }

  Future<void> _openEditor([String? itemId]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MasterItemEditorScreen(itemId: itemId),
      ),
    );
    if (!mounted) return;
    ref.invalidate(itemsProvider);
    ref.invalidate(categoriesProvider);
  }

  Future<void> _draftItem(PlatformItem item) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await ref.read(platformConfigActionsProvider).createDraft(item.id);
      if (!mounted) return;
      ref.invalidate(itemsProvider);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _publishItem(PlatformItem item) async {
    if (_acting) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _acting = true);
    try {
      final actions = ref.read(platformConfigActionsProvider);
      var detail = await ref
          .read(platformConfigApiProvider)
          .itemDetail(item.id);
      var draft = detail.draftVersion;
      // No draft yet: create one first so publish always acts on a draft
      // version. Both calls below are the standard item APIs.
      draft ??= (await actions.createDraft(item.id)).draftVersion;
      if (draft == null) {
        if (!mounted) return;
        _showMessage(l10n.error, isError: true);
        return;
      }
      if (!mounted) return;
      final confirmed = await showPlatformConfirmDialog(
        context: context,
        title: l10n.publishItem,
        body: '${l10n.publishItem} · v${draft.versionNo}',
        confirmLabel: l10n.publish,
      );
      if (confirmed != true) return;
      await actions.publishItem(item.id, draft.id);
      if (!mounted) return;
      _showMessage(l10n.itemPublished);
      ref.invalidate(itemsProvider);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmRetireItem(PlatformItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: l10n.retireItem,
      body: l10n.retireConfirm,
      confirmLabel: l10n.retire,
      destructive: true,
    );
    if (confirmed != true) return;
    try {
      await ref.read(platformConfigActionsProvider).retireItem(item.id);
      if (!mounted) return;
      _showMessage(l10n.itemRetired);
      ref.invalidate(itemsProvider);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_failureMessage(error), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError ? PtTheme.rose : PtTheme.deepGreen,
        content: Text(
          message,
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.white),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories =
        categoriesAsync.asData?.value ?? const <PlatformCategory>[];
    final query = ItemQuery(
      search: _search,
      categoryId: _categoryId,
      status: _status,
    );
    final itemsAsync = ref.watch(itemsProvider(query));
    final healthAsync = ref.watch(configHealthProvider);
    final showHealthBanner = healthAsync.maybeWhen(
      data: (health) => !health.healthy,
      orElse: () => false,
    );
    final countLabel = itemsAsync.maybeWhen(
      data: (items) => l10n.chkResultCount(items.length),
      orElse: () => null,
    );

    return ChecklistPageFrame(
      currentRoute: '/checklist/items',
      currentTab: ChecklistTab.items,
      onSearchChanged: _onSearchChanged,
      actions: [
        PlatformPrimaryButton(
          label: l10n.addItem,
          icon: Icons.add_rounded,
          onPressed: () => _openEditor(),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHealthBanner) ...[
                _buildHealthBanner(l10n),
                const SizedBox(height: 20),
              ],
              Text(
                l10n.chkItemsTitle,
                style: PtTheme.font(
                  18,
                  lineHeight: 24,
                  weight: FontWeight.w800,
                  color: PtTheme.ink,
                  tracking: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _buildFilters(l10n, categories, countLabel),
              const SizedBox(height: 20),
              _buildItems(l10n, itemsAsync),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHealthBanner(AppLocalizations l10n) {
    return PlatformSectionCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PtTheme.rose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: PtTheme.rose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.unhealthy,
                style: PtTheme.font(
                  14,
                  lineHeight: 20,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
            ],
          ),
          PlatformPrimaryButton(
            label: l10n.reviewHealth,
            icon: Icons.health_and_safety_outlined,
            onPressed: () => context.go('/checklist/health'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    AppLocalizations l10n,
    List<PlatformCategory> categories,
    String? countLabel,
  ) {
    return PlatformToolbar(
      searchController: _searchController,
      searchHint: l10n.search,
      onSearchChanged: _onSearchChanged,
      countLabel: countLabel,
      filters: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: PlatformDropdown<String>(
            label: l10n.status,
            value: _status,
            items: [
              DropdownMenuItem(value: '', child: Text(l10n.filterAll)),
              for (final status in _itemStatuses)
                DropdownMenuItem(value: status, child: Text(status)),
            ],
            onChanged: (value) {
              setState(() => _status = value ?? '');
            },
          ),
        ),
        PlatformCategoryPicker(
          categories: categories,
          selectedId: _categoryId,
          onChanged: (id) => setState(() => _categoryId = id ?? ''),
        ),
      ],
    );
  }

  Widget _buildItems(
    AppLocalizations l10n,
    AsyncValue<List<PlatformItem>> itemsAsync,
  ) {
    return itemsAsync.when(
      loading: () => PlatformLoadingView(message: l10n.loading),
      error: (error, _) => PlatformErrorView(
        message: _failureMessage(error),
        retryLabel: l10n.retry,
        onRetry: () => ref.invalidate(itemsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return PlatformEmptyView(
            icon: Icons.inbox_outlined,
            title: l10n.noData,
          );
        }
        // Rich cards are the primary view on every breakpoint; two columns
        // on wide viewports, one stacked column below the breakpoint.
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 1000;
            if (!twoColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items) ...[
                    _buildItemCard(l10n, item),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }
            final rows = <Widget>[];
            for (var index = 0; index < items.length; index += 2) {
              rows.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildItemCard(l10n, items[index])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: index + 1 < items.length
                          ? _buildItemCard(l10n, items[index + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
              rows.add(const SizedBox(height: 12));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(AppLocalizations l10n, PlatformItem item) {
    final retired = item.status == 'RETIRED';
    final categoryLabel = item.categoryLabelEn.isEmpty
        ? (item.categoryLabelAr.isEmpty
              ? item.categoryId
              : item.categoryLabelAr)
        : item.categoryLabelEn;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: PtTheme.canvas,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: PtTheme.border),
                    ),
                    child: Text(
                      item.code,
                      style: PtTheme.font(
                        11,
                        weight: FontWeight.w700,
                        color: PtTheme.muted,
                        tracking: 0.4,
                      ),
                    ),
                  ),
                  PlatformStatusChip(status: item.status),
                  if (item.safetyCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: PtTheme.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.safetyCritical,
                        style: PtTheme.font(
                          11,
                          weight: FontWeight.w700,
                          color: PtTheme.rose,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                item.currentVersion == null ? '' : 'v${item.currentVersion}',
                style: PtTheme.font(
                  12,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.labelEn.isEmpty ? item.code : item.labelEn,
            style: PtTheme.font(
              16,
              lineHeight: 22,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.labelAr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.labelAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(14, lineHeight: 20, color: PtTheme.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              PlatformMetaPill(label: l10n.category, value: categoryLabel),
              Semantics(
                label:
                    '${l10n.measurementUnit}: '
                    '${item.measurementUnit.isEmpty ? '—' : item.measurementUnit}',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: PtTheme.canvas,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: PtTheme.border),
                  ),
                  child: Text(
                    item.measurementUnit.isEmpty ? '—' : item.measurementUnit,
                    style: PtTheme.font(
                      11,
                      lineHeight: 14,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (item.sensorTool.isNotEmpty)
                PlatformMetaPill(
                  label: l10n.sensorTool,
                  value: item.sensorTool,
                ),
              // Evidence counts are not in the items list payload; the
              // placeholder below marks the gap instead of inventing counts.
              PlatformMetaPill(label: l10n.chkEvidence, value: '—'),
              PlatformMetaPill(
                label: l10n.chkUpdated,
                value: item.updatedAt.isEmpty ? '—' : item.updatedAt,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: l10n.edit,
                onPressed: _acting ? null : () => _openEditor(item.id),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                tooltip: l10n.createDraft,
                onPressed: _acting ? null : () => _draftItem(item),
                icon: const Icon(Icons.note_add_outlined, size: 20),
              ),
              if (!retired)
                IconButton(
                  tooltip: l10n.publishItem,
                  onPressed: _acting ? null : () => _publishItem(item),
                  icon: const Icon(Icons.publish_rounded, size: 20),
                ),
              if (!retired)
                IconButton(
                  tooltip: l10n.retireItem,
                  onPressed: _acting ? null : () => _confirmRetireItem(item),
                  icon: const Icon(
                    Icons.archive_outlined,
                    size: 20,
                    color: PtTheme.rose,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _surfaceDecoration() {
    return BoxDecoration(
      color: PtTheme.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PtTheme.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 8,
          offset: Offset(0, 2),
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
