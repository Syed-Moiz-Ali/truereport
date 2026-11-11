import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  bool _busy = false;

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
    final weightController = TextEditingController(
      text: (category?.weightPercentage ?? 0).toString(),
    );
    final sortOrderController = TextEditingController(
      text: (category?.sortOrder ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();
    var active = category?.active ?? true;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                category == null ? l10n.addCategory : l10n.editCategory,
                style: PtTheme.font(
                  18,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InputField(
                          controller: codeController,
                          label: l10n.categoryCode,
                          validator: (value) => _required(value, l10n),
                        ),
                        const SizedBox(height: 12),
                        _InputField(
                          controller: nameEnController,
                          label: l10n.categoryNameEn,
                          validator: (value) => _required(value, l10n),
                        ),
                        const SizedBox(height: 12),
                        _InputField(
                          controller: nameArController,
                          label: l10n.categoryNameAr,
                          textDirection: TextDirection.rtl,
                          validator: (value) => _required(value, l10n),
                        ),
                        const SizedBox(height: 12),
                        _InputField(
                          controller: weightController,
                          label: l10n.categoryWeight,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(
                              (value ?? '').trim(),
                            );
                            if (parsed == null) {
                              return l10n.weightsInvalid;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _InputField(
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
                  ),
                ),
              ),
              actions: [
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
                  style: FilledButton.styleFrom(
                    backgroundColor: PtTheme.deepGreen,
                  ),
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
          },
        );
      },
    );

    final code = codeController.text.trim();
    final nameEn = nameEnController.text.trim();
    final nameAr = nameArController.text.trim();
    final weight = double.tryParse(weightController.text.trim()) ?? 0;
    final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;
    codeController.dispose();
    nameEnController.dispose();
    nameArController.dispose();
    weightController.dispose();
    sortOrderController.dispose();

    if (shouldSave != true) return;
    await _run(() async {
      await ref
          .read(platformConfigActionsProvider)
          .saveCategory(
            id: category?.id,
            code: code,
            nameEn: nameEn,
            nameAr: nameAr,
            weightPercentage: weight,
            sortOrder: sortOrder,
            active: active,
          );
    });
  }

  Future<void> _confirmRetire(PlatformCategory category) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.retireCategory,
            style: PtTheme.font(
              18,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Text(
                l10n.retireConfirm,
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
              ),
            ),
          ),
          actions: [
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
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: PtTheme.rose),
              child: Text(
                l10n.retireCategory,
                style: PtTheme.font(
                  13,
                  weight: FontWeight.w700,
                  color: PtTheme.white,
                ),
              ),
            ),
          ],
        );
      },
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
    final weightAsync = ref.watch(categoryWeightCheckProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      appBar: AppBar(
        backgroundColor: PtTheme.white,
        surfaceTintColor: PtTheme.white,
        foregroundColor: PtTheme.ink,
        title: Text(
          l10n.categoryManagement,
          style: PtTheme.font(18, weight: FontWeight.w700, color: PtTheme.ink),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: TextButton.icon(
              onPressed: _busy ? null : () => _showCategoryDialog(null),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: PtTheme.deepGreen,
              ),
              label: Text(
                l10n.addCategory,
                style: PtTheme.font(
                  13,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final horizontalPadding = constraints.maxWidth >= 900 ? 32.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.masterLibraryTitle,
                      style: PtTheme.font(
                        24,
                        lineHeight: 30,
                        weight: FontWeight.w800,
                        color: PtTheme.ink,
                        tracking: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.masterLibrarySubtitle,
                      style: PtTheme.font(
                        13,
                        lineHeight: 19,
                        color: PtTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    categoriesAsync.when(
                      loading: () => _StatePanel(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              color: PtTheme.deepGreen,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.loading,
                              style: PtTheme.font(13, color: PtTheme.muted),
                            ),
                          ],
                        ),
                      ),
                      error: (error, _) => _StatePanel(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 36,
                              color: PtTheme.rose,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _failureMessage(error),
                              textAlign: TextAlign.center,
                              style: PtTheme.font(
                                13,
                                lineHeight: 18,
                                color: PtTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  ref.invalidate(categoriesProvider),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                      data: (categories) {
                        if (categories.isEmpty) {
                          return _StatePanel(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.category_outlined,
                                  size: 38,
                                  color: PtTheme.muted,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l10n.noData,
                                  style: PtTheme.font(
                                    15,
                                    weight: FontWeight.w700,
                                    color: PtTheme.ink,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final ordered = [...categories]
                          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isWide)
                              _buildTable(l10n, ordered)
                            else
                              _buildCards(l10n, ordered),
                            const SizedBox(height: 16),
                            _buildWeightFooter(l10n, weightAsync),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTable(AppLocalizations l10n, List<PlatformCategory> ordered) {
    return Container(
      decoration: _surfaceDecoration(),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 22,
          headingTextStyle: PtTheme.font(
            11,
            weight: FontWeight.w700,
            color: PtTheme.muted,
            tracking: 0.4,
          ),
          dataTextStyle: PtTheme.font(13, color: PtTheme.ink),
          columns: [
            DataColumn(label: Text(l10n.categoryCode.toUpperCase())),
            DataColumn(label: Text(l10n.categoryNameEn.toUpperCase())),
            DataColumn(label: Text(l10n.categoryNameAr.toUpperCase())),
            DataColumn(label: Text(l10n.categoryWeight.toUpperCase())),
            DataColumn(label: Text(l10n.categoryOrder.toUpperCase())),
            DataColumn(label: Text(l10n.itemsTab.toUpperCase())),
            DataColumn(label: Text(l10n.status.toUpperCase())),
            DataColumn(label: Text(l10n.reorder.toUpperCase())),
            DataColumn(label: Text(l10n.edit.toUpperCase())),
          ],
          rows: [
            for (var index = 0; index < ordered.length; index++)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      ordered[index].code,
                      style: PtTheme.font(
                        12,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                  ),
                  DataCell(Text(ordered[index].nameEn)),
                  DataCell(
                    Text(
                      ordered[index].nameAr,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  DataCell(
                    Text('${_formatWeight(ordered[index].weightPercentage)}%'),
                  ),
                  DataCell(Text('${ordered[index].sortOrder}')),
                  DataCell(Text('${ordered[index].itemCount}')),
                  DataCell(_StatusChip(status: ordered[index].status)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _reorderButton(
                          icon: Icons.arrow_upward_rounded,
                          tooltip: l10n.reorder,
                          onPressed: index == 0
                              ? null
                              : () => _reorder(ordered, index, -1),
                        ),
                        _reorderButton(
                          icon: Icons.arrow_downward_rounded,
                          tooltip: l10n.reorder,
                          onPressed: index == ordered.length - 1
                              ? null
                              : () => _reorder(ordered, index, 1),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.edit,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: PtTheme.deepGreen,
                          ),
                          onPressed: _busy
                              ? null
                              : () => _showCategoryDialog(ordered[index]),
                        ),
                        IconButton(
                          tooltip: l10n.retireCategory,
                          icon: const Icon(
                            Icons.archive_outlined,
                            size: 17,
                            color: PtTheme.rose,
                          ),
                          onPressed: _busy
                              ? null
                              : () => _confirmRetire(ordered[index]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCards(AppLocalizations l10n, List<PlatformCategory> ordered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < ordered.length; index++) ...[
          Container(
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
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          ordered[index].code,
                          style: PtTheme.font(
                            12,
                            weight: FontWeight.w700,
                            color: PtTheme.muted,
                            tracking: 0.4,
                          ),
                        ),
                        _StatusChip(status: ordered[index].status),
                      ],
                    ),
                    _reorderButton(
                      icon: Icons.arrow_upward_rounded,
                      tooltip: l10n.reorder,
                      onPressed: index == 0
                          ? null
                          : () => _reorder(ordered, index, -1),
                    ),
                    _reorderButton(
                      icon: Icons.arrow_downward_rounded,
                      tooltip: l10n.reorder,
                      onPressed: index == ordered.length - 1
                          ? null
                          : () => _reorder(ordered, index, 1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ordered[index].nameEn,
                  style: PtTheme.font(
                    16,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
                if (ordered[index].nameAr.isNotEmpty)
                  Text(
                    ordered[index].nameAr,
                    textDirection: TextDirection.rtl,
                    style: PtTheme.font(13, color: PtTheme.muted),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaPill(
                      label: l10n.categoryWeight,
                      value:
                          '${_formatWeight(ordered[index].weightPercentage)}%',
                    ),
                    _MetaPill(
                      label: l10n.categoryOrder,
                      value: '${ordered[index].sortOrder}',
                    ),
                    _MetaPill(
                      label: l10n.itemsTab,
                      value: '${ordered[index].itemCount}',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _showCategoryDialog(ordered[index]),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: PtTheme.deepGreen,
                      ),
                      label: Text(
                        l10n.edit,
                        style: PtTheme.font(
                          12,
                          weight: FontWeight.w700,
                          color: PtTheme.deepGreen,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _confirmRetire(ordered[index]),
                      icon: const Icon(
                        Icons.archive_outlined,
                        size: 15,
                        color: PtTheme.rose,
                      ),
                      label: Text(
                        l10n.retireCategory,
                        style: PtTheme.font(
                          12,
                          weight: FontWeight.w700,
                          color: PtTheme.rose,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildWeightFooter(
    AppLocalizations l10n,
    AsyncValue<CategoryWeightCheck> weightAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: weightAsync.when(
        loading: () => Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: PtTheme.deepGreen,
              ),
            ),
            const SizedBox(width: 10),
            Text(l10n.loading, style: PtTheme.font(12, color: PtTheme.muted)),
          ],
        ),
        error: (error, _) => Text(
          _failureMessage(error),
          style: PtTheme.font(12, color: PtTheme.rose),
        ),
        data: (check) {
          final color = check.valid ? PtTheme.deepGreen : PtTheme.rose;
          final background = check.valid
              ? PtTheme.emerald.withValues(alpha: 0.12)
              : PtTheme.rose.withValues(alpha: 0.08);
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                l10n.weightTotal,
                style: PtTheme.font(
                  13,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      check.valid
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 16,
                      color: color,
                    ),
                    Text(
                      '${_formatWeight(check.total)} / '
                      '${_formatWeight(check.expected)}',
                      style: PtTheme.font(
                        12,
                        weight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      check.valid ? l10n.weightsValid : l10n.weightsInvalid,
                      style: PtTheme.font(
                        12,
                        weight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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

String _formatWeight(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String? _required(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) return l10n.required;
  return null;
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: PtTheme.font(12, color: PtTheme.muted),
    filled: true,
    fillColor: PtTheme.canvas,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PtTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PtTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: PtTheme.deepGreen, width: 1.5),
    ),
  );
}

String _failureMessage(Object error) {
  if (error is AppFailure) {
    return error.statusCode == null
        ? error.messageKey
        : '${error.messageKey} (${error.statusCode})';
  }
  return error.toString();
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.textDirection,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textDirection: textDirection,
      style: PtTheme.font(14, color: PtTheme.ink),
      decoration: _inputDecoration(label),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    Color foreground = PtTheme.muted;
    Color background = PtTheme.canvas;
    if (normalized == 'ACTIVE' || normalized == 'PUBLISHED') {
      foreground = PtTheme.deepGreen;
      background = PtTheme.emerald.withValues(alpha: 0.14);
    } else if (normalized == 'DRAFT') {
      foreground = PtTheme.amber;
      background = const Color(0xFFFFF7E6);
    } else if (normalized == 'RETIRED') {
      foreground = PtTheme.rose;
      background = PtTheme.rose.withValues(alpha: 0.08);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.isEmpty ? '—' : status,
        style: PtTheme.font(
          10,
          weight: FontWeight.w700,
          color: foreground,
          tracking: 0.4,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PtTheme.border),
      ),
      child: Text(
        '$label: $value',
        style: PtTheme.font(11, weight: FontWeight.w600, color: PtTheme.muted),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Center(child: child),
    );
  }
}
