import 'package:admin_app/src/screens/f3b/settings_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Screen 11 — Workshop Settings.
///
/// Desktop layout matching Figma specification.
/// Implements cohesive Fx design tokens, typography, shadows, and interactive controls.
class WorkshopSettingsView extends StatefulWidget {
  const WorkshopSettingsView({
    super.key,
    this.selectedNavIndex = 4,
    this.onNavSelected,
    this.onSaveSettings,
    this.onSearch,
    this.searchController,
    this.onSignOut,
    this.onToggleLocale,
    this.userName,
    this.userRole,
    this.workshopName,
    this.contactPhone,
    this.address,
  });

  final int selectedNavIndex;
  final ValueChanged<int>? onNavSelected;
  final VoidCallback? onSaveSettings;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;
  final VoidCallback? onSignOut;
  final VoidCallback? onToggleLocale;
  final String? userName;
  final String? userRole;
  final String? workshopName;
  final String? contactPhone;
  final String? address;

  static const double width = 1280;
  static const double height = 1674;

  @override
  State<WorkshopSettingsView> createState() => _WorkshopSettingsViewState();
}

class _WorkshopSettingsViewState extends State<WorkshopSettingsView> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _autoSendPdf = true;
  bool _mandatoryPhoto = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.workshopName ?? 'Apex Fleet Hub — Bay District',
    );
    _phoneController = TextEditingController(
      text: widget.contactPhone ?? '+1 (555) 382-9011',
    );
    _addressController = TextEditingController(
      text: widget.address ?? '4200 Industrial Parkway, Suite 4B',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Widget _svg(String raw, double w, double h) {
    return SvgPicture.string(
      raw,
      width: w,
      height: h,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: WorkshopSettingsView.width,
          height: WorkshopSettingsView.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background canvas
              Positioned.fill(
                child: Container(
                  color: Fx.white,
                ),
              ),

              // Main Layout (x: 96, y: 0, w: 1184, h: 1674)
              Positioned(
                left: 96,
                top: 0,
                width: 1184,
                height: WorkshopSettingsView.height,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: 1184,
                    height: WorkshopSettingsView.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main Container (x: 80, y: 80, w: 1024)
                        Positioned(
                          left: 80,
                          top: 80,
                          width: 1024,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 32),
                              // 1. Header Block
                              _buildHeaderBlock(),
                              const SizedBox(height: 36),

                              // 2. Visual Anchor / Hub Metrics Row
                              _buildMetricsRow(),
                              const SizedBox(height: 36),

                              // 3. Main Stacked Form Cards
                              _buildFormCards(),
                              const SizedBox(height: 36),

                              // 4. Bottom Actions Container
                              _buildBottomActions(),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Header Bar (x: 96, y: 0, w: 1184, h: 80)
              Positioned(
                left: 96,
                top: 0,
                width: 1184,
                height: 80,
                child: _buildHeaderBar(),
              ),

              // Aside Navigation (x: 0, y: 0, w: 96, h: 800)
              Positioned(
                left: 0,
                top: 0,
                width: 96,
                height: 800,
                child: _buildAside(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Header Bar (x: 96, y: 0, w: 1184, h: 80)
  // -------------------------------------------------------------
  Widget _buildHeaderBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: Fx.whiteE5,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE3E2E7), width: 1),
        ),
      ),
      child: Row(
        children: [
          // 'BAY ACTIVE' Pill
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Fx.container,
              borderRadius: const BorderRadius.all(Radius.circular(Fx.pillRadius)),
              border: Border.all(color: const Color(0xFFE3E2E7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Fx.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'BAY ACTIVE',
                  style: Fx.text(11, 14, FontWeight.w600, 0.5, color: Fx.secondaryInk),
                ),
                const SizedBox(width: 12),
                Text(
                  'Shop Floor #04',
                  style: Fx.text(12, 16, FontWeight.w700, 0.2, color: Fx.ink),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Search Box
          Container(
            width: 299,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
            ),
            child: Row(
              children: [
                _svg(SettingsAssets.Icon_1_2825, 15, 15),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: widget.onSearch,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Search VIN, tech, job ticket...',
                      hintStyle: Fx.text(13, 16, FontWeight.w400, 0, color: Fx.muted),
                    ),
                    style: Fx.text(13, 16, FontWeight.w500, 0, color: Fx.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // User Info
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.userName ?? 'Marcus Vance',
                style: Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.ink),
              ),
              Text(
                widget.userRole ?? 'Lead Inspector',
                style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Avatar
          InkWell(
            onTap: () => _showUserMenu(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Fx.deepGreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'MV',
                style: Fx.text(12, 14, FontWeight.w700, 0, color: Fx.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Workshop Settings & Profile'),
              subtitle: const Text('Business details, bays, working hours & profile'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onNavSelected?.call(4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Staff Management'),
              subtitle: const Text('Invite technicians, assign roles & permissions'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onNavSelected?.call(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Inspection Templates'),
              subtitle: const Text('Service checklists and template builder'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onNavSelected?.call(3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Toggle Language (EN / AR)'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onToggleLocale?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                widget.onSignOut?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Aside Navigation
  // -------------------------------------------------------------
  Widget _buildAside() {
    return Container(
      width: 96,
      height: 800,
      decoration: const BoxDecoration(
        color: Fx.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE3E2E7), width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Logo
          Positioned(
            left: 24,
            top: 32,
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onNavSelected?.call(0),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  alignment: Alignment.center,
                  child: _svg(SettingsAssets.Icon_1_2843, 21.67, 21.67),
                ),
              ),
            ),
          ),

          // Nav Dashboard
          Positioned(
            left: 20,
            top: 112,
            width: 56,
            height: 52,
            child: Tooltip(
              message: 'Overview Dashboard',
              child: InkWell(
                onTap: () => widget.onNavSelected?.call(0),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.selectedNavIndex == 0
                        ? Fx.emerald
                        : Fx.container,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    boxShadow: widget.selectedNavIndex == 0 ? Fx.ctaShadow : null,
                  ),
                  alignment: Alignment.center,
                  child: _svg(SettingsAssets.Icon_1_2847, 18, 18),
                ),
              ),
            ),
          ),

          // Nav Jobs
          Positioned(
            left: 20,
            top: 176,
            width: 56,
            height: 52,
            child: Tooltip(
              message: 'Live Job Queue',
              child: InkWell(
                onTap: () => widget.onNavSelected?.call(1),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.selectedNavIndex == 1
                        ? Fx.emerald
                        : Fx.container,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    boxShadow: widget.selectedNavIndex == 1 ? Fx.ctaShadow : null,
                  ),
                  alignment: Alignment.center,
                  child: _svg(SettingsAssets.Icon_1_2850, 18, 20),
                ),
              ),
            ),
          ),

          // Nav Staff
          Positioned(
            left: 20,
            top: 240,
            width: 56,
            height: 52,
            child: Tooltip(
              message: 'Staff Management',
              child: InkWell(
                onTap: () => widget.onNavSelected?.call(2),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.selectedNavIndex == 2
                        ? Fx.emerald
                        : Fx.container,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    boxShadow: widget.selectedNavIndex == 2 ? Fx.ctaShadow : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.groups_outlined,
                    size: 20,
                    color: widget.selectedNavIndex == 2
                        ? Fx.white
                        : Fx.muted,
                  ),
                ),
              ),
            ),
          ),

          // Nav Templates
          Positioned(
            left: 20,
            top: 304,
            width: 56,
            height: 52,
            child: Tooltip(
              message: 'Inspection Templates',
              child: InkWell(
                onTap: () => widget.onNavSelected?.call(3),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.selectedNavIndex == 3
                        ? Fx.emerald
                        : Fx.container,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    boxShadow: widget.selectedNavIndex == 3 ? Fx.ctaShadow : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.dashboard_customize_outlined,
                    size: 20,
                    color: widget.selectedNavIndex == 3
                        ? Fx.white
                        : Fx.muted,
                  ),
                ),
              ),
            ),
          ),

          // Nav Settings — ACTIVE
          Positioned(
            left: 20,
            top: 368,
            width: 56,
            height: 52,
            child: Tooltip(
              message: 'Workshop Settings & Profile',
              child: InkWell(
                onTap: () => widget.onNavSelected?.call(4),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.selectedNavIndex == 4
                        ? Fx.emerald
                        : Fx.container,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    boxShadow: widget.selectedNavIndex == 4 ? Fx.ctaShadow : null,
                  ),
                  alignment: Alignment.center,
                  child: _svg(SettingsAssets.Icon_1_2853, 18, 18),
                ),
              ),
            ),
          ),

          // Bottom Settings / Profile
          Positioned(
            left: 28,
            top: 728,
            width: 40,
            height: 40,
            child: Tooltip(
              message: 'Profile & Workshop Settings',
              child: InkWell(
                onTap: () => _showUserMenu(context),
                borderRadius: const BorderRadius.all(Radius.circular(Fx.pillRadius)),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _svg(SettingsAssets.Icon_1_2856, 18.3, 17.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. Header Block
  // -------------------------------------------------------------
  Widget _buildHeaderBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left Column: Configuration Engine tag, Title, Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                ),
                child: Text(
                  'CONFIGURATION ENGINE',
                  style: Fx.text(11, 14, FontWeight.w600, 0.5, color: Fx.muted),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Workshop Settings',
                style: Fx.text(32, 38, FontWeight.w800, -0.8, color: Fx.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'Configure shop telemetry, compliance protocols, and customer dispatch.',
                style: Fx.text(16, 24, FontWeight.w500, -0.16, color: Fx.muted),
              ),
            ],
          ),
        ),

        // Right Sync Status Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Fx.white,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: const Color(0xFFE3E2E7)),
            boxShadow: Fx.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Fx.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sync Status',
                    style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Shop Net Synchronized',
                    style: Fx.text(12, 16, FontWeight.w700, 0.2, color: Fx.ink),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 2. Hub Metrics Row
  // -------------------------------------------------------------
  Widget _buildMetricsRow() {
    return Row(
      children: [
        // Metric 1: ACTIVE INSPECTION BAYS
        Expanded(
          child: _buildMetricCard(
            label: 'ACTIVE INSPECTION BAYS',
            value: '08 / 08 Operational',
            icon: SettingsAssets.Icon_1_2678,
          ),
        ),
        const SizedBox(width: 24),

        // Metric 2: AUTO-DISPATCH LATENCY
        Expanded(
          child: _buildMetricCard(
            label: 'AUTO-DISPATCH LATENCY',
            value: '< 140 ms',
            icon: SettingsAssets.Icon_1_2687,
          ),
        ),
        const SizedBox(width: 24),

        // Metric 3: OPTICAL AI INTEGRITY
        Expanded(
          child: _buildMetricCard(
            label: 'OPTICAL AI INTEGRITY',
            value: '99.94%',
            icon: SettingsAssets.Icon_1_2696,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String icon,
  }) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Fx.text(11, 14, FontWeight.w600, 0.5, color: Fx.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Fx.text(22, 28, FontWeight.w700, -0.44, color: Fx.ink),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: _svg(icon, 24, 24),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. Main Stacked Form Cards
  // -------------------------------------------------------------
  Widget _buildFormCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Business Profile
        _buildBusinessProfileCard(),
        const SizedBox(height: 32),

        // Card 2: Preferences
        _buildPreferencesCard(),
      ],
    );
  }

  // Card 1: Business Profile
  Widget _buildBusinessProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                alignment: Alignment.center,
                child: _svg(SettingsAssets.Icon_1_2703, 24, 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Profile',
                      style: Fx.heading22.copyWith(color: Fx.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Public credentials stamped on certified vehicle inspection slips',
                      style: Fx.body13Medium.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                ),
                child: Text(
                  'LEGAL ENTITY',
                  style: Fx.text(11, 14, FontWeight.w600, 0.5, color: Fx.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Field 1: Workshop Name
          Text(
            'Workshop Name',
            style: Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
          ),
          const SizedBox(height: 8),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Fx.container,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: const Color(0xFFE3E2E7)),
            ),
            child: Row(
              children: [
                _svg(SettingsAssets.Icon_1_2717, 20, 20),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: Fx.text(15, 20, FontWeight.w600, 0, color: Fx.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Row: Contact Phone & Address
          Row(
            children: [
              // Contact Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Phone',
                      style: Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        border: Border.all(color: const Color(0xFFE3E2E7)),
                      ),
                      child: Row(
                        children: [
                          _svg(SettingsAssets.Icon_1_2726, 20, 20),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: Fx.text(15, 20, FontWeight.w600, 0, color: Fx.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address',
                      style: Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        border: Border.all(color: const Color(0xFFE3E2E7)),
                      ),
                      child: Row(
                        children: [
                          _svg(SettingsAssets.Icon_1_2735, 20, 20),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: Fx.text(15, 20, FontWeight.w600, 0, color: Fx.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Footnote Badges
          Row(
            children: [
              _svg(SettingsAssets.Icon_1_2742, 16, 16),
              const SizedBox(width: 8),
              Text(
                'Region: Northern Cal/Pacific Sector',
                style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
              const SizedBox(width: 24),
              _svg(SettingsAssets.Icon_1_2747, 16, 16),
              const SizedBox(width: 8),
              Text(
                'DOT Certified #99401-AF',
                style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 2: Preferences
  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                alignment: Alignment.center,
                child: _svg(SettingsAssets.Icon_1_2755, 24, 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferences',
                      style: Fx.heading22.copyWith(color: Fx.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inspection routines, optical validation, and distribution rules',
                      style: Fx.body13Medium.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: const BoxDecoration(
                  color: Fx.tintEmerald,
                  borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                ),
                child: Text(
                  'Standard Flow',
                  style: Fx.text(11, 14, FontWeight.w700, 0.2, color: Fx.emerald),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Field: Default Template
          Text(
            'Default Template',
            style: Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Fx.container,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: const Color(0xFFE3E2E7)),
            ),
            child: Row(
              children: [
                _svg(SettingsAssets.Icon_1_2771, 24, 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100-Point Standard Check v2.0',
                        style: Fx.title16.copyWith(color: Fx.ink),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Compliant with ANSI Tier-4 EV & Combustion Fleet standards',
                        style: Fx.body13Medium.copyWith(color: Fx.muted),
                      ),
                    ],
                  ),
                ),
                _svg(SettingsAssets.Icon_1_2778, 20, 20),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Toggle 1: Auto-Send PDF to Customers
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Fx.container,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: const Color(0xFFE3E2E7)),
            ),
            child: Row(
              children: [
                Switch(
                  value: _autoSendPdf,
                  activeThumbColor: Fx.emerald,
                  activeTrackColor: Fx.emerald.withValues(alpha: 0.3),
                  onChanged: (v) => setState(() => _autoSendPdf = v),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Send PDF to Customers',
                        style: Fx.title16.copyWith(color: Fx.ink),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Immediately deliver cryptographic-stamped PDF summaries via SMS & email upon technician sign-off.',
                        style: Fx.body13Medium.copyWith(color: Fx.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Toggle 2: Mandatory Optical Photo Verification
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Fx.container,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: const Color(0xFFE3E2E7)),
            ),
            child: Row(
              children: [
                Switch(
                  value: _mandatoryPhoto,
                  activeThumbColor: Fx.emerald,
                  activeTrackColor: Fx.emerald.withValues(alpha: 0.3),
                  onChanged: (v) => setState(() => _mandatoryPhoto = v),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mandatory Optical Photo Verification',
                        style: Fx.title16.copyWith(color: Fx.ink),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Forces technicians to capture at least 4 high-resolution angle photos before clearing safety critical faults.',
                        style: Fx.body13Medium.copyWith(color: Fx.muted),
                      ),
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

  // -------------------------------------------------------------
  // 4. Bottom Actions Container
  // -------------------------------------------------------------
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: _svg(SettingsAssets.Icon_1_2807, 24, 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'All changes sync to shop fleet nodes instantly with zero downtime.',
              style: Fx.body13Medium.copyWith(color: Fx.muted),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onSaveSettings,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: const BoxDecoration(
                  color: Fx.emerald,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  boxShadow: Fx.ctaShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Fx.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Save Settings',
                      style: Fx.label14.copyWith(color: Fx.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
