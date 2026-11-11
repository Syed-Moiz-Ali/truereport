import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_catalogue_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

/// Screen 9: Platform Audit Events Log, backed by the platform API.
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _query = '';
  String? _actionFilter;
  String? _entityFilter;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;
    final l10n = AppLocalizations.of(context);
    final auditEvents = ref.watch(auditEventsProvider);

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            PlatformSidebar(
              currentRoute: '/audit-log',
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
                            auditEvents.when(
                              loading: () => const _LoadingState(),
                              error: (error, stackTrace) => _ErrorState(
                                onRetry: () =>
                                    ref.invalidate(auditEventsProvider),
                              ),
                              data: (events) => _buildData(l10n, events),
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
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 14,
              color: PtTheme.muted,
            ),
            Text(
              'TAMPER-PROOF LEDGER',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                weight: FontWeight.w700,
                color: PtTheme.muted,
                tracking: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.auditLog,
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
          'Administrative operations and permission changes served by the platform API.',
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
        ),
      ],
    );
  }

  Widget _buildData(
    AppLocalizations l10n,
    List<PlatformAuditEvent> events,
  ) {
    final actions = _distinct(events.map((event) => event.action));
    final entities = _distinct(events.map((event) => event.entityType));
    final activeAction = actions.contains(_actionFilter) ? _actionFilter : null;
    final activeEntity = entities.contains(_entityFilter) ? _entityFilter : null;

    final query = _query.trim().toLowerCase();
    final filtered = events
        .where(
          (event) =>
              (activeAction == null || event.action == activeAction) &&
              (activeEntity == null || event.entityType == activeEntity) &&
              (query.isEmpty || _matches(event, query)),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchField(l10n),
        const SizedBox(height: 16),
        _buildFilters(l10n, actions, entities, activeAction, activeEntity),
        const SizedBox(height: 20),
        if (events.isEmpty)
          _EmptyState(message: l10n.noData)
        else ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                '${l10n.auditLog} (${filtered.length})',
                style: PtTheme.font(
                  15,
                  lineHeight: 20,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              _CountChip(label: '${filtered.length} / ${events.length}'),
            ],
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            _EmptyState(message: l10n.noData)
          else
            LayoutBuilder(
              builder: (context, constraints) => _buildEventGrid(
                l10n,
                filtered,
                constraints.maxWidth,
              ),
            ),
        ],
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
        key: const Key('input-search-audit-log'),
        onChanged: (value) => setState(() => _query = value),
        style: PtTheme.font(13, lineHeight: 18, color: PtTheme.ink),
        decoration: InputDecoration(
          hintText: '${l10n.search} ${l10n.auditLog}...',
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

  Widget _buildFilters(
    AppLocalizations l10n,
    List<String> actions,
    List<String> entities,
    String? activeAction,
    String? activeEntity,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterRow(
            label: l10n.action,
            values: actions,
            selected: activeAction,
            allLabel: l10n.filterAll,
            onSelected: (value) => setState(() => _actionFilter = value),
          ),
          const SizedBox(height: 12),
          _FilterRow(
            label: l10n.entity,
            values: entities,
            selected: activeEntity,
            allLabel: l10n.filterAll,
            onSelected: (value) => setState(() => _entityFilter = value),
          ),
        ],
      ),
    );
  }

  Widget _buildEventGrid(
    AppLocalizations l10n,
    List<PlatformAuditEvent> events,
    double maxWidth,
  ) {
    const spacing = 16.0;
    final columns = maxWidth >= 1100 ? 2 : 1;
    final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final event in events)
          SizedBox(
            width: cardWidth,
            child: _buildEventCard(l10n, event),
          ),
      ],
    );
  }

  Widget _buildEventCard(
    AppLocalizations l10n,
    PlatformAuditEvent event,
  ) {
    final metadata = event.metadataJson.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PtTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PtTheme.border),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 19,
                  color: PtTheme.deepGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.action.isEmpty ? '-' : event.action,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PtTheme.font(
                        15,
                        lineHeight: 20,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${l10n.entity}: '
                      '${event.entityType.isEmpty ? '-' : event.entityType} / '
                      '${event.entityId.isEmpty ? '-' : event.entityId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 12),
          const Divider(color: PtTheme.border, height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _Meta(label: 'Actor', value: event.actorRole),
              _Meta(label: l10n.reason, value: event.reasonCode),
              _Meta(label: l10n.occurredAt, value: event.occurredAt),
            ],
          ),
          if (metadata.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PtTheme.canvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PtTheme.border),
              ),
              child: Text(
                metadata,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: PtTheme.font(
                  11,
                  lineHeight: 16,
                  color: PtTheme.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _matches(PlatformAuditEvent event, String query) =>
      event.action.toLowerCase().contains(query) ||
      event.entityType.toLowerCase().contains(query) ||
      event.entityId.toLowerCase().contains(query) ||
      event.actorRole.toLowerCase().contains(query) ||
      event.occurredAt.toLowerCase().contains(query) ||
      event.reasonCode.toLowerCase().contains(query) ||
      event.metadataJson.toLowerCase().contains(query);

  List<String> _distinct(Iterable<String> values) {
    final set = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return set;
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.allLabel,
    required this.onSelected,
  });

  final String label;
  final List<String> values;
  final String? selected;
  final String allLabel;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: PtTheme.font(
            11,
            lineHeight: 14,
            weight: FontWeight.w700,
            color: PtTheme.muted,
            tracking: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: allLabel,
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final value in values)
              _FilterChip(
                label: value,
                selected: selected == value,
                onTap: () => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? PtTheme.deepGreen : PtTheme.canvas,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? PtTheme.deepGreen : PtTheme.border,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PtTheme.font(
              11,
              lineHeight: 14,
              weight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? PtTheme.white : PtTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: PtTheme.font(
            10,
            lineHeight: 13,
            weight: FontWeight.w700,
            color: PtTheme.muted,
            tracking: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PtTheme.font(
            12,
            lineHeight: 16,
            weight: FontWeight.w600,
            color: PtTheme.ink,
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: PtTheme.deepGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PtTheme.font(
          11,
          lineHeight: 14,
          weight: FontWeight.w700,
          color: PtTheme.deepGreen,
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
            Icons.history_toggle_off_rounded,
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
