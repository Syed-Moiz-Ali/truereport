import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_catalogue_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

/// Screen 8: Global Equipment Library, backed by the platform API.
class EquipmentLibraryScreen extends ConsumerStatefulWidget {
  const EquipmentLibraryScreen({super.key});

  @override
  ConsumerState<EquipmentLibraryScreen> createState() =>
      _EquipmentLibraryScreenState();
}

class _EquipmentLibraryScreenState
    extends ConsumerState<EquipmentLibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;
    final l10n = AppLocalizations.of(context);
    final equipment = ref.watch(equipmentProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            PlatformSidebar(
              currentRoute: '/equipment',
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
                            equipment.when(
                              loading: () => const _LoadingState(),
                              error: (error, stackTrace) => _ErrorState(
                                onRetry: () =>
                                    ref.invalidate(equipmentProvider),
                              ),
                              data: (items) => _buildResults(l10n, items),
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
          'NETWORK HARDWARE FLEET',
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
          l10n.equipment,
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
          'Hardware devices and diagnostic instruments served by the platform API.',
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
        key: const Key('input-search-equipment'),
        onChanged: (value) => setState(() => _query = value),
        style: PtTheme.font(13, lineHeight: 18, color: PtTheme.ink),
        decoration: InputDecoration(
          hintText: '${l10n.search} ${l10n.equipment}...',
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

  Widget _buildResults(
    AppLocalizations l10n,
    List<PlatformCatalogueEntry> items,
  ) {
    final query = _query.trim().toLowerCase();
    final filtered = _sortedEntries(items)
        .where((entry) => query.isEmpty || _matches(entry, query))
        .toList(growable: false);

    if (items.isEmpty) {
      return _EmptyState(message: l10n.noData);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              '${l10n.equipment} (${filtered.length})',
              style: PtTheme.font(
                15,
                lineHeight: 20,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          _EmptyState(message: l10n.noData)
        else
          LayoutBuilder(
            builder: (context, constraints) => _buildGrid(
              filtered,
              constraints.maxWidth,
            ),
          ),
      ],
    );
  }

  Widget _buildGrid(List<PlatformCatalogueEntry> items, double maxWidth) {
    const spacing = 16.0;
    const maxCardExtent = 360.0;
    final columns = (maxWidth / maxCardExtent).floor().clamp(1, 4);
    final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final entry in items)
          SizedBox(width: cardWidth, child: _buildEquipmentCard(entry)),
      ],
    );
  }

  Widget _buildEquipmentCard(PlatformCatalogueEntry entry) {
    final label = entry.labelEn.trim().isEmpty ? entry.code : entry.labelEn;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: PtTheme.border),
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 21,
                  color: PtTheme.deepGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.isEmpty ? '-' : label,
                      style: PtTheme.font(
                        15,
                        lineHeight: 20,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    if (entry.labelAr.trim().isNotEmpty)
                      Text(
                        entry.labelAr,
                        textDirection: TextDirection.rtl,
                        style: PtTheme.font(
                          12,
                          lineHeight: 16,
                          color: PtTheme.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: PtTheme.border, height: 1),
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
        ],
      ),
    );
  }

  bool _matches(PlatformCatalogueEntry entry, String query) =>
      entry.code.toLowerCase().contains(query) ||
      entry.labelEn.toLowerCase().contains(query) ||
      entry.labelAr.toLowerCase().contains(query);

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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.construction_outlined,
            size: 36,
            color: PtTheme.muted,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: PtTheme.font(
              14,
              weight: FontWeight.w600,
              color: PtTheme.ink,
            ),
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
