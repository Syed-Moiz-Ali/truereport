import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../checklist/catalog/catalog_ui.dart';
import '../checklist/checklist_status.dart';
import '../localization/translation_issue_dialog.dart';

class MasterLibraryScreen extends ConsumerStatefulWidget {
  const MasterLibraryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<MasterLibraryScreen> createState() =>
      _MasterLibraryScreenState();
}

class _MasterLibraryScreenState extends ConsumerState<MasterLibraryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  String _categoryId = '';
  String _status = '';
  String? _selectedId;
  bool _acting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final categories =
        ref.watch(categoriesProvider).asData?.value ??
        const <PlatformCategory>[];
    final query = ItemQuery(
      search: _search,
      categoryId: _categoryId,
      status: _status,
    );
    final itemsAsync = ref.watch(itemsProvider(query));
    final health = ref.watch(configHealthProvider).asData?.value;

    final content = LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 22, wide ? 24 : 14, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                strings: strings,
                wide: wide,
                onAdd: () => context.go('/checklist/items/new'),
              ),
              const SizedBox(height: 12),
              CatalogTabs(
                labels: [
                  strings.tKey(PlatformAdminKeys.tabChecklistItems),
                  strings.tKey(PlatformAdminKeys.tabChecklistCategories),
                  strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
                ],
                selected: 0,
                onSelected: (index) {
                  if (index == 1) context.go('/checklist/categories');
                  if (index == 2) context.go('/checklist/option-sets');
                },
              ),
              if (health != null && !health.healthy) ...[
                const SizedBox(height: 12),
                _HealthStrip(
                  strings: strings,
                  count: health.checks.where((check) => !check.ok).length,
                  onOpen: () => context.go('/checklist/health'),
                ),
              ],
              const SizedBox(height: 12),
              _Toolbar(
                strings: strings,
                controller: _searchController,
                onSearch: _onSearch,
                categories: categories,
                categoryId: _categoryId,
                status: _status,
                onCategory: (value) => setState(() => _categoryId = value),
                onStatus: (value) => setState(() => _status = value),
                countLabel: itemsAsync.maybeWhen(
                  data: (items) => strings.tArgsKey(
                    PlatformAdminKeys.pageChecklistItemsResultCount,
                    {'count': items.length},
                  ),
                  orElse: () => '',
                ),
              ),
              const SizedBox(height: 12),
              itemsAsync.when(
                loading: () => const CatalogSkeleton(),
                error: (_, _) => CatalogError(
                  strings: strings,
                  onRetry: () => ref.invalidate(itemsProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    final filtered =
                        _search.isNotEmpty ||
                        _categoryId.isNotEmpty ||
                        _status.isNotEmpty;
                    return CatalogSurface(
                      child: CatalogEmpty(
                        title: strings.tKey(
                          filtered
                              ? PlatformAdminKeys
                                    .checklistItemsEmptyFilteredTitle
                              : PlatformAdminKeys
                                    .checklistItemsEmptyInitialTitle,
                        ),
                        body: strings.tKey(
                          filtered
                              ? PlatformAdminKeys
                                    .checklistItemsEmptyFilteredBody
                              : PlatformAdminKeys
                                    .checklistItemsEmptyInitialBody,
                        ),
                        actionLabel: filtered
                            ? null
                            : strings.tKey(PlatformAdminKeys.buttonItemAdd),
                        onAction: filtered
                            ? null
                            : () => context.go('/checklist/items/new'),
                      ),
                    );
                  }
                  final selected = items.firstWhere(
                    (item) => item.id == _selectedId,
                    orElse: () => items.first,
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 380,
                          child: _IndexPane(
                            strings: strings,
                            items: items,
                            selectedId: selected.id,
                            onSelect: (item) =>
                                setState(() => _selectedId = item.id),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RecordPane(
                            strings: strings,
                            item: selected,
                            acting: _acting,
                            onEdit: () => context.go(
                              '/checklist/items/${selected.id}/edit',
                            ),
                            onDraft: () => _draft(strings, selected),
                            onPublish: () => _publish(strings, selected),
                            onRetire: () => _retire(strings, selected),
                          ),
                        ),
                      ],
                    );
                  }
                  return _IndexPane(
                    strings: strings,
                    items: items,
                    selectedId: null,
                    onSelect: (item) =>
                        context.go('/checklist/items/${item.id}/edit'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
    if (widget.embedded) return content;
    return PlatformShell(
      currentRoute: '/checklist/items',
      onNavigate: (route) => context.go(route),
      child: content,
    );
  }

  Future<void> _draft(UiMessageStrings strings, PlatformItem item) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await ref.read(platformConfigActionsProvider).createDraft(item.id);
      if (!mounted) return;
      _toast(
        strings.tKey(PlatformAdminKeys.checklistEditorButtonCreateDraftToEdit),
      );
      ref.invalidate(itemsProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError), error: true);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _publish(UiMessageStrings strings, PlatformItem item) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      final api = ref.read(platformConfigApiProvider);
      final actions = ref.read(platformConfigActionsProvider);
      final detail = await api.itemDetail(item.id);
      final draft =
          detail.draftVersion ??
          (await actions.createDraft(item.id)).draftVersion;
      if (draft == null) return;
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => CatalogDialog(
          title: strings.tKey(PlatformAdminKeys.buttonItemPublish),
          body: Text(
            '${item.code} · v${draft.versionNo}',
            style: Catalog.text(12.5),
          ),
          actions: [
            CatalogButton(
              label: strings.tKey(CommonKeys.buttonCancel),
              secondary: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            CatalogButton(
              label: strings.tKey(PlatformAdminKeys.buttonPublish),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await actions.publishItem(item.id, draft.id);
      if (!mounted) return;
      _toast(strings.tKey(PlatformAdminKeys.toastItemPublished));
      ref.invalidate(itemsProvider);
    } catch (error) {
      if (!mounted) return;
      if (error is AppFailure && error.code == 'TRANSLATION_REVIEW_REQUIRED') {
        await showTranslationIssuesDialog(context, error);
        return;
      }
      _toast(strings.tKey(CommonKeys.stateError), error: true);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _retire(UiMessageStrings strings, PlatformItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CatalogDialog(
        title: strings.tKey(PlatformAdminKeys.buttonItemRetire),
        body: Text(
          strings.tKey(PlatformAdminKeys.dialogRetireConfirm),
          style: Catalog.body,
        ),
        actions: [
          CatalogButton(
            label: strings.tKey(CommonKeys.buttonCancel),
            secondary: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CatalogButton(
            label: strings.tKey(PlatformAdminKeys.buttonRetire),
            danger: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(platformConfigActionsProvider).retireItem(item.id);
      if (!mounted) return;
      _toast(strings.tKey(PlatformAdminKeys.toastItemRetired));
      ref.invalidate(itemsProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError), error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: error ? PtTheme.rose : PtTheme.deepGreen,
        content: Text(message, style: Catalog.text(12.5, color: PtTheme.white)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.strings,
    required this.wide,
    required this.onAdd,
  });

  final UiMessageStrings strings;
  final bool wide;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final block = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.tKey(PlatformAdminKeys.pageMasterLibraryHeading),
          style: Catalog.eyebrow,
        ),
        const SizedBox(height: 7),
        Text(
          strings.tKey(PlatformAdminKeys.pageChecklistItemsTitle),
          style: Catalog.pageTitle,
        ),
        const SizedBox(height: 4),
        Text(
          strings.tKey(PlatformAdminKeys.checklistItemsEmptyInitialBody),
          style: Catalog.body,
        ),
      ],
    );
    final add = CatalogButton(
      label: strings.tKey(PlatformAdminKeys.buttonItemAdd),
      icon: Icons.add_rounded,
      onPressed: onAdd,
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block,
          const SizedBox(height: 12),
          Align(alignment: AlignmentDirectional.centerStart, child: add),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: block),
        add,
      ],
    );
  }
}

class _HealthStrip extends StatelessWidget {
  const _HealthStrip({
    required this.strings,
    required this.count,
    required this.onOpen,
  });

  final UiMessageStrings strings;
  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Catalog.amberTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1DFC2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 17,
            color: PtTheme.gold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.tArgsKey(PlatformAdminKeys.checklistHealthAffectedCount, {
                'count': count,
              }),
              style: Catalog.text(
                11.5,
                weight: FontWeight.w700,
                color: const Color(0xFF7C4A05),
              ),
            ),
          ),
          CatalogButton(
            label: strings.tKey(
              PlatformAdminKeys.dashboardQuickActionsViewHealth,
            ),
            secondary: true,
            compact: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.strings,
    required this.controller,
    required this.onSearch,
    required this.categories,
    required this.categoryId,
    required this.status,
    required this.onCategory,
    required this.onStatus,
    required this.countLabel,
  });

  final UiMessageStrings strings;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final List<PlatformCategory> categories;
  final String categoryId;
  final String status;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onStatus;
  final String countLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 720;
        final search = CatalogSearch(
          controller: controller,
          hint: strings.tKey(PlatformAdminKeys.checklistBuilderSearchItems),
          onChanged: onSearch,
        );
        // Item lifecycle filter, not a taxonomy list: platform_items only ever
        // has these three statuses; labels resolve from the API.
        // gate-allow: codes
        final statusFilters = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final value in const ['', 'PUBLISHED', 'DRAFT', 'RETIRED'])
              _FilterPill(
                label: value.isEmpty
                    ? strings.tKey(CommonKeys.filterAll)
                    : checklistStatusLabel(ref, value),
                selected: status == value,
                onTap: () => onStatus(value),
              ),
          ],
        );
        final categoryFilters = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FilterPill(
              label: strings.tKey(PlatformAdminKeys.filterAllCategories),
              selected: categoryId.isEmpty,
              onTap: () => onCategory(''),
            ),
            for (final category in categories)
              _FilterPill(
                label: category.name,
                selected: categoryId == category.id,
                onTap: () => onCategory(category.id),
              ),
          ],
        );
        final filterStack = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unbounded width keeps the pills intrinsic; they stay visible and
            // only scroll if the viewport is too narrow for all four.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: statusFilters,
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: categoryFilters,
            ),
          ],
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 8), filterStack],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(width: 360, child: search),
                const Spacer(),
                Text(countLabel, style: Catalog.text(11, color: PtTheme.muted)),
              ],
            ),
            const SizedBox(height: 8),
            filterStack,
          ],
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      hoverColor: Catalog.neutralTint,
      child: Padding(
        // 7px above/below the 30px pill keeps the 44px touch target.
        padding: const EdgeInsetsDirectional.symmetric(vertical: 7),
        child: Container(
          height: 30,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? Catalog.tint : PtTheme.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? Catalog.tint : PtTheme.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Catalog.text(
              11,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? PtTheme.deepGreen : PtTheme.muted,
            ),
          ),
        ),
      ),
    ),
  );
}

class _IndexPane extends StatelessWidget {
  const _IndexPane({
    required this.strings,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final UiMessageStrings strings;
  final List<PlatformItem> items;
  final String? selectedId;
  final ValueChanged<PlatformItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return CatalogSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings.tKey(PlatformAdminKeys.tabChecklistItems),
                    style: Catalog.eyebrow,
                  ),
                ),
                Text(
                  strings.tArgsKey(
                    PlatformAdminKeys.pageChecklistItemsResultCount,
                    {'count': items.length},
                  ),
                  style: Catalog.text(10.5, color: PtTheme.muted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: PtTheme.border),
          for (final item in items)
            _ItemRow(
              strings: strings,
              item: item,
              selected: item.id == selectedId,
              onTap: () => onSelect(item),
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.strings,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final UiMessageStrings strings;
  final PlatformItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: selected
          ? Catalog.tint.withValues(alpha: 0.55)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: PtTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label.isNotEmpty ? item.label : item.code,
                      style: Catalog.text(12, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.code} · ${item.categoryLabelEn}',
                      style: Catalog.text(9.5, color: PtTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CatalogPill(
                label: checklistStatusLabel(ref, item.status),
                tone: item.status == 'PUBLISHED' || item.status == 'ACTIVE'
                    ? CatalogTone.good
                    : item.status == 'RETIRED'
                    ? CatalogTone.bad
                    : CatalogTone.warn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordPane extends ConsumerWidget {
  const _RecordPane({
    required this.strings,
    required this.item,
    required this.acting,
    required this.onEdit,
    required this.onDraft,
    required this.onPublish,
    required this.onRetire,
  });

  final UiMessageStrings strings;
  final PlatformItem item;
  final bool acting;
  final VoidCallback onEdit;
  final VoidCallback onDraft;
  final VoidCallback onPublish;
  final VoidCallback onRetire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final published = item.status.toUpperCase() == 'PUBLISHED';
    final retired = item.status.toUpperCase() == 'RETIRED';
    return CatalogSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.code,
                      style: Catalog.text(
                        10.5,
                        weight: FontWeight.w800,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label.isNotEmpty ? item.label : item.code,
                      style: Catalog.text(
                        20,
                        weight: FontWeight.w800,
                        tracking: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.categoryLabelEn,
                      style: Catalog.text(11, color: PtTheme.muted),
                    ),
                  ],
                ),
              ),
              CatalogPill(
                label: checklistStatusLabel(ref, item.status),
                tone: item.status == 'PUBLISHED' || item.status == 'ACTIVE'
                    ? CatalogTone.good
                    : retired
                    ? CatalogTone.bad
                    : CatalogTone.warn,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: PtTheme.border),
          const SizedBox(height: 12),
          _Fact(
            label: strings.tKey(PlatformAdminKeys.fieldItemCode),
            value: item.code,
          ),
          _Fact(
            label: strings.tKey(PlatformAdminKeys.fieldItemMeasurementUnit),
            value: item.measurementUnit.isEmpty ? '—' : item.measurementUnit,
          ),
          _Fact(
            label: strings.tKey(PlatformAdminKeys.fieldItemSensorTool),
            value: item.sensorTool.isEmpty ? '—' : item.sensorTool,
          ),
          _Fact(
            label: strings.tKey(PlatformAdminKeys.fieldItemStandardSpecEn),
            value: item.standardSpec.isEmpty ? '—' : item.standardSpec,
          ),
          _Fact(
            label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
            value: '${item.sortOrder}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (item.safetyCritical)
                CatalogPill(
                  label: strings.tKey(PlatformAdminKeys.badgeSafetyCritical),
                  tone: CatalogTone.bad,
                ),
              if (item.multiPoint)
                CatalogPill(
                  label: strings.tKey(PlatformAdminKeys.fieldItemMultiPoint),
                  tone: CatalogTone.info,
                ),
              if (item.allowFreeTextNote)
                CatalogPill(
                  label: strings.tKey(PlatformAdminKeys.fieldItemAllowFreeText),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CatalogButton(
                label: strings.tKey(CommonKeys.buttonEdit),
                icon: Icons.edit_outlined,
                secondary: true,
                onPressed: onEdit,
              ),
              if (item.draftVersionExists)
                CatalogButton(
                  label: strings.tKey(PlatformAdminKeys.buttonPublish),
                  icon: Icons.check_rounded,
                  onPressed: acting ? null : onPublish,
                )
              else
                CatalogButton(
                  label: strings.tKey(
                    PlatformAdminKeys.checklistEditorButtonCreateDraftToEdit,
                  ),
                  secondary: true,
                  onPressed: acting ? null : onDraft,
                ),
              if (!retired)
                CatalogButton(
                  label: strings.tKey(PlatformAdminKeys.buttonItemRetire),
                  danger: true,
                  onPressed: acting ? null : onRetire,
                ),
            ],
          ),
          if (published) ...[
            const SizedBox(height: 12),
            Text(
              strings.tKey(PlatformAdminKeys.alertVersionImmutable),
              style: Catalog.text(10.5, color: PtTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: Catalog.text(10.5, color: PtTheme.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: Catalog.text(11.5, weight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

extension on PlatformItem {
  bool get draftVersionExists => status.toUpperCase() == 'DRAFT';
}
