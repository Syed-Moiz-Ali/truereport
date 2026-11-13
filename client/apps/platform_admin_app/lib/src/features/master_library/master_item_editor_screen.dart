import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

String _resultLabel(UiMessageStrings strings, String code) {
  switch (code) {
    case 'NO_ISSUE_OBSERVED':
      return strings.tKey(PlatformAdminKeys.labelResultCodeNoIssueObserved);
    case 'ATTENTION_RECOMMENDED':
      return strings.tKey(
        PlatformAdminKeys.labelResultCodeAttentionRecommended,
      );
    case 'DEFECT_FOUND':
      return strings.tKey(PlatformAdminKeys.labelResultCodeDefectFound);
    default:
      return code;
  }
}

String _evidenceTypeLabel(UiMessageStrings strings, String type) {
  switch (type) {
    case 'PHOTO':
      return strings.tKey(PlatformAdminKeys.labelEvidenceTypePhoto);
    case 'VIDEO':
      return strings.tKey(PlatformAdminKeys.labelEvidenceTypeVideo);
    case 'DOCUMENT':
      return strings.tKey(PlatformAdminKeys.labelEvidenceTypeDocument);
    case '':
      return strings.tKey(PlatformAdminKeys.labelEvidenceTypeNone);
    default:
      return type;
  }
}

String _inputTypeLabel(UiMessageStrings strings, String type) {
  switch (type) {
    case 'SELECT':
      return strings.tKey(PlatformAdminKeys.labelInputTypeSelect);
    case 'MULTI_SELECT':
      return strings.tKey(PlatformAdminKeys.labelInputTypeMultiSelect);
    case 'NUMBER':
      return strings.tKey(PlatformAdminKeys.labelInputTypeNumber);
    case 'BOOLEAN':
      return strings.tKey(PlatformAdminKeys.labelInputTypeBoolean);
    case 'TEXT':
      return strings.tKey(PlatformAdminKeys.labelInputTypeText);
    default:
      return type;
  }
}

String _directionLabel(UiMessageStrings strings, String direction) {
  switch (direction) {
    case 'HIGHER_IS_BETTER':
      return strings.tKey(
        PlatformAdminKeys.labelMeasureDirectionHigherIsBetter,
      );
    case 'LOWER_IS_BETTER':
      return strings.tKey(PlatformAdminKeys.labelMeasureDirectionLowerIsBetter);
    default:
      return direction;
  }
}

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

class _CreateItemStepperState extends ConsumerState<_CreateItemStepper> {
  int _step = 0;
  final _basicsFormKey = GlobalKey<FormState>();
  final _contentFormKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _labelController = TextEditingController();
  final _instructionController = TextEditingController();
  final _unitController = TextEditingController();
  final _sensorController = TextEditingController();
  final _specController = TextEditingController();
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
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _labelController.dispose();
    _instructionController.dispose();
    _unitController.dispose();
    _sensorController.dispose();
    _specController.dispose();
    _maxTyreAgeController.dispose();
    _sortOrderController.dispose();
    super.dispose();
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
    final strings = ref.read(uiStringsProvider);
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
        title: strings.tKey(PlatformAdminKeys.buttonItemPublish),
        body: strings.tKey(PlatformAdminKeys.buttonItemPublish),
        confirmLabel: strings.tKey(PlatformAdminKeys.buttonPublish),
      );
      if (confirmed != true) return;
    }
    setState(() => _saving = true);
    try {
      final actions = ref.read(platformConfigActionsProvider);
      final detail = await actions.createItem(<String, dynamic>{
        'stableCode': _codeController.text.trim(),
        'categoryId': _categoryId,
        'label': _labelController.text.trim(),
        'instruction': _instructionController.text.trim(),
        'standardSpec': _specController.text.trim(),
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
      if (publish) {
        await actions.publishItem(detail.item.id, versionId);
      }
      if (!mounted) return;
      _showSnack(
        context,
        publish
            ? strings.tKey(PlatformAdminKeys.toastItemPublished)
            : strings.tKey(PlatformAdminKeys.toastItemCreated),
      );
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
    final strings = ref.watch(uiStringsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories =
        categoriesAsync.asData?.value ?? const <PlatformCategory>[];
    final optionSets =
        ref.watch(optionSetsProvider).asData?.value ?? const <OptionSet>[];

    return _EditorShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(strings),
          const SizedBox(height: 18),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              strings.tArgsKey(PlatformAdminKeys.stepCounter, {
                'current': _step + 1,
                'total': 6,
              }),
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
                        label: strings.tKey(CommonKeys.buttonPrevious),
                        onPressed: _saving
                            ? null
                            : () => setState(() => _step--),
                      ),
                    if (!isLast)
                      PlatformPrimaryButton(
                        key: const Key('stepper-next'),
                        label: strings.tKey(CommonKeys.buttonNext),
                        onPressed: _saving ? null : () => _continueFrom(_step),
                      ),
                    if (isLast) ...[
                      PlatformSecondaryButton(
                        label: strings.tKey(
                          PlatformAdminKeys.buttonItemSaveDraft,
                        ),
                        onPressed: _saving
                            ? null
                            : () => _saveAll(publish: false),
                      ),
                      PlatformPrimaryButton(
                        label: strings.tKey(PlatformAdminKeys.buttonPublish),
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
                title: Text(strings.tKey(PlatformAdminKeys.stepItemBasics)),
                subtitle: Text(strings.tKey(PlatformAdminKeys.helpStepBasics)),
                isActive: _step >= 0,
                state: _step > 0 ? StepState.complete : StepState.indexed,
                content: _buildBasicsStep(strings, categories),
              ),
              Step(
                title: Text(strings.tKey(PlatformAdminKeys.stepItemContent)),
                subtitle: Text(strings.tKey(PlatformAdminKeys.helpStepContent)),
                isActive: _step >= 1,
                state: _step > 1 ? StepState.complete : StepState.indexed,
                content: _buildContentStep(strings),
              ),
              Step(
                title: Text(
                  strings.tKey(PlatformAdminKeys.stepItemIssueOptions),
                ),
                subtitle: Text(
                  strings.tKey(PlatformAdminKeys.helpStepIssueOptions),
                ),
                isActive: _step >= 2,
                state: _step > 2 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.tKey(PlatformAdminKeys.helpStepIssueOptions),
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
                title: Text(strings.tKey(PlatformAdminKeys.stepItemEvidence)),
                subtitle: Text(
                  strings.tKey(PlatformAdminKeys.helpStepEvidence),
                ),
                isActive: _step >= 3,
                state: _step > 3 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.tKey(PlatformAdminKeys.helpStepEvidence),
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
                title: Text(
                  strings.tKey(PlatformAdminKeys.stepItemMeasurements),
                ),
                subtitle: Text(
                  strings.tKey(PlatformAdminKeys.helpStepMeasurements),
                ),
                isActive: _step >= 4,
                state: _step > 4 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.tKey(PlatformAdminKeys.helpStepMeasurements),
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
                title: Text(strings.tKey(PlatformAdminKeys.stepItemReview)),
                subtitle: Text(strings.tKey(PlatformAdminKeys.helpStepReview)),
                isActive: _step >= 5,
                state: StepState.indexed,
                content: _buildCreateReview(strings, categories),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicsStep(dynamic strings, List<PlatformCategory> categories) {
    return Form(
      key: _basicsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.tKey(PlatformAdminKeys.helpStepBasics),
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
                      label: strings.tKey(PlatformAdminKeys.fieldItemCode),
                      validator: (value) => _required(value, strings),
                    ),
                    FormField<String>(
                      initialValue: _categoryId,
                      validator: (value) => value == null || value.isEmpty
                          ? strings.tKey(CommonKeys.labelCategory)
                          : null,
                      builder: (state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlatformDropdown<String>(
                            label: strings.tKey(CommonKeys.labelCategory),
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
                      label: strings.tKey(
                        PlatformAdminKeys.fieldItemMeasurementUnit,
                      ),
                    ),
                    PlatformTextField(
                      controller: _sensorController,
                      label: strings.tKey(
                        PlatformAdminKeys.fieldItemSensorTool,
                      ),
                    ),
                    PlatformTextField(
                      controller: _sortOrderController,
                      label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
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
                      label: strings.tKey(
                        PlatformAdminKeys.badgeSafetyCritical,
                      ),
                      value: _safetyCritical,
                      onChanged: (value) =>
                          setState(() => _safetyCritical = value),
                    ),
                    _SwitchTile(
                      label: strings.tKey(
                        PlatformAdminKeys.fieldItemMultiPoint,
                      ),
                      value: _multiPoint,
                      onChanged: (value) => setState(() => _multiPoint = value),
                    ),
                    _SwitchTile(
                      label: strings.tKey(
                        PlatformAdminKeys.fieldItemAllowFreeText,
                      ),
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
                strings.tKey(PlatformAdminKeys.sectionItemAdvanced),
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
                            key: const Key('item-standard-spec'),
                            controller: _specController,
                            label: strings.tKey(
                              PlatformAdminKeys.fieldItemStandardSpecEn,
                            ),
                          ),
                          PlatformTextField(
                            controller: _maxTyreAgeController,
                            label: strings.tKey(
                              PlatformAdminKeys.fieldItemMaxTyreAge,
                            ),
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

  Widget _buildContentStep(dynamic strings) {
    return Form(
      key: _contentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.tKey(PlatformAdminKeys.helpStepContent),
            style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            key: const Key('item-label'),
            controller: _labelController,
            label: strings.tKey(PlatformAdminKeys.fieldItemLabelEn),
            validator: (value) => _required(value, strings),
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            key: const Key('item-instruction'),
            controller: _instructionController,
            label: strings.tKey(PlatformAdminKeys.fieldItemInstructionEn),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateReview(
    dynamic strings,
    List<PlatformCategory> categories,
  ) {
    var categoryName = _categoryId;
    for (final category in categories) {
      if (category.id == _categoryId) {
        categoryName = category.name;
        if (categoryName.isEmpty) categoryName = category.code;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.tKey(PlatformAdminKeys.helpStepReview),
          style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
        ),
        const SizedBox(height: 12),
        PlatformSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReviewRow(
                label: strings.tKey(PlatformAdminKeys.fieldItemCode),
                value: _codeController.text.trim().isEmpty
                    ? '�'
                    : _codeController.text.trim(),
              ),
              _ReviewRow(
                label: strings.tKey(CommonKeys.labelCategory),
                value: categoryName,
              ),
              _ReviewRow(
                label: strings.tKey(PlatformAdminKeys.fieldItemLabelEn),
                value: _labelController.text.trim().isEmpty
                    ? '—'
                    : _labelController.text.trim(),
              ),
              _ReviewRow(
                label: strings.tKey(PlatformAdminKeys.fieldItemMeasurementUnit),
                value: _unitController.text.trim().isEmpty
                    ? '�'
                    : _unitController.text.trim(),
              ),
              _ReviewRow(
                label: strings.tKey(PlatformAdminKeys.sectionItemIssueFields),
                value: '${_issueFields.length}',
              ),
              _ReviewRow(
                label: strings.tKey(PlatformAdminKeys.sectionItemEvidenceRules),
                value: '${_evidenceRules.length}',
              ),
              _ReviewRow(
                label: strings.tKey(
                  PlatformAdminKeys.sectionItemMeasurementBands,
                ),
                value: '${_bands.length}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(dynamic strings) {
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
                strings.tKey(PlatformAdminKeys.pageMasterLibraryHeading),
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
          strings.tKey(PlatformAdminKeys.pageItemEditorTitle),
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
          strings.tKey(PlatformAdminKeys.buttonItemAdd),
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
    final strings = ref.read(uiStringsProvider);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: strings.tKey(PlatformAdminKeys.buttonItemPublish),
      body:
          '${strings.tKey(PlatformAdminKeys.buttonItemPublish)} · v${draft.versionNo}',
      confirmLabel: strings.tKey(PlatformAdminKeys.buttonItemPublish),
    );
    if (!confirmed) return;
    setState(() => _publishing = true);
    try {
      await ref
          .read(platformConfigActionsProvider)
          .publishItem(widget.itemId, draft.id);
      if (!mounted) return;
      _showSnack(context, strings.tKey(PlatformAdminKeys.toastItemPublished));
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
    final strings = ref.read(uiStringsProvider);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: strings.tKey(PlatformAdminKeys.buttonItemRetire),
      body: strings.tKey(PlatformAdminKeys.dialogRetireConfirm),
      confirmLabel: strings.tKey(PlatformAdminKeys.buttonRetire),
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _retiring = true);
    try {
      await ref.read(platformConfigActionsProvider).retireItem(item.id);
      if (!mounted) return;
      _showSnack(context, strings.tKey(PlatformAdminKeys.toastItemRetired));
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
    final strings = ref.watch(uiStringsProvider);
    final detailAsync = ref.watch(itemDetailProvider(widget.itemId));
    return detailAsync.when(
      loading: () => _EditorShell(
        child: PlatformLoadingView(
          message: strings.tKey(CommonKeys.stateLoading),
        ),
      ),
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
              label: strings.tKey(PlatformAdminKeys.pageMasterLibraryHeading),
              onTap: () => Navigator.of(context).maybePop(),
            ),
            ContextBreadcrumbItem(label: detail.item.code),
          ],
        ),
        child: _buildDetail(strings, detail),
      ),
    );
  }

  Widget _buildDetail(dynamic strings, PlatformItemDetail detail) {
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
        _buildHeader(strings, detail, version),
        const SizedBox(height: 16),
        if (version == null)
          PlatformEmptyView(
            title: strings.tKey(CommonKeys.emptyTitle),
            actionLabel: strings.tKey(CommonKeys.buttonCreateDraft),
            onAction: _creatingDraft ? null : _createDraft,
          )
        else ...[
          if (!editable) _buildImmutableBanner(strings, detail),
          if (!editable) const SizedBox(height: 14),
          _buildStepper(strings, detail, version, editable, optionSets),
        ],
      ],
    );
  }

  Widget _buildHeader(
    dynamic strings,
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
                strings.tKey(PlatformAdminKeys.pageMasterLibraryHeading),
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
                    item.label.isEmpty ? item.code : item.label,
                    style: PtTheme.font(
                      24,
                      lineHeight: 30,
                      weight: FontWeight.w800,
                      color: PtTheme.ink,
                      tracking: -0.4,
                    ),
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
            if (item.status != 'RETIRED')
              PlatformSecondaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonItemRetire),
                icon: Icons.archive_outlined,
                destructive: true,
                onPressed: _retiring ? null : () => _retire(item),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImmutableBanner(dynamic strings, PlatformItemDetail detail) {
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
                  strings.tKey(PlatformAdminKeys.alertVersionImmutable),
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
                label: strings.tKey(CommonKeys.buttonCreateDraft),
                icon: Icons.add_rounded,
                onPressed: _creatingDraft ? null : _createDraft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _stepTitles(dynamic strings) => [
    strings.tKey(PlatformAdminKeys.stepItemBasics),
    strings.tKey(PlatformAdminKeys.stepItemContent),
    strings.tKey(PlatformAdminKeys.stepItemIssueOptions),
    strings.tKey(PlatformAdminKeys.stepItemEvidence),
    strings.tKey(PlatformAdminKeys.stepItemMeasurements),
    strings.tKey(PlatformAdminKeys.stepItemReview),
  ];

  List<String> _stepHelps(dynamic strings) => [
    strings.tKey(PlatformAdminKeys.helpStepBasics),
    strings.tKey(PlatformAdminKeys.helpStepContent),
    strings.tKey(PlatformAdminKeys.helpStepIssueOptions),
    strings.tKey(PlatformAdminKeys.helpStepEvidence),
    strings.tKey(PlatformAdminKeys.helpStepMeasurements),
    strings.tKey(PlatformAdminKeys.helpStepReview),
  ];

  /// Inline per-step validity on persisted state. Content requires saved
  /// Inline per-step validity on persisted state. Content requires a saved
  /// source label; config steps accept the server model as-is (empty lists
  /// and optional fields are valid), so they never block Next.
  bool _stepValid(int step, PlatformItemVersion version) {
    if (step != 1) return true;
    final label = version.label.trim();
    return label.isNotEmpty;
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
    dynamic strings,
    PlatformItemDetail detail,
    PlatformItemVersion version,
    bool editable,
    List<OptionSet> optionSets,
  ) {
    final titles = _stepTitles(strings);
    final helps = _stepHelps(strings);
    final valid = _stepValid(_step, version);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            strings.tArgsKey(PlatformAdminKeys.stepCounter, {
              'current': _step + 1,
              'total': titles.length,
            }),
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
                      label: strings.tKey(CommonKeys.buttonPrevious),
                      onPressed: () => setState(() => _step--),
                    ),
                  if (!isLast)
                    PlatformPrimaryButton(
                      key: const Key('stepper-next'),
                      label: strings.tKey(CommonKeys.buttonNext),
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
                  strings,
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
    dynamic strings,
    PlatformItemDetail detail,
    PlatformItemVersion version,
    bool editable,
    List<OptionSet> optionSets,
  ) {
    final key = ItemVersionKey(widget.itemId, version.id);
    final configAsync = ref.watch(itemConfigProvider(key));
    switch (index) {
      case 0:
        return configAsync.when(
          loading: () => PlatformLoadingView(
            message: strings.tKey(CommonKeys.stateLoading),
          ),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            onRetry: () => ref.invalidate(itemConfigProvider(key)),
          ),
          data: (config) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.helpStepBasics),
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
              strings.tKey(PlatformAdminKeys.helpStepContent),
              style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
            ),
            const SizedBox(height: 12),
            _SourceContentSection(
              label: version.label,
              instruction: version.instruction,
              editable: editable,
              onSave: (label, instruction) => ref
                  .read(platformConfigApiProvider)
                  .updateTranslation(
                    widget.itemId,
                    version.id,
                    'en',
                    label: label,
                    instruction: instruction,
                  ),
            ),
            if (!_stepValid(1, version)) ...[
              const SizedBox(height: 8),
              Text(
                strings.tKey(CommonKeys.validationRequired),
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
          loading: () => PlatformLoadingView(
            message: strings.tKey(CommonKeys.stateLoading),
          ),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            onRetry: () => ref.invalidate(itemConfigProvider(key)),
          ),
          data: (config) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.helpStepIssueOptions),
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
          loading: () => PlatformLoadingView(
            message: strings.tKey(CommonKeys.stateLoading),
          ),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            onRetry: () => ref.invalidate(itemConfigProvider(key)),
          ),
          data: (config) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.helpStepEvidence),
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
          loading: () => PlatformLoadingView(
            message: strings.tKey(CommonKeys.stateLoading),
          ),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            onRetry: () => ref.invalidate(itemConfigProvider(key)),
          ),
          data: (config) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.tKey(PlatformAdminKeys.helpStepMeasurements),
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
        return _buildEditReview(strings, detail);
    }
  }

  Widget _buildEditReview(dynamic strings, PlatformItemDetail detail) {
    final draft = detail.draftVersion;
    if (draft == null) {
      return PlatformEmptyView(
        title: strings.tKey(CommonKeys.emptyTitle),
        actionLabel: strings.tKey(CommonKeys.buttonCreateDraft),
        onAction: _creatingDraft ? null : _createDraft,
      );
    }
    final key = ItemVersionKey(widget.itemId, draft.id);
    final configAsync = ref.watch(itemConfigProvider(key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.tKey(PlatformAdminKeys.helpStepReview),
          style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
        ),
        const SizedBox(height: 12),
        configAsync.when(
          loading: () => PlatformLoadingView(
            message: strings.tKey(CommonKeys.stateLoading),
          ),
          error: (error, _) => PlatformErrorView(
            message: _failureMessage(error),
            retryLabel: strings.tKey(CommonKeys.buttonRetry),
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
                    item.label.isEmpty ? item.code : item.label,
                    style: PtTheme.font(
                      18,
                      lineHeight: 24,
                      weight: FontWeight.w800,
                      color: PtTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ReviewRow(
                    label: strings.tKey(
                      PlatformAdminKeys.fieldItemMeasurementUnit,
                    ),
                    value: config.metadata.measurementUnit.isEmpty
                        ? '�'
                        : config.metadata.measurementUnit,
                  ),
                  _ReviewRow(
                    label: strings.tKey(
                      PlatformAdminKeys.sectionItemIssueFields,
                    ),
                    value: '${config.issueFields.length}',
                  ),
                  _ReviewRow(
                    label: strings.tKey(
                      PlatformAdminKeys.sectionItemEvidenceRules,
                    ),
                    value: '${config.evidenceRules.length}',
                  ),
                  _ReviewRow(
                    label: strings.tKey(
                      PlatformAdminKeys.sectionItemMeasurementBands,
                    ),
                    value: '${config.measurementBands.length}',
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
              label: strings.tKey(PlatformAdminKeys.buttonItemSaveDraft),
              icon: Icons.note_add_outlined,
              onPressed: _creatingDraft ? null : () => _ensureDraft(detail),
            ),
            PlatformSecondaryButton(
              label: strings.tKey(PlatformAdminKeys.textNeedsTranslation),
              icon: Icons.translate_rounded,
              onPressed: () => context.go('/settings/languages'),
            ),
            PlatformPrimaryButton(
              label: strings.tKey(PlatformAdminKeys.buttonPublish),
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

class _BasicsSection extends ConsumerStatefulWidget {
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
  ConsumerState<_BasicsSection> createState() => _BasicsSectionState();
}

class _BasicsSectionState extends ConsumerState<_BasicsSection> {
  late final TextEditingController _unit;
  late final TextEditingController _sensor;
  late final TextEditingController _standardSpec;
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
    _standardSpec = TextEditingController(text: widget.metadata.standardSpec);
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
      _standardSpec.text = widget.metadata.standardSpec;
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
    _standardSpec.dispose();
    _maxTyreAge.dispose();
    _sortOrder.dispose();
    _guideImage.dispose();
    super.dispose();
  }

  Future<void> _save(dynamic strings) async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        ItemMetadata(
          itemId: widget.itemId,
          measurementUnit: _unit.text.trim(),
          sensorTool: _sensor.text.trim(),
          standardSpec: _standardSpec.text.trim(),
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
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.sectionItemBasics),
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
                      controller: _unit,
                      label: strings.tKey(
                        PlatformAdminKeys.fieldItemMeasurementUnit,
                      ),
                      enabled: widget.editable,
                    ),
                    PlatformTextField(
                      controller: _sensor,
                      label: strings.tKey(
                        PlatformAdminKeys.fieldItemSensorTool,
                      ),
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
                strings.tKey(PlatformAdminKeys.sectionItemAdvanced),
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
                            key: const Key('item-standard-spec-edit'),
                            controller: _standardSpec,
                            label: strings.tKey(
                              PlatformAdminKeys.fieldItemStandardSpecEn,
                            ),
                            enabled: widget.editable,
                          ),
                          PlatformTextField(
                            controller: _maxTyreAge,
                            label: strings.tKey(
                              PlatformAdminKeys.fieldItemMaxTyreAge,
                            ),
                            enabled: widget.editable,
                            keyboardType: TextInputType.number,
                          ),
                          PlatformTextField(
                            controller: _sortOrder,
                            label: strings.tKey(
                              PlatformAdminKeys.fieldCategoryOrder,
                            ),
                            enabled: widget.editable,
                            keyboardType: TextInputType.number,
                          ),
                          PlatformTextField(
                            controller: _guideImage,
                            label: strings.tKey(
                              PlatformAdminKeys.sectionItemGuideImage,
                            ),
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
                      label: strings.tKey(
                        PlatformAdminKeys.badgeSafetyCritical,
                      ),
                      value: _safetyCritical,
                      enabled: widget.editable,
                      onChanged: (value) =>
                          setState(() => _safetyCritical = value),
                    ),
                    _SwitchTile(
                      label: strings.tKey(
                        PlatformAdminKeys.fieldItemMultiPoint,
                      ),
                      value: _multiPoint,
                      enabled: widget.editable,
                      onChanged: (value) => setState(() => _multiPoint = value),
                    ),
                    _SwitchTile(
                      label: strings.tKey(
                        PlatformAdminKeys.fieldItemAllowFreeText,
                      ),
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
              label: strings.tKey(CommonKeys.buttonSave),
              isLoading: _saving,
              onPressed: widget.editable && !_saving
                  ? () => _save(strings)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceContentSection extends ConsumerStatefulWidget {
  const _SourceContentSection({
    required this.label,
    required this.instruction,
    required this.editable,
    required this.onSave,
  });

  final String label;
  final String instruction;
  final bool editable;
  final Future<void> Function(String label, String instruction) onSave;

  @override
  ConsumerState<_SourceContentSection> createState() =>
      _SourceContentSectionState();
}

class _SourceContentSectionState extends ConsumerState<_SourceContentSection> {
  late final TextEditingController _label;
  late final TextEditingController _instruction;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.label);
    _instruction = TextEditingController(text: widget.instruction);
  }

  @override
  void didUpdateWidget(covariant _SourceContentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label) _label.text = widget.label;
    if (oldWidget.instruction != widget.instruction) {
      _instruction.text = widget.instruction;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _instruction.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_label.text.trim(), _instruction.text.trim());
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, _failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.stepItemContent),
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            key: const Key('item-edit-label'),
            controller: _label,
            label: strings.tKey(PlatformAdminKeys.fieldItemLabelEn),
            enabled: widget.editable,
          ),
          const SizedBox(height: 12),
          PlatformTextField(
            key: const Key('item-edit-instruction'),
            controller: _instruction,
            label: strings.tKey(PlatformAdminKeys.fieldItemInstructionEn),
            enabled: widget.editable,
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PlatformPrimaryButton(
              label: strings.tKey(CommonKeys.buttonSave),
              isLoading: _saving,
              onPressed: widget.editable && !_saving ? _save : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRulesSection extends ConsumerStatefulWidget {
  const _EvidenceRulesSection({
    required this.rules,
    required this.editable,
    required this.onSave,
  });

  final List<EvidenceRule> rules;
  final bool editable;
  final Future<void> Function(List<EvidenceRule> rules) onSave;

  @override
  ConsumerState<_EvidenceRulesSection> createState() =>
      _EvidenceRulesSectionState();
}

class _EvidenceRulesSectionState extends ConsumerState<_EvidenceRulesSection> {
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
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.sectionItemEvidenceRules),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _forms.length; index++) ...[
            _buildRuleRow(strings, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformSecondaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonItemAdd),
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
                label: strings.tKey(CommonKeys.buttonSave),
                isLoading: _saving,
                onPressed: widget.editable && !_saving ? _save : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow(dynamic strings, int index) {
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
                      label: strings.tKey(CommonKeys.tableStatus),
                      value: form.resultCode,
                      items: [
                        for (final code in _resultCodes)
                          DropdownMenuItem(
                            value: code,
                            child: Text(_resultLabel(strings, code)),
                          ),
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
                tooltip: strings.tKey(CommonKeys.buttonDelete),
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
                      label: strings.tKey(
                        PlatformAdminKeys.fieldEvidenceMinPhotos,
                      ),
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                    PlatformTextField(
                      controller: form.minVideos,
                      label: strings.tKey(
                        PlatformAdminKeys.fieldEvidenceMinVideos,
                      ),
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                    PlatformTextField(
                      controller: form.minNotes,
                      label: strings.tKey(
                        PlatformAdminKeys.fieldEvidenceMinNotes,
                      ),
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                    IgnorePointer(
                      ignoring: !widget.editable,
                      child: Opacity(
                        opacity: widget.editable ? 1 : 0.6,
                        child: PlatformDropdown<String>(
                          label: strings.tKey(
                            PlatformAdminKeys.fieldEvidenceRequiredEvidenceType,
                          ),
                          value:
                              _evidenceTypes.contains(form.requiredEvidenceType)
                              ? form.requiredEvidenceType
                              : '',
                          items: [
                            for (final type in _evidenceTypes)
                              DropdownMenuItem(
                                value: type,
                                child: Text(_evidenceTypeLabel(strings, type)),
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
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.sectionItemIssueFields),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _forms.length; index++) ...[
            _buildFieldRow(strings, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformSecondaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonItemAdd),
                icon: Icons.add_rounded,
                onPressed: widget.editable
                    ? () => setState(
                        () => _forms.add(_IssueFieldForm.empty(_forms.length)),
                      )
                    : null,
              ),
              PlatformPrimaryButton(
                label: strings.tKey(CommonKeys.buttonSave),
                isLoading: _saving,
                onPressed: widget.editable && !_saving ? _save : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(dynamic strings, int index) {
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
                  label: strings.tKey(PlatformAdminKeys.fieldIssueCode),
                  enabled: widget.editable,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: strings.tKey(CommonKeys.buttonDelete),
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
                      key: const Key('issue-field-label'),
                      controller: form.label,
                      label: strings.tKey(PlatformAdminKeys.fieldItemLabelEn),
                      enabled: widget.editable,
                    ),
                    IgnorePointer(
                      ignoring: !widget.editable,
                      child: Opacity(
                        opacity: widget.editable ? 1 : 0.6,
                        child: PlatformDropdown<String>(
                          label: strings.tKey(
                            PlatformAdminKeys.fieldIssueInputType,
                          ),
                          value: form.inputType,
                          items: [
                            for (final type in _inputTypes)
                              DropdownMenuItem(
                                value: type,
                                child: Text(_inputTypeLabel(strings, type)),
                              ),
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
                          label: strings.tKey(
                            PlatformAdminKeys.fieldIssueOptionSet,
                          ),
                          value: form.optionSetCode,
                          items: [
                            const DropdownMenuItem(value: '', child: Text('—')),
                            for (final optionSet in widget.optionSets)
                              DropdownMenuItem(
                                value: optionSet.code,
                                child: Text(_optionSetName(optionSet)),
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
                      label: strings.tKey(PlatformAdminKeys.fieldMeasureMin),
                      enabled: widget.editable,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    PlatformTextField(
                      controller: form.maxValue,
                      label: strings.tKey(PlatformAdminKeys.fieldMeasureMax),
                      enabled: widget.editable,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    PlatformTextField(
                      controller: form.decimalPlaces,
                      label: strings.tKey(
                        PlatformAdminKeys.fieldIssueDecimalPlaces,
                      ),
                      enabled: widget.editable,
                      keyboardType: TextInputType.number,
                    ),
                    PlatformTextField(
                      controller: form.dependsOnFieldCode,
                      label: strings.tKey(
                        PlatformAdminKeys.fieldIssueDependsOn,
                      ),
                      enabled: widget.editable,
                    ),
                    PlatformTextField(
                      controller: form.dependsOnValueCode,
                      label: strings.tKey(
                        PlatformAdminKeys.fieldIssueDependsOnValue,
                      ),
                      enabled: widget.editable,
                    ),
                    PlatformTextField(
                      controller: form.sortOrder,
                      label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
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
              strings.tKey(PlatformAdminKeys.fieldIssueAllowedValues),
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
                        label: _optionValueLabel(value),
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
                label: strings.tKey(CommonKeys.validationRequired),
                value: form.required,
                enabled: widget.editable,
                onChanged: (value) => setState(() => form.required = value),
              ),
              _SwitchTile(
                label: strings.tKey(PlatformAdminKeys.fieldIssueAllowMultiple),
                value: form.allowMultiple,
                enabled: widget.editable,
                onChanged: (value) =>
                    setState(() => form.allowMultiple = value),
              ),
              _SwitchTile(
                label: strings.tKey(PlatformAdminKeys.fieldItemAllowFreeText),
                value: form.allowFreeText,
                enabled: widget.editable,
                onChanged: (value) =>
                    setState(() => form.allowFreeText = value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            strings.tKey(PlatformAdminKeys.fieldIssueRequiredForStatuses),
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
                      label: _resultLabel(strings, status),
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
      label = TextEditingController(text: field.label),
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
      label = TextEditingController(),
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
  final TextEditingController label;
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
    label: label.text.trim(),
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
    label.dispose();
    minValue.dispose();
    maxValue.dispose();
    decimalPlaces.dispose();
    dependsOnFieldCode.dispose();
    dependsOnValueCode.dispose();
    sortOrder.dispose();
  }
}

class _MeasurementBandsSection extends ConsumerStatefulWidget {
  const _MeasurementBandsSection({
    required this.bands,
    required this.editable,
    required this.onSave,
  });

  final List<MeasurementBand> bands;
  final bool editable;
  final Future<void> Function(List<MeasurementBand> bands) onSave;

  @override
  ConsumerState<_MeasurementBandsSection> createState() =>
      _MeasurementBandsSectionState();
}

class _MeasurementBandsSectionState
    extends ConsumerState<_MeasurementBandsSection> {
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
    final strings = ref.watch(uiStringsProvider);
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: strings.tKey(PlatformAdminKeys.sectionItemMeasurementBands),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _forms.length; index++) ...[
            _buildBandRow(strings, index),
            const SizedBox(height: 10),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformSecondaryButton(
                label: strings.tKey(PlatformAdminKeys.buttonItemAdd),
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
                              sortOrder: _forms.length,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              PlatformPrimaryButton(
                label: strings.tKey(CommonKeys.buttonSave),
                isLoading: _saving,
                onPressed: widget.editable && !_saving ? _save : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBandRow(dynamic strings, int index) {
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
                  label: strings.tKey(PlatformAdminKeys.fieldIssueCode),
                  enabled: widget.editable,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: strings.tKey(CommonKeys.buttonDelete),
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
                      label: strings.tKey(
                        PlatformAdminKeys.fieldItemMeasurementUnit,
                      ),
                      enabled: widget.editable,
                    ),
                    IgnorePointer(
                      ignoring: !widget.editable,
                      child: Opacity(
                        opacity: widget.editable ? 1 : 0.6,
                        child: PlatformDropdown<String>(
                          label: strings.tKey(
                            PlatformAdminKeys.fieldMeasureDirection,
                          ),
                          value: form.direction,
                          items: [
                            for (final direction in _directions)
                              DropdownMenuItem(
                                value: direction,
                                child: Text(
                                  _directionLabel(strings, direction),
                                ),
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
                      label: strings.tKey(PlatformAdminKeys.fieldMeasureMin),
                      enabled: widget.editable,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    PlatformTextField(
                      controller: form.maxValue,
                      label: strings.tKey(PlatformAdminKeys.fieldMeasureMax),
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
                          label: strings.tKey(CommonKeys.tableStatus),
                          value: form.resultCode,
                          items: [
                            for (final code in _resultCodes)
                              DropdownMenuItem(
                                value: code,
                                child: Text(_resultLabel(strings, code)),
                              ),
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
                      key: const Key('band-label'),
                      controller: form.label,
                      label: strings.tKey(PlatformAdminKeys.fieldItemLabelEn),
                      enabled: widget.editable,
                    ),
                    PlatformTextField(
                      controller: form.sortOrder,
                      label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
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
      label = TextEditingController(text: band.label),
      sortOrder = TextEditingController(text: band.sortOrder.toString());

  final TextEditingController fieldCode;
  final TextEditingController unitCode;
  String direction;
  final TextEditingController minValue;
  final TextEditingController maxValue;
  String resultCode;
  final TextEditingController label;
  final TextEditingController sortOrder;

  MeasurementBand toBand() => MeasurementBand(
    fieldCode: fieldCode.text.trim(),
    unitCode: unitCode.text.trim(),
    direction: direction,
    minValue: double.tryParse(minValue.text.trim()) ?? 0,
    maxValue: double.tryParse(maxValue.text.trim()) ?? 0,
    resultCode: resultCode,
    label: label.text.trim(),
    sortOrder: int.tryParse(sortOrder.text.trim()) ?? 0,
  );

  void dispose() {
    fieldCode.dispose();
    unitCode.dispose();
    minValue.dispose();
    maxValue.dispose();
    label.dispose();
    sortOrder.dispose();
  }
}

String? _required(String? value, dynamic strings) {
  if (value == null || value.trim().isEmpty) {
    return strings.tKey(CommonKeys.validationRequired);
  }
  return null;
}

String _optionSetName(OptionSet set) {
  return set.name.isEmpty ? set.code : set.name;
}

String _optionValueLabel(OptionValue value) {
  return value.label.isEmpty ? value.code : value.label;
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
