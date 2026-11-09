import 'package:admin_app/src/models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Workshop Job Detail Screen.
///
/// Pixel-perfect desktop layout matching the Live Job Queue UI design system.
/// Features:
/// - 96px left navigation rail
/// - 80px floating top header
/// - Breadcrumb navigation (< Back to Live Queue)
/// - Hero work order block with vehicle name, VIN, plate, status, and action CTAs
/// - Two-column dashboard:
///   - Left: Vehicle specs, customer details, inspection protocol progress
///   - Right: Assigned bay & inspector, live telemetry feed, cryptographic audit seal
class WorkshopJobDetailView extends StatefulWidget {
  const WorkshopJobDetailView({
    super.key,
    required this.job,
    required this.onBack,
    this.selectedNavIndex = 1,
    this.onNavSelected,
    this.onAssignTechnician,
    this.onPreviewPdf,
    this.onMarkComplete,
    this.onSignOut,
    this.onToggleLocale,
    this.userName,
    this.userRole,
  });

  final WorkshopJob job;
  final VoidCallback onBack;
  final int selectedNavIndex;
  final ValueChanged<int>? onNavSelected;
  final VoidCallback? onAssignTechnician;
  final VoidCallback? onPreviewPdf;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onSignOut;
  final VoidCallback? onToggleLocale;
  final String? userName;
  final String? userRole;

  static const double width = 1280;
  static const double minHeight = 1125;

  @override
  State<WorkshopJobDetailView> createState() => _WorkshopJobDetailViewState();
}

class _WorkshopJobDetailViewState extends State<WorkshopJobDetailView> {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: WorkshopJobDetailView.width,
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
                        const SizedBox(height: 32),

                        // Two-Column Dashboard
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

          // Queue (1) - ACTIVE
          _railItem(Icons.receipt_long_rounded, 'Live Job Queue', 1),
          const SizedBox(height: 12),

          // Staff (2)
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
          if (index == 1) {
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

          // Back to Queue pill button in header
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
                      'Live Queue',
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
                    'Back to Live Queue',
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
            widget.job.reference.isNotEmpty ? widget.job.reference : '#JOB-2024-0891',
            style: Fx.text(12, 16, FontWeight.w700, 0.5, color: Fx.ink),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Created Today \u2022 Bay #04 Operational',
          style: Fx.text(12, 16, FontWeight.w500, 0, color: Fx.muted),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Hero Block
  // -------------------------------------------------------------
  Widget _buildHeroBlock() {
    final vehicleTitle = widget.job.vehicleModel.isNotEmpty
        ? widget.job.vehicleModel
        : '2024 Porsche 911 GT3 RS';
    final plate = widget.job.vehiclePlate?.isNotEmpty == true
        ? widget.job.vehiclePlate!
        : 'CA 8XYZ901';
    final vin = widget.job.vehicleVin?.isNotEmpty == true
        ? widget.job.vehicleVin!
        : 'WP0AB2A87LS290042';

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
          // Left: Vehicle icon avatar
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.directions_car_filled_rounded,
              size: 38,
              color: Fx.emerald,
            ),
          ),
          const SizedBox(width: 24),

          // Middle: Title & badges
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
                    'VEHICLE INSPECTION WORK ORDER',
                    style: Fx.text(10, 12, FontWeight.w700, 0.5, color: Fx.muted),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vehicleTitle,
                  style: Fx.text(28, 34, FontWeight.w800, -0.6, color: Fx.ink),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    // Status chip
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
                            widget.job.status.replaceAll('_', ' '),
                            style: Fx.text(11, 14, FontWeight.w700, 0.3, color: Fx.emerald),
                          ),
                        ],
                      ),
                    ),

                    // License Plate
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.circular(Fx.pillRadius),
                        border: Border.all(color: const Color(0xFFE3E2E7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag_rounded, size: 13, color: Fx.muted),
                          const SizedBox(width: 4),
                          Text(
                            plate,
                            style: Fx.text(11, 14, FontWeight.w700, 0.3, color: Fx.ink),
                          ),
                        ],
                      ),
                    ),

                    // VIN
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.circular(Fx.pillRadius),
                      ),
                      child: Text(
                        'VIN: $vin',
                        style: Fx.text(11, 14, FontWeight.w600, 0.2, color: Fx.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  // Secondary: PDF Preview
                  OutlinedButton.icon(
                    onPressed: widget.onPreviewPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('PDF Preview'),
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

                  // Primary CTA: Assign / Mark Complete
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onAssignTechnician,
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
                            const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Fx.white),
                            const SizedBox(width: 8),
                            Text(
                              'Assign Technician',
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
                'Live Telemetry Active \u2022 Shop Net Synchronized',
                style: Fx.text(11, 14, FontWeight.w500, 0, color: Fx.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Dashboard Two-Column Layout
  // -------------------------------------------------------------
  Widget _buildDashboardContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Width ~690px)
        Expanded(
          flex: 65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card 1: Vehicle Specifications
              _buildVehicleSpecsCard(),
              const SizedBox(height: 24),

              // Card 2: Customer & Account Details
              _buildCustomerCard(),
              const SizedBox(height: 24),

              // Card 3: Inspection Protocol & Progress
              _buildProtocolCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Right Column (Width ~390px)
        Expanded(
          flex: 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card 1: Assigned Bay & Technician
              _buildBayTechnicianCard(),
              const SizedBox(height: 24),

              // Card 2: Live Diagnostic Feed
              _buildDiagnosticCard(),
              const SizedBox(height: 24),

              // Card 3: Cryptographic Audit Seal
              _buildCryptographicSealCard(),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Card 1: Vehicle Specifications
  // -------------------------------------------------------------
  Widget _buildVehicleSpecsCard() {
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
                child: const Icon(Icons.directions_car_outlined, size: 20, color: Fx.emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Specifications',
                      style: Fx.heading18.copyWith(color: Fx.ink),
                    ),
                    Text(
                      'Telemetry verified via OBD-II & VIN decoder',
                      style: Fx.body13Medium.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                ),
                child: Text(
                  'CONFIRMED',
                  style: Fx.text(10, 12, FontWeight.w700, 0.4, color: Fx.deepGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2x3 Grid of Specs
          Row(
            children: [
              Expanded(child: _specTile('Odometer', '14,280 mi', Icons.speed_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _specTile('Powertrain', '4.0L Boxer-6 Flat (518 HP)', Icons.settings_suggest_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _specTile('Transmission', '7-Speed Dual Clutch (PDK)', Icons.sync_alt_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _specTile('Fuel / SoC', '84% Capacity Normal', Icons.battery_charging_full_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _specTile('Exterior Trim', 'Shark Blue / Weissach Pkg', Icons.palette_outlined)),
              const SizedBox(width: 16),
              Expanded(child: _specTile('Safety Class', 'DOT Level-4 Certified', Icons.verified_user_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E2E7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Fx.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Fx.text(11, 14, FontWeight.w600, 0.3, color: Fx.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Fx.text(13, 17, FontWeight.w700, 0, color: Fx.ink),
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

  // -------------------------------------------------------------
  // Card 2: Customer & Account Details
  // -------------------------------------------------------------
  Widget _buildCustomerCard() {
    final customer = widget.job.customerName.isNotEmpty
        ? widget.job.customerName
        : 'Enterprise Holdings Fleet Operations';
    final phone = widget.job.customerPhone?.isNotEmpty == true
        ? widget.job.customerPhone!
        : '+1 (555) 019-2834';
    final email = widget.job.customerEmail?.isNotEmpty == true
        ? widget.job.customerEmail!
        : 'fleet.dispatch@enterprise.corp';

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
                child: const Icon(Icons.business_center_outlined, size: 20, color: Fx.emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer & Dispatch Details',
                      style: Fx.heading18.copyWith(color: Fx.ink),
                    ),
                    Text(
                      'Primary contact for inspection sign-off & report delivery',
                      style: Fx.body13Medium.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                ),
                child: Text(
                  'COMMERCIAL FLEET',
                  style: Fx.text(10, 12, FontWeight.w700, 0.4, color: Fx.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Details Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUSTOMER / COMPANY',
                      style: Fx.text(10, 12, FontWeight.w700, 0.4, color: Fx.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer,
                      style: Fx.text(14, 18, FontWeight.w700, 0, color: Fx.ink),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHONE NUMBER',
                      style: Fx.text(10, 12, FontWeight.w700, 0.4, color: Fx.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: Fx.text(14, 18, FontWeight.w600, 0, color: Fx.ink),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMAIL DISPATCH',
                      style: Fx.text(10, 12, FontWeight.w700, 0.4, color: Fx.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Fx.text(14, 18, FontWeight.w600, 0, color: Fx.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Card 3: Inspection Protocol & Checklist Progress
  // -------------------------------------------------------------
  Widget _buildProtocolCard() {
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
                child: const Icon(Icons.checklist_rounded, size: 20, color: Fx.emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inspection Protocol & Progress',
                      style: Fx.heading18.copyWith(color: Fx.ink),
                    ),
                    Text(
                      '100-Point Standard Check v2.0 (ANSI Tier-4 Fleet Protocol)',
                      style: Fx.body13Medium.copyWith(color: Fx.muted),
                    ),
                  ],
                ),
              ),
              Text(
                '68%',
                style: Fx.text(22, 28, FontWeight.w800, -0.4, color: Fx.emerald),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              color: Fx.container,
              child: Row(
                children: [
                  Expanded(
                    flex: 68,
                    child: Container(color: Fx.emerald),
                  ),
                  Expanded(
                    flex: 32,
                    child: Container(color: Colors.transparent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '68 of 100 items verified',
                style: Fx.text(12, 16, FontWeight.w600, 0, color: Fx.ink),
              ),
              Text(
                '32 pending technician check',
                style: Fx.text(12, 16, FontWeight.w500, 0, color: Fx.muted),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Categories Breakdown
          _categoryProgressRow('Powertrain & High-Voltage System', 20, 20, 'All Clear', Fx.deepGreen),
          const SizedBox(height: 12),
          _categoryProgressRow('Brake System & Hydraulic Lines', 18, 20, '1 Minor Pad Wear', const Color(0xFFD97706)),
          const SizedBox(height: 12),
          _categoryProgressRow('Chassis, Steering & Suspension', 15, 25, 'In Progress', Fx.emerald),
          const SizedBox(height: 12),
          _categoryProgressRow('Optical Sensors & Exterior Glass', 15, 35, '1 Stone Chip', const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _categoryProgressRow(String title, int done, int total, String statusNote, Color noteColor) {
    final pct = (done / total * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Fx.text(13, 16, FontWeight.w700, 0, color: Fx.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '$done / $total points inspected ($pct%)',
                  style: Fx.text(11, 14, FontWeight.w500, 0, color: Fx.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: noteColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Fx.pillRadius),
            ),
            child: Text(
              statusNote,
              style: Fx.text(11, 14, FontWeight.w700, 0.2, color: noteColor),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Right Column Cards
  // -------------------------------------------------------------
  Widget _buildBayTechnicianCard() {
    final techName = widget.job.assignedTechnicianName?.isNotEmpty == true
        ? widget.job.assignedTechnicianName!
        : 'Marcus Vance';

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
                child: const Icon(Icons.garage_rounded, size: 18, color: Fx.emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Assigned Bay',
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
                  'BAY #04',
                  style: Fx.text(11, 14, FontWeight.w700, 0.4, color: Fx.emerald),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tech Avatar and Name
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Fx.deepGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'MV',
                    style: Fx.text(14, 18, FontWeight.w700, 0, color: Fx.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        techName,
                        style: Fx.text(14, 18, FontWeight.w700, 0, color: Fx.ink),
                      ),
                      Text(
                        'Lead Inspector \u2022 Level 4 Master',
                        style: Fx.text(11, 14, FontWeight.w500, 0, color: Fx.muted),
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

  Widget _buildDiagnosticCard() {
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
                child: const Icon(Icons.cell_tower_rounded, size: 18, color: Fx.emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Live Diagnostic Feed',
                  style: Fx.heading18.copyWith(color: Fx.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Diagnostic items
          _feedRow(Icons.check_circle_outline, 'OBD-II Telemetry', 'Active Stream - Clean (0 DTC)', Fx.deepGreen),
          const SizedBox(height: 12),
          _feedRow(Icons.timer_outlined, 'Inspection Duration', '42m Elapsed / ~60m Est.', Fx.ink),
          const SizedBox(height: 12),
          _feedRow(Icons.camera_alt_outlined, 'Optical Evidence', '14 Photos Captured & Verified', Fx.ink),
        ],
      ),
    );
  }

  Widget _feedRow(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Fx.text(12, 16, FontWeight.w600, 0, color: Fx.muted),
              ),
              Text(
                subtitle,
                style: Fx.text(13, 16, FontWeight.w700, 0, color: Fx.ink),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCryptographicSealCard() {
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
                child: const Icon(Icons.security_rounded, size: 18, color: Fx.emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Audit & Cryptography',
                  style: Fx.heading18.copyWith(color: Fx.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'SHA-256 Ledger Stamp:',
            style: Fx.text(11, 14, FontWeight.w600, 0.2, color: Fx.muted),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '8f3b2904a1c58e7428fb4199da2058b73a24',
              style: Fx.text(11, 14, FontWeight.w500, 0.5, color: Fx.ink),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 16, color: Fx.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tamper-Proof Certificate Ready',
                  style: Fx.text(11, 14, FontWeight.w600, 0, color: Fx.emerald),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
