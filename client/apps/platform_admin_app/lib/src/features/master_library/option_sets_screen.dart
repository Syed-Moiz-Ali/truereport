import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_shell.dart';
import '../../platform_config_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';
import '../checklist/catalog/catalog_ui.dart';
import '../checklist/checklist_status.dart';
import 'option_label.dart';

class OptionSetsScreen extends ConsumerStatefulWidget {
  const OptionSetsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<OptionSetsScreen> createState() => _OptionSetsScreenState();
}

class _OptionSetsScreenState extends ConsumerState<OptionSetsScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _selectedId;
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final setsAsync = ref.watch(optionSetsProvider);
    final content = LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1000;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 22, wide ? 24 : 14, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                strings: strings,
                wide: wide,
                onAdd: () => _setDialog(strings),
              ),
              const SizedBox(height: 12),
              CatalogTabs(
                labels: [
                  strings.tKey(PlatformAdminKeys.tabChecklistItems),
                  strings.tKey(PlatformAdminKeys.tabChecklistCategories),
                  strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
                ],
                selected: 2,
                onSelected: (index) {
                  if (index == 0) context.go('/checklist/items');
                  if (index == 1) context.go('/checklist/categories');
                },
              ),
              const SizedBox(height: 10),
              Text(
                strings.tKey(PlatformAdminKeys.pageIssueOptionsHelper),
                style: Catalog.body,
              ),
              const SizedBox(height: 12),
              CatalogSearch(
                controller: _search,
                hint: strings.tKey(PlatformAdminKeys.filterOptionSetsSearch),
                onChanged: (value) =>
                    setState(() => _query = value.toLowerCase()),
              ),
              const SizedBox(height: 12),
              setsAsync.when(
                loading: () => const CatalogSkeleton(),
                error: (_, _) => CatalogError(
                  strings: strings,
                  onRetry: () => ref.invalidate(optionSetsProvider),
                ),
                data: (sets) {
                  final filtered = sets
                      .where(
                        (set) =>
                            _query.isEmpty ||
                            set.name.toLowerCase().contains(_query) ||
                            set.code.toLowerCase().contains(_query),
                      )
                      .toList(growable: false);
                  if (filtered.isEmpty) {
                    return CatalogSurface(
                      child: CatalogEmpty(
                        title: strings.tKey(
                          sets.isEmpty
                              ? CommonKeys.emptyTitle
                              : CommonKeys.emptySearch,
                        ),
                        body: strings.tKey(
                          PlatformAdminKeys.pageIssueOptionsHelper,
                        ),
                        actionLabel: sets.isEmpty
                            ? strings.tKey(PlatformAdminKeys.buttonOptionSetAdd)
                            : null,
                        onAction: sets.isEmpty
                            ? () => _setDialog(strings)
                            : null,
                      ),
                    );
                  }
                  final selected = filtered.firstWhere(
                    (set) => set.id == _selectedId,
                    orElse: () => filtered.first,
                  );
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 340,
                          child: _SetList(
                            strings: strings,
                            sets: filtered,
                            selectedId: selected.id,
                            onSelect: (set) =>
                                setState(() => _selectedId = set.id),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OptionSetValuesPane(
                            strings: strings,
                            set: selected,
                            busy: _busy,
                            onAdd: () => _valueDialog(strings, selected),
                            onEdit: (value) =>
                                _valueDialog(strings, selected, value),
                            onRetire: (value) =>
                                _retireValue(strings, selected, value),
                            onActivate: (value) =>
                                _activateValue(strings, selected, value),
                            onMove: (value, delta) =>
                                _moveValue(strings, selected, value, delta),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _SetList(
                        strings: strings,
                        sets: filtered,
                        selectedId: selected.id,
                        onSelect: (set) => setState(() => _selectedId = set.id),
                      ),
                      const SizedBox(height: 14),
                      OptionSetValuesPane(
                        strings: strings,
                        set: selected,
                        busy: _busy,
                        onAdd: () => _valueDialog(strings, selected),
                        onEdit: (value) =>
                            _valueDialog(strings, selected, value),
                        onRetire: (value) =>
                            _retireValue(strings, selected, value),
                        onActivate: (value) =>
                            _activateValue(strings, selected, value),
                        onMove: (value, delta) =>
                            _moveValue(strings, selected, value, delta),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
    if (widget.embedded) return content;
    return PlatformShell(
      currentRoute: '/checklist/option-sets',
      onNavigate: (route) => context.go(route),
      child: content,
    );
  }

  Future<void> _setDialog(UiMessageStrings strings, [OptionSet? set]) async {
    final code = TextEditingController(text: set?.code ?? '');
    final name = TextEditingController(text: set?.name ?? '');
    final order = TextEditingController(text: '${set?.sortOrder ?? 0}');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CatalogDialog(
        title: strings.tKey(
          set == null
              ? PlatformAdminKeys.buttonOptionSetAdd
              : PlatformAdminKeys.dialogCategoryEditTitle,
        ),
        body: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CatalogField(
                controller: code,
                label: strings.tKey(PlatformAdminKeys.fieldCategoryCode),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
              const SizedBox(height: 12),
              CatalogField(
                controller: name,
                label: strings.tKey(PlatformAdminKeys.fieldCategoryNameEn),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
              const SizedBox(height: 12),
              CatalogField(
                controller: order,
                label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse((value ?? '').trim()) == null
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          CatalogButton(
            label: strings.tKey(CommonKeys.buttonCancel),
            secondary: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CatalogButton(
            label: strings.tKey(CommonKeys.buttonSave),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(dialogContext).pop(true);
            },
          ),
        ],
      ),
    );
    if (saved != true) return;
    try {
      final actions = ref.read(platformConfigActionsProvider);
      final body = <String, dynamic>{
        'code': code.text.trim(),
        'name': name.text.trim(),
        'sortOrder': int.tryParse(order.text.trim()) ?? 0,
        'active': true,
      };
      if (set == null) {
        await actions.createOptionSet(body);
      } else {
        await actions.updateOptionSet(set.id, body);
      }
      ref.invalidate(optionSetsProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    }
  }

  Future<void> _valueDialog(
    UiMessageStrings strings,
    OptionSet set, [
    OptionValue? value,
  ]) async {
    final code = TextEditingController(text: value?.code ?? '');
    final label = TextEditingController(text: value?.labelEn ?? '');
    final description = TextEditingController();
    final order = TextEditingController(
      text: '${value?.sortOrder ?? set.values.length}',
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CatalogDialog(
        title: strings.tKey(
          value == null
              ? PlatformAdminKeys.buttonOptionValueAdd
              : CommonKeys.buttonEdit,
        ),
        body: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CatalogField(
                controller: code,
                label: strings.tKey(PlatformAdminKeys.fieldOptionValueCode),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
              const SizedBox(height: 12),
              CatalogField(
                controller: label,
                label: strings.tKey(PlatformAdminKeys.fieldOptionValueLabel),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
              const SizedBox(height: 12),
              CatalogField(
                controller: description,
                label: strings.tKey(
                  PlatformAdminKeys.fieldOptionValueDescription,
                ),
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              CatalogField(
                controller: order,
                label: strings.tKey(PlatformAdminKeys.fieldCategoryOrder),
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse((v ?? '').trim()) == null
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          CatalogButton(
            label: strings.tKey(CommonKeys.buttonCancel),
            secondary: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CatalogButton(
            label: strings.tKey(CommonKeys.buttonSave),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(dialogContext).pop(true);
            },
          ),
        ],
      ),
    );
    if (saved != true) return;
    try {
      final actions = ref.read(platformConfigActionsProvider);
      final body = <String, dynamic>{
        'code': code.text.trim(),
        'label': label.text.trim(),
        'description': description.text.trim(),
        'sortOrder': int.tryParse(order.text.trim()) ?? 0,
        'active': true,
      };
      if (value == null) {
        await actions.addOptionValue(set.id, body);
      } else {
        await actions.updateOptionValue(set.id, value.id, body);
      }
      ref.invalidate(optionSetsProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    }
  }

  Future<void> _retireValue(
    UiMessageStrings strings,
    OptionSet set,
    OptionValue value,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CatalogDialog(
        title: strings.tKey(PlatformAdminKeys.buttonRetire),
        body: Text(
          strings.tKey(PlatformAdminKeys.dialogRetireConfirm),
          style: Catalog.body,
        ),
        actions: [
          CatalogButton(
            label: strings.tKey(CommonKeys.buttonCancel),
            secondary: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CatalogButton(
            label: strings.tKey(PlatformAdminKeys.buttonRetire),
            danger: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(platformConfigActionsProvider)
          .retireOptionValue(set.id, value.id);
      ref.invalidate(optionSetsProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    }
  }

  Future<void> _activateValue(
    UiMessageStrings strings,
    OptionSet set,
    OptionValue value,
  ) async {
    try {
      await ref.read(platformConfigActionsProvider).updateOptionValue(
        set.id,
        value.id,
        {
          'code': value.code,
          'label': value.labelEn,
          'description': '',
          'sortOrder': value.sortOrder,
          'active': true,
        },
      );
      ref.invalidate(optionSetsProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    }
  }

  Future<void> _moveValue(
    UiMessageStrings strings,
    OptionSet set,
    OptionValue value,
    int delta,
  ) async {
    if (_busy) return;
    final values = [...set.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = values.indexWhere((item) => item.id == value.id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= values.length) return;
    setState(() => _busy = true);
    try {
      final other = values[target];
      final actions = ref.read(platformConfigActionsProvider);
      await actions.updateOptionValue(set.id, value.id, {
        'code': value.code,
        'label': value.labelEn,
        'description': '',
        'sortOrder': other.sortOrder,
        'active': true,
      });
      await actions.updateOptionValue(set.id, other.id, {
        'code': other.code,
        'label': other.labelEn,
        'description': '',
        'sortOrder': value.sortOrder,
        'active': true,
      });
      ref.invalidate(optionSetsProvider);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: PtTheme.rose,
        content: Text(message, style: Catalog.text(12.5, color: PtTheme.white)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.strings,
    required this.wide,
    required this.onAdd,
  });

  final UiMessageStrings strings;
  final bool wide;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final block = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.tKey(PlatformAdminKeys.pageMasterLibraryHeading),
          style: Catalog.eyebrow,
        ),
        const SizedBox(height: 7),
        Text(
          strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
          style: Catalog.pageTitle,
        ),
      ],
    );
    final add = CatalogButton(
      label: strings.tKey(PlatformAdminKeys.buttonOptionSetAdd),
      icon: Icons.add_rounded,
      onPressed: onAdd,
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block,
          const SizedBox(height: 12),
          Align(alignment: AlignmentDirectional.centerStart, child: add),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: block),
        add,
      ],
    );
  }
}

class _SetList extends ConsumerWidget {
  const _SetList({
    required this.strings,
    required this.sets,
    required this.selectedId,
    required this.onSelect,
  });

  final UiMessageStrings strings;
  final List<OptionSet> sets;
  final String selectedId;
  final ValueChanged<OptionSet> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CatalogSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  strings.tKey(PlatformAdminKeys.tabChecklistOptionSets),
                  style: Catalog.eyebrow,
                ),
              ),
              Text(
                '${sets.length}',
                style: Catalog.text(10.5, color: PtTheme.muted),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: PtTheme.border),
        for (final set in sets)
          Material(
            color: set.id == selectedId
                ? Catalog.tint.withValues(alpha: 0.55)
                : Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(set),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: PtTheme.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            set.name,
                            style: Catalog.text(12, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${set.code} · ${set.values.length} ${strings.tKey(PlatformAdminKeys.sectionOptionSetValues)}',
                            style: Catalog.text(9.5, color: PtTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    CatalogPill(
                      label: checklistStatusLabel(ref, set.status),
                      tone: set.status.toUpperCase() == 'ACTIVE'
                          ? CatalogTone.good
                          : CatalogTone.neutral,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class OptionSetValuesPane extends ConsumerWidget {
  const OptionSetValuesPane({
    required this.strings,
    required this.set,
    required this.busy,
    required this.onAdd,
    required this.onEdit,
    required this.onRetire,
    required this.onActivate,
    required this.onMove,
    super.key,
  });

  final UiMessageStrings strings;
  final OptionSet set;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<OptionValue> onEdit;
  final ValueChanged<OptionValue> onRetire;
  final ValueChanged<OptionValue> onActivate;
  final void Function(OptionValue, int) onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final values = [...set.values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return CatalogSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.code,
                      style: Catalog.text(
                        10.5,
                        weight: FontWeight.w800,
                        color: PtTheme.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      set.name,
                      style: Catalog.text(
                        20,
                        weight: FontWeight.w800,
                        tracking: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              CatalogButton(
                label: strings.tKey(PlatformAdminKeys.buttonOptionValueAdd),
                icon: Icons.add_rounded,
                secondary: true,
                compact: true,
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            strings.tKey(PlatformAdminKeys.sectionOptionSetValues),
            style: Catalog.eyebrow,
          ),
          const SizedBox(height: 6),
          if (values.isEmpty)
            CatalogEmpty(
              title: strings.tKey(CommonKeys.emptyTitle),
              body: strings.tKey(PlatformAdminKeys.pageIssueOptionsInlineHint),
              actionLabel: strings.tKey(PlatformAdminKeys.buttonOptionValueAdd),
              onAction: onAdd,
            )
          else
            for (final value in values)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: PtTheme.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            optionValueLabel(t, value),
                            style: Catalog.text(12, weight: FontWeight.w700),
                          ),
                          Text(
                            value.code,
                            style: Catalog.text(9.5, color: PtTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    CatalogPill(
                      label: checklistStatusLabel(ref, value.status),
                      tone: value.status.toUpperCase() == 'ACTIVE'
                          ? CatalogTone.good
                          : CatalogTone.bad,
                    ),
                    _icon(
                      Icons.arrow_upward_rounded,
                      strings.tKey(CommonKeys.buttonMoveUp),
                      () => onMove(value, -1),
                    ),
                    _icon(
                      Icons.arrow_downward_rounded,
                      strings.tKey(CommonKeys.buttonMoveDown),
                      () => onMove(value, 1),
                    ),
                    _icon(
                      Icons.edit_outlined,
                      strings.tKey(CommonKeys.buttonEdit),
                      () => onEdit(value),
                    ),
                    _icon(
                      value.status.toUpperCase() == 'ACTIVE'
                          ? Icons.block_outlined
                          : Icons.check_circle_outlined,
                      strings.tKey(
                        value.status.toUpperCase() == 'ACTIVE'
                            ? PlatformAdminKeys.buttonRetire
                            : PlatformAdminKeys.buttonContentActivate,
                      ),
                      value.status.toUpperCase() == 'ACTIVE'
                          ? () => onRetire(value)
                          : () => onActivate(value),
                      danger: value.status.toUpperCase() == 'ACTIVE',
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _icon(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool danger = false,
  }) => Tooltip(
    message: tooltip,
    child: IconButton(
      icon: Icon(icon, size: 17),
      color: danger ? PtTheme.rose : PtTheme.muted,
      visualDensity: VisualDensity.compact,
      onPressed: busy ? null : onPressed,
    ),
  );
}
