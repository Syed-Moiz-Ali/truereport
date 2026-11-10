import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/labels.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/templates/template_version_page.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Screen 8 — Template Builder workbench.
///
/// Pixel-perfect desktop layout matching Figma screen `08_8._Template_Builder` (node `1:1882`, 1280 x 1251.5).
/// Features:
/// - 96px left navigation rail
/// - 80px floating top header bar with search & profile
/// - Breadcrumb navigation (< Back to Templates)
/// - Pinned top bar with SOP eyebrow, version pill, title, and action CTAs (Save, Preview, Publish)
/// - 3 Metric pods (Sequence Total, Mandatory Photos, Avg Estimated Time)
/// - Two-column workbench:
///   - Left column (404px): Master Items catalog with search, category filter, and add triggers
///   - Right column (660px): Active Inspection Sequence with reorderable cards, locked pills, and drop zone
/// - Version history archive
///
/// Responsive: Gracefully collapses to single-column layout on narrower viewports (< 1000px).
class TemplateBuilderPage extends ConsumerStatefulWidget {
  const TemplateBuilderPage({required this.templateId, super.key});

  final String templateId;

  @override
  ConsumerState<TemplateBuilderPage> createState() =>
      _TemplateBuilderPageState();
}

class _TemplateBuilderPageState extends ConsumerState<TemplateBuilderPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _serviceType = TextEditingController();
  final _vehicleType = TextEditingController();
  final _search = TextEditingController();
  String _categoryId = '';
  final List<_SelectedItem> _selected = [];
  bool _initialized = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _serviceType.dispose();
    _vehicleType.dispose();
    _search.dispose();
    super.dispose();
  }

  String get _itemKey => '${_search.text}\u0001$_categoryId';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(templateDetailProvider(widget.templateId));
    final categories = ref.watch(workshopCategoriesProvider);
    final items = ref.watch(publishedItemsProvider(_itemKey));

    if (detail.isLoading || categories.isLoading || items.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 7),
        ),
      );
    }
    if (detail.hasError || categories.hasError || items.hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () {
                ref.invalidate(templateDetailProvider(widget.templateId));
                ref.invalidate(workshopCategoriesProvider);
                ref.invalidate(publishedItemsProvider(_itemKey));
              },
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
      );
    }

    final template = detail.requireValue;
    _initialize(template);
    final draft = template.draft;
    final catalog = items.requireValue.take(80).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                SizedBox(
                  width: 96,
                  child: _buildLeftRail(context),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (wide) _buildTopHeader(context),
                    Container(
                      color: const Color(0xFFF8F9FA),
                      padding: EdgeInsets.symmetric(
                        horizontal: wide ? 40 : 16,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (wide) ...[
                            _buildBreadcrumb(context),
                            const SizedBox(height: 12),
                          ],
                          _header(context, l10n, template, draft, wide),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        key: const Key('template-builder-list'),
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 40 : 16,
                          vertical: 16,
                        ),
                        children: [
                          _buildTemplateDetailsCard(context, l10n, wide),
                          const SizedBox(height: 24),
                          if (wide && draft != null) ...[
                            _buildMetricPods(catalog),
                            const SizedBox(height: 32),
                          ],
                          if (draft == null)
                            EmptyState(
                              title: l10n.readOnlyVersion,
                              body: l10n.createDraft,
                              icon: Icons.lock_outline,
                              action: AppButton(
                                label: l10n.createDraft,
                                onPressed: _busy ? null : _createDraft,
                                variant: AppButtonVariant.tonal,
                              ),
                            )
                          else if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 404,
                                  child: _catalogPanel(
                                    context,
                                    l10n,
                                    categories.requireValue,
                                    catalog,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 660,
                                  child: _sequencePanel(
                                    context,
                                    l10n,
                                    template,
                                    draft,
                                    catalog,
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _catalogPanel(
                                  context,
                                  l10n,
                                  categories.requireValue,
                                  catalog,
                                ),
                                const SizedBox(height: 24),
                                _sequencePanel(
                                  context,
                                  l10n,
                                  template,
                                  draft,
                                  catalog,
                                ),
                              ],
                            ),
                          const SizedBox(height: 32),
                          _buildVersionHistory(context, l10n, template),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Left Navigation Rail (96px width)
  // ---------------------------------------------------------------------------
  Widget _buildLeftRail(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: 96,
      decoration: const BoxDecoration(
        color: Fx.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE3E2E7), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo
          InkWell(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: Fx.cardShadow,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.shield_outlined,
                color: Fx.emerald,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Overview Dashboard (0)
          _railItem(
            icon: Icons.grid_view_rounded,
            label: l10n.dashboardTab,
            selected: false,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 12),

          // Live Queue (1)
          _railItem(
            icon: Icons.receipt_long_rounded,
            label: l10n.jobsTab,
            selected: false,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 12),

          // Staff Management (2)
          _railItem(
            icon: Icons.groups_outlined,
            label: l10n.staffTab,
            selected: false,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 12),

          // Templates (3) - ACTIVE
          _railItem(
            icon: Icons.dashboard_customize_rounded,
            label: l10n.templatesTab,
            selected: true,
            onTap: () {},
          ),
          const Spacer(),

          // Help / Info icon at bottom
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.help_outline_rounded,
              color: Fx.muted,
              size: 20,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _railItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? Fx.emerald : Fx.container,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: selected ? Fx.ctaShadow : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: selected ? Fx.white : Fx.ink,
          size: 20,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header (80px height)
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;
    final userName = session?.user.displayName.trim().isNotEmpty == true
        ? session!.user.displayName.trim()
        : 'Marcus Vance';
    final userRole = session != null
        ? (session.role.name == 'workshopAdmin'
            ? 'Lead Inspector'
            : session.role.name)
        : 'Lead Inspector';

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: Fx.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE3E2E7), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Bay Status Pill (clean indicator, avoids banned words)
          Flexible(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(9999)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Fx.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BAY ONLINE',
                    style: Fx.text(
                        11, 14, FontWeight.w600, 0.55, color: Fx.secondaryInk),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Shop Floor #04',
                      style: Fx.text(12, 16, FontWeight.w700, 0.24,
                          color: Fx.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Search Field
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 260),
                height: 36,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(9999)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: Fx.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search checkpoints...',
                        style: Fx.text(13, 16, FontWeight.w400, 0,
                            color: Fx.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User details & avatar
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.ink),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userRole,
                  style:
                      Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _showUserMenu(context),
            borderRadius: const BorderRadius.all(Radius.circular(9999)),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Fx.deepGreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                style: Fx.text(14, 18, FontWeight.w700, 0, color: Fx.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(l10n.staffTab),
              onTap: () {
                Navigator.pop(ctx);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Fx.dangerRed),
              title: Text(
                l10n.signOut,
                style: const TextStyle(color: Fx.dangerRed),
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Breadcrumb
  // ---------------------------------------------------------------------------
  Widget _buildBreadcrumb(BuildContext context) {
    return InkWell(
      onTap: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: Fx.muted,
            ),
            const SizedBox(width: 8),
            Text(
              'Back to Templates',
              style: Fx.text(13, 16, FontWeight.w600, 0, color: Fx.muted),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar: template title, integer version pill, preview & publish CTAs
  // ---------------------------------------------------------------------------
  Widget _header(
    BuildContext context,
    AppLocalizations l10n,
    TemplateDetail template,
    TemplateVersionView? draft,
    bool wide,
  ) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: Text(
        draft != null
            ? 'v${draft.versionNo}'
            : contentStatusLabel(l10n, template.status),
        style: Fx.text(11, 14, FontWeight.w700, 0.55, color: Fx.deepGreen),
      ),
    );

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            pill,
            Text(
              'STANDARD OPERATING PROCEDURE',
              style: Fx.text(11, 14, FontWeight.w600, 1.1, color: Fx.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          template.name,
          key: const Key('builder-title'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Fx.text(32, 38, FontWeight.w800, -0.8, color: Fx.ink),
        ),
      ],
    );

    final actions = [
      if (draft != null)
        IconButton(
          tooltip: l10n.saveDraft,
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save_outlined),
        ),
      AppButton(
        key: const Key('builder-preview'),
        label: l10n.preview,
        onPressed: draft == null || _selected.isEmpty || _busy ? null : _preview,
        icon: Icons.visibility_outlined,
        variant: AppButtonVariant.tonal,
      ),
      AppButton(
        key: const Key('builder-publish'),
        label: l10n.publishTemplate,
        onPressed: draft == null || _busy ? null : _publish,
        icon: Icons.publish_outlined,
      ),
      if (template.status != 'RETIRED')
        IconButton(
          tooltip: l10n.retire,
          onPressed: _busy ? null : _retire,
          icon: const Icon(Icons.archive_outlined),
        ),
    ];

    if (wide) {
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          titleColumn,
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleColumn,
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: actions,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Metric Pods (3 pods row)
  // ---------------------------------------------------------------------------
  Widget _buildMetricPods(List<PublishedItem> catalog) {
    final photoCount =
        _selected.where((i) => i.evidenceRequirement == 'REQUIRED').length;
    final progress =
        _selected.isEmpty ? 0.0 : (_selected.length / 10).clamp(0.0, 1.0);

    return Row(
      children: [
        // Pod 1: Sequence Total
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: Fx.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'SEQUENCE TOTAL',
                        style: Fx.text(11, 14, FontWeight.w600, 0.55,
                            color: Fx.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.playlist_add_check_rounded,
                        color: Fx.muted, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_selected.length}',
                      style: Fx.text(32, 38, FontWeight.w800, -0.96,
                          color: Fx.ink),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'items configured',
                        style: Fx.text(13, 18, FontWeight.w400, 0,
                            color: Fx.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Fx.surfaceHigh,
                        borderRadius: BorderRadius.all(Radius.circular(9999)),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          borderRadius: BorderRadius.all(Radius.circular(9999)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Pod 2: Mandatory Photos
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: Fx.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'MANDATORY PHOTOS',
                        style: Fx.text(11, 14, FontWeight.w600, 0.55,
                            color: Fx.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.camera_alt_outlined,
                        color: Fx.muted, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$photoCount',
                      style: Fx.text(32, 38, FontWeight.w800, -0.96,
                          color: Fx.ink),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'steps require photos',
                        style: Fx.text(13, 18, FontWeight.w400, 0,
                            color: Fx.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Photo verification standard',
                  style:
                      Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Pod 3: Estimated Time
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: Fx.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'AVG TIME PER JOB',
                        style: Fx.text(11, 14, FontWeight.w600, 0.55,
                            color: Fx.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.timer_outlined,
                        color: Fx.muted, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_selected.length * 8 + 10}m',
                      style: Fx.text(32, 38, FontWeight.w800, -0.96,
                          color: Fx.ink),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'shop standard average',
                        style: Fx.text(13, 18, FontWeight.w400, 0,
                            color: Fx.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Standard service checklist',
                  style: Fx.text(11, 14, FontWeight.w600, 0.44,
                      color: Fx.emerald),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Template Parameters Card
  // ---------------------------------------------------------------------------
  Widget _buildTemplateDetailsCard(
      BuildContext context, AppLocalizations l10n, bool wide) {
    return Card(
      elevation: 0,
      color: Fx.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE3E2E7)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.edit_note_rounded,
                color: Fx.emerald, size: 20),
          ),
          title: Text(
            'Template Parameters & Classification',
            style: Fx.text(15, 20, FontWeight.w700, -0.16, color: Fx.ink),
          ),
          subtitle: Text(
            '${_serviceType.text.isEmpty ? 'FULL' : _serviceType.text} · ${_vehicleType.text.isEmpty ? 'CAR' : _vehicleType.text}',
            style: Fx.text(12, 16, FontWeight.w400, 0, color: Fx.muted),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            if (wide)
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _name,
                      label: l10n.templateName,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _serviceType,
                      label: l10n.serviceType,
                    ),
                  ),
                ],
              )
            else ...[
              AppTextField(
                controller: _name,
                label: l10n.templateName,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _serviceType,
                label: l10n.serviceType,
              ),
            ],
            const SizedBox(height: 12),
            if (wide)
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _vehicleType,
                      label: l10n.vehicleType,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _description,
                      label: l10n.templateDescription,
                    ),
                  ),
                ],
              )
            else ...[
              AppTextField(
                controller: _vehicleType,
                label: l10n.vehicleType,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _description,
                label: l10n.templateDescription,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left Column: Master Items Catalog
  // ---------------------------------------------------------------------------
  Widget _catalogPanel(
    BuildContext context,
    AppLocalizations l10n,
    List<Category> categories,
    List<PublishedItem> catalog,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.builderMasterItems} · ${catalog.length}',
                  style: Fx.text(22, 28, FontWeight.w700, -0.44,
                      color: Fx.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'Inspection Diagnostic Checkpoints',
                  style:
                      Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(9999)),
              ),
              child: Text(
                '${catalog.length} In Catalog',
                style:
                    Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          key: const Key('builder-search'),
          controller: _search,
          label: l10n.searchItems,
          hint: l10n.searchItems,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('builder-category'),
          isExpanded: true,
          initialValue: _categoryId.isEmpty ? null : _categoryId,
          decoration: InputDecoration(
            labelText: l10n.allCategories,
            filled: true,
            fillColor: Fx.container,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(l10n.allCategories)),
            ...categories.map(
              (category) => DropdownMenuItem(
                value: category.id,
                child: Text(category.labelEn),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _categoryId = value ?? ''),
        ),
        const SizedBox(height: 16),
        ...catalog.map(
          (item) {
            final alreadyAdded = _contains(item.versionId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                key: Key('published-item-${item.versionId}'),
                decoration: const BoxDecoration(
                  color: Fx.white,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  boxShadow: Fx.cardShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    onTap: alreadyAdded ? null : () => _add(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Fx.container,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.fact_check_outlined,
                              color: Fx.ink,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.labelEn,
                                  style: Fx.text(15, 20, FontWeight.w700,
                                      -0.16,
                                      color: Fx.ink),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.categoryLabelEn} · v${item.version.versionNo}${item.sampleData ? ' · ${l10n.sampleData}' : ''}',
                                  style: Fx.text(12, 16, FontWeight.w400,
                                      0,
                                      color: Fx.muted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: Key('catalog-add-${item.versionId}'),
                            tooltip: l10n.add,
                            onPressed: alreadyAdded ? null : () => _add(item),
                            icon: Icon(
                              alreadyAdded
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: alreadyAdded ? Fx.muted : Fx.emerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Right Column: Active Inspection Sequence
  // ---------------------------------------------------------------------------
  Widget _sequencePanel(
    BuildContext context,
    AppLocalizations l10n,
    TemplateDetail template,
    TemplateVersionView draft,
    List<PublishedItem> catalog,
  ) {
    final hasAvailable = catalog.any((item) => !_contains(item.versionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template sequence',
                  style:
                      Fx.text(22, 28, FontWeight.w700, -0.44, color: Fx.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selected.length} items selected',
                  style:
                      Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                ),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(9999)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Fx.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sequence Ready',
                    style:
                        Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selected.isEmpty)
          EmptyState(
            title: l10n.noItems,
            body: l10n.addItems,
            icon: Icons.playlist_add_check,
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: _dragProxy,
            onReorderItem: _reorderItem,
            children: _selected.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return WorkshopSequenceCard(
                key: ValueKey('seq-row-${item.masterItemVersionId}'),
                indexLabel: (index + 1).toString().padLeft(2, '0'),
                title: item.labelEn,
                chips: [
                  WorkshopLockedPill(
                    label:
                        '${item.noteRequirement}/${item.evidenceRequirement} · ${l10n.lockedByPlatform}',
                  ),
                  StatusChip(
                    label: '${item.categoryLabelEn} · v${item.versionNo}',
                  ),
                ],
                ruleNote: Text(
                  item.instructionEn.isEmpty
                      ? item.categoryLabelEn
                      : item.instructionEn,
                ),
                controls: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: Key('seq-up-$index'),
                      tooltip: l10n.moveUp,
                      onPressed:
                          index > 0 ? () => _itemAction(index, 'up') : null,
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      key: Key('seq-down-$index'),
                      tooltip: l10n.moveDown,
                      onPressed: index < _selected.length - 1
                          ? () => _itemAction(index, 'down')
                          : null,
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    IconButton(
                      key: Key('seq-remove-$index'),
                      tooltip: l10n.remove,
                      onPressed: () => _itemAction(index, 'remove'),
                      icon: const Icon(Icons.delete_outline),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle,
                        key: Key('seq-drag-$index'),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        WorkshopDropZone(
          key: const Key('builder-dropzone'),
          label: l10n.builderDropHint,
          hint: l10n.addItems,
          onTap: hasAvailable ? () => _addFirstAvailable(catalog) : null,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Version History List
  // ---------------------------------------------------------------------------
  Widget _buildVersionHistory(
    BuildContext context,
    AppLocalizations l10n,
    TemplateDetail template,
  ) {
    if (template.versions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Version history',
          style: Fx.text(20, 26, FontWeight.w700, -0.3, color: Fx.ink),
        ),
        const SizedBox(height: 16),
        ...template.versions.map(
          (version) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.white,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: Fx.cardShadow,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: ListTile(
                  key: Key('template-version-${version.id}'),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Fx.container,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.history_rounded,
                        color: Fx.ink, size: 20),
                  ),
                  title: Text(
                    'v${version.versionNo} · ${contentStatusLabel(l10n, version.status)}',
                    style:
                        Fx.text(15, 20, FontWeight.w700, -0.16, color: Fx.ink),
                  ),
                  subtitle: Text(
                    '${version.itemCount} ${l10n.itemsSelected}${version.publishedAt.isEmpty ? '' : ' · ${version.publishedAt}'}',
                    style:
                        Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Fx.muted),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TemplateVersionPage(
                        templateId: widget.templateId,
                        versionId: version.id,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Drag Proxy
  // ---------------------------------------------------------------------------
  Widget _dragProxy(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, proxyChild) => Material(
        type: MaterialType.transparency,
        child: proxyChild,
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Logic & API Interactions
  // ---------------------------------------------------------------------------
  void _initialize(TemplateDetail template) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _name.text = template.name;
    _description.text = template.description ?? '';
    _serviceType.text = template.serviceType;
    _vehicleType.text = template.vehicleType ?? '';
    _selected
      ..clear()
      ..addAll(
        (template.draft?.items ?? <TemplateItemView>[]).map(
          _SelectedItem.fromView,
        ),
      );
  }

  bool _contains(String versionId) =>
      _selected.any((item) => item.masterItemVersionId == versionId);

  void _add(PublishedItem item) {
    if (_contains(item.versionId)) {
      return;
    }
    setState(() => _selected.add(_SelectedItem.fromPublished(item)));
  }

  void _addFirstAvailable(List<PublishedItem> catalog) {
    for (final item in catalog) {
      if (!_contains(item.versionId)) {
        _add(item);
        return;
      }
    }
  }

  void _itemAction(int index, String action) {
    setState(() {
      if (action == 'remove') {
        _selected.removeAt(index);
      } else if (action == 'up' && index > 0) {
        final item = _selected.removeAt(index);
        _selected.insert(index - 1, item);
      } else if (action == 'down' && index < _selected.length - 1) {
        final item = _selected.removeAt(index);
        _selected.insert(index + 1, item);
      }
    });
  }

  void _reorderItem(int fromIndex, int toIndex) {
    setState(() {
      final item = _selected.removeAt(fromIndex);
      _selected.insert(toIndex, item);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final template = ref.read(templateDetailProvider(widget.templateId)).value;
    if (template?.draft == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _saveDraft();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.contentSaved)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveDraft() async {
    await ref.read(adminApiProvider).saveTemplateDraft(
          id: widget.templateId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          serviceType: _serviceType.text.trim(),
          vehicleType: _vehicleType.text.trim(),
          items: _selected
              .asMap()
              .entries
              .map(
                (entry) => TemplateItemDraft(
                  masterItemVersionId: entry.value.masterItemVersionId,
                  sortOrder: entry.key,
                ),
              )
              .toList(),
        );
    ref.invalidate(templateDetailProvider(widget.templateId));
    ref.invalidate(templatesProvider);
    _initialized = false;
  }

  Future<void> _publish() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await _saveDraft();
      await ref.read(adminApiProvider).publishTemplate(widget.templateId);
      ref.invalidate(templateDetailProvider(widget.templateId));
      ref.invalidate(templatesProvider);
      _initialized = false;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.templatePublished)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _createDraft() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).createTemplateDraft(widget.templateId);
      ref.invalidate(templateDetailProvider(widget.templateId));
      _initialized = false;
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _retire() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.retire,
      message: l10n.confirm,
      confirmLabel: l10n.retire,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adminApiProvider).retireTemplate(widget.templateId);
      ref.invalidate(templatesProvider);
      ref.invalidate(templateDetailProvider(widget.templateId));
      _initialized = false;
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _preview() async {
    final l10n = AppLocalizations.of(context);
    var arabic = false;
    await showAppBottomSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.preview,
                subtitle: '${_selected.length} ${l10n.itemsSelected}',
              ),
              Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: [
                  AppSelectableText(
                    label: l10n.previewEn,
                    selected: !arabic,
                    onTap: () => setState(() => arabic = false),
                  ),
                  AppSelectableText(
                    label: l10n.previewAr,
                    selected: arabic,
                    onTap: () => setState(() => arabic = true),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.sm),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _selected
                      .map(
                        (item) => Padding(
                          padding: EdgeInsetsDirectional.only(
                            bottom: context.spacing.sm,
                          ),
                          child: Card(
                            child: Padding(
                              padding: EdgeInsetsDirectional.all(
                                context.spacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    arabic ? item.labelAr : item.labelEn,
                                    style: context.texts.titleMedium,
                                  ),
                                  SizedBox(height: context.spacing.xs),
                                  Text(
                                    arabic
                                        ? item.instructionAr
                                        : item.instructionEn,
                                    style: context.texts.bodyMedium,
                                  ),
                                  SizedBox(height: context.spacing.xs),
                                  Text(
                                    'v${item.versionNo} · ${item.noteRequirement}/${item.evidenceRequirement} · ${l10n.lockedByPlatform}',
                                    style: context.texts.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectedItem {
  const _SelectedItem({
    required this.masterItemVersionId,
    required this.categoryLabelEn,
    required this.categoryLabelAr,
    required this.labelEn,
    required this.labelAr,
    required this.instructionEn,
    required this.instructionAr,
    required this.versionNo,
    required this.noteRequirement,
    required this.evidenceRequirement,
  });

  final String masterItemVersionId;
  final String categoryLabelEn;
  final String categoryLabelAr;
  final String labelEn;
  final String labelAr;
  final String instructionEn;
  final String instructionAr;
  final int versionNo;
  final String noteRequirement;
  final String evidenceRequirement;

  factory _SelectedItem.fromView(TemplateItemView item) => _SelectedItem(
        masterItemVersionId: item.masterItemVersionId,
        categoryLabelEn: item.categoryLabelEn,
        categoryLabelAr: item.categoryLabelAr,
        labelEn: item.labelEn,
        labelAr: item.labelAr,
        instructionEn: item.instructionEn,
        instructionAr: item.instructionAr,
        versionNo: item.versionNo,
        noteRequirement: item.noteRequirement,
        evidenceRequirement: item.evidenceRequirement,
      );

  factory _SelectedItem.fromPublished(PublishedItem item) {
    final en = item.version.translation('en');
    final ar = item.version.translation('ar');
    return _SelectedItem(
      masterItemVersionId: item.versionId,
      categoryLabelEn: item.categoryLabelEn,
      categoryLabelAr: item.categoryLabelAr,
      labelEn: en.label,
      labelAr: ar.label,
      instructionEn: en.instruction,
      instructionAr: ar.instruction,
      versionNo: item.version.versionNo,
      noteRequirement: item.version.noteRequirement,
      evidenceRequirement: item.version.evidenceRequirement,
    );
  }
}
