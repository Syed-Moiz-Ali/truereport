import 'dart:math' as math;

import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/labels.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/template_builder_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

// F3-B Step 2, screen 7 — Workshop Template List.
//
// Figma 1280 restyle over the EXISTING template endpoints only: GET list via
// [templatesProvider] (TemplateSummary: id/name/serviceType/vehicleType/
// status/currentVersion int/itemCount) and the existing create flow (POST via
// createTemplate, then TemplateBuilderPage). All behaviour and payloads are
// preserved; only the presentation changed.
//
// Deliberately omitted per the slot sheet (no new data / locked rules):
// bay binding ("Bays Bound"), avg-completion / compliance / audit KPIs,
// custom tags, descriptions, photo-gate / cycle-time / PPE counts, DOT/ISO/
// certification wording, semver versions, JSON schema export, and any
// approval-gate ("Master Inspector") copy. The footnote keeps a neutral
// validation-lock line ([AppLocalizations.lockedByPlatform]) plus a
// version-audit action that opens the existing builder (which hosts the
// version history leading to TemplateVersionPage).
//
// Two ARB/data gaps (reported, one closed by the lead):
// - [AppLocalizations.templatesUpdatedOn] now renders per-card updated
//   labels ([TemplateSummary.updatedAt] parsed by the lead; was missing).
// - No dedicated column/empty/footer copy exists; the closest existing keys
//   (template/versions/itemsSelected/status, noResults, lockedByPlatform,
//   versionHistory) are reused and noted below.
//
// Responsive is derived per O3/P7 (Figma draws a fixed 3-column grid at
// 1280): desktop (>= [AppBreakpoints.desktop]) shows 3 columns, tablet
// (>= [AppBreakpoints.tablet]) 2 columns, narrower (phone) widths a single
// column. The list view is an [AppDataTable] over the same rows.

/// Lifecycle tone for template status chips (same mapping the list used
/// before the restyle: published = success, retired = neutral, else warn).
StatusTone _templateStatusTone(String status) => switch (status) {
  'PUBLISHED' => StatusTone.success,
  'RETIRED' => StatusTone.neutral,
  _ => StatusTone.warning,
};

/// Locale-aware count, mirroring the F3-B Step 0 intl approach used by the
/// job queue (NumberFormat.decimalPattern under the active locale).
String _formatCount(BuildContext context, int value) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(locale).format(value);
}

/// Locale date for `updatedAt` (UTC ISO from the server, shown in
/// Asia/Dubai wall-clock like the scheduled times); empty when unparseable.
String _formatUpdated(BuildContext context, String value) {
  if (value.isEmpty) {
    return '';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return '';
  }
  final utc = parsed.isUtc
      ? parsed
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
        );
  final local = utc.add(const Duration(hours: 4));
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).format(local);
}

class TemplatesTab extends ConsumerStatefulWidget {
  const TemplatesTab({super.key});

  @override
  ConsumerState<TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends ConsumerState<TemplatesTab> {
  final TextEditingController _search = TextEditingController();
  String _status = '';
  bool _grid = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(templatesProvider);
    final spacing = context.spacing;
    // Derived per O3/P7: the Figma header keeps title + search + New
    // Template in one row at 1280. On narrower widths the _titleRow inside
    // WorkshopHeader (title + action) would overflow at large text scales,
    // so the action moves below the header while search stays in it.
    final wideActions =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: spacing.lg,
            end: spacing.lg,
            top: spacing.lg,
          ),
          child: WorkshopHeader(
            title: l10n.templateListTitle,
            search: AppTextField(
              key: const Key('templates-search'),
              controller: _search,
              label: l10n.search,
              hint: l10n.search,
              prefixIcon: const Icon(Icons.search),
              onChanged: (_) => setState(() {}),
            ),
            actions: [
              if (wideActions) _newTemplateButton(ref),
            ],
          ),
        ),
        if (!wideActions)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: spacing.lg,
              end: spacing.lg,
              top: spacing.sm,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _newTemplateButton(ref),
            ),
          ),
        templates.when(
          loading: () => Padding(
            padding: EdgeInsetsDirectional.all(spacing.lg),
            child: const LoadingSkeleton(lines: 4),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: EdgeInsetsDirectional.all(spacing.lg),
              child: ErrorState(
                title: l10n.error,
                body: l10n.genericError,
                onRetry: () => ref.invalidate(templatesProvider),
                retryLabel: l10n.retryAction,
              ),
            ),
          ),
          data: (items) {
            final query = _search.text.trim().toLowerCase();
            final searched = query.isEmpty
                ? items
                : items.where((template) {
                    final statusLabel = contentStatusLabel(
                      l10n,
                      template.status,
                    ).toLowerCase();
                    return template.name.toLowerCase().contains(query) ||
                        template.serviceType.toLowerCase().contains(query) ||
                        template.status.toLowerCase().contains(query) ||
                        statusLabel.contains(query);
                  }).toList(growable: false);
            final filtered = _status.isEmpty
                ? searched
                : searched
                      .where((template) => template.status == _status)
                      .toList(growable: false);
            // KPI is client-side: ΣitemCount over the search-scoped snapshot
            // (status-unfiltered), mirroring the queue chip-count approach.
            final total = searched.fold<int>(
              0,
              (sum, template) => sum + template.itemCount,
            );
            return Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(templatesProvider),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsetsDirectional.all(spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // KPI row: the single real metric. The Figma
                      // timing/compliance/audit cards are data gaps.
                      WorkshopMetric(
                        value: _formatCount(context, total),
                        label: l10n.templateTotalCheckpoints,
                        icon: Icons.dashboard_customize_outlined,
                      ),
                      SizedBox(height: spacing.sm),
                      // Filter chips from the real statuses (+ counts) and
                      // the Figma grid/list toggle. A Wrap (not a fixed Row)
                      // keeps derived phone widths overflow-free.
                      Wrap(
                        spacing: spacing.sm,
                        runSpacing: spacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _filter(context, l10n, '', searched),
                          for (final status in _statusOrder(items))
                            _filter(context, l10n, status, searched),
                          SizedBox(
                            width: 240,
                            child: AppSegmentedControl<bool>(
                              key: const Key('templates-view-toggle'),
                              segments: [
                                AppSegment(
                                  value: true,
                                  label: l10n.templateViewGrid,
                                  icon: Icons.grid_view,
                                ),
                                AppSegment(
                                  value: false,
                                  label: l10n.templateViewList,
                                  icon: Icons.list,
                                ),
                              ],
                              selected: _grid,
                              onChanged: (value) =>
                                  setState(() => _grid = value),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      if (items.isEmpty)
                        EmptyState(
                          title: l10n.noResults,
                          body: l10n.newTemplate,
                          icon: Icons.dashboard_customize_outlined,
                          action: AppButton(
                            label: l10n.newTemplate,
                            onPressed: () => _create(context, ref),
                            variant: AppButtonVariant.tonal,
                          ),
                        )
                      else if (filtered.isEmpty)
                        EmptyState(
                          title: l10n.noResults,
                          body: l10n.newTemplate,
                          icon: Icons.dashboard_customize_outlined,
                        )
                      else if (_grid)
                        _gridRows(context, ref, l10n, filtered)
                      else
                        _listTable(context, ref, l10n, filtered),
                      SizedBox(height: spacing.lg),
                      _footnote(context, ref, l10n, filtered),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _filter(
    BuildContext context,
    AppLocalizations l10n,
    String value,
    List<TemplateSummary> scoped,
  ) {
    final count = value.isEmpty
        ? scoped.length
        : scoped.where((template) => template.status == value).length;
    final label = value.isEmpty
        ? l10n.filterAll
        : contentStatusLabel(l10n, value);
    return AppSelectableText(
      label: '$label (${_formatCount(context, count)})',
      selected: _status == value,
      onTap: () => setState(() => _status = value),
    );
  }

  /// Stable chip order: lifecycle order first, then any other status codes
  /// as they appear.
  List<String> _statusOrder(List<TemplateSummary> scoped) {
    const lifecycle = ['PUBLISHED', 'DRAFT', 'RETIRED'];
    final present = scoped.map((template) => template.status).toSet();
    return [
      for (final status in lifecycle)
        if (present.contains(status)) status,
      for (final status in present)
        if (!lifecycle.contains(status)) status,
    ];
  }

  Widget _gridRows(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<TemplateSummary> filtered,
  ) {
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Derived per O3/P7: Figma draws a fixed 3-column grid at 1280
        // (desktop breakpoint). Tablet widths collapse to 2 columns and
        // narrower (phone) widths to a single column.
        final columns = constraints.maxWidth >= AppBreakpoints.desktop
            ? 3
            : constraints.maxWidth >= AppBreakpoints.tablet
            ? 2
            : 1;
        final cells = <Widget>[
          for (final template in filtered) _card(context, ref, l10n, template),
          _CreateTemplateTile(onTap: () => _create(context, ref)),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < cells.length; start += columns)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: start + columns < cells.length ? spacing.md : 0,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < columns; index++)
                        if (start + index < cells.length) ...[
                          if (index > 0) SizedBox(width: spacing.md),
                          Expanded(child: cells[start + index]),
                        ] else ...[
                          if (index > 0) SizedBox(width: spacing.md),
                          const Expanded(child: SizedBox.shrink()),
                        ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _card(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    TemplateSummary template,
  ) {
    // Integer version only (server currentVersion int): "v2", never semver.
    // Closest existing ARB key for the item count (no per-card count key).
    final versionLabel =
        'v${template.currentVersion ?? '-'} · '
        '${_formatCount(context, template.itemCount)} ${l10n.itemsSelected}';
    return WorkshopTemplateCard(
      key: Key('template-${template.id}'),
      title: template.name,
      versionLabel: versionLabel,
      // Tag chip rendered from the real serviceType only (custom tags are a
      // data gap); description / photo-gate / cycle / PPE lines omitted.
      requirement: StatusChip(
        label: template.serviceType,
        tone: StatusTone.neutral,
      ),
      status: StatusChip(
        label: contentStatusLabel(l10n, template.status),
        tone: _templateStatusTone(template.status),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_formatUpdated(context, template.updatedAt).isNotEmpty)
            Flexible(
              child: Text(
                l10n.templatesUpdatedOn(
                  _formatUpdated(context, template.updatedAt),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          AppButton(
            label: l10n.edit,
            variant: AppButtonVariant.tonal,
            onPressed: () => _open(context, ref, template.id),
          ),
        ],
      ),
      onTap: () => _open(context, ref, template.id),
    );
  }

  Widget _listTable(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<TemplateSummary> filtered,
  ) {
    // Column headers reuse the closest existing ARB keys (no list-view copy
    // was drawn or approved): template / serviceType / versions /
    // itemsSelected / status.
    Text cell(String value, {TextDirection? direction}) => Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: direction,
    );
    return AppDataTable<TemplateSummary>(
      rows: filtered,
      onRowTap: (template) => _open(context, ref, template.id),
      rowSemanticLabelBuilder: (template, _) => template.name,
      columns: [
        AppDataColumn<TemplateSummary>(
          label: l10n.template,
          cellBuilder: (_, template, _) => cell(template.name),
        ),
        AppDataColumn<TemplateSummary>(
          label: l10n.serviceType,
          cellBuilder: (_, template, _) => cell(template.serviceType),
        ),
        AppDataColumn<TemplateSummary>(
          label: l10n.versions,
          cellBuilder: (_, template, _) => cell(
            'v${template.currentVersion ?? '-'}',
            direction: TextDirection.ltr,
          ),
        ),
        AppDataColumn<TemplateSummary>(
          label: l10n.itemsSelected,
          numeric: true,
          cellBuilder: (_, template, _) => cell(
            _formatCount(context, template.itemCount),
            direction: TextDirection.ltr,
          ),
        ),
        AppDataColumn<TemplateSummary>(
          label: l10n.status,
          cellBuilder: (_, template, _) => StatusChip(
            label: contentStatusLabel(l10n, template.status),
            tone: _templateStatusTone(template.status),
          ),
        ),
      ],
    );
  }

  /// Neutral footnote: validation-lock wording WITHOUT any approval-gate
  /// ("Master Inspector" sign-off is an O6 conflict — never rendered) plus
  /// a version-audit action. JSON schema export has no endpoint — omitted.
  /// The audit action opens the existing builder for the first visible
  /// template, which hosts the version history leading to
  /// TemplateVersionPage (the only versions UI reachable with list data).
  Widget _footnote(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<TemplateSummary> filtered,
  ) {
    final spacing = context.spacing;
    final lockLine = Row(
      children: [
        Icon(
          Icons.lock_outline,
          size: context.sizing.iconMd,
          color: context.colors.onSurfaceVariant,
        ),
        SizedBox(width: spacing.sm),
        Expanded(child: Text(l10n.lockedByPlatform)),
      ],
    );
    final audit = filtered.isEmpty
        ? null
        : AppButton(
            label: l10n.versionHistory,
            variant: AppButtonVariant.tonal,
            onPressed: () => _open(context, ref, filtered.first.id),
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.card),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(spacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Derived per O3/P7: Figma single row at 1280; narrow widths
            // stack the audit action below the lock line so the fixed-size
            // button can never overflow at large text scales.
            if (constraints.maxWidth >= AppBreakpoints.tablet &&
                audit != null) {
              return Row(
                children: [
                  Expanded(child: lockLine),
                  SizedBox(width: spacing.md),
                  audit,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                lockLine,
                if (audit != null) ...[
                  SizedBox(height: spacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: audit,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _newTemplateButton(WidgetRef ref) {
    // Built via context at the call site (header or derived phone slot).
    return Builder(
      builder: (context) => AppButton(
        label: AppLocalizations.of(context).newTemplate,
        onPressed: () => _create(context, ref),
        icon: Icons.add,
      ),
    );
  }

  // Existing create flow preserved verbatim (dialog fields + POST payload +
  // builder navigation + error handling).
  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final description = TextEditingController();
    final serviceType = TextEditingController(text: 'FULL');
    final vehicleType = TextEditingController(text: 'CAR');
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newTemplate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: name, label: l10n.templateName),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: description,
                label: l10n.templateDescription,
                maxLines: 2,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: serviceType, label: l10n.serviceType),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: vehicleType, label: l10n.vehicleType),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(false),
            variant: AppButtonVariant.text,
          ),
          AppButton(
            label: l10n.create,
            onPressed: () async {
              try {
                final template = await ref
                    .read(adminApiProvider)
                    .createTemplate(
                      name: name.text.trim(),
                      description: description.text.trim(),
                      serviceType: serviceType.text.trim(),
                      vehicleType: vehicleType.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                  ref.invalidate(templatesProvider);
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TemplateBuilderPage(templateId: template.id),
                    ),
                  );
                  ref.invalidate(templatesProvider);
                }
              } on Object {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
                }
              }
            },
          ),
        ],
      ),
    );
    name.dispose();
    description.dispose();
    serviceType.dispose();
    vehicleType.dispose();
    if (created != true) {
      return;
    }
  }

  // Existing open flow preserved: tap opens the template builder.
  void _open(BuildContext context, WidgetRef ref, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateBuilderPage(templateId: id),
      ),
    );
  }
}

/// Dashed create tile closing the Figma grid (the spec maps it to the
/// states EmptyState/add tile). Runs the existing create flow; no thresholds
/// or trigger copy (no new capabilities per O7).
class _CreateTemplateTile extends StatefulWidget {
  const _CreateTemplateTile({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CreateTemplateTile> createState() => _CreateTemplateTileState();
}

class _CreateTemplateTileState extends State<_CreateTemplateTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final radius = BorderRadius.circular(context.radii.cardLarge);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 160),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          canRequestFocus: true,
          onFocusChange: (value) => setState(() => _focused = value),
          borderRadius: radius,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: context.colors.onSurfaceVariant,
              radius: context.radii.cardLarge,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(spacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: context.sizing.iconLg,
                      color: context.colors.onSurfaceVariant,
                    ),
                    SizedBox(height: spacing.sm),
                    Text(
                      l10n.newTemplate,
                      textAlign: TextAlign.center,
                      style: context.texts.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: l10n.newTemplate,
      child: AnimatedContainer(
        duration: context.motionDuration(context.motion.fast),
        curve: context.motion.enterCurve,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _focused ? [context.shadows.focus] : null,
        ),
        child: content,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 4.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            math.min(distance + dash, metric.length),
          ),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
