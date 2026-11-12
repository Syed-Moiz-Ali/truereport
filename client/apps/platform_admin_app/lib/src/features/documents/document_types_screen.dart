import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_context_bar.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class DocumentTypesScreen extends ConsumerWidget {
  const DocumentTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return PlatformShell(
      currentRoute: '/reports/document-types',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(label: l10n.reportsTitle),
          ContextBreadcrumbItem(label: l10n.reportDocuments),
        ],
      ),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: l10n.reportsTitle,
              subtitle: l10n.documentTypes,
              actions: [
                PlatformPrimaryButton(
                  label: l10n.addDocumentType,
                  icon: Icons.add_rounded,
                  onPressed: () => showDocumentTypeDialog(context, null),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const DocumentTypesSection(),
          ],
        ),
      ),
    );
  }
}

/// Shows the add/edit dialog for a report document type.
///
/// Shared by [DocumentTypesScreen] and [ReportsScreen] headers so the single
/// primary action per section opens the same editor. Data wiring is unchanged.
Future<void> showDocumentTypeDialog(
  BuildContext context,
  ReportDocumentType? initial,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: _DocumentTypeDialog(initial: initial),
    ),
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

/// Reusable "Report Documents" section: data wiring plus the management UI
/// (table/cards with code, EN/AR name, required, active, order plus
/// add/edit/reorder/retire).
///
/// Extracted so the Reports landing can append future report settings as
/// additional sections below without duplicating data logic. All
/// providers, APIs, dialogs and validators are identical to the previous
/// single-section page.
class DocumentTypesSection extends ConsumerWidget {
  const DocumentTypesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final types = ref.watch(documentTypesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformSectionHeader(title: l10n.reportDocuments),
        const SizedBox(height: 12),
        types.when(
          loading: () => const PlatformLoadingView(),
          error: (error, stackTrace) => PlatformErrorView(
            message: l10n.unhealthy,
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(documentTypesProvider),
          ),
          data: (items) => items.isEmpty
              ? PlatformEmptyView(
                  icon: Icons.description_outlined,
                  title: l10n.noData,
                )
              : _DocumentTypesContent(
                  items: items,
                  onEdit: (item) => showDocumentTypeDialog(context, item),
                  onRetire: (item) => _retire(context, ref, item),
                  onMove: (index, delta) =>
                      _reorder(context, ref, items, index, delta),
                ),
        ),
      ],
    );
  }

  Future<void> _retire(
    BuildContext context,
    WidgetRef ref,
    ReportDocumentType item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: l10n.retired,
      body: l10n.retireConfirm,
      confirmLabel: l10n.retire,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
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

String _statusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'ACTIVE':
      return l10n.active;
    case 'RETIRED':
      return l10n.retired;
    default:
      return status;
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
    return PlatformSectionCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.documentTypeCode)),
            DataColumn(
              label: Text(
                l10n.labelEn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataColumn(
              label: Text(
                l10n.labelAr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataColumn(label: Text(l10n.required)),
            DataColumn(label: Text(l10n.status)),
            DataColumn(label: Text(l10n.categoryOrder)),
            DataColumn(label: Text(l10n.actions)),
          ],
          rows: [
            for (var index = 0; index < items.length; index++)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      items[index].code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      items[index].nameEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      items[index].nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(Text(items[index].required ? l10n.required : '-')),
                  DataCell(
                    PlatformStatusChip(
                      status: _statusLabel(l10n, items[index].status),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${items[index].sortOrder}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.moveUp,
                          onPressed: index > 0 ? () => onMove(index, -1) : null,
                          icon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.moveDown,
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
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlatformMetaPill(label: l10n.documentTypeCode, value: item.code),
              PlatformStatusChip(status: _statusLabel(l10n, item.status)),
              if (item.required) PlatformStatusChip(status: l10n.required),
              PlatformMetaPill(
                label: l10n.categoryOrder,
                value: '${item.sortOrder}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.nameEn,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: l10n.moveUp,
                onPressed: canMoveUp ? onUp : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
              ),
              IconButton(
                tooltip: l10n.moveDown,
                onPressed: canMoveDown ? onDown : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              ),
              PlatformSecondaryButton(
                label: l10n.edit,
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              PlatformSecondaryButton(
                label: l10n.retire,
                icon: Icons.archive_outlined,
                destructive: true,
                onPressed: onRetire,
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
    return PlatformDialogShell(
      title: widget.initial == null ? l10n.addDocumentType : l10n.documentTypes,
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformTextField(
              controller: _codeController,
              label: l10n.documentTypeCode,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.required
                  : null,
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              controller: _nameEnController,
              label: l10n.labelEn,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.required
                  : null,
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              controller: _nameArController,
              label: l10n.labelAr,
              textDirection: TextDirection.rtl,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.required
                  : null,
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              controller: _sortOrderController,
              label: l10n.categoryOrder,
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
      actions: [
        PlatformSecondaryButton(
          label: l10n.cancel,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        PlatformPrimaryButton(
          label: l10n.save,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}
