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
import '../../platform_translations.dart';

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
  'NO_ISSUE_OBSERVED',
  'ATTENTION_RECOMMENDED',
  'DEFECT_FOUND',
];

class MasterItemEditorScreen extends StatelessWidget {
  const MasterItemEditorScreen({super.key, this.itemId});

  final String? itemId;

  @override
  Widget build(BuildContext context) {
    final id = itemId;
    if (id == null) {
      return const _CreateItemStepper();
    }
    return _EditItemView(itemId: id);
  }
}

class _EditorShell extends StatelessWidget {
  const _EditorShell({required this.child, this.contextBar});

  final Widget child;
  final Widget? contextBar;

  @override
  Widget build(BuildContext context) {
    return PlatformShell(
      currentRoute: '/checklist/items',
      contextBar: contextBar,
      child: PlatformPage(maxWidth: 1100, child: child),
    );
  }
}

class _CreateItemStepper extends ConsumerStatefulWidget {
  const _CreateItemStepper();

  @override
  ConsumerState<_CreateItemStepper> createState() => _CreateItemStepperState();
}

/// Lightweight label/instruction pair for a non-en/ar registry language.
class _LangText {
  _LangText({this.label = '', this.instruction = ''});

  String label;
  String instruction;

  _LangText copy() => _LangText(label: label, instruction: instruction);
}

/// Best-effort overlay save for non-en/ar languages. Translations for the
/// version-scoped ITEM entity are upserted AFTER the item exists; failures
/// are returned so the caller can surface a review-step warning instead of
/// failing the whole save.
Future<List<String>> _upsertExtraTranslations(
  TranslationApi api, {
  required String versionId,
  required Map<String, _LangText> extras,
}) async {
  final failed = <String>[];
  for (final entry in extras.entries) {
    final label = entry.value.label.trim();
    final instruction = entry.value.instruction.trim();
    if (label.isEmpty && instruction.isEmpty) continue;
    try {
      if (label.isNotEmpty) {
        await api.upsertTranslation(
          entityType: 'ITEM',
          entityId: versionId,
          field: 'label',
          language: entry.key,
          text: label,
        );
      }
      if (instruction.isNotEmpty) {
        await api.upsertTranslation(
          entityType: 'ITEM',
          entityId: versionId,
          field: 'instruction',
          language: entry.key,
          text: instruction,
        );
      }
    } catch (_) {
      failed.add(entry.key);
    }
  }
  return failed;
}

class _CreateItemStepperState extends ConsumerState<_CreateItemStepper> {
  int _step = 0;
  final _basicsFormKey = GlobalKey<FormState>();
  final _contentFormKey = GlobalKey<FormState>();
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
  List<EvidenceRule> _evidenceRules = const <EvidenceRule>[];
  List<IssueField> _issueFields = const <IssueField>[];
  List<MeasurementBand> _bands = const <MeasurementBand>[];
  bool _evidenceTouched = false;
  bool _fieldsTouched = false;
  bool _bandsTouched = false;
  Map<String, _LangText> _extras = {};
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

  List<PlatformLanguage> _extraLanguages(List<PlatformLanguage> languages) {
    return [
      for (final language in languages)
        if (language.code != 'en' && language.code != 'ar') language,
    ];
  }

  void _continueFrom(int step) {
    if (step == 0) {
      final valid =
          _basicsFormKey.currentState?.validate() == true &&
          _categoryId.isNotEmpty;
      if (!valid) {
        _basicsFormKey.currentState?.validate();
        setState(() {});
        return;
      }
    }
    if (step == 1) {
      if (_contentFormKey.currentState?.validate() != true) return;
    }
    if (step < 5) setState(() => _step = step + 1);
  }

  Future<void> _saveAll({required bool publish}) async {
    final l10n = AppLocalizations.of(context);
    if (_basicsFormKey.currentState?.validate() != true ||
        _categoryId.isEmpty) {
      setState(() => _step = 0);
      _basicsFormKey.currentState?.validate();
      return;
    }
    if (_contentFormKey.currentState?.validate() != true) {
      setState(() => _step = 1);
      return;
    }
    if (publish) {
      final confirmed = await showPlatformConfirmDialog(
        context: context,
        title: l10n.publishItem,
        body: l10n.publishItem,
        confirmLabel: l10n.publish,
      );
      if (confirmed != true) return;
    }
    setState(() => _saving = true);
    try {
      final actions = ref.read(platformConfigActionsProvider);
      final detail = await actions.createItem(<String, dynamic>{
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
        'maxTyreAgeYears': int.tryParse(_maxTyreAgeController.text.trim()),
        'allowFreeTextNote': _allowFreeTextNote,
        'sortOrder': int.tryParse(_sortOrderController.text.trim()) ?? 0,
      });
      final versionId = detail.draftVersion?.id ?? detail.versions.first.id;
      if (_evidenceTouched) {
        await actions.saveConfig(
          itemId: detail.item.id,
          versionId: versionId,
          evidenceRules: _evidenceRules,
        );
      }
      if (_fieldsTouched) {
        await actions.saveConfig(
          itemId: detail.item.id,
          versionId: versionId,
          issueFields: _issueFields,
        );
      }
      if (_bandsTouched) {
        await actions.saveConfig(
          itemId: detail.item.id,
          versionId: versionId,
          measurementBands: _bands,
        );
      }
      final failed = await _upsertExtraTranslations(
        ref.read(translationApiProvider),
        versionId: versionId,
        extras: _extras,
      );
      if (publish) {
        await actions.publishItem(detail.item.id, versionId);
      }
      if (!mounted) return;
      if (failed.isNotEmpty) {
        // Item and en/ar content are saved; extra-language translations can
        // be retried from the editor Content step.
        _showSnack(context, l10n.error, isError: true);
      } else {
        _showSnack(context, publish ? l10n.itemPublished : l10n.itemCreated);
      }
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
    final languages =
        ref.watch(platformLanguagesProvider).asData?.value ??
        const <PlatformLanguage>[];
    final extras = _extraLanguages(languages);
    final optionSets =
        ref.watch(optionSetsProvider).asData?.value ?? const <OptionSet>[];

    return _EditorShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(l10n),
          const SizedBox(height: 18),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.stepCounter(_step + 1, 6),
              style: PtTheme.font(
                12,
                weight: FontWeight.w700,
                color: PtTheme.muted,
                tracking: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Stepper(
            currentStep: _step,
            onStepTapped: (index) {
              if (index < _step && !_saving) {
                setState(() => _step = index);
              }
            },
            controlsBuilder: (context, details) {
              final isLast = _step == 5;
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (_step > 0)
                      PlatformSecondaryButton(
                        key: const Key('stepper-back'),
                        label: l10n.previous,
                        onPressed: _saving
                            ? null
                            : () => setState(() => _step--),
                      ),
                    if (!isLast)
                      PlatformPrimaryButton(
                        key: const Key('stepper-next'),
                        label: l10n.next,
                        onPressed: _saving ? null : () => _continueFrom(_step),
                      ),
                    if (isLast) ...[
                      PlatformSecondaryButton(
                        label: l10n.itemSaveDraft,
                        onPressed: _saving
                            ? null
                            : () => _saveAll(publish: false),
                      ),
                      PlatformPrimaryButton(
                        label: l10n.publish,
                        isLoading: _saving,
                        onPressed: _saving
                            ? null
                            : () => _saveAll(publish: true),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text(l10n.stepBasics),
                subtitle: Text(l10n.stepBasicsHelp),
                isActive: _step >= 0,
                state: _step > 0 ? StepState.complete : StepState.indexed,
                content: _buildBasicsStep(l10n, categories),
              ),
              Step(
                title: Text(l10n.stepContent),
                subtitle: Text(l10n.stepContentHelp),
                isActive: _step >= 1,
                state: _step > 1 ? StepState.complete : StepState.indexed,
                content: _buildContentStep(l10n, extras),
              ),
              Step(
                title: Text(l10n.stepIssueOptions),
                subtitle: Text(l10n.stepIssueHelp),
                isActive: _step >= 2,
                state: _step > 2 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.stepIssueHelp,
                      style: PtTheme.font(
                        13,
                        lineHeight: 19,
                        color: PtTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _IssueFieldsSection(
                      fields: _issueFields,
                      optionSets: optionSets,
                      editable: true,
                      onSave: (fields) async {
                        setState(() {
                          _issueFields = fields;
                          _fieldsTouched = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Step(
                title: Text(l10n.stepEvidence),
                subtitle: Text(l10n.stepEvidenceHelp),
                isActive: _step >= 3,
                state: _step > 3 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.stepEvidenceHelp,
                      style: PtTheme.font(
                        13,
                        lineHeight: 19,
                        color: PtTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EvidenceRulesSection(
                      rules: _evidenceRules,
                      editable: true,
                      onSave: (rules) async {
                        setState(() {
                          _evidenceRules = rules;
                          _evidenceTouched = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Step(
                title: Text(l10n.stepMeasurement),
                subtitle: Text(l10n.stepMeasureHelp),
                isActive: _step >= 4,
                state: _step > 4 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.stepMeasureHelp,
                      style: PtTheme.font(
                        13,
                        lineHeight: 19,
                        color: PtTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MeasurementBandsSection(
                      bands: _bands,
                      editable: true,
                      onSave: (bands) async {
                        setState(() {
                          _bands = bands;
                          _bandsTouched = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Step(
                title: Text(l10n.stepReview),
                subtitle: Text(l10n.stepReviewHelp),
                isActive: _step >= 5,
                state: StepState.indexed,
                content: _buildCreateReview(l10n, categories, extras),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicsStep(
    AppLocalizations l10n,
    List<PlatformCategory> categories,
  ) {
    return Form(
      key: _basicsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.stepBasicsHelp,
            style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final field in <Widget>[
                    PlatformTextField(
                      controller: _codeController,
                      label: l10n.itemCode,
                      validator: (value) => _required(value, l10n),
                    ),
                    FormField<String>(
                      initialValue: _categoryId,
                      validator: (value) =>
                          value == null || value.isEmpty ? l10n.category : null,
                      builder: (state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlatformDropdown<String>(
                            label: l10n.category,
                            value: state.value ?? '',
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('—'),
                              ),
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
                            onChanged: (value) {
                              state.didChange(value ?? '');
                              setState(() => _categoryId = value ?? '');
                            },
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 12,
                                top: 6,
                              ),
                              child: Text(
                                state.errorText!,
                                style: PtTheme.font(
                                  12,
                                  lineHeight: 16,
                                  color: PtTheme.rose,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    PlatformTextField(
                      controller: _unitController,
                      label: l10n.measurementUnit,
                    ),
                    PlatformTextField(
                      controller: _sensorController,
                      label: l10n.sensorTool,
                    ),
                    PlatformTextField(
                      controller: _sortOrderController,
                      label: l10n.categoryOrder,
                      keyboardType: TextInputType.number,
                    ),
                  ])
                    SizedBox(width: fieldWidth, child: field),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final field in <Widget>[
                    _SwitchTile(
                      label: l10n.safetyCritical,
                      value: _safetyCritical,
                      onChanged: (value) =>
                          setState(() => _safetyCritical = value),
                    ),
                    _SwitchTile(
                      label: l10n.multiPoint,
                      value: _multiPoint,
                      onChanged: (value) => setState(() => _multiPoint = value),
                    ),
                    _SwitchTile(
                      label: l10n.allowFreeText,
                      value: _allowFreeTextNote,
                      onChanged: (value) =>
                          setState(() => _allowFreeTextNote = value),
                    ),
                  ])
                    SizedBox(width: fieldWidth, child: field),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: PtTheme.canvas,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: PtTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              title: Text(
                l10n.itemAdvanced,
                style: PtTheme.font(
                  14,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth >= 700
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        for (final field in <Widget>[
                          PlatformTextField(
                            controller: _specEnController,
                            label: l10n.standardSpecEn,
                          ),
                          PlatformTextField(
                            controller: _specArController,
                            label: l10n.standardSpecAr,
                            textDirection: TextDirection.rtl,
                          ),
                          PlatformTextField(
                            controller: _maxTyreAgeController,
                            label: l10n.maxTyreAge,
                            keyboardType: TextInputType.number,
                          ),
                        ])
                          SizedBox(width: fieldWidth, child: field),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentStep(
    AppLocalizations l10n,
    List<PlatformLanguage> extras,
  ) {
    return Form(
      key: _contentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.stepContentHelp,
            style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            controller: _labelEnController,
            label: l10n.labelEn,
            validator: (value) => _required(value, l10n),
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            controller: _labelArController,
            label: l10n.labelAr,
            textDirection: TextDirection.rtl,
            validator: (value) => _required(value, l10n),
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            controller: _instructionEnController,
            label: l10n.instructionEn,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            controller: _instructionArController,
            label: l10n.instructionAr,
            maxLines: 3,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          _ExtraTranslationsCard(
            languages: extras,
            initial: _extras,
            onChanged: (texts) => _extras = texts,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateReview(
    AppLocalizations l10n,
    List<PlatformCategory> categories,
    List<PlatformLanguage> extras,
  ) {
    var categoryName = _categoryId;
    for (final category in categories) {
      if (category.id == _categoryId) {
        categoryName = category.name.isEmpty ? category.code : category.name;
        break;
      }
    }
    final stagedExtras = [
      for (final language in extras)
        if (((_extras[language.code]?.label.trim().isNotEmpty) == true) ||
            ((_extras[language.code]?.instruction.trim().isNotEmpty) == true))
          language.code,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.stepReviewHelp,
          style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
        ),
        const SizedBox(height: 12),
        PlatformSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReviewRow(
                label: l10n.itemCode,
                value: _codeController.text.trim().isEmpty
                    ? '—'
                    : _codeController.text.trim(),
              ),
              _ReviewRow(label: l10n.category, value: categoryName),
              _ReviewRow(
                label: l10n.labelEn,
                value: _labelEnController.text.trim().isEmpty
                    ? '—'
                    : _labelEnController.text.trim(),
              ),
              _ReviewRow(
                label: l10n.labelAr,
                value: _labelArController.text.trim().isEmpty
                    ? '—'
                    : _labelArController.text.trim(),
              ),
              _ReviewRow(
                label: l10n.measurementUnit,
                value: _unitController.text.trim().isEmpty
                    ? '—'
                    : _unitController.text.trim(),
              ),
              _ReviewRow(
                label: l10n.issueFields,
                value: '${_issueFields.length}',
              ),
              _ReviewRow(
                label: l10n.evidenceRules,
                value: '${_evidenceRules.length}',
              ),
              _ReviewRow(
                label: l10n.measurementBands,
                value: '${_bands.length}',
              ),
              if (stagedExtras.isNotEmpty)
                _ReviewRow(
                  label: l10n.stepContent,
                  value: stagedExtras.join(', '),
                ),
            ],
          ),
        ),
      ],
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.addItem,
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: PtTheme.font(
                12,
                weight: FontWeight.w600,
                color: PtTheme.muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: PtTheme.font(
                13,
                weight: FontWeight.w600,
                color: PtTheme.ink,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extra (non-en/ar) language fields driven by the language registry.
///
/// In create mode the texts are synced live via [onChanged] and upserted
/// after the item is created. In edit mode they are saved explicitly via
/// [onSave]; the overlay save is best-effort and failures are reported back
/// to the review step.
class _ExtraTranslationsCard extends StatefulWidget {
  const _ExtraTranslationsCard({
    required this.languages,
    this.initial = const {},
    this.enabled = true,
    this.saving = false,
    this.onSave,
    this.onChanged,
  });

  final List<PlatformLanguage> languages;
  final Map<String, _LangText> initial;
  final bool enabled;
  final bool saving;
  final Future<void> Function(Map<String, _LangText> texts)? onSave;
  final ValueChanged<Map<String, _LangText>>? onChanged;

  @override
  State<_ExtraTranslationsCard> createState() => _ExtraTranslationsCardState();
}

class _ExtraTranslationsCardState extends State<_ExtraTranslationsCard> {
  final Map<String, TextEditingController> _labels = {};
  final Map<String, TextEditingController> _instructions = {};

  @override
  void initState() {
    super.initState();
    _reconcile(widget.languages);
  }

  @override
  void didUpdateWidget(covariant _ExtraTranslationsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.languages, widget.languages)) {
      _reconcile(widget.languages);
    }
  }

  void _reconcile(List<PlatformLanguage> languages) {
    final codes = {for (final language in languages) language.code};
    for (final code in List.of(_labels.keys)) {
      if (!codes.contains(code)) {
        _labels.remove(code)?.dispose();
        _instructions.remove(code)?.dispose();
      }
    }
    for (final language in languages) {
      if (_labels.containsKey(language.code)) continue;
      final initial = widget.initial[language.code];
      final label = TextEditingController(text: initial?.label ?? '');
      final instruction = TextEditingController(
        text: initial?.instruction ?? '',
      );
      label.addListener(_notify);
      instruction.addListener(_notify);
      _labels[language.code] = label;
      _instructions[language.code] = instruction;
    }
  }

  void _notify() {
    widget.onChanged?.call(_snapshot());
  }

  Map<String, _LangText> _snapshot() {
    return {
      for (final code in _labels.keys)
        code: _LangText(
          label: _labels[code]!.text,
          instruction: _instructions[code]!.text,
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _labels.values) {
      controller.dispose();
    }
    for (final controller in _instructions.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.languages.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final language in widget.languages) ...[
          Container(
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
                  language.nativeName.isEmpty
                      ? language.code
                      : language.nativeName,
                  style: PtTheme.font(
                    14,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
                const SizedBox(height: 10),
                PlatformTextField(
                  controller: _labels[language.code]!,
                  label: l10n.labelEn,
                  enabled: widget.enabled,
                  textDirection: language.direction == 'rtl'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
                const SizedBox(height: 10),
                PlatformTextField(
                  controller: _instructions[language.code]!,
                  label: l10n.instructionEn,
                  enabled: widget.enabled,
                  maxLines: 4,
                  textDirection: language.direction == 'rtl'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.onSave != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PlatformPrimaryButton(
              label: l10n.save,
              isLoading: widget.saving,
              onPressed: widget.enabled && !widget.saving
                  ? () => widget.onSave!(_snapshot())
                  : null,
            ),
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
  int _step = 0;
  bool _creatingDraft = false;
  bool _publishing = false;
  bool _retiring = false;
  Map<String, _LangText> _extras = {};
  List<String> _extraFailed = [];
  bool _extraSaving = false;

  Future<void> _createDraft() async {
    setState(() => _creatingDraft = true);
    try {
      await ref.read(platformConfigActionsProvider).createDraft(widget.itemId);
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
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: l10n.publishItem,
      body: '${l10n.publishItem} Â· v${draft.versionNo}',
      confirmLabel: l10n.publishItem,
    );
    if (!confirmed) return;
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

  Future<void> _retire(PlatformItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: l10n.retireItem,
      body: l10n.retireConfirm,
      confirmLabel: l10n.retire,
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _retiring = true);
    try {
      await ref.read(platformConfigActionsProvider).retireItem(item.id);
      if (!mounted) return;
      _showSnack(context, l10n.itemRetired);
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _retiring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(itemDetailProvider(widget.itemId));
    return detailAsync.when(
      loading: () =>
          _EditorShell(child: PlatformLoadingView(message: l10n.loading)),
      error: (error, _) => _EditorShell(
        child: PlatformErrorView(
          message: _failureMessage(error),
          onRetry: () => ref.invalidate(itemDetailProvider(widget.itemId)),
        ),
      ),
      data: (detail) => _EditorShell(
        contextBar: PlatformContextBar(
          breadcrumbs: [
            ContextBreadcrumbItem(
              label: l10n.masterLibraryTitle,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            ContextBreadcrumbItem(label: detail.item.code),
          ],
        ),
        child: _buildDetail(l10n, detail),
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
          PlatformEmptyView(
            title: l10n.noData,
            actionLabel: l10n.createDraft,
            onAction: _creatingDraft ? null : _createDraft,
          )
        else ...[
          if (!editable) _buildImmutableBanner(l10n, detail),
          if (!editable) const SizedBox(height: 14),
          _buildStepper(l10n, detail, version, editable, optionSets),
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
                      PlatformStatusChip(status: item.status),
                      if (version != null)
                        PlatformStatusChip(status: version.status),
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
                            'v${itemVersion.versionNo} Â· ${itemVersion.status}',
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
            if (item.status != 'RETIRED')
              PlatformSecondaryButton(
                label: l10n.retireItem,
                icon: Icons.archive_outlined,
                destructive: true,
                onPressed: _retiring ? null : () => _retire(item),
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
              child: PlatformSecondaryButton(
                label: l10n.createDraft,
                icon: Icons.add_rounded,
                onPressed: _creatingDraft ? null : _createDraft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _stepTitles(AppLocalizations l10n) => [
    l10n.stepBasics,
    l10n.stepContent,
    l10n.stepIssueOptions,
    l10n.stepEvidence,
    l10n.stepMeasurement,
    l10n.stepReview,
  ];

  List<String> _stepHelps(AppLocalizations l10n) => [
    l10n.stepBasicsHelp,
    l10n.stepContentHelp,
    l10n.stepIssueHelp,
    l10n.stepEvidenceHelp,
    l10n.stepMeasureHelp,
    l10n.stepReviewHelp,
  ];

  /// Inline per-step validity on persisted state. Content requires saved
  /// en/ar labels; config steps accept the server model as-is (empty lists
  /// and optional fields are valid), so they never block Next.
  bool _stepValid(int step, PlatformItemVersion version) {
    if (step != 1) return true;
    final enLabel = version.translations['en']?.label.trim() ?? '';
    final arLabel = version.translations['ar']?.label.trim() ?? '';
    return enLabel.isNotEmpty && arLabel.isNotEmpty;
  }

  Future<void> _saveExtras(
    PlatformItemVersion version,
    Map<String, _LangText> texts,
  ) async {
    setState(() => _extraSaving = true);
    try {
      final failed = await _upsertExtraTranslations(
        ref.read(translationApiProvider),
        versionId: version.id,
        extras: texts,
      );
      if (!mounted) return;
      setState(() {
        _extraSaving = false;
        _extraFailed = failed;
        _extras = texts;
      });
      if (failed.isNotEmpty) {
        _showSnack(context, AppLocalizations.of(context).error, isError: true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _extraSaving = false;
        _extraFailed = texts.keys.toList(growable: false);
      });
      _showSnack(context, _failureMessage(error), isError: true);
    }
  }

  /// Review-step draft action: creates a draft when none exists, otherwise
  /// refreshes so the summary reflects the latest per-section saves.
  Future<void> _ensureDraft(PlatformItemDetail detail) async {
    if (detail.draftVersion != null) {
      ref.invalidate(itemDetailProvider(widget.itemId));
      return;
    }
    await _createDraft();
  }

  Widget _buildStepper(
    AppLocalizations l10n,
    PlatformItemDetail detail,
    PlatformItemVersion version,
    bool editable,
    List<OptionSet> optionSets,
  ) {
    final titles = _stepTitles(l10n);
    final helps = _stepHelps(l10n);
    final valid = _stepValid(_step, version);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.stepCounter(_step + 1, titles.length),
            style: PtTheme.font(
              12,
              weight: FontWeight.w700,
              color: PtTheme.muted,
              tracking: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Stepper(
          currentStep: _step,
          onStepTapped: (index) {
            if (index < _step) setState(() => _step = index);
          },
          controlsBuilder: (context, details) {
            final isLast = _step == titles.length - 1;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (_step > 0)
                    PlatformSecondaryButton(
                      key: const Key('stepper-back'),
                      label: l10n.previous,
                      onPressed: () => setState(() => _step--),
                    ),
                  if (!isLast)
                    PlatformPrimaryButton(
                      key: const Key('stepper-next'),
                      label: l10n.next,
                      onPressed: valid ? () => setState(() => _step++) : null,
                    ),
                ],
              ),
            );
          },
          steps: [
            for (var index = 0; index < titles.length; index++)
              Step(
                title: Text(titles[index]),
                subtitle: Text(helps[index]),
                isActive: _step >= index,
                state: _step > index ? StepState.complete : StepState.indexed,
                content: _buildStepContent(
                  index,
                  l10n,
                  detail,
                  version,
                  editable,
                  optionSets,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepContent(
    int index,
    AppLocalizations l10n,
    PlatformItemDetail detail,
    PlatformItemVersion version,
    bool editable,
    List<OptionSet> optionSets,
  ) {
    final key = ItemVersionKey(widget.itemId, version.id);
    final configAsync = ref.watch(itemConfigProvider(key));
    final languages =
        ref.watch(platformLanguagesProvider).asData?.value ??
        const <PlatformLanguage>[];
    final extras = [
      for (final language in languages)
        if (language.code != 'en' && language.code != 'ar') language,
    ];
    switch (index) {
      case 0:
        return configAsync.when(
          loading: () => PlatformLoadingView(message: l10n.loading),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            onRetry: () => ref.invalidate(itemConfigProvider(key)),
          ),
          data: (config) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.stepBasicsHelp,
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
              ),
              const SizedBox(height: 12),
              _BasicsSection(
                itemId: widget.itemId,
                metadata: config.metadata,
                editable: editable,
                onSave: (metadata) => ref
                    .read(platformConfigActionsProvider)
                    .saveMetadata(widget.itemId, metadata),
              ),
            ],
          ),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.stepContentHelp,
              style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
            ),
            const SizedBox(height: 12),
            _TranslationsSection(
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
            ),
            const SizedBox(height: 12),
            _ExtraTranslationsCard(
              languages: extras,
              initial: _extras,
              enabled: editable,
              saving: _extraSaving,
              onSave: (texts) => _saveExtras(version, texts),
            ),
            if (!_stepValid(1, version)) ...[
              const SizedBox(height: 8),
              Text(
                l10n.required,
                style: PtTheme.font(
                  12,
                  lineHeight: 16,
                  weight: FontWeight.w600,
                  color: PtTheme.rose,
                ),
              ),
            ],
          ],
        );
      case 2:
        return configAsync.when(
          loading: () => PlatformLoadingView(message: l10n.loading),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            onRetry: () => ref.invalidate(itemConfigProvider(key)),
          ),
          data: (config) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.stepIssueHelp,
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
              ),
              const SizedBox(height: 12),
              _IssueFieldsSection(
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
              ),
            ],
          ),
        );
      case 3:
        return configAsync.when(
          loading: () => PlatformLoadingView(message: l10n.loading),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            onRetry: () => ref.invalidate(itemConfigProvider(key)),
          ),
          data: (config) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.stepEvidenceHelp,
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
              ),
              const SizedBox(height: 12),
              _EvidenceRulesSection(
                rules: config.evidenceRules,
                editable: editable,
                onSave: (rules) => ref
                    .read(platformConfigActionsProvider)
                    .saveConfig(
                      itemId: widget.itemId,
                      versionId: version.id,
                      evidenceRules: rules,
                    ),
              ),
            ],
          ),
        );
      case 4:
        return configAsync.when(
          loading: () => PlatformLoadingView(message: l10n.loading),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            onRetry: () => ref.invalidate(itemConfigProvider(key)),
          ),
          data: (config) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.stepMeasureHelp,
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
              ),
              const SizedBox(height: 12),
              _MeasurementBandsSection(
                bands: config.measurementBands,
                editable: editable,
                onSave: (bands) => ref
                    .read(platformConfigActionsProvider)
                    .saveConfig(
                      itemId: widget.itemId,
                      versionId: version.id,
                      measurementBands: bands,
                    ),
              ),
            ],
          ),
        );
      default:
        return _buildEditReview(l10n, detail);
    }
  }

  Widget _buildEditReview(AppLocalizations l10n, PlatformItemDetail detail) {
    final draft = detail.draftVersion;
    if (draft == null) {
      return PlatformEmptyView(
        title: l10n.noData,
        actionLabel: l10n.createDraft,
        onAction: _creatingDraft ? null : _createDraft,
      );
    }
    final key = ItemVersionKey(widget.itemId, draft.id);
    final configAsync = ref.watch(itemConfigProvider(key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.stepReviewHelp,
          style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
        ),
        const SizedBox(height: 12),
        configAsync.when(
          loading: () => PlatformLoadingView(message: l10n.loading),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(itemConfigProvider(key)),
          ),
          data: (config) {
            final item = detail.item;
            return PlatformSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      PlatformStatusChip(status: item.status),
                      PlatformStatusChip(status: draft.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.labelEn.isEmpty ? item.code : item.labelEn,
                    style: PtTheme.font(
                      18,
                      lineHeight: 24,
                      weight: FontWeight.w800,
                      color: PtTheme.ink,
                    ),
                  ),
                  if (item.labelAr.isNotEmpty)
                    Text(
                      item.labelAr,
                      textDirection: TextDirection.rtl,
                      style: PtTheme.font(
                        14,
                        lineHeight: 20,
                        color: PtTheme.muted,
                      ),
                    ),
                  const SizedBox(height: 8),
                  _ReviewRow(
                    label: l10n.measurementUnit,
                    value: config.metadata.measurementUnit.isEmpty
                        ? '—'
                        : config.metadata.measurementUnit,
                  ),
                  _ReviewRow(
                    label: l10n.issueFields,
                    value: '${config.issueFields.length}',
                  ),
                  _ReviewRow(
                    label: l10n.evidenceRules,
                    value: '${config.evidenceRules.length}',
                  ),
                  _ReviewRow(
                    label: l10n.measurementBands,
                    value: '${config.measurementBands.length}',
                  ),
                  if (_extraFailed.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PtTheme.rose.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: PtTheme.rose.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '${l10n.error}: ${_extraFailed.join(', ')}',
                        style: PtTheme.font(
                          12,
                          lineHeight: 17,
                          weight: FontWeight.w600,
                          color: PtTheme.rose,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            PlatformSecondaryButton(
              label: l10n.itemSaveDraft,
              icon: Icons.note_add_outlined,
              onPressed: _creatingDraft ? null : () => _ensureDraft(detail),
            ),
            PlatformPrimaryButton(
              label: l10n.publish,
              icon: Icons.publish_rounded,
              isLoading: _publishing,
              onPressed: _publishing ? null : () => _publish(draft),
            ),
          ],
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
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(title: l10n.basics),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final field in <Widget>[
                    PlatformTextField(
                      controller: _unit,
                      label: l10n.measurementUnit,
                      enabled: widget.editable,
                    ),
                    PlatformTextField(
                      controller: _sensor,
                      label: l10n.sensorTool,
                      enabled: widget.editable,
                    ),
                  ])
                    SizedBox(width: fieldWidth, child: field),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Material(
            color: PtTheme.canvas,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: PtTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              title: Text(
                l10n.itemAdvanced,
                style: PtTheme.font(
                  14,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth >= 700
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        for (final field in <Widget>[
                          PlatformTextField(
                            controller: _specEn,
                            label: l10n.standardSpecEn,
                            enabled: widget.editable,
                          ),
                          PlatformTextField(
                            controller: _specAr,
                            label: l10n.standardSpecAr,
                            enabled: widget.editable,
                            textDirection: TextDirection.rtl,
                          ),
                          PlatformTextField(
                            controller: _maxTyreAge,
                            label: l10n.maxTyreAge,
                            enabled: widget.editable,
                            keyboardType: TextInputType.number,
                          ),
                          PlatformTextField(
                            controller: _sortOrder,
                            label: l10n.categoryOrder,
                            enabled: widget.editable,
                            keyboardType: TextInputType.number,
                          ),
                          PlatformTextField(
                            controller: _guideImage,
                            label: l10n.guideImage,
                            enabled: widget.editable,
                          ),
                        ])
                          SizedBox(width: fieldWidth, child: field),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final field in <Widget>[
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
                  ])
                    SizedBox(width: fieldWidth, child: field),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PlatformPrimaryButton(
              label: l10n.save,
              isLoading: _saving,
              onPressed: widget.editable && !_saving ? () => _save(l10n) : null,
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
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: '${l10n.englishContent} / ${l10n.arabicContent}',
          ),
          const SizedBox(height: 12),
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
            child: PlatformPrimaryButton(
              label: l10n.save,
              isLoading: _saving,
              onPressed: widget.editable && !_saving ? _save : null,
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
          PlatformTextField(
            controller: labelController,
            label: isRtl ? l10n.labelAr : l10n.labelEn,
            enabled: widget.editable,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: 10),
          PlatformTextField(
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
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(title: l10n.evidenceRules),
          const SizedBox(height: 12),
          for (var index = 0; index < _forms.length; index++) ...[
            _buildRuleRow(l10n, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformSecondaryButton(
                label: l10n.addItem,
                icon: Icons.add_rounded,
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
              ),
              PlatformPrimaryButton(
                label: l10n.save,
                isLoading: _saving,
                onPressed: widget.editable && !_saving ? _save : null,
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
                child: IgnorePointer(
                  ignoring: !widget.editable,
                  child: Opacity(
                    opacity: widget.editable ? 1 : 0.6,
                    child: PlatformDropdown<String>(
                      label: l10n.status,
                      value: form.resultCode,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final field in <Widget>[
                    PlatformTextField(
                      controller: form.minPhotos,
                      label: l10n.minPhotos,
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                    PlatformTextField(
                      controller: form.minVideos,
                      label: l10n.minVideos,
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                    PlatformTextField(
                      controller: form.minNotes,
                      label: l10n.minNotes,
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                    IgnorePointer(
                      ignoring: !widget.editable,
                      child: Opacity(
                        opacity: widget.editable ? 1 : 0.6,
                        child: PlatformDropdown<String>(
                          label: l10n.requiredEvidenceType,
                          value:
                              _evidenceTypes.contains(form.requiredEvidenceType)
                              ? form.requiredEvidenceType
                              : '',
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
                      ),
                    ),
                  ])
                    SizedBox(width: fieldWidth, child: field),
                ],
              );
            },
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
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(title: l10n.issueFields),
          const SizedBox(height: 12),
          for (var index = 0; index < _forms.length; index++) ...[
            _buildFieldRow(l10n, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformSecondaryButton(
                label: l10n.addItem,
                icon: Icons.add_rounded,
                onPressed: widget.editable
                    ? () => setState(
                        () => _forms.add(_IssueFieldForm.empty(_forms.length)),
                      )
                    : null,
              ),
              PlatformPrimaryButton(
                label: l10n.save,
                isLoading: _saving,
                onPressed: widget.editable && !_saving ? _save : null,
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
    OptionSet? selectedOptionSet;
    for (final optionSet in widget.optionSets) {
      if (optionSet.code == form.optionSetCode) {
        selectedOptionSet = optionSet;
        break;
      }
    }
    final usesOptions =
        form.inputType == 'SELECT' || form.inputType == 'MULTI_SELECT';
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
                child: PlatformTextField(
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
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final field in <Widget>[
                    PlatformTextField(
                      controller: form.labelEn,
                      label: l10n.labelEn,
                      enabled: widget.editable,
                    ),
                    PlatformTextField(
                      controller: form.labelAr,
                      label: l10n.labelAr,
                      enabled: widget.editable,
                      textDirection: TextDirection.rtl,
                    ),
                    IgnorePointer(
                      ignoring: !widget.editable,
                      child: Opacity(
                        opacity: widget.editable ? 1 : 0.6,
                        child: PlatformDropdown<String>(
                          label: l10n.inputType,
                          value: form.inputType,
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
                      ),
                    ),
                    IgnorePointer(
                      ignoring: !widget.editable,
                      child: Opacity(
                        opacity: widget.editable ? 1 : 0.6,
                        child: PlatformDropdown<String>(
                          label: l10n.optionSet,
                          value: form.optionSetCode,
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('â€”'),
                            ),
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
                      ),
                    ),
                    PlatformTextField(
                      controller: form.minValue,
                      label: l10n.minValue,
                      enabled: widget.editable,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    PlatformTextField(
                      controller: form.maxValue,
                      label: l10n.maxValue,
                      enabled: widget.editable,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    PlatformTextField(
                      controller: form.decimalPlaces,
                      label: l10n.decimalPlaces,
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                    PlatformTextField(
                      controller: form.dependsOnFieldCode,
                      label: l10n.dependsOn,
                      enabled: widget.editable,
                    ),
                    PlatformTextField(
                      controller: form.dependsOnValueCode,
                      label: 'Depends on value',
                      enabled: widget.editable,
                    ),
                    PlatformTextField(
                      controller: form.sortOrder,
                      label: l10n.categoryOrder,
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                  ])
                    SizedBox(width: fieldWidth, child: field),
                ],
              );
            },
          ),
          if (usesOptions &&
              selectedOptionSet != null &&
              selectedOptionSet.values.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.allowedValues,
              style: PtTheme.font(
                12,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            const SizedBox(height: 6),
            IgnorePointer(
              ignoring: !widget.editable,
              child: Opacity(
                opacity: widget.editable ? 1 : 0.6,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final value in selectedOptionSet.values)
                      PlatformFilterChip(
                        label: value.labelEn.isEmpty
                            ? value.code
                            : value.labelEn,
                        selected: form.allowedValues.contains(value.code),
                        onTap: () => setState(() {
                          if (form.allowedValues.contains(value.code)) {
                            form.allowedValues.remove(value.code);
                          } else {
                            form.allowedValues.add(value.code);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ],
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
                onChanged: (value) => setState(() => form.required = value),
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
            l10n.requiredForStatuses,
            style: PtTheme.font(
              12,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          IgnorePointer(
            ignoring: !widget.editable,
            child: Opacity(
              opacity: widget.editable ? 1 : 0.6,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final status in _requiredForStatuses)
                    PlatformFilterChip(
                      label: status,
                      selected: form.requiredForStatuses.contains(status),
                      onTap: () => setState(() {
                        if (form.requiredForStatuses.contains(status)) {
                          form.requiredForStatuses.remove(status);
                        } else {
                          form.requiredForStatuses.add(status);
                        }
                      }),
                    ),
                ],
              ),
            ),
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
      minValue = TextEditingController(text: field.minValue?.toString() ?? ''),
      maxValue = TextEditingController(text: field.maxValue?.toString() ?? ''),
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
      allowedValues = List<String>.from(field.allowedValues);

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
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(title: l10n.measurementBands),
          const SizedBox(height: 12),
          for (var index = 0; index < _forms.length; index++) ...[
            _buildBandRow(l10n, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformSecondaryButton(
                label: l10n.addItem,
                icon: Icons.add_rounded,
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
                              labelEn: '',
                              labelAr: '',
                              sortOrder: _forms.length,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              PlatformPrimaryButton(
                label: l10n.save,
                isLoading: _saving,
                onPressed: widget.editable && !_saving ? _save : null,
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
                child: PlatformTextField(
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
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final field in <Widget>[
                    PlatformTextField(
                      controller: form.unitCode,
                      label: l10n.measurementUnit,
                      enabled: widget.editable,
                    ),
                    IgnorePointer(
                      ignoring: !widget.editable,
                      child: Opacity(
                        opacity: widget.editable ? 1 : 0.6,
                        child: PlatformDropdown<String>(
                          label: 'Direction',
                          value: form.direction,
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
                      ),
                    ),
                    PlatformTextField(
                      controller: form.minValue,
                      label: l10n.minValue,
                      enabled: widget.editable,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    PlatformTextField(
                      controller: form.maxValue,
                      label: l10n.maxValue,
                      enabled: widget.editable,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    IgnorePointer(
                      ignoring: !widget.editable,
                      child: Opacity(
                        opacity: widget.editable ? 1 : 0.6,
                        child: PlatformDropdown<String>(
                          label: l10n.status,
                          value: form.resultCode,
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
                    ),
                    PlatformTextField(
                      controller: form.labelEn,
                      label: l10n.labelEn,
                      enabled: widget.editable,
                    ),
                    PlatformTextField(
                      controller: form.labelAr,
                      label: l10n.labelAr,
                      enabled: widget.editable,
                      textDirection: TextDirection.rtl,
                    ),
                    PlatformTextField(
                      controller: form.sortOrder,
                      label: l10n.categoryOrder,
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                  ])
                    SizedBox(width: fieldWidth, child: field),
                ],
              );
            },
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
      labelEn = TextEditingController(text: band.labelEn),
      labelAr = TextEditingController(text: band.labelAr),
      sortOrder = TextEditingController(text: band.sortOrder.toString());

  final TextEditingController fieldCode;
  final TextEditingController unitCode;
  String direction;
  final TextEditingController minValue;
  final TextEditingController maxValue;
  String resultCode;
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
    labelEn: labelEn.text.trim(),
    labelAr: labelAr.text.trim(),
    sortOrder: int.tryParse(sortOrder.text.trim()) ?? 0,
  );

  void dispose() {
    fieldCode.dispose();
    unitCode.dispose();
    minValue.dispose();
    maxValue.dispose();
    labelEn.dispose();
    labelAr.dispose();
    sortOrder.dispose();
  }
}

String? _required(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) return l10n.required;
  return null;
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

/// NOTE: _SwitchTile stays local (no shared switch component exists).
/// Status, state, button, input and section chrome use shared components.
