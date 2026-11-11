import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_models.dart';
import '../../platform_providers.dart';
import '../../platform_theme.dart';

class WorkshopDetailsScreen extends ConsumerStatefulWidget {
  const WorkshopDetailsScreen({
    super.key,
    this.workshopId,
  });

  final String? workshopId;

  @override
  ConsumerState<WorkshopDetailsScreen> createState() =>
      _WorkshopDetailsScreenState();
}

class _WorkshopDetailsScreenState extends ConsumerState<WorkshopDetailsScreen> {
  late final TextEditingController _adminNameController;
  late final TextEditingController _phoneController;

  String _activeTab = 'General';
  bool _isWorkshopEnabled = true;
  bool _isSaving = false;
  late String _selectedWorkshopId;

  @override
  void initState() {
    super.initState();
    _selectedWorkshopId = widget.workshopId ?? 'workshop-1';
    _adminNameController = TextEditingController(text: 'Workshop Admin');
    _phoneController = TextEditingController(text: '+1 (555) 382-9011');
  }

  @override
  void dispose() {
    _adminNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _discardChanges() {
    setState(() {
      _adminNameController.text = 'Workshop Admin';
      _phoneController.text = '+1 (555) 382-9011';
      _isWorkshopEnabled = true;
    });
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/workshops');
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PtTheme.deepGreen,
          content: Text(
            'Workshop settings updated successfully.',
            style: PtTheme.font(14, color: PtTheme.white, weight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 880;
    final workshops = ref.watch(hierarchyStateProvider).value?.workshops ?? const <HierarchyWorkshop>[];
    final activeWorkshop = workshops.firstWhere(
      (w) => w.id == _selectedWorkshopId,
      orElse: () => workshops.isNotEmpty
          ? workshops.first
          : const HierarchyWorkshop(
              id: 'workshop-1',
              name: 'Workshop A',
              branchName: 'EMEA Industrial Hub',
              status: 'ACTIVE',
              memberCount: 12,
              admins: [],
              technicians: [],
              pendingInvitations: [],
            ),
    );

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar
          if (isDesktop)
            PlatformSidebar(
              currentRoute: '/workshops',
              onNavigate: (route) => context.go(route),
            ),

          // 2. Main Area
          Expanded(
            child: Column(
              children: [
                // Top Global Header
                const PlatformHeader(),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Header Context Eyebrow
                            _buildHeaderContext(activeWorkshop),

                            const SizedBox(height: 20),

                            // 2. Main Split-Screen Layout
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 780) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildLeftPane(workshops, activeWorkshop),
                                      const SizedBox(height: 20),
                                      _buildRightOverviewCard(
                                          activeWorkshop, constraints.maxWidth),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left clean tree pane
                                    SizedBox(
                                      width: (MediaQuery.sizeOf(context).width * 0.2)
                                          .clamp(200.0, 280.0),
                                      child: _buildLeftPane(
                                          workshops, activeWorkshop),
                                    ),

                                    const SizedBox(width: 24),

                                    // Right main card
                                    Expanded(
                                      child: _buildRightOverviewCard(
                                          activeWorkshop, constraints.maxWidth),
                                    ),
                                  ],
                                );
                              },
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

  Widget _buildHeaderContext(HierarchyWorkshop workshop) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        // Left: Eyebrow + Node ID
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            InkWell(
              onTap: () => context.go('/workshops'),
              child: Text(
                'WORKSPACE HIERARCHY',
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                  tracking: 0.6,
                ),
              ),
            ),
            Text(
              '•',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                color: PtTheme.muted,
              ),
            ),
            Text(
              'Node ID #WS-8841',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                weight: FontWeight.w600,
                color: PtTheme.muted,
              ),
            ),
          ],
        ),

        // Right: Live Telematics Sync Status Capsule
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: PtTheme.emerald.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: PtTheme.emerald.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: PtTheme.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live Telematics Sync',
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: PtTheme.emerald,
                  tracking: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPane(
      List<HierarchyWorkshop> workshops, HierarchyWorkshop active) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Organization Tree Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PtTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organization Tree',
                style: PtTheme.font(
                  13,
                  lineHeight: 18,
                  weight: FontWeight.w700,
                  color: PtTheme.ink,
                ),
              ),
              const SizedBox(height: 12),

              // Root Node: Platform
              Row(
                children: [
                  const Icon(
                    Icons.hub_rounded,
                    size: 16,
                    color: PtTheme.deepGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Platform',
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w600,
                      color: PtTheme.ink,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Workshops sub-tree
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  children: [
                    for (final w in workshops) ...[
                      InkWell(
                        onTap: () {
                          setState(() => _selectedWorkshopId = w.id);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: w.id == active.id
                                ? PtTheme.deepGreen.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: w.id == active.id
                                ? Border.all(
                                    color: PtTheme.deepGreen
                                        .withValues(alpha: 0.3),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: w.id == active.id
                                      ? PtTheme.deepGreen
                                      : PtTheme.muted.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  w.name,
                                  style: PtTheme.font(
                                    12,
                                    lineHeight: 16,
                                    weight: w.id == active.id
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: w.id == active.id
                                        ? PtTheme.deepGreen
                                        : PtTheme.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Node Status Card: VALIDATION PROTOCOL
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PtTheme.canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PtTheme.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    size: 14,
                    color: PtTheme.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'VALIDATION PROTOCOL',
                      style: PtTheme.font(
                        10,
                        lineHeight: 14,
                        weight: FontWeight.w700,
                        color: PtTheme.muted,
                        tracking: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Active node authenticated via ISO 26262 diagnostic relay. Automatic backup scheduled hourly.',
                style: PtTheme.font(
                  11,
                  lineHeight: 16,
                  weight: FontWeight.w400,
                  color: PtTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightOverviewCard(
      HierarchyWorkshop workshop, double availableWidth) {
    final isNarrow = availableWidth < 680;

    return Container(
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 60,
            offset: Offset(0, 20),
          ),
        ],
      ),
      padding: EdgeInsets.all(isNarrow ? 20 : 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Title Row & Tabs
          _buildTitleRow(workshop),

          const SizedBox(height: 24),

          // 2. Three Pastel Gray Metric Chips
          _buildMetricChips(workshop),

          const SizedBox(height: 28),

          // 3. Mid Section based on active tab
          if (_activeTab == 'General')
            _buildMidSection(isNarrow)
          else if (_activeTab == 'Permissions')
            _buildPermissionsSection()
          else
            _buildAuditSection(),

          const SizedBox(height: 32),

          // 4. Bottom Footer Area with Solid Chunky Button
          _buildFooterRow(isNarrow),
        ],
      ),
    );
  }

  Widget _buildTitleRow(HierarchyWorkshop workshop) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        // Title & Eyebrow
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONFIGURATION & DIAGNOSTICS',
              style: PtTheme.font(
                11,
                lineHeight: 14,
                weight: FontWeight.w700,
                color: PtTheme.muted,
                tracking: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${workshop.name} Overview',
              style: PtTheme.font(
                24,
                lineHeight: 30,
                weight: FontWeight.w800,
                color: PtTheme.ink,
                tracking: -0.4,
              ),
            ),
          ],
        ),

        // Tabs: General, Permissions, Audit
        Container(
          height: 36,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: PtTheme.canvas,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTab('General'),
                _buildTab('Permissions'),
                _buildTab('Audit'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _activeTab == label;
    return InkWell(
      onTap: () => setState(() => _activeTab = label),
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? PtTheme.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: PtTheme.font(
            12,
            lineHeight: 16,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? PtTheme.ink : PtTheme.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChips(HierarchyWorkshop workshop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
        final isCompact = constraints.maxWidth < 600;

        final chip1 = _buildMetricChip(
          eyebrow: 'WORKFORCE',
          value: '${workshop.memberCount > 0 ? workshop.memberCount : 12}',
          label: l10n?.technicians ?? 'Technicians',
          subtext: 'All shifts staffed',
        );

        final chip2 = _buildMetricChip(
          eyebrow: 'THROUGHPUT',
          value: '450',
          label: l10n?.totalJobs ?? 'Total Jobs',
          subtext: '+18% this month',
          subtextColor: PtTheme.deepGreen,
        );

        final chip3 = _buildOperationalStateChip(workshop);

        if (isCompact) {
          return Column(
            children: [
              chip1,
              const SizedBox(height: 10),
              chip2,
              const SizedBox(height: 10),
              chip3,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: chip1),
            const SizedBox(width: 14),
            Expanded(child: chip2),
            const SizedBox(width: 14),
            Expanded(child: chip3),
          ],
        );
      },
    );
  }

  Widget _buildMetricChip({
    required String eyebrow,
    required String value,
    required String label,
    required String subtext,
    Color? subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: PtTheme.font(
              10,
              lineHeight: 14,
              weight: FontWeight.w700,
              color: PtTheme.muted,
              tracking: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: PtTheme.font(
                  24,
                  lineHeight: 28,
                  weight: FontWeight.w800,
                  color: PtTheme.ink,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: PtTheme.font(
                    13,
                    lineHeight: 16,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: PtTheme.font(
              11,
              lineHeight: 14,
              weight: FontWeight.w500,
              color: subtextColor ?? PtTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalStateChip(HierarchyWorkshop workshop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPERATIONAL STATE',
            style: PtTheme.font(
              10,
              lineHeight: 14,
              weight: FontWeight.w700,
              color: PtTheme.muted,
              tracking: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PtTheme.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  workshop.status == 'STANDBY' ? 'Standby' : 'Active',
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w700,
                    color: PtTheme.deepGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Latency: 14ms',
            style: PtTheme.font(
              11,
              lineHeight: 14,
              weight: FontWeight.w500,
              color: PtTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMidSection(bool isNarrow) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final inputsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Admin Name Field
        _buildFormField(
          key: const Key('input-workshop-admin-name'),
          controller: _adminNameController,
          label: l10n?.workshopAdminName ?? 'Workshop Admin Name',
          subtext:
              'Primary authority for job sign-offs and diagnostic overrides.',
          icon: Icons.person_outline_rounded,
        ),

        const SizedBox(height: 20),

        // Contact Phone Field
        _buildFormField(
          key: const Key('input-workshop-contact-phone'),
          controller: _phoneController,
          label: l10n?.contactPhone ?? 'Contact Phone',
          subtext: 'Direct escalation hotline for emergency fleet dispatch.',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );

    final toggleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PtTheme.canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PtTheme.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isWorkshopEnabled
                          ? 'Enable/Disable Workshop (Active)'
                          : 'Enable/Disable Workshop (Muted)',
                      style: PtTheme.font(
                        13,
                        lineHeight: 18,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isWorkshopEnabled
                          ? 'Operational ingestion & bay assignments enabled'
                          : 'Operational ingestion & bay assignments paused',
                      style: PtTheme.font(
                        11,
                        lineHeight: 15,
                        weight: FontWeight.w400,
                        color: PtTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                key: const Key('switch-enable-workshop'),
                value: _isWorkshopEnabled,
                activeThumbColor: PtTheme.emerald,
                activeTrackColor: PtTheme.emerald.withValues(alpha: 0.3),
                onChanged: (val) {
                  setState(() => _isWorkshopEnabled = val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Verified telematics status pill
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PtTheme.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: PtTheme.deepGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Workshop node is actively syncing telematics',
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w600,
                    color: PtTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          inputsColumn,
          const SizedBox(height: 20),
          toggleColumn,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: inputsColumn),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: toggleColumn),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role-Based Access Control (RBAC)',
            style: PtTheme.font(
              16,
              lineHeight: 22,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Granular authorization policies for diagnostic overrides and workshop dispatch.',
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: FontWeight.w400,
              color: PtTheme.muted,
            ),
          ),
          const SizedBox(height: 16),
          _buildPermissionTile(
            permTitle: Localizations.of<AppLocalizations>(context, AppLocalizations)?.technicianDispatchClearance ??
                'Technician Dispatch Clearance',
            description:
                'Authorized for real-time bay allocation and telemetry sync.',
            enabled: true,
          ),
          const SizedBox(height: 10),
          _buildPermissionTile(
            permTitle: Localizations.of<AppLocalizations>(context, AppLocalizations)?.diagnosticOverrideAuthority ??
                'Diagnostic Override Authority',
            description:
                'Permits bypassing secondary sensor calibration steps.',
            enabled: true,
          ),
          const SizedBox(height: 10),
          _buildPermissionTile(
            permTitle: Localizations.of<AppLocalizations>(context, AppLocalizations)?.telemetryIngestionKey ??
                'Telemetry Ingestion Key',
            description:
                'Automated OBD-II dongle API sync token: VALIDATED (ACTIVE).',
            enabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String permTitle,
    required String description,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: enabled ? PtTheme.emerald : PtTheme.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permTitle,
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
                Text(
                  description,
                  style: PtTheme.font(
                    11,
                    lineHeight: 15,
                    weight: FontWeight.w400,
                    color: PtTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Node Lifecycle & Telematics Audit Log',
            style: PtTheme.font(
              16,
              lineHeight: 22,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Immutable telemetry ledger and configuration change log.',
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: FontWeight.w400,
              color: PtTheme.muted,
            ),
          ),
          const SizedBox(height: 16),
          _buildAuditTile(
            event: 'Diagnostic Telematics Link Verified',
            actor: 'System Relay Daemon',
            time: '2 minutes ago',
            status: 'VERIFIED',
          ),
          const SizedBox(height: 10),
          _buildAuditTile(
            event: 'Alex Vance modified Operational Parameters',
            actor: 'Alex Vance (Platform Director)',
            time: '14:24 UTC',
            status: 'AUDITED',
          ),
          const SizedBox(height: 10),
          _buildAuditTile(
            event: 'Workshop Configuration Created',
            actor: 'Station Manager (Workshop Admin)',
            time: 'Yesterday 09:12',
            status: 'COMMITTED',
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTile({
    required String event,
    required String actor,
    required String time,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 16,
            color: PtTheme.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event,
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w700,
                    color: PtTheme.ink,
                  ),
                ),
                Text(
                  '$actor • $time',
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    weight: FontWeight.w400,
                    color: PtTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: PtTheme.deepGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: PtTheme.font(
                10,
                lineHeight: 13,
                weight: FontWeight.w700,
                color: PtTheme.deepGreen,
                tracking: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String subtext,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: PtTheme.font(
            13,
            lineHeight: 18,
            weight: FontWeight.w600,
            color: PtTheme.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PtTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: key,
                  controller: controller,
                  keyboardType: keyboardType,
                  style: PtTheme.font(
                    14,
                    lineHeight: 20,
                    weight: FontWeight.w500,
                    color: PtTheme.ink,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  icon,
                  size: 18,
                  color: PtTheme.muted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtext,
          style: PtTheme.font(
            11,
            lineHeight: 15,
            weight: FontWeight.w400,
            color: PtTheme.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterRow(bool isNarrow) {
    final infoWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.history_rounded, size: 14, color: PtTheme.muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Last modified today at 14:28 EST by Alex Vance',
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: FontWeight.w400,
              color: PtTheme.muted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final actionButtons = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        // Discard Button
        TextButton(
          key: const Key('btn-discard-workshop-details'),
          onPressed: _discardChanges,
          style: TextButton.styleFrom(
            backgroundColor: PtTheme.canvas,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Discard',
            style: PtTheme.font(
              13,
              weight: FontWeight.w600,
              color: PtTheme.ink,
            ),
          ),
        ),

        // Save Changes Button
        ElevatedButton.icon(
          key: const Key('btn-save-workshop-details'),
          onPressed: _isSaving ? null : _saveChanges,
          icon: _isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PtTheme.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 16, color: PtTheme.white),
          label: Text(
            'Save Changes',
            style: PtTheme.font(
              14,
              lineHeight: 20,
              weight: FontWeight.w700,
              color: PtTheme.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: PtTheme.deepGreen,
            foregroundColor: PtTheme.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          infoWidget,
          const SizedBox(height: 16),
          actionButtons,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: infoWidget),
        const SizedBox(width: 12),
        actionButtons,
      ],
    );
  }
}
