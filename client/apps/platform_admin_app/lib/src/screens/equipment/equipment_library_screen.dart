import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_theme.dart';

/// Models an equipment device or gauge authorized across the platform network.
class EquipmentItem {
  EquipmentItem({
    required this.id,
    required this.name,
    required this.specSubtitle,
    required this.capabilityTag,
    required this.capabilityIcon,
    required this.icon,
    this.isActive = true,
    this.isCalibrated = true,
    this.isTelemetry = true,
  });

  final String id;
  final String name;
  final String specSubtitle;
  final String capabilityTag;
  final IconData capabilityIcon;
  final IconData icon;
  bool isActive;
  final bool isCalibrated;
  final bool isTelemetry;
}

/// Screen 8: Global Equipment Library
class EquipmentLibraryScreen extends StatefulWidget {
  const EquipmentLibraryScreen({super.key});

  @override
  State<EquipmentLibraryScreen> createState() => _EquipmentLibraryScreenState();
}

class _EquipmentLibraryScreenState extends State<EquipmentLibraryScreen> {
  String _activeFilter = 'All Tools';
  String _searchQuery = '';

  late final List<EquipmentItem> _equipmentList;

  @override
  void initState() {
    super.initState();
    _equipmentList = [
      EquipmentItem(
        id: 'eq-obd2',
        name: 'OBD2 Scanner',
        specSubtitle: 'Diagnostic Telemetry Tool • BLE 5.0',
        capabilityTag: 'Signal Locked',
        capabilityIcon: Icons.bluetooth_connected_rounded,
        icon: Icons.electrical_services_rounded,
        isActive: true,
        isCalibrated: true,
        isTelemetry: true,
      ),
      EquipmentItem(
        id: 'eq-tire-depth',
        name: 'Digital Tire Depth Gauge',
        specSubtitle: 'Laser Micrometer • 0.01mm Precision',
        capabilityTag: 'ISO Certified',
        capabilityIcon: Icons.verified_outlined,
        icon: Icons.straighten_rounded,
        isActive: true,
        isCalibrated: true,
        isTelemetry: false,
      ),
      EquipmentItem(
        id: 'eq-torque-wrench',
        name: 'Precision Torque Wrench',
        specSubtitle: 'Digital Strain Sensor • 120-140 Nm',
        capabilityTag: 'Auto Zeroing',
        capabilityIcon: Icons.tune_rounded,
        icon: Icons.build_outlined,
        isActive: true,
        isCalibrated: true,
        isTelemetry: true,
      ),
      EquipmentItem(
        id: 'eq-paint-depth',
        name: 'Paint Depth Gauge (Fe/NFe)',
        specSubtitle: 'Ultrasonic Substrate Probe',
        capabilityTag: 'Magnetic Eddy',
        capabilityIcon: Icons.radar_rounded,
        icon: Icons.layers_outlined,
        isActive: true,
        isCalibrated: true,
        isTelemetry: false,
      ),
      EquipmentItem(
        id: 'eq-ev-analyzer',
        name: 'EV High-Voltage Analyzer',
        specSubtitle: 'Cell Impedance & Isolation Tester',
        capabilityTag: 'CAT IV 1000V',
        capabilityIcon: Icons.flash_on_rounded,
        icon: Icons.bolt_rounded,
        isActive: true,
        isCalibrated: false,
        isTelemetry: true,
      ),
    ];
  }

  List<EquipmentItem> get _filteredEquipment {
    return _equipmentList.where((item) {
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !item.specSubtitle
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
        return false;
      }
      switch (_activeFilter) {
        case 'Calibrated':
          return item.isCalibrated;
        case 'Telemetry':
          return item.isTelemetry;
        default:
          return true;
      }
    }).toList();
  }

  int get _activeCount => _equipmentList.where((e) => e.isActive).length;

  void _toggleEquipment(EquipmentItem item) {
    setState(() {
      item.isActive = !item.isActive;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.name} is now ${item.isActive ? "Active" : "Disabled"} across network.',
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.white),
        ),
        backgroundColor: item.isActive ? PtTheme.deepGreen : PtTheme.muted,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openRegisterDialog() {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final tagCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Register Network Equipment',
            style: PtTheme.font(18, lineHeight: 24, weight: FontWeight.w700),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Authorizes new diagnostic hardware across all 48 workshop nodes.',
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      color: PtTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('input-register-eq-name'),
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Device Name',
                      hintText: 'e.g. Optical Wheel Aligner',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('input-register-eq-spec'),
                    controller: specCtrl,
                    decoration: InputDecoration(
                      labelText: 'Specification / Protocol',
                      hintText: 'e.g. 3D Camera Rig • ISO 17025',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('input-register-eq-tag'),
                    controller: tagCtrl,
                    decoration: InputDecoration(
                      labelText: 'Capability Tag',
                      hintText: 'e.g. 4-Wheel Live Sync',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: PtTheme.font(13, lineHeight: 18, color: PtTheme.muted),
              ),
            ),
            ElevatedButton(
              key: const Key('btn-submit-register-equipment'),
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  _equipmentList.add(
                    EquipmentItem(
                      id: 'eq-${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      specSubtitle: specCtrl.text.trim().isEmpty
                          ? 'Certified Platform Tool'
                          : specCtrl.text.trim(),
                      capabilityTag: tagCtrl.text.trim().isEmpty
                          ? 'Active Protocol'
                          : tagCtrl.text.trim(),
                      capabilityIcon: Icons.precision_manufacturing_rounded,
                      icon: Icons.build_circle_outlined,
                      isActive: true,
                      isCalibrated: true,
                      isTelemetry: true,
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$name registered into Global Equipment Library.',
                      style: PtTheme.font(
                        13,
                        lineHeight: 18,
                        color: PtTheme.white,
                      ),
                    ),
                    backgroundColor: PtTheme.deepGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PtTheme.deepGreen,
                foregroundColor: PtTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Register & Provision'),
            ),
          ],
        );
      },
    );
  }

  void _openProtocolsDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Supported Diagnostic Protocols',
            style: PtTheme.font(18, lineHeight: 24, weight: FontWeight.w700),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProtocolTile(
                  'ISO 14229 (UDS)',
                  'Unified Diagnostic Services on CAN / CAN-FD',
                ),
                _buildProtocolTile(
                  'SAE J1939',
                  'Heavy-duty commercial telemetry standard',
                ),
                _buildProtocolTile(
                  'DoIP (ISO 13400)',
                  'Diagnostics over IP for Next-Gen Ethernet gateways',
                ),
                _buildProtocolTile(
                  'BLE 5.2 GATT',
                  'Ultra low-latency short-range wireless sensor link',
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

  Widget _buildProtocolTile(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: PtTheme.emerald,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(
                  desc,
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
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

  void _openLogsDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Telemetry Calibration Drift Logs',
            style: PtTheme.font(18, lineHeight: 24, weight: FontWeight.w700),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automated telemetry stream events (Last 24 Hours):',
                  style: PtTheme.font(
                    13,
                    lineHeight: 18,
                    color: PtTheme.muted,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLogItem(
                  'OBD2-8849',
                  'Drift: +0.02% • Signal Latency: 4ms',
                  'SYNC OK',
                ),
                _buildLogItem(
                  'TORQ-104',
                  'Zero Offset Recalibrated • Strain: 0.00Nm',
                  'SYNC OK',
                ),
                _buildLogItem(
                  'TIRE-291',
                  'Laser Optics Clean • Accuracy: 0.005mm',
                  'SYNC OK',
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
              child: const Text('Dismiss'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogItem(String tool, String details, String badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PtTheme.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PtTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool,
                  style: PtTheme.font(
                    12,
                    lineHeight: 16,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(
                  details,
                  style: PtTheme.font(
                    11,
                    lineHeight: 14,
                    color: PtTheme.muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: PtTheme.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: PtTheme.font(
                10,
                lineHeight: 14,
                weight: FontWeight.w700,
                color: PtTheme.deepGreen,
              ),
            ),
          ),
        ],
      ),
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
              currentRoute: '/equipment',
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
                            // Section 0: Context Header & Filter / Action Bar
                            _buildContextHeader(),

                            const SizedBox(height: 28),

                            // Section 1: Equipment Cards Grid
                            _buildEquipmentGrid(),

                            const SizedBox(height: 28),

                            // Section 2: Bottom Telemetry Sync Banner
                            _buildTelemetrySyncBanner(),
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

  /// Top Context Header with title, description, filter tabs, and Register button
  Widget _buildContextHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            // Left Title Column
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth < 600
                    ? constraints.maxWidth
                    : constraints.maxWidth - 380,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NETWORK HARDWARE FLEET',
                    style: PtTheme.font(
                      11,
                      lineHeight: 14,
                      weight: FontWeight.w700,
                      color: PtTheme.muted,
                      tracking: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Platform Equipment Catalogue',
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
                    'Hardware devices, calibration gauges, and diagnostic readers authorized across network.',
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

            // Right Filter Tabs and Register Equipment Button
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Filter Tabs
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: PtTheme.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PtTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterTab('All Tools'),
                        const SizedBox(width: 4),
                        _buildFilterTab('Calibrated'),
                        const SizedBox(width: 4),
                        _buildFilterTab('Telemetry'),
                      ],
                    ),
                  ),
                ),

                // Register Equipment CTA
                ElevatedButton.icon(
                  key: const Key('btn-register-equipment'),
                  onPressed: _openRegisterDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    'Register Equipment',
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
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  Widget _buildFilterTab(String label) {
    final isSelected = _activeFilter == label;
    return InkWell(
      key: Key('filter-tab-$label'),
      onTap: () => setState(() => _activeFilter = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? PtTheme.deepGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: PtTheme.font(
            12,
            lineHeight: 16,
            weight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? PtTheme.white : PtTheme.muted,
          ),
        ),
      ),
    );
  }

  /// Responsive Grid for Equipment Cards + "Integrate New Spec"
  Widget _buildEquipmentGrid() {
    final items = _filteredEquipment;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 1;
        if (width >= 960) {
          columns = 3;
        } else if (width >= 620) {
          columns = 2;
        }

        final itemWidth = (width - ((columns - 1) * 20)) / columns;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _buildEquipmentCard(item),
              ),
            // The "Integrate New Spec" card
            SizedBox(
              width: itemWidth,
              child: _buildIntegrateNewCard(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEquipmentCard(EquipmentItem item) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Device Icon + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PtTheme.border),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 24,
                    color: item.isActive ? PtTheme.deepGreen : PtTheme.muted,
                  ),
                ),
              ),

              // Active / Inactive Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isActive
                      ? PtTheme.emerald.withValues(alpha: 0.12)
                      : PtTheme.canvas,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: item.isActive
                        ? PtTheme.emerald.withValues(alpha: 0.3)
                        : PtTheme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.isActive ? PtTheme.emerald : PtTheme.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.isActive ? 'Active' : 'Disabled',
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w700,
                        color: item.isActive
                            ? PtTheme.deepGreen
                            : PtTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Device Name
          Text(
            item.name,
            style: PtTheme.font(
              16,
              lineHeight: 22,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Subtitle / spec
          Text(
            item.specSubtitle,
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: FontWeight.w400,
              color: PtTheme.muted,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 22),
          const Divider(color: PtTheme.border, height: 1),
          const SizedBox(height: 14),

          // Bottom Capabilities & Toggle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Capability tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PtTheme.canvas,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.capabilityIcon,
                      size: 13,
                      color: PtTheme.deepGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.capabilityTag,
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w600,
                        color: PtTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),

              // Network Enable/Disable Toggle Switch
              Switch.adaptive(
                key: Key('toggle-equipment-${item.id}'),
                value: item.isActive,
                activeTrackColor: PtTheme.deepGreen,
                onChanged: (_) => _toggleEquipment(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dashed "Integrate New Spec" card
  Widget _buildIntegrateNewCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PtTheme.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PtTheme.deepGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.hub_outlined,
                size: 24,
                color: PtTheme.deepGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Integrate New Spec',
            style: PtTheme.font(
              16,
              lineHeight: 22,
              weight: FontWeight.w700,
              color: PtTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pair CAN-bus, RF or optical\ncalibration heads.',
            textAlign: TextAlign.center,
            style: PtTheme.font(
              12,
              lineHeight: 16,
              weight: FontWeight.w400,
              color: PtTheme.muted,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            key: const Key('btn-browse-protocols'),
            onPressed: _openProtocolsDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: PtTheme.deepGreen,
              side: const BorderSide(color: PtTheme.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Browse Protocols',
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
    );
  }

  /// Bottom Telemetry Sync Policy Banner
  Widget _buildTelemetrySyncBanner() {
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
              // Icon + description
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
                          Icons.sync_rounded,
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
                            'Automatic Telemetry Sync',
                            style: PtTheme.font(
                              15,
                              lineHeight: 20,
                              weight: FontWeight.w700,
                              color: PtTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All certified devices auto-stream calibration drifts every 24 hours to workshop nodes.',
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

              // Status capsule + Action CTA
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: PtTheme.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: PtTheme.emerald.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: PtTheme.emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_activeCount/5 Authorized Active',
                          style: PtTheme.font(
                            11,
                            lineHeight: 14,
                            weight: FontWeight.w700,
                            color: PtTheme.deepGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('btn-diagnostic-logs'),
                    onPressed: _openLogsDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PtTheme.ink,
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
                      'Diagnostic Logs',
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
            ],
          ),
        );
      },
    );
  }
}
