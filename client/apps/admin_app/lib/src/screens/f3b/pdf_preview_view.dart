import 'dart:convert';
import 'package:admin_app/src/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'pdf_preview_assets.dart';

/// Print-Ready PDF Preview View matching Figma screen 12:
/// `12_12._Print-Ready_PDF_Preview` (1280 x 1227.58)
class PrintReadyPdfPreviewView extends StatefulWidget {
  const PrintReadyPdfPreviewView({
    super.key,
    this.report,
    this.userName,
    this.userRole,
    this.onBack,
    this.onSendEmail,
    this.onDownloadPdf,
    this.onPrint,
    this.onNavSelected,
  });

  final ReportAdmin? report;
  final String? userName;
  final String? userRole;
  final VoidCallback? onBack;
  final VoidCallback? onSendEmail;
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onPrint;
  final ValueChanged<int>? onNavSelected;

  @override
  State<PrintReadyPdfPreviewView> createState() =>
      _PrintReadyPdfPreviewViewState();
}

class _PrintReadyPdfPreviewViewState extends State<PrintReadyPdfPreviewView> {
  bool _portrait = true;
  bool _includeHighRes = true;
  bool _stampSeal = true;
  int _zoomPercent = 100;

  Widget _svg(String rawSvg, double width, double height) {
    return SvgPicture.string(
      rawSvg,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  // Safe data extraction
  String get _vehicleTitle {
    final content = widget.report?.content;
    if (content != null && content['vehicle'] is Map) {
      final v = content['vehicle'] as Map;
      final y = v['year'] ?? 2024;
      final m = v['make'] ?? 'Ford';
      final mod = v['model'] ?? 'Transit 350';
      return '$y $m $mod';
    }
    return '2024 Ford Transit 350';
  }

  String get _vin {
    final content = widget.report?.content;
    if (content != null && content['vehicle'] is Map) {
      final v = content['vehicle'] as Map;
      if (v['vin'] != null) return '${v['vin']}';
    }
    return '1FTBR1Y85RKB92104';
  }

  String get _odometer {
    final content = widget.report?.content;
    if (content != null && content['vehicle'] is Map) {
      final v = content['vehicle'] as Map;
      if (v['odometer'] != null) return '${v['odometer']} mi';
    }
    return '14,820 mi';
  }

  String get _licensePlate {
    final content = widget.report?.content;
    if (content != null && content['vehicle'] is Map) {
      final v = content['vehicle'] as Map;
      if (v['licensePlate'] != null) return '${v['licensePlate']}';
    }
    return '7XYZ994 (CA)';
  }

  String get _inspectorName {
    return widget.userName ?? 'Marcus Vance';
  }

  String get _inspectorRole {
    return widget.userRole ?? 'Lead Inspector';
  }

  String get _reportNumber {
    return widget.report?.reportNumber ?? 'CERTIFICATE #1042';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;
        return Container(
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide) _buildLeftNav(context),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 1104,
                              child: isWide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 320,
                                          child: _buildLeftControls(context),
                                        ),
                                        const SizedBox(width: 32),
                                        Expanded(
                                          child: _buildRightPaperCanvas(
                                            context,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildLeftControls(context),
                                        const SizedBox(height: 24),
                                        _buildRightPaperCanvas(context),
                                      ],
                                    ),
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
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Left Navigation Aside (w: 96, h: 800)
  // ---------------------------------------------------------------------------
  Widget _buildLeftNav(BuildContext context) {
    return Container(
      width: 96,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFF4F3F8), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Badge
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x08000000),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: _svg(PdfPreviewAssets.Icon_1_3157, 22, 22),
            ),
          ),
          const SizedBox(height: 48),
          // Nav items
          _navItem(0, PdfPreviewAssets.Icon_1_3161, isSelected: false),
          const SizedBox(height: 24),
          _navItem(1, PdfPreviewAssets.Icon_1_3164, isSelected: false),
          const SizedBox(height: 24),
          _navItem(4, PdfPreviewAssets.Icon_1_3167, isSelected: false),
          const SizedBox(height: 380),
          // Bottom logout icon
          IconButton(
            onPressed: () {},
            icon: _svg(PdfPreviewAssets.Icon_1_3170, 18, 18),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _navItem(int idx, String rawSvg, {required bool isSelected}) {
    return InkWell(
      onTap: () => widget.onNavSelected?.call(idx),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1B1F) : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Center(child: _svg(rawSvg, 18, 18)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header (w: 1184, h: 80)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xE5FFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF4F3F8), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
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
                  'BAY ACTIVE',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.55,
                    color: Color(0xFF3C4A42),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Shop Floor #04',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1B1F),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Search Box
          Container(
            width: 299,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.all(Radius.circular(17)),
            ),
            child: Row(
              children: [
                _svg(PdfPreviewAssets.Icon_1_3139, 15, 15),
                const SizedBox(width: 10),
                const Text(
                  'Search VIN, tech, job ticket...',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: Color(0xFF5E5D69),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // User Badge
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _inspectorName,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1B1F),
                ),
              ),
              Text(
                _inspectorRole,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5E5D69),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1B1F),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _svg(PdfPreviewAssets.Icon_1_3151, 12, 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left Controls Column (w: 320)
  // ---------------------------------------------------------------------------
  Widget _buildLeftControls(BuildContext context) {
    return Column(
      children: [
        _buildOverviewCard(context),
        const SizedBox(height: 24),
        _buildPrintSettingsCard(context),
        const SizedBox(height: 24),
        _buildRecipientsCard(context),
      ],
    );
  }

  // Card 1: Document Overview & Actions (w: 320, h: 494)
  Widget _buildOverviewCard(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x0B000000),
            offset: Offset(0, 14),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button
          InkWell(
            onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F3F8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _svg(PdfPreviewAssets.Icon_1_2866, 12, 12),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Return to Inspection Jobs',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5E5D69),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Row(
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
                  'PDF Ready (v2.1)',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1B1F),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: const Text(
                    'AUDITED',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF006C49),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Metadata Breakdown
          const Text(
            'DOCUMENT METADATA',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.55,
              color: Color(0xFF5E5D69),
            ),
          ),
          const SizedBox(height: 12),
          _metaRow('Generated', 'Oct 24, 2024 • 14:32'),
          const SizedBox(height: 8),
          _metaRow('File Size', '2.4 MB (Vector HQ)'),
          const SizedBox(height: 8),
          _metaRow('Security Hash', 'SHA-256 #89c4...'),
          const SizedBox(height: 8),
          _metaRow(
            'Sign-off Status',
            'Cryptographically Signed',
            valueColor: const Color(0xFF006C49),
          ),
          const SizedBox(height: 24),
          // Primary CTAs
          ElevatedButton(
            onPressed: widget.onSendEmail ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email sent to fleet client.'),
                    ),
                  );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _svg(PdfPreviewAssets.Icon_1_2902, 16, 14),
                const SizedBox(width: 10),
                const Text(
                  'Send Email to Client',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: widget.onDownloadPdf ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading report PDF...')),
                  );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF4F3F8),
              foregroundColor: const Color(0xFF1A1B1F),
              minimumSize: const Size.fromHeight(56),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _svg(PdfPreviewAssets.Icon_1_2907, 14, 14),
                const SizedBox(width: 10),
                const Text(
                  'Download PDF',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: Color(0xFF5E5D69),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1B1F),
          ),
        ),
      ],
    );
  }

  // Card 2: Print Settings & Controls Module (w: 320, h: 302)
  Widget _buildPrintSettingsCard(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x0B000000),
            offset: Offset(0, 14),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRINT ORIENTATION',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.55,
                  color: Color(0xFF5E5D69),
                ),
              ),
              Text(
                'A4 Standard',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF006C49),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segmented Toggle
          Container(
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _portrait = true),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _portrait ? Colors.white : Colors.transparent,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        boxShadow: _portrait
                            ? const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _svg(
                            PdfPreviewAssets.Icon_1_2919,
                            13.5,
                            13.5,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Portrait',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: _portrait
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _portrait
                                  ? const Color(0xFF1A1B1F)
                                  : const Color(0xFF5E5D69),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _portrait = false),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !_portrait ? Colors.white : Colors.transparent,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        boxShadow: !_portrait
                            ? const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _svg(
                            PdfPreviewAssets.Icon_1_2923,
                            16.5,
                            9,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Landscape',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: !_portrait
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: !_portrait
                                  ? const Color(0xFF1A1B1F)
                                  : const Color(0xFF5E5D69),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Toggle 1: Include High-Res Evidence
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Include High-Res Evidence',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1B1F),
                      ),
                    ),
                    Text(
                      'Attach raw macro photos',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: Color(0xFF5E5D69),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _includeHighRes,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF10B981),
                onChanged: (v) => setState(() => _includeHighRes = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Toggle 2: Stamp Physical Seal
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stamp Physical Seal',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1B1F),
                      ),
                    ),
                    Text(
                      'ISO 17020 shop compliance mark',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: Color(0xFF5E5D69),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _stampSeal,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF10B981),
                onChanged: (v) => setState(() => _stampSeal = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick Print Trigger
          ElevatedButton(
            onPressed: widget.onPrint ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sending document to printer...'),
                    ),
                  );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEEEDF3),
              foregroundColor: const Color(0xFF1A1B1F),
              minimumSize: const Size.fromHeight(40),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _svg(PdfPreviewAssets.Icon_1_2945, 15, 13.5),
                const SizedBox(width: 8),
                const Text(
                  'Direct System Print',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Quick Delivery Recipients Card (w: 320, h: 120)
  Widget _buildRecipientsCard(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x04000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x0B000000),
            offset: Offset(0, 14),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ASSIGNED DISTRIBUTION',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.55,
              color: Color(0xFF5E5D69),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1B1F),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Center(
                    child: _svg(PdfPreviewAssets.Icon_1_2953, 14, 12),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apex Logistics Fleet Ops',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1B1F),
                      ),
                    ),
                    Text(
                      'fleet-compliance@apex.io',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: Color(0xFF5E5D69),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right Paper Canvas Viewport (w: 752, h: 1099.58)
  // ---------------------------------------------------------------------------
  Widget _buildRightPaperCanvas(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3F8),
        borderRadius: BorderRadius.all(Radius.circular(48)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          // Floating Toolbar (w: 400, h: 52)
          _buildFloatingToolbar(context),
          const SizedBox(height: 24),
          // Physical A4 Paper Document (w: 656, h: 927.58)
          _buildPhysicalA4Document(context),
        ],
      ),
    );
  }

  Widget _buildFloatingToolbar(BuildContext context) {
    return Container(
      width: 400,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 10),
            blurRadius: 30,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Zoom controls
          Row(
            children: [
              IconButton(
                iconSize: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  if (_zoomPercent > 50) {
                    setState(() => _zoomPercent -= 25);
                  }
                },
                icon: _svg(PdfPreviewAssets.Icon_1_2965, 13.5, 13.5),
              ),
              const SizedBox(width: 4),
              Text(
                '$_zoomPercent%',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1F),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                iconSize: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  if (_zoomPercent < 200) {
                    setState(() => _zoomPercent += 25);
                  }
                },
                icon: _svg(PdfPreviewAssets.Icon_1_2970, 13.5, 13.5),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 16,
            color: const Color(0xFFE3E2E7),
          ),
          const Text(
            'Page 1 of 1',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5E5D69),
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: const Color(0xFFE3E2E7),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Prepress Verified',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Luxury A4 Paper Document (w: 656)
  // ---------------------------------------------------------------------------
  Widget _buildPhysicalA4Document(BuildContext context) {
    return Container(
      width: 656,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(48)),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 25),
            blurRadius: 60,
          ),
        ],
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF006C49),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Center(
                  child: _svg(PdfPreviewAssets.Icon_1_2986, 13.5, 13.5),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TECHINSPECT',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Color(0xFF1A1B1F),
                    ),
                  ),
                  Text(
                    'AUTOMOTIVE PRECISION SYSTEMS',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.55,
                      color: Color(0xFF5E5D69),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Text(
                      _reportNumber,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006C49),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Issue Date: Oct 24, 2024',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      color: Color(0xFF5E5D69),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Big Headline
          const Text(
            'VEHICLE INSPECTION & COMPLIANCE CERTIFICATE',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Color(0xFF1A1B1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Official technical record conforming to Department of Transportation & Fleet Safety Directive 44B.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF5E5D69),
            ),
          ),
          const SizedBox(height: 24),
          // Vehicle Summary Bar (High Visual Contrast Card)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F8),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _vehicleSummaryItem('SUBJECT VEHICLE', _vehicleTitle, isBig: true),
                _vehicleSummaryItem('VIN NUMBER', _vin),
                _vehicleSummaryItem('ODOMETER READING', _odometer),
                _vehicleSummaryItem('LICENSE PLATE', _licensePlate),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Metrics Block (3 Badges)
          Row(
            children: [
              Expanded(
                child: _metricBadge(
                  iconSvg: PdfPreviewAssets.Icon_1_3027,
                  iconBg: const Color(0xFF10B981),
                  value: '104',
                  label: 'Checks Passed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricBadge(
                  iconSvg: PdfPreviewAssets.Icon_1_3036,
                  iconBg: const Color(0xFFFEE2E2),
                  value: '2',
                  label: 'Flagged Defects',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricBadge(
                  iconSvg: PdfPreviewAssets.Icon_1_3045,
                  iconBg: const Color(0xFFF4F3F8),
                  value: _inspectorName,
                  label: _inspectorRole,
                  isTextValue: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Diagnostic Evidence Section
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIAGNOSTIC EVIDENCE PHOTO GRID',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: Color(0xFF1A1B1F),
                ),
              ),
              Text(
                '• Macro 4K captures',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: Color(0xFF5E5D69),
                ),
              ),
              Text(
                '2 Findings Captured',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF006C49),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 2 Photo Cards
          Row(
            children: [
              Expanded(
                child: _buildPhotoCard(
                  base64Image: PdfPreviewAssets.tireTreadImageBase64,
                  tagBadge: 'Pass: 6.2 mm',
                  tagColor: const Color(0xFF10B981),
                  captionId: 'IMG_3091_R_FRONT',
                  title: 'Front Right Tire Tread Profile',
                  description:
                      'Inner/Outer wear patterns uniform within 0.3mm tolerance.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPhotoCard(
                  base64Image: PdfPreviewAssets.doorScratchImageBase64,
                  tagBadge: 'Defect #01: Scuff',
                  tagColor: const Color(0xFFBA1A1A),
                  captionId: 'IMG_3092_DOOR_SCRATCH',
                  title: 'Passenger Sliding Door Clear-Coat',
                  description:
                      'Surface paint abrasion: 42mm. Primer unbreached.',
                  showAnnotationPin: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          // Document Footer: Compliance Seal & Digital Signature
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Official Compliance Stamp
              if (_stampSeal)
                Row(
                  children: [
                    // Physical Stamp Circular Seal
                    Transform.rotate(
                      angle: 0.1, // ~6 degrees
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF006C49),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _svg(PdfPreviewAssets.Icon_1_3097, 18, 18),
                            const SizedBox(height: 2),
                            const Text(
                              'APPROVED',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF006C49),
                              ),
                            ),
                            const Text(
                              'ISO 17020',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5E5D69),
                              ),
                            ),
                            const Text(
                              'BAY #04',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF006C49),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TechInspect Certified Facility',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1B1F),
                          ),
                        ),
                        Text(
                          'Licence #DOT-CA-994012',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Audit verification code: TI-24-OCT-1042',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: Color(0xFF5E5D69),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              // Inspector Signature Box
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _svg(PdfPreviewAssets.Vector_1_3122, 133, 24),
                  const SizedBox(height: 4),
                  Container(
                    width: 180,
                    height: 1.5,
                    color: const Color(0xFF1A1B1F),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _inspectorName,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1B1F),
                    ),
                  ),
                  const Text(
                    'Master Inspector ASE #40921',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
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
    );
  }

  Widget _vehicleSummaryItem(String label, String value, {bool isBig = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.55,
            color: Color(0xFF5E5D69),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: isBig ? 15 : 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B1F),
          ),
        ),
      ],
    );
  }

  Widget _metricBadge({
    required String iconSvg,
    required Color iconBg,
    required String value,
    required String label,
    bool isTextValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3F8),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _svg(iconSvg, 18, 18),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: isTextValue ? 12 : 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1B1F),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5E5D69),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String base64Image,
    required String tagBadge,
    required Color tagColor,
    required String captionId,
    required String title,
    required String description,
    bool showAnnotationPin = false,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3F8),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Area
          Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFE3E2E7),
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              // Top-left status tag
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xE5FFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tagBadge,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1B1F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Defect annotation pin if requested
              if (showAnnotationPin)
                Positioned(
                  top: 50,
                  left: 100,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFBA1A1A),
                        width: 2,
                      ),
                      color: const Color(0x33BA1A1A),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              // Bottom-right filename badge
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xD91A1B1F),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Text(
                    captionId,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Caption Area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1B1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    height: 1.3,
                    color: Color(0xFF5E5D69),
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
