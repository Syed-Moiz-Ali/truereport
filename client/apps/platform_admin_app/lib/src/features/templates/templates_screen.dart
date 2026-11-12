import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../checklist/checklist_page_frame.dart';
import '../checklist/checklist_tab_bar.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  final Set<String> _busyIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(templatesProvider);

    return ChecklistPageFrame(
      currentRoute: '/checklist/templates',
      currentTab: ChecklistTab.templates,
      showSearch: false,
      actions: [
        PlatformPrimaryButton(
          label: l10n.tmplCreate,
          icon: Icons.add_rounded,
          onPressed: () => _createTemplate(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.templateHelper, style: PtTheme.bodyMuted),
          const SizedBox(height: 20),
          templates.when(
            loading: () => PlatformLoadingView(message: l10n.loading),
            error: (error, stackTrace) => PlatformErrorView(
              message: l10n.unhealthy,
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
            'nameEn': request.nameEn,
            'nameAr': request.nameAr,
            'descriptionEn': request.descriptionEn,
            'descriptionAr': request.descriptionAr,
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
        SnackBar(content: Text(AppLocalizations.of(context).genericError)),
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
        'nameEn': template.nameEn,
        'nameAr': template.nameAr,
        'descriptionEn': template.descriptionEn,
        'descriptionAr': template.descriptionAr,
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
        SnackBar(content: Text(AppLocalizations.of(context).genericError)),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(template.id));
    }
  }

  Future<void> _retireTemplate(
    BuildContext context,
    GlobalTemplate template,
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
      await ref.read(platformConfigActionsProvider).retireTemplate(template.id);
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

class _TemplatesContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (templates.isEmpty) {
      return PlatformEmptyView(
        icon: Icons.description_outlined,
        title: l10n.noData,
        body: l10n.templateHelper,
        actionLabel: l10n.tmplCreate,
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

class _TemplateCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = template.nameEn.isEmpty ? template.nameAr : template.nameEn;
    return InkWell(
      onTap: busy ? null : onOpen,
      borderRadius: BorderRadius.circular(14),
      child: PlatformSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PlatformMetaPill(
                  label: l10n.templateCode,
                  value: template.code,
                ),
                PlatformStatusChip(status: template.status),
                PlatformMetaPill(
                  label: l10n.versions,
                  value:
                      '${template.versionCount}'
                      '${template.currentVersionNo == null ? '' : ' / v${template.currentVersionNo}'}',
                ),
                PlatformMetaPill(
                  label: l10n.categoriesTab,
                  value: '${_categoryCount(template)}',
                ),
                PlatformMetaPill(
                  label: l10n.itemsTab,
                  value: '${_itemCount(template)}',
                ),
                PlatformMetaPill(
                  label: l10n.chkUpdated,
                  value: _updatedLabel(context, template),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
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
            if (template.nameEn.isNotEmpty && template.nameAr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                template.nameAr,
                textDirection: TextDirection.rtl,
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (template.descriptionEn.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                template.descriptionEn,
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (template.descriptionEn.isEmpty &&
                template.descriptionAr.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                template.descriptionAr,
                textDirection: TextDirection.rtl,
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PlatformSecondaryButton(
                  label: l10n.tmplBuilderTitle,
                  icon: Icons.open_in_new_rounded,
                  onPressed: busy ? null : onOpen,
                ),
                PlatformSecondaryButton(
                  label: l10n.tmplDuplicate,
                  icon: Icons.copy_outlined,
                  onPressed: busy ? null : onDuplicate,
                ),
                PlatformSecondaryButton(
                  label: l10n.retire,
                  icon: Icons.archive_outlined,
                  destructive: true,
                  onPressed: busy ? null : onRetire,
                ),
              ],
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
String _updatedLabel(BuildContext context, GlobalTemplate template) {
  final l10n = AppLocalizations.of(context);
  var latestPublished = '';
  var latestVersionNo = -1;
  for (final version in template.versions) {
    if (version.versionNo > latestVersionNo) {
      latestVersionNo = version.versionNo;
      latestPublished = version.publishedAt;
    }
  }
  if (latestPublished.isEmpty) return '—';
  return l10n.templatesUpdatedOn(latestPublished);
}

class _CreateTemplateRequest {
  const _CreateTemplateRequest({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
  });

  final String code;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
}

class _CreateTemplateDialog extends StatefulWidget {
  const _CreateTemplateDialog();

  @override
  State<_CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<_CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _nameArController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _descriptionArController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _descriptionEnController.dispose();
    _descriptionArController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: PlatformDialogShell(
        title: l10n.tmplCreate,
        body: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.templateHelper,
                style: PtTheme.font(13, color: PtTheme.muted),
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                controller: _codeController,
                label: l10n.templateCode,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.required
                    : null,
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                controller: _nameEnController,
                label: l10n.templateNameEn,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.required
                    : null,
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                controller: _nameArController,
                label: l10n.templateNameAr,
                textDirection: TextDirection.rtl,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.required
                    : null,
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                controller: _descriptionEnController,
                label: l10n.templateDescriptionEn,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                controller: _descriptionArController,
                label: l10n.templateDescriptionAr,
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          PlatformSecondaryButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          PlatformPrimaryButton(
            label: l10n.tmplCreate,
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(
                _CreateTemplateRequest(
                  code: _codeController.text.trim(),
                  nameEn: _nameEnController.text.trim(),
                  nameAr: _nameArController.text.trim(),
                  descriptionEn: _descriptionEnController.text.trim(),
                  descriptionAr: _descriptionArController.text.trim(),
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
