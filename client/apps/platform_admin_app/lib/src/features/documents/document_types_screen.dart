import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class DocumentTypesScreen extends ConsumerWidget {
  const DocumentTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final types = ref.watch(documentTypesProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      appBar: AppBar(
        backgroundColor: PtTheme.white,
        foregroundColor: PtTheme.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.documentTypes,
          style: PtTheme.font(
            18,
            lineHeight: 24,
            weight: FontWeight.w800,
            color: PtTheme.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 28,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.documentTypes,
                                  style: PtTheme.font(
                                    compact ? 22 : 28,
                                    lineHeight: compact ? 28 : 34,
                                    weight: FontWeight.w800,
                                    color: PtTheme.ink,
                                    tracking: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.documentTypeCode,
                                  style: PtTheme.font(14, color: PtTheme.muted),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _edit(context, null),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l10n.addDocumentType),
                            style: FilledButton.styleFrom(
                              backgroundColor: PtTheme.deepGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      types.when(
                        loading: () => const _LoadingState(),
                        error: (error, stackTrace) => _ErrorState(
                          onRetry: () => ref.invalidate(documentTypesProvider),
                        ),
                        data: (items) => items.isEmpty
                            ? const _EmptyState()
                            : _DocumentTypesContent(
                                items: items,
                                onEdit: (item) => _edit(context, item),
                                onRetire: (item) => _retire(context, ref, item),
                                onMove: (index, delta) =>
                                    _reorder(context, ref, items, index, delta),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, ReportDocumentType? initial) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DocumentTypeDialog(initial: initial),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).save),
          backgroundColor: PtTheme.deepGreen,
        ),
      );
    }
  }

  Future<void> _retire(
    BuildContext context,
    WidgetRef ref,
    ReportDocumentType item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.retired),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Text(
              l10n.retireConfirm,
              style: PtTheme.font(14, color: PtTheme.muted),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: PtTheme.rose),
            child: Text(l10n.retire),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(platformConfigActionsProvider).retireDocumentType(item.id);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.genericError)));
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    List<ReportDocumentType> items,
    int index,
    int delta,
  ) async {
    final target = index + delta;
    if (target < 0 || target >= items.length) return;
    final ids = items.map((item) => item.id).toList();
    final id = ids.removeAt(index);
    ids.insert(target, id);
    try {
      await ref.read(platformConfigApiProvider).reorderDocumentTypes(ids);
      if (!context.mounted) return;
      ref.invalidate(documentTypesProvider);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).genericError)),
      );
    }
  }
}

class _DocumentTypesContent extends StatelessWidget {
  const _DocumentTypesContent({
    required this.items,
    required this.onEdit,
    required this.onRetire,
    required this.onMove,
  });

  final List<ReportDocumentType> items;
  final ValueChanged<ReportDocumentType> onEdit;
  final ValueChanged<ReportDocumentType> onRetire;
  final void Function(int index, int delta) onMove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          return _DocumentTypesTable(
            items: items,
            onEdit: onEdit,
            onRetire: onRetire,
            onMove: onMove,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _DocumentTypeCard(
                item: items[index],
                canMoveUp: index > 0,
                canMoveDown: index < items.length - 1,
                onEdit: () => onEdit(items[index]),
                onRetire: () => onRetire(items[index]),
                onUp: () => onMove(index, -1),
                onDown: () => onMove(index, 1),
              ),
              if (index != items.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _DocumentTypesTable extends StatelessWidget {
  const _DocumentTypesTable({
    required this.items,
    required this.onEdit,
    required this.onRetire,
    required this.onMove,
  });

  final List<ReportDocumentType> items;
  final ValueChanged<ReportDocumentType> onEdit;
  final ValueChanged<ReportDocumentType> onRetire;
  final void Function(int index, int delta) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.documentTypeCode)),
            DataColumn(label: Text(l10n.labelEn)),
            DataColumn(label: Text(l10n.labelAr)),
            DataColumn(label: Text(l10n.required)),
            DataColumn(label: Text(l10n.status)),
            const DataColumn(label: Text('Order')),
            DataColumn(label: Text(l10n.actions)),
          ],
          rows: [
            for (var index = 0; index < items.length; index++)
              DataRow(
                cells: [
                  DataCell(Text(items[index].code)),
                  DataCell(Text(items[index].nameEn)),
                  DataCell(Text(items[index].nameAr)),
                  DataCell(Text(items[index].required ? l10n.required : '-')),
                  DataCell(_StatusChip(status: items[index].status)),
                  DataCell(Text('${items[index].sortOrder}')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Up',
                          onPressed: index > 0 ? () => onMove(index, -1) : null,
                          icon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Down',
                          onPressed: index < items.length - 1
                              ? () => onMove(index, 1)
                              : null,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.edit,
                          onPressed: () => onEdit(items[index]),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: l10n.retire,
                          onPressed: () => onRetire(items[index]),
                          icon: const Icon(
                            Icons.archive_outlined,
                            size: 18,
                            color: PtTheme.rose,
                          ),
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
}

class _DocumentTypeCard extends StatelessWidget {
  const _DocumentTypeCard({
    required this.item,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onEdit,
    required this.onRetire,
    required this.onUp,
    required this.onDown,
  });

  final ReportDocumentType item;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onRetire;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CodeChip(label: item.code),
              _StatusChip(status: item.status),
              if (item.required)
                _InfoChip(label: l10n.required, color: PtTheme.deepGreen),
              Text(
                'Order: ${item.sortOrder}',
                style: PtTheme.font(11, color: PtTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.nameEn,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          if (item.nameAr.isNotEmpty)
            Text(
              item.nameAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: 'Up',
                onPressed: canMoveUp ? onUp : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
              ),
              IconButton(
                tooltip: 'Down',
                onPressed: canMoveDown ? onDown : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.edit),
              ),
              TextButton.icon(
                onPressed: onRetire,
                icon: const Icon(
                  Icons.archive_outlined,
                  size: 16,
                  color: PtTheme.rose,
                ),
                label: Text(
                  l10n.retire,
                  style: PtTheme.font(13, color: PtTheme.rose),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentTypeDialog extends ConsumerStatefulWidget {
  const _DocumentTypeDialog({this.initial});

  final ReportDocumentType? initial;

  @override
  ConsumerState<_DocumentTypeDialog> createState() =>
      _DocumentTypeDialogState();
}

class _DocumentTypeDialogState extends ConsumerState<_DocumentTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;
  late final TextEditingController _sortOrderController;
  late bool _required;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _codeController = TextEditingController(text: initial?.code ?? '');
    _nameEnController = TextEditingController(text: initial?.nameEn ?? '');
    _nameArController = TextEditingController(text: initial?.nameAr ?? '');
    _sortOrderController = TextEditingController(
      text: '${initial?.sortOrder ?? 0}',
    );
    _required = initial?.required ?? false;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(platformConfigActionsProvider)
          .saveDocumentType(
            id: widget.initial?.id,
            code: _codeController.text.trim(),
            nameEn: _nameEnController.text.trim(),
            nameAr: _nameArController.text.trim(),
            required: _required,
            sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey);
    } catch (_) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context).genericError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.initial == null ? l10n.addDocumentType : l10n.documentTypes,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(
                  controller: _codeController,
                  label: l10n.documentTypeCode,
                  requiredMessage: l10n.required,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _nameEnController,
                  label: l10n.labelEn,
                  requiredMessage: l10n.required,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _nameArController,
                  label: l10n.labelAr,
                  requiredMessage: l10n.required,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: _sortOrderController,
                  label: 'Order',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _required,
                  onChanged: (value) => setState(() => _required = value),
                  title: Text(l10n.required),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: PtTheme.deepGreen),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PtTheme.white,
                  ),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    this.requiredMessage,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? requiredMessage;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: PtTheme.font(14, color: PtTheme.ink),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (value) {
        if (requiredMessage != null &&
            (value == null || value.trim().isEmpty)) {
          return requiredMessage;
        }
        return null;
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = switch (status) {
      'ACTIVE' => PtTheme.emerald,
      'RETIRED' => PtTheme.rose,
      _ => PtTheme.muted,
    };
    final label = switch (status) {
      'ACTIVE' => l10n.active,
      'RETIRED' => l10n.retired,
      _ => status,
    };
    return _InfoChip(label: label, color: color);
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PtTheme.border),
      ),
      child: Text(
        label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: PtTheme.muted,
          tracking: 0.4,
        ),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
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
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.rose.withValues(alpha: 0.4)),
      ),
      child: Column(
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 36,
            color: PtTheme.muted,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noData,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
