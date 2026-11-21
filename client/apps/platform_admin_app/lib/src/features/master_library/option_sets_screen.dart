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

/// The three taxonomy families served by the merged option-set catalogue.
enum OptionSetTab {
  checklist(
    'checklist',
    PlatformAdminKeys.tabOptionSetsChecklist,
    PlatformAdminKeys.optionSetsChecklistHelper,
    PlatformAdminKeys.filterOptionSetsSearchChecklist,
    PlatformAdminKeys.optionSetsListChecklist,
    PlatformAdminKeys.optionSetsEmptyChecklist,
    Icons.checklist_rounded,
  ),
  statuses(
    'statuses',
    PlatformAdminKeys.tabOptionSetsStatuses,
    PlatformAdminKeys.optionSetsStatusesHelper,
    PlatformAdminKeys.filterOptionSetsSearchStatuses,
    PlatformAdminKeys.optionSetsListStatuses,
    PlatformAdminKeys.optionSetsEmptyStatuses,
    Icons.timeline_rounded,
  ),
  enums(
    'enums',
    PlatformAdminKeys.tabOptionSetsEnums,
    PlatformAdminKeys.optionSetsEnumsHelper,
    PlatformAdminKeys.filterOptionSetsSearchEnums,
    PlatformAdminKeys.optionSetsListEnums,
    PlatformAdminKeys.optionSetsEmptyEnums,
    Icons.data_object_rounded,
  );

  const OptionSetTab(
    this.slug,
    this.labelKey,
    this.helperKey,
    this.searchKey,
    this.sectionKey,
    this.emptyKey,
    this.icon,
  );

  final String slug;
  final UiMessageKey labelKey;
  final UiMessageKey helperKey;
  final UiMessageKey searchKey;
  final UiMessageKey sectionKey;
  final UiMessageKey emptyKey;
  final IconData icon;

  /// Deep link for this tab. Checklist stays on the canonical route.
  String get location => this == OptionSetTab.checklist
      ? '/checklist/option-sets'
      : '/checklist/option-sets?tab=$slug';

  static OptionSetTab fromSlug(String? slug) {
    final normalized = (slug ?? '').trim().toLowerCase();
    for (final tab in values) {
      if (tab.slug == normalized) return tab;
    }
    return OptionSetTab.checklist;
  }
}

/// Sets shown for one tab, ordered the way the backend serves them.
List<OptionSet> optionSetsForTab(Iterable<OptionSet> sets, OptionSetTab tab) {
  final filtered = <OptionSet>[
    for (final set in sets)
      if (switch (tab) {
        OptionSetTab.checklist => set.isChecklistCatalog,
        OptionSetTab.statuses => set.isStatusCatalog,
        OptionSetTab.enums => set.isEnumCatalog,
      })
        set,
  ];
  filtered.sort((a, b) {
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    if (byOrder != 0) return byOrder;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return filtered;
}

/// Within-tab search across set identity and its values.
List<OptionSet> searchOptionSets(Iterable<OptionSet> sets, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return sets.toList(growable: false);
  bool has(String value) => value.toLowerCase().contains(needle);
  return <OptionSet>[
    for (final set in sets)
      if (has(set.name) ||
          has(set.code) ||
          has(set.domainKey) ||
          set.values.any((value) => has(value.code) || has(value.labelEn)))
        set,
  ];
}

class OptionSetsScreen extends ConsumerStatefulWidget {
  const OptionSetsScreen({super.key, this.embedded = false, this.initialTab});

  final bool embedded;
  final String? initialTab;

  @override
  ConsumerState<OptionSetsScreen> createState() => _OptionSetsScreenState();
}

class _OptionSetsScreenState extends ConsumerState<OptionSetsScreen> {
  final _search = TextEditingController();
  final _paneKey = GlobalKey();
  final Map<OptionSetTab, String> _selectedByTab = <OptionSetTab, String>{};
  String _query = '';
  late OptionSetTab _tab;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tab = OptionSetTab.fromSlug(widget.initialTab);
  }

  @override
  void didUpdateWidget(covariant OptionSetsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final next = OptionSetTab.fromSlug(widget.initialTab);
      if (next != _tab) {
        _tab = next;
        _clearSearch();
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _query = '';
    _search.clear();
  }

  void _selectTab(OptionSetTab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _clearSearch();
    });
    final router = GoRouter.maybeOf(context);
    router?.go(tab.location);
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
              _Header(strings: strings, wide: wide, tab: _tab),
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
              const SizedBox(height: 14),
              _KindTabs(
                strings: strings,
                selected: _tab,
                counts: setsAsync.asData == null
                    ? null
                    : <OptionSetTab, int>{
                        for (final tab in OptionSetTab.values)
                          tab: optionSetsForTab(
                            setsAsync.requireValue,
                            tab,
                          ).length,
                      },
                onSelected: _selectTab,
              ),
              const SizedBox(height: 12),
              CatalogSearch(
                controller: _search,
                hint: strings.tKey(_tab.searchKey),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              setsAsync.when(
                loading: () => _ResultsSkeleton(wide: wide),
                error: (_, _) => CatalogError(
                  strings: strings,
                  onRetry: () => ref.invalidate(optionSetsProvider),
                ),
                data: (sets) {
                  final tabSets = optionSetsForTab(sets, _tab);
                  final filtered = searchOptionSets(tabSets, _query);
                  return _results(
                    strings: strings,
                    wide: wide,
                    filtered: filtered,
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

  Widget _results({
    required UiMessageStrings strings,
    required bool wide,
    required List<OptionSet> filtered,
  }) {
    if (filtered.isEmpty) {
      return CatalogSurface(
        child: CatalogEmpty(
          title: strings.tKey(
            _query.isNotEmpty ? CommonKeys.emptySearch : _tab.emptyKey,
          ),
          body: strings.tKey(_tab.helperKey),
        ),
      );
    }
    final preferredId = _selectedByTab[_tab];
    final selected = filtered.firstWhere(
      (set) => set.id == preferredId,
      orElse: () => filtered.first,
    );
    void select(OptionSet set) {
      setState(() => _selectedByTab[_tab] = set.id);
      if (wide) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _paneKey.currentContext;
        if (context == null) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 240),
          alignment: 0.05,
        );
      });
    }

    final list = _SetList(
      strings: strings,
      tab: _tab,
      sets: filtered,
      selectedId: selected.id,
      onSelect: select,
    );
    final pane = OptionSetValuesPane(
      strings: strings,
      set: selected,
      busy: _busy,
      canAdd: selected.isChecklistCatalog,
      canRetire: selected.isChecklistCatalog,
      showBackendDefined: selected.codeLocked,
      onAdd: () => _valueDialog(strings, selected),
      onEdit: (value) => _valueDialog(strings, selected, value),
      onRetire: (value) => _retireValue(strings, selected, value),
      onActivate: (value) => _activateValue(strings, selected, value),
      onMove: (value, delta) => _moveValue(strings, selected, value, delta),
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 340, child: list),
          const SizedBox(width: 16),
          Expanded(child: pane),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        list,
        const SizedBox(height: 14),
        KeyedSubtree(key: _paneKey, child: pane),
      ],
    );
  }

  Future<void> _valueDialog(
    UiMessageStrings strings,
    OptionSet set, [
    OptionValue? value,
  ]) async {
    final editing = value != null;
    final codeLocked = set.codeLocked || editing;
    final code = TextEditingController(text: value?.code ?? '');
    final label = TextEditingController(text: value?.labelEn ?? '');
    final description = TextEditingController();
    final order = TextEditingController(
      text: '${value?.sortOrder ?? set.effectiveValuesCount}',
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
                key: const Key('option-value-code-field'),
                controller: code,
                label: strings.tKey(PlatformAdminKeys.fieldOptionValueCode),
                enabled: !codeLocked,
                helper: codeLocked
                    ? strings.tKey(PlatformAdminKeys.optionSetsCodeImmutable)
                    : null,
                validator: (v) => (v ?? '').trim().isEmpty
                    ? strings.tKey(CommonKeys.validationRequiredField)
                    : null,
              ),
              const SizedBox(height: 12),
              CatalogField(
                key: const Key('option-value-label-field'),
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
                key: const Key('option-value-order-field'),
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
            key: const Key('option-value-save'),
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
        'active': value == null ? true : value.status.toUpperCase() == 'ACTIVE',
        if (value?.labelKey != null) 'labelKey': value!.labelKey,
        if (value != null && value.translations.isNotEmpty)
          'translations': value.translations,
      };
      if (value == null) {
        await actions.addOptionValue(set.id, body);
      } else {
        await actions.updateOptionValue(set.id, value.id, body);
      }
      _reload(set.id);
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
      _reload(set.id);
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
          if (value.labelKey != null) 'labelKey': value.labelKey,
          if (value.translations.isNotEmpty) 'translations': value.translations,
        },
      );
      _reload(set.id);
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
    var values = [...set.values];
    if (values.isEmpty && set.valuesCount > 0) {
      try {
        values = [...await ref.read(optionSetValuesProvider(set.id).future)];
      } catch (_) {
        if (mounted) _toast(strings.tKey(CommonKeys.stateError));
        return;
      }
    }
    values.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (values.isEmpty) return;
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
        'active': value.status.toUpperCase() == 'ACTIVE',
        if (value.labelKey != null) 'labelKey': value.labelKey,
        if (value.translations.isNotEmpty) 'translations': value.translations,
      });
      await actions.updateOptionValue(set.id, other.id, {
        'code': other.code,
        'label': other.labelEn,
        'description': '',
        'sortOrder': value.sortOrder,
        'active': other.status.toUpperCase() == 'ACTIVE',
        if (other.labelKey != null) 'labelKey': other.labelKey,
        if (other.translations.isNotEmpty) 'translations': other.translations,
      });
      _reload(set.id);
    } catch (_) {
      if (mounted) _toast(strings.tKey(CommonKeys.stateError));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reload(String setId) {
    ref.invalidate(optionSetsProvider);
    ref.invalidate(optionSetValuesProvider(setId));
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
  const _Header({required this.strings, required this.wide, required this.tab});

  final UiMessageStrings strings;
  final bool wide;
  final OptionSetTab tab;

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
        const SizedBox(height: 8),
        Text(strings.tKey(tab.helperKey), style: Catalog.body),
      ],
    );
    final transitions = tab == OptionSetTab.statuses
        ? CatalogButton(
            key: const Key('option-sets-open-transitions'),
            label: strings.tKey(PlatformAdminKeys.optionSetsTransitionsAction),
            icon: Icons.swap_horiz_rounded,
            secondary: true,
            compact: true,
            onPressed: () => context.go('/configuration/transitions'),
          )
        : null;
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block,
          if (transitions != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: transitions,
            ),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: block),
        ?transitions,
      ],
    );
  }
}

class _KindTabs extends StatelessWidget {
  const _KindTabs({
    required this.strings,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final UiMessageStrings strings;
  final OptionSetTab selected;
  final Map<OptionSetTab, int>? counts;
  final ValueChanged<OptionSetTab> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: PtTheme.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: PtTheme.border),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final tabs = <Widget>[
          for (final tab in OptionSetTab.values)
            _KindTabButton(
              tab: tab,
              label: strings.tKey(tab.labelKey),
              count: counts?[tab],
              selected: tab == selected,
              onTap: () => onSelected(tab),
            ),
        ];
        if (constraints.maxWidth < 520) {
          return Wrap(spacing: 2, runSpacing: 2, children: tabs);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisSize: MainAxisSize.min, children: tabs),
        );
      },
    ),
  );
}

class _KindTabButton extends StatelessWidget {
  const _KindTabButton({
    required this.tab,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final OptionSetTab tab;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('option-sets-tab-${tab.slug}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: Catalog.fast,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Catalog.tint : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 17,
                color: selected ? PtTheme.deepGreen : PtTheme.muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Catalog.text(
                  12.5,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? PtTheme.ink : PtTheme.muted,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? PtTheme.white : Catalog.neutralTint,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? PtTheme.deepGreen.withValues(alpha: 0.24)
                          : PtTheme.border,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: Catalog.text(
                      10.5,
                      weight: FontWeight.w800,
                      tabular: true,
                      color: selected ? PtTheme.deepGreen : PtTheme.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Loading skeleton shaped like the final master-detail layout.
class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final list = CatalogSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            child: _bone(width: 110, height: 10),
          ),
          const Divider(height: 1, color: PtTheme.border),
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bone(width: 150, height: 11),
                  const SizedBox(height: 8),
                  _bone(width: 90, height: 8),
                ],
              ),
            ),
        ],
      ),
    );
    final pane = CatalogSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bone(width: 80, height: 9),
          const SizedBox(height: 8),
          _bone(width: 190, height: 18),
          const SizedBox(height: 18),
          _bone(width: 60, height: 8),
          const SizedBox(height: 12),
          for (var i = 0; i < 5; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bone(width: 140, height: 11),
                      const SizedBox(height: 7),
                      _bone(width: 80, height: 8),
                    ],
                  ),
                ),
                _bone(width: 64, height: 20),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [list, const SizedBox(height: 14), pane],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 340, child: list),
        const SizedBox(width: 16),
        Expanded(child: pane),
      ],
    );
  }

  Widget _bone({required double width, required double height}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: PtTheme.border.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class _SetList extends ConsumerWidget {
  const _SetList({
    required this.strings,
    required this.tab,
    required this.sets,
    required this.selectedId,
    required this.onSelect,
  });

  final UiMessageStrings strings;
  final OptionSetTab tab;
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
                  strings.tKey(tab.sectionKey),
                  style: Catalog.eyebrow,
                ),
              ),
              Text(
                '${sets.length}',
                style: Catalog.text(
                  10.5,
                  weight: FontWeight.w700,
                  tabular: true,
                  color: PtTheme.muted,
                ),
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
              key: Key('option-set-row-${set.code}'),
              onTap: () => onSelect(set),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
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
                          const SizedBox(height: 3),
                          Text(
                            '${set.code} · '
                            '${strings.tArgsKey(PlatformAdminKeys.checklistOptionSetsValueCount, {'count': '${set.effectiveValuesCount}'})}',
                            style: Catalog.text(9.5, color: PtTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    if (set.codeLocked)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: Tooltip(
                          message: strings.tKey(
                            PlatformAdminKeys.optionSetsBackendDefinedHelper,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: PtTheme.muted,
                          ),
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
    this.canAdd = true,
    this.canRetire = true,
    this.showBackendDefined = false,
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
  final bool canAdd;
  final bool canRetire;
  final bool showBackendDefined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsFetch = set.values.isEmpty && set.valuesCount > 0;
    return CatalogSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaneHeader(
            strings: strings,
            set: set,
            canAdd: canAdd,
            showBackendDefined: showBackendDefined,
            onAdd: onAdd,
          ),
          const SizedBox(height: 14),
          if (needsFetch)
            ref
                .watch(optionSetValuesProvider(set.id))
                .when(
                  loading: () => const CatalogSkeleton(rows: 3),
                  error: (_, _) => CatalogError(
                    strings: strings,
                    onRetry: () =>
                        ref.invalidate(optionSetValuesProvider(set.id)),
                  ),
                  data: (values) => _ValuesList(
                    strings: strings,
                    set: set,
                    values: values,
                    busy: busy,
                    canAdd: canAdd,
                    canRetire: canRetire,
                    onAdd: onAdd,
                    onEdit: onEdit,
                    onRetire: onRetire,
                    onActivate: onActivate,
                    onMove: onMove,
                  ),
                )
          else
            _ValuesList(
              strings: strings,
              set: set,
              values: set.values,
              busy: busy,
              canAdd: canAdd,
              canRetire: canRetire,
              onAdd: onAdd,
              onEdit: onEdit,
              onRetire: onRetire,
              onActivate: onActivate,
              onMove: onMove,
            ),
        ],
      ),
    );
  }
}

class _PaneHeader extends StatelessWidget {
  const _PaneHeader({
    required this.strings,
    required this.set,
    required this.canAdd,
    required this.showBackendDefined,
    required this.onAdd,
  });

  final UiMessageStrings strings;
  final OptionSet set;
  final bool canAdd;
  final bool showBackendDefined;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          if (canAdd)
            CatalogButton(
              key: const Key('option-value-add'),
              label: strings.tKey(PlatformAdminKeys.buttonOptionValueAdd),
              icon: Icons.add_rounded,
              secondary: true,
              compact: true,
              onPressed: onAdd,
            ),
        ],
      ),
      if (showBackendDefined) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            CatalogPill(
              key: Key('option-set-backend-defined-${set.code}'),
              label: strings.tKey(
                PlatformAdminKeys.optionSetsBackendDefinedBadge,
              ),
              tone: CatalogTone.info,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Catalog.blueTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: Catalog.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.tKey(
                    PlatformAdminKeys.optionSetsBackendDefinedHelper,
                  ),
                  style: Catalog.text(11.5, color: Catalog.blue),
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _ValuesList extends StatelessWidget {
  const _ValuesList({
    required this.strings,
    required this.set,
    required this.values,
    required this.busy,
    required this.canAdd,
    required this.canRetire,
    required this.onAdd,
    required this.onEdit,
    required this.onRetire,
    required this.onActivate,
    required this.onMove,
  });

  final UiMessageStrings strings;
  final OptionSet set;
  final List<OptionValue> values;
  final bool busy;
  final bool canAdd;
  final bool canRetire;
  final VoidCallback onAdd;
  final ValueChanged<OptionValue> onEdit;
  final ValueChanged<OptionValue> onRetire;
  final ValueChanged<OptionValue> onActivate;
  final void Function(OptionValue, int) onMove;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ordered = [...values]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.tKey(PlatformAdminKeys.sectionOptionSetValues),
                style: Catalog.eyebrow,
              ),
            ),
            Text(
              '${ordered.length}',
              style: Catalog.text(
                10.5,
                weight: FontWeight.w700,
                tabular: true,
                color: PtTheme.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (ordered.isEmpty)
          CatalogEmpty(
            title: strings.tKey(CommonKeys.emptyTitle),
            body: strings.tKey(
              PlatformAdminKeys.checklistOptionSetsEmptyValues,
            ),
            actionLabel: canAdd
                ? strings.tKey(PlatformAdminKeys.buttonOptionValueAdd)
                : null,
            onAction: canAdd ? onAdd : null,
          )
        else
          for (var index = 0; index < ordered.length; index++)
            _ValueRow(
              strings: strings,
              value: ordered[index],
              order: ordered[index].sortOrder,
              busy: busy,
              canRetire: canRetire,
              canMoveUp: index > 0,
              canMoveDown: index < ordered.length - 1,
              onEdit: () => onEdit(ordered[index]),
              onRetire: () => onRetire(ordered[index]),
              onActivate: () => onActivate(ordered[index]),
              onMove: (delta) => onMove(ordered[index], delta),
              translatedLabel: optionValueLabel(t, ordered[index]),
            ),
      ],
    );
  }
}

class _ValueRow extends ConsumerWidget {
  const _ValueRow({
    required this.strings,
    required this.value,
    required this.order,
    required this.busy,
    required this.canRetire,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onEdit,
    required this.onRetire,
    required this.onActivate,
    required this.onMove,
    required this.translatedLabel,
  });

  final UiMessageStrings strings;
  final OptionValue value;
  final int order;
  final bool busy;
  final bool canRetire;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onRetire;
  final VoidCallback onActivate;
  final ValueChanged<int> onMove;
  final String translatedLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = value.status.toUpperCase() == 'ACTIVE';
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(translatedLabel, style: Catalog.text(12, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value.code, style: Catalog.text(9.5, color: PtTheme.muted)),
      ],
    );
    final meta = <Widget>[
      _OrderPill(strings: strings, order: order),
      if (value.tone.isNotEmpty)
        CatalogPill(
          label: _toneLabel(strings, value.tone),
          tone: _catalogTone(value.tone),
        ),
      if (value.icon.isNotEmpty)
        Tooltip(
          message: value.icon,
          child: Icon(_catalogIcon(value.icon), size: 16, color: PtTheme.muted),
        ),
      if (canRetire)
        CatalogPill(
          label: checklistStatusLabel(ref, value.status),
          tone: active ? CatalogTone.good : CatalogTone.neutral,
        ),
      _icon(
        Icons.arrow_upward_rounded,
        strings.tKey(CommonKeys.buttonMoveUp),
        canMoveUp ? () => onMove(-1) : null,
        key: Key('option-value-move-up-${value.code}'),
      ),
      _icon(
        Icons.arrow_downward_rounded,
        strings.tKey(CommonKeys.buttonMoveDown),
        canMoveDown ? () => onMove(1) : null,
        key: Key('option-value-move-down-${value.code}'),
      ),
      _icon(
        Icons.edit_outlined,
        strings.tKey(CommonKeys.buttonEdit),
        onEdit,
        key: Key('option-value-edit-${value.code}'),
      ),
      if (canRetire)
        _icon(
          active ? Icons.block_outlined : Icons.check_circle_outlined,
          strings.tKey(
            active
                ? PlatformAdminKeys.buttonRetire
                : PlatformAdminKeys.buttonContentActivate,
          ),
          active ? onRetire : onActivate,
          danger: active,
          key: Key(
            active
                ? 'option-value-retire-${value.code}'
                : 'option-value-activate-${value.code}',
          ),
        ),
    ];
    return Container(
      key: Key('option-value-row-${value.code}'),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PtTheme.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: meta,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              for (final item in meta) ...[const SizedBox(width: 6), item],
            ],
          );
        },
      ),
    );
  }

  Widget _icon(
    IconData icon,
    String tooltip,
    VoidCallback? onPressed, {
    bool danger = false,
    Key? key,
  }) => Tooltip(
    message: tooltip,
    child: IconButton(
      key: key,
      icon: Icon(icon, size: 17),
      color: danger ? PtTheme.rose : PtTheme.muted,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: busy ? null : onPressed,
    ),
  );
}

class _OrderPill extends StatelessWidget {
  const _OrderPill({required this.strings, required this.order});

  final UiMessageStrings strings;
  final int order;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: strings.tKey(PlatformAdminKeys.taxonomyOrder),
    child: CatalogPill(label: '$order', tone: CatalogTone.neutral),
  );
}

String _toneLabel(
  UiMessageStrings strings,
  String raw,
) => strings.tKey(switch (raw.trim().toLowerCase()) {
  'success' || 'good' || 'positive' => PlatformAdminKeys.referenceToneSuccess,
  'warning' || 'warn' || 'attention' => PlatformAdminKeys.referenceToneWarning,
  'danger' || 'error' || 'critical' => PlatformAdminKeys.referenceToneDanger,
  'info' => PlatformAdminKeys.referenceToneInfo,
  _ => PlatformAdminKeys.referenceToneNeutral,
});

CatalogTone _catalogTone(String raw) => switch (raw.trim().toLowerCase()) {
  'success' || 'good' || 'positive' => CatalogTone.good,
  'warning' || 'warn' || 'attention' => CatalogTone.warn,
  'danger' || 'error' || 'critical' => CatalogTone.bad,
  'info' => CatalogTone.info,
  _ => CatalogTone.neutral,
};

IconData _catalogIcon(String raw) => switch (raw.trim().toLowerCase()) {
  'check' || 'check_circle' || 'done' => Icons.check_circle_outline,
  'warning' || 'alert' || 'alert_circle' => Icons.warning_amber_rounded,
  'block' || 'cancel' || 'error' => Icons.block_outlined,
  'clock' || 'pending' || 'schedule' => Icons.schedule_rounded,
  'info' => Icons.info_outline_rounded,
  'flag' => Icons.flag_outlined,
  'star' => Icons.star_outline_rounded,
  _ => Icons.circle_outlined,
};
