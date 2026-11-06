import 'package:admin_app/src/admin_api.dart';
import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/labels.dart';
import 'package:admin_app/src/models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class ItemFormPage extends ConsumerWidget {
  const ItemFormPage({this.itemId, super.key});

  final String? itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final reasons = ref.watch(reasonsProvider);
    final equipment = ref.watch(equipmentProvider);
    final guideImages = ref.watch(guideImagesProvider);
    if (categories.isLoading ||
        reasons.isLoading ||
        equipment.isLoading ||
        guideImages.isLoading) {
      return AppScaffold(
        appBar: AppBar(),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
      );
    }
    if (categories.hasError ||
        reasons.hasError ||
        equipment.hasError ||
        guideImages.hasError) {
      return AppScaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: AppLocalizations.of(context).error,
              body: AppLocalizations.of(context).genericError,
            ),
          ),
        ),
      );
    }
    if (itemId == null) {
      return _ItemForm(
        initial: null,
        categories: categories.requireValue,
        reasons: reasons.requireValue,
        equipment: equipment.requireValue,
        guideImages: guideImages.requireValue,
      );
    }
    final detail = ref.watch(itemDetailProvider(itemId!));
    return detail.when(
      loading: () => AppScaffold(
        appBar: AppBar(),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
      ),
      error: (error, _) => AppScaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: AppLocalizations.of(context).error,
              body: AppLocalizations.of(context).genericError,
            ),
          ),
        ),
      ),
      data: (value) => _ItemForm(
        key: ValueKey(value.draft?.id ?? 'no-draft'),
        initial: value,
        categories: categories.requireValue,
        reasons: reasons.requireValue,
        equipment: equipment.requireValue,
        guideImages: guideImages.requireValue,
      ),
    );
  }
}

class _ItemForm extends ConsumerStatefulWidget {
  const _ItemForm({
    required this.initial,
    required this.categories,
    required this.reasons,
    required this.equipment,
    required this.guideImages,
    super.key,
  });

  final ItemDetail? initial;
  final List<Category> categories;
  final List<Reason> reasons;
  final List<Equipment> equipment;
  final List<GuideImage> guideImages;

  @override
  ConsumerState<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends ConsumerState<_ItemForm> {
  late final TextEditingController _stableCode;
  late final TextEditingController _labelEn;
  late final TextEditingController _labelAr;
  late final TextEditingController _instructionEn;
  late final TextEditingController _instructionAr;
  late final TextEditingController _labelRu;
  late final TextEditingController _labelZh;
  late final TextEditingController _instructionRu;
  late final TextEditingController _instructionZh;
  late final TextEditingController _minPhotos;
  late final TextEditingController _severityPolicy;
  late final TextEditingController _applicability;
  late String _categoryId;
  late String _noteRequirement;
  late String _evidenceRequirement;
  late bool _sampleData;
  late Set<String> _resultOptions;
  late Set<String> _reasonCodes;
  late Set<String> _equipmentIds;
  String? _guideImageId;
  bool _busy = false;

  ItemVersion? get _draft => widget.initial?.draft;

  @override
  void initState() {
    super.initState();
    final detail = widget.initial;
    final draft = detail?.draft;
    _stableCode = TextEditingController(text: detail?.item.stableCode ?? '');
    _labelEn = TextEditingController(
      text: draft?.translation('en').label ?? '',
    );
    _labelAr = TextEditingController(
      text: draft?.translation('ar').label ?? '',
    );
    _instructionEn = TextEditingController(
      text: draft?.translation('en').instruction ?? '',
    );
    _instructionAr = TextEditingController(
      text: draft?.translation('ar').instruction ?? '',
    );
    _labelRu = TextEditingController(
      text: draft?.translation('ru').label ?? '',
    );
    _labelZh = TextEditingController(
      text: draft?.translation('zh-Hans').label ?? '',
    );
    _instructionRu = TextEditingController(
      text: draft?.translation('ru').instruction ?? '',
    );
    _instructionZh = TextEditingController(
      text: draft?.translation('zh-Hans').instruction ?? '',
    );
    _minPhotos = TextEditingController(
      text: (draft?.minPhotos ?? 0).toString(),
    );
    _severityPolicy = TextEditingController(
      text: draft?.severityPolicy ?? '{}',
    );
    _applicability = TextEditingController(text: draft?.applicability ?? '{}');
    _categoryId =
        detail?.item.categoryId ??
        (widget.categories.isEmpty ? '' : widget.categories.first.id);
    _noteRequirement = draft?.noteRequirement ?? 'OPTIONAL';
    _evidenceRequirement = draft?.evidenceRequirement ?? 'NONE';
    _sampleData = detail?.item.sampleData ?? false;
    _resultOptions = {...?draft?.resultOptions};
    _reasonCodes = {...?draft?.reasonCodes};
    _equipmentIds = {...?draft?.equipmentIds};
    _guideImageId = draft?.guideImageId;
  }

  @override
  void dispose() {
    _stableCode.dispose();
    _labelEn.dispose();
    _labelAr.dispose();
    _instructionEn.dispose();
    _instructionAr.dispose();
    _labelRu.dispose();
    _labelZh.dispose();
    _instructionRu.dispose();
    _instructionZh.dispose();
    _minPhotos.dispose();
    _severityPolicy.dispose();
    _applicability.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNew = widget.initial == null;
    final canEdit = isNew || _draft != null;
    return AppScaffold(
      appBar: AppBar(
        title: Text(
          isNew ? l10n.newItem : (widget.initial?.item.labelEn ?? l10n.items),
        ),
        actions: [
          if (!isNew && _draft == null)
            AppButton(
              label: l10n.createDraft,
              onPressed: _busy ? null : _createDraft,
              variant: AppButtonVariant.text,
            ),
          if (canEdit)
            IconButton(
              tooltip: l10n.saveDraft,
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save_outlined),
            ),
          if (_draft != null)
            IconButton(
              tooltip: l10n.publish,
              onPressed: _busy ? null : _publish,
              icon: const Icon(Icons.publish_outlined),
            ),
          if (!isNew)
            IconButton(
              tooltip: l10n.retire,
              onPressed: _busy ? null : _retire,
              icon: const Icon(Icons.archive_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          if (!isNew && widget.initial!.item.sampleData)
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: context.spacing.md),
              child: StatusChip(
                label: l10n.sampleData,
                tone: StatusTone.warning,
                icon: Icons.science_outlined,
              ),
            ),
          if (!isNew && _draft == null)
            EmptyState(
              title: l10n.draft,
              body: l10n.createDraft,
              action: AppButton(
                label: l10n.createDraft,
                onPressed: _busy ? null : _createDraft,
                variant: AppButtonVariant.tonal,
              ),
            )
          else ...[
            AppTextField(
              controller: _stableCode,
              label: l10n.stableCode,
              readOnly: !isNew,
            ),
            SizedBox(height: context.spacing.sm),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _categoryId.isEmpty ? null : _categoryId,
              decoration: InputDecoration(labelText: l10n.category),
              items: widget.categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.labelEn),
                    ),
                  )
                  .toList(),
              onChanged: isNew
                  ? (value) =>
                        setState(() => _categoryId = value ?? _categoryId)
                  : null,
            ),
            SizedBox(height: context.spacing.lg),
            _localizedFields(l10n),
            SizedBox(height: context.spacing.lg),
            SectionHeader(title: l10n.resultOptions),
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: _resultOptionCodes
                  .map(
                    (code) => AppSelectableText(
                      label: code,
                      selected: _resultOptions.contains(code),
                      onTap: () => setState(() {
                        _resultOptions.contains(code)
                            ? _resultOptions.remove(code)
                            : _resultOptions.add(code);
                      }),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: context.spacing.lg),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _noteRequirement,
              decoration: InputDecoration(labelText: l10n.noteRequirement),
              items: const ['NONE', 'OPTIONAL', 'REQUIRED']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _noteRequirement = value ?? _noteRequirement),
            ),
            SizedBox(height: context.spacing.sm),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _evidenceRequirement,
              decoration: InputDecoration(labelText: l10n.evidenceRequirement),
              items: const ['NONE', 'OPTIONAL', 'REQUIRED', 'REQUIRED_MIN_N']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(
                () => _evidenceRequirement = value ?? _evidenceRequirement,
              ),
            ),
            SizedBox(height: context.spacing.sm),
            AppTextField(
              controller: _minPhotos,
              label: l10n.minPhotos,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: context.spacing.sm),
            AppTextField(
              controller: _severityPolicy,
              label: l10n.severityPolicy,
            ),
            SizedBox(height: context.spacing.sm),
            AppTextField(controller: _applicability, label: l10n.applicability),
            SizedBox(height: context.spacing.lg),
            SectionHeader(title: l10n.reasons),
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: widget.reasons
                  .map(
                    (reason) => AppSelectableText(
                      label: reason.labelEn,
                      selected: _reasonCodes.contains(reason.code),
                      onTap: () => setState(() {
                        _reasonCodes.contains(reason.code)
                            ? _reasonCodes.remove(reason.code)
                            : _reasonCodes.add(reason.code);
                      }),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: context.spacing.lg),
            SectionHeader(title: l10n.equipment),
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: widget.equipment
                  .map(
                    (item) => AppSelectableText(
                      label: item.labelEn,
                      selected: _equipmentIds.contains(item.id),
                      onTap: () => setState(() {
                        _equipmentIds.contains(item.id)
                            ? _equipmentIds.remove(item.id)
                            : _equipmentIds.add(item.id);
                      }),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: context.spacing.lg),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: _guideImageId,
              decoration: InputDecoration(labelText: l10n.guideImage),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.notAvailable),
                ),
                ...widget.guideImages.map(
                  (image) => DropdownMenuItem<String?>(
                    value: image.id,
                    child: Text(image.altEn),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _guideImageId = value),
            ),
            if (isNew) ...[
              SizedBox(height: context.spacing.sm),
              AppSelectableText(
                label: l10n.sampleData,
                selected: _sampleData,
                onTap: () => setState(() => _sampleData = !_sampleData),
              ),
            ],
            SizedBox(height: context.spacing.lg),
            AppButton(
              label: isNew ? l10n.create : l10n.save,
              onPressed: _busy ? null : _save,
              isLoading: _busy,
              icon: Icons.save_outlined,
              expand: true,
            ),
          ],
          if (!isNew && widget.initial!.versions.isNotEmpty) ...[
            SizedBox(height: context.spacing.xl),
            SectionHeader(title: l10n.versions),
            ...widget.initial!.versions.map(
              (version) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
                child: Card(
                  child: AppListTile(
                    title:
                        'v${version.versionNo} · ${contentStatusLabel(l10n, version.status)}',
                    subtitle: version.translation('en').label,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _localizedFields(AppLocalizations l10n) {
    return Column(
      children: [
        _pair(l10n.labelEn, _labelEn, l10n.instructionEn, _instructionEn),
        SizedBox(height: context.spacing.md),
        _pair(l10n.labelAr, _labelAr, l10n.instructionAr, _instructionAr),
        SizedBox(height: context.spacing.md),
        _pair(l10n.russian, _labelRu, l10n.russian, _instructionRu),
        SizedBox(height: context.spacing.md),
        _pair(l10n.chinese, _labelZh, l10n.chinese, _instructionZh),
      ],
    );
  }

  Widget _pair(
    String labelLabel,
    TextEditingController label,
    String instructionLabel,
    TextEditingController instruction,
  ) {
    return Column(
      children: [
        AppTextField(controller: label, label: labelLabel),
        SizedBox(height: context.spacing.xs),
        AppTextField(
          controller: instruction,
          label: instructionLabel,
          maxLines: 2,
        ),
      ],
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final isNew = widget.initial == null;
    final draft = _draft;
    if (isNew && (_stableCode.text.trim().isEmpty || _categoryId.isEmpty)) {
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(adminApiProvider);
      if (isNew) {
        await api.createItem(
          NewItem(
            stableCode: _stableCode.text.trim(),
            categoryId: _categoryId,
            labelEn: _labelEn.text.trim(),
            labelAr: _labelAr.text.trim(),
            instructionEn: _instructionEn.text.trim(),
            instructionAr: _instructionAr.text.trim(),
            resultOptions: _resultOptions.toList(),
            reasonCodes: _reasonCodes.toList(),
            equipmentIds: _equipmentIds.toList(),
            noteRequirement: _noteRequirement,
            evidenceRequirement: _evidenceRequirement,
            minPhotos: int.tryParse(_minPhotos.text) ?? 0,
            sampleData: _sampleData,
            severityPolicy: _severityPolicy.text.trim(),
            applicability: _applicability.text.trim(),
            guideImageId: _guideImageId,
          ),
        );
        ref.invalidate(itemsProvider);
        ref.invalidate(categoriesProvider);
        ref.invalidate(auditProvider);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else if (draft != null) {
        for (final entry in <String, (String, String)>{
          'en': (_labelEn.text, _instructionEn.text),
          'ar': (_labelAr.text, _instructionAr.text),
          'ru': (_labelRu.text, _instructionRu.text),
          'zh-Hans': (_labelZh.text, _instructionZh.text),
        }.entries) {
          if (entry.value.$1.trim().isEmpty && entry.value.$2.trim().isEmpty) {
            continue;
          }
          await api.updateTranslation(
            widget.initial!.item.id,
            draft.id,
            entry.key,
            entry.value.$1.trim(),
            entry.value.$2.trim(),
          );
        }
        await api.updateRules(
          widget.initial!.item.id,
          draft.id,
          ItemRules(
            resultOptions: _resultOptions.toList(),
            reasonCodes: _reasonCodes.toList(),
            equipmentIds: _equipmentIds.toList(),
            noteRequirement: _noteRequirement,
            evidenceRequirement: _evidenceRequirement,
            minPhotos: int.tryParse(_minPhotos.text) ?? 0,
            severityPolicy: _severityPolicy.text.trim(),
            applicability: _applicability.text.trim(),
            guideImageId: _guideImageId,
          ),
        );
        ref.invalidate(itemDetailProvider(widget.initial!.item.id));
        ref.invalidate(itemsProvider);
        ref.invalidate(auditProvider);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.contentSaved)));
        }
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
    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).createDraft(widget.initial!.item.id);
      ref.invalidate(itemDetailProvider(widget.initial!.item.id));
      ref.invalidate(itemsProvider);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _publish() async {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(adminApiProvider)
          .publish(widget.initial!.item.id, draft.id);
      ref.invalidate(itemDetailProvider(widget.initial!.item.id));
      ref.invalidate(itemsProvider);
      ref.invalidate(auditProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).versionPublished),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
        );
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
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).retireItem(widget.initial!.item.id);
      ref.invalidate(itemsProvider);
      ref.invalidate(auditProvider);
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

  static const _resultOptionCodes = [
    'NO_ISSUE_OBSERVED',
    'ATTENTION_RECOMMENDED',
    'DEFECT_FOUND',
    'NOT_CHECKED',
    'NOT_APPLICABLE',
    'COULD_NOT_VERIFY',
  ];
}
