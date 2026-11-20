import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:reference_data/reference_data.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../platform_theme.dart';

import 'reference_failures.dart';

const List<String> referenceTones = <String>[
  'neutral',
  'info',
  'success',
  'warning',
  'danger',
];

const List<String> referenceClients = <String>['workshop_admin', 'technician'];

/// Create/edit dialog shared by statuses and enums.
///
/// Saves through [ReferenceAdminActions]: create returns a DRAFT, update keeps
/// the lifecycle state. The dialog stays open and shows the catalog-mapped
/// error when the server rejects the write (403/409/422).
Future<ReferenceRecord?> showReferenceRecordForm({
  required BuildContext context,
  required UiMessageStrings strings,
  required ReferenceAdminActions actions,
  required String domain,
  required bool isEnum,
  ReferenceRecord? record,
  required int nextOrder,
}) {
  return showDialog<ReferenceRecord>(
    context: context,
    builder: (dialogContext) => _ReferenceRecordDialog(
      strings: strings,
      actions: actions,
      domain: domain,
      isEnum: isEnum,
      record: record,
      nextOrder: nextOrder,
    ),
  );
}

class _ReferenceRecordDialog extends StatefulWidget {
  const _ReferenceRecordDialog({
    required this.strings,
    required this.actions,
    required this.domain,
    required this.isEnum,
    required this.record,
    required this.nextOrder,
  });

  final UiMessageStrings strings;
  final ReferenceAdminActions actions;
  final String domain;
  final bool isEnum;
  final ReferenceRecord? record;
  final int nextOrder;

  @override
  State<_ReferenceRecordDialog> createState() => _ReferenceRecordDialogState();
}

class _ReferenceRecordDialogState extends State<_ReferenceRecordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _labelKey;
  late final TextEditingController _order;
  late String _tone;
  late bool _selectable;
  late Set<String> _clients;
  bool _saving = false;
  String? _error;

  bool get _isCreate => widget.record == null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _code = TextEditingController(text: record?.code ?? '');
    _labelKey = TextEditingController(text: record?.labelKey ?? '');
    _order = TextEditingController(
      text: '${record?.order ?? widget.nextOrder}',
    );
    _tone = referenceTones.contains(record?.tone)
        ? record!.tone
        : referenceTones.first;
    _selectable = record?.selectable ?? true;
    _clients = record == null
        ? <String>{...referenceClients}
        : <String>{
            for (final client in record.visibleFor)
              if (referenceClients.contains(client)) client,
          };
  }

  @override
  void dispose() {
    _code.dispose();
    _labelKey.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final write = ReferenceWrite(
      code: _code.text.trim(),
      labelKey: _labelKey.text.trim(),
      tone: _tone,
      icon: (widget.record?.icon ?? '').isEmpty
          ? 'circle'
          : widget.record!.icon,
      order: int.parse(_order.text.trim()),
      selectable: _selectable,
      visibleFor: <String>['platform_admin', ..._clients],
      allowedNext: widget.record?.allowedNext ?? const <String>[],
    );
    try {
      final record = widget.record;
      final saved = record == null
          ? (widget.isEnum
                ? await widget.actions.createEnum(widget.domain, write)
                : await widget.actions.createStatus(widget.domain, write))
          : (widget.isEnum
                ? await widget.actions.updateEnum(
                    widget.domain,
                    record.code,
                    write,
                  )
                : await widget.actions.updateStatus(
                    widget.domain,
                    record.code,
                    write,
                  ));
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = referenceErrorText(widget.strings, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final title = widget.isEnum
        ? strings.tKey(
            _isCreate
                ? PlatformAdminKeys.referenceCreateEnumTitle
                : PlatformAdminKeys.referenceEditEnumTitle,
          )
        : strings.tKey(
            _isCreate
                ? PlatformAdminKeys.referenceCreateStatusTitle
                : PlatformAdminKeys.referenceEditStatusTitle,
          );
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: PlatformDialogShell(
        title: title,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PlatformTextField(
                key: const Key('reference-form-code'),
                controller: _code,
                label: strings.tKey(PlatformAdminKeys.taxonomyCode),
                hint: strings.tKey(PlatformAdminKeys.referenceCodeHint),
                helperText: _isCreate
                    ? strings.tKey(PlatformAdminKeys.referenceCodeHelper)
                    : null,
                enabled: _isCreate,
                validator: (value) {
                  final code = value?.trim() ?? '';
                  if (code.isEmpty) {
                    return strings.tKey(CommonKeys.validationRequiredField);
                  }
                  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$')
                      .hasMatch(code)) {
                    return strings.tKey(
                      PlatformAdminKeys.referenceErrorCodeInvalid,
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                key: const Key('reference-form-label-key'),
                controller: _labelKey,
                label: strings.tKey(PlatformAdminKeys.taxonomyLabelKey),
                helperText: strings.tKey(
                  PlatformAdminKeys.referenceLabelKeyHelper,
                ),
                validator: (value) {
                  final labelKey = value?.trim() ?? '';
                  if (labelKey.isEmpty) {
                    return strings.tKey(CommonKeys.validationRequiredField);
                  }
                  if (RegExp(r'\s').hasMatch(labelKey)) {
                    return strings.tKey(
                      PlatformAdminKeys.referenceErrorLabelKeyFormat,
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              PlatformDropdown<String>(
                key: const Key('reference-form-tone'),
                label: strings.tKey(PlatformAdminKeys.taxonomyTone),
                value: _tone,
                items: <DropdownMenuItem<String>>[
                  for (final tone in referenceTones)
                    DropdownMenuItem<String>(
                      value: tone,
                      child: Text(_toneLabel(strings, tone)),
                    ),
                ],
                onChanged: _saving
                    ? (_) {}
                    : (value) {
                        if (value != null) setState(() => _tone = value);
                      },
              ),
              const SizedBox(height: 12),
              PlatformTextField(
                key: const Key('reference-form-order'),
                controller: _order,
                label: strings.tKey(PlatformAdminKeys.taxonomyOrder),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final order = int.tryParse(value?.trim() ?? '');
                  if (order == null || order < 0) {
                    return strings.tKey(
                      PlatformAdminKeys.referenceErrorOrderInvalid,
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                key: const Key('reference-form-selectable'),
                value: _selectable,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _selectable = value),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  strings.tKey(PlatformAdminKeys.taxonomySelectable),
                  style: PtTheme.font(13, weight: FontWeight.w600),
                ),
                subtitle: Text(
                  strings.tKey(PlatformAdminKeys.referenceSelectableHelper),
                  style: PtTheme.caption,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.tKey(PlatformAdminKeys.taxonomyVisibility),
                style: PtTheme.font(
                  12,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.tKey(PlatformAdminKeys.referenceVisibleForHelper),
                style: PtTheme.caption,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  PlatformMetadataChip(
                    label: strings.tKey(CommonKeys.rolePlatformAdmin),
                    icon: Icons.lock_outline_rounded,
                  ),
                  for (final client in referenceClients)
                    PlatformFilterChip(
                      key: Key('reference-form-client-$client'),
                      label: strings.tKey(_clientLabelKey(client)),
                      selected: _clients.contains(client),
                      onTap: _saving
                          ? () {}
                          : () => setState(() {
                              if (!_clients.remove(client)) {
                                _clients.add(client);
                              }
                            }),
                    ),
                ],
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  key: const Key('reference-form-error'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PtTheme.rose.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: PtTheme.rose.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: PtTheme.font(12.5, color: PtTheme.rose),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          PlatformSecondaryButton(
            label: strings.tKey(CommonKeys.buttonCancel),
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
          PlatformPrimaryButton(
            key: const Key('reference-form-save'),
            label: strings.tKey(CommonKeys.buttonSave),
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

String _toneLabel(UiMessageStrings strings, String tone) {
  switch (tone) {
    case 'info':
      return strings.tKey(PlatformAdminKeys.referenceToneInfo);
    case 'success':
      return strings.tKey(PlatformAdminKeys.referenceToneSuccess);
    case 'warning':
      return strings.tKey(PlatformAdminKeys.referenceToneWarning);
    case 'danger':
      return strings.tKey(PlatformAdminKeys.referenceToneDanger);
    default:
      return strings.tKey(PlatformAdminKeys.referenceToneNeutral);
  }
}

UiMessageKey _clientLabelKey(String client) => client == 'workshop_admin'
    ? CommonKeys.roleWorkshopAdmin
    : CommonKeys.roleTechnician;
