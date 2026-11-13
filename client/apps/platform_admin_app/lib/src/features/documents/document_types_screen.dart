import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

import 'package:l10n/l10n.dart';

class DocumentTypesScreen extends ConsumerWidget {
  const DocumentTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);

    return PlatformShell(
      currentRoute: '/reports/document-types',
      contextBar: PlatformContextBar(
        breadcrumbs: [
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.pageReportsTitle),
          ),
          ContextBreadcrumbItem(
            label: strings.tKey(PlatformAdminKeys.sectionReportsDocuments),
          ),
        ],
      ),
      child: PlatformPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformPageHeader(
              title: strings.tKey(PlatformAdminKeys.pageReportsTitle),
              subtitle: strings.tKey(PlatformAdminKeys.pageDocumentTypesTitle),
              actions: [
                PlatformPrimaryButton(
                  label: strings.tKey(PlatformAdminKeys.buttonDocumentTypeAdd),
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
        content: Text(
          ProviderScope.containerOf(
            context,
            listen: false,
          ).read(uiStringsProvider).tKey(CommonKeys.buttonSave),
        ),
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
    final strings = ref.watch(uiStringsProvider);
    final types = ref.watch(documentTypesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformSectionHeader(
          title: strings.tKey(PlatformAdminKeys.sectionReportsDocuments),
        ),
        const SizedBox(height: 12),
        types.when(
          loading: () => const PlatformLoadingView(),
          error: (error, stackTrace) => PlatformErrorView(
            message: strings.tKey(CommonKeys.statusUnhealthy),
            retryLabel: strings.tKey(CommonKeys.buttonRetry),
            onRetry: () => ref.invalidate(documentTypesProvider),
          ),
          data: (items) => items.isEmpty
              ? PlatformEmptyView(
                  icon: Icons.description_outlined,
                  title: strings.tKey(CommonKeys.emptyTitle),
                )
              : _DocumentTypesContent(
                  items: items,
                  onEdit: (item) => showDocumentTypeDialog(context, item),
                  onActivate: (item) => _activate(context, ref, item),
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
    final strings = ref.read(uiStringsProvider);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: strings.tKey(CommonKeys.statusRetired),
      body: strings.tKey(PlatformAdminKeys.dialogRetireConfirm),
      confirmLabel: strings.tKey(PlatformAdminKeys.buttonRetire),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.tKey(CommonKeys.errorGeneric))),
      );
    }
  }

  Future<void> _activate(
    BuildContext context,
    WidgetRef ref,
    ReportDocumentType item,
  ) async {
    final strings = ref.read(uiStringsProvider);
    try {
      await ref
          .read(platformConfigActionsProvider)
          .saveDocumentType(
            id: item.id,
            code: item.code,
            name: item.name,
            required: item.required,
            sortOrder: item.sortOrder,
            active: true,
          );
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.tKey(CommonKeys.errorGeneric))),
      );
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
        SnackBar(
          content: Text(
            ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric),
          ),
        ),
      );
    }
  }
}

String _statusLabel(dynamic strings, String status) {
  switch (status) {
    case 'ACTIVE':
      return strings.tKey(CommonKeys.statusActive);
    case 'DRAFT':
      return strings.tKey(PlatformAdminKeys.statusContentDraft);
    case 'RETIRED':
      return strings.tKey(CommonKeys.statusRetired);
    default:
      return status;
  }
}

/// Source-language (default) name for a document type.
String _documentTypeName(ReportDocumentType type) {
  return type.name.isEmpty ? type.code : type.name;
}

class _DocumentTypesContent extends StatelessWidget {
  const _DocumentTypesContent({
    required this.items,
    required this.onEdit,
    required this.onActivate,
    required this.onRetire,
    required this.onMove,
  });

  final List<ReportDocumentType> items;
  final ValueChanged<ReportDocumentType> onEdit;
  final ValueChanged<ReportDocumentType> onActivate;
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
            onActivate: onActivate,
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
                onActivate: () => onActivate(items[index]),
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

class _DocumentTypesTable extends ConsumerWidget {
  const _DocumentTypesTable({
    required this.items,
    required this.onEdit,
    required this.onActivate,
    required this.onRetire,
    required this.onMove,
  });

  final List<ReportDocumentType> items;
  final ValueChanged<ReportDocumentType> onEdit;
  final ValueChanged<ReportDocumentType> onActivate;
  final ValueChanged<ReportDocumentType> onRetire;
  final void Function(int index, int delta) onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
              label: Text(
                strings.tKey(PlatformAdminKeys.fieldDocumentTypeCode),
              ),
            ),
            DataColumn(
              label: Text(
                strings.tKey(PlatformAdminKeys.fieldItemLabelEn),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataColumn(
              label: Text(strings.tKey(CommonKeys.validationRequired)),
            ),
            DataColumn(label: Text(strings.tKey(CommonKeys.tableStatus))),
            DataColumn(
              label: Text(strings.tKey(PlatformAdminKeys.fieldCategoryOrder)),
            ),
            DataColumn(label: Text(strings.tKey(CommonKeys.tableActions))),
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
                      _documentTypeName(items[index]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      items[index].required
                          ? strings.tKey(CommonKeys.validationRequired)
                          : '-',
                    ),
                  ),
                  DataCell(
                    PlatformStatusChip(
                      status: _statusLabel(strings, items[index].status),
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
                          tooltip: strings.tKey(CommonKeys.buttonMoveUp),
                          onPressed: index > 0 ? () => onMove(index, -1) : null,
                          icon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: strings.tKey(CommonKeys.buttonMoveDown),
                          onPressed: index < items.length - 1
                              ? () => onMove(index, 1)
                              : null,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                          ),
                        ),
                        if (items[index].status == 'DRAFT')
                          IconButton(
                            tooltip: strings.tKey(
                              PlatformAdminKeys.buttonContentActivate,
                            ),
                            onPressed: () => onActivate(items[index]),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                          ),
                        IconButton(
                          tooltip: strings.tKey(CommonKeys.buttonEdit),
                          onPressed: () => onEdit(items[index]),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: strings.tKey(PlatformAdminKeys.buttonRetire),
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

class _DocumentTypeCard extends ConsumerWidget {
  const _DocumentTypeCard({
    required this.item,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onEdit,
    required this.onActivate,
    required this.onRetire,
    required this.onUp,
    required this.onDown,
  });

  final ReportDocumentType item;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onActivate;
  final VoidCallback onRetire;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.fieldDocumentTypeCode),
                value: item.code,
              ),
              PlatformStatusChip(status: _statusLabel(strings, item.status)),
              if (item.required)
                PlatformStatusChip(
                  status: strings.tKey(CommonKeys.validationRequired),
                ),
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
                value: '${item.sortOrder}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _documentTypeName(item),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: strings.tKey(CommonKeys.buttonMoveUp),
                onPressed: canMoveUp ? onUp : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
              ),
              IconButton(
                tooltip: strings.tKey(CommonKeys.buttonMoveDown),
                onPressed: canMoveDown ? onDown : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              ),
              if (item.status == 'DRAFT')
                PlatformPrimaryButton(
                  label: strings.tKey(PlatformAdminKeys.buttonContentActivate),
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: onActivate,
                ),
              PlatformSecondaryButton(
                label: strings.tKey(CommonKeys.buttonEdit),
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              PlatformSecondaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonRetire),
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
  late final TextEditingController _nameController;
  late final TextEditingController _sortOrderController;
  late bool _required;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _codeController = TextEditingController(text: initial?.code ?? '');
    _nameController = TextEditingController(text: initial?.name ?? '');
    _sortOrderController = TextEditingController(
      text: '${initial?.sortOrder ?? 0}',
    );
    _required = initial?.required ?? false;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(platformConfigApiProvider);
      final body = <String, dynamic>{
        'code': _codeController.text.trim(),
        'name': _nameController.text.trim(),
        'required': _required,
        'sortOrder': int.tryParse(_sortOrderController.text.trim()) ?? 0,
      };
      final id = widget.initial?.id;
      if (id == null) {
        await api.createDocumentType(body);
      } else {
        await api.updateDocumentType(id, body);
      }
      ref.invalidate(documentTypesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey);
    } catch (_) {
      if (!mounted) return;
      _snack(ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric));
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
    final strings = ref.watch(uiStringsProvider);
    return PlatformDialogShell(
      title: widget.initial == null
          ? strings.tKey(PlatformAdminKeys.buttonDocumentTypeAdd)
          : strings.tKey(PlatformAdminKeys.pageDocumentTypesTitle),
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformTextField(
              key: const Key('doc-type-code'),
              controller: _codeController,
              label: strings.tKey(PlatformAdminKeys.fieldDocumentTypeCode),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? strings.tKey(CommonKeys.validationRequired)
                  : null,
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              key: const Key('doc-type-name'),
              controller: _nameController,
              label: strings.tKey(PlatformAdminKeys.fieldItemLabelEn),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? strings.tKey(CommonKeys.validationRequired)
                  : null,
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              controller: _sortOrderController,
              label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _required,
              onChanged: (value) => setState(() => _required = value),
              title: Text(strings.tKey(CommonKeys.validationRequired)),
            ),
          ],
        ),
      ),
      actions: [
        PlatformSecondaryButton(
          label: strings.tKey(CommonKeys.buttonCancel),
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
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
