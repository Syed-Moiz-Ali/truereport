import 'dart:convert';
import 'dart:ui' as ui;

import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/screens/f3b/completed_report_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Screen 9 — Completed Report Viewer.
///
/// Pixel-perfect 1280 desktop layout matching Figma spec
/// `09_9._Completed_Report_Viewer` (node `1:2236`, 1280 x 1680.75).
class CompletedReportView extends StatefulWidget {
  const CompletedReportView({
    super.key,
    this.report,
    this.selectedNavIndex = 1,
    this.onNavSelected,
    this.onResendWhatsApp,
    this.onResendSms,
    this.onDownloadPdf,
    this.onPreviewPdf,
    this.onDeactivateLink,
    this.onSearch,
    this.searchController,
    this.onSignOut,
    this.onToggleLocale,
    this.userName,
    this.userRole,
  });

  final ReportAdmin? report;
  final int selectedNavIndex;
  final ValueChanged<int>? onNavSelected;
  final VoidCallback? onResendWhatsApp;
  final VoidCallback? onResendSms;
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onPreviewPdf;
  final ValueChanged<String>? onDeactivateLink;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;
  final VoidCallback? onSignOut;
  final VoidCallback? onToggleLocale;
  final String? userName;
  final String? userRole;

  static const double width = 1280;
  static const double height = 1680.75;

  @override
  State<CompletedReportView> createState() => _CompletedReportViewState();
}

class _CompletedReportViewState extends State<CompletedReportView> {
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
    final report = widget.report;
    final content = report?.content ?? const <String, dynamic>{};
    final vehicle = content['vehicle'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final make = vehicle['make'] as String? ?? '';
    final model = vehicle['model'] as String? ?? '';
    final customer = content['customer'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final customerName = customer['name'] as String? ?? '';
    final vinVal = vehicle['vin'] as String? ?? '';

    final vehicleTitle = (make.isNotEmpty && model.isNotEmpty)
        ? '$make $model'
        : '2024 Ford Transit 350 High Roof';
    final vehicleSubtitle = customerName.isNotEmpty
        ? '$customerName / Fleet Transport'
        : 'Renault Megan 3 / Fleet Transport';
    final vin = vinVal.isNotEmpty ? vinVal : '1FTBR1Y85RKB92104';
    final reportId = (report != null && report.reportNumber.isNotEmpty)
        ? report.reportNumber
        : '#1042';

    return SizedBox(
      width: CompletedReportView.width,
      height: CompletedReportView.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background canvas #F4F3F8
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF4F3F8),
            ),
          ),

          // Main Scrollable / Static Layout (x: 96, y: 0, w: 1184)
          Positioned(
            left: 96,
            top: 0,
            width: 1184,
            height: CompletedReportView.height,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: 1184,
                height: CompletedReportView.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Header row (y: 80 to 221)
                    Positioned(
                      left: 40, // 136 - 96
                      top: 80,
                      width: 1104,
                      height: 141,
                      child: _buildTitleRow(reportId),
                    ),

                    // Main Report Card (x: 136 - 96 = 40, y: 221, w: 1104, h: 1333.8)
                    Positioned(
                      left: 40,
                      top: 221,
                      width: 1104,
                      height: 1333.8,
                      child: _buildMainCard(
                        vehicleTitle: vehicleTitle,
                        vehicleSubtitle: vehicleSubtitle,
                        vin: vin,
                      ),
                    ),

                    // Footer (x: 40, y: 1554.8, w: 1104, h: 78)
                    Positioned(
                      left: 40,
                      top: 1554.8,
                      width: 1104,
                      height: 78,
                      child: _buildFooter(),
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
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE3E2E7), width: 1),
        ),
      ),
      child: Row(
        children: [
          // "BAY ACTIVE" Pill (229.7 x 32)
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(9999)),
              border: Border.all(color: const Color(0xFFE3E2E7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3310B981),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'BAY ACTIVE',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: Color(0xFF3C4A42),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Shop Floor #04',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF1A1B1F),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Search Box (299 x 34)
          Container(
            width: 299,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.all(Radius.circular(9999)),
            ),
            child: Row(
              children: [
                _svg(CompletedReportAssets.Icon_1_2470, 15, 15),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: widget.onSearch,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Search VIN, tech, job ticket...',
                      hintStyle: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Color(0xFF5E5D69),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      color: Color(0xFF1A1B1F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // User info
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.userName ?? 'Marcus Vance',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1B1F),
                ),
              ),
              Text(
                widget.userRole ?? 'Lead Inspector',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Color(0xFF5E5D69),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // User Avatar (32 x 32)
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF006C49),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'MV',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Aside Navigation (x: 0, y: 0, w: 96, h: 800)
  // -------------------------------------------------------------
  Widget _buildAside() {
    return Container(
      width: 96,
      height: 800,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE3E2E7), width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Logo (24, 32, 48x48)
          Positioned(
            left: 24,
            top: 32,
            width: 48,
            height: 48,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F3F8),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: _svg(CompletedReportAssets.Icon_1_2488, 21.67, 21.67),
            ),
          ),

          // Nav Dashboard (top: 128)
          Positioned(
            left: 20,
            top: 128,
            width: 56,
            height: 56,
            child: InkWell(
              onTap: () => widget.onNavSelected?.call(0),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.selectedNavIndex == 0
                      ? const Color(0xFF006C49)
                      : Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                alignment: Alignment.center,
                child: _svg(CompletedReportAssets.Icon_1_2492, 18, 18),
              ),
            ),
          ),

          // Nav Jobs (top: 208)
          Positioned(
            left: 20,
            top: 208,
            width: 56,
            height: 56,
            child: InkWell(
              onTap: () => widget.onNavSelected?.call(1),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.selectedNavIndex == 1
                      ? const Color(0xFF006C49)
                      : Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                alignment: Alignment.center,
                child: _svg(CompletedReportAssets.Icon_1_2495, 18, 20),
              ),
            ),
          ),

          // Nav Settings (top: 288)
          Positioned(
            left: 20,
            top: 288,
            width: 56,
            height: 56,
            child: InkWell(
              onTap: () => widget.onNavSelected?.call(4),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.selectedNavIndex == 4
                      ? const Color(0xFF006C49)
                      : Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                ),
                alignment: Alignment.center,
                child: _svg(CompletedReportAssets.Icon_1_2498, 18, 18),
              ),
            ),
          ),

          // Bottom Settings / Profile (top: 728)
          Positioned(
            left: 28,
            top: 728,
            width: 40,
            height: 40,
            child: InkWell(
              onTap: widget.onSignOut,
              borderRadius: const BorderRadius.all(Radius.circular(9999)),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F3F8),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: _svg(CompletedReportAssets.Icon_1_2501, 18.3, 17.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Title / Actions Row (w: 1104, h: 141)
  // -------------------------------------------------------------
  Widget _buildTitleRow(String reportId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left Column: Badge, Title, Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Badge (AUDIT SEALED & LOCKED • SHA-256 #89c41f)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(9999)),
                  border: Border.all(color: const Color(0xFFE3E2E7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AUDIT SEALED & LOCKED',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.55,
                        color: Color(0xFF3C4A42),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '• SHA-256 #89c41f',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Color(0xFF5E5D69),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Heading
              Text(
                'Report $reportId — Finalized',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  color: Color(0xFF1A1B1F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inspected by Marcus Vance on Oct 24 • Verified via Bay 04 Telematics',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF5E5D69),
                ),
              ),
            ],
          ),
        ),

        // Right Buttons Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Resend WhatsApp Button (201 x 56, bg: #006C49, text: white)
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onResendWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C49),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _svg(CompletedReportAssets.Icon_1_2256, 17.4, 14.7),
                    const SizedBox(width: 12),
                    const Text(
                      'Resend WhatsApp',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Resend SMS Button (160.9 x 56, bg: white, border: #E3E2E7)
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: widget.onResendSms,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A1B1F),
                  side: const BorderSide(color: Color(0xFFE3E2E7)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _svg(CompletedReportAssets.Icon_1_2261, 18.3, 18.3),
                    const SizedBox(width: 12),
                    const Text(
                      'Resend SMS',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Download PDF Button (173.3 x 56, bg: white, border: #E3E2E7)
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: widget.onDownloadPdf,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A1B1F),
                  side: const BorderSide(color: Color(0xFFE3E2E7)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _svg(CompletedReportAssets.Icon_1_2266, 14.7, 14.7),
                    const SizedBox(width: 12),
                    const Text(
                      'Download PDF',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.onPreviewPdf != null) ...[
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: widget.onPreviewPdf,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A1B1F),
                    side: const BorderSide(color: Color(0xFFE3E2E7)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_outlined, size: 18, color: Color(0xFF5E5D69)),
                      SizedBox(width: 8),
                      Text(
                        'Print Preview',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Main Report Card (w: 1104, h: 1333.8)
  // -------------------------------------------------------------
  Widget _buildMainCard({
    required String vehicleTitle,
    required String vehicleSubtitle,
    required String vin,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Vehicle Header Row (h: 243.8)
          _buildVehicleHeaderRow(
            vehicleTitle: vehicleTitle,
            vehicleSubtitle: vehicleSubtitle,
            vin: vin,
          ),
          const SizedBox(height: 48),

          // 2. Diagnostic Completeness Card (h: 174, bg: #F4F3F8)
          _buildDiagnosticCompletenessCard(),
          const SizedBox(height: 32),

          // 3. Category Grid: Tire Condition & Engine Diagnostics (h: 374)
          _buildCategoryGrid(),
          const SizedBox(height: 32),

          // 4. Observed Fleet Action Items Banner (h: 112)
          _buildActionItemsBanner(),
          const SizedBox(height: 48),

          // 5. Digital Certification Seal & Authorized Delivery Channel (h: 158)
          _buildSealAndDeliveryRow(),
        ],
      ),
    );
  }

  // 1. Vehicle Header Row
  Widget _buildVehicleHeaderRow({
    required String vehicleTitle,
    required String vehicleSubtitle,
    required String vin,
  }) {
    return SizedBox(
      height: 243.8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Info (width: 562)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Stage Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F3F8),
                        borderRadius: BorderRadius.all(Radius.circular(9999)),
                      ),
                      child: const Text(
                        'FLEET COMMERCIAL',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: Color(0xFF5E5D69),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Passed Certification Stage',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Color(0xFF006C49),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vehicle Title
                Text(
                  vehicleTitle,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: Color(0xFF1A1B1F),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),

                // Vehicle Subtitle
                Text(
                  vehicleSubtitle,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF5E5D69),
                  ),
                ),
                const Spacer(),

                // Chips Row: VIN + Odometer + In Service
                Row(
                  children: [
                    // VIN pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F3F8),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'VIN ',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Color(0xFF5E5D69),
                            ),
                          ),
                          Text(
                            vin,
                            style: const TextStyle(
                              fontFamily: 'Liberation Mono',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF1A1B1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Odometer
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _svg(CompletedReportAssets.Icon_1_2290, 15, 12),
                        const SizedBox(width: 8),
                        const Text(
                          '24,812 mi Odometer',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),

                    // In Service
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _svg(CompletedReportAssets.Icon_1_2295, 13.5, 15),
                        const SizedBox(width: 8),
                        const Text(
                          'In Service: 11 Mo',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),

          // Right Vehicle Photo Card (390 x 243.8)
          Container(
            width: 390,
            height: 243.8,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              color: Color(0xFFF4F3F8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Vehicle image
                Image.memory(
                  base64Decode(CompletedReportAssets.vehicleImageBase64),
                  fit: BoxFit.cover,
                ),

                // Blur pill: HD Scans Attached (18)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(9999)),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        color: const Color(0xE6FFFFFF),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'HD Scans Attached (18)',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: Color(0xFF1A1B1F),
                              ),
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

  // 2. Diagnostic Completeness Card
  Widget _buildDiagnosticCompletenessCard() {
    return Container(
      height: 174,
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3F8),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DIAGNOSTIC COMPLETENESS',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: Color(0xFF5E5D69),
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '104 Checks Completed',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: Color(0xFF1A1B1F),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'of 106 Required',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF5E5D69),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // 102 Cleared pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(9999)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '102 Cleared',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF1A1B1F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 2 Defects Found pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.all(Radius.circular(9999)),
                ),
                child: const Text(
                  '2 Defects Found',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFFB91A24),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Progress Bar (h: 8)
          Container(
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFE3E2E7),
              borderRadius: BorderRadius.all(Radius.circular(9999)),
            ),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.981,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.all(Radius.circular(9999)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Subtext Row
          const Row(
            children: [
              Text(
                '98.1% Specification Compliance',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Color(0xFF5E5D69),
                ),
              ),
              Spacer(),
              Text(
                'Target Fleet Threshold: >95.0%',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Color(0xFF5E5D69),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Category Grid: Tire Condition & Engine Diagnostics
  Widget _buildCategoryGrid() {
    return SizedBox(
      height: 374,
      child: Row(
        children: [
          // Card 1: Tire Condition (width: 480)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: const Color(0xFFE3E2E7)),
              ),
              padding: const EdgeInsets.all(24),
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
                          color: Color(0xFFF4F3F8),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        alignment: Alignment.center,
                        child: _svg(CompletedReportAssets.Icon_1_2336, 25.7, 22.2),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.all(Radius.circular(9999)),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF006C49),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tire Condition: Verified',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF1A1B1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Four-corner optical tread depth and load pressure calibration',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: Color(0xFF5E5D69),
                    ),
                  ),
                  const Spacer(),

                  // Metric Boxes Row
                  Row(
                    children: [
                      // Box 1: Front Steer
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Front Steer Tread',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF5E5D69),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '8.2 / 8.5 mm',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1A1B1F),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Even Wear Profile',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF006C49),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Box 2: Rear Drive
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rear Drive Tread',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF5E5D69),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '9.0 / 9.1 mm',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1A1B1F),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tire TPMS 71 PSI',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF006C49),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Footer: Sidewalls check
                  Row(
                    children: [
                      _svg(CompletedReportAssets.Icon_1_2359, 12.2, 9),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Sidewalls clear of structural fissures or bead abrasions',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),

          // Card 2: Engine Diagnostics (width: 480)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: const Color(0xFFE3E2E7)),
              ),
              padding: const EdgeInsets.all(24),
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
                          color: Color(0xFFF4F3F8),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        alignment: Alignment.center,
                        child: _svg(CompletedReportAssets.Icon_1_2366, 21, 23.3),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.all(Radius.circular(9999)),
                        ),
                        child: const Text(
                          'Passed',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF006C49),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Engine Diagnostics: Passed',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF1A1B1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Full OBD-II ECU telemetry scan & exhaust gas recirc balance',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: Color(0xFF5E5D69),
                    ),
                  ),
                  const Spacer(),

                  // Metric Boxes Row
                  Row(
                    children: [
                      // Box 1: Fault Codes (DTC)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fault Codes (DTC)',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF5E5D69),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '0 Active / 0 Pending',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF006C49),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'MIL Lamp Extinguished',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF5E5D69),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Box 2: Fluid Viscosity
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fluid Viscosity Index',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF5E5D69),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Grade 5W-30 OK',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF1A1B1F),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Coolant -35°F Safe',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Color(0xFF006C49),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Footer: Alternator rail charging
                  Row(
                    children: [
                      _svg(CompletedReportAssets.Icon_1_2389, 12.2, 9),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Alternator rail charging stable at 14.3V under full load',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Observed Fleet Action Items Banner (h: 112)
  Widget _buildActionItemsBanner() {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: const Color(0xFFE3E2E7)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            alignment: Alignment.center,
            child: _svg(CompletedReportAssets.Icon_1_2396, 23.8, 20.6),
          ),
          const SizedBox(width: 16),

          // Action Items text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text(
                      'Observed Fleet Action Items (2)',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF1A1B1F),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.all(Radius.circular(9999)),
                      ),
                      child: const Text(
                        'MINOR',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: Color(0xFFB91A24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rear cargo threshold scuff (cosmetic, non-structural) & washer reservoir low level.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Color(0xFF5E5D69),
                  ),
                ),
              ],
            ),
          ),

          // Right Status Pill: Logged in Bay Ledger • Scheduled at Next Cycle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Logged in Bay Ledger',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Color(0xFF5E5D69),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3E2E7),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Scheduled at Next Cycle',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF1A1B1F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Digital Certification Seal & Authorized Delivery Channel (h: 158)
  Widget _buildSealAndDeliveryRow() {
    return SizedBox(
      height: 158,
      child: Row(
        children: [
          // Left Card: Digital Certification Seal (width: 650.7)
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F3F8),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // QR Seal Composite SVG (80 x 80)
                  _svg(CompletedReportAssets.comp_Background_Shadow_1_2413, 80, 80),
                  const SizedBox(width: 24),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Digital Certification Seal',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF1A1B1F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _svg(CompletedReportAssets.Icon_1_2437, 13.3, 16.7),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Digitally cryptographically signed by Inspector Marcus Vance. Timestamp: Oct 24,\n2024 at 14:38:11 UTC. Scan QR to view live cloud ledger.',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Color(0xFF5E5D69),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'URN: fleet:inspect:2024:ord:1042:vance:58f7009be12',
                          style: TextStyle(
                            fontFamily: 'Liberation Mono',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: Color(0xFF3C4A42),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),

          // Right Card: Authorized Delivery Channel (width: 309.3)
          SizedBox(
            width: 309.3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: const Color(0xFFE3E2E7)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'AUTHORIZED DELIVERY CHANNEL',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: Color(0xFF5E5D69),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Acme Logistics Dispatch',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF1A1B1F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'dispatch@acmelogistics.corp',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: Color(0xFF5E5D69),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF006C49),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Read Receipt Confirmed',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Color(0xFF006C49),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Footer (w: 1104, h: 78)
  // -------------------------------------------------------------
  Widget _buildFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Automotive Telematics Protocol v4.8 • ISO/IEC 27001 Authenticated',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: Color(0xFF5E5D69),
          ),
        ),
        Text(
          'Report Storage: Immutable Record Active',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: Color(0xFF5E5D69),
          ),
        ),
      ],
    );
  }
}
