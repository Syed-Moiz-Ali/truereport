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

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
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
                onAdd: () => _editDialog(strings),
              ),
              const SizedBox(height: 12),
              CatalogTabs(
                labels: [
                  strings.tKey(PlatformAdminKeys.tabChecklistItems),
                  strings.tKey(PlatformAdminKeys.tabChecklistCategories),
                  strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
                ],
                selected: 1,
                onSelected: (index) {
                  if (index == 0) context.go('/checklist/items');
                  if (index == 2) context.go('/checklist/option-sets');
                },
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                loading: () => const CatalogSkeleton(),
                error: (_, _) => CatalogError(
                  strings: strings,
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
                data: (categories) {
                  if (categories.isEmpty) {
                    return CatalogSurface(
                      child: CatalogEmpty(
                        title: strings.tKey(
                          PlatformAdminKeys.checklistCategoriesEmptyTitle,
                        ),
                        body: strings.tKey(
                          PlatformAdminKeys.checklistCategoriesEmptyBody,
                        ),
                        actionLabel: strings.tKey(
                          PlatformAdminKeys.buttonCategoryAdd,
                        ),
                        onAction: () => _editDialog(strings),
                      ),
                    );
                  }
                  return CatalogSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < categories.length; i++)
                          _CategoryRow(
                            strings: strings,
                            category: categories[i],
                            busy: _busy,
                            first: i == 0,
                            last: i == categories.length - 1,
                            onUp: () => _move(strings, categories, i, -1),
                            onDown: () => _move(strings, categories, i, 1),
                            onEdit: () => _editDialog(strings, categories[i]),
                            onRetire: () => _retire(strings, categories[i]),
                            onActivate: () => _activate(strings, categories[i]),
                            onItems: () => context.go(
                              '/checklist/items?category=${categories[i].id}',
                            ),
                          ),
                      ],
                    ),
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
      currentRoute: '/checklist/categories',
      onNavigate: (route) => context.go(route),
      child: content,
    );
  }

  Future<void> _editDialog(
    UiMessageStrings strings, [
    PlatformCategory? category,
  ]) async {
    final code = TextEditingController(text: category?.code ?? '');
    final name = TextEditingController(text: category?.name ?? '');
    final order = TextEditingController(text: '${category?.sortOrder ?? 0}');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CatalogDialog(
        title: strings.tKey(
          category == null
              ? PlatformAdminKeys.buttonCategoryAdd
              : PlatformAdminKeys.dialogCategoryEditTitle,
        ),
        body: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CatalogField(
                controller: code,
                label: strings.tKey(PlatformAdminKeys.fieldCategoryCode),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
              const SizedBox(height: 12),
              CatalogField(
                controller: name,
                label: strings.tKey(PlatformAdminKeys.fieldCategoryNameEn),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
              const SizedBox(height: 12),
              CatalogField(
                controller: order,
                label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse((value ?? '').trim()) == null
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          CatalogButton(
            label: strings.tKey(CommonKeys.buttonCancel),
            secondary: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CatalogButton(
            label: strings.tKey(CommonKeys.buttonSave),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(dialogContext).pop(true);
            },
          ),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await ref
          .read(platformConfigActionsProvider)
          .saveCategory(
            id: category?.id,
            code: code.text.trim(),
            name: name.text.trim(),
            sortOrder: int.tryParse(order.text.trim()) ?? 0,
            active: true,
          );
      ref.invalidate(categoriesProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    }
  }

  Future<void> _retire(
    UiMessageStrings strings,
    PlatformCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CatalogDialog(
        title: strings.tKey(PlatformAdminKeys.dialogCategoryRetireTitle),
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
      await ref.read(platformConfigActionsProvider).retireCategory(category.id);
      ref.invalidate(categoriesProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    }
  }

  Future<void> _activate(
    UiMessageStrings strings,
    PlatformCategory category,
  ) async {
    try {
      await ref
          .read(platformConfigActionsProvider)
          .saveCategory(
            id: category.id,
            code: category.code,
            name: category.name,
            sortOrder: category.sortOrder,
            active: true,
          );
      ref.invalidate(categoriesProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    }
  }

  Future<void> _move(
    UiMessageStrings strings,
    List<PlatformCategory> categories,
    int index,
    int delta,
  ) async {
    final target = index + delta;
    if (target < 0 || target >= categories.length || _busy) return;
    final ids = categories.map((category) => category.id).toList();
    final moved = ids.removeAt(index);
    ids.insert(target, moved);
    setState(() => _busy = true);
    try {
      await ref.read(platformConfigActionsProvider).reorderCategories(ids);
      ref.invalidate(categoriesProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: PtTheme.rose,
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
          strings.tKey(PlatformAdminKeys.tabChecklistCategories),
          style: Catalog.pageTitle,
        ),
        const SizedBox(height: 4),
        Text(
          strings.tKey(PlatformAdminKeys.checklistCategoriesEmptyBody),
          style: Catalog.body,
        ),
      ],
    );
    final add = CatalogButton(
      label: strings.tKey(PlatformAdminKeys.buttonCategoryAdd),
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

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({
    required this.strings,
    required this.category,
    required this.busy,
    required this.first,
    required this.last,
    required this.onUp,
    required this.onDown,
    required this.onEdit,
    required this.onRetire,
    required this.onActivate,
    required this.onItems,
  });

  final UiMessageStrings strings;
  final PlatformCategory category;
  final bool busy;
  final bool first;
  final bool last;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onEdit;
  final VoidCallback onRetire;
  final VoidCallback onActivate;
  final VoidCallback onItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active =
        category.active && category.status.toUpperCase() != 'RETIRED';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PtTheme.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${category.sortOrder}',
              style: Catalog.text(
                10.5,
                weight: FontWeight.w700,
                tabular: true,
                color: PtTheme.muted,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  style: Catalog.text(12.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${category.code} · ${strings.tArgsKey(PlatformAdminKeys.checklistCategoriesItemCount, {'count': category.itemCount})}',
                  style: Catalog.text(10, color: PtTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CatalogPill(
            label: checklistStatusLabel(ref, category.status),
            tone: active ? CatalogTone.good : CatalogTone.bad,
          ),
          const SizedBox(width: 6),
          _Icon(
            icon: Icons.arrow_upward_rounded,
            tooltip: strings.tKey(CommonKeys.buttonMoveUp),
            onPressed: busy || first ? null : onUp,
          ),
          _Icon(
            icon: Icons.arrow_downward_rounded,
            tooltip: strings.tKey(CommonKeys.buttonMoveDown),
            onPressed: busy || last ? null : onDown,
          ),
          _Icon(
            icon: Icons.visibility_outlined,
            tooltip: strings.tKey(
              PlatformAdminKeys.checklistCategoriesButtonViewItems,
            ),
            onPressed: onItems,
          ),
          _Icon(
            icon: Icons.edit_outlined,
            tooltip: strings.tKey(CommonKeys.buttonEdit),
            onPressed: onEdit,
          ),
          _Icon(
            icon: active ? Icons.block_outlined : Icons.check_circle_outlined,
            tooltip: strings.tKey(
              active
                  ? PlatformAdminKeys.dialogCategoryRetireTitle
                  : PlatformAdminKeys.buttonContentActivate,
            ),
            danger: active,
            onPressed: active ? onRetire : onActivate,
          ),
        ],
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: IconButton(
      icon: Icon(icon, size: 18),
      color: danger ? PtTheme.rose : PtTheme.muted,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    ),
  );
}
