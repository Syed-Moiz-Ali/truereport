import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_catalogue_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

/// Screen 7: Master Dropdowns & Data Catalogues, backed by the platform API.
class DataCataloguesScreen extends ConsumerStatefulWidget {
  const DataCataloguesScreen({super.key});

  @override
  ConsumerState<DataCataloguesScreen> createState() =>
      _DataCataloguesScreenState();
}

class _CatalogueGroup {
  const _CatalogueGroup({required this.section, required this.entry});

  final String section;
  final PlatformCatalogueEntry entry;

  String get key => '${section}_${entry.id}';
}

class _DataCataloguesScreenState extends ConsumerState<DataCataloguesScreen> {
  String _query = '';
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;
    final l10n = AppLocalizations.of(context);
    final reasons = ref.watch(reasonsProvider);
    final dropdowns = ref.watch(dropdownsProvider);

    void retry() {
      ref.invalidate(reasonsProvider);
      ref.invalidate(dropdownsProvider);
    }

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            PlatformSidebar(
              currentRoute: '/data-catalogues',
              onNavigate: (route) => context.go(route),
            ),
          Expanded(
            child: Column(
              children: [
                const PlatformHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPageHeader(l10n),
                            const SizedBox(height: 20),
                            _buildSearchField(l10n),
                            const SizedBox(height: 20),
                            reasons.when(
                              loading: () => const _LoadingState(),
                              error: (error, stackTrace) =>
                                  _ErrorState(onRetry: retry),
                              data: (reasonItems) => dropdowns.when(
                                loading: () => const _LoadingState(),
                                error: (error, stackTrace) =>
                                    _ErrorState(onRetry: retry),
                                data: (dropdownItems) => LayoutBuilder(
                                  builder: (context, constraints) =>
                                      _buildBrowser(
                                        l10n,
                                        reasonItems,
                                        dropdownItems,
                                        constraints.maxWidth < 760,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLATFORM DICTIONARIES',
          style: PtTheme.font(
            11,
            lineHeight: 14,
            weight: FontWeight.w700,
            color: PtTheme.muted,
            tracking: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.dataCatalogues,
          style: PtTheme.font(
            26,
            lineHeight: 32,
            weight: FontWeight.w800,
            color: PtTheme.ink,
            tracking: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Browse reason and dropdown catalogues served by the platform API.',
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
        ),
      ],
    );
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
      ),
      child: TextField(
        key: const Key('input-search-catalogues'),
        onChanged: (value) => setState(() => _query = value),
        style: PtTheme.font(13, lineHeight: 18, color: PtTheme.ink),
        decoration: InputDecoration(
          hintText: '${l10n.search} ${l10n.dataCatalogues}...',
          hintStyle: PtTheme.font(12, lineHeight: 16, color: PtTheme.muted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: PtTheme.muted,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBrowser(
    AppLocalizations l10n,
    List<PlatformCatalogueEntry> reasons,
    List<PlatformCatalogueEntry> dropdowns,
    bool compact,
  ) {
    final groups = <_CatalogueGroup>[
      for (final entry in _sortedEntries(reasons))
        _CatalogueGroup(section: 'Reasons', entry: entry),
      for (final entry in _sortedEntries(dropdowns))
        _CatalogueGroup(section: 'Dropdowns', entry: entry),
    ];
    final filtered = groups.where(_groupMatches).toList(growable: false);

    _CatalogueGroup? selected;
    if (filtered.isNotEmpty) {
      selected = filtered.firstWhere(
        (group) => group.key == _selectedKey,
        orElse: () => filtered.first,
      );
    }

    final groupPanel = _buildGroupPanel(l10n, filtered);
    final detailPanel = _buildDetailPanel(l10n, selected);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          groupPanel,
          const SizedBox(height: 20),
          detailPanel,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: groupPanel),
        const SizedBox(width: 20),
        Expanded(flex: 3, child: detailPanel),
      ],
    );
  }

  Widget _buildGroupPanel(
    AppLocalizations l10n,
    List<_CatalogueGroup> groups,
  ) {
    final reasonGroups = groups
        .where((group) => group.section == 'Reasons')
        .toList(growable: false);
    final dropdownGroups = groups
        .where((group) => group.section == 'Dropdowns')
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
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
              Text(
                'Catalogues',
                style: PtTheme.font(
                  16,
                  lineHeight: 22,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              _CountChip(label: '${groups.length}'),
            ],
          ),
          const SizedBox(height: 14),
          if (groups.isEmpty)
            _EmptyHint(message: l10n.noData)
          else ...[
            if (reasonGroups.isNotEmpty) ...[
              _SectionLabel(label: l10n.reasons),
              const SizedBox(height: 8),
              for (final group in reasonGroups) ...[
                _buildGroupCard(group),
                const SizedBox(height: 10),
              ],
            ],
            if (dropdownGroups.isNotEmpty) ...[
              if (reasonGroups.isNotEmpty) const SizedBox(height: 6),
              const _SectionLabel(label: 'Dropdowns'),
              const SizedBox(height: 8),
              for (final group in dropdownGroups) ...[
                _buildGroupCard(group),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGroupCard(_CatalogueGroup group) {
    final entry = group.entry;
    final isSelected = group.key == _selectedKey;
    final label = entry.labelEn.trim().isEmpty ? entry.code : entry.labelEn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('catalogue-group-${group.key}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedKey = group.key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? PtTheme.deepGreen.withValues(alpha: 0.06)
                : PtTheme.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? PtTheme.deepGreen : PtTheme.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? PtTheme.deepGreen.withValues(alpha: 0.12)
                      : PtTheme.canvas,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  group.section == 'Reasons'
                      ? Icons.rule_folder_outlined
                      : Icons.list_alt_rounded,
                  size: 17,
                  color: isSelected ? PtTheme.deepGreen : PtTheme.muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.isEmpty ? '-' : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        14,
                        lineHeight: 18,
                        weight: FontWeight.w700,
                        color: isSelected ? PtTheme.deepGreen : PtTheme.ink,
                      ),
                    ),
                    if (entry.labelAr.trim().isNotEmpty)
                      Text(
                        entry.labelAr,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PtTheme.font(
                          12,
                          lineHeight: 16,
                          color: PtTheme.muted,
                        ),
                      ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CodeChip(label: entry.code),
                        _StatusPill(status: entry.status),
                        if (entry.values.isNotEmpty)
                          _CountChip(label: '${entry.values.length}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(AppLocalizations l10n, _CatalogueGroup? selected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: selected == null
          ? _EmptyHint(message: l10n.noData)
          : _buildDetailContent(l10n, selected.entry),
    );
  }

  Widget _buildDetailContent(
    AppLocalizations l10n,
    PlatformCatalogueEntry entry,
  ) {
    final query = _query.toLowerCase();
    final values = query.isEmpty
        ? _sortedValues(entry.values)
        : _sortedValues(
            entry.values.where((value) => _valueMatchesQuery(value, query)),
          );
    final label = entry.labelEn.trim().isEmpty ? entry.code : entry.labelEn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.isEmpty ? '-' : label,
          style: PtTheme.font(
            18,
            lineHeight: 24,
            weight: FontWeight.w700,
            color: PtTheme.ink,
          ),
        ),
        if (entry.labelAr.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            entry.labelAr,
            textDirection: TextDirection.rtl,
            style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CodeChip(label: entry.code),
            _StatusPill(status: entry.status),
            _CountChip(label: 'Order: ${entry.sortOrder}'),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(color: PtTheme.border, height: 1),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              'Values',
              style: PtTheme.font(
                15,
                lineHeight: 20,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            _CountChip(label: '${values.length}'),
          ],
        ),
        const SizedBox(height: 10),
        if (values.isEmpty)
          _EmptyHint(message: l10n.noData)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final value in values) ...[
                _buildValueTile(value),
                const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildValueTile(PlatformCatalogueValue value) {
    final label = value.labelEn.trim().isEmpty ? value.code : value.labelEn;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.isEmpty ? '-' : label,
            style: PtTheme.font(
              13,
              lineHeight: 18,
              weight: FontWeight.w600,
              color: PtTheme.ink,
            ),
          ),
          if (value.labelAr.trim().isNotEmpty)
            Text(
              value.labelAr,
              textDirection: TextDirection.rtl,
              style: PtTheme.font(12, lineHeight: 16, color: PtTheme.muted),
            ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CodeChip(label: value.code),
              _StatusPill(status: value.status),
              _CountChip(label: 'Order: ${value.sortOrder}'),
            ],
          ),
        ],
      ),
    );
  }

  bool _groupMatches(_CatalogueGroup group) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    if (_entryMatches(group.entry, query)) return true;
    return group.entry.values.any(
      (value) => _valueMatchesQuery(value, query),
    );
  }

  bool _entryMatches(PlatformCatalogueEntry entry, String query) =>
      entry.code.toLowerCase().contains(query) ||
      entry.labelEn.toLowerCase().contains(query) ||
      entry.labelAr.toLowerCase().contains(query);

  bool _valueMatchesQuery(PlatformCatalogueValue value, String query) =>
      value.code.toLowerCase().contains(query) ||
      value.labelEn.toLowerCase().contains(query) ||
      value.labelAr.toLowerCase().contains(query);

  List<PlatformCatalogueEntry> _sortedEntries(
    List<PlatformCatalogueEntry> entries,
  ) {
    final sorted = [...entries];
    sorted.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.code.compareTo(b.code);
    });
    return sorted;
  }

  List<PlatformCatalogueValue> _sortedValues(
    Iterable<PlatformCatalogueValue> values,
  ) {
    final sorted = [...values];
    sorted.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.code.compareTo(b.code);
    });
    return sorted;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: PtTheme.font(
        11,
        lineHeight: 14,
        weight: FontWeight.w700,
        color: PtTheme.muted,
        tracking: 0.7,
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PtTheme.border),
      ),
      child: Text(
        label.isEmpty ? '-' : label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: PtTheme.muted,
          tracking: 0.4,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final normalized = status.toUpperCase();
    final color = switch (normalized) {
      'ACTIVE' => PtTheme.emerald,
      'RETIRED' => PtTheme.rose,
      _ => PtTheme.muted,
    };
    final label = switch (normalized) {
      'ACTIVE' => l10n.active,
      'RETIRED' => l10n.retired,
      _ => status.isEmpty ? '-' : status,
    };
    return _CountChip(label: label, color: color);
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, this.color = PtTheme.muted});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 30, color: PtTheme.muted),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: PtTheme.deepGreen),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).loading,
              style: PtTheme.font(13, color: PtTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.rose.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: PtTheme.rose, size: 34),
          const SizedBox(height: 12),
          Text(
            l10n.unhealthy,
            style: PtTheme.font(
              16,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: PtTheme.deepGreen),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
