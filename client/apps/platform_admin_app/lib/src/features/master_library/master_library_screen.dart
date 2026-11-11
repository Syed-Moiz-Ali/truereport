import 'dart:async';

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
import 'categories_screen.dart';
import 'master_item_editor_screen.dart';
import 'option_sets_screen.dart';

const _itemStatuses = <String>[
  'ACTIVE',
  'DRAFT',
  'PUBLISHED',
  'RETIRED',
];

class MasterLibraryScreen extends ConsumerStatefulWidget {
  const MasterLibraryScreen({super.key});

  @override
  ConsumerState<MasterLibraryScreen> createState() =>
      _MasterLibraryScreenState();
}

class _MasterLibraryScreenState extends ConsumerState<MasterLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';
  String _categoryId = '';
  String _status = '';
  bool _seeding = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _search = value);
    });
  }

  Future<void> _openEditor([String? itemId]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MasterItemEditorScreen(itemId: itemId),
      ),
    );
    if (!mounted) return;
    ref.invalidate(itemsProvider);
    ref.invalidate(categoriesProvider);
  }

  Future<void> _openCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
    );
    if (!mounted) return;
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoryWeightCheckProvider);
    ref.invalidate(itemsProvider);
  }

  Future<void> _openOptionSets() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OptionSetsScreen()),
    );
    if (!mounted) return;
    ref.invalidate(optionSetsProvider);
  }

  Future<void> _seedChecklist() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _seeding = true);
    try {
      final result = await ref.read(platformConfigActionsProvider).seed();
      if (!mounted) return;
      _showMessage(l10n.seedSuccess(result.created, result.skipped));
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        '${l10n.seedFailed}: ${_failureMessage(error)}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories =
        categoriesAsync.asData?.value ?? const <PlatformCategory>[];
    final query = ItemQuery(
      search: _search,
      categoryId: _categoryId,
      status: _status,
    );
    final itemsAsync = ref.watch(itemsProvider(query));
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
                PlatformHeader(onSearchChanged: _onSearchChanged),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isExpanded = constraints.maxWidth >= 820;
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
                            constraints: const BoxConstraints(maxWidth: 1240),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(l10n),
                                const SizedBox(height: 20),
                                _buildFilters(l10n, categories),
                                const SizedBox(height: 20),
                                _buildItems(
                                  l10n,
                                  itemsAsync,
                                  categories,
                                  isExpanded,
                                ),
                              ],
                            ),
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

  Widget _buildHeader(AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.masterLibraryTitle,
                style: PtTheme.font(
                  28,
                  lineHeight: 34,
                  weight: FontWeight.w800,
                  color: PtTheme.ink,
                  tracking: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.masterLibrarySubtitle,
                style: PtTheme.font(
                  14,
                  lineHeight: 20,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _openCategories,
              icon: const Icon(
                Icons.category_outlined,
                size: 16,
                color: PtTheme.deepGreen,
              ),
              label: Text(
                l10n.addCategory,
                style: PtTheme.font(
                  13,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
              style: _outlinedButtonStyle(),
            ),
            OutlinedButton.icon(
              onPressed: _openOptionSets,
              icon: const Icon(
                Icons.list_alt_outlined,
                size: 16,
                color: PtTheme.deepGreen,
              ),
              label: Text(
                l10n.optionSetsTab,
                style: PtTheme.font(
                  13,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
              style: _outlinedButtonStyle(),
            ),
            OutlinedButton.icon(
              onPressed: _seeding ? null : _seedChecklist,
              icon: _seeding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PtTheme.deepGreen,
                      ),
                    )
                  : const Icon(
                      Icons.cloud_download_outlined,
                      size: 16,
                      color: PtTheme.deepGreen,
                    ),
              label: Text(
                l10n.seedDefaultChecklist,
                style: PtTheme.font(
                  13,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
              style: _outlinedButtonStyle(),
            ),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                l10n.addItem,
                style: PtTheme.font(
                  13,
                  weight: FontWeight.w700,
                  color: PtTheme.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PtTheme.deepGreen,
                foregroundColor: PtTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(
    AppLocalizations l10n,
    List<PlatformCategory> categories,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    color: PtTheme.ink,
                  ),
                  decoration: _inputDecoration(l10n.search).copyWith(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: PtTheme.muted,
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: _inputDecoration(l10n.status),
                  style: PtTheme.font(14, color: PtTheme.ink),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l10n.filterAll),
                    ),
                    for (final status in _itemStatuses)
                      DropdownMenuItem(value: status, child: Text(status)),
                  ],
                  onChanged: (value) {
                    setState(() => _status = value ?? '');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterChip(
                  label: l10n.filterAll,
                  selected: _categoryId.isEmpty,
                  onTap: () => setState(() => _categoryId = ''),
                ),
                for (final category in categories) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: category.name.isEmpty
                        ? category.code
                        : category.name,
                    selected: _categoryId == category.id,
                    onTap: () =>
                        setState(() => _categoryId = category.id),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItems(
    AppLocalizations l10n,
    AsyncValue<List<PlatformItem>> itemsAsync,
    List<PlatformCategory> categories,
    bool isExpanded,
  ) {
    return itemsAsync.when(
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
              onPressed: () => ref.invalidate(itemsProvider),
              style: _outlinedButtonStyle(),
              child: Text(
                l10n.retry,
                style: PtTheme.font(
                  13,
                  weight: FontWeight.w700,
                  color: PtTheme.deepGreen,
                ),
              ),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _StatePanel(
            child: Column(
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 38,
                  color: PtTheme.muted,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.noData,
                  style: PtTheme.font(
                    15,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
              ],
            ),
          );
        }
        if (isExpanded) {
          return _buildTable(l10n, items);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items) ...[
              _buildItemCard(l10n, item),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTable(AppLocalizations l10n, List<PlatformItem> items) {
    return Container(
      decoration: _surfaceDecoration(),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          headingTextStyle: PtTheme.font(
            11,
            weight: FontWeight.w700,
            color: PtTheme.muted,
            tracking: 0.4,
          ),
          dataTextStyle: PtTheme.font(13, color: PtTheme.ink),
          columns: [
            DataColumn(label: Text(l10n.itemCode.toUpperCase())),
            DataColumn(label: Text(l10n.labelEn.toUpperCase())),
            DataColumn(label: Text(l10n.labelAr.toUpperCase())),
            DataColumn(label: Text(l10n.category.toUpperCase())),
            DataColumn(label: Text(l10n.status.toUpperCase())),
            DataColumn(label: Text(l10n.measurementUnit.toUpperCase())),
            DataColumn(label: Text(l10n.safetyCritical.toUpperCase())),
            const DataColumn(label: Text('VERSION')),
            DataColumn(label: Text(l10n.edit.toUpperCase())),
          ],
          rows: [
            for (final item in items)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      item.code,
                      style: PtTheme.font(
                        12,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                  ),
                  DataCell(Text(item.labelEn.isEmpty ? '—' : item.labelEn)),
                  DataCell(Text(item.labelAr.isEmpty ? '—' : item.labelAr)),
                  DataCell(
                    Text(
                      item.categoryLabelEn.isEmpty
                          ? item.categoryId
                          : item.categoryLabelEn,
                    ),
                  ),
                  DataCell(_StatusChip(status: item.status)),
                  DataCell(Text(item.measurementUnit.isEmpty
                      ? '—'
                      : item.measurementUnit)),
                  DataCell(
                    Icon(
                      item.safetyCritical
                          ? Icons.verified_user_rounded
                          : Icons.remove_rounded,
                      size: 16,
                      color: item.safetyCritical
                          ? PtTheme.rose
                          : PtTheme.muted,
                    ),
                  ),
                  DataCell(
                    Text(
                      item.currentVersion == null
                          ? '—'
                          : 'v${item.currentVersion}',
                    ),
                  ),
                  DataCell(
                    TextButton.icon(
                      onPressed: () => _openEditor(item.id),
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
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(AppLocalizations l10n, PlatformItem item) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: PtTheme.canvas,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: PtTheme.border),
                    ),
                    child: Text(
                      item.code,
                      style: PtTheme.font(
                        11,
                        weight: FontWeight.w700,
                        color: PtTheme.muted,
                        tracking: 0.4,
                      ),
                    ),
                  ),
                  _StatusChip(status: item.status),
                  if (item.safetyCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: PtTheme.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.safetyCritical,
                        style: PtTheme.font(
                          11,
                          weight: FontWeight.w700,
                          color: PtTheme.rose,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                item.currentVersion == null
                    ? ''
                    : 'v${item.currentVersion}',
                style: PtTheme.font(
                  12,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.labelEn.isEmpty ? item.code : item.labelEn,
            style: PtTheme.font(
              16,
              lineHeight: 22,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          if (item.labelAr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.labelAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(
                14,
                lineHeight: 20,
                color: PtTheme.muted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetaPill(
                label: l10n.category,
                value: item.categoryLabelEn.isEmpty
                    ? item.categoryId
                    : item.categoryLabelEn,
              ),
              if (item.measurementUnit.isNotEmpty)
                _MetaPill(
                  label: l10n.measurementUnit,
                  value: item.measurementUnit,
                ),
              if (item.sensorTool.isNotEmpty)
                _MetaPill(label: l10n.sensorTool, value: item.sensorTool),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              onPressed: () => _openEditor(item.id),
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
          ),
        ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
              : PtTheme.canvas,
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PtTheme.border),
      ),
      child: Text(
        '$label: $value',
        style: PtTheme.font(
          11,
          weight: FontWeight.w600,
          color: PtTheme.muted,
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
