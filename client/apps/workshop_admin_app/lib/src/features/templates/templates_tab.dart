import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/templates/template_builder_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

// F3-B Step 2, screen 7 — Workshop Template List.
//
// Restyle over the EXISTING template endpoints only: GET list via
// [templatesProvider] (TemplateSummary: id/name/serviceType/vehicleType/
// status/currentVersion int/itemCount/updatedAt) and the existing create flow
// (POST via createTemplate, then TemplateBuilderPage). All behaviour and
// payloads are preserved.
//
// Deliberately omitted per the slot sheet (no new data / locked rules):
// bay binding ("Bays Bound"), avg-completion / compliance / audit KPIs, custom
// tags, descriptions, photo-gate / cycle-time / PPE counts, DOT/ISO/
// certification wording, semver versions, JSON schema export, approval-gate
// ("Master Inspector") copy and the grid/list toggle.
//
// One summary strip with three real metrics (templates, published, ΣitemCount),
// one column of full-width template rows and one subtle validation-lock note.
// Each row exposes the whole-card builder navigation plus a single
// "Version history" secondary action (history lives in the builder).
//
// ARB/data notes: [AppLocalizations.templatesUpdatedOn] renders the server
// `updatedAt`; the status labels reuse [contentStatusLabel]; the "Templates"
// metric label reuses [AppLocalizations.templatesTab] (no dedicated key was
// added in this phase).

/// Lifecycle tone for template status badges (published = success, retired =
/// neutral, else warning).
WorkshopStatusTone _templateStatusTone(String status) => switch (status) {
  'PUBLISHED' => WorkshopStatusTone.success,
  'RETIRED' => WorkshopStatusTone.neutral,
  _ => WorkshopStatusTone.warning,
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final templates = ref.watch(templatesProvider);
    final items = templates.value;
    final searched = items == null ? null : _searched(items, l10n);

    return WorkshopPageScroll(
      children: [
        WorkshopPageHeader(
          title: l10n.templateListTitle,
          subtitle: l10n.templatesSubtitle,
          primaryAction: WorkshopButton(
            label: l10n.newTemplate,
            icon: Icons.add,
            onPressed: () => _create(context, ref),
          ),
        ),
        SizedBox(height: spacing.lg),
        WorkshopToolbar(
          search: WorkshopSearchField(
            key: const Key('templates-search'),
            controller: _search,
            hint: l10n.search,
            semanticLabel: l10n.search,
            onChanged: (_) => setState(() {}),
          ),
          filters: [
            _filter(l10n, '', l10n.filterAll, searched),
            _filter(l10n, 'PUBLISHED', l10n.published, searched),
            _filter(l10n, 'DRAFT', l10n.draft, searched),
            _filter(l10n, 'RETIRED', l10n.retired, searched),
          ],
        ),
        SizedBox(height: spacing.xl),
        templates.when(
          loading: () => const WorkshopSkeleton(lines: 6, card: true),
          error: (error, _) => WorkshopErrorState(
            title: l10n.error,
            body: l10n.genericError,
            retryLabel: l10n.retryAction,
            onRetry: () => ref.invalidate(templatesProvider),
          ),
          data: (all) => _content(context, ref, l10n, all),
        ),
      ],
    );
  }

  List<TemplateSummary> _searched(
    List<TemplateSummary> items,
    AppLocalizations l10n,
  ) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) {
      return items;
    }
    return items
        .where((template) {
          final statusLabel = contentStatusLabel(
            l10n,
            template.status,
          ).toLowerCase();
          return template.name.toLowerCase().contains(query) ||
              template.serviceType.toLowerCase().contains(query) ||
              template.status.toLowerCase().contains(query) ||
              statusLabel.contains(query);
        })
        .toList(growable: false);
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<TemplateSummary> all,
  ) {
    final spacing = context.spacing;
    final searched = _searched(all, l10n);
    final filtered = _status.isEmpty
        ? searched
        : searched
              .where((template) => template.status == _status)
              .toList(growable: false);
    final published = searched
        .where((template) => template.status == 'PUBLISHED')
        .length;
    // KPI is client-side: ΣitemCount over the search-scoped snapshot
    // (status-unfiltered), mirroring the queue chip-count approach.
    final checkpoints = searched.fold<int>(
      0,
      (sum, template) => sum + template.itemCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopCard(
          padding: EdgeInsetsDirectional.zero,
          child: WorkshopMetricStrip(
            items: [
              WorkshopMetric(
                value: _formatCount(context, searched.length),
                label: l10n.templatesTab,
              ),
              WorkshopMetric(
                value: _formatCount(context, published),
                label: l10n.published,
              ),
              WorkshopMetric(
                value: _formatCount(context, checkpoints),
                label: l10n.templateTotalCheckpoints,
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        if (all.isEmpty)
          WorkshopEmptyState(
            title: l10n.templatesEmptyTitle,
            body: l10n.templatesEmptyBody,
            icon: Icons.dashboard_customize_outlined,
            action: WorkshopButton(
              label: l10n.newTemplate,
              icon: Icons.add,
              onPressed: () => _create(context, ref),
            ),
          )
        else if (filtered.isEmpty)
          WorkshopEmptyState(
            title: l10n.noResults,
            body: l10n.templatesEmptyBody,
            icon: Icons.dashboard_customize_outlined,
          )
        else
          _list(context, ref, l10n, filtered),
        SizedBox(height: spacing.lg),
        WorkshopInlineNote(
          icon: Icons.lock_outline,
          text: l10n.lockedByPlatform,
        ),
      ],
    );
  }

  /// One column of full-width cards at every width. Each card reads as a
  /// deliberate row: name + meta on the leading side, status and the single
  /// secondary action trailing and vertically centred (stacked on phones).
  Widget _list(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<TemplateSummary> filtered,
  ) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < filtered.length; index++)
          Padding(
            padding: EdgeInsetsDirectional.only(
              bottom: index < filtered.length - 1 ? spacing.md : 0,
            ),
            child: _card(context, ref, l10n, filtered[index]),
          ),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    TemplateSummary template,
  ) {
    final ws = context.ws;
    final spacing = context.spacing;
    final updated = _formatUpdated(context, template.updatedAt);
    final status = WorkshopStatusBadge(
      label: contentStatusLabel(l10n, template.status),
      tone: _templateStatusTone(template.status),
    );
    final history = WorkshopButton(
      label: l10n.versionHistory,
      variant: WorkshopButtonVariant.ghost,
      onPressed: () => _open(context, ref, template.id),
    );
    return WorkshopCard(
      key: Key('template-${template.id}'),
      onTap: () => _open(context, ref, template.id),
      padding: EdgeInsetsDirectional.all(spacing.lg),
      semanticLabel: template.name,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(template.name, style: ws.cardTitle.copyWith(color: ws.ink)),
              SizedBox(height: spacing.xs),
              Text(
                'v${template.currentVersion ?? '-'} · '
                '${l10n.templateItemsCount(template.itemCount)}',
                style: ws.meta.copyWith(color: ws.muted),
              ),
              SizedBox(height: spacing.xxs),
              Text(
                '${l10n.serviceType}: ${template.serviceType}',
                style: ws.meta.copyWith(color: ws.muted),
              ),
              if (updated.isNotEmpty) ...[
                SizedBox(height: spacing.xxs),
                Text(
                  l10n.templatesUpdatedOn(updated),
                  style: ws.meta.copyWith(color: ws.muted),
                ),
              ],
            ],
          );
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                details,
                SizedBox(height: spacing.md),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: spacing.sm,
                  runSpacing: spacing.sm,
                  children: [status, history],
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: details),
              SizedBox(width: spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  status,
                  SizedBox(height: spacing.sm),
                  history,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filter(
    AppLocalizations l10n,
    String value,
    String label,
    List<TemplateSummary>? scoped,
  ) {
    final count = scoped == null
        ? null
        : value.isEmpty
        ? scoped.length
        : scoped.where((template) => template.status == value).length;
    return WorkshopFilterChip(
      label: label,
      count: count,
      selected: _status == value,
      onTap: () => setState(() => _status = value),
    );
  }

  // Existing create flow preserved (dialog fields + POST payload + builder
  // navigation + error handling). Controller ownership lives inside the
  // dialog state so they are disposed only when the route is gone.
  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final template = await showDialog<TemplateDetail>(
      context: context,
      builder: (_) => const _CreateTemplateDialog(),
    );
    if (template == null || !context.mounted) {
      return;
    }
    ref.invalidate(templatesProvider);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateBuilderPage(templateId: template.id),
      ),
    );
    ref.invalidate(templatesProvider);
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

/// Create-template dialog. Owns its controllers (disposed with the route) and
/// keeps the existing payload: trimmed name/description/serviceType/
/// vehicleType, then POST via `adminApiProvider.createTemplate`.
class _CreateTemplateDialog extends ConsumerStatefulWidget {
  const _CreateTemplateDialog();

  @override
  ConsumerState<_CreateTemplateDialog> createState() =>
      _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends ConsumerState<_CreateTemplateDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _serviceType = TextEditingController(text: 'FULL');
  final _vehicleType = TextEditingController(text: 'CAR');

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _serviceType.dispose();
    _vehicleType.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    try {
      final template = await ref
          .read(adminApiProvider)
          .createTemplate(
            name: _name.text.trim(),
            description: _description.text.trim(),
            serviceType: _serviceType.text.trim(),
            vehicleType: _vehicleType.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop(template);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.newTemplate),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: _name, label: l10n.templateName),
            SizedBox(height: context.spacing.sm),
            AppTextField(
              controller: _description,
              label: l10n.templateDescription,
              maxLines: 2,
            ),
            SizedBox(height: context.spacing.sm),
            AppTextField(controller: _serviceType, label: l10n.serviceType),
            SizedBox(height: context.spacing.sm),
            AppTextField(controller: _vehicleType, label: l10n.vehicleType),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(),
          variant: AppButtonVariant.text,
        ),
        AppButton(label: l10n.create, onPressed: _submit),
      ],
    );
  }
}
