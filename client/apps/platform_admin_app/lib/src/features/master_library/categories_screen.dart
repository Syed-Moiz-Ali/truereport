import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_states.dart';
import '../../components/platform_toolbar.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../checklist/checklist_page_frame.dart';
import '../checklist/checklist_tab_bar.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  bool _busy = false;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _status = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
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

  Future<void> _showCategoryDialog(PlatformCategory? category) async {
    final l10n = AppLocalizations.of(context);
    final codeController = TextEditingController(text: category?.code ?? '');
    final nameEnController = TextEditingController(
      text: category?.nameEn ?? '',
    );
    final nameArController = TextEditingController(
      text: category?.nameAr ?? '',
    );
    final sortOrderController = TextEditingController(
      text: (category?.sortOrder ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();
    var active = category?.active ?? true;

    final shouldSave = await showPlatformDialog<bool>(
      context: context,
      title: category == null ? l10n.addCategory : l10n.editCategory,
      body: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlatformTextField(
                  controller: codeController,
                  label: l10n.categoryCode,
                  validator: (value) => _required(value, l10n),
                ),
                const SizedBox(height: 12),
                PlatformTextField(
                  controller: nameEnController,
                  label: l10n.categoryNameEn,
                  validator: (value) => _required(value, l10n),
                ),
                const SizedBox(height: 12),
                PlatformTextField(
                  controller: nameArController,
                  label: l10n.categoryNameAr,
                  textDirection: TextDirection.rtl,
                  validator: (value) => _required(value, l10n),
                ),
                const SizedBox(height: 12),
                PlatformTextField(
                  controller: sortOrderController,
                  label: l10n.categoryOrder,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (int.tryParse((value ?? '').trim()) == null) {
                      return l10n.categoryOrder;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: PtTheme.deepGreen,
                  title: Text(
                    l10n.active,
                    style: PtTheme.font(
                      13,
                      weight: FontWeight.w600,
                      color: PtTheme.ink,
                    ),
                  ),
                  value: active,
                  onChanged: (value) {
                    setDialogState(() => active = value);
                  },
                ),
              ],
            ),
          );
        },
      ),
      actionsBuilder: (dialogContext) => [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            l10n.cancel,
            style: PtTheme.font(
              13,
              weight: FontWeight.w700,
              color: PtTheme.muted,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.of(dialogContext).pop(true);
          },
          style: FilledButton.styleFrom(backgroundColor: PtTheme.deepGreen),
          child: Text(
            l10n.save,
            style: PtTheme.font(
              13,
              weight: FontWeight.w700,
              color: PtTheme.white,
            ),
          ),
        ),
      ],
    );

    final code = codeController.text.trim();
    final nameEn = nameEnController.text.trim();
    final nameAr = nameArController.text.trim();
    final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      codeController.dispose();
      nameEnController.dispose();
      nameArController.dispose();
      sortOrderController.dispose();
    });

    if (shouldSave != true) return;
    await _run(() async {
      await ref
          .read(platformConfigActionsProvider)
          .saveCategory(
            id: category?.id,
            code: code,
            nameEn: nameEn,
            nameAr: nameAr,
            sortOrder: sortOrder,
            active: active,
          );
    });
  }

  Future<void> _confirmRetire(PlatformCategory category) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: l10n.retireCategory,
      body: l10n.retireConfirm,
      confirmLabel: l10n.retireCategory,
      destructive: true,
    );
    if (confirmed != true) return;
    await _run(() async {
      await ref.read(platformConfigActionsProvider).retireCategory(category.id);
    });
  }

  Future<void> _reorder(
    List<PlatformCategory> ordered,
    int index,
    int delta,
  ) async {
    final target = index + delta;
    if (target < 0 || target >= ordered.length) return;
    final ids = ordered.map((category) => category.id).toList();
    final moved = ids.removeAt(index);
    ids.insert(target, moved);
    await _run(() async {
      await ref.read(platformConfigActionsProvider).reorderCategories(ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return ChecklistPageFrame(
      currentRoute: '/checklist/categories',
      currentTab: ChecklistTab.categories,
      showSearch: false,
      actions: [
        PlatformPrimaryButton(
          label: l10n.addCategory,
          icon: Icons.add_rounded,
          onPressed: _busy ? null : () => _showCategoryDialog(null),
        ),
      ],
      child: categoriesAsync.when(
        loading: () => PlatformLoadingView(message: l10n.loading),
        error: (error, _) => PlatformErrorView(
          message: _failureMessage(error),
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) {
          final ordered = [...categories]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final query = _search.trim().toLowerCase();
          final filtered = ordered
              .where((category) {
                if (_status.isNotEmpty && category.status != _status) {
                  return false;
                }
                if (query.isEmpty) return true;
                return category.code.toLowerCase().contains(query) ||
                    category.nameEn.toLowerCase().contains(query) ||
                    category.nameAr.contains(_search.trim());
              })
              .toList(growable: false);
          final countLabel = query.isEmpty && _status.isEmpty
              ? '${ordered.length}'
              : '${filtered.length} / ${ordered.length}';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlatformToolbar(
                searchController: _searchController,
                searchHint: l10n.search,
                onSearchChanged: (value) => setState(() => _search = value),
                countLabel: countLabel,
                filters: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: PlatformDropdown<String>(
                      label: l10n.status,
                      value: _status,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(l10n.filterAll),
                        ),
                        DropdownMenuItem(
                          value: 'ACTIVE',
                          child: Text(l10n.active),
                        ),
                        DropdownMenuItem(
                          value: 'RETIRED',
                          child: Text(l10n.retired),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _status = value ?? '');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                PlatformEmptyView(
                  icon: Icons.category_outlined,
                  title: l10n.noData,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 1000;
                    if (!twoColumns) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var index = 0;
                            index < filtered.length;
                            index++
                          ) ...[
                            _buildCategoryCard(l10n, filtered, ordered, index),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }
                    final rows = <Widget>[];
                    for (var index = 0; index < filtered.length; index += 2) {
                      rows.add(
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildCategoryCard(
                                l10n,
                                filtered,
                                ordered,
                                index,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: index + 1 < filtered.length
                                  ? _buildCategoryCard(
                                      l10n,
                                      filtered,
                                      ordered,
                                      index + 1,
                                    )
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
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    AppLocalizations l10n,
    List<PlatformCategory> visible,
    List<PlatformCategory> ordered,
    int visibleIndex,
  ) {
    final category = visible[visibleIndex];
    final orderedIndex = ordered.indexWhere((item) => item.id == category.id);
    final canMoveUp = orderedIndex > 0;
    final canMoveDown = orderedIndex >= 0 && orderedIndex < ordered.length - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    category.code,
                    style: PtTheme.font(
                      12,
                      weight: FontWeight.w700,
                      color: PtTheme.muted,
                      tracking: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  PlatformStatusChip(status: category.status),
                ],
              ),
              Wrap(
                spacing: 0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _reorderButton(
                    icon: Icons.arrow_upward_rounded,
                    tooltip: l10n.reorder,
                    onPressed: canMoveUp
                        ? () => _reorder(ordered, orderedIndex, -1)
                        : null,
                  ),
                  _reorderButton(
                    icon: Icons.arrow_downward_rounded,
                    tooltip: l10n.reorder,
                    onPressed: canMoveDown
                        ? () => _reorder(ordered, orderedIndex, 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            category.nameEn.isEmpty ? category.code : category.nameEn,
            style: PtTheme.font(
              16,
              lineHeight: 22,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (category.nameAr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              category.nameAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              PlatformMetaPill(
                label: l10n.categoryOrder,
                value: '${category.sortOrder}',
              ),
              PlatformMetaPill(
                label: l10n.itemsTab,
                value: '${category.itemCount}',
              ),
              PlatformMetaPill(label: l10n.status, value: category.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlatformSecondaryButton(
                label: l10n.edit,
                icon: Icons.edit_outlined,
                onPressed: _busy ? null : () => _showCategoryDialog(category),
              ),
              PlatformSecondaryButton(
                label: l10n.retireCategory,
                icon: Icons.archive_outlined,
                destructive: true,
                onPressed: _busy ? null : () => _confirmRetire(category),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reorderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 18,
        color: onPressed == null ? PtTheme.border : PtTheme.muted,
      ),
      onPressed: _busy ? null : onPressed,
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

String? _required(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) return l10n.required;
  return null;
}

String _failureMessage(Object error) {
  if (error is AppFailure) {
    return error.statusCode == null
        ? error.messageKey
        : '${error.messageKey} (${error.statusCode})';
  }
  return error.toString();
}
