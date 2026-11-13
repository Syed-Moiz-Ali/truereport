import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../components/platform_buttons.dart';
import '../../components/platform_chips.dart';
import '../../components/platform_shell.dart';
import '../../components/platform_states.dart';
import '../../download_file_stub.dart'
    if (dart.library.html) '../../download_file_web.dart';
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
  final _action = TextEditingController();
  final _entityType = TextEditingController();
  final _actor = TextEditingController();
  final _dateFrom = TextEditingController();
  final _dateTo = TextEditingController();
  final _search = TextEditingController();
  AuditQuery _query = const AuditQuery();
  Timer? _debounce;
  bool _exporting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _action.dispose();
    _entityType.dispose();
    _actor.dispose();
    _dateFrom.dispose();
    _dateTo.dispose();
    _search.dispose();
    super.dispose();
  }

  void _apply(AuditQuery next) {
    setState(() => _query = next.copyWith(page: 0));
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _apply(_query.copyWith(search: value.trim()));
    });
  }

  Future<void> _export(String format) async {
    if (_exporting) return;
    final strings = ref.read(uiStringsProvider);
    setState(() => _exporting = true);
    try {
      final bytes = await ref
          .read(platformConfigApiProvider)
          .exportAuditEvents(
            format: format,
            action: _query.action,
            entityType: _query.entityType,
            actor: _query.actor,
            dateFrom: _query.dateFrom,
            dateTo: _query.dateTo,
            search: _query.search,
            sort: _query.sort,
          );
      downloadBytes('audit-events.$format', bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PtTheme.deepGreen,
          content: Text(
            strings.tKey(PlatformAdminKeys.pageAuditTitle),
            style: PtTheme.font(13, color: PtTheme.white),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.tKey(CommonKeys.errorGeneric))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(uiStringsProvider);
    final auditEvents = ref.watch(auditEventsPageProvider(_query));

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
                  strings.tKey(PlatformAdminKeys.pageAuditEyebrow),
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
              title: strings.tKey(PlatformAdminKeys.pageAuditTitle),
              subtitle: strings.tKey(PlatformAdminKeys.pageAuditSubtitle),
              actions: [
                PlatformSecondaryButton(
                  label: strings.tKey(PlatformAdminKeys.buttonAuditExportCsv),
                  icon: Icons.table_view_rounded,
                  isLoading: _exporting,
                  onPressed: _exporting ? null : () => _export('csv'),
                ),
                PlatformSecondaryButton(
                  label: strings.tKey(PlatformAdminKeys.buttonAuditExportJson),
                  icon: Icons.data_object_rounded,
                  isLoading: _exporting,
                  onPressed: _exporting ? null : () => _export('json'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFilters(strings),
            const SizedBox(height: 20),
            auditEvents.when(
              loading: () => const PlatformLoadingView(),
              error: (error, stackTrace) => PlatformErrorView(
                message: strings.tKey(CommonKeys.statusUnhealthy),
                retryLabel: strings.tKey(CommonKeys.buttonRetry),
                onRetry: () => ref.invalidate(auditEventsPageProvider(_query)),
              ),
              data: (page) => _buildData(strings, page),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(UiMessageStrings strings) {
    return PlatformSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: strings.tKey(PlatformAdminKeys.filterAuditSearch),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
            ),
            onChanged: _searchChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _filterField(
                controller: _action,
                label: strings.tKey(PlatformAdminKeys.filterAuditAction),
                onSubmitted: (value) =>
                    _apply(_query.copyWith(action: value.trim())),
              ),
              _filterField(
                controller: _entityType,
                label: strings.tKey(PlatformAdminKeys.filterAuditEntityType),
                onSubmitted: (value) =>
                    _apply(_query.copyWith(entityType: value.trim())),
              ),
              _filterField(
                controller: _actor,
                label: strings.tKey(PlatformAdminKeys.filterAuditActor),
                onSubmitted: (value) =>
                    _apply(_query.copyWith(actor: value.trim())),
              ),
              _filterField(
                controller: _dateFrom,
                label: strings.tKey(PlatformAdminKeys.filterAuditDateFrom),
                onSubmitted: (value) =>
                    _apply(_query.copyWith(dateFrom: value.trim())),
              ),
              _filterField(
                controller: _dateTo,
                label: strings.tKey(PlatformAdminKeys.filterAuditDateTo),
                onSubmitted: (value) =>
                    _apply(_query.copyWith(dateTo: value.trim())),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _query.sort,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: [
                    DropdownMenuItem(
                      value: 'occurredAt,desc',
                      child: Text(
                        strings.tKey(PlatformAdminKeys.filterAuditNewestFirst),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'occurredAt,asc',
                      child: Text(
                        strings.tKey(PlatformAdminKeys.filterAuditOldestFirst),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _apply(_query.copyWith(sort: value));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onSubmitted,
  }) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        onSubmitted: onSubmitted,
      ),
    );
  }

  Widget _buildData(UiMessageStrings strings, AuditEventPage page) {
    final pages = page.size <= 0
        ? 1
        : (page.total / page.size).ceil().clamp(1, 1 << 30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              strings.tArgsKey(PlatformAdminKeys.paginationPageInfo, {
                'page': page.page + 1,
                'pages': pages,
                'total': page.total,
              }),
              style: PtTheme.font(12, color: PtTheme.muted),
            ),
            PlatformSecondaryButton(
              label: strings.tKey(CommonKeys.buttonPrevious),
              icon: Icons.chevron_left_rounded,
              onPressed: page.page <= 0
                  ? null
                  : () => setState(
                      () => _query = _query.copyWith(page: page.page - 1),
                    ),
            ),
            PlatformSecondaryButton(
              label: strings.tKey(CommonKeys.buttonNext),
              icon: Icons.chevron_right_rounded,
              onPressed: page.page + 1 >= pages
                  ? null
                  : () => setState(
                      () => _query = _query.copyWith(page: page.page + 1),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (page.items.isEmpty)
          PlatformEmptyView(
            icon: Icons.history_toggle_off_rounded,
            title: strings.tKey(CommonKeys.emptyTitle),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) =>
                _buildEventGrid(strings, page.items, constraints.maxWidth),
          ),
      ],
    );
  }

  Widget _buildEventGrid(
    UiMessageStrings strings,
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
            width: columns == 1 ? double.infinity : cardWidth,
            child: _buildEventCard(strings, event),
          ),
      ],
    );
  }

  Widget _buildEventCard(UiMessageStrings strings, PlatformAuditEvent event) {
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
                      '${strings.tKey(PlatformAdminKeys.tableAuditEntity)}: '
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
                label: strings.tKey(PlatformAdminKeys.tableAuditActor),
                value: event.actorRole.isEmpty ? '-' : event.actorRole,
              ),
              PlatformMetaPill(
                label: strings.tKey(CommonKeys.fieldReason),
                value: event.reasonCode.isEmpty ? '-' : event.reasonCode,
              ),
              PlatformMetaPill(
                label: strings.tKey(PlatformAdminKeys.tableAuditOccurredAt),
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
}
