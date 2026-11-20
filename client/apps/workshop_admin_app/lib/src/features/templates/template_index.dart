import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/features/templates/template_create_page.dart';
import 'package:workshop_admin_app/src/features/templates/template_route_page.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_clock.dart';

/// Template index â€” one surface, hairline rows, status pills.
///
/// Reads `templatesProvider` only (name, service, vehicle, status, version,
/// item count, updatedAt). Search and status filtering happen client-side over
/// the same snapshot; no counts or compliance metrics are derived.
class TemplateIndex extends ConsumerStatefulWidget {
  const TemplateIndex({super.key});

  @override
  ConsumerState<TemplateIndex> createState() => _TemplateIndexState();
}

class _TemplateIndexState extends ConsumerState<TemplateIndex> {
  final TextEditingController _search = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final templates = ref.watch(templatesProvider);
    final templateStatuses = ref.watch(statusesProvider('template')).value;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: ws.pagePadding(constraints.maxWidth),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
              child: templates.when(
                loading: () => const _IndexSkeleton(),
                error: (error, _) => _IndexError(
                  onRetry: () => ref.invalidate(templatesProvider),
                ),
                data: (all) =>
                    _content(all, constraints.maxWidth, templateStatuses),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(
    List<TemplateSummary> all,
    double width,
    List<ReferenceRecord>? templateStatuses,
  ) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final wide = width >= 900;
    final filtered = _filtered(all, templateStatuses);
    final filters = <({String code, String label})>[
      (code: '', label: t(WorkshopAdminKeys.filterAll)),
      for (final record in templateStatuses ?? const <ReferenceRecord>[])
        if (record.selectable)
          (
            code: record.code,
            label:
                referenceLabelFor(record) ?? humanizeReferenceCode(record.code),
          ),
    ];
    final counts = <String, int>{
      '': all.length,
      for (final filter in filters.skip(1))
        filter.code: all.where((t) => t.status == filter.code).length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (width < 520) ...[
          Text(
            t(WorkshopAdminKeys.templateListTitle),
            style: ws.pageTitle.copyWith(
              fontSize: 26,
              letterSpacing: -0.6,
              color: ws.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t(WorkshopAdminKeys.templatesSubtitle),
            style: ws.meta.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TemplatePillButton(
              label: t(WorkshopAdminKeys.newTemplate),
              icon: Icons.add,
              onPressed: () => _create(),
            ),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(WorkshopAdminKeys.templateListTitle),
                      style: ws.pageTitle.copyWith(
                        fontSize: 30,
                        letterSpacing: -0.6,
                        color: ws.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t(WorkshopAdminKeys.templatesSubtitle),
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ),
              ),
              TemplatePillButton(
                label: t(WorkshopAdminKeys.newTemplate),
                icon: Icons.add,
                onPressed: () => _create(),
              ),
            ],
          ),
        const SizedBox(height: 20),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: WorkshopSearchField(
              key: const Key('templates-search'),
              controller: _search,
              hint: t(WorkshopAdminKeys.search),
              semanticLabel: t(WorkshopAdminKeys.search),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in filters) ...[
                TemplatePillChip(
                  label: entry.label,
                  count: counts[entry.code] ?? 0,
                  selected: _status == entry.code,
                  onTap: () => setState(() => _status = entry.code),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (all.isEmpty)
          _EmptyIndex(onCreate: _create)
        else if (filtered.isEmpty)
          _NoResults(
            onClear: () => setState(() {
              _search.clear();
              _status = '';
            }),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: ws.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ws.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < filtered.length; i++)
                  _row(filtered[i], i == 0, wide),
              ],
            ),
          ),
        const SizedBox(height: 28),
      ],
    );
  }

  List<TemplateSummary> _filtered(
    List<TemplateSummary> all,
    List<ReferenceRecord>? templateStatuses,
  ) {
    final query = _search.text.trim().toLowerCase();
    return all
        .where((template) {
          if (_status.isNotEmpty && template.status != _status) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          final statusLabel = referenceStatusText(
            templateStatuses,
            template.status,
          );
          return template.name.toLowerCase().contains(query) ||
              template.serviceType.toLowerCase().contains(query) ||
              (template.vehicleType ?? '').toLowerCase().contains(query) ||
              statusLabel.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Widget _row(TemplateSummary template, bool first, bool wide) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    final updated = WorkshopClock.formatDate(context, template.updatedAt);
    final meta = [
      template.serviceType,
      if ((template.vehicleType ?? '').isNotEmpty) template.vehicleType!,
      t(WorkshopAdminKeys.templateItemsCount, {'count': template.itemCount}),
      if (template.currentVersion != null) 'v${template.currentVersion}',
    ].join(' Â· ');
    return _RowHover(
      onTap: () => _open(template.id),
      child: Container(
        key: Key('template-${template.id}'),
        padding: EdgeInsetsDirectional.fromSTEB(16, 14, wide ? 16 : 12, 14),
        decoration: BoxDecoration(
          border: first
              ? null
              : BorderDirectional(top: BorderSide(color: ws.border)),
        ),
        child: Row(
          crossAxisAlignment: wide
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(top: wide ? 0 : 2),
              child: const TemplateGlyph(size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: ws.body.copyWith(
                      color: ws.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    wide
                        ? meta
                        : [
                            template.serviceType,
                            if ((template.vehicleType ?? '').isNotEmpty)
                              template.vehicleType!,
                          ].join(' Â· '),
                    maxLines: wide ? 1 : 2,
                    overflow: wide ? TextOverflow.ellipsis : null,
                    style: ws.meta.copyWith(color: ws.muted),
                  ),
                  if (!wide) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TemplateStatusPill(status: template.status),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            [
                              t(WorkshopAdminKeys.templateItemsCount, {
                                'count': template.itemCount,
                              }),
                              if (template.currentVersion != null)
                                'v${template.currentVersion}',
                            ].join(' Â· '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ws.meta.copyWith(color: ws.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (wide) ...[
              const SizedBox(width: 12),
              TemplateStatusPill(status: template.status),
              const SizedBox(width: 18),
              SizedBox(
                width: 96,
                child: Text(
                  updated,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Padding(
              padding: EdgeInsetsDirectional.only(top: wide ? 0 : 6),
              child: Icon(Icons.chevron_right, size: 18, color: ws.muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<TemplateDetail>(
      MaterialPageRoute<TemplateDetail>(
        builder: (_) => const TemplateCreatePage(),
      ),
    );
    if (created == null || !mounted) {
      return;
    }
    ref.invalidate(templatesProvider);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TemplateBuilderPage(templateId: created.id, autoDraft: true),
      ),
    );
    ref.invalidate(templatesProvider);
  }

  void _open(String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateBuilderPage(templateId: id),
      ),
    );
  }
}

class _RowHover extends StatefulWidget {
  const _RowHover({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_RowHover> createState() => _RowHoverState();
}

class _RowHoverState extends State<_RowHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: ColoredBox(
          color: _hover ? context.ws.canvas : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

class _EmptyIndex extends StatelessWidget {
  const _EmptyIndex({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 44, 24, 44),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        children: [
          const TemplateGlyph(size: 52),
          const SizedBox(height: 16),
          Text(
            t(WorkshopAdminKeys.templatesEmptyTitle),
            textAlign: TextAlign.center,
            style: ws.sectionTitle.copyWith(color: ws.ink),
          ),
          const SizedBox(height: 6),
          Text(
            t(WorkshopAdminKeys.templatesEmptyBody),
            textAlign: TextAlign.center,
            style: ws.body.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 18),
          TemplatePillButton(
            label: t(WorkshopAdminKeys.newTemplate),
            icon: Icons.add,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        children: [
          Text(
            t(WorkshopAdminKeys.noResults),
            style: ws.body.copyWith(color: ws.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TemplatePillButton(
            label: t(WorkshopAdminKeys.jobsClearFilters),
            variant: TemplatePillVariant.outline,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _IndexError extends StatelessWidget {
  const _IndexError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final t = UiStrings.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 34, 24, 34),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.priority_high_rounded, size: 20, color: ws.danger),
          const SizedBox(height: 12),
          Text(
            t(WorkshopAdminKeys.error),
            style: ws.sectionTitle.copyWith(color: ws.ink),
          ),
          const SizedBox(height: 6),
          Text(
            t(WorkshopAdminKeys.commonLoadFailed),
            style: ws.body.copyWith(color: ws.muted),
          ),
          const SizedBox(height: 16),
          TemplatePillButton(
            label: t(WorkshopAdminKeys.retryAction),
            icon: Icons.refresh,
            variant: TemplatePillVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _IndexSkeleton extends StatefulWidget {
  const _IndexSkeleton();

  @override
  State<_IndexSkeleton> createState() => _IndexSkeletonState();
}

class _IndexSkeletonState extends State<_IndexSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulse.duration = const Duration(milliseconds: 1100);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 0.55;
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ws.border,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.42,
        end: 0.95,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(children: [bar(240, 26), const Spacer(), bar(128, 42)]),
          const SizedBox(height: 22),
          bar(360, 46),
          const SizedBox(height: 14),
          Row(children: [bar(56, 32), const SizedBox(width: 8), bar(96, 32)]),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: ws.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ws.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < 6; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      14,
                      16,
                      14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: ws.border,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: bar(220, 12)),
                        bar(72, 22),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
