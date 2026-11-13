import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_category_picker.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_context_bar.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../components/platform_toolbar.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

import 'package:l10n/l10n.dart';

/// Full-screen guided template builder (category-first, no weights/scoring).
///
/// Steps: Details -> Categories -> Items+Order -> Review.
/// Contract: [templateId] is REQUIRED; the create flow creates a DRAFT first
/// and navigates here with the new id (no id-less builder).
class TemplateBuilderScreen extends ConsumerStatefulWidget {
  const TemplateBuilderScreen({super.key, required this.templateId});

  final String templateId;

  @override
  ConsumerState<TemplateBuilderScreen> createState() =>
      _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends ConsumerState<TemplateBuilderScreen> {
  static const int _totalSteps = 4;

  final _detailsFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _step = 0;
  String? _selectedVersionId;
  List<_CategoryState> _categories = [];
  String? _loadedVersionId;
  String? _prefilledTemplateId;
  bool _busy = false;

  @override
  void didUpdateWidget(TemplateBuilderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.templateId != widget.templateId) {
      _step = 0;
      _selectedVersionId = null;
      _loadedVersionId = null;
      _prefilledTemplateId = null;
      _categories = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (successMessage != null) _snack(successMessage);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _snack(failure.messageKey);
    } catch (_) {
      if (!mounted) return;
      _snack(ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _ensureDetails(GlobalTemplate template) {
    if (_prefilledTemplateId == template.id) return;
    _prefilledTemplateId = template.id;
    _nameController.text = _templateName(template);
    _descriptionController.text = _templateDescription(template);
  }

  void _syncVersion(TemplateVersionDetail detail) {
    if (_loadedVersionId == detail.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedVersionId == detail.id) return;
      setState(() {
        _loadedVersionId = detail.id;
        _selectedVersionId = detail.id;
        _categories = detail.categories
            .map(_CategoryState.fromTemplate)
            .toList(growable: true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final templateAsync = ref.watch(templateDetailProvider(widget.templateId));

    return PlatformShell(
      currentRoute: '/checklist/templates/${widget.templateId}',
      contextBar: templateAsync.maybeWhen(
        data: (template) => PlatformContextBar(
          breadcrumbs: [
            ContextBreadcrumbItem(
              label: strings.tKey(PlatformAdminKeys.pageTemplatesTitle),
              onTap: () => Navigator.of(context).pop(),
            ),
            ContextBreadcrumbItem(label: template.code),
          ],
        ),
        orElse: () => null,
      ),
      child: PlatformPage(
        maxWidth: 1200,
        child: templateAsync.when(
          loading: () => PlatformLoadingView(
            message: strings.tKey(CommonKeys.stateLoading),
          ),
          error: (error, stackTrace) => PlatformErrorView(
            message: strings.tKey(CommonKeys.emptyTitle),
            onRetry: () =>
                ref.invalidate(templateDetailProvider(widget.templateId)),
          ),
          data: (template) => _buildBody(context, strings, template),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    dynamic strings,
    GlobalTemplate template,
  ) {
    _ensureDetails(template);
    final versions = [...template.versions]
      ..sort((a, b) => b.versionNo.compareTo(a.versionNo));
    final selected =
        _findVersion(versions, _selectedVersionId) ??
        (versions.isEmpty ? null : versions.first);
    final versionId = selected?.id ?? '';
    final editing = selected?.status == 'DRAFT';
    final hasDraft = versions.any((version) => version.status == 'DRAFT');

    final versionAsync = versionId.isEmpty
        ? null
        : ref.watch(
            templateVersionDetailProvider(
              ItemVersionKey(widget.templateId, versionId),
            ),
          );
    if (versionAsync != null) {
      final detail = versionAsync.asData?.value;
      if (detail != null) {
        _syncVersion(detail);
      }
    }

    final includedCategories = _categories.where(_hasIncludedItems).toList();
    final includedCount = includedCategories
        .expand((category) => category.items.where((item) => item.included))
        .length;
    final displayName = _templateName(template);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformPageHeader(
          title: strings.tKey(PlatformAdminKeys.pageTemplateBuilderTitle),
          subtitle:
              '${strings.tArgsKey(PlatformAdminKeys.stepCounter, {'current': _step + 1, 'total': _totalSteps})} · $displayName',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final sidePanel = _buildSidePanel(
              strings,
              template,
              versions,
              selected,
              includedCategories.length,
              includedCount,
              compact: !wide,
            );
            final mainColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selected?.status == 'PENDING_APPROVAL') ...[
                  PlatformSectionCard(
                    child: Text(
                      strings.tKey(CommonKeys.statusPendingApproval),
                      style: PtTheme.font(
                        12,
                        weight: FontWeight.w600,
                        color: PtTheme.gold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                PlatformSectionCard(child: _buildStepIndicator(strings)),
                const SizedBox(height: 16),
                if (versions.isEmpty)
                  _buildNoVersion(strings)
                else if (_step == 0)
                  _buildDetailsStep(strings, template, editing)
                else if (_step == 1)
                  _buildCategoriesStep(strings, editing)
                else if (_step == 2)
                  _buildItemsStep(
                    strings,
                    editing,
                    includedCategories.length,
                    includedCount,
                  )
                else
                  _buildReviewStep(
                    strings,
                    template,
                    selected,
                    editing,
                    hasDraft,
                    includedCategories.length,
                    includedCount,
                  ),
                const SizedBox(height: 16),
                _buildStepNav(strings, versions.isEmpty),
              ],
            );
            // Sticky summary/action area on wide viewports; the same
            // summary stacks above the steps on compact viewports.
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: mainColumn),
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: SizedBox(width: 320, child: sidePanel),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [sidePanel, const SizedBox(height: 12), mainColumn],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSidePanel(
    dynamic strings,
    GlobalTemplate template,
    List<TemplateVersionSummary> versions,
    TemplateVersionSummary? selected,
    int includedCategories,
    int includedCount, {
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformSectionCard(child: _TemplateSummary(template: template)),
        const SizedBox(height: 12),
        PlatformSectionCard(
          child: _VersionSelector(
            versions: versions,
            selected: selected,
            enabled: !_busy,
            onChanged: (id) {
              setState(() {
                _selectedVersionId = id;
                _loadedVersionId = null;
                _categories = [];
              });
            },
          ),
        ),
        // Progress counts live in the sticky rail on wide viewports; on
        // compact widths the steps toolbar and review step already show
        // them, so the extra card is omitted to keep Next in view.
        if (!compact) ...[
          const SizedBox(height: 12),
          PlatformSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlatformSectionHeader(
                  title: strings.tKey(PlatformAdminKeys.stepTemplateReview),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    PlatformMetaPill(
                      label: strings.tKey(
                        PlatformAdminKeys.tabChecklistCategories,
                      ),
                      value: '$includedCategories',
                    ),
                    PlatformMetaPill(
                      label: strings.tKey(PlatformAdminKeys.tabChecklistItems),
                      value: '$includedCount',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Step titles. Gap: no tmplStepItems key exists, so the Items+Order step
  /// uses the closest key [items] ("Inspection items").
  List<String> _stepTitles(dynamic strings) => [
    strings.tKey(PlatformAdminKeys.stepTemplateDetails),
    strings.tKey(PlatformAdminKeys.stepTemplateCategories),
    strings.tKey(CommonKeys.labelItems),
    strings.tKey(PlatformAdminKeys.stepTemplateReview),
  ];

  Widget _buildStepIndicator(dynamic strings) {
    final titles = _stepTitles(strings);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < _totalSteps; index++)
          PlatformFilterChip(
            label: '${index + 1}. ${titles[index]}',
            selected: _step == index,
            onTap: () {
              if (_busy) return;
              setState(() => _step = index);
            },
          ),
      ],
    );
  }

  Widget _buildNoVersion(dynamic strings) {
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformEmptyView(title: strings.tKey(CommonKeys.emptyTitle)),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PlatformPrimaryButton(
              label: strings.tKey(CommonKeys.buttonCreateDraft),
              icon: Icons.add_rounded,
              onPressed: _busy ? null : _createDraft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(
    dynamic strings,
    GlobalTemplate template,
    bool editing,
  ) {
    return PlatformSectionCard(
      child: Form(
        key: _detailsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlatformSectionHeader(
              title: strings.tKey(PlatformAdminKeys.stepTemplateDetails),
              subtitle: strings.tKey(PlatformAdminKeys.pageTemplatesHelper),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${strings.tKey(PlatformAdminKeys.fieldTemplateCode)}: ',
                  style: PtTheme.font(
                    12,
                    weight: FontWeight.w700,
                    color: PtTheme.muted,
                  ),
                ),
                Flexible(
                  child: Text(
                    template.code,
                    style: PtTheme.font(
                      13,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              key: const Key('template-builder-name'),
              controller: _nameController,
              label: strings.tKey(PlatformAdminKeys.fieldTemplateName),
              enabled: editing,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? strings.tKey(CommonKeys.validationRequired)
                  : null,
            ),
            const SizedBox(height: 12),
            PlatformTextField(
              key: const Key('template-builder-description'),
              controller: _descriptionController,
              label: strings.tKey(PlatformAdminKeys.fieldTemplateDescription),
              maxLines: 3,
              enabled: editing,
            ),
            if (!editing) ...[
              const SizedBox(height: 8),
              Text(
                strings.tKey(PlatformAdminKeys.alertVersionImmutable),
                style: PtTheme.font(12, color: PtTheme.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesStep(dynamic strings, bool editing) {
    final available = _availableCategories();
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.stepTemplateCategories),
            subtitle: strings.tKey(
              PlatformAdminKeys.filterTemplateSearchCategories,
            ),
          ),
          const SizedBox(height: 12),
          if (editing)
            PlatformCategoryPicker(
              categories: [
                ...available,
                ..._categories.map(
                  (category) => PlatformCategory(
                    id: category.categoryId,
                    code: category.categoryCode,
                    name: category.name,
                    status: 'ACTIVE',
                    sortOrder: 0,
                    active: true,
                    itemCount: category.itemCount,
                  ),
                ),
              ],
              selectedId: null,
              onChanged: (id) {
                if (id == null) return;
                final match = available.where((c) => c.id == id).toList();
                if (match.isEmpty) return;
                _addCategory(match.first);
              },
            ),
          if (editing) const SizedBox(height: 12),
          if (_categories.isEmpty)
            PlatformEmptyView(title: strings.tKey(CommonKeys.emptyTitle))
          else
            for (var index = 0; index < _categories.length; index++) ...[
              _buildCategoryOrderRow(strings, index, editing),
              if (index != _categories.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildCategoryOrderRow(dynamic strings, int index, bool editing) {
    final category = _categories[index];
    final displayName = category.name.isEmpty
        ? category.categoryCode
        : category.name;
    final included = category.items.where((item) => item.included).length;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${category.categoryCode} · $included / '
                  '${category.items.length} ${strings.tKey(PlatformAdminKeys.tabChecklistItems)}',
                  style: PtTheme.font(12, color: PtTheme.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (editing) ...[
            IconButton(
              tooltip: strings.tKey(CommonKeys.buttonMoveUp),
              onPressed: index == 0
                  ? null
                  : () => setState(() => _moveCategory(index, -1)),
              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            IconButton(
              tooltip: strings.tKey(CommonKeys.buttonMoveDown),
              onPressed: index == _categories.length - 1
                  ? null
                  : () => setState(() => _moveCategory(index, 1)),
              icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            IconButton(
              tooltip: strings.tKey(CommonKeys.buttonDelete),
              onPressed: () => setState(() => _categories.removeAt(index)),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: PtTheme.rose,
              ),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ] else
            PlatformStatusChip(status: category.categoryCode),
        ],
      ),
    );
  }

  Widget _buildItemsStep(
    dynamic strings,
    bool editing,
    int includedCategories,
    int includedCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformToolbar(
          searchHint: strings.tKey(PlatformAdminKeys.filterTemplateSearchItems),
          onSearchChanged: (_) {},
          countLabel:
              '${strings.tArgsKey(PlatformAdminKeys.pageTemplateProgressCategories, {'count': includedCategories})}'
              '  ·  ${strings.tArgsKey(PlatformAdminKeys.pageTemplateProgressItems, {'count': includedCount})}',
        ),
        const SizedBox(height: 14),
        if (_categories.isEmpty)
          PlatformEmptyView(title: strings.tKey(CommonKeys.emptyTitle))
        else
          for (var index = 0; index < _categories.length; index++) ...[
            _CategoryItemsSection(
              key: ValueKey('${_categories[index].categoryId}-$index-$editing'),
              category: _categories[index],
              editing: editing,
              canMoveUp: editing && index > 0,
              canMoveDown: editing && index < _categories.length - 1,
              onMoveUp: () => setState(() => _moveCategory(index, -1)),
              onMoveDown: () => setState(() => _moveCategory(index, 1)),
              onRemoveCategory: () =>
                  setState(() => _categories.removeAt(index)),
              onChanged: () => setState(() {}),
              onAddItem: () => _addItemDialog(_categories[index]),
            ),
            if (index != _categories.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildReviewStep(
    dynamic strings,
    GlobalTemplate template,
    TemplateVersionSummary? selected,
    bool editing,
    bool hasDraft,
    int includedCategories,
    int includedCount,
  ) {
    final displayName = _templateName(template);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlatformSectionHeader(
                title: strings.tKey(PlatformAdminKeys.stepTemplateReview),
                subtitle: strings.tKey(PlatformAdminKeys.helpStepReview),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 18,
                    color: PtTheme.deepGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.tArgsKey(
                        PlatformAdminKeys.pageTemplateProgressCategories,
                        {'count': includedCategories},
                      ),
                      style: PtTheme.font(
                        14,
                        weight: FontWeight.w600,
                        color: PtTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.checklist_rounded,
                    size: 18,
                    color: PtTheme.deepGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.tArgsKey(
                        PlatformAdminKeys.pageTemplateProgressItems,
                        {'count': includedCount},
                      ),
                      style: PtTheme.font(
                        14,
                        weight: FontWeight.w600,
                        color: PtTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${template.code} · $displayName',
                style: PtTheme.font(13, color: PtTheme.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PlatformSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlatformSectionHeader(
                title: strings.tKey(
                  PlatformAdminKeys.sectionTemplateVersionHistory,
                ),
                subtitle: selected == null
                    ? null
                    : 'v${selected.versionNo} · ${selected.status}',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!hasDraft)
                    PlatformPrimaryButton(
                      label: strings.tKey(CommonKeys.buttonCreateDraft),
                      icon: Icons.add_rounded,
                      onPressed: _busy ? null : _createDraft,
                    ),
                  if (editing)
                    PlatformPrimaryButton(
                      label: strings.tKey(CommonKeys.buttonSaveDraft),
                      icon: Icons.save_outlined,
                      onPressed: _busy ? null : () => _save(selected?.id ?? ''),
                    ),
                  if (selected?.status == 'DRAFT')
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonTemplatePublish,
                      ),
                      icon: Icons.publish_rounded,
                      onPressed: _busy
                          ? null
                          : () => _publish(selected?.id ?? ''),
                    ),
                  if (selected?.status == 'PENDING_APPROVAL') ...[
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonTemplateApprove,
                      ),
                      icon: Icons.check_rounded,
                      onPressed: _busy
                          ? null
                          : () => _approve(selected?.id ?? ''),
                    ),
                    PlatformSecondaryButton(
                      label: strings.tKey(
                        PlatformAdminKeys.buttonTemplateReject,
                      ),
                      icon: Icons.close_rounded,
                      destructive: true,
                      onPressed: _busy
                          ? null
                          : () => _reject(selected?.id ?? ''),
                    ),
                  ],
                  if (selected != null && !editing && hasDraft)
                    Text(
                      strings.tKey(PlatformAdminKeys.alertVersionImmutable),
                      style: PtTheme.font(12, color: PtTheme.muted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepNav(dynamic strings, bool noVersions) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_step > 0)
          PlatformSecondaryButton(
            label: strings.tKey(CommonKeys.buttonPrevious),
            icon: Icons.arrow_back_rounded,
            onPressed: _busy
                ? null
                : () => setState(() => _step = (_step - 1).clamp(0, 3)),
          ),
        if (_step < _totalSteps - 1 && !noVersions)
          PlatformPrimaryButton(
            label: strings.tKey(CommonKeys.buttonNext),
            icon: Icons.arrow_forward_rounded,
            onPressed: _busy ? null : _continue,
          ),
      ],
    );
  }

  void _continue() {
    if (_step == 0) {
      if (!(_detailsFormKey.currentState?.validate() ?? false)) return;
    }
    setState(() => _step = (_step + 1).clamp(0, _totalSteps - 1));
  }

  bool _hasIncludedItems(_CategoryState category) =>
      category.items.any((item) => item.included);

  void _moveCategory(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _categories.length) return;
    final moved = _categories.removeAt(index);
    _categories.insert(target, moved);
  }

  List<PlatformCategory> _availableCategories() {
    final used = _categories.map((category) => category.categoryId).toSet();
    final all =
        ref.watch(categoriesProvider).asData?.value ??
        const <PlatformCategory>[];
    return all.where((category) => !used.contains(category.id)).toList();
  }

  void _addCategory(PlatformCategory category) {
    setState(() {
      final existing = _categories
          .where((c) => c.categoryId == category.id)
          .toList();
      if (existing.isNotEmpty) return;
      _categories.add(
        _CategoryState(
          categoryId: category.id,
          categoryCode: category.code,
          name: _categoryName(category),
          itemCount: category.itemCount,
          included: true,
          items: [],
        ),
      );
    });
  }

  Future<void> _addItemDialog(_CategoryState category) async {
    final strings = ref.watch(uiStringsProvider);
    final List<PlatformItem> all;
    try {
      all = await ref.read(itemsProvider(const ItemQuery()).future);
    } catch (_) {
      if (mounted) {
        _snack(ref.read(uiStringsProvider).tKey(CommonKeys.errorGeneric));
      }
      return;
    }
    if (!mounted) return;
    final used = category.items.map((item) => item.itemId).toSet();
    final available = all
        .where(
          (item) =>
              item.categoryId == category.categoryId && !used.contains(item.id),
        )
        .toList();
    final selected = await showPlatformDialog<PlatformItem>(
      context: context,
      title: strings.tKey(PlatformAdminKeys.buttonTemplateAddItem),
      body: _ItemPickerBody(items: available),
    );
    if (selected == null || !mounted) return;
    try {
      final detail = await ref
          .read(platformConfigApiProvider)
          .itemDetail(selected.id);
      final version = detail.draftVersion ?? detail.publishedVersion;
      if (version == null) {
        _snack(strings.tKey(CommonKeys.emptyTitle));
        return;
      }
      setState(() {
        category.items.add(
          _ItemState(
            itemId: selected.id,
            itemVersionId: version.id,
            itemCode: selected.code,
            label: _itemLabel(selected),
            included: true,
          ),
        );
      });
    } catch (_) {
      if (mounted) _snack(strings.tKey(CommonKeys.errorGeneric));
    }
  }

  /// Persists details (updateTemplate), then the ordered structure
  /// (replaceTemplateCategories/replaceTemplateItems).
  Future<void> _save(String versionId) async {
    if (versionId.isEmpty) return;
    await _run(
      () async {
        final actions = ref.read(platformConfigActionsProvider);
        await actions.updateTemplate(widget.templateId, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
        });
        await actions.replaceTemplateCategories(widget.templateId, versionId, [
          for (var index = 0; index < _categories.length; index++)
            {
              'categoryId': _categories[index].categoryId,
              'included': true,
              'sortOrder': index + 1,
            },
        ]);
        await actions.replaceTemplateItems(widget.templateId, versionId, [
          for (final category in _categories)
            for (var index = 0; index < category.items.length; index++)
              if (category.items[index].included)
                {
                  'categoryId': category.categoryId,
                  'itemVersionId': category.items[index].itemVersionId,
                  'included': true,
                  'sortOrder': index + 1,
                },
        ]);
        if (mounted) {
          setState(() => _loadedVersionId = null);
          ref.invalidate(
            templateVersionDetailProvider(
              ItemVersionKey(widget.templateId, versionId),
            ),
          );
        }
      },
      successMessage: ref
          .read(uiStringsProvider)
          .tKey(CommonKeys.buttonSaveDraft),
    );
  }

  Future<void> _createDraft() async {
    await _run(() async {
      final updated = await ref
          .read(platformConfigActionsProvider)
          .createTemplateDraft(widget.templateId);
      if (!mounted) return;
      TemplateVersionSummary? draft;
      for (final version in updated.versions) {
        if (version.status == 'DRAFT') {
          draft = version;
          break;
        }
      }
      if (draft != null) {
        setState(() {
          _selectedVersionId = draft!.id;
          _loadedVersionId = null;
          _categories = [];
        });
      }
    });
  }

  Future<void> _publish(String versionId) async {
    await _run(
      () => ref
          .read(platformConfigActionsProvider)
          .publishTemplate(widget.templateId, versionId)
          .then((_) {}),
      successMessage: ref
          .read(uiStringsProvider)
          .tKey(CommonKeys.statusPendingApproval),
    );
  }

  Future<void> _approve(String versionId) async {
    await _run(
      () => ref
          .read(platformConfigActionsProvider)
          .approveTemplate(widget.templateId, versionId)
          .then((_) {}),
      successMessage: ref
          .read(uiStringsProvider)
          .tKey(PlatformAdminKeys.statusPublished),
    );
  }

  Future<void> _reject(String versionId) async {
    await _run(
      () => ref
          .read(platformConfigActionsProvider)
          .rejectTemplate(widget.templateId, versionId)
          .then((_) {}),
      successMessage: ref.read(uiStringsProvider).tKey(CommonKeys.statusDraft),
    );
  }
}

class _CategoryState {
  _CategoryState({
    required this.categoryId,
    required this.categoryCode,
    required this.name,
    required this.itemCount,
    required this.included,
    required this.items,
  });

  factory _CategoryState.fromTemplate(TemplateCategory category) =>
      _CategoryState(
        categoryId: category.categoryId,
        categoryCode: category.categoryCode,
        name: category.name,
        itemCount: category.itemCount,
        included: category.included,
        items: category.items
            .map(
              (item) => _ItemState(
                itemId: item.itemId,
                itemVersionId: item.itemVersionId,
                itemCode: item.itemCode,
                label: item.label,
                included: item.included,
              ),
            )
            .toList(growable: true),
      );

  final String categoryId;
  final String categoryCode;
  final String name;
  final int itemCount;
  final bool included;
  final List<_ItemState> items;
}

class _ItemState {
  _ItemState({
    required this.itemId,
    required this.itemVersionId,
    required this.itemCode,
    required this.label,
    required this.included,
  });

  final String itemId;
  final String itemVersionId;
  final String itemCode;
  final String label;
  bool included;
}

class _ItemPickerBody extends ConsumerStatefulWidget {
  const _ItemPickerBody({required this.items});

  final List<PlatformItem> items;

  @override
  ConsumerState<_ItemPickerBody> createState() => _ItemPickerBodyState();
}

class _ItemPickerBodyState extends ConsumerState<_ItemPickerBody> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.items
        : widget.items
              .where((item) {
                return item.code.toLowerCase().contains(query) ||
                    _itemLabel(item).toLowerCase().contains(query);
              })
              .toList(growable: false);
    if (filtered.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformTextField(
            hint: strings.tKey(PlatformAdminKeys.filterTemplateSearchItems),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Text(
            strings.tKey(CommonKeys.emptyTitle),
            style: PtTheme.font(13, color: PtTheme.muted),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformTextField(
          hint: strings.tKey(PlatformAdminKeys.filterTemplateSearchItems),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return ListTile(
                dense: true,
                title: Text('${item.code} · ${_itemLabel(item)}'),
                onTap: () => Navigator.of(context).pop(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryItemsSection extends ConsumerStatefulWidget {
  const _CategoryItemsSection({
    super.key,
    required this.category,
    required this.editing,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemoveCategory,
    required this.onChanged,
    required this.onAddItem,
  });

  final _CategoryState category;
  final bool editing;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemoveCategory;
  final VoidCallback onChanged;
  final VoidCallback onAddItem;

  @override
  ConsumerState<_CategoryItemsSection> createState() =>
      _CategoryItemsSectionState();
}

class _CategoryItemsSectionState extends ConsumerState<_CategoryItemsSection> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final category = widget.category;
    final query = _query.trim().toLowerCase();
    final visibleItems = query.isEmpty
        ? category.items
        : category.items
              .where(
                (item) =>
                    item.itemCode.toLowerCase().contains(query) ||
                    item.label.toLowerCase().contains(query),
              )
              .toList(growable: false);
    final included = category.items.where((item) => item.included).length;
    final displayName = category.name.isEmpty
        ? category.categoryCode
        : category.name;

    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: displayName,
            subtitle:
                '$included / ${category.items.length} ${strings.tKey(PlatformAdminKeys.tabChecklistItems)}',
            action: widget.editing
                ? Wrap(
                    spacing: 0,
                    children: [
                      IconButton(
                        tooltip: strings.tKey(CommonKeys.buttonMoveUp),
                        onPressed: widget.canMoveUp ? widget.onMoveUp : null,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                      IconButton(
                        tooltip: strings.tKey(CommonKeys.buttonMoveDown),
                        onPressed: widget.canMoveDown
                            ? widget.onMoveDown
                            : null,
                        icon: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                      IconButton(
                        tooltip: strings.tKey(CommonKeys.buttonDelete),
                        onPressed: widget.onRemoveCategory,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: PtTheme.rose,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                    ],
                  )
                : PlatformStatusChip(status: category.categoryCode),
          ),
          const SizedBox(height: 8),
          PlatformTextField(
            hint: strings.tKey(PlatformAdminKeys.filterTemplateSearchItems),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          if (category.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                strings.tKey(PlatformAdminKeys.emptyTemplateCategory),
                style: PtTheme.font(13, color: PtTheme.muted),
              ),
            )
          else if (visibleItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                strings.tKey(CommonKeys.emptyTitle),
                style: PtTheme.font(13, color: PtTheme.muted),
              ),
            )
          else
            for (
              var itemIndex = 0;
              itemIndex < visibleItems.length;
              itemIndex++
            )
              _buildItemRow(
                strings,
                category,
                visibleItems[itemIndex],
                category.items.indexOf(visibleItems[itemIndex]),
              ),
          if (widget.editing) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PlatformSecondaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonTemplateAddItem),
                icon: Icons.add_rounded,
                onPressed: widget.onAddItem,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(
    dynamic strings,
    _CategoryState category,
    _ItemState item,
    int index,
  ) {
    final label = item.label;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 8),
      decoration: BoxDecoration(
        color: item.included
            ? PtTheme.white
            : PtTheme.canvas.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.included
              ? PtTheme.border
              : PtTheme.border.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: item.included,
            onChanged: widget.editing
                ? (value) {
                    setState(() => item.included = value ?? false);
                    widget.onChanged();
                  }
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.itemCode,
                  style: PtTheme.font(
                    11,
                    weight: FontWeight.w700,
                    color: PtTheme.muted,
                    tracking: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label.isEmpty ? item.itemCode : label,
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    weight: FontWeight.w600,
                    color: item.included ? PtTheme.ink : PtTheme.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.editing) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: strings.tKey(CommonKeys.buttonMoveUp),
              onPressed: index == 0
                  ? null
                  : () {
                      setState(() {
                        final moved = category.items.removeAt(index);
                        category.items.insert(index - 1, moved);
                      });
                      widget.onChanged();
                    },
              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            IconButton(
              tooltip: strings.tKey(CommonKeys.buttonMoveDown),
              onPressed: index == category.items.length - 1
                  ? null
                  : () {
                      setState(() {
                        final moved = category.items.removeAt(index);
                        category.items.insert(index + 1, moved);
                      });
                      widget.onChanged();
                    },
              icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            IconButton(
              tooltip: strings.tKey(CommonKeys.buttonDelete),
              onPressed: () {
                setState(() => category.items.removeAt(index));
                widget.onChanged();
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: PtTheme.rose,
              ),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ] else ...[
            const SizedBox(width: 4),
            PlatformStatusChip(
              status: item.included
                  ? strings.tKey(CommonKeys.statusActive)
                  : strings.tKey(CommonKeys.statusDraft),
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplateSummary extends ConsumerWidget {
  const _TemplateSummary({required this.template});

  final GlobalTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PlatformStatusChip(status: template.code),
            PlatformStatusChip(status: template.status),
            PlatformMetaPill(
              label: strings.tKey(CommonKeys.labelVersions),
              value: '${template.versionCount}',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _templateName(template),
          style: PtTheme.font(
            22,
            lineHeight: 28,
            weight: FontWeight.w800,
            color: PtTheme.ink,
          ),
        ),
        if (_templateDescription(template).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _templateDescription(template),
            style: PtTheme.font(13, color: PtTheme.muted),
          ),
        ],
      ],
    );
  }
}

class _VersionSelector extends ConsumerWidget {
  const _VersionSelector({
    required this.versions,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final List<TemplateVersionSummary> versions;
  final TemplateVersionSummary? selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final current = selected;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          strings.tKey(CommonKeys.labelVersions),
          style: PtTheme.font(12, weight: FontWeight.w700, color: PtTheme.ink),
        ),
        if (current != null)
          PlatformDropdown<String>(
            label: strings.tKey(CommonKeys.labelVersions),
            value: current.id,
            items: [
              for (final version in versions)
                DropdownMenuItem(
                  value: version.id,
                  child: Text('v${version.versionNo} · ${version.status}'),
                ),
            ],
            onChanged: (value) {
              if (enabled && value != null) onChanged(value);
            },
          ),
        if (current != null) PlatformStatusChip(status: current.status),
      ],
    );
  }
}

TemplateVersionSummary? _findVersion(
  List<TemplateVersionSummary> versions,
  String? id,
) {
  if (id == null) return null;
  for (final version in versions) {
    if (version.id == id) return version;
  }
  return null;
}

String _templateName(GlobalTemplate template) {
  return template.name.isEmpty ? template.code : template.name;
}

String _templateDescription(GlobalTemplate template) => template.description;

String _categoryName(PlatformCategory category) {
  return category.name.isEmpty ? category.code : category.name;
}

String _itemLabel(PlatformItem item) {
  return item.label.isEmpty ? item.code : item.label;
}
