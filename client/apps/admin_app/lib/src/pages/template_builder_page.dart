import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/labels.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/template_version_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class TemplateBuilderPage extends ConsumerStatefulWidget {
  const TemplateBuilderPage({required this.templateId, super.key});

  final String templateId;

  @override
  ConsumerState<TemplateBuilderPage> createState() =>
      _TemplateBuilderPageState();
}

class _TemplateBuilderPageState extends ConsumerState<TemplateBuilderPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _serviceType = TextEditingController();
  final _vehicleType = TextEditingController();
  final _search = TextEditingController();
  String _categoryId = '';
  final List<_SelectedItem> _selected = [];
  bool _initialized = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _serviceType.dispose();
    _vehicleType.dispose();
    _search.dispose();
    super.dispose();
  }

  String get _itemKey => '${_search.text}\u0001$_categoryId';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(templateDetailProvider(widget.templateId));
    final categories = ref.watch(workshopCategoriesProvider);
    final items = ref.watch(publishedItemsProvider(_itemKey));
    if (detail.isLoading || categories.isLoading || items.isLoading) {
      return AppScaffold(
        appBar: AppBar(),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 7),
        ),
      );
    }
    if (detail.hasError || categories.hasError || items.hasError) {
      return AppScaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () {
                ref.invalidate(templateDetailProvider(widget.templateId));
                ref.invalidate(workshopCategoriesProvider);
                ref.invalidate(publishedItemsProvider(_itemKey));
              },
              retryLabel: l10n.search,
            ),
          ),
        ),
      );
    }
    final template = detail.requireValue;
    _initialize(template);
    final draft = template.draft;
    return AppScaffold(
      appBar: AppBar(
        title: Text(template.name),
        actions: [
          if (draft != null) ...[
            IconButton(
              tooltip: l10n.saveDraft,
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save_outlined),
            ),
            IconButton(
              tooltip: l10n.publishTemplate,
              onPressed: _busy ? null : _publish,
              icon: const Icon(Icons.publish_outlined),
            ),
          ],
          if (template.status != 'RETIRED')
            IconButton(
              tooltip: l10n.retire,
              onPressed: _busy ? null : _retire,
              icon: const Icon(Icons.archive_outlined),
            ),
        ],
      ),
      body: ListView(
        key: const Key('template-builder-list'),
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          SectionHeader(title: l10n.templateDetails),
          AppTextField(controller: _name, label: l10n.templateName),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: _description,
            label: l10n.templateDescription,
            maxLines: 2,
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(controller: _serviceType, label: l10n.serviceType),
          SizedBox(height: context.spacing.sm),
          AppTextField(controller: _vehicleType, label: l10n.vehicleType),
          SizedBox(height: context.spacing.lg),
          if (draft == null)
            EmptyState(
              title: l10n.readOnlyVersion,
              body: l10n.createDraft,
              icon: Icons.lock_outline,
              action: AppButton(
                label: l10n.createDraft,
                onPressed: _busy ? null : _createDraft,
                variant: AppButtonVariant.tonal,
              ),
            )
          else ...[
            SectionHeader(title: l10n.addItems),
            AppTextField(
              controller: _search,
              label: l10n.searchItems,
              hint: l10n.searchItems,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: context.spacing.sm),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _categoryId.isEmpty ? null : _categoryId,
              decoration: InputDecoration(labelText: l10n.allCategories),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.allCategories)),
                ...categories.requireValue.map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.labelEn),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _categoryId = value ?? ''),
            ),
            SizedBox(height: context.spacing.sm),
            ...items.requireValue
                .take(80)
                .map(
                  (item) => Card(
                    child: AppListTile(
                      key: Key('published-item-${item.versionId}'),
                      leading: const Icon(Icons.fact_check_outlined),
                      title: item.labelEn,
                      subtitle:
                          '${item.categoryLabelEn} · v${item.version.versionNo}${item.sampleData ? ' · ${l10n.sampleData}' : ''}',
                      trailing: IconButton(
                        tooltip: l10n.add,
                        onPressed: _contains(item.versionId)
                            ? null
                            : () => _add(item),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      onTap: _contains(item.versionId)
                          ? null
                          : () => _add(item),
                    ),
                  ),
                ),
            SizedBox(height: context.spacing.lg),
            SectionHeader(
              title: l10n.selectedItems,
              subtitle: '${_selected.length} ${l10n.itemsSelected}',
              action: AppButton(
                label: l10n.preview,
                onPressed: _selected.isEmpty ? null : _preview,
                icon: Icons.visibility_outlined,
                variant: AppButtonVariant.tonal,
              ),
            ),
            if (_selected.isEmpty)
              EmptyState(
                title: l10n.noItems,
                body: l10n.addItems,
                icon: Icons.playlist_add_check,
              )
            else
              ..._selected.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: context.spacing.sm,
                  ),
                  child: Card(
                    child: AppListTile(
                      title: entry.value.labelEn,
                      subtitle:
                          '${entry.value.categoryLabelEn} · v${entry.value.versionNo} · ${entry.value.noteRequirement}/${entry.value.evidenceRequirement} · ${l10n.lockedByPlatform}',
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => _itemAction(entry.key, value),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'up', child: Text(l10n.moveUp)),
                          PopupMenuItem(
                            value: 'down',
                            child: Text(l10n.moveDown),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(l10n.remove),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: context.spacing.xl),
            SectionHeader(title: l10n.versionHistory),
            ...template.versions.map(
              (version) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
                child: Card(
                  child: AppListTile(
                    key: Key('template-version-${version.id}'),
                    title:
                        'v${version.versionNo} · ${contentStatusLabel(l10n, version.status)}',
                    subtitle:
                        '${version.itemCount} ${l10n.itemsSelected}${version.publishedAt.isEmpty ? '' : ' · ${version.publishedAt}'}',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TemplateVersionPage(
                          templateId: widget.templateId,
                          versionId: version.id,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _initialize(TemplateDetail template) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _name.text = template.name;
    _description.text = template.description ?? '';
    _serviceType.text = template.serviceType;
    _vehicleType.text = template.vehicleType ?? '';
    _selected
      ..clear()
      ..addAll(
        (template.draft?.items ?? <TemplateItemView>[]).map(
          _SelectedItem.fromView,
        ),
      );
  }

  bool _contains(String versionId) =>
      _selected.any((item) => item.masterItemVersionId == versionId);

  void _add(PublishedItem item) {
    if (_contains(item.versionId)) {
      return;
    }
    setState(() => _selected.add(_SelectedItem.fromPublished(item)));
  }

  void _itemAction(int index, String action) {
    setState(() {
      if (action == 'remove') {
        _selected.removeAt(index);
      } else if (action == 'up' && index > 0) {
        final item = _selected.removeAt(index);
        _selected.insert(index - 1, item);
      } else if (action == 'down' && index < _selected.length - 1) {
        final item = _selected.removeAt(index);
        _selected.insert(index + 1, item);
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final template = ref.read(templateDetailProvider(widget.templateId)).value;
    if (template?.draft == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _saveDraft();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.contentSaved)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveDraft() async {
    await ref
        .read(adminApiProvider)
        .saveTemplateDraft(
          id: widget.templateId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          serviceType: _serviceType.text.trim(),
          vehicleType: _vehicleType.text.trim(),
          items: _selected
              .asMap()
              .entries
              .map(
                (entry) => TemplateItemDraft(
                  masterItemVersionId: entry.value.masterItemVersionId,
                  sortOrder: entry.key,
                ),
              )
              .toList(),
        );
    ref.invalidate(templateDetailProvider(widget.templateId));
    ref.invalidate(templatesProvider);
    _initialized = false;
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await _saveDraft();
      await ref.read(adminApiProvider).publishTemplate(widget.templateId);
      ref.invalidate(templateDetailProvider(widget.templateId));
      ref.invalidate(templatesProvider);
      _initialized = false;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.templatePublished)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _createDraft() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).createTemplateDraft(widget.templateId);
      ref.invalidate(templateDetailProvider(widget.templateId));
      _initialized = false;
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _retire() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.retire,
      message: l10n.confirm,
      confirmLabel: l10n.retire,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).retireTemplate(widget.templateId);
      ref.invalidate(templatesProvider);
      ref.invalidate(templateDetailProvider(widget.templateId));
      _initialized = false;
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _preview() async {
    final l10n = AppLocalizations.of(context);
    var arabic = false;
    await showAppBottomSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.preview,
                subtitle: '${_selected.length} ${l10n.itemsSelected}',
              ),
              Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: [
                  AppSelectableText(
                    label: l10n.previewEn,
                    selected: !arabic,
                    onTap: () => setState(() => arabic = false),
                  ),
                  AppSelectableText(
                    label: l10n.previewAr,
                    selected: arabic,
                    onTap: () => setState(() => arabic = true),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.sm),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _selected
                      .map(
                        (item) => Padding(
                          padding: EdgeInsetsDirectional.only(
                            bottom: context.spacing.sm,
                          ),
                          child: Card(
                            child: Padding(
                              padding: EdgeInsetsDirectional.all(
                                context.spacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    arabic ? item.labelAr : item.labelEn,
                                    style: context.texts.titleMedium,
                                  ),
                                  SizedBox(height: context.spacing.xs),
                                  Text(
                                    arabic
                                        ? item.instructionAr
                                        : item.instructionEn,
                                    style: context.texts.bodyMedium,
                                  ),
                                  SizedBox(height: context.spacing.xs),
                                  Text(
                                    'v${item.versionNo} · ${item.noteRequirement}/${item.evidenceRequirement} · ${l10n.lockedByPlatform}',
                                    style: context.texts.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectedItem {
  const _SelectedItem({
    required this.masterItemVersionId,
    required this.categoryLabelEn,
    required this.categoryLabelAr,
    required this.labelEn,
    required this.labelAr,
    required this.instructionEn,
    required this.instructionAr,
    required this.versionNo,
    required this.noteRequirement,
    required this.evidenceRequirement,
  });

  final String masterItemVersionId;
  final String categoryLabelEn;
  final String categoryLabelAr;
  final String labelEn;
  final String labelAr;
  final String instructionEn;
  final String instructionAr;
  final int versionNo;
  final String noteRequirement;
  final String evidenceRequirement;

  factory _SelectedItem.fromView(TemplateItemView item) => _SelectedItem(
    masterItemVersionId: item.masterItemVersionId,
    categoryLabelEn: item.categoryLabelEn,
    categoryLabelAr: item.categoryLabelAr,
    labelEn: item.labelEn,
    labelAr: item.labelAr,
    instructionEn: item.instructionEn,
    instructionAr: item.instructionAr,
    versionNo: item.versionNo,
    noteRequirement: item.noteRequirement,
    evidenceRequirement: item.evidenceRequirement,
  );

  factory _SelectedItem.fromPublished(PublishedItem item) {
    final en = item.version.translation('en');
    final ar = item.version.translation('ar');
    return _SelectedItem(
      masterItemVersionId: item.versionId,
      categoryLabelEn: item.categoryLabelEn,
      categoryLabelAr: item.categoryLabelAr,
      labelEn: en.label,
      labelAr: ar.label,
      instructionEn: en.instruction,
      instructionAr: ar.instruction,
      versionNo: item.version.versionNo,
      noteRequirement: item.version.noteRequirement,
      evidenceRequirement: item.version.evidenceRequirement,
    );
  }
}
