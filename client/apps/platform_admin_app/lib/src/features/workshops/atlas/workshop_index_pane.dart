import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_models.dart';
import '../../../platform_theme.dart';
import '../workshop_status.dart';
import 'atlas_ui.dart';

/// Left-hand index of the Atlas workspace: search, status filters, and one
/// scannable row per workshop.
class WorkshopIndexPane extends StatelessWidget {
  const WorkshopIndexPane({
    super.key,
    required this.strings,
    required this.workshops,
    required this.filtered,
    required this.searchController,
    required this.query,
    required this.statuses,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onOpen,
    required this.onClearFilters,
    this.selectedId,
    this.loading = false,
    this.inline = false,
  });

  final UiMessageStrings strings;
  final List<HierarchyWorkshop> workshops;
  final List<HierarchyWorkshop> filtered;
  final TextEditingController searchController;
  final String query;
  final List<String> statuses;
  final String statusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<HierarchyWorkshop> onOpen;
  final VoidCallback onClearFilters;
  final String? selectedId;
  final bool loading;
  final bool inline;

  bool get _hasFilters => query.trim().isNotEmpty || statusFilter.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.tKey(PlatformAdminKeys.navWorkshops),
                  style: Atlas.eyebrow,
                ),
              ),
              Text(
                strings.tArgsKey(PlatformAdminKeys.pageWorkshopsResultCount, {
                  'count': filtered.length,
                }),
                style: Atlas.text(
                  11,
                  weight: FontWeight.w600,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AtlasSearchField(
            controller: searchController,
            hint: strings.tKey(PlatformAdminKeys.filterWorkshopsSearch),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: strings.tKey(CommonKeys.filterAll),
                  count: workshops.length,
                  selected: statusFilter.isEmpty,
                  onTap: () => onStatusChanged(''),
                ),
                for (final status in statuses) ...[
                  const SizedBox(width: 6),
                  _FilterPill(
                    label: workshopStatusLabel(strings, status),
                    count: workshops
                        .where((w) => w.status.toUpperCase() == status)
                        .length,
                    selected: statusFilter == status,
                    onTap: () => onStatusChanged(status),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final body = loading
        ? const AtlasSkeletonRows(rows: 6)
        : filtered.isEmpty
        ? AtlasEmpty(
            icon: Icons.storefront_outlined,
            title: strings.tKey(
              workshops.isEmpty
                  ? PlatformAdminKeys.emptyWorkshopsTitle
                  : PlatformAdminKeys.emptyWorkshopsFilteredTitle,
            ),
            body: strings.tKey(
              workshops.isEmpty
                  ? PlatformAdminKeys.emptyWorkshopsBody
                  : PlatformAdminKeys.emptyWorkshopsFilteredBody,
            ),
            actionLabel: _hasFilters
                ? strings.tKey(PlatformAdminKeys.buttonClearFilters)
                : null,
            onAction: _hasFilters ? onClearFilters : null,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < filtered.length; i++)
                WorkshopIndexRow(
                  strings: strings,
                  workshop: filtered[i],
                  selected: filtered[i].id == selectedId,
                  last: i == filtered.length - 1,
                  onTap: () => onOpen(filtered[i]),
                ),
            ],
          );

    final footer = !inline && !loading && filtered.isNotEmpty
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Atlas.neutralTint,
              border: Border(top: BorderSide(color: PtTheme.border)),
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final status in statuses)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: workshopTone(status) == AtlasTone.positive
                              ? PtTheme.deepGreen
                              : PtTheme.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        workshopStatusLabel(strings, status),
                        style: Atlas.text(10.5, color: PtTheme.muted),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${workshops.where((w) => w.status.toUpperCase() == status).length}',
                        style: Atlas.text(
                          10.5,
                          weight: FontWeight.w700,
                          tabular: true,
                          color: PtTheme.muted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          )
        : null;

    return AtlasSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(height: 1, color: PtTheme.border),
          if (inline)
            body
          else
            Expanded(child: SingleChildScrollView(child: body)),
          ?footer,
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      child: Material(
        color: selected ? Atlas.accentTint : PtTheme.white,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: Atlas.pillHeight,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? Atlas.accentTint : PtTheme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Atlas.text(
                    11.5,
                    weight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? PtTheme.deepGreen : PtTheme.muted,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: Atlas.text(
                    10.5,
                    weight: FontWeight.w700,
                    tabular: true,
                    color: selected ? PtTheme.deepGreen : PtTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkshopIndexRow extends StatefulWidget {
  const WorkshopIndexRow({
    super.key,
    required this.strings,
    required this.workshop,
    required this.selected,
    required this.last,
    required this.onTap,
  });

  final UiMessageStrings strings;
  final HierarchyWorkshop workshop;
  final bool selected;
  final bool last;
  final VoidCallback onTap;

  @override
  State<WorkshopIndexRow> createState() => _WorkshopIndexRowState();
}

class _WorkshopIndexRowState extends State<WorkshopIndexRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final workshop = widget.workshop;
    final inactive = workshop.status.toUpperCase() != 'ACTIVE';
    final capacity = workshop.assignedCapacityPercent;
    final tone = capacity >= 90 ? PtTheme.amber : PtTheme.deepGreen;
    final percentTone = capacity >= 90 ? PtTheme.gold : PtTheme.deepGreen;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: workshop.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: IntrinsicHeight(
              child: AnimatedContainer(
                duration: Atlas.fast,
                constraints: const BoxConstraints(minHeight: 76),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? Atlas.accentTint.withValues(alpha: 0.6)
                      : _hover
                      ? Atlas.neutralTint.withValues(alpha: 0.55)
                      : Colors.transparent,
                  border: widget.last
                      ? null
                      : const Border(bottom: BorderSide(color: PtTheme.border)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3,
                      color: widget.selected
                          ? PtTheme.deepGreen
                          : Colors.transparent,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 3,
                              height: 14 + (capacity.clamp(0, 100) * 0.2),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: inactive ? PtTheme.border : tone,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AtlasMonogram(
                              name: workshop.name,
                              size: 38,
                              muted: inactive,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    workshop.name,
                                    style: Atlas.text(
                                      13.5,
                                      weight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Tooltip(
                                    message: workshop.branchName ?? '—',
                                    child: Text(
                                      (workshop.branchName ?? '').trim().isEmpty
                                          ? '—'
                                          : workshop.branchName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Atlas.text(
                                        11.5,
                                        color: PtTheme.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  inactive && capacity == 0
                                      ? '—'
                                      : '$capacity%',
                                  style: Atlas.text(
                                    13.5,
                                    weight: FontWeight.w800,
                                    tabular: true,
                                    color: inactive && capacity == 0
                                        ? PtTheme.muted
                                        : percentTone,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: inactive
                                            ? PtTheme.muted
                                            : PtTheme.deepGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      workshopStatusLabel(
                                        widget.strings,
                                        workshop.status,
                                      ),
                                      maxLines: 1,
                                      style: Atlas.text(
                                        10,
                                        weight: FontWeight.w600,
                                        color: PtTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
