import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_chips.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../components/platform_toolbar.dart';
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
    final l10n = AppLocalizations.of(context);
    final auditEvents = ref.watch(auditEventsProvider);

    return PlatformShell(
      currentRoute: '/audit-log',
      onNavigate: (route) => context.go(route),
      child: PlatformPage(
        maxWidth: 1200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            PlatformPageHeader(
              title: l10n.auditLog,
              subtitle: 'Administrative operations and permission changes served by the platform API.',
            ),
            const SizedBox(height: 20),
            auditEvents.when(
              loading: () => const PlatformLoadingView(),
              error: (error, stackTrace) => PlatformErrorView(
                message: l10n.unhealthy,
                onRetry: () => ref.invalidate(auditEventsProvider),
              ),
              data: (events) => _buildData(l10n, events),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildData(AppLocalizations l10n, List<PlatformAuditEvent> events) {
    final actions = _distinct(events.map((event) => event.action));
    final entities = _distinct(events.map((event) => event.entityType));
    final activeAction = actions.contains(_actionFilter) ? _actionFilter : null;
    final activeEntity = entities.contains(_entityFilter)
        ? _entityFilter
        : null;

    final query = _query.trim().toLowerCase();
    final filtered = events
        .where(
          (event) =>
              (activeAction == null || event.action == activeAction) &&
              (activeEntity == null || event.entityType == activeEntity) &&
              (query.isEmpty || _matches(event, query)),
        )
        .toList(growable: false);

    if (events.isEmpty) {
      return PlatformEmptyView(
        icon: Icons.history_toggle_off_rounded,
        title: l10n.noData,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlatformToolbar(
          searchHint: '${l10n.search} ${l10n.auditLog}...',
          onSearchChanged: (value) => setState(() => _query = value),
          filters: [
            _buildFilterGroup(
              label: l10n.action,
              values: actions,
              selected: activeAction,
              allLabel: l10n.filterAll,
              onSelected: (value) => setState(() => _actionFilter = value),
            ),
            _buildFilterGroup(
              label: l10n.entity,
              values: entities,
              selected: activeEntity,
              allLabel: l10n.filterAll,
              onSelected: (value) => setState(() => _entityFilter = value),
            ),
          ],
          countLabel:
              '${l10n.auditLog} (${filtered.length}) • ${filtered.length} / ${events.length}',
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          PlatformEmptyView(
            icon: Icons.history_toggle_off_rounded,
            title: l10n.noData,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) =>
                _buildEventGrid(l10n, filtered, constraints.maxWidth),
          ),
      ],
    );
  }

  Widget _buildFilterGroup({
    required String label,
    required List<String> values,
    required String? selected,
    required String allLabel,
    required ValueChanged<String?> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
            PlatformFilterChip(
              label: allLabel,
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final value in values)
              PlatformFilterChip(
                label: value,
                selected: selected == value,
                onTap: () => onSelected(value),
              ),
          ],
        ),
      ],
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
          SizedBox(width: cardWidth, child: _buildEventCard(l10n, event)),
      ],
    );
  }

  Widget _buildEventCard(AppLocalizations l10n, PlatformAuditEvent event) {
    final metadata = event.metadataJson.trim();

    return PlatformSectionCard(
      padding: const EdgeInsets.all(16),
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
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlatformStatusChip(
                status: event.entityType.isEmpty ? '-' : event.entityType,
              ),
              PlatformMetaPill(
                label: 'Actor',
                value: event.actorRole.isEmpty ? '-' : event.actorRole,
              ),
              PlatformMetaPill(
                label: l10n.reason,
                value: event.reasonCode.isEmpty ? '-' : event.reasonCode,
              ),
              PlatformMetaPill(
                label: l10n.occurredAt,
                value: event.occurredAt.isEmpty ? '-' : event.occurredAt,
              ),
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
                style: PtTheme.font(11, lineHeight: 16, color: PtTheme.muted),
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
