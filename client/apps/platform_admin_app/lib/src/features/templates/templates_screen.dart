import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../checklist/checklist_page_frame.dart';
import '../checklist/checklist_plural.dart';
import '../checklist/checklist_status.dart';
import '../checklist/checklist_tab_bar.dart';

import 'package:l10n/l10n.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  final Set<String> _busyIds = {};

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final templates = ref.watch(templatesProvider);

    return ChecklistPageFrame(
      currentRoute: '/checklist/templates',
      currentTab: ChecklistTab.templates,
      showSearch: false,
      actions: [
        PlatformPrimaryButton(
          label: strings.tKey(PlatformAdminKeys.pageTemplatesCreate),
          icon: Icons.add_rounded,
          onPressed: () => _createTemplate(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.tKey(PlatformAdminKeys.pageTemplatesHelper),
            style: PtTheme.bodyMuted,
          ),
          const SizedBox(height: 20),
          templates.when(
            loading: () => PlatformLoadingView(
              message: strings.tKey(CommonKeys.stateLoading),
            ),
            error: (error, stackTrace) => PlatformErrorView(
              message: strings.tKey(CommonKeys.statusUnhealthy),
              onRetry: () => ref.invalidate(templatesProvider),
            ),
            data: (items) => _TemplatesContent(
              templates: items,
              busyIds: _busyIds,
              onOpen: (id) => _openBuilder(context, id),
              onDuplicate: (template) => _duplicateTemplate(context, template),
              onRetire: (template) => _retireTemplate(context, template),
              onCreate: () => _createTemplate(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Create flow: creates a DRAFT via the existing create API, then navigates
  /// to the builder with the new id (no id-less builder).
  Future<void> _createTemplate(BuildContext context) async {
    final strings = ref.read(uiStringsProvider);
    final request = await showDialog<_CreateTemplateRequest>(
      context: context,
      builder: (dialogContext) => const _CreateTemplateDialog(),
    );
    if (request == null || !context.mounted) return;
    try {
      final created = await ref
          .read(platformConfigActionsProvider)
          .createTemplate({
            'code': request.code,
            'name': request.name,
            'description': request.description,
          });
      if (!context.mounted) return;
      _openBuilder(context, created.id);
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

  void _openBuilder(BuildContext context, String id) {
    context.go('/checklist/templates/$id');
  }

  /// Client-side duplicate: createTemplate with copied names/code+'-COPY',
  /// then replaceCategories/replaceItems from the source version,
  /// then open the builder with the new id.
  Future<void> _duplicateTemplate(
    BuildContext context,
    GlobalTemplate template,
  ) async {
    final strings = ref.read(uiStringsProvider);
    if (_busyIds.contains(template.id)) return;
    setState(() => _busyIds.add(template.id));
    try {
      final actions = ref.read(platformConfigActionsProvider);
      final sourceVersionId = template.currentPublishedVersionId.isNotEmpty
          ? template.currentPublishedVersionId
          : _latestVersionId(template);
      TemplateVersionDetail? detail;
      if (sourceVersionId != null) {
        detail = await ref
            .read(platformConfigApiProvider)
            .templateVersionDetail(template.id, sourceVersionId);
      }
      final created = await actions.createTemplate({
        'code': '${template.code}-COPY',
        'name': _templateName(template),
        'description': _templateDescription(template),
      });
      final draftVersionId = _draftVersionId(created);
      if (detail != null && draftVersionId != null) {
        final categories = [...detail.categories]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        await actions.replaceTemplateCategories(created.id, draftVersionId, [
          for (var index = 0; index < categories.length; index++)
            {
              'categoryId': categories[index].categoryId,
              'included': true,
              'sortOrder': index + 1,
            },
        ]);
        await actions.replaceTemplateItems(created.id, draftVersionId, [
          for (final category in categories)
            for (var index = 0; index < _sortedItems(category).length; index++)
              if (_sortedItems(category)[index].included)
                {
                  'categoryId': category.categoryId,
                  'itemVersionId': _sortedItems(category)[index].itemVersionId,
                  'included': true,
                  'sortOrder': index + 1,
                },
        ]);
      }
      if (!context.mounted) return;
      _openBuilder(context, created.id);
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.messageKey)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.tKey(CommonKeys.errorGeneric))),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(template.id));
    }
  }

  Future<void> _retireTemplate(
    BuildContext context,
    GlobalTemplate template,
  ) async {
    final strings = ref.watch(uiStringsProvider);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: strings.tKey(CommonKeys.statusRetired),
      body: strings.tKey(PlatformAdminKeys.dialogRetireConfirm),
      confirmLabel: strings.tKey(PlatformAdminKeys.buttonRetire),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(platformConfigActionsProvider).retireTemplate(template.id);
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
}

String? _latestVersionId(GlobalTemplate template) {
  if (template.versions.isEmpty) return null;
  var latest = template.versions.first;
  for (final version in template.versions) {
    if (version.versionNo > latest.versionNo) latest = version;
  }
  return latest.id;
}

String? _draftVersionId(GlobalTemplate template) {
  TemplateVersionSummary? draft;
  for (final version in template.versions) {
    if (version.status == 'DRAFT' &&
        (draft == null || version.versionNo > draft.versionNo)) {
      draft = version;
    }
  }
  return draft?.id;
}

List<TemplateItem> _sortedItems(TemplateCategory category) {
  final items = [...category.items]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return items;
}

class _TemplatesContent extends ConsumerWidget {
  const _TemplatesContent({
    required this.templates,
    required this.busyIds,
    required this.onOpen,
    required this.onDuplicate,
    required this.onRetire,
    required this.onCreate,
  });

  final List<GlobalTemplate> templates;
  final Set<String> busyIds;
  final ValueChanged<String> onOpen;
  final ValueChanged<GlobalTemplate> onDuplicate;
  final ValueChanged<GlobalTemplate> onRetire;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    if (templates.isEmpty) {
      return PlatformEmptyView(
        icon: Icons.description_outlined,
        title: strings.tKey(CommonKeys.emptyTitle),
        body: strings.tKey(PlatformAdminKeys.pageTemplatesHelper),
        actionLabel: strings.tKey(PlatformAdminKeys.pageTemplatesCreate),
        onAction: onCreate,
      );
    }
    // Premium cards are the primary view on every breakpoint: two columns
    // on wide viewports, one stacked column below the breakpoint.
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 1000;
        if (!twoColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < templates.length; index++) ...[
                _TemplateCard(
                  template: templates[index],
                  busy: busyIds.contains(templates[index].id),
                  onOpen: () => onOpen(templates[index].id),
                  onDuplicate: () => onDuplicate(templates[index]),
                  onRetire: () => onRetire(templates[index]),
                ),
                if (index != templates.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        final rows = <Widget>[];
        for (var index = 0; index < templates.length; index += 2) {
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TemplateCard(
                    template: templates[index],
                    busy: busyIds.contains(templates[index].id),
                    onOpen: () => onOpen(templates[index].id),
                    onDuplicate: () => onDuplicate(templates[index]),
                    onRetire: () => onRetire(templates[index]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: index + 1 < templates.length
                      ? _TemplateCard(
                          template: templates[index + 1],
                          busy: busyIds.contains(templates[index + 1].id),
                          onOpen: () => onOpen(templates[index + 1].id),
                          onDuplicate: () => onDuplicate(templates[index + 1]),
                          onRetire: () => onRetire(templates[index + 1]),
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
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({
    required this.template,
    required this.busy,
    required this.onOpen,
    required this.onDuplicate,
    required this.onRetire,
  });

  final GlobalTemplate template;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;
  final VoidCallback onRetire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final name = _templateName(template);
    final description = _templateDescription(template);
    final catCount = _categoryCount(template);
    final itemCount = _itemCount(template);
    final updatedLabel = _updatedLabel(strings, template);

    // Readiness determination
    final bool isReady;
    final String readinessLabel;
    final Color readinessColor;
    if (template.status == 'RETIRED') {
      isReady = false;
      readinessLabel = strings.tKey(CommonKeys.statusRetired);
      readinessColor = PtTheme.muted;
    } else if (catCount == 0) {
      isReady = false;
      readinessLabel = strings.tKey(
        PlatformAdminKeys.checklistTemplatesReadinessNeedsCategories,
      );
      readinessColor = PtTheme.amber;
    } else if (itemCount == 0) {
      isReady = false;
      readinessLabel = strings.tKey(
        PlatformAdminKeys.checklistTemplatesReadinessNeedsItems,
      );
      readinessColor = PtTheme.amber;
    } else {
      isReady = true;
      readinessLabel = strings.tKey(
        PlatformAdminKeys.checklistTemplatesReadinessReady,
      );
      readinessColor = PtTheme.deepGreen;
    }

    final accentColor = template.status == 'PUBLISHED'
        ? PtTheme.deepGreen
        : (template.status == 'DRAFT' ? PtTheme.amber : PtTheme.muted);

    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top row: initial tile, template title, version pill, status, overflow actions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'T',
                            style: PtTheme.font(
                              18,
                              weight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: PtTheme.font(
                                        17,
                                        lineHeight: 22,
                                        weight: FontWeight.w700,
                                        color: PtTheme.ink,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PlatformStatusChip(
                                    status: template.status,
                                    label: checklistStatusLabel(
                                      strings,
                                      template.status,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    tooltip: strings.tKey(
                                      CommonKeys.tableActions,
                                    ),
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 20,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'duplicate') onDuplicate();
                                      if (value == 'retire') onRetire();
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'duplicate',
                                        enabled: !busy,
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.copy_outlined,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              strings.tKey(
                                                PlatformAdminKeys
                                                    .buttonTemplateDuplicate,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'retire',
                                        enabled: !busy,
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.archive_outlined,
                                              size: 18,
                                              color: PtTheme.rose,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              strings.tKey(
                                                PlatformAdminKeys.buttonRetire,
                                              ),
                                              style: const TextStyle(
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
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    template.code,
                                    style: PtTheme.font(
                                      12,
                                      weight: FontWeight.w700,
                                      color: PtTheme.muted,
                                      tracking: 0.4,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: PtTheme.canvas,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      template.currentVersionNo == null
                                          ? 'v1.0'
                                          : 'v${template.currentVersionNo}',
                                      style: PtTheme.font(
                                        11,
                                        weight: FontWeight.w600,
                                        color: PtTheme.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: PtTheme.font(
                          13,
                          lineHeight: 19,
                          color: PtTheme.muted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Structure badges & Readiness Indicator
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: PtTheme.canvas,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: PtTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.folder_outlined,
                                size: 15,
                                color: PtTheme.deepGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                checklistCategoryCountLabel(strings, catCount),
                                style: PtTheme.font(
                                  12,
                                  weight: FontWeight.w700,
                                  color: PtTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: PtTheme.canvas,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: PtTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.checklist_rounded,
                                size: 15,
                                color: PtTheme.deepGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                checklistItemCountLabel(strings, itemCount),
                                style: PtTheme.font(
                                  12,
                                  weight: FontWeight.w700,
                                  color: PtTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: readinessColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: readinessColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isReady
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.info_outline_rounded,
                                size: 15,
                                color: readinessColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                readinessLabel,
                                style: PtTheme.font(
                                  12,
                                  weight: FontWeight.w700,
                                  color: readinessColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    // Action row: Open builder (primary visible)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PlatformPrimaryButton(
                          label: strings.tKey(
                            PlatformAdminKeys
                                .checklistTemplatesButtonOpenBuilder,
                          ),
                          icon: Icons.open_in_new_rounded,
                          onPressed: busy ? null : onOpen,
                        ),
                        if (updatedLabel.isNotEmpty)
                          Text(
                            updatedLabel,
                            style: PtTheme.font(11, color: PtTheme.muted),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Closest available label for the "updated" column: the newest version's
/// publish timestamp via [templatesUpdatedOn] under the [chkUpdated] header.
/// [GlobalTemplate] carries no updated field, so an exact updated key is a gap.
String _updatedLabel(dynamic strings, GlobalTemplate template) {
  var latestPublished = '';
  var latestVersionNo = -1;
  for (final version in template.versions) {
    if (version.versionNo > latestVersionNo) {
      latestVersionNo = version.versionNo;
      latestPublished = version.publishedAt;
    }
  }
  if (latestPublished.isEmpty) return '';
  return strings.tArgsKey(PlatformAdminKeys.pageTemplatesUpdatedOn, {
    'date': latestPublished,
  });
}

class _CreateTemplateRequest {
  const _CreateTemplateRequest({
    required this.code,
    required this.name,
    required this.description,
  });

  final String code;
  final String name;
  final String description;
}

class _CreateTemplateDialog extends ConsumerStatefulWidget {
  const _CreateTemplateDialog();

  @override
  ConsumerState<_CreateTemplateDialog> createState() =>
      _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends ConsumerState<_CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: PlatformDialogShell(
        title: strings.tKey(PlatformAdminKeys.pageTemplatesCreate),
        body: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.pageTemplatesHelper),
                style: PtTheme.font(13, color: PtTheme.muted),
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                controller: _codeController,
                label: strings.tKey(PlatformAdminKeys.fieldTemplateCode),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? strings.tKey(CommonKeys.validationRequired)
                    : null,
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                key: const Key('template-name'),
                controller: _nameController,
                label: strings.tKey(PlatformAdminKeys.fieldTemplateName),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? strings.tKey(CommonKeys.validationRequired)
                    : null,
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                key: const Key('template-description'),
                controller: _descriptionController,
                label: strings.tKey(PlatformAdminKeys.fieldTemplateDescription),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          PlatformSecondaryButton(
            label: strings.tKey(CommonKeys.buttonCancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          PlatformPrimaryButton(
            label: strings.tKey(PlatformAdminKeys.pageTemplatesCreate),
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(
                _CreateTemplateRequest(
                  code: _codeController.text.trim(),
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

int _categoryCount(GlobalTemplate template) => template.categories.length;

int _itemCount(GlobalTemplate template) => template.categories.fold<int>(
  0,
  (sum, category) => sum + category.itemCount,
);

String _templateName(GlobalTemplate template) {
  return template.name.isEmpty ? template.code : template.name;
}

String _templateDescription(GlobalTemplate template) => template.description;
