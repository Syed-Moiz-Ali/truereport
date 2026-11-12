import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_dialogs.dart';
import '../../components/platform_form.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../checklist/checklist_page_frame.dart';
import '../checklist/checklist_tab_bar.dart';

class OptionSetsScreen extends ConsumerStatefulWidget {
  const OptionSetsScreen({super.key});

  @override
  ConsumerState<OptionSetsScreen> createState() => _OptionSetsScreenState();
}

class _OptionSetsScreenState extends ConsumerState<OptionSetsScreen> {
  bool _busy = false;
  String? _selectedSetId;

  late final TextEditingController _setSearchController;
  late final TextEditingController _valueSearchController;

  // In-page set editor: panel replacing the detail panel (no new route).
  bool _editorOpen = false;
  OptionSet? _editorTarget; // null => adding a new set.
  TextEditingController? _editorCode;
  TextEditingController? _editorNameEn;
  TextEditingController? _editorNameAr;
  TextEditingController? _editorOrder;
  GlobalKey<FormState>? _editorFormKey;

  // Inline value editor pinned at the top of the values panel.
  // [_editingValueId] null => add mode; otherwise edit mode for that value.
  String? _editingValueId;
  late final TextEditingController _valueCodeController;
  late final TextEditingController _valueLabelEnController;
  late final TextEditingController _valueLabelArController;
  late final TextEditingController _valueMetadataController;
  final _valueFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _setSearchController = TextEditingController();
    _valueSearchController = TextEditingController();
    _valueCodeController = TextEditingController();
    _valueLabelEnController = TextEditingController();
    _valueLabelArController = TextEditingController();
    _valueMetadataController = TextEditingController();
  }

  @override
  void dispose() {
    _closeEditorControllers();
    _setSearchController.dispose();
    _valueSearchController.dispose();
    _valueCodeController.dispose();
    _valueLabelEnController.dispose();
    _valueLabelArController.dispose();
    _valueMetadataController.dispose();
    super.dispose();
  }

  void _closeEditorControllers() {
    _editorCode?.dispose();
    _editorNameEn?.dispose();
    _editorNameAr?.dispose();
    _editorOrder?.dispose();
    _editorCode = null;
    _editorNameEn = null;
    _editorNameAr = null;
    _editorOrder = null;
    _editorFormKey = null;
  }

  String get _setQuery => _setSearchController.text.trim().toLowerCase();

  String get _valueQuery => _valueSearchController.text.trim().toLowerCase();

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_failureMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
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

  // ------------------------------------------------------------ set editor

  void _openSetEditor(OptionSet? set, {String initialCode = ''}) {
    _closeEditorControllers();
    setState(() {
      _editorOpen = true;
      _editorTarget = set;
      _editorCode = TextEditingController(text: set?.code ?? initialCode);
      _editorNameEn = TextEditingController(text: set?.nameEn ?? '');
      _editorNameAr = TextEditingController(text: set?.nameAr ?? '');
      _editorOrder = TextEditingController(
        text: (set?.sortOrder ?? 0).toString(),
      );
      _editorFormKey = GlobalKey<FormState>();
    });
  }

  void _closeSetEditor() {
    if (!_editorOpen) return;
    setState(() {
      _editorOpen = false;
      _editorTarget = null;
      _closeEditorControllers();
    });
  }

  Future<void> _saveSetEditor() async {
    final formKey = _editorFormKey;
    if (formKey == null || formKey.currentState?.validate() != true) return;
    final isNew = _editorTarget == null;
    final code = _editorCode?.text.trim() ?? '';
    final nameEn = _editorNameEn?.text.trim() ?? '';
    final nameAr = _editorNameAr?.text.trim() ?? '';
    final sortOrder = int.tryParse(_editorOrder?.text.trim() ?? '') ?? 0;
    await _run(() async {
      final actions = ref.read(platformConfigActionsProvider);
      final body = <String, dynamic>{
        'code': code,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'sortOrder': sortOrder,
      };
      if (isNew) {
        final created = await actions.createOptionSet(body);
        if (mounted) {
          setState(() {
            _selectedSetId = created.id;
            _valueSearchController.clear();
            _cancelValueEdit(silent: true);
          });
        }
      } else {
        await actions.updateOptionSet(_editorTarget!.id, body);
      }
      if (mounted) _closeSetEditor();
    });
  }

  Future<void> _confirmRetireSet(OptionSet set) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showPlatformConfirmDialog(
      context: context,
      title: l10n.retire,
      body: l10n.retireConfirm,
      confirmLabel: l10n.retire,
      destructive: true,
    );
    if (confirmed != true) return;
    await _run(() async {
      await ref.read(platformConfigActionsProvider).retireOptionSet(set.id);
      if (mounted) {
        setState(() {
          _selectedSetId = null;
          if (_editorTarget?.id == set.id) {
            _editorOpen = false;
            _editorTarget = null;
            _closeEditorControllers();
          }
        });
      }
    });
  }

  // ---------------------------------------------------------- value editor

  void _startEditValue(OptionValue value) {
    setState(() {
      _editingValueId = value.id;
      _valueCodeController.text = value.code;
      _valueLabelEnController.text = value.labelEn;
      _valueLabelArController.text = value.labelAr;
      _valueMetadataController.text = value.metadataJson;
    });
  }

  void _cancelValueEdit({bool silent = false}) {
    void apply() {
      _editingValueId = null;
      _valueCodeController.clear();
      _valueLabelEnController.clear();
      _valueLabelArController.clear();
      _valueMetadataController.clear();
    }

    if (silent) {
      apply();
    } else {
      setState(apply);
    }
  }

  void _focusValueEditor({String? prefillCode}) {
    setState(() {
      _editingValueId = null;
      if (prefillCode != null && prefillCode.isNotEmpty) {
        _valueCodeController.text = prefillCode;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _valueFormKey.currentContext;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          alignment: 0.1,
        );
      }
    });
  }

  Future<void> _saveValue(OptionSet set) async {
    if (_valueFormKey.currentState?.validate() != true) return;
    final code = _valueCodeController.text.trim();
    final labelEn = _valueLabelEnController.text.trim();
    final labelAr = _valueLabelArController.text.trim();
    final metadata = _valueMetadataController.text.trim();
    final editingId = _editingValueId;
    await _run(() async {
      final actions = ref.read(platformConfigActionsProvider);
      if (editingId == null) {
        var nextOrder = 0;
        for (final value in set.values) {
          if (value.sortOrder >= nextOrder) nextOrder = value.sortOrder + 1;
        }
        await actions.addOptionValue(set.id, <String, dynamic>{
          'code': code,
          'labelEn': labelEn,
          'labelAr': labelAr,
          'sortOrder': nextOrder,
          'metadataJson': metadata,
        });
        if (mounted) {
          setState(() {
            _valueCodeController.clear();
            _valueLabelEnController.clear();
            _valueLabelArController.clear();
            _valueMetadataController.clear();
          });
        }
      } else {
        var sortOrder = 0;
        for (final value in set.values) {
          if (value.id == editingId) sortOrder = value.sortOrder;
        }
        await actions.updateOptionValue(set.id, editingId, <String, dynamic>{
          'labelEn': labelEn,
          'labelAr': labelAr,
          'sortOrder': sortOrder,
          'metadataJson': metadata,
        });
        if (mounted) _cancelValueEdit();
      }
    });
  }

  Future<void> _confirmRetireValue(OptionSet set, OptionValue value) async {
    final l10n = AppLocalizations.of(context);
    final replacementController = TextEditingController();
    String? errorText;
    var submitting = false;
    StateSetter? refreshBody;
    StateSetter? refreshActions;

    void refresh() {
      refreshBody?.call(() {});
      refreshActions?.call(() {});
    }

    final retired = await showPlatformDialog<bool>(
      context: context,
      title: l10n.retire,
      body: StatefulBuilder(
        builder: (context, setState) {
          refreshBody = setState;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.retireConfirm,
                style: PtTheme.font(13, lineHeight: 19, color: PtTheme.muted),
              ),
              const SizedBox(height: 14),
              PlatformTextField(
                key: const Key('opt-value-replacement'),
                controller: replacementController,
                label: l10n.optUsedBy,
                enabled: !submitting,
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(errorText!, style: PtTheme.font(12, color: PtTheme.rose)),
              ],
            ],
          );
        },
      ),
      actionsBuilder: (dialogContext) => [
        StatefulBuilder(
          builder: (context, setState) {
            refreshActions = setState;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
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
                  onPressed: submitting
                      ? null
                      : () async {
                          submitting = true;
                          errorText = null;
                          refresh();
                          try {
                            await ref
                                .read(platformConfigActionsProvider)
                                .retireOptionValue(
                                  set.id,
                                  value.id,
                                  replacementCode:
                                      replacementController.text.trim().isEmpty
                                      ? null
                                      : replacementController.text.trim(),
                                );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } catch (error) {
                            if (!dialogContext.mounted) return;
                            submitting = false;
                            errorText = _failureMessage(error);
                            refresh();
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: PtTheme.rose),
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: PtTheme.white,
                          ),
                        )
                      : Text(
                          l10n.retire,
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
        ),
      ],
    );
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      replacementController.dispose,
    );
    if (retired == true && mounted) {
      if (_editingValueId == value.id) _cancelValueEdit();
      ref.invalidate(optionSetsProvider);
    }
  }

  Future<void> _reorderValue(OptionSet set, String valueId, int delta) async {
    final ordered = [...set.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = ordered.indexWhere((value) => value.id == valueId);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= ordered.length) return;
    final codes = ordered.map((value) => value.code).toList();
    final moved = codes.removeAt(index);
    codes.insert(target, moved);
    await _run(() async {
      await ref
          .read(platformConfigApiProvider)
          .reorderOptionValues(set.id, codes);
      ref.invalidate(optionSetsProvider);
    });
  }

  // -------------------------------------------------------------- selection

  OptionSet? _resolveSelection(List<OptionSet> sets) {
    if (sets.isEmpty) return null;
    if (_selectedSetId != null) {
      for (final set in sets) {
        if (set.id == _selectedSetId) return set;
      }
    }
    return sets.first;
  }

  List<OptionSet> _filteredSets(List<OptionSet> sets) {
    final query = _setQuery;
    if (query.isEmpty) return sets;
    return sets
        .where(
          (set) =>
              set.code.toLowerCase().contains(query) ||
              set.nameEn.toLowerCase().contains(query) ||
              set.nameAr.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  List<OptionValue> _filteredValues(OptionSet set) {
    final query = _valueQuery;
    final ordered = [...set.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (query.isEmpty) return ordered;
    return ordered
        .where(
          (value) =>
              value.code.toLowerCase().contains(query) ||
              value.labelEn.toLowerCase().contains(query) ||
              value.labelAr.toLowerCase().contains(query) ||
              value.metadataJson.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setsAsync = ref.watch(optionSetsProvider);

    return ChecklistPageFrame(
      currentRoute: '/checklist/option-sets',
      currentTab: ChecklistTab.issueOptions,
      showSearch: false,
      actions: [
        PlatformPrimaryButton(
          key: const Key('btn-add-option-set'),
          label: l10n.addOptionSet,
          icon: Icons.add_rounded,
          onPressed: _busy ? null : () => _openSetEditor(null),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HelperBanner(message: l10n.optHelper),
          const SizedBox(height: 16),
          setsAsync.when(
            loading: () =>
                Center(child: PlatformLoadingView(message: l10n.loading)),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: PlatformErrorView(
                  message: _failureMessage(error),
                  retryLabel: l10n.retry,
                  onRetry: () => ref.invalidate(optionSetsProvider),
                ),
              ),
            ),
            data: (sets) {
              final selected = _resolveSelection(sets);
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Master-detail: side-by-side on medium+ widths,
                  // stacked panels on compact widths.
                  final isWide = constraints.maxWidth >= 760;
                  final listPanel = _buildSetsPanel(l10n, sets);
                  // In-page editor panel replaces the detail panel while
                  // open (no new route). Controllers are disposed
                  // synchronously on close, so no exit animation may
                  // outlive them (see D-069 for the dialog variant).
                  final detailPanel = _editorOpen
                      ? _buildSetEditor(l10n)
                      : selected == null
                      ? _buildDetailEmpty(l10n)
                      : _buildSetDetail(l10n, selected);
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: listPanel),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: detailPanel),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      listPanel,
                      const SizedBox(height: 16),
                      detailPanel,
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ list panel

  Widget _buildSetsPanel(AppLocalizations l10n, List<OptionSet> sets) {
    final filtered = _filteredSets(sets);
    final selected = _resolveSelection(sets);
    final countLabel = _setQuery.isEmpty
        ? '${sets.length}'
        : '${filtered.length} / ${sets.length}';
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.optionSetsTab,
                  style: PtTheme.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                countLabel,
                style: PtTheme.font(
                  12,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SearchField(
            key: const Key('opt-set-search'),
            controller: _setSearchController,
            hint: l10n.optSearchSets,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (sets.isEmpty)
            PlatformEmptyView(
              title: l10n.noData,
              actionLabel: l10n.addOptionSet,
              onAction: _busy ? null : () => _openSetEditor(null),
            )
          else if (filtered.isEmpty)
            PlatformEmptyView(
              title: l10n.noResults,
              actionLabel: l10n.addOptionSet,
              onAction: _busy
                  ? null
                  : () => _openSetEditor(
                      null,
                      initialCode: _setSearchController.text.trim(),
                    ),
            )
          else
            for (final set in filtered) ...[
              _buildSetTile(l10n, set, selected?.id == set.id),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildSetTile(AppLocalizations l10n, OptionSet set, bool isSelected) {
    final ordered = [...set.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final preview = ordered.take(3).toList(growable: false);
    final remaining = ordered.length - preview.length;
    return InkWell(
      key: Key('opt-set-tile-${set.id}'),
      onTap: () {
        setState(() {
          if (_editorOpen && _editorTarget != null) _closeSetEditor();
          _selectedSetId = set.id;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: set.code,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? PtTheme.deepGreen.withValues(alpha: 0.08)
                : PtTheme.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? PtTheme.deepGreen.withValues(alpha: 0.35)
                  : PtTheme.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      set.code,
                      style: PtTheme.font(
                        11,
                        weight: FontWeight.w700,
                        color: PtTheme.deepGreen,
                        tracking: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: '${l10n.status}: ${set.status}',
                    child: PlatformStatusChip(status: set.status),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                set.nameEn.isEmpty ? set.code : set.nameEn,
                style: PtTheme.font(
                  14,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (set.nameAr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  set.nameAr,
                  textDirection: TextDirection.rtl,
                  style: PtTheme.font(12, color: PtTheme.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  PlatformMetaPill(
                    label: l10n.optValues,
                    value: '${set.values.length}',
                  ),
                  PlatformMetaPill(label: l10n.status, value: set.status),
                ],
              ),
              // Values preview for unselected sets; the selected set lists
              // its values in the detail panel, so its tile omits the
              // preview to avoid duplicating the same labels.
              if (preview.isNotEmpty && !isSelected) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: PtTheme.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PtTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final value in preview)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                value.code,
                                style: PtTheme.font(
                                  11,
                                  weight: FontWeight.w700,
                                  color: PtTheme.muted,
                                  tracking: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  value.labelEn.isEmpty
                                      ? value.labelAr
                                      : value.labelEn,
                                  style: PtTheme.font(
                                    12,
                                    weight: FontWeight.w600,
                                    color: PtTheme.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (remaining > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+$remaining ${l10n.optValues}',
                            style: PtTheme.font(
                              11,
                              weight: FontWeight.w600,
                              color: PtTheme.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- editor panel

  Widget _buildSetEditor(AppLocalizations l10n) {
    final isNew = _editorTarget == null;
    final formKey = _editorFormKey;
    if (formKey == null) return const SizedBox.shrink();
    return PlatformSectionCard(
      key: const Key('opt-set-editor'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isNew ? l10n.addOptionSet : l10n.edit,
                  style: PtTheme.sectionTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                key: const Key('opt-set-editor-close'),
                tooltip: l10n.close,
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: _busy ? null : _closeSetEditor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlatformTextField(
                  key: const Key('opt-set-code'),
                  controller: _editorCode,
                  label: l10n.categoryCode,
                  enabled: isNew && !_busy,
                  validator: (value) => _required(value, l10n),
                ),
                const SizedBox(height: 12),
                PlatformTextField(
                  key: const Key('opt-set-name-en'),
                  controller: _editorNameEn,
                  label: l10n.categoryNameEn,
                  enabled: !_busy,
                  validator: (value) => _required(value, l10n),
                ),
                const SizedBox(height: 12),
                PlatformTextField(
                  key: const Key('opt-set-name-ar'),
                  controller: _editorNameAr,
                  label: l10n.categoryNameAr,
                  textDirection: TextDirection.rtl,
                  enabled: !_busy,
                  validator: (value) => _required(value, l10n),
                ),
                const SizedBox(height: 12),
                PlatformTextField(
                  key: const Key('opt-set-order'),
                  controller: _editorOrder,
                  label: l10n.categoryOrder,
                  keyboardType: TextInputType.number,
                  enabled: !_busy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              PlatformSecondaryButton(
                label: l10n.cancel,
                onPressed: _busy ? null : _closeSetEditor,
              ),
              PlatformPrimaryButton(
                key: const Key('opt-set-save'),
                label: l10n.save,
                isLoading: _busy,
                onPressed: _busy ? null : _saveSetEditor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailEmpty(AppLocalizations l10n) {
    return PlatformEmptyView(
      key: const Key('opt-detail-empty'),
      title: l10n.noData,
      actionLabel: l10n.addOptionSet,
      onAction: _busy ? null : () => _openSetEditor(null),
    );
  }

  // ---------------------------------------------------------- detail panel

  Widget _buildSetDetail(AppLocalizations l10n, OptionSet set) {
    return Column(
      key: Key('opt-set-detail-${set.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              set.code,
                              style: PtTheme.font(
                                11,
                                weight: FontWeight.w700,
                                color: PtTheme.deepGreen,
                                tracking: 0.4,
                              ),
                            ),
                            PlatformStatusChip(status: set.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          set.nameEn.isEmpty ? set.code : set.nameEn,
                          style: PtTheme.font(
                            18,
                            weight: FontWeight.w700,
                            color: PtTheme.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (set.nameAr.isNotEmpty)
                          Text(
                            set.nameAr,
                            textDirection: TextDirection.rtl,
                            style: PtTheme.font(13, color: PtTheme.muted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PlatformSecondaryButton(
                        key: const Key('opt-set-edit'),
                        label: l10n.edit,
                        icon: Icons.edit_outlined,
                        onPressed: _busy ? null : () => _openSetEditor(set),
                      ),
                      PlatformSecondaryButton(
                        key: const Key('opt-set-retire'),
                        label: l10n.retire,
                        icon: Icons.archive_outlined,
                        destructive: true,
                        onPressed: _busy ? null : () => _confirmRetireSet(set),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildValuesPanel(l10n, set),
      ],
    );
  }

  Widget _buildValuesPanel(AppLocalizations l10n, OptionSet set) {
    final filtered = _filteredValues(set);
    final countLabel = _valueQuery.isEmpty
        ? '${set.values.length}'
        : '${filtered.length} / ${set.values.length}';
    final reorderEnabled = _valueQuery.isEmpty;
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlatformSectionHeader(
            title: l10n.optValues,
            subtitle: l10n.optInlineHint,
            action: Text(
              countLabel,
              style: PtTheme.font(
                12,
                weight: FontWeight.w700,
                color: PtTheme.muted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SearchField(
            key: const Key('opt-value-search'),
            controller: _valueSearchController,
            hint: l10n.optSearchValues,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildValueEditor(l10n, set),
          const SizedBox(height: 12),
          if (set.values.isEmpty)
            PlatformEmptyView(
              title: l10n.noData,
              actionLabel: l10n.optAddValue,
              onAction: () => _focusValueEditor(),
            )
          else if (filtered.isEmpty)
            PlatformEmptyView(
              title: l10n.noResults,
              actionLabel: l10n.optAddValue,
              onAction: () => _focusValueEditor(
                prefillCode: _valueSearchController.text.trim(),
              ),
            )
          else
            for (final value in filtered) ...[
              _buildValueRow(l10n, set, value, reorderEnabled),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildValueEditor(AppLocalizations l10n, OptionSet set) {
    final isEdit = _editingValueId != null;
    return Container(
      key: const Key('opt-value-editor'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Form(
        key: _valueFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEdit ? l10n.edit : l10n.optAddValue,
                    style: PtTheme.font(
                      13,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isEdit) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    key: const Key('opt-value-cancel'),
                    onPressed: _busy ? null : _cancelValueEdit,
                    child: Text(
                      l10n.cancel,
                      style: PtTheme.font(
                        13,
                        weight: FontWeight.w700,
                        color: PtTheme.muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            PlatformTextField(
              key: const Key('opt-value-code'),
              controller: _valueCodeController,
              label: l10n.fieldCode,
              enabled: !isEdit && !_busy,
              validator: (input) => _required(input, l10n),
            ),
            const SizedBox(height: 10),
            PlatformTextField(
              key: const Key('opt-value-label-en'),
              controller: _valueLabelEnController,
              label: l10n.labelEn,
              enabled: !_busy,
              validator: (input) => _required(input, l10n),
            ),
            const SizedBox(height: 10),
            PlatformTextField(
              key: const Key('opt-value-label-ar'),
              controller: _valueLabelArController,
              label: l10n.labelAr,
              textDirection: TextDirection.rtl,
              enabled: !_busy,
              validator: (input) => _required(input, l10n),
            ),
            const SizedBox(height: 10),
            PlatformTextField(
              key: const Key('opt-value-metadata'),
              controller: _valueMetadataController,
              label: l10n.details,
              hint: '{}',
              enabled: !_busy,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PlatformPrimaryButton(
                key: const Key('opt-value-save'),
                label: isEdit ? l10n.save : l10n.optAddValue,
                icon: isEdit ? null : Icons.add_rounded,
                isLoading: _busy,
                onPressed: _busy ? null : () => _saveValue(set),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow(
    AppLocalizations l10n,
    OptionSet set,
    OptionValue value,
    bool reorderEnabled,
  ) {
    final ordered = [...set.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = ordered.indexWhere((item) => item.id == value.id);
    return Container(
      key: Key('opt-value-row-${value.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      value.code,
                      style: PtTheme.font(
                        11,
                        weight: FontWeight.w700,
                        color: PtTheme.muted,
                        tracking: 0.4,
                      ),
                    ),
                    PlatformStatusChip(status: value.status),
                    Text(
                      '${l10n.categoryOrder}: ${value.sortOrder}',
                      style: PtTheme.font(11, color: PtTheme.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _smallIconButton(
                    key: Key('opt-value-up-${value.id}'),
                    tooltip: l10n.moveUp,
                    icon: Icons.arrow_upward_rounded,
                    onPressed: !reorderEnabled || index <= 0
                        ? null
                        : () => _reorderValue(set, value.id, -1),
                  ),
                  _smallIconButton(
                    key: Key('opt-value-down-${value.id}'),
                    tooltip: l10n.moveDown,
                    icon: Icons.arrow_downward_rounded,
                    onPressed:
                        !reorderEnabled ||
                            index < 0 ||
                            index >= ordered.length - 1
                        ? null
                        : () => _reorderValue(set, value.id, 1),
                  ),
                  _smallIconButton(
                    key: Key('opt-value-edit-${value.id}'),
                    tooltip: l10n.edit,
                    icon: Icons.edit_outlined,
                    onPressed: _busy ? null : () => _startEditValue(value),
                  ),
                  _smallIconButton(
                    key: Key('opt-value-retire-${value.id}'),
                    tooltip: l10n.retire,
                    icon: Icons.archive_outlined,
                    color: PtTheme.rose,
                    onPressed: _busy
                        ? null
                        : () => _confirmRetireValue(set, value),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.labelEn,
            style: PtTheme.font(
              13,
              weight: FontWeight.w600,
              color: PtTheme.ink,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (value.labelAr.isNotEmpty)
            Text(
              value.labelAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(12, color: PtTheme.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (value.metadataJson.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              value.metadataJson,
              style: PtTheme.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _smallIconButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    Color color = PtTheme.muted,
  }) {
    return IconButton(
      key: key,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 17,
        color: onPressed == null ? PtTheme.border : color,
      ),
      onPressed: _busy ? null : onPressed,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits (in-file, screen-owned).

class _HelperBanner extends StatelessWidget {
  const _HelperBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: PtTheme.emerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.deepGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: PtTheme.deepGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: PtTheme.bodyMuted,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: PtTheme.font(14, lineHeight: 20, color: PtTheme.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: PtTheme.font(14, lineHeight: 20, color: PtTheme.muted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: PtTheme.muted,
        ),
        filled: true,
        fillColor: PtTheme.canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        constraints: const BoxConstraints(minHeight: 44),
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
      ),
    );
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
