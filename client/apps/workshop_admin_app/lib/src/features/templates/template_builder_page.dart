import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/templates/template_version_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Screen 8 — Template Builder workbench.
///
/// Chrome/restructure pass over the existing builder logic (state, providers,
/// save/publish/preview/create-draft/retire/version/reorder/drop/add/remove/
/// search/category behaviour and every test key are preserved):
/// - 60 px top bar: back action, "Template builder" section label, status badge
/// - page header: template name (key `builder-title`), integer version,
///   service/vehicle meta
/// - template details [WorkshopCard] with the existing editable fields
/// - two-pane body from 1000 px (catalog ≈40%, sequence ≈60%, 24 px gap),
///   stacked below that; each pane is a single [WorkshopCard]
/// - sticky save/publish bar: Save draft, Preview, Publish, Retire overflow
/// - version history as a secondary collapsible section at the bottom
///
/// Removed fake chrome: the 96 px left rail, Fx shadows/gradients, uppercase
/// "STANDARD OPERATING PROCEDURE" eyebrow, the three metric pods (sequence /
/// photos / estimated time were derived, not server data) and the hardcoded
/// bay/user header.
/// Picks the localized master-content value with an English fallback.
String _localized(BuildContext context, String en, String ar) =>
    context.isArabic && ar.trim().isNotEmpty ? ar : en;

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

  bool get _wide => MediaQuery.sizeOf(context).width >= 1000;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final detail = ref.watch(templateDetailProvider(widget.templateId));
    final categories = ref.watch(workshopCategoriesProvider);
    final items = ref.watch(publishedItemsProvider(_itemKey));

    if (detail.isLoading || categories.isLoading || items.isLoading) {
      return Scaffold(
        backgroundColor: ws.canvas,
        body: const SafeArea(
          child: WorkshopPageScroll(
            children: [WorkshopSkeleton(lines: 8, card: true)],
          ),
        ),
      );
    }
    if (detail.hasError || categories.hasError || items.hasError) {
      return Scaffold(
        backgroundColor: ws.canvas,
        body: SafeArea(
          child: WorkshopPageScroll(
            children: [
              WorkshopErrorState(
                title: l10n.error,
                body: l10n.genericError,
                retryLabel: l10n.retryAction,
                onRetry: () {
                  ref.invalidate(templateDetailProvider(widget.templateId));
                  ref.invalidate(workshopCategoriesProvider);
                  ref.invalidate(publishedItemsProvider(_itemKey));
                },
              ),
            ],
          ),
        ),
      );
    }

    final template = detail.requireValue;
    _initialize(template);
    final draft = template.draft;
    final catalog = items.requireValue.take(80).toList();
    final wide = _wide;
    final spacing = context.spacing;
    final gutter = ws.pageGutter(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: ws.canvas,
      body: Column(
        children: [
          _topBar(context, l10n, template),
          Expanded(
            child: ListView(
              key: const Key('template-builder-list'),
              padding: EdgeInsetsDirectional.fromSTEB(
                gutter,
                spacing.lg,
                gutter,
                spacing.xl,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _header(context, l10n, template, draft),
                        SizedBox(height: spacing.xl),
                        _detailsCard(context, l10n, wide),
                        SizedBox(height: spacing.xl),
                        if (draft == null)
                          _readOnly(context, l10n)
                        else if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: _catalogPanel(
                                  context,
                                  l10n,
                                  categories.requireValue,
                                  catalog,
                                ),
                              ),
                              SizedBox(width: spacing.xl),
                              Expanded(
                                flex: 6,
                                child: _sequencePanel(context, l10n, catalog),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _catalogPanel(
                                context,
                                l10n,
                                categories.requireValue,
                                catalog,
                              ),
                              SizedBox(height: spacing.xl),
                              _sequencePanel(context, l10n, catalog),
                            ],
                          ),
                        SizedBox(height: spacing.xl),
                        _versionHistory(context, l10n, template),
                        SizedBox(height: spacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _saveBar(context, l10n, template, draft),
    );
  }

  /// Full-bleed chrome with the page's 1120 column inside (same pattern as the
  /// job detail/report top bars).
  Widget _pageColumn(BuildContext context, Widget child) {
    final ws = context.ws;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: child,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar (60 px)
  // ---------------------------------------------------------------------------
  Widget _topBar(
    BuildContext context,
    AppLocalizations l10n,
    TemplateDetail template,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(bottom: BorderSide(color: ws.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: ws.topBarHeight,
          child: _pageColumn(
            context,
            Row(
              children: [
                WorkshopIconButton(
                  icon: Icons.arrow_back,
                  semanticLabel: MaterialLocalizations.of(context)
                      .backButtonTooltip,
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    l10n.templateBuilder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ws.bodyStrong.copyWith(color: ws.ink),
                  ),
                ),
                SizedBox(width: spacing.sm),
                WorkshopStatusBadge(
                  label: contentStatusLabel(l10n, template.status),
                  tone: _statusTone(template.status),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page header
  // ---------------------------------------------------------------------------
  Widget _header(
    BuildContext context,
    AppLocalizations l10n,
    TemplateDetail template,
    TemplateVersionView? draft,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          template.name,
          key: const Key('builder-title'),
          style: ws.pageTitle.copyWith(color: ws.ink),
        ),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.md,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'v${draft?.versionNo ?? '-'}',
              textDirection: TextDirection.ltr,
              style: ws.bodyStrong.copyWith(color: ws.ink),
            ),
            Text(
              _classification(template),
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ],
        ),
      ],
    );
  }

  String _classification(TemplateDetail template) {
    final parts = [
      template.serviceType,
      template.vehicleType ?? '',
    ].where((part) => part.isNotEmpty);
    return parts.join(' · ');
  }

  /// Panels keep the standard card padding from 600 px and tighten to 12 on
  /// phones so the sequence controls (44 px targets) never overflow.
  EdgeInsetsGeometry _panelPadding(BuildContext context) {
    final spacing = context.spacing;
    return MediaQuery.sizeOf(context).width < 600
        ? EdgeInsetsDirectional.all(spacing.md)
        : EdgeInsetsDirectional.all(context.ws.cardPadding);
  }

  WorkshopStatusTone _statusTone(String status) => switch (status) {
    'PUBLISHED' => WorkshopStatusTone.success,
    'RETIRED' => WorkshopStatusTone.neutral,
    _ => WorkshopStatusTone.warning,
  };

  // ---------------------------------------------------------------------------
  // Template details card
  // ---------------------------------------------------------------------------
  Widget _detailsCard(BuildContext context, AppLocalizations l10n, bool wide) {
    final spacing = context.spacing;
    final name = WorkshopTextField(controller: _name, label: l10n.templateName);
    final service = WorkshopTextField(
      controller: _serviceType,
      label: l10n.serviceType,
    );
    final vehicle = WorkshopTextField(
      controller: _vehicleType,
      label: l10n.vehicleType,
    );
    final description = WorkshopTextField(
      controller: _description,
      label: l10n.templateDescription,
    );
    return WorkshopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkshopSectionHeader(title: l10n.template),
          SizedBox(height: spacing.md),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: name),
                SizedBox(width: spacing.md),
                Expanded(child: service),
              ],
            )
          else ...[
            name,
            SizedBox(height: spacing.md),
            service,
          ],
          SizedBox(height: spacing.md),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: vehicle),
                SizedBox(width: spacing.md),
                Expanded(child: description),
              ],
            )
          else ...[
            vehicle,
            SizedBox(height: spacing.md),
            description,
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left pane: master items catalog
  // ---------------------------------------------------------------------------
  Widget _catalogPanel(
    BuildContext context,
    AppLocalizations l10n,
    List<Category> categories,
    List<PublishedItem> catalog,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    return WorkshopCard(
      padding: _panelPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkshopSectionHeader(
            title: '${l10n.builderMasterItems} (${catalog.length})',
          ),
          SizedBox(height: spacing.md),
          WorkshopTextField(
            key: const Key('builder-search'),
            controller: _search,
            label: l10n.searchItems,
            hint: l10n.searchItems,
            prefixIcon: Icon(Icons.search, size: 18, color: ws.muted),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: spacing.md),
          DropdownButtonFormField<String>(
            key: const Key('builder-category'),
            isExpanded: true,
            initialValue: _categoryId.isEmpty ? null : _categoryId,
            style: ws.body.copyWith(color: ws.ink),
            iconEnabledColor: ws.muted,
            dropdownColor: ws.surface,
            decoration: InputDecoration(
              labelText: l10n.allCategories,
              labelStyle: ws.meta.copyWith(color: ws.muted),
              filled: true,
              fillColor: ws.canvas,
              contentPadding: EdgeInsetsDirectional.symmetric(
                horizontal: spacing.md,
                vertical: spacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ws.controlRadius),
                borderSide: BorderSide(color: ws.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ws.controlRadius),
                borderSide: BorderSide(color: ws.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ws.controlRadius),
                borderSide: BorderSide(color: ws.accent),
              ),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(l10n.allCategories)),
              ...categories.map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(
                    _localized(context, category.labelEn, category.labelAr),
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _categoryId = value ?? ''),
          ),
          SizedBox(height: spacing.md),
          for (var index = 0; index < catalog.length; index++) ...[
            if (index > 0) const WorkshopDivider(),
            _catalogRow(context, l10n, catalog[index]),
          ],
        ],
      ),
    );
  }

  Widget _catalogRow(
    BuildContext context,
    AppLocalizations l10n,
    PublishedItem item,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    final alreadyAdded = _contains(item.versionId);
    final meta =
        '${_localized(context, item.categoryLabelEn, item.categoryLabelAr)} '
        '· v${item.version.versionNo}'
        '${item.sampleData ? ' · ${l10n.sampleData}' : ''}';
    // Divider-separated row inside the panel — no nested card border.
    return Material(
      key: Key('published-item-${item.versionId}'),
      type: MaterialType.transparency,
      child: InkWell(
        onTap: alreadyAdded ? null : () => _add(item),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: spacing.xs),
          child: Row(
            children: [
              Container(
                width: ws.touchTarget,
                height: ws.touchTarget,
                decoration: BoxDecoration(
                  color: ws.canvas,
                  borderRadius: BorderRadius.circular(ws.chipRadius),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.fact_check_outlined,
                  size: 20,
                  color: ws.muted,
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _localized(context, item.labelEn, item.labelAr),
                      style: ws.bodyStrong.copyWith(color: ws.ink),
                    ),
                    SizedBox(height: spacing.xxs),
                    Text(meta, style: ws.meta.copyWith(color: ws.muted)),
                  ],
                ),
              ),
              IconButton(
                key: Key('catalog-add-${item.versionId}'),
                tooltip: l10n.add,
                onPressed: alreadyAdded ? null : () => _add(item),
                icon: Icon(
                  alreadyAdded
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: alreadyAdded ? ws.muted : ws.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right pane: active inspection sequence
  // ---------------------------------------------------------------------------
  Widget _sequencePanel(
    BuildContext context,
    AppLocalizations l10n,
    List<PublishedItem> catalog,
  ) {
    final spacing = context.spacing;
    final hasAvailable = catalog.any((item) => !_contains(item.versionId));
    return WorkshopCard(
      padding: _panelPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkshopSectionHeader(
            title: l10n.builderSequenceTitle,
            subtitle: l10n.templateItemsCount(_selected.length),
          ),
          SizedBox(height: spacing.md),
          if (_selected.isEmpty)
            WorkshopEmptyState(
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
                  showDivider: index < _selected.length - 1,
                  indexLabel: (index + 1).toString().padLeft(2, '0'),
                  title: _localized(context, item.labelEn, item.labelAr),
                  chips: [
                    WorkshopLockedPill(
                      label:
                          '${item.noteRequirement}/${item.evidenceRequirement}'
                          ' · ${l10n.lockedByPlatform}',
                    ),
                    StatusChip(
                      label:
                          '${_localized(context, item.categoryLabelEn, item.categoryLabelAr)}'
                          ' · v${item.versionNo}',
                    ),
                  ],
                  ruleNote: Text(
                    context.isArabic && item.instructionAr.isNotEmpty
                        ? item.instructionAr
                        : (item.instructionEn.isEmpty
                              ? _localized(
                                  context,
                                  item.categoryLabelEn,
                                  item.categoryLabelAr,
                                )
                              : item.instructionEn),
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
                        child: SizedBox.square(
                          dimension: context.ws.touchTarget,
                          child: Icon(
                            Icons.drag_handle,
                            key: Key('seq-drag-$index'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          SizedBox(height: spacing.md),
          WorkshopDropZone(
            key: const Key('builder-dropzone'),
            label: l10n.builderDropHint,
            hint: l10n.addItems,
            onTap: hasAvailable ? () => _addFirstAvailable(catalog) : null,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Version history (secondary, collapsible)
  // ---------------------------------------------------------------------------
  Widget _versionHistory(
    BuildContext context,
    AppLocalizations l10n,
    TemplateDetail template,
  ) {
    if (template.versions.isEmpty) {
      return const SizedBox.shrink();
    }
    final ws = context.ws;
    final spacing = context.spacing;
    return WorkshopCard(
      padding: EdgeInsetsDirectional.zero,
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: ws.surface),
          child: ExpansionTile(
            key: const Key('builder-version-history'),
            initiallyExpanded: true,
            tilePadding: EdgeInsetsDirectional.symmetric(
              horizontal: spacing.lg,
              vertical: spacing.xxs,
            ),
            childrenPadding: EdgeInsetsDirectional.only(bottom: spacing.sm),
            title: Text(
              l10n.versionHistory,
              style: ws.sectionTitle.copyWith(color: ws.ink),
            ),
            children: [
              for (
                var index = 0;
                index < template.versions.length;
                index++
              ) ...[
                if (index > 0) const WorkshopDivider(),
                _versionRow(context, l10n, template.versions[index]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _versionRow(
    BuildContext context,
    AppLocalizations l10n,
    TemplateVersionSummary version,
  ) {
    final ws = context.ws;
    final published = version.publishedAt.isEmpty
        ? ''
        : ' · ${version.publishedAt}';
    return ListTile(
      key: Key('template-version-${version.id}'),
      contentPadding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.lg,
        vertical: context.spacing.xs,
      ),
      title: Text(
        'v${version.versionNo} · '
        '${contentStatusLabel(l10n, version.status)}',
        style: ws.bodyStrong.copyWith(color: ws.ink),
      ),
      subtitle: Text(
        '${version.itemCount} ${l10n.itemsSelected}$published',
        style: ws.meta.copyWith(color: ws.muted),
      ),
      trailing: Icon(Icons.chevron_right, color: ws.muted),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TemplateVersionPage(
            templateId: widget.templateId,
            versionId: version.id,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Read-only state
  // ---------------------------------------------------------------------------
  Widget _readOnly(BuildContext context, AppLocalizations l10n) {
    return WorkshopCard(
      child: WorkshopEmptyState(
        title: l10n.readOnlyVersion,
        body: l10n.createDraft,
        icon: Icons.lock_outline,
        action: WorkshopButton(
          label: l10n.createDraft,
          onPressed: _busy ? null : _createDraft,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sticky save/publish bar
  // ---------------------------------------------------------------------------
  Widget _saveBar(
    BuildContext context,
    AppLocalizations l10n,
    TemplateDetail template,
    TemplateVersionView? draft,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    final editable = draft != null && !_busy;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
            vertical: spacing.md,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: spacing.sm,
                  runSpacing: spacing.sm,
                  children: [
                    WorkshopButton(
                      label: l10n.saveDraft,
                      icon: Icons.save_outlined,
                      variant: WorkshopButtonVariant.secondary,
                      onPressed: editable ? _save : null,
                    ),
                    WorkshopButton(
                      key: const Key('builder-preview'),
                      label: l10n.preview,
                      icon: Icons.visibility_outlined,
                      variant: WorkshopButtonVariant.ghost,
                      onPressed: draft == null || _selected.isEmpty || _busy
                          ? null
                          : _preview,
                    ),
                    WorkshopButton(
                      key: const Key('builder-publish'),
                      label: l10n.publishTemplate,
                      icon: Icons.publish_outlined,
                      isLoading: _busy,
                      onPressed: draft == null || _busy ? null : _publish,
                    ),
                    if (template.status != 'RETIRED')
                      PopupMenuButton<String>(
                        key: const Key('builder-more'),
                        tooltip: l10n.actions,
                        icon: SizedBox.square(
                          dimension: ws.touchTarget,
                          child: Icon(Icons.archive_outlined, color: ws.muted),
                        ),
                        onSelected: (value) {
                          if (value == 'retire') {
                            _retire();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'retire',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.archive_outlined,
                                  size: 18,
                                  color: ws.danger,
                                ),
                                SizedBox(width: spacing.sm),
                                Text(
                                  l10n.retire,
                                  style: ws.body.copyWith(color: ws.danger),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Drag Proxy
  // ---------------------------------------------------------------------------
  Widget _dragProxy(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, proxyChild) =>
          Material(type: MaterialType.transparency, child: proxyChild),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Logic & API Interactions
  // ---------------------------------------------------------------------------
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
              WorkshopSectionHeader(
                title: l10n.preview,
                subtitle: l10n.templateItemsCount(_selected.length),
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
                          child: WorkshopCard(
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
                                  'v${item.versionNo} · '
                                  '${item.noteRequirement}/'
                                  '${item.evidenceRequirement} · '
                                  '${l10n.lockedByPlatform}',
                                  style: context.texts.bodySmall,
                                ),
                              ],
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
