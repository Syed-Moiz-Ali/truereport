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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Catalog.maxWidth),
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
                                compact: !wide,
                                onUp: () => _move(strings, categories, i, -1),
                                onDown: () => _move(strings, categories, i, 1),
                                onEdit: () =>
                                    _editDialog(strings, categories[i]),
                                onRetire: () => _retire(strings, categories[i]),
                                onActivate: () =>
                                    _activate(strings, categories[i]),
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
            ),
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
    final result = await showDialog<_CategoryDraft>(
      context: context,
      builder: (dialogContext) =>
          _CategoryDialog(strings: strings, category: category),
    );
    if (result == null) return;
    try {
      await ref
          .read(platformConfigActionsProvider)
          .saveCategory(
            id: category?.id,
            code: result.code,
            name: result.name,
            sortOrder: result.order,
            active: true,
          );
      ref.invalidate(categoriesProvider);
    } catch (error) {
      if (mounted) await _saveFailure(strings, error);
    }
  }

  /// Opens the review desk for a publish gate, otherwise keeps the existing
  /// generic failure toast.
  Future<void> _saveFailure(UiMessageStrings strings, Object error) async {
    if (error is AppFailure && error.code == 'TRANSLATION_REVIEW_REQUIRED') {
      await showTranslationIssuesDialog(context, error);
      return;
    }
    _toast(strings.tKey(CommonKeys.stateError));
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
    } catch (error) {
      if (mounted) await _saveFailure(strings, error);
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

class _CategoryDraft {
  const _CategoryDraft({
    required this.code,
    required this.name,
    required this.order,
  });

  final String code;
  final String name;
  final int order;
}

/// Create/edit a category with one obvious field.
///
/// The code used to be typed by hand; it is now derived from the name as an
/// upper-snake slug and stays editable for anyone who needs a specific code.
class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.strings, this.category});

  final UiMessageStrings strings;
  final PlatformCategory? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _order;
  bool _codeTouched = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _name = TextEditingController(text: category?.name ?? '');
    _code = TextEditingController(text: category?.code ?? '');
    _order = TextEditingController(text: '${category?.sortOrder ?? 0}');
    _name.addListener(_syncCodeFromName);
  }

  @override
  void dispose() {
    _name
      ..removeListener(_syncCodeFromName)
      ..dispose();
    _code.dispose();
    _order.dispose();
    super.dispose();
  }

  void _syncCodeFromName() {
    if (_codeTouched) return;
    final next = _slug(_name.text);
    if (next == _code.text) return;
    _code.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  static String _slug(String value) => value
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      _CategoryDraft(
        code: _code.text.trim(),
        name: _name.text.trim(),
        order: int.tryParse(_order.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return CatalogDialog(
      title: strings.tKey(
        widget.category == null
            ? PlatformAdminKeys.buttonCategoryAdd
            : PlatformAdminKeys.dialogCategoryEditTitle,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            CatalogField(
              controller: _name,
              label: strings.tKey(PlatformAdminKeys.fieldCategoryNameEn),
              hint: strings.tKey(PlatformAdminKeys.fieldCategoryNameEn),
              autofocus: widget.category == null,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? strings.tKey(CommonKeys.validationRequiredField)
                  : null,
            ),
            const SizedBox(height: 12),
            CatalogField(
              controller: _code,
              label: strings.tKey(PlatformAdminKeys.fieldCategoryCode),
              helper: strings.tKey(PlatformAdminKeys.fieldCategoryCodeHelper),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? strings.tKey(CommonKeys.validationRequiredField)
                  : null,
              onChanged: (_) => _codeTouched = true,
            ),
            const SizedBox(height: 12),
            CatalogField(
              controller: _order,
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        CatalogButton(
          key: const Key('category-dialog-save'),
          label: strings.tKey(CommonKeys.buttonSave),
          onPressed: _submit,
        ),
      ],
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
    required this.compact,
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
  final bool compact;
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onItems,
        hoverColor: Catalog.neutralTint.withValues(alpha: 0.55),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: PtTheme.border)),
          ),
          child: Row(
            children: [
              Tooltip(
                message: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
                child: SizedBox(
                  width: 34,
                  child: Text(
                    '#${category.sortOrder}',
                    style: Catalog.text(
                      10.5,
                      weight: FontWeight.w700,
                      tabular: true,
                      color: PtTheme.muted,
                    ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Catalog.text(13.5, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.code} · ${strings.tArgsKey(PlatformAdminKeys.checklistCategoriesItemCount, {'count': category.itemCount})}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Catalog.text(10.5, color: PtTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Every live category used to carry an identical "Active" pill;
              // only the retired ones need to say something.
              if (!active)
                CatalogPill(
                  label: checklistStatusLabel(ref, category.status),
                  tone: CatalogTone.bad,
                ),
              const SizedBox(width: 6),
              if (compact) ...[
                _Icon(
                  icon: Icons.visibility_outlined,
                  tooltip: strings.tKey(
                    PlatformAdminKeys.checklistCategoriesButtonViewItems,
                  ),
                  onPressed: onItems,
                ),
                PopupMenuButton<String>(
                  tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 19,
                    color: PtTheme.muted,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    switch (value) {
                      case 'up':
                        onUp();
                      case 'down':
                        onDown();
                      case 'edit':
                        onEdit();
                      case 'toggle':
                        active ? onRetire() : onActivate();
                    }
                  },
                  itemBuilder: (context) => [
                    _menuItem(
                      strings,
                      value: 'up',
                      icon: Icons.arrow_upward_rounded,
                      label: CommonKeys.buttonMoveUp,
                      enabled: !busy && !first,
                    ),
                    _menuItem(
                      strings,
                      value: 'down',
                      icon: Icons.arrow_downward_rounded,
                      label: CommonKeys.buttonMoveDown,
                      enabled: !busy && !last,
                    ),
                    _menuItem(
                      strings,
                      value: 'edit',
                      icon: Icons.edit_outlined,
                      label: CommonKeys.buttonEdit,
                      enabled: !busy,
                    ),
                    _menuItem(
                      strings,
                      value: 'toggle',
                      icon: active
                          ? Icons.block_outlined
                          : Icons.check_circle_outlined,
                      label: active
                          ? PlatformAdminKeys.dialogCategoryRetireTitle
                          : PlatformAdminKeys.buttonContentActivate,
                      enabled: !busy,
                      danger: active,
                    ),
                  ],
                ),
              ] else ...[
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
                  icon: active
                      ? Icons.block_outlined
                      : Icons.check_circle_outlined,
                  tooltip: strings.tKey(
                    active
                        ? PlatformAdminKeys.dialogCategoryRetireTitle
                        : PlatformAdminKeys.buttonContentActivate,
                  ),
                  danger: active,
                  onPressed: active ? onRetire : onActivate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    UiMessageStrings strings, {
    required String value,
    required IconData icon,
    required UiMessageKey label,
    required bool enabled,
    bool danger = false,
  }) {
    final color = danger ? PtTheme.rose : PtTheme.ink;
    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 17, color: enabled ? color : PtTheme.muted),
          const SizedBox(width: 10),
          Text(
            strings.tKey(label),
            style: Catalog.text(13, weight: FontWeight.w600, color: color),
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
      icon: Icon(icon, size: 19),
      color: danger ? PtTheme.rose : PtTheme.muted,
      onPressed: onPressed,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      padding: EdgeInsets.zero,
    ),
  );
}
