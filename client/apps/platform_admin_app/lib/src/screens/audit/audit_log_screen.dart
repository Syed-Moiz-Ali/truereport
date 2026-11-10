import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_theme.dart';

/// Models a cryptographic audit event on the platform ledger.
class AuditEventItem {
  const AuditEventItem({
    required this.id,
    required this.title,
    required this.hashOrRef,
    required this.actor,
    required this.timestamp,
    required this.metadataItems,
    required this.category,
    required this.badgeLabel,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.icon,
  });

  final String id;
  final String title;
  final String hashOrRef;
  final String actor;
  final String timestamp;
  final List<String> metadataItems;
  final String category; // 'Permission Changes', 'Deactivations', 'Access Grants'
  final String badgeLabel;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final IconData icon;
}

/// Screen 9: Platform Audit Events Log
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _activeCategory = 'All Events';
  String _searchQuery = '';
  int _loadedBlockCount = 4;

  static const List<AuditEventItem> _allAuditEvents = [
    AuditEventItem(
      id: 'evt-1',
      title: 'Public Share Link Deactivated',
      hashOrRef: 'SHA256: 9b2d...f4e1',
      actor: 'Marcus Vance (Lead Inspector)',
      timestamp: 'Today, 14:32 EST',
      metadataItems: ['Report #1042', 'IP: 192.168.1.42'],
      category: 'Deactivations',
      badgeLabel: 'Security Action',
      badgeBgColor: Color(0xFFFFDAD7),
      badgeTextColor: Color(0xFFB91A24),
      icon: Icons.link_off_rounded,
    ),
    AuditEventItem(
      id: 'evt-2',
      title: 'Workshop Node Created: Apex Fleet Central',
      hashOrRef: 'UUID: 8a4c...11a0',
      actor: 'Alex Vance (Principal Admin)',
      timestamp: 'Today, 11:15 EST',
      metadataItems: ['Cluster Region: US-East-1'],
      category: 'Access Grants',
      badgeLabel: 'Node Provisioned',
      badgeBgColor: Color(0xFFE8F5E9),
      badgeTextColor: Color(0xFF006C49),
      icon: Icons.add_business_outlined,
    ),
    AuditEventItem(
      id: 'evt-3',
      title: 'Admin Role Granted to David Vance',
      hashOrRef: 'Policy: Role.SuperAdmin, Workshop A',
      actor: 'Arthur Pendelton (Admin)',
      timestamp: 'Yesterday, 16:40 EST',
      metadataItems: ['Dual-Factor Approved'],
      category: 'Permission Changes',
      badgeLabel: 'RBAC Updated',
      badgeBgColor: Color(0xFFFEF3C7),
      badgeTextColor: Color(0xFFB45309),
      icon: Icons.admin_panel_settings_outlined,
    ),
    AuditEventItem(
      id: 'evt-4',
      title: 'Master Checklist Schema Modified: Brake Wear',
      hashOrRef: 'Rev: v4.19',
      actor: 'Elena Rostova (Supervisor)',
      timestamp: 'Oct 23, 09:20 EST',
      metadataItems: ['Tire & Chassis Specification v2'],
      category: 'Permission Changes',
      badgeLabel: 'Catalog Versioned',
      badgeBgColor: Color(0xFFE0F2FE),
      badgeTextColor: Color(0xFF0369A1),
      icon: Icons.edit_note_rounded,
    ),
    AuditEventItem(
      id: 'evt-5',
      title: 'API Token Revoked: Legacy Scan Tool Sync',
      hashOrRef: 'SHA256: 3c7a...20e9',
      actor: 'DevOps Service Account',
      timestamp: 'Oct 22, 18:05 EST',
      metadataItems: ['IP: 10.0.4.15', 'Certificate Expired'],
      category: 'Deactivations',
      badgeLabel: 'Security Action',
      badgeBgColor: Color(0xFFFFDAD7),
      badgeTextColor: Color(0xFFB91A24),
      icon: Icons.key_off_rounded,
    ),
    AuditEventItem(
      id: 'evt-6',
      title: 'Technician Write Permissions Granted: Omar Sayed',
      hashOrRef: 'Policy: Role.LeadTech, Workshop B',
      actor: 'Alex Vance (Principal Admin)',
      timestamp: 'Oct 21, 14:00 EST',
      metadataItems: ['Dual-Factor Approved', 'Workshop B Lead'],
      category: 'Access Grants',
      badgeLabel: 'Access Granted',
      badgeBgColor: Color(0xFFE8F5E9),
      badgeTextColor: Color(0xFF006C49),
      icon: Icons.badge_outlined,
    ),
  ];

  List<AuditEventItem> get _visibleEvents {
    final currentPool = _allAuditEvents.take(_loadedBlockCount).toList();

    return currentPool.where((item) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final match = item.title.toLowerCase().contains(query) ||
            item.hashOrRef.toLowerCase().contains(query) ||
            item.actor.toLowerCase().contains(query);
        if (!match) return false;
      }

      if (_activeCategory == 'All Events') return true;
      return item.category == _activeCategory;
    }).toList();
  }

  void _loadPreviousBlock() {
    setState(() {
      _loadedBlockCount = (_loadedBlockCount + 2).clamp(0, _allAuditEvents.length);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Loaded previous cryptographic block from audit ledger.',
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.white),
        ),
        backgroundColor: PtTheme.deepGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportCSV() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exporting cryptographic audit log (CSV format)...',
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.white),
        ),
        backgroundColor: PtTheme.deepGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _verifyNodes() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              const Icon(Icons.verified_user_rounded,
                  size: 22, color: PtTheme.emerald),
              Text(
                'Ledger & Node Verification',
                style: PtTheme.font(18, lineHeight: 24, weight: FontWeight.w700),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cryptographic verification executed against CoreOS Platform Root CA.',
                  style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
                ),
                const SizedBox(height: 14),
                _buildVerificationCheck('48 / 48 Workshop Cluster Nodes Validated'),
                _buildVerificationCheck('14,802 Ledger Blocks Signed & Sealed'),
                _buildVerificationCheck('0 Hash Anomalies or Tampering Detected'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PtTheme.canvas,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PtTheme.border),
                  ),
                  child: Text(
                    'Root Merkle Tree Hash:\n0x489F2A6C88D3B101E9024BCA778F33AE',
                    style: PtTheme.font(
                      11,
                      lineHeight: 16,
                      weight: FontWeight.w600,
                      color: PtTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: PtTheme.deepGreen,
                foregroundColor: PtTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerificationCheck(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 16, color: PtTheme.emerald),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: PtTheme.font(12, lineHeight: 16, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _inspectEvent(AuditEventItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Audit Event Payload',
            style: PtTheme.font(18, lineHeight: 24, weight: FontWeight.w700),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: PtTheme.font(15, lineHeight: 20, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Timestamp: ${item.timestamp}\nActor: ${item.actor}\nSignature: ${item.hashOrRef}',
                    style: PtTheme.font(12, lineHeight: 18, color: PtTheme.muted),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PtTheme.canvas,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PtTheme.border),
                    ),
                    child: Text(
                      '{\n  "event_id": "${item.id}",\n  "action": "${item.badgeLabel}",\n  "category": "${item.category}",\n  "verified": true,\n  "merkle_leaf": "${item.hashOrRef}"\n}',
                      style: PtTheme.font(
                        11,
                        lineHeight: 16,
                        weight: FontWeight.w500,
                        color: PtTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: PtTheme.deepGreen,
                foregroundColor: PtTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: PtTheme.canvas,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar Navigation
          if (isDesktop)
            PlatformSidebar(
              currentRoute: '/audit-log',
              onNavigate: (route) => context.go(route),
            ),

          // 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Global Header
                PlatformHeader(
                  onSearchChanged: (val) => setState(() => _searchQuery = val),
                ),

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
                            // Section 0: Context Header & Actions
                            _buildTopContextBar(),

                            const SizedBox(height: 24),

                            // Section 1: Filters & Search Strip
                            _buildFilterAndSearchStrip(),

                            const SizedBox(height: 20),

                            // Section 2: Audit Event Log Cards List
                            _buildAuditEventsList(),

                            const SizedBox(height: 28),

                            // Section 3: Bottom Ledger Integrity Seal Banner
                            _buildLedgerSealBanner(),
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

  /// Top Context Header with title, subtitle, Export CSV, and Verify Nodes CTAs
  Widget _buildTopContextBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 14,
          children: [
            // Left Title Column
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth < 600
                    ? constraints.maxWidth
                    : constraints.maxWidth - 280,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: PtTheme.muted,
                      ),
                      Text(
                        'TAMPER-PROOF LEDGER',
                        style: PtTheme.font(
                          11,
                          lineHeight: 14,
                          weight: FontWeight.w700,
                          color: PtTheme.muted,
                          tracking: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Security Audit Log',
                    style: PtTheme.font(
                      26,
                      lineHeight: 32,
                      weight: FontWeight.w800,
                      color: PtTheme.ink,
                      tracking: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cryptographic ledger of administrative operations and permission shifts across workshop tiers.',
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w400,
                      color: PtTheme.muted,
                    ),
                  ),
                ],
              ),
            ),

            // Right Action Buttons
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('btn-export-csv'),
                  onPressed: _exportCSV,
                  icon: const Icon(Icons.download_rounded, size: 15),
                  label: Text(
                    'Export CSV',
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w600,
                      color: PtTheme.ink,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PtTheme.ink,
                    side: const BorderSide(color: PtTheme.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('btn-verify-nodes'),
                  onPressed: _verifyNodes,
                  icon: const Icon(Icons.verified_outlined, size: 15),
                  label: Text(
                    'Verify Nodes',
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w700,
                      color: PtTheme.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PtTheme.deepGreen,
                    foregroundColor: PtTheme.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Filters Bar with Pills and Local Hash/User Search
  Widget _buildFilterAndSearchStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              // Filter Tabs
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCategoryTab('All Events'),
                    const SizedBox(width: 4),
                    _buildCategoryTab('Permission Changes'),
                    const SizedBox(width: 4),
                    _buildCategoryTab('Deactivations'),
                    const SizedBox(width: 4),
                    _buildCategoryTab('Access Grants'),
                  ],
                ),
              ),

              // Search field
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth < 260
                      ? constraints.maxWidth
                      : 240,
                ),
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    key: const Key('input-filter-audit-log'),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: PtTheme.font(12, lineHeight: 16, color: PtTheme.ink),
                    decoration: InputDecoration(
                      hintText: 'Filter by user or hash...',
                      hintStyle: PtTheme.font(11,
                          lineHeight: 14, color: PtTheme.muted),
                      filled: true,
                      fillColor: PtTheme.canvas,
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 15, color: PtTheme.muted),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTab(String category) {
    final isSelected = _activeCategory == category;
    return InkWell(
      key: Key('category-tab-$category'),
      onTap: () => setState(() => _activeCategory = category),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? PtTheme.deepGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          category,
          style: PtTheme.font(
            12,
            lineHeight: 16,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? PtTheme.white : PtTheme.muted,
          ),
        ),
      ),
    );
  }

  /// Event list with cards
  Widget _buildAuditEventsList() {
    final events = _visibleEvents;

    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off_rounded,
                size: 36, color: PtTheme.muted),
            const SizedBox(height: 10),
            Text(
              'No audit events match your criteria.',
              style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final item in events) ...[
          _buildAuditEventCard(item),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildAuditEventCard(AuditEventItem item) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Type Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PtTheme.border),
                ),
                child: Icon(item.icon, size: 20, color: PtTheme.ink),
              ),
              const SizedBox(width: 14),

              // Event Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Hash/Ref Row
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          item.title,
                          style: PtTheme.font(
                            15,
                            lineHeight: 20,
                            weight: FontWeight.w700,
                            color: PtTheme.ink,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PtTheme.canvas,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.hashOrRef,
                            style: PtTheme.font(
                              11,
                              lineHeight: 14,
                              weight: FontWeight.w600,
                              color: PtTheme.muted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Metadata trace line
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final meta in item.metadataItems) ...[
                          Text(
                            meta,
                            style: PtTheme.font(
                              12,
                              lineHeight: 16,
                              weight: FontWeight.w600,
                              color: PtTheme.ink,
                            ),
                          ),
                          Text(
                            '•',
                            style: PtTheme.font(12,
                                lineHeight: 16, color: PtTheme.muted),
                          ),
                        ],
                        Text(
                          item.actor,
                          style: PtTheme.font(
                            12,
                            lineHeight: 16,
                            weight: FontWeight.w600,
                            color: PtTheme.ink,
                          ),
                        ),
                        Text(
                          '•',
                          style: PtTheme.font(12,
                              lineHeight: 16, color: PtTheme.muted),
                        ),
                        Text(
                          item.timestamp,
                          style: PtTheme.font(
                            12,
                            lineHeight: 16,
                            weight: FontWeight.w400,
                            color: PtTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Badge & Action button
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item.badgeBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.badgeLabel,
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w700,
                        color: item.badgeTextColor,
                      ),
                    ),
                  ),
                  IconButton(
                    key: Key('btn-inspect-event-${item.id}'),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: PtTheme.muted,
                    ),
                    onPressed: () => _inspectEvent(item),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Bottom Ledger Integrity Seal Banner
  Widget _buildLedgerSealBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PtTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 14,
            children: [
              // Shield icon + Seal texts
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth < 650
                      ? constraints.maxWidth
                      : constraints.maxWidth - 340,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: PtTheme.deepGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.verified_user_rounded,
                          size: 22,
                          color: PtTheme.deepGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ledger Integrity Seal: 0x489F...A39E',
                            style: PtTheme.font(
                              15,
                              lineHeight: 20,
                              weight: FontWeight.w700,
                              color: PtTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All entries signed with CoreOS Platform Root CA. 0 validation anomalies found across 14,802 historic blocks.',
                            style: PtTheme.font(
                              12,
                              lineHeight: 16,
                              weight: FontWeight.w400,
                              color: PtTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Showing count and Load Previous Block CTA
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'SHOWING $_loadedBlockCount OF 241 EVENTS',
                    style: PtTheme.font(
                      11,
                      lineHeight: 14,
                      weight: FontWeight.w700,
                      color: PtTheme.muted,
                      tracking: 0.5,
                    ),
                  ),
                  ElevatedButton(
                    key: const Key('btn-load-previous-block'),
                    onPressed: _loadPreviousBlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PtTheme.canvas,
                      foregroundColor: PtTheme.ink,
                      elevation: 0,
                      side: const BorderSide(color: PtTheme.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Load Previous Block',
                      style: PtTheme.font(
                        12,
                        lineHeight: 16,
                        weight: FontWeight.w700,
                        color: PtTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
