import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

const _resultCodes = <String>[
  'NO_ISSUE_OBSERVED',
  'ATTENTION_RECOMMENDED',
  'DEFECT_FOUND',
];
const _inputTypes = <String>[
  'SELECT',
  'MULTI_SELECT',
  'NUMBER',
  'BOOLEAN',
  'TEXT',
];
const _evidenceTypes = <String>['PHOTO', 'VIDEO', 'DOCUMENT', ''];
const _directions = <String>['HIGHER_IS_BETTER', 'LOWER_IS_BETTER'];
const _requiredForStatuses = <String>[
  'ACTIVE',
  'DRAFT',
  'PUBLISHED',
  'RETIRED',
];

class MasterItemEditorScreen extends StatelessWidget {
  const MasterItemEditorScreen({super.key, this.itemId});

  final String? itemId;

  @override
  Widget build(BuildContext context) {
    final id = itemId;
    if (id == null) {
      return const _CreateItemForm();
    }
    return _EditItemView(itemId: id);
  }
}

class _EditorShell extends StatelessWidget {
  const _EditorShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final showSidebar = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSidebar)
            PlatformSidebar(
              currentRoute: '/master-library',
              onNavigate: (route) => context.go(route),
            ),
          Expanded(
            child: Column(
              children: [
                const PlatformHeader(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = constraints.maxWidth >= 900
                          ? 32.0
                          : 16.0;
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: child,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateItemForm extends ConsumerStatefulWidget {
  const _CreateItemForm();

  @override
  ConsumerState<_CreateItemForm> createState() => _CreateItemFormState();
}

class _CreateItemFormState extends ConsumerState<_CreateItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _labelEnController = TextEditingController();
  final _labelArController = TextEditingController();
  final _instructionEnController = TextEditingController();
  final _instructionArController = TextEditingController();
  final _unitController = TextEditingController();
  final _sensorController = TextEditingController();
  final _specEnController = TextEditingController();
  final _specArController = TextEditingController();
  final _maxTyreAgeController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  String _categoryId = '';
  bool _safetyCritical = false;
  bool _multiPoint = false;
  bool _allowFreeTextNote = false;
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _labelEnController.dispose();
    _labelArController.dispose();
    _instructionEnController.dispose();
    _instructionArController.dispose();
    _unitController.dispose();
    _sensorController.dispose();
    _specEnController.dispose();
    _specArController.dispose();
    _maxTyreAgeController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_formKey.currentState?.validate() != true) return;
    if (_categoryId.isEmpty) return;
    setState(() => _saving = true);
    try {
      final detail = await ref
          .read(platformConfigActionsProvider)
          .createItem(<String, dynamic>{
            'stableCode': _codeController.text.trim(),
            'categoryId': _categoryId,
            'labelEn': _labelEnController.text.trim(),
            'labelAr': _labelArController.text.trim(),
            'instructionEn': _instructionEnController.text.trim(),
            'instructionAr': _instructionArController.text.trim(),
            'sampleData': false,
            'resultOptions': const <String>[
              'NO_ISSUE_OBSERVED',
              'ATTENTION_RECOMMENDED',
              'DEFECT_FOUND',
            ],
            'severityPolicy': '{}',
            'applicability': '{}',
            'reasonCodes': const <String>[],
            'noteRequirement': 'OPTIONAL',
            'evidenceRequirement': 'REQUIRED_MIN_N',
            'minPhotos': 1,
            'equipmentIds': const <String>[],
            'guideImageId': null,
            'measurementUnit': _unitController.text.trim(),
            'sensorTool': _sensorController.text.trim(),
            'standardSpecEn': _specEnController.text.trim(),
            'standardSpecAr': _specArController.text.trim(),
            'safetyCritical': _safetyCritical,
            'multiPoint': _multiPoint,
            'maxTyreAgeYears': int.tryParse(
              _maxTyreAgeController.text.trim(),
            ),
            'allowFreeTextNote': _allowFreeTextNote,
            'sortOrder': int.tryParse(_sortOrderController.text.trim()) ?? 0,
          });
      if (!mounted) return;
      _showSnack(context, l10n.itemCreated);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MasterItemEditorScreen(itemId: detail.item.id),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories =
        categoriesAsync.asData?.value ?? const <PlatformCategory>[];

    return _EditorShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 18),
            _SectionCard(
              title: l10n.basics,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldGrid(
                    children: [
                      _InputField(
                        controller: _codeController,
                        label: l10n.itemCode,
                        validator: (value) => _required(value, l10n),
                      ),
                      _DropdownField<String>(
                        label: l10n.category,
                        value: _categoryId,
                        items: [
                          const DropdownMenuItem(value: '', child: Text('—')),
                          for (final category in categories)
                            DropdownMenuItem(
                              value: category.id,
                              child: Text(
                                category.name.isEmpty
                                    ? category.code
                                    : category.name,
                              ),
                            ),
                        ],
                        validator: (value) =>
                            value == null || value.isEmpty
                            ? l10n.category
                            : null,
                        onChanged: (value) =>
                            setState(() => _categoryId = value ?? ''),
                      ),
                      _InputField(
                        controller: _labelEnController,
                        label: l10n.labelEn,
                        validator: (value) => _required(value, l10n),
                      ),
                      _InputField(
                        controller: _labelArController,
                        label: l10n.labelAr,
                        textDirection: TextDirection.rtl,
                        validator: (value) => _required(value, l10n),
                      ),
                      _InputField(
                        controller: _instructionEnController,
                        label: l10n.englishContent,
                        maxLines: 3,
                      ),
                      _InputField(
                        controller: _instructionArController,
                        label: l10n.arabicContent,
                        maxLines: 3,
                        textDirection: TextDirection.rtl,
                      ),
                      _InputField(
                        controller: _unitController,
                        label: l10n.measurementUnit,
                      ),
                      _InputField(
                        controller: _sensorController,
                        label: l10n.sensorTool,
                      ),
                      _InputField(
                        controller: _specEnController,
                        label: l10n.standardSpecEn,
                      ),
                      _InputField(
                        controller: _specArController,
                        label: l10n.standardSpecAr,
                        textDirection: TextDirection.rtl,
                      ),
                      _InputField(
                        controller: _maxTyreAgeController,
                        label: l10n.maxTyreAge,
                        keyboardType: TextInputType.number,
                      ),
                      _InputField(
                        controller: _sortOrderController,
                        label: l10n.categoryOrder,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldGrid(
                    children: [
                      _SwitchTile(
                        label: l10n.safetyCritical,
                        value: _safetyCritical,
                        onChanged: (value) =>
                            setState(() => _safetyCritical = value),
                      ),
                      _SwitchTile(
                        label: l10n.multiPoint,
                        value: _multiPoint,
                        onChanged: (value) =>
                            setState(() => _multiPoint = value),
                      ),
                      _SwitchTile(
                        label: l10n.allowFreeText,
                        value: _allowFreeTextNote,
                        onChanged: (value) =>
                            setState(() => _allowFreeTextNote = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  style: _outlinedButtonStyle(),
                  child: Text(
                    l10n.cancel,
                    style: PtTheme.font(
                      13,
                      weight: FontWeight.w700,
                      color: PtTheme.muted,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: _primaryButtonStyle(),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: PtTheme.white,
                          ),
                        )
                      : Text(
                          l10n.save,
                          style: PtTheme.font(
                            13,
                            weight: FontWeight.w700,
                            color: PtTheme.white,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: PtTheme.muted,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.masterLibraryTitle,
                style: PtTheme.font(
                  11,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                  tracking: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.itemEditor,
          style: PtTheme.font(
            26,
            lineHeight: 32,
            weight: FontWeight.w800,
            color: PtTheme.ink,
            tracking: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.addItem,
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
        ),
      ],
    );
  }
}

class _EditItemView extends ConsumerStatefulWidget {
  const _EditItemView({required this.itemId});

  final String itemId;

  @override
  ConsumerState<_EditItemView> createState() => _EditItemViewState();
}

class _EditItemViewState extends ConsumerState<_EditItemView> {
  String? _selectedVersionId;
  int _section = 0;
  bool _creatingDraft = false;
  bool _publishing = false;

  Future<void> _createDraft() async {
    setState(() => _creatingDraft = true);
    try {
      await ref
          .read(platformConfigActionsProvider)
          .createDraft(widget.itemId);
      if (!mounted) return;
      setState(() => _selectedVersionId = null);
      ref.invalidate(itemDetailProvider(widget.itemId));
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _creatingDraft = false);
    }
  }

  Future<void> _publish(PlatformItemVersion draft) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.publishItem,
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
                '${l10n.publishItem} · v${draft.versionNo}',
                style: PtTheme.font(
                  13,
                  lineHeight: 19,
                  color: PtTheme.muted,
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
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: PtTheme.deepGreen),
              child: Text(
                l10n.publishItem,
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
    setState(() => _publishing = true);
    try {
      await ref
          .read(platformConfigActionsProvider)
          .publishItem(widget.itemId, draft.id);
      if (!mounted) return;
      _showSnack(context, l10n.itemPublished);
      setState(() => _selectedVersionId = null);
      ref.invalidate(itemDetailProvider(widget.itemId));
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(itemDetailProvider(widget.itemId));
    return _EditorShell(
      child: detailAsync.when(
        loading: () => _StatePanel(
          child: Column(
            children: [
              const CircularProgressIndicator(color: PtTheme.deepGreen),
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
                style: PtTheme.font(13, lineHeight: 18, color: PtTheme.ink),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(itemDetailProvider(widget.itemId)),
                style: _outlinedButtonStyle(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (detail) => _buildDetail(l10n, detail),
      ),
    );
  }

  Widget _buildDetail(AppLocalizations l10n, PlatformItemDetail detail) {
    final versions = detail.versions;
    final fallback = detail.draftVersion ?? detail.publishedVersion;
    final selectedId =
        _selectedVersionId != null &&
            versions.any((version) => version.id == _selectedVersionId)
        ? _selectedVersionId
        : fallback?.id;
    final version = selectedId == null
        ? null
        : versions.firstWhere((item) => item.id == selectedId);
    final editable = version != null && version.status == 'DRAFT';
    final optionSets =
        ref.watch(optionSetsProvider).asData?.value ?? const <OptionSet>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(l10n, detail, version),
        const SizedBox(height: 16),
        if (version == null)
          _StatePanel(
            child: Column(
              children: [
                Text(
                  l10n.noData,
                  style: PtTheme.font(
                    14,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _creatingDraft ? null : _createDraft,
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: PtTheme.deepGreen,
                  ),
                  label: Text(l10n.createDraft),
                ),
              ],
            ),
          )
        else ...[
          if (!editable) _buildImmutableBanner(l10n, detail),
          if (!editable) const SizedBox(height: 14),
          _buildSectionTabs(l10n),
          const SizedBox(height: 14),
          _buildSectionContent(l10n, detail, version, editable, optionSets),
          const SizedBox(height: 18),
          _buildPublishBar(l10n, detail),
        ],
      ],
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    PlatformItemDetail detail,
    PlatformItemVersion? version,
  ) {
    final item = detail.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: PtTheme.muted,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.masterLibraryTitle,
                style: PtTheme.font(
                  11,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                  tracking: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.code,
                        style: PtTheme.font(
                          12,
                          weight: FontWeight.w700,
                          color: PtTheme.deepGreen,
                          tracking: 0.4,
                        ),
                      ),
                      _StatusChip(status: item.status),
                      if (version != null)
                        _StatusChip(status: version.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.labelEn.isEmpty ? item.code : item.labelEn,
                    style: PtTheme.font(
                      24,
                      lineHeight: 30,
                      weight: FontWeight.w800,
                      color: PtTheme.ink,
                      tracking: -0.4,
                    ),
                  ),
                  if (item.labelAr.isNotEmpty)
                    Text(
                      item.labelAr,
                      textDirection: TextDirection.rtl,
                      style: PtTheme.font(14, color: PtTheme.muted),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    item.categoryLabelEn.isEmpty
                        ? item.categoryId
                        : item.categoryLabelEn,
                    style: PtTheme.font(12, color: PtTheme.muted),
                  ),
                ],
              ),
            ),
            if (detail.versions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: PtTheme.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: PtTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: version?.id,
                    isDense: true,
                    style: PtTheme.font(
                      12,
                      weight: FontWeight.w600,
                      color: PtTheme.ink,
                    ),
                    items: [
                      for (final itemVersion in detail.versions)
                        DropdownMenuItem(
                          value: itemVersion.id,
                          child: Text(
                            'v${itemVersion.versionNo} · ${itemVersion.status}',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedVersionId = value);
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImmutableBanner(
    AppLocalizations l10n,
    PlatformItemDetail detail,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: PtTheme.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.versionImmutable,
                  style: PtTheme.font(
                    13,
                    lineHeight: 19,
                    weight: FontWeight.w600,
                    color: PtTheme.gold,
                  ),
                ),
              ),
            ],
          ),
          if (detail.draftVersion == null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: OutlinedButton.icon(
                onPressed: _creatingDraft ? null : _createDraft,
                icon: _creatingDraft
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PtTheme.deepGreen,
                        ),
                      )
                    : const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: PtTheme.deepGreen,
                      ),
                label: Text(
                  l10n.createDraft,
                  style: PtTheme.font(
                    12,
                    weight: FontWeight.w700,
                    color: PtTheme.deepGreen,
                  ),
                ),
                style: _outlinedButtonStyle(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTabs(AppLocalizations l10n) {
    final labels = <String>[
      l10n.basics,
      l10n.englishContent,
      l10n.arabicContent,
      l10n.scoreBands,
      l10n.evidenceRules,
      l10n.issueFields,
      l10n.measurementBands,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            _TabPill(
              label: labels[index],
              selected: _section == index,
              onTap: () => setState(() => _section = index),
            ),
            if (index != labels.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionContent(
    AppLocalizations l10n,
    PlatformItemDetail detail,
    PlatformItemVersion version,
    bool editable,
    List<OptionSet> optionSets,
  ) {
    final key = ItemVersionKey(widget.itemId, version.id);
    final configAsync = ref.watch(itemConfigProvider(key));
    return configAsync.when(
      loading: () => _StatePanel(
        child: Column(
          children: [
            const CircularProgressIndicator(color: PtTheme.deepGreen),
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
              style: PtTheme.font(13, color: PtTheme.ink),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(itemConfigProvider(key)),
              style: _outlinedButtonStyle(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (config) {
        switch (_section) {
          case 0:
            return _BasicsSection(
              itemId: widget.itemId,
              metadata: config.metadata,
              editable: editable,
              onSave: (metadata) => ref
                  .read(platformConfigActionsProvider)
                  .saveMetadata(widget.itemId, metadata),
            );
          case 1:
          case 2:
            return _TranslationsSection(
              translations: version.translations,
              editable: editable,
              onSave: (labelEn, instructionEn, labelAr, instructionAr) => ref
                  .read(platformConfigActionsProvider)
                  .saveTranslations(
                    widget.itemId,
                    version.id,
                    labelEn: labelEn,
                    instructionEn: instructionEn,
                    labelAr: labelAr,
                    instructionAr: instructionAr,
                  ),
            );
          case 3:
            return _ScoreBandsSection(
              bands: config.scoreBands,
              editable: editable,
              onSave: (bands) => ref
                  .read(platformConfigActionsProvider)
                  .saveConfig(
                    itemId: widget.itemId,
                    versionId: version.id,
                    scoreBands: bands,
                  ),
            );
          case 4:
            return _EvidenceRulesSection(
              rules: config.evidenceRules,
              editable: editable,
              onSave: (rules) => ref
                  .read(platformConfigActionsProvider)
                  .saveConfig(
                    itemId: widget.itemId,
                    versionId: version.id,
                    evidenceRules: rules,
                  ),
            );
          case 5:
            return _IssueFieldsSection(
              fields: config.issueFields,
              optionSets: optionSets,
              editable: editable,
              onSave: (fields) => ref
                  .read(platformConfigActionsProvider)
                  .saveConfig(
                    itemId: widget.itemId,
                    versionId: version.id,
                    issueFields: fields,
                  ),
            );
          default:
            return _MeasurementBandsSection(
              bands: config.measurementBands,
              editable: editable,
              onSave: (bands) => ref
                  .read(platformConfigActionsProvider)
                  .saveConfig(
                    itemId: widget.itemId,
                    versionId: version.id,
                    measurementBands: bands,
                  ),
            );
        }
      },
    );
  }

  Widget _buildPublishBar(AppLocalizations l10n, PlatformItemDetail detail) {
    final draft = detail.draftVersion;
    if (draft == null) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Text(
          'v${draft.versionNo} · ${draft.status}',
          style: PtTheme.font(
            12,
            weight: FontWeight.w600,
            color: PtTheme.muted,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _publishing ? null : () => _publish(draft),
          icon: _publishing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PtTheme.white,
                  ),
                )
              : const Icon(Icons.publish_rounded, size: 16),
          label: Text(
            l10n.publishItem,
            style: PtTheme.font(
              13,
              weight: FontWeight.w700,
              color: PtTheme.white,
            ),
          ),
          style: _primaryButtonStyle(),
        ),
      ],
    );
  }
}

class _BasicsSection extends StatefulWidget {
  const _BasicsSection({
    required this.itemId,
    required this.metadata,
    required this.editable,
    required this.onSave,
  });

  final String itemId;
  final ItemMetadata metadata;
  final bool editable;
  final Future<void> Function(ItemMetadata metadata) onSave;

  @override
  State<_BasicsSection> createState() => _BasicsSectionState();
}

class _BasicsSectionState extends State<_BasicsSection> {
  late final TextEditingController _unit;
  late final TextEditingController _sensor;
  late final TextEditingController _specEn;
  late final TextEditingController _specAr;
  late final TextEditingController _maxTyreAge;
  late final TextEditingController _sortOrder;
  late final TextEditingController _guideImage;
  late bool _safetyCritical;
  late bool _multiPoint;
  late bool _allowFreeText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _unit = TextEditingController(text: widget.metadata.measurementUnit);
    _sensor = TextEditingController(text: widget.metadata.sensorTool);
    _specEn = TextEditingController(text: widget.metadata.standardSpecEn);
    _specAr = TextEditingController(text: widget.metadata.standardSpecAr);
    _maxTyreAge = TextEditingController(
      text: widget.metadata.maxTyreAgeYears?.toString() ?? '',
    );
    _sortOrder = TextEditingController(
      text: widget.metadata.sortOrder.toString(),
    );
    _guideImage = TextEditingController(text: widget.metadata.guideImageId);
    _safetyCritical = widget.metadata.safetyCritical;
    _multiPoint = widget.metadata.multiPoint;
    _allowFreeText = widget.metadata.allowFreeTextNote;
  }

  @override
  void didUpdateWidget(covariant _BasicsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.metadata, widget.metadata)) {
      _unit.text = widget.metadata.measurementUnit;
      _sensor.text = widget.metadata.sensorTool;
      _specEn.text = widget.metadata.standardSpecEn;
      _specAr.text = widget.metadata.standardSpecAr;
      _maxTyreAge.text = widget.metadata.maxTyreAgeYears?.toString() ?? '';
      _sortOrder.text = widget.metadata.sortOrder.toString();
      _guideImage.text = widget.metadata.guideImageId;
      _safetyCritical = widget.metadata.safetyCritical;
      _multiPoint = widget.metadata.multiPoint;
      _allowFreeText = widget.metadata.allowFreeTextNote;
    }
  }

  @override
  void dispose() {
    _unit.dispose();
    _sensor.dispose();
    _specEn.dispose();
    _specAr.dispose();
    _maxTyreAge.dispose();
    _sortOrder.dispose();
    _guideImage.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        ItemMetadata(
          itemId: widget.itemId,
          measurementUnit: _unit.text.trim(),
          sensorTool: _sensor.text.trim(),
          standardSpecEn: _specEn.text.trim(),
          standardSpecAr: _specAr.text.trim(),
          safetyCritical: _safetyCritical,
          multiPoint: _multiPoint,
          maxTyreAgeYears: int.tryParse(_maxTyreAge.text.trim()),
          allowFreeTextNote: _allowFreeText,
          sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
          guideImageId: _guideImage.text.trim(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.basics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldGrid(
            children: [
              _InputField(
                controller: _unit,
                label: l10n.measurementUnit,
                enabled: widget.editable,
              ),
              _InputField(
                controller: _sensor,
                label: l10n.sensorTool,
                enabled: widget.editable,
              ),
              _InputField(
                controller: _specEn,
                label: l10n.standardSpecEn,
                enabled: widget.editable,
              ),
              _InputField(
                controller: _specAr,
                label: l10n.standardSpecAr,
                enabled: widget.editable,
                textDirection: TextDirection.rtl,
              ),
              _InputField(
                controller: _maxTyreAge,
                label: l10n.maxTyreAge,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: _sortOrder,
                label: l10n.categoryOrder,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: _guideImage,
                label: l10n.guideImage,
                enabled: widget.editable,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FieldGrid(
            children: [
              _SwitchTile(
                label: l10n.safetyCritical,
                value: _safetyCritical,
                enabled: widget.editable,
                onChanged: (value) =>
                    setState(() => _safetyCritical = value),
              ),
              _SwitchTile(
                label: l10n.multiPoint,
                value: _multiPoint,
                enabled: widget.editable,
                onChanged: (value) => setState(() => _multiPoint = value),
              ),
              _SwitchTile(
                label: l10n.allowFreeText,
                value: _allowFreeText,
                enabled: widget.editable,
                onChanged: (value) =>
                    setState(() => _allowFreeText = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton(
              onPressed: widget.editable && !_saving
                  ? () => _save(l10n)
                  : null,
              style: _primaryButtonStyle(),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PtTheme.white,
                      ),
                    )
                  : Text(
                      l10n.save,
                      style: PtTheme.font(
                        13,
                        weight: FontWeight.w700,
                        color: PtTheme.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslationsSection extends StatefulWidget {
  const _TranslationsSection({
    required this.translations,
    required this.editable,
    required this.onSave,
  });

  final Map<String, ItemTranslation> translations;
  final bool editable;
  final Future<void> Function(
    String labelEn,
    String instructionEn,
    String labelAr,
    String instructionAr,
  )
  onSave;

  @override
  State<_TranslationsSection> createState() => _TranslationsSectionState();
}

class _TranslationsSectionState extends State<_TranslationsSection> {
  late final TextEditingController _labelEn;
  late final TextEditingController _instructionEn;
  late final TextEditingController _labelAr;
  late final TextEditingController _instructionAr;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _labelEn = TextEditingController(
      text: widget.translations['en']?.label ?? '',
    );
    _instructionEn = TextEditingController(
      text: widget.translations['en']?.instruction ?? '',
    );
    _labelAr = TextEditingController(
      text: widget.translations['ar']?.label ?? '',
    );
    _instructionAr = TextEditingController(
      text: widget.translations['ar']?.instruction ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _TranslationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.translations, widget.translations)) {
      _labelEn.text = widget.translations['en']?.label ?? '';
      _instructionEn.text = widget.translations['en']?.instruction ?? '';
      _labelAr.text = widget.translations['ar']?.label ?? '';
      _instructionAr.text = widget.translations['ar']?.instruction ?? '';
    }
  }

  @override
  void dispose() {
    _labelEn.dispose();
    _instructionEn.dispose();
    _labelAr.dispose();
    _instructionAr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _labelEn.text.trim(),
        _instructionEn.text.trim(),
        _labelAr.text.trim(),
        _instructionAr.text.trim(),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: '${l10n.englishContent} / ${l10n.arabicContent}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final en = _buildLanguageCard(
                title: l10n.englishContent,
                labelController: _labelEn,
                instructionController: _instructionEn,
                isRtl: false,
                l10n: l10n,
              );
              final ar = _buildLanguageCard(
                title: l10n.arabicContent,
                labelController: _labelAr,
                instructionController: _instructionAr,
                isRtl: true,
                l10n: l10n,
              );
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [en, const SizedBox(height: 14), ar],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: en),
                  const SizedBox(width: 14),
                  Expanded(child: ar),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ElevatedButton(
              onPressed: widget.editable && !_saving ? _save : null,
              style: _primaryButtonStyle(),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PtTheme.white,
                      ),
                    )
                  : Text(
                      l10n.save,
                      style: PtTheme.font(
                        13,
                        weight: FontWeight.w700,
                        color: PtTheme.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required String title,
    required TextEditingController labelController,
    required TextEditingController instructionController,
    required bool isRtl,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: PtTheme.font(
              14,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          _InputField(
            controller: labelController,
            label: isRtl ? l10n.labelAr : l10n.labelEn,
            enabled: widget.editable,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: 10),
          _InputField(
            controller: instructionController,
            label: isRtl ? l10n.arabicContent : l10n.englishContent,
            enabled: widget.editable,
            maxLines: 5,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}

class _ScoreBandsSection extends StatefulWidget {
  const _ScoreBandsSection({
    required this.bands,
    required this.editable,
    required this.onSave,
  });

  final List<ScoreBand> bands;
  final bool editable;
  final Future<void> Function(List<ScoreBand> bands) onSave;

  @override
  State<_ScoreBandsSection> createState() => _ScoreBandsSectionState();
}

class _ScoreBandsSectionState extends State<_ScoreBandsSection> {
  late List<_ScoreBandForm> _forms;
  bool _saving = false;

  static const _defaults = <ScoreBand>[
    ScoreBand(
      resultCode: 'NO_ISSUE_OBSERVED',
      minScore: 90,
      maxScore: 100,
      defaultScore: 100,
      criteriaEn: '',
      criteriaAr: '',
    ),
    ScoreBand(
      resultCode: 'ATTENTION_RECOMMENDED',
      minScore: 50,
      maxScore: 89,
      defaultScore: 70,
      criteriaEn: '',
      criteriaAr: '',
    ),
    ScoreBand(
      resultCode: 'DEFECT_FOUND',
      minScore: 0,
      maxScore: 49,
      defaultScore: 0,
      criteriaEn: '',
      criteriaAr: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _forms = _buildForms(widget.bands);
  }

  @override
  void didUpdateWidget(covariant _ScoreBandsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bands, widget.bands)) {
      _disposeForms();
      _forms = _buildForms(widget.bands);
    }
  }

  List<_ScoreBandForm> _buildForms(List<ScoreBand> bands) {
    final source = bands.isEmpty ? _defaults : bands;
    return source.map(_ScoreBandForm.new).toList();
  }

  void _disposeForms() {
    for (final form in _forms) {
      form.dispose();
    }
  }

  @override
  void dispose() {
    _disposeForms();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_forms.map((form) => form.toBand()).toList());
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.scoreBands,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _forms.length; index++) ...[
            _buildBandRow(l10n, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: widget.editable
                    ? () => setState(
                        () => _forms.add(
                          _ScoreBandForm(
                            ScoreBand(
                              resultCode: _resultCodes.first,
                              minScore: 0,
                              maxScore: 100,
                              defaultScore: 0,
                              criteriaEn: '',
                              criteriaAr: '',
                            ),
                          ),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(l10n.addItem),
                style: _outlinedButtonStyle(),
              ),
              ElevatedButton(
                onPressed: widget.editable && !_saving ? _save : null,
                style: _primaryButtonStyle(),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PtTheme.white,
                        ),
                      )
                    : Text(
                        l10n.save,
                        style: PtTheme.font(
                          13,
                          weight: FontWeight.w700,
                          color: PtTheme.white,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBandRow(AppLocalizations l10n, int index) {
    final form = _forms[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _DropdownField<String>(
                  label: l10n.status,
                  value: form.resultCode,
                  enabled: widget.editable,
                  items: [
                    for (final code in _resultCodes)
                      DropdownMenuItem(value: code, child: Text(code)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => form.resultCode = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: PtTheme.rose,
                ),
                onPressed: widget.editable
                    ? () => setState(() {
                        form.dispose();
                        _forms.removeAt(index);
                      })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FieldGrid(
            children: [
              _InputField(
                controller: form.minScore,
                label: l10n.minScore,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: form.maxScore,
                label: l10n.maxScore,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: form.defaultScore,
                label: l10n.defaultScore,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: form.criteriaEn,
                label: l10n.criteriaEn,
                enabled: widget.editable,
                maxLines: 2,
              ),
              _InputField(
                controller: form.criteriaAr,
                label: l10n.criteriaAr,
                enabled: widget.editable,
                maxLines: 2,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBandForm {
  _ScoreBandForm(ScoreBand band)
    : resultCode = _resultCodes.contains(band.resultCode)
          ? band.resultCode
          : _resultCodes.first,
      minScore = TextEditingController(text: band.minScore.toString()),
      maxScore = TextEditingController(text: band.maxScore.toString()),
      defaultScore = TextEditingController(text: band.defaultScore.toString()),
      criteriaEn = TextEditingController(text: band.criteriaEn),
      criteriaAr = TextEditingController(text: band.criteriaAr);

  String resultCode;
  final TextEditingController minScore;
  final TextEditingController maxScore;
  final TextEditingController defaultScore;
  final TextEditingController criteriaEn;
  final TextEditingController criteriaAr;

  ScoreBand toBand() => ScoreBand(
    resultCode: resultCode,
    minScore: int.tryParse(minScore.text.trim()) ?? 0,
    maxScore: int.tryParse(maxScore.text.trim()) ?? 0,
    defaultScore: int.tryParse(defaultScore.text.trim()) ?? 0,
    criteriaEn: criteriaEn.text.trim(),
    criteriaAr: criteriaAr.text.trim(),
  );

  void dispose() {
    minScore.dispose();
    maxScore.dispose();
    defaultScore.dispose();
    criteriaEn.dispose();
    criteriaAr.dispose();
  }
}

class _EvidenceRulesSection extends StatefulWidget {
  const _EvidenceRulesSection({
    required this.rules,
    required this.editable,
    required this.onSave,
  });

  final List<EvidenceRule> rules;
  final bool editable;
  final Future<void> Function(List<EvidenceRule> rules) onSave;

  @override
  State<_EvidenceRulesSection> createState() => _EvidenceRulesSectionState();
}

class _EvidenceRulesSectionState extends State<_EvidenceRulesSection> {
  late List<_EvidenceRuleForm> _forms;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _forms = _buildForms(widget.rules);
  }

  @override
  void didUpdateWidget(covariant _EvidenceRulesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.rules, widget.rules)) {
      _disposeForms();
      _forms = _buildForms(widget.rules);
    }
  }

  List<_EvidenceRuleForm> _buildForms(List<EvidenceRule> rules) {
    if (rules.isNotEmpty) {
      return rules.map(_EvidenceRuleForm.new).toList();
    }
    return [
      for (final code in _resultCodes)
        _EvidenceRuleForm(
          EvidenceRule(
            resultCode: code,
            minPhotos: code == 'DEFECT_FOUND' ? 1 : 0,
            minVideos: 0,
            minNotesChars: 0,
            requiredEvidenceType: '',
          ),
        ),
    ];
  }

  void _disposeForms() {
    for (final form in _forms) {
      form.dispose();
    }
  }

  @override
  void dispose() {
    _disposeForms();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_forms.map((form) => form.toRule()).toList());
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.evidenceRules,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _forms.length; index++) ...[
            _buildRuleRow(l10n, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: widget.editable
                    ? () => setState(
                        () => _forms.add(
                          _EvidenceRuleForm(
                            EvidenceRule(
                              resultCode: _resultCodes.first,
                              minPhotos: 0,
                              minVideos: 0,
                              minNotesChars: 0,
                              requiredEvidenceType: '',
                            ),
                          ),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(l10n.addItem),
                style: _outlinedButtonStyle(),
              ),
              ElevatedButton(
                onPressed: widget.editable && !_saving ? _save : null,
                style: _primaryButtonStyle(),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PtTheme.white,
                        ),
                      )
                    : Text(
                        l10n.save,
                        style: PtTheme.font(
                          13,
                          weight: FontWeight.w700,
                          color: PtTheme.white,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(AppLocalizations l10n, int index) {
    final form = _forms[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _DropdownField<String>(
                  label: l10n.status,
                  value: form.resultCode,
                  enabled: widget.editable,
                  items: [
                    for (final code in _resultCodes)
                      DropdownMenuItem(value: code, child: Text(code)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => form.resultCode = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: PtTheme.rose,
                ),
                onPressed: widget.editable
                    ? () => setState(() {
                        form.dispose();
                        _forms.removeAt(index);
                      })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FieldGrid(
            children: [
              _InputField(
                controller: form.minPhotos,
                label: l10n.minPhotos,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: form.minVideos,
                label: l10n.minVideos,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: form.minNotes,
                label: l10n.minNotes,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _DropdownField<String>(
                label: l10n.requiredEvidenceType,
                value: _evidenceTypes.contains(form.requiredEvidenceType)
                    ? form.requiredEvidenceType
                    : '',
                enabled: widget.editable,
                items: [
                  for (final type in _evidenceTypes)
                    DropdownMenuItem(
                      value: type,
                      child: Text(type.isEmpty ? 'none' : type),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => form.requiredEvidenceType = value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EvidenceRuleForm {
  _EvidenceRuleForm(EvidenceRule rule)
    : resultCode = _resultCodes.contains(rule.resultCode)
          ? rule.resultCode
          : _resultCodes.first,
      requiredEvidenceType = rule.requiredEvidenceType,
      minPhotos = TextEditingController(text: rule.minPhotos.toString()),
      minVideos = TextEditingController(text: rule.minVideos.toString()),
      minNotes = TextEditingController(text: rule.minNotesChars.toString());

  String resultCode;
  String requiredEvidenceType;
  final TextEditingController minPhotos;
  final TextEditingController minVideos;
  final TextEditingController minNotes;

  EvidenceRule toRule() => EvidenceRule(
    resultCode: resultCode,
    minPhotos: int.tryParse(minPhotos.text.trim()) ?? 0,
    minVideos: int.tryParse(minVideos.text.trim()) ?? 0,
    minNotesChars: int.tryParse(minNotes.text.trim()) ?? 0,
    requiredEvidenceType: requiredEvidenceType,
  );

  void dispose() {
    minPhotos.dispose();
    minVideos.dispose();
    minNotes.dispose();
  }
}

class _IssueFieldsSection extends ConsumerStatefulWidget {
  const _IssueFieldsSection({
    required this.fields,
    required this.optionSets,
    required this.editable,
    required this.onSave,
  });

  final List<IssueField> fields;
  final List<OptionSet> optionSets;
  final bool editable;
  final Future<void> Function(List<IssueField> fields) onSave;

  @override
  ConsumerState<_IssueFieldsSection> createState() =>
      _IssueFieldsSectionState();
}

class _IssueFieldsSectionState extends ConsumerState<_IssueFieldsSection> {
  late List<_IssueFieldForm> _forms;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _forms = widget.fields.map(_IssueFieldForm.new).toList();
  }

  @override
  void didUpdateWidget(covariant _IssueFieldsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.fields, widget.fields)) {
      _disposeForms();
      _forms = widget.fields.map(_IssueFieldForm.new).toList();
    }
  }

  void _disposeForms() {
    for (final form in _forms) {
      form.dispose();
    }
  }

  @override
  void dispose() {
    _disposeForms();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave([
        for (var index = 0; index < _forms.length; index++)
          _forms[index].toIssueField(index),
      ]);
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.issueFields,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _forms.length; index++) ...[
            _buildFieldRow(l10n, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: widget.editable
                    ? () => setState(
                        () => _forms.add(
                          _IssueFieldForm.empty(_forms.length),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(l10n.addItem),
                style: _outlinedButtonStyle(),
              ),
              ElevatedButton(
                onPressed: widget.editable && !_saving ? _save : null,
                style: _primaryButtonStyle(),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PtTheme.white,
                        ),
                      )
                    : Text(
                        l10n.save,
                        style: PtTheme.font(
                          13,
                          weight: FontWeight.w700,
                          color: PtTheme.white,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(AppLocalizations l10n, int index) {
    final form = _forms[index];
    final optionCodes = widget.optionSets
        .map((optionSet) => optionSet.code)
        .toSet();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: form.fieldCode,
                  label: l10n.fieldCode,
                  enabled: widget.editable,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: PtTheme.rose,
                ),
                onPressed: widget.editable
                    ? () => setState(() {
                        form.dispose();
                        _forms.removeAt(index);
                      })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FieldGrid(
            children: [
              _InputField(
                controller: form.labelEn,
                label: l10n.labelEn,
                enabled: widget.editable,
              ),
              _InputField(
                controller: form.labelAr,
                label: l10n.labelAr,
                enabled: widget.editable,
                textDirection: TextDirection.rtl,
              ),
              _DropdownField<String>(
                label: l10n.inputType,
                value: form.inputType,
                enabled: widget.editable,
                items: [
                  for (final type in _inputTypes)
                    DropdownMenuItem(value: type, child: Text(type)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => form.inputType = value);
                  }
                },
              ),
              _DropdownField<String>(
                label: l10n.optionSet,
                value: form.optionSetCode,
                enabled: widget.editable,
                items: [
                  const DropdownMenuItem(value: '', child: Text('—')),
                  for (final optionSet in widget.optionSets)
                    DropdownMenuItem(
                      value: optionSet.code,
                      child: Text(
                        optionSet.nameEn.isEmpty
                            ? optionSet.code
                            : optionSet.nameEn,
                      ),
                    ),
                  if (form.optionSetCode.isNotEmpty &&
                      !optionCodes.contains(form.optionSetCode))
                    DropdownMenuItem(
                      value: form.optionSetCode,
                      child: Text(form.optionSetCode),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => form.optionSetCode = value);
                  }
                },
              ),
              _InputField(
                controller: form.minValue,
                label: l10n.minScore,
                enabled: widget.editable,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _InputField(
                controller: form.maxValue,
                label: l10n.maxScore,
                enabled: widget.editable,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _InputField(
                controller: form.decimalPlaces,
                label: l10n.decimalPlaces,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: form.dependsOnFieldCode,
                label: l10n.dependsOn,
                enabled: widget.editable,
              ),
              _InputField(
                controller: form.dependsOnValueCode,
                label: 'Depends on value',
                enabled: widget.editable,
              ),
              _InputField(
                controller: form.sortOrder,
                label: l10n.categoryOrder,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SwitchTile(
                label: l10n.required,
                value: form.required,
                enabled: widget.editable,
                onChanged: (value) =>
                    setState(() => form.required = value),
              ),
              _SwitchTile(
                label: l10n.allowMultiple,
                value: form.allowMultiple,
                enabled: widget.editable,
                onChanged: (value) =>
                    setState(() => form.allowMultiple = value),
              ),
              _SwitchTile(
                label: l10n.allowFreeText,
                value: form.allowFreeText,
                enabled: widget.editable,
                onChanged: (value) =>
                    setState(() => form.allowFreeText = value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Required for statuses',
            style: PtTheme.font(
              12,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final status in _requiredForStatuses)
                FilterChip(
                  label: Text(status),
                  selected: form.requiredForStatuses.contains(status),
                  onSelected: widget.editable
                      ? (selected) => setState(() {
                          if (selected) {
                            form.requiredForStatuses.add(status);
                          } else {
                            form.requiredForStatuses.remove(status);
                          }
                        })
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueFieldForm {
  _IssueFieldForm(IssueField field)
    : initialId = field.id,
      fieldCode = TextEditingController(text: field.fieldCode),
      labelEn = TextEditingController(text: field.labelEn),
      labelAr = TextEditingController(text: field.labelAr),
      inputType = _inputTypes.contains(field.inputType)
          ? field.inputType
          : _inputTypes.first,
      optionSetCode = field.optionSetCode,
      unitSetCode = field.unitSetCode,
      required = field.required,
      requiredForStatuses = field.requiredForStatuses.toSet(),
      minValue = TextEditingController(
        text: field.minValue?.toString() ?? '',
      ),
      maxValue = TextEditingController(
        text: field.maxValue?.toString() ?? '',
      ),
      decimalPlaces = TextEditingController(
        text: field.decimalPlaces.toString(),
      ),
      dependsOnFieldCode = TextEditingController(
        text: field.dependsOnFieldCode,
      ),
      dependsOnValueCode = TextEditingController(
        text: field.dependsOnValueCode,
      ),
      allowMultiple = field.allowMultiple,
      allowFreeText = field.allowFreeText,
      sortOrder = TextEditingController(text: field.sortOrder.toString()),
      allowedValues = field.allowedValues;

  _IssueFieldForm.empty(int index)
    : initialId = null,
      fieldCode = TextEditingController(),
      labelEn = TextEditingController(),
      labelAr = TextEditingController(),
      inputType = _inputTypes.first,
      optionSetCode = '',
      unitSetCode = '',
      required = false,
      requiredForStatuses = <String>{},
      minValue = TextEditingController(),
      maxValue = TextEditingController(),
      decimalPlaces = TextEditingController(text: '0'),
      dependsOnFieldCode = TextEditingController(),
      dependsOnValueCode = TextEditingController(),
      allowMultiple = false,
      allowFreeText = false,
      sortOrder = TextEditingController(text: index.toString()),
      allowedValues = const <String>[];

  final String? initialId;
  final TextEditingController fieldCode;
  final TextEditingController labelEn;
  final TextEditingController labelAr;
  String inputType;
  String optionSetCode;
  String unitSetCode;
  bool required;
  final Set<String> requiredForStatuses;
  final TextEditingController minValue;
  final TextEditingController maxValue;
  final TextEditingController decimalPlaces;
  final TextEditingController dependsOnFieldCode;
  final TextEditingController dependsOnValueCode;
  bool allowMultiple;
  bool allowFreeText;
  final TextEditingController sortOrder;
  final List<String> allowedValues;

  IssueField toIssueField(int index) => IssueField(
    id: initialId,
    fieldCode: fieldCode.text.trim(),
    labelEn: labelEn.text.trim(),
    labelAr: labelAr.text.trim(),
    inputType: inputType,
    optionSetCode: optionSetCode,
    unitSetCode: unitSetCode,
    required: required,
    requiredForStatuses: requiredForStatuses.toList(),
    minValue: double.tryParse(minValue.text.trim()),
    maxValue: double.tryParse(maxValue.text.trim()),
    decimalPlaces: int.tryParse(decimalPlaces.text.trim()) ?? 0,
    dependsOnFieldCode: dependsOnFieldCode.text.trim(),
    dependsOnValueCode: dependsOnValueCode.text.trim(),
    allowMultiple: allowMultiple,
    allowFreeText: allowFreeText,
    sortOrder: int.tryParse(sortOrder.text.trim()) ?? index,
    allowedValues: allowedValues,
  );

  void dispose() {
    fieldCode.dispose();
    labelEn.dispose();
    labelAr.dispose();
    minValue.dispose();
    maxValue.dispose();
    decimalPlaces.dispose();
    dependsOnFieldCode.dispose();
    dependsOnValueCode.dispose();
    sortOrder.dispose();
  }
}

class _MeasurementBandsSection extends StatefulWidget {
  const _MeasurementBandsSection({
    required this.bands,
    required this.editable,
    required this.onSave,
  });

  final List<MeasurementBand> bands;
  final bool editable;
  final Future<void> Function(List<MeasurementBand> bands) onSave;

  @override
  State<_MeasurementBandsSection> createState() =>
      _MeasurementBandsSectionState();
}

class _MeasurementBandsSectionState extends State<_MeasurementBandsSection> {
  late List<_MeasurementBandForm> _forms;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _forms = widget.bands.map(_MeasurementBandForm.new).toList();
  }

  @override
  void didUpdateWidget(covariant _MeasurementBandsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bands, widget.bands)) {
      _disposeForms();
      _forms = widget.bands.map(_MeasurementBandForm.new).toList();
    }
  }

  void _disposeForms() {
    for (final form in _forms) {
      form.dispose();
    }
  }

  @override
  void dispose() {
    _disposeForms();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_forms.map((form) => form.toBand()).toList());
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      title: l10n.measurementBands,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _forms.length; index++) ...[
            _buildBandRow(l10n, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: widget.editable
                    ? () => setState(
                        () => _forms.add(
                          _MeasurementBandForm(
                            MeasurementBand(
                              fieldCode: '',
                              unitCode: '',
                              direction: _directions.first,
                              minValue: 0,
                              maxValue: 0,
                              resultCode: _resultCodes.first,
                              defaultScore: 0,
                              labelEn: '',
                              labelAr: '',
                              sortOrder: _forms.length,
                            ),
                          ),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(l10n.addItem),
                style: _outlinedButtonStyle(),
              ),
              ElevatedButton(
                onPressed: widget.editable && !_saving ? _save : null,
                style: _primaryButtonStyle(),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PtTheme.white,
                        ),
                      )
                    : Text(
                        l10n.save,
                        style: PtTheme.font(
                          13,
                          weight: FontWeight.w700,
                          color: PtTheme.white,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBandRow(AppLocalizations l10n, int index) {
    final form = _forms[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: form.fieldCode,
                  label: l10n.fieldCode,
                  enabled: widget.editable,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: PtTheme.rose,
                ),
                onPressed: widget.editable
                    ? () => setState(() {
                        form.dispose();
                        _forms.removeAt(index);
                      })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FieldGrid(
            children: [
              _InputField(
                controller: form.unitCode,
                label: l10n.measurementUnit,
                enabled: widget.editable,
              ),
              _DropdownField<String>(
                label: 'Direction',
                value: form.direction,
                enabled: widget.editable,
                items: [
                  for (final direction in _directions)
                    DropdownMenuItem(
                      value: direction,
                      child: Text(direction),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => form.direction = value);
                  }
                },
              ),
              _InputField(
                controller: form.minValue,
                label: l10n.minScore,
                enabled: widget.editable,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _InputField(
                controller: form.maxValue,
                label: l10n.maxScore,
                enabled: widget.editable,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              _DropdownField<String>(
                label: l10n.status,
                value: form.resultCode,
                enabled: widget.editable,
                items: [
                  for (final code in _resultCodes)
                    DropdownMenuItem(value: code, child: Text(code)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => form.resultCode = value);
                  }
                },
              ),
              _InputField(
                controller: form.defaultScore,
                label: l10n.defaultScore,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: form.labelEn,
                label: l10n.labelEn,
                enabled: widget.editable,
              ),
              _InputField(
                controller: form.labelAr,
                label: l10n.labelAr,
                enabled: widget.editable,
                textDirection: TextDirection.rtl,
              ),
              _InputField(
                controller: form.sortOrder,
                label: l10n.categoryOrder,
                enabled: widget.editable,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeasurementBandForm {
  _MeasurementBandForm(MeasurementBand band)
    : fieldCode = TextEditingController(text: band.fieldCode),
      unitCode = TextEditingController(text: band.unitCode),
      direction = _directions.contains(band.direction)
          ? band.direction
          : _directions.first,
      minValue = TextEditingController(text: band.minValue.toString()),
      maxValue = TextEditingController(text: band.maxValue.toString()),
      resultCode = _resultCodes.contains(band.resultCode)
          ? band.resultCode
          : _resultCodes.first,
      defaultScore = TextEditingController(text: band.defaultScore.toString()),
      labelEn = TextEditingController(text: band.labelEn),
      labelAr = TextEditingController(text: band.labelAr),
      sortOrder = TextEditingController(text: band.sortOrder.toString());

  final TextEditingController fieldCode;
  final TextEditingController unitCode;
  String direction;
  final TextEditingController minValue;
  final TextEditingController maxValue;
  String resultCode;
  final TextEditingController defaultScore;
  final TextEditingController labelEn;
  final TextEditingController labelAr;
  final TextEditingController sortOrder;

  MeasurementBand toBand() => MeasurementBand(
    fieldCode: fieldCode.text.trim(),
    unitCode: unitCode.text.trim(),
    direction: direction,
    minValue: double.tryParse(minValue.text.trim()) ?? 0,
    maxValue: double.tryParse(maxValue.text.trim()) ?? 0,
    resultCode: resultCode,
    defaultScore: int.tryParse(defaultScore.text.trim()) ?? 0,
    labelEn: labelEn.text.trim(),
    labelAr: labelAr.text.trim(),
    sortOrder: int.tryParse(sortOrder.text.trim()) ?? 0,
  );

  void dispose() {
    fieldCode.dispose();
    unitCode.dispose();
    minValue.dispose();
    maxValue.dispose();
    defaultScore.dispose();
    labelEn.dispose();
    labelAr.dispose();
    sortOrder.dispose();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 700
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? PtTheme.deepGreen.withValues(alpha: 0.12)
              : PtTheme.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: selected
                ? PtTheme.deepGreen.withValues(alpha: 0.35)
                : PtTheme.border,
          ),
        ),
        child: Text(
          label,
          style: PtTheme.font(
            12,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? PtTheme.deepGreen : PtTheme.muted,
          ),
        ),
      ),
    );
  }
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

ButtonStyle _outlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    side: const BorderSide(color: PtTheme.border, width: 1.4),
    backgroundColor: PtTheme.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9999),
    ),
  );
}

ButtonStyle _primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: PtTheme.deepGreen,
    foregroundColor: PtTheme.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9999),
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

void _showSnack(BuildContext context, String message, {bool isError = false}) {
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.textDirection,
    this.enabled = true,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textDirection: textDirection,
      enabled: enabled,
      maxLines: maxLines,
      style: PtTheme.font(14, color: PtTheme.ink),
      decoration: _inputDecoration(label),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
    this.validator,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      validator: validator,
      onChanged: enabled ? onChanged : null,
      style: PtTheme.font(14, color: PtTheme.ink),
      decoration: _inputDecoration(label),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeThumbColor: PtTheme.deepGreen,
          title: Text(
            label,
            style: PtTheme.font(
              12,
              weight: FontWeight.w600,
              color: PtTheme.ink,
            ),
          ),
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ),
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
