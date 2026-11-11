import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class OptionSetsScreen extends ConsumerStatefulWidget {
  const OptionSetsScreen({super.key});

  @override
  ConsumerState<OptionSetsScreen> createState() => _OptionSetsScreenState();
}

class _OptionSetsScreenState extends ConsumerState<OptionSetsScreen> {
  bool _busy = false;
  String? _selectedSetId;

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

  Future<void> _showSetDialog(OptionSet? set) async {
    final l10n = AppLocalizations.of(context);
    final codeController = TextEditingController(text: set?.code ?? '');
    final nameEnController = TextEditingController(text: set?.nameEn ?? '');
    final nameArController = TextEditingController(text: set?.nameAr ?? '');
    final sortOrderController = TextEditingController(
      text: (set?.sortOrder ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            set == null ? l10n.optionSetsTab : l10n.edit,
            style: PtTheme.font(
              18,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InputField(
                      controller: codeController,
                      label: l10n.categoryCode,
                      enabled: set == null,
                      validator: (value) => _required(value, l10n),
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: nameEnController,
                      label: l10n.categoryNameEn,
                      validator: (value) => _required(value, l10n),
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: nameArController,
                      label: l10n.categoryNameAr,
                      textDirection: TextDirection.rtl,
                      validator: (value) => _required(value, l10n),
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: sortOrderController,
                      label: l10n.categoryOrder,
                      keyboardType: TextInputType.number,
                    ),
                  ],
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
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: PtTheme.deepGreen,
              ),
              child: Text(
                l10n.save,
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

    final code = codeController.text.trim();
    final nameEn = nameEnController.text.trim();
    final nameAr = nameArController.text.trim();
    final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;
    codeController.dispose();
    nameEnController.dispose();
    nameArController.dispose();
    sortOrderController.dispose();

    if (shouldSave != true) return;
    await _run(() async {
      final actions = ref.read(platformConfigActionsProvider);
      final body = <String, dynamic>{
        'code': code,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'sortOrder': sortOrder,
      };
      if (set == null) {
        final created = await actions.createOptionSet(body);
        if (mounted) setState(() => _selectedSetId = created.id);
      } else {
        await actions.updateOptionSet(set.id, body);
      }
    });
  }

  Future<void> _confirmRetireSet(OptionSet set) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.retireCategory,
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
                l10n.retireConfirm,
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
              style: FilledButton.styleFrom(backgroundColor: PtTheme.rose),
              child: Text(
                l10n.retireCategory,
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
    await _run(() async {
      await ref
          .read(platformConfigActionsProvider)
          .retireOptionSet(set.id);
      if (mounted) setState(() => _selectedSetId = null);
    });
  }

  Future<void> _showValueDialog(OptionSet set, OptionValue? value) async {
    final l10n = AppLocalizations.of(context);
    final codeController = TextEditingController(text: value?.code ?? '');
    final labelEnController = TextEditingController(
      text: value?.labelEn ?? '',
    );
    final labelArController = TextEditingController(
      text: value?.labelAr ?? '',
    );
    final sortOrderController = TextEditingController(
      text: (value?.sortOrder ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            value == null ? l10n.addItem : l10n.edit,
            style: PtTheme.font(
              18,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InputField(
                      controller: codeController,
                      label: l10n.fieldCode,
                      validator: (input) => _required(input, l10n),
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: labelEnController,
                      label: l10n.labelEn,
                      validator: (input) => _required(input, l10n),
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: labelArController,
                      label: l10n.labelAr,
                      textDirection: TextDirection.rtl,
                      validator: (input) => _required(input, l10n),
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: sortOrderController,
                      label: l10n.categoryOrder,
                      keyboardType: TextInputType.number,
                    ),
                  ],
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
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: PtTheme.deepGreen,
              ),
              child: Text(
                l10n.save,
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

    final code = codeController.text.trim();
    final labelEn = labelEnController.text.trim();
    final labelAr = labelArController.text.trim();
    final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;
    codeController.dispose();
    labelEnController.dispose();
    labelArController.dispose();
    sortOrderController.dispose();

    if (shouldSave != true) return;
    await _run(() async {
      final actions = ref.read(platformConfigActionsProvider);
      final body = <String, dynamic>{
        'code': code,
        'labelEn': labelEn,
        'labelAr': labelAr,
        'sortOrder': sortOrder,
      };
      if (value == null) {
        await actions.addOptionValue(set.id, body);
      } else {
        await actions.updateOptionValue(set.id, value.id, body);
      }
    });
  }

  Future<void> _confirmRetireValue(OptionSet set, OptionValue value) async {
    final l10n = AppLocalizations.of(context);
    final replacementController = TextEditingController();
    String? errorText;
    var submitting = false;
    final retired = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                l10n.delete,
                style: PtTheme.font(
                  18,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.retireConfirm,
                        style: PtTheme.font(
                          13,
                          lineHeight: 19,
                          color: PtTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        controller: replacementController,
                        label: 'Replacement code',
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText!,
                          style: PtTheme.font(12, color: PtTheme.rose),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
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
                          setDialogState(() {
                            submitting = true;
                            errorText = null;
                          });
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
                            setDialogState(() {
                              submitting = false;
                              errorText = _failureMessage(error);
                            });
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
                          l10n.delete,
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
      },
    );
    replacementController.dispose();
    if (retired == true && mounted) {
      ref.invalidate(optionSetsProvider);
    }
  }

  Future<void> _reorderValue(OptionSet set, int index, int delta) async {
    final ordered = [...set.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final target = index + delta;
    if (target < 0 || target >= ordered.length) return;
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

  OptionSet? _resolveSelection(List<OptionSet> sets) {
    if (sets.isEmpty) return null;
    if (_selectedSetId != null) {
      for (final set in sets) {
        if (set.id == _selectedSetId) return set;
      }
    }
    return sets.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setsAsync = ref.watch(optionSetsProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      appBar: AppBar(
        backgroundColor: PtTheme.white,
        surfaceTintColor: PtTheme.white,
        foregroundColor: PtTheme.ink,
        title: Text(
          l10n.optionSetsTab,
          style: PtTheme.font(
            18,
            weight: FontWeight.w700,
            color: PtTheme.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: TextButton.icon(
              onPressed: _busy ? null : () => _showSetDialog(null),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: PtTheme.deepGreen,
              ),
              label: Text(
                l10n.addItem,
                style: PtTheme.font(
                  13,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
            ),
          ),
        ],
      ),
      body: setsAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  onPressed: () => ref.invalidate(optionSetsProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (sets) {
          final selected = _resolveSelection(sets);
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final horizontalPadding = constraints.maxWidth >= 900
                  ? 32.0
                  : 16.0;
              final listPanel = _buildSetsPanel(l10n, sets, selected);
              final detailPanel = selected == null
                  ? _StatePanel(
                      child: Text(
                        l10n.noData,
                        style: PtTheme.font(
                          14,
                          weight: FontWeight.w600,
                          color: PtTheme.ink,
                        ),
                      ),
                    )
                  : _buildSetDetail(l10n, selected);
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.optionSetsTab,
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
                          l10n.masterLibrarySubtitle,
                          style: PtTheme.font(
                            13,
                            lineHeight: 19,
                            color: PtTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: listPanel),
                              const SizedBox(width: 20),
                              Expanded(flex: 3, child: detailPanel),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              listPanel,
                              const SizedBox(height: 16),
                              detailPanel,
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSetsPanel(
    AppLocalizations l10n,
    List<OptionSet> sets,
    OptionSet? selected,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                l10n.optionSetsTab,
                style: PtTheme.font(
                  15,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              Text(
                '${sets.length}',
                style: PtTheme.font(
                  12,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (sets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  l10n.noData,
                  style: PtTheme.font(13, color: PtTheme.muted),
                ),
              ),
            )
          else
            for (final set in sets) ...[
              _buildSetTile(l10n, set, selected?.id == set.id),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildSetTile(AppLocalizations l10n, OptionSet set, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedSetId = set.id),
      borderRadius: BorderRadius.circular(12),
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
                _StatusChip(status: set.status),
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
            ),
            if (set.nameAr.isNotEmpty)
              Text(
                set.nameAr,
                textDirection: TextDirection.rtl,
                style: PtTheme.font(12, color: PtTheme.muted),
              ),
            const SizedBox(height: 4),
            Text(
              '${set.values.length}',
              style: PtTheme.font(11, color: PtTheme.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetDetail(AppLocalizations l10n, OptionSet set) {
    final ordered = [...set.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
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
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 6,
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
                        _StatusChip(status: set.status),
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
                    ),
                    if (set.nameAr.isNotEmpty)
                      Text(
                        set.nameAr,
                        textDirection: TextDirection.rtl,
                        style: PtTheme.font(13, color: PtTheme.muted),
                      ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _showSetDialog(set),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: PtTheme.deepGreen,
                    ),
                    label: Text(
                      l10n.edit,
                      style: PtTheme.font(
                        12,
                        weight: FontWeight.w700,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                    style: _outlinedButtonStyle(),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _confirmRetireSet(set),
                    icon: const Icon(
                      Icons.archive_outlined,
                      size: 15,
                      color: PtTheme.rose,
                    ),
                    label: Text(
                      l10n.retireCategory,
                      style: PtTheme.font(
                        12,
                        weight: FontWeight.w700,
                        color: PtTheme.rose,
                      ),
                    ),
                    style: _outlinedButtonStyle(),
                  ),
                  ElevatedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _showValueDialog(set, null),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      l10n.addItem,
                      style: PtTheme.font(
                        12,
                        weight: FontWeight.w700,
                        color: PtTheme.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PtTheme.deepGreen,
                      foregroundColor: PtTheme.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ordered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  l10n.noData,
                  style: PtTheme.font(13, color: PtTheme.muted),
                ),
              ),
            )
          else
            for (var index = 0; index < ordered.length; index++) ...[
              _buildValueRow(l10n, set, ordered, index),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildValueRow(
    AppLocalizations l10n,
    OptionSet set,
    List<OptionValue> ordered,
    int index,
  ) {
    final value = ordered[index];
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
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
                  _StatusChip(status: value.status),
                  Text(
                    '${l10n.categoryOrder}: ${value.sortOrder}',
                    style: PtTheme.font(11, color: PtTheme.muted),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _smallIconButton(
                    Icons.arrow_upward_rounded,
                    onPressed: index == 0
                        ? null
                        : () => _reorderValue(set, index, -1),
                  ),
                  _smallIconButton(
                    Icons.arrow_downward_rounded,
                    onPressed: index == ordered.length - 1
                        ? null
                        : () => _reorderValue(set, index, 1),
                  ),
                  _smallIconButton(
                    Icons.edit_outlined,
                    onPressed: _busy
                        ? null
                        : () => _showValueDialog(set, value),
                  ),
                  _smallIconButton(
                    Icons.archive_outlined,
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
          ),
          if (value.labelAr.isNotEmpty)
            Text(
              value.labelAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
        ],
      ),
    );
  }

  Widget _smallIconButton(
    IconData icon, {
    required VoidCallback? onPressed,
    Color color = PtTheme.muted,
  }) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 17,
        color: onPressed == null ? PtTheme.border : color,
      ),
      onPressed: _busy ? null : onPressed,
    );
  }

  ButtonStyle _outlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: PtTheme.border, width: 1.4),
      backgroundColor: PtTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9999),
      ),
    );
  }

  BoxDecoration _surfaceDecoration() {
    return BoxDecoration(
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

String _failureMessage(Object error) {
  if (error is AppFailure) {
    return error.statusCode == null
        ? error.messageKey
        : '${error.messageKey} (${error.statusCode})';
  }
  return error.toString();
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.textDirection,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textDirection: textDirection,
      enabled: enabled,
      style: PtTheme.font(14, color: PtTheme.ink),
      decoration: _inputDecoration(label),
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
