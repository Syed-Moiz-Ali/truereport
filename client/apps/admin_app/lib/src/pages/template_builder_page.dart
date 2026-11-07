import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/labels.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/template_version_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// F3-B Step 2, screen 8 — Template Builder workbench.
///
/// Figma 1280 draws a two-column workbench: left master-item catalog
/// (search + category filter + tap-to-add cards), right numbered inspection
/// sequence with reorder controls + tap-to-add drop zone + versions.
/// Derived phone/tablet layout stacks the catalog above the sequence.
///
/// Existing behaviour is preserved verbatim: tap-to-add, move up/down/remove,
/// save draft (PUT with the ordered item list incl. sortOrder), publish
/// (save then POST publish), retire, create draft, versions navigation and the
/// EN/AR preview bottom sheet. Only existing ARB keys and tokens are used.
/// Deliberately omitted per O7: custom-item creation, autosave, per-item
/// Active/Automated flags, numeric ranges, telemetry/AI, QA policy card,
/// semver, time estimates and "of 14" counts.
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
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
      );
    }
    final template = detail.requireValue;
    _initialize(template);
    final draft = template.draft;
    // Existing catalog contract: approved master items via the
    // published-items provider (?search= plus category filter).
    final catalog = items.requireValue.take(80).toList();
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Figma 1280: catalog and sequence sit side by side.
          // Derived phone/tablet layout: catalog stacks above the sequence.
          final wide = constraints.maxWidth >= 900;
          return ListView(
            key: const Key('template-builder-list'),
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            children: [
              _header(context, l10n, template, draft, wide),
              SizedBox(height: context.spacing.lg),
              SectionHeader(title: l10n.templateDetails),
              AppTextField(controller: _name, label: l10n.templateName),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _description,
                label: l10n.templateDescription,
                maxLines: 2,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _serviceType,
                label: l10n.serviceType,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _vehicleType,
                label: l10n.vehicleType,
              ),
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
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 404,
                        child: _catalogPanel(
                          context,
                          l10n,
                          categories.requireValue,
                          catalog,
                        ),
                      ),
                      SizedBox(width: context.spacing.xl),
                      Expanded(
                        flex: 660,
                        child: _sequencePanel(
                          context,
                          l10n,
                          template,
                          draft,
                          catalog,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _catalogPanel(
                        context,
                        l10n,
                        categories.requireValue,
                        catalog,
                      ),
                      SizedBox(height: context.spacing.xl),
                      _sequencePanel(
                        context,
                        l10n,
                        template,
                        draft,
                        catalog,
                      ),
                    ],
                  ),
                SizedBox(height: context.spacing.xl),
                SectionHeader(title: l10n.versionHistory),
                ...template.versions.map(
                  (version) => Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: context.spacing.sm,
                    ),
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
          );
        },
      ),
    );
  }

  /// Top bar: template title, integer version pill (vN, never semver),
  /// preview (existing EN/AR sheet) and publish (existing flow).
  Widget _header(
    BuildContext context,
    AppLocalizations l10n,
    TemplateDetail template,
    TemplateVersionView? draft,
    bool wide,
  ) {
    final pill = StatusChip(
      label: draft != null
          ? 'v${draft.versionNo}'
          : contentStatusLabel(l10n, template.status),
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          template.name,
          key: const Key('builder-title'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.texts.headlineSmall,
        ),
        SizedBox(height: context.spacing.xs),
        pill,
      ],
    );
    final actions = [
      AppButton(
        key: const Key('builder-preview'),
        label: l10n.preview,
        onPressed: draft == null || _selected.isEmpty || _busy
            ? null
            : _preview,
        icon: Icons.visibility_outlined,
        variant: AppButtonVariant.tonal,
      ),
      AppButton(
        key: const Key('builder-publish'),
        label: l10n.publishTemplate,
        onPressed: draft == null || _busy ? null : _publish,
        icon: Icons.publish_outlined,
      ),
    ];
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: title),
          ...actions.map(
            (action) => Padding(
              padding: EdgeInsetsDirectional.only(start: context.spacing.sm),
              child: action,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: actions,
        ),
      ],
    );
  }

  /// Left catalog column: search, category filter and tap-to-add cards.
  /// Workshop cannot create master items (platform GET-only contract), so no
  /// custom-item button is offered.
  Widget _catalogPanel(
    BuildContext context,
    AppLocalizations l10n,
    List<Category> categories,
    List<PublishedItem> catalog,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: '${l10n.builderMasterItems} · ${catalog.length}',
        ),
        AppTextField(
          key: const Key('builder-search'),
          controller: _search,
          label: l10n.searchItems,
          hint: l10n.searchItems,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: context.spacing.sm),
        DropdownButtonFormField<String>(
          key: const Key('builder-category'),
          isExpanded: true,
          initialValue: _categoryId.isEmpty ? null : _categoryId,
          decoration: InputDecoration(labelText: l10n.allCategories),
          items: [
            DropdownMenuItem(value: '', child: Text(l10n.allCategories)),
            ...categories.map(
              (category) => DropdownMenuItem(
                value: category.id,
                child: Text(category.labelEn),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _categoryId = value ?? ''),
        ),
        SizedBox(height: context.spacing.sm),
        ...catalog.map(
          (item) => Padding(
            padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
            child: Card(
              child: AppListTile(
                key: Key('published-item-${item.versionId}'),
                leading: const Icon(Icons.fact_check_outlined),
                title: item.labelEn,
                subtitle:
                    '${item.categoryLabelEn} · v${item.version.versionNo}${item.sampleData ? ' · ${l10n.sampleData}' : ''}',
                trailing: IconButton(
                  key: Key('catalog-add-${item.versionId}'),
                  tooltip: l10n.add,
                  onPressed: _contains(item.versionId)
                      ? null
                      : () => _add(item),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                onTap: _contains(item.versionId) ? null : () => _add(item),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Right sequence column: numbered cards with locked-rule pills, keyboard
  /// reachable up/down/remove buttons plus a drag handle per row, and a
  /// tap-to-add drop zone wired to the existing add flow.
  Widget _sequencePanel(
    BuildContext context,
    AppLocalizations l10n,
    TemplateDetail template,
    TemplateVersionView draft,
    List<PublishedItem> catalog,
  ) {
    final hasAvailable =
        catalog.any((item) => !_contains(item.versionId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          title: l10n.builderSequenceTitle,
          subtitle: '${_selected.length} ${l10n.itemsSelected}',
        ),
        if (_selected.isEmpty)
          EmptyState(
            title: l10n.noItems,
            body: l10n.addItems,
            icon: Icons.playlist_add_check,
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: _dragProxy,
            onReorderItem: _reorderItem,
            children: _selected.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return WorkshopSequenceCard(
                key: ValueKey('seq-row-${item.masterItemVersionId}'),
                indexLabel: (index + 1).toString().padLeft(2, '0'),
                title: item.labelEn,
                chips: [
                  WorkshopLockedPill(
                    label:
                        '${item.noteRequirement}/${item.evidenceRequirement} · ${l10n.lockedByPlatform}',
                  ),
                  StatusChip(
                    label:
                        '${item.categoryLabelEn} · v${item.versionNo}',
                  ),
                ],
                ruleNote: Text(
                  item.instructionEn.isEmpty
                      ? item.categoryLabelEn
                      : item.instructionEn,
                ),
                controls: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: Key('seq-up-$index'),
                      tooltip: l10n.moveUp,
                      onPressed: index > 0
                          ? () => _itemAction(index, 'up')
                          : null,
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      key: Key('seq-down-$index'),
                      tooltip: l10n.moveDown,
                      onPressed: index < _selected.length - 1
                          ? () => _itemAction(index, 'down')
                          : null,
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      key: Key('seq-remove-$index'),
                      tooltip: l10n.remove,
                      onPressed: () => _itemAction(index, 'remove'),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        key: Key('seq-drag-$index'),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        SizedBox(height: context.spacing.sm),
        WorkshopDropZone(
          key: const Key('builder-dropzone'),
          label: l10n.builderDropHint,
          hint: l10n.addItems,
          onTap: hasAvailable ? () => _addFirstAvailable(catalog) : null,
        ),
      ],
    );
  }

  /// Drag proxy keeps the card style while a row is being dragged.
  Widget _dragProxy(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, proxyChild) => Material(
        type: MaterialType.transparency,
        child: proxyChild,
      ),
      child: child,
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

  void _addFirstAvailable(List<PublishedItem> catalog) {
    for (final item in catalog) {
      if (!_contains(item.versionId)) {
        _add(item);
        return;
      }
    }
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

  void _reorderItem(int fromIndex, int toIndex) {
    setState(() {
      final item = _selected.removeAt(fromIndex);
      _selected.insert(toIndex, item);
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
