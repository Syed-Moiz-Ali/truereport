import 'package:admin_app/src/models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Workshop Staff Detail Screen.
///
/// Pixel-perfect desktop layout matching the Workshop Staff Management design language.
/// Features:
/// - 96px left navigation rail
/// - 80px floating top header
/// - Breadcrumb navigation (< Back to Staff Management)
/// - Hero staff block with avatar, name, role, status chip, bay assignment, and action CTAs
/// - 4-item Performance metrics strip
/// - Two-column dashboard:
///   - Left: Profile & Contact information, Certifications & Skill badges, NFC access & credentials
///   - Right: Active work orders in technician's queue, Shift activity & clocked hours log
class WorkshopStaffDetailView extends StatefulWidget {
  const WorkshopStaffDetailView({
    super.key,
    required this.staff,
    required this.onBack,
    this.selectedNavIndex = 2,
    this.onNavSelected,
    this.onEditStaff,
    this.onReassignBay,
    this.onSignOut,
    this.onToggleLocale,
    this.userName,
    this.userRole,
  });

  final StaffMember staff;
  final VoidCallback onBack;
  final int selectedNavIndex;
  final ValueChanged<int>? onNavSelected;
  final VoidCallback? onEditStaff;
  final VoidCallback? onReassignBay;
  final VoidCallback? onSignOut;
  final VoidCallback? onToggleLocale;
  final String? userName;
  final String? userRole;

  static const double width = 1280;
  static const double minHeight = 1125;

  @override
  State<WorkshopStaffDetailView> createState() => _WorkshopStaffDetailViewState();
}

class _WorkshopStaffDetailViewState extends State<WorkshopStaffDetailView> {
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'ST';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: WorkshopStaffDetailView.width,
          child: ColoredBox(
            color: Fx.white,
            child: Stack(
              children: [
                // Main Content area
                Padding(
                  padding: const EdgeInsets.only(left: 96, top: 80),
                  child: Container(
                    width: 1184,
                    padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Breadcrumbs & Reference Bar
                        _buildBreadcrumbsBar(),
                        const SizedBox(height: 24),

                        // Hero Header Block
                        _buildHeroBlock(),
                        const SizedBox(height: 28),

                        // Performance Metrics Strip
                        _buildMetricsStrip(),
                        const SizedBox(height: 32),

                        // Two-Column Dashboard Content
                        _buildDashboardContent(),
                      ],
                    ),
                  ),
                ),

                // Top Header Bar
                Positioned(
                  left: 96,
                  top: 0,
                  width: 1184,
                  height: 80,
                  child: _buildTopHeader(),
                ),

                // Left Rail Navigation
                Positioned(
                  left: 0,
                  top: 0,
                  width: 96,
                  bottom: 0,
                  child: _buildLeftRail(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Left Rail (96px width)
  // -------------------------------------------------------------
  Widget _buildLeftRail() {
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onNavSelected?.call(0),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.shield_outlined,
                  color: Fx.emerald,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Dashboard (0)
          _railItem(Icons.grid_view_rounded, 'Overview Dashboard', 0),
          const SizedBox(height: 12),

          // Queue (1)
          _railItem(Icons.receipt_long_rounded, 'Live Job Queue', 1),
          const SizedBox(height: 12),

          // Staff (2) - ACTIVE
          _railItem(Icons.groups_outlined, 'Staff Management', 2),
          const SizedBox(height: 12),

          // Templates (3)
          _railItem(Icons.dashboard_customize_outlined, 'Inspection Templates', 3),
          const SizedBox(height: 12),

          // Settings (4)
          _railItem(Icons.settings_outlined, 'Workshop Settings & Profile', 4),

          const Spacer(),

          // Bottom profile / menu
          Tooltip(
            message: 'Profile & Workshop Settings',
            child: InkWell(
              onTap: () => _showUserMenu(context),
              borderRadius: const BorderRadius.all(Radius.circular(Fx.pillRadius)),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.manage_accounts_outlined, color: Fx.muted, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _railItem(IconData icon, String tooltip, int index) {
    final active = widget.selectedNavIndex == index;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          if (index == 2) {
            widget.onBack();
          } else {
            widget.onNavSelected?.call(index);
          }
        },
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Container(
          width: 56,
          height: 52,
          decoration: BoxDecoration(
            color: active ? Fx.emerald : Fx.container,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            boxShadow: active ? Fx.ctaShadow : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: active ? Fx.white : Fx.muted,
            size: 20,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Top Header Bar (80px height)
  // -------------------------------------------------------------
  Widget _buildTopHeader() {
    final name = widget.userName ?? 'Marcus Vance';
    final role = widget.userRole ?? 'Lead Inspector';
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
          // Active Bay pill
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

          // Back to Staff pill button in header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onBack,
              borderRadius: BorderRadius.circular(Fx.pillRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.circular(Fx.pillRadius),
                  border: Border.all(color: const Color(0xFFE3E2E7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 14, color: Fx.ink),
                    const SizedBox(width: 6),
                    Text(
                      'Staff List',
                      style: Fx.text(12, 16, FontWeight.w600, 0, color: Fx.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          // User Info
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                name,
                style: Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.ink),
              ),
              Text(
                role,
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

  // -------------------------------------------------------------
  // Breadcrumbs & Reference Bar
  // -------------------------------------------------------------
  Widget _buildBreadcrumbsBar() {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onBack,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Fx.emerald),
                  const SizedBox(width: 8),
                  Text(
                    'Back to Staff Management',
                    style: Fx.text(13, 16, FontWeight.w600, 0, color: Fx.emerald),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(width: 1, height: 16, color: const Color(0xFFE3E2E7)),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: const BoxDecoration(
            color: Fx.container,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          child: Text(
            'EMP-${widget.staff.userId.toUpperCase().replaceAll('-', '').substring(0, widget.staff.userId.length >= 6 ? 6 : widget.staff.userId.length)}',
            style: Fx.text(12, 16, FontWeight.w700, 0.5, color: Fx.ink),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Shop Floor #04 \u2022 Northern Sector Fleet',
          style: Fx.text(12, 16, FontWeight.w500, 0, color: Fx.muted),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Hero Block
  // -------------------------------------------------------------
  Widget _buildHeroBlock() {
    final displayName = widget.staff.displayName.isNotEmpty
        ? widget.staff.displayName
        : 'David Vance';
    final role = widget.staff.role.isNotEmpty
        ? widget.staff.role
        : 'Senior Technician \u2022 Bay 02';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff Avatar
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Fx.deepGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(displayName),
              style: Fx.text(24, 30, FontWeight.w800, 0, color: Fx.white),
            ),
          ),
          const SizedBox(width: 24),

          // Details & badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                  ),
                  child: Text(
                    'CERTIFIED PERSONNEL PROFILE',
                    style: Fx.text(10, 12, FontWeight.w700, 0.5, color: Fx.muted),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayName,
                  style: Fx.text(28, 34, FontWeight.w800, -0.6, color: Fx.ink),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    // Active on shift chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Fx.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Fx.pillRadius),
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
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVE ON SHIFT',
                            style: Fx.text(11, 14, FontWeight.w700, 0.3, color: Fx.emerald),
                          ),
                        ],
                      ),
                    ),

                    // Role pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.circular(Fx.pillRadius),
                        border: Border.all(color: const Color(0xFFE3E2E7)),
                      ),
                      child: Text(
                        role,
                        style: Fx.text(11, 14, FontWeight.w600, 0.2, color: Fx.ink),
                      ),
                    ),

                    // EV Certified chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.circular(Fx.pillRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 14, color: Fx.deepGreen),
                          const SizedBox(width: 4),
                          Text(
                            'EV Certified Level 4',
                            style: Fx.text(11, 14, FontWeight.w700, 0.2, color: Fx.deepGreen),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onReassignBay,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Reassign Bay'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Fx.ink,
                      side: const BorderSide(color: Color(0xFFE3E2E7)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onEditStaff,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          boxShadow: Fx.ctaShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined, size: 16, color: Fx.white),
                            const SizedBox(width: 8),
                            Text(
                              'Edit Profile',
                              style: Fx.text(13, 16, FontWeight.w700, 0.1, color: Fx.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'NFC Badge Synced \u2022 Clocked In at 07:30 AM',
                style: Fx.text(11, 14, FontWeight.w500, 0, color: Fx.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Metrics Strip (4 Cards)
  // -------------------------------------------------------------
  Widget _buildMetricsStrip() {
    return Row(
      children: [
        Expanded(child: _metricCard('INSPECTIONS DONE', '142', '+12% this month', Icons.task_alt_rounded, Fx.deepGreen)),
        const SizedBox(width: 20),
        Expanded(child: _metricCard('AVG TURNAROUND', '38m', 'Top 5% shop speed', Icons.timer_outlined, Fx.emerald)),
        const SizedBox(width: 20),
        Expanded(child: _metricCard('QUALITY PASS RATE', '99.4%', '0 defect escalations', Icons.verified_rounded, Fx.deepGreen)),
        const SizedBox(width: 20),
        Expanded(child: _metricCard('SHIFT HOURS', '6h 12m', 'Clocked Today', Icons.schedule_rounded, Fx.ink)),
      ],
    );
  }

  Widget _metricCard(String label, String value, String caption, IconData icon, Color captionColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Fx.text(10, 12, FontWeight.w700, 0.4, color: Fx.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Fx.text(22, 28, FontWeight.w800, -0.4, color: Fx.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: Fx.text(11, 14, FontWeight.w600, 0, color: captionColor),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: Fx.muted),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Dashboard Content
  // -------------------------------------------------------------
  Widget _buildDashboardContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Width ~690px)
        Expanded(
          flex: 62,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card 1: Contact Information
              _buildContactCard(),
              const SizedBox(height: 24),

              // Card 2: Certifications & Skills
              _buildCertificationsCard(),
              const SizedBox(height: 24),

              // Card 3: Digital Credentials & Security
              _buildCredentialsCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Right Column (Width ~410px)
        Expanded(
          flex: 38,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card 1: Active Work Orders in Queue
              _buildActiveWorkOrdersCard(),
              const SizedBox(height: 24),

              // Card 2: Shift Activity Log
              _buildShiftActivityCard(),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Left Column Cards
  // -------------------------------------------------------------
  Widget _buildContactCard() {
    final email = widget.staff.emailMasked.isNotEmpty
        ? widget.staff.emailMasked
        : 'd.vance@apexfleet.io';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.badge_outlined, size: 20, color: Fx.emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile & Identification',
                      style: Fx.heading18.copyWith(color: Fx.ink),
                    ),
                    Text(
                      'Official staff record and shop dispatch contacts',
                      style: Fx.body13Medium.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _contactTile('EMAIL ADDRESS', email, Icons.email_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _contactTile('PHONE NUMBER', '+1 (555) 392-8810', Icons.phone_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _contactTile('LOCATION', 'Shop Floor #04 \u2022 Bay 02', Icons.place_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _contactTile('TENURE', 'March 2021 \u2022 3.5 yrs', Icons.calendar_today_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Fx.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Fx.text(10, 12, FontWeight.w700, 0.4, color: Fx.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Fx.text(13, 17, FontWeight.w600, 0, color: Fx.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.military_tech_outlined, size: 20, color: Fx.emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certifications & Skills',
                      style: Fx.heading18.copyWith(color: Fx.ink),
                    ),
                    Text(
                      'Verified technical masteries and regulatory clearances',
                      style: Fx.body13Medium.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Skill rows
          _skillRow('EV Certified Level 4', 'High-Voltage Battery, Inverter & Drive Unit Safety Protocol', Icons.bolt_rounded, Fx.deepGreen),
          const SizedBox(height: 12),
          _skillRow('ASE Master Technician', 'Certified across Powertrain, Chassis, Brakes & Electrical Systems', Icons.verified_user_rounded, Fx.emerald),
          const SizedBox(height: 12),
          _skillRow('OBD-II Diagnostic Specialist', 'CAN-Bus Telemetry, Live Waveform Analysis & DTC Clearing', Icons.memory_rounded, const Color(0xFF2563EB)),
          const SizedBox(height: 12),
          _skillRow('DOT Certified Inspector #99401', 'State and Federal Commercial Fleet Vehicle Clearance Authority', Icons.assignment_turned_in_rounded, Fx.ink),
        ],
      ),
    );
  }

  Widget _skillRow(String title, String desc, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Fx.text(13, 17, FontWeight.w700, 0, color: Fx.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: Fx.text(11, 14, FontWeight.w500, 0, color: Fx.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.nfc_rounded, size: 20, color: Fx.emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFC Access & Digital Key',
                      style: Fx.heading18.copyWith(color: Fx.ink),
                    ),
                    Text(
                      'Cryptographic shop floor card and ledger signing key',
                      style: Fx.body13Medium.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NFC KEYCARD SERIAL', style: Fx.text(10, 12, FontWeight.w700, 0.4, color: Fx.muted)),
                      const SizedBox(height: 4),
                      Text('04:A2:8B:19:EF:41', style: Fx.text(13, 16, FontWeight.w700, 0.5, color: Fx.ink)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SECURITY CLEARANCE', style: Fx.text(10, 12, FontWeight.w700, 0.4, color: Fx.muted)),
                      const SizedBox(height: 4),
                      Text('Tier-3 Lead Sign-Off', style: Fx.text(13, 16, FontWeight.w700, 0, color: Fx.emerald)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Right Column Cards
  // -------------------------------------------------------------
  Widget _buildActiveWorkOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.car_repair_rounded, size: 18, color: Fx.emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Active Work Orders',
                  style: Fx.heading18.copyWith(color: Fx.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                ),
                child: Text(
                  '2 Assigned',
                  style: Fx.text(11, 14, FontWeight.w700, 0.2, color: Fx.emerald),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Job 1
          _workOrderTile('2024 Porsche 911 GT3 RS', 'In Progress \u2022 68%', 'Bay #02', Fx.emerald),
          const SizedBox(height: 12),
          // Active Job 2
          _workOrderTile('2023 Ford F-150 Lightning', 'Scheduled \u2022 11:30 AM', 'Bay #02', Fx.muted),
        ],
      ),
    );
  }

  Widget _workOrderTile(String vehicle, String status, String bay, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.directions_car_filled_rounded, size: 20, color: Fx.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle,
                  style: Fx.text(13, 16, FontWeight.w700, 0, color: Fx.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: Fx.text(11, 14, FontWeight.w600, 0, color: statusColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              bay,
              style: Fx.text(11, 14, FontWeight.w700, 0, color: Fx.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftActivityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.history_rounded, size: 18, color: Fx.emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Shift Activity Log',
                  style: Fx.heading18.copyWith(color: Fx.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _logItem('07:30 AM', 'Clocked in at Shop Floor #04 \u2022 Bay 02 opened'),
          const SizedBox(height: 12),
          _logItem('08:15 AM', 'Initiated 100-Point Inspection on Porsche 911'),
          const SizedBox(height: 12),
          _logItem('09:40 AM', 'Completed 68 points, captured 14 optical photos'),
          const SizedBox(height: 12),
          _logItem('11:00 AM', 'OBD-II CAN telemetry scan verified clean'),
        ],
      ),
    );
  }

  Widget _logItem(String time, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Fx.container,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            time,
            style: Fx.text(10, 12, FontWeight.w700, 0, color: Fx.muted),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Fx.text(12, 16, FontWeight.w500, 0, color: Fx.ink),
          ),
        ),
      ],
    );
  }
}
