import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/inspection_models.dart';

import '../option_labels.dart';
import 'fieldwork_ui.dart';

/// The item's configured issue fields as chips (select / multi-select /
/// boolean) or fields (number / text). The item screen owns the values,
/// dependencies and validation; this zone only presents them.
class IssueChipsSection extends StatelessWidget {
  const IssueChipsSection({
    required this.item,
    required this.result,
    required this.language,
    required this.fieldErrors,
    required this.showValidation,
    required this.optionValues,
    required this.multiValues,
    required this.controllers,
    required this.dependencySatisfied,
    required this.indexesFor,
    required this.isMulti,
    required this.optionsFor,
    required this.requiredFor,
    required this.missing,
    required this.onOptionChanged,
    required this.onMultiChanged,
    required this.controllerFor,
    required this.booleanLabel,
    super.key,
  });

  final ChecklistItem item;
  final String? result;
  final String language;
  final Map<String, ApiFieldError> fieldErrors;
  final bool showValidation;
  final Map<String, Map<String?, String>> optionValues;
  final Map<String, Map<String?, Set<String>>> multiValues;
  final Map<String, Map<String?, TextEditingController>> controllers;
  final bool Function(IssueField field, String? index) dependencySatisfied;
  final List<String?> Function(IssueField field) indexesFor;
  final bool Function(IssueField field) isMulti;
  final List<IssueOption> Function(IssueField field) optionsFor;
  final bool Function(IssueField field) requiredFor;
  final bool Function(IssueField field, String? index) missing;
  final void Function(IssueField field, String? index, String code)
  onOptionChanged;
  final void Function(
    IssueField field,
    String? index,
    String code,
    bool selected,
  )
  onMultiChanged;
  final TextEditingController Function(IssueField field, String? index)
  controllerFor;
  final String Function(UiStrings t, String code) booleanLabel;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final fields = [...item.issueFields]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final inputs = <Widget>[];
    for (final field in fields) {
      if (field.fieldCode == 'MEASUREMENT' ||
          (field.inputType == 'TEXT' && !field.allowFreeText)) {
        continue;
      }
      for (final index in indexesFor(field)) {
        if (!dependencySatisfied(field, index)) {
          continue;
        }
        inputs.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 12),
            child: _IssueFieldInput(
              field: field,
              index: index,
              language: language,
              required: requiredFor(field),
              selectedOptions: optionValues[field.fieldCode]?[index],
              selectedMulti: multiValues[field.fieldCode]?[index] ?? const {},
              controller: controllerFor(field, index),
              options: optionsFor(field),
              isMulti: isMulti(field),
              booleanLabel: booleanLabel,
              errorText:
                  fieldErrors[field.fieldCode]?.messageFor(language) ??
                  (showValidation && missing(field, index)
                      ? t(TechnicianKeys.technicianIssueFieldRequired)
                      : null),
              onOptionChanged: (code) => onOptionChanged(field, index, code),
              onMultiChanged: (code, selected) =>
                  onMultiChanged(field, index, code, selected),
            ),
          ),
        );
      }
    }
    if (inputs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t(TechnicianKeys.technicianIssueDetails),
          style: fieldworkText(
            context,
            15,
            weight: FontWeight.w800,
            height: 20,
            tracking: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          t(TechnicianKeys.technicianIssueDetailsHint),
          style: fieldworkText(
            context,
            12,
            height: 17,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...inputs,
      ],
    );
  }
}

class _IssueFieldInput extends StatelessWidget {
  const _IssueFieldInput({
    required this.field,
    required this.index,
    required this.language,
    required this.required,
    required this.selectedOptions,
    required this.selectedMulti,
    required this.controller,
    required this.options,
    required this.isMulti,
    required this.booleanLabel,
    required this.errorText,
    required this.onOptionChanged,
    required this.onMultiChanged,
  });

  final IssueField field;
  final String? index;
  final String language;
  final bool required;
  final String? selectedOptions;
  final Set<String> selectedMulti;
  final TextEditingController controller;
  final List<IssueOption> options;
  final bool isMulti;
  final String Function(UiStrings t, String code) booleanLabel;
  final String? errorText;
  final ValueChanged<String> onOptionChanged;
  final void Function(String code, bool selected) onMultiChanged;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final label = index == null
        ? field.labelFor(language)
        : '${field.labelFor(language)} · $index';
    final title = required ? '$label *' : label;
    switch (field.inputType) {
      case 'NUMBER':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: controller,
              label: title,
              labelAbove: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: (field.decimalPlaces ?? 0) > 0,
              ),
              suffixText: field.unitSetCode,
              errorText: errorText,
            ),
            if (field.minValue != null || field.maxValue != null) ...[
              const SizedBox(height: 4),
              Text(
                '${field.minValue ?? ''} – ${field.maxValue ?? ''}'
                '${field.unitSetCode == null ? '' : ' ${field.unitSetCode}'}',
                style: fieldworkText(
                  context,
                  11.5,
                  height: 15,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      case 'TEXT':
        return AppTextField(
          controller: controller,
          label: title,
          labelAbove: true,
          maxLines: 2,
          errorText: errorText,
        );
      case 'BOOLEAN':
      case 'SELECT':
      case 'MULTI_SELECT':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: fieldworkText(
                context,
                12.5,
                weight: FontWeight.w700,
                height: 17,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: context.spacing.xs,
              runSpacing: context.spacing.xs,
              children: [
                for (final option in options)
                  AppFilterChip(
                    label:
                        field.inputType == 'BOOLEAN' &&
                            option.labelEn.isEmpty &&
                            option.labelAr.isEmpty
                        ? booleanLabel(t, option.code)
                        : issueOptionLabel(t, option, language),
                    selected: isMulti
                        ? selectedMulti.contains(option.code)
                        : selectedOptions == option.code,
                    onSelected: (selected) {
                      if (isMulti) {
                        onMultiChanged(option.code, selected);
                      } else {
                        onOptionChanged(selected ? option.code : '');
                      }
                    },
                  ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 6),
              FieldworkNote(
                message: errorText!,
                tone: StatusTone.danger,
                icon: Icons.error_outline_rounded,
              ),
            ],
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
