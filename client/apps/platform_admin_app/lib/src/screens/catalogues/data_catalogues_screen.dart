import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/platform_header.dart';
import '../../components/platform_sidebar.dart';
import '../../platform_theme.dart';

/// Models a single item within a platform catalogue.
class CatalogueItem {
  const CatalogueItem({
    required this.id,
    required this.name,
    this.code,
    this.badge,
    this.color,
  });

  final String id;
  final String name;
  final String? code;
  final String? badge;
  final Color? color;
}

/// Models a platform catalogue entity (e.g. Vehicle Makes, Defect Severities).
class CatalogueEntity {
  const CatalogueEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.addPlaceholder,
    required this.addBtnLabel,
    required this.defaultItems,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String addPlaceholder;
  final String addBtnLabel;
  final List<CatalogueItem> defaultItems;
}

/// Screen 7: Master Dropdowns & Data Catalogues
class DataCataloguesScreen extends StatefulWidget {
  const DataCataloguesScreen({super.key});

  @override
  State<DataCataloguesScreen> createState() => _DataCataloguesScreenState();
}

class _DataCataloguesScreenState extends State<DataCataloguesScreen> {
  // Tab switcher: 0 for Global Standard, 1 for Workshop Overrides
  int _activeTab = 0;

  // Alphabet Quick Index filter
  String _activeAlphabetIndex = 'All';

  // Search filter query
  String _searchQuery = '';

  // Currently selected catalogue entity id
  String _selectedCatalogueId = 'makes';

  // Dynamic storage for catalogue items
  late final Map<String, List<CatalogueItem>> _catalogueData;

  // Controller for adding new items
  final TextEditingController _addItemController = TextEditingController();

  static const List<CatalogueEntity> _catalogues = [
    CatalogueEntity(
      id: 'makes',
      title: 'Vehicle Makes',
      description: 'Manufacturer master list',
      icon: Icons.directions_car_outlined,
      addPlaceholder: 'e.g. Genesis',
      addBtnLabel: 'Add Make',
      defaultItems: [
        CatalogueItem(id: '1', name: 'Toyota'),
        CatalogueItem(id: '2', name: 'Nissan'),
        CatalogueItem(id: '3', name: 'Porsche'),
        CatalogueItem(id: '4', name: 'Ford'),
        CatalogueItem(id: '5', name: 'Renault'),
        CatalogueItem(id: '6', name: 'BMW'),
        CatalogueItem(id: '7', name: 'Mercedes-Benz'),
        CatalogueItem(id: '8', name: 'Audi'),
        CatalogueItem(id: '9', name: 'Tesla'),
        CatalogueItem(id: '10', name: 'Volvo'),
        CatalogueItem(id: '11', name: 'Hyundai'),
      ],
    ),
    CatalogueEntity(
      id: 'severities',
      title: 'Defect Severities',
      description: 'Grading definitions (P0–P3)',
      icon: Icons.warning_amber_rounded,
      addPlaceholder: 'e.g. P4 - Informational',
      addBtnLabel: 'Add Severity',
      defaultItems: [
        CatalogueItem(
          id: 's0',
          name: 'P0 - Critical / Immediate Safety Hazard',
          code: 'P0',
          badge: 'Immediate Stop',
          color: PtTheme.rose,
        ),
        CatalogueItem(
          id: 's1',
          name: 'P1 - Major Defect / Fails Standard',
          code: 'P1',
          badge: 'Fails Inspection',
          color: PtTheme.amber,
        ),
        CatalogueItem(
          id: 's2',
          name: 'P2 - Moderate / Near-term Attention',
          code: 'P2',
          badge: 'Advisory 30 Days',
          color: PtTheme.gold,
        ),
        CatalogueItem(
          id: 's3',
          name: 'P3 - Minor / Cosmetic Advisory',
          code: 'P3',
          badge: 'Informational',
          color: PtTheme.muted,
        ),
      ],
    ),
    CatalogueEntity(
      id: 'not_checked',
      title: 'Not-Checked Reasons',
      description: 'Bypass & exemption tags',
      icon: Icons.rule_folder_outlined,
      addPlaceholder: 'e.g. Third-party Sealed Unit',
      addBtnLabel: 'Add Reason',
      defaultItems: [
        CatalogueItem(id: 'nc1', name: 'Customer Declined'),
        CatalogueItem(id: 'nc2', name: 'Inaccessible / Blocked by Cargo'),
        CatalogueItem(id: 'nc3', name: 'Special Tool Unavailable'),
        CatalogueItem(id: 'nc4', name: 'Non-Applicable to Vehicle Trim'),
        CatalogueItem(id: 'nc5', name: 'Weather / Environmental Limitation'),
        CatalogueItem(id: 'nc6', name: 'Component Missing from Vehicle'),
      ],
    ),
    CatalogueEntity(
      id: 'powertrain',
      title: 'Fuel & Powertrain Types',
      description: 'BEV, Hybrid, PHEV, ICE',
      icon: Icons.electric_bolt_outlined,
      addPlaceholder: 'e.g. Hydrogen Dual-Fuel',
      addBtnLabel: 'Add Type',
      defaultItems: [
        CatalogueItem(id: 'pt1', name: 'BEV (Battery Electric)'),
        CatalogueItem(id: 'pt2', name: 'Hybrid Electric (HEV)'),
        CatalogueItem(id: 'pt3', name: 'Plug-in Hybrid (PHEV)'),
        CatalogueItem(id: 'pt4', name: 'ICE - Unleaded Gasoline'),
        CatalogueItem(id: 'pt5', name: 'ICE - Clean Diesel'),
        CatalogueItem(id: 'pt6', name: 'FCEV (Hydrogen Fuel Cell)'),
        CatalogueItem(id: 'pt7', name: 'CNG / Compressed Natural Gas'),
      ],
    ),
    CatalogueEntity(
      id: 'fluids',
      title: 'Fluid Specifications',
      description: 'Viscosities, DOT ratings',
      icon: Icons.water_drop_outlined,
      addPlaceholder: 'e.g. Synthetic 5W-30 API SP',
      addBtnLabel: 'Add Spec',
      defaultItems: [
        CatalogueItem(id: 'fl1', name: 'Engine Oil 0W-20 API SN+'),
        CatalogueItem(id: 'fl2', name: 'Brake Fluid DOT 4 (High Temp)'),
        CatalogueItem(id: 'fl3', name: 'Coolant OAT (Organic Acid Tech)'),
        CatalogueItem(id: 'fl4', name: 'ATF Dexron VI Synthetic'),
        CatalogueItem(id: 'fl5', name: 'Differential Oil 75W-90 GL-5'),
        CatalogueItem(id: 'fl6', name: 'Brake Fluid DOT 5.1 Low Viscosity'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _catalogueData = {
      for (final cat in _catalogues)
        cat.id: List<CatalogueItem>.from(cat.defaultItems),
    };
  }

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  CatalogueEntity get _currentCatalogue =>
      _catalogues.firstWhere((c) => c.id == _selectedCatalogueId);

  List<CatalogueItem> get _filteredItems {
    final items = _catalogueData[_selectedCatalogueId] ?? [];
    return items.where((item) {
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_activeAlphabetIndex == 'All') return true;

      final firstLetter = item.name.trim().isNotEmpty
          ? item.name.trim()[0].toUpperCase()
          : '';
      switch (_activeAlphabetIndex) {
        case 'A-F':
          return firstLetter.compareTo('A') >= 0 &&
              firstLetter.compareTo('F') <= 0;
        case 'G-M':
          return firstLetter.compareTo('G') >= 0 &&
              firstLetter.compareTo('M') <= 0;
        case 'N-S':
          return firstLetter.compareTo('N') >= 0 &&
              firstLetter.compareTo('S') <= 0;
        case 'T-Z':
          return firstLetter.compareTo('T') >= 0 &&
              firstLetter.compareTo('Z') <= 0;
        default:
          return true;
      }
    }).toList();
  }

  void _addNewItem() {
    final text = _addItemController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      final list = _catalogueData[_selectedCatalogueId] ?? [];
      list.add(
        CatalogueItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: text,
        ),
      );
      _catalogueData[_selectedCatalogueId] = list;
      _addItemController.clear();
    });
  }

  void _removeItem(String id) {
    setState(() {
      _catalogueData[_selectedCatalogueId]?.removeWhere((i) => i.id == id);
    });
  }

  void _revertToOEM() {
    final cat = _currentCatalogue;
    setState(() {
      _catalogueData[_selectedCatalogueId] =
          List<CatalogueItem>.from(cat.defaultItems);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reverted ${cat.title} to OEM factory default specification.',
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.white),
        ),
        backgroundColor: PtTheme.deepGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _publishCatalogue() {
    final cat = _currentCatalogue;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${cat.title} catalogue published and broadcasted to 48 workshop clusters.',
          style: PtTheme.font(13, lineHeight: 18, color: PtTheme.white),
        ),
        backgroundColor: PtTheme.deepGreen,
        duration: const Duration(seconds: 3),
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
              currentRoute: '/data-catalogues',
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
                            // Header & Mode Toggle
                            _buildTopContextBar(),

                            const SizedBox(height: 24),

                            // Main Split or Stack
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Catalogues Navigation
                                  SizedBox(
                                    width: 310,
                                    child: _buildCatalogueListColumn(),
                                  ),
                                  const SizedBox(width: 24),
                                  // Right Entries Manager
                                  Expanded(
                                    child: _buildCatalogueDetailsCard(),
                                  ),
                                ],
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCatalogueListColumn(),
                                  const SizedBox(height: 20),
                                  _buildCatalogueDetailsCard(),
                                ],
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

  /// Top context breadcrumb, title, and "Global Standard | Workshop Overrides" toggle
  Widget _buildTopContextBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 14,
          children: [
            // Title & Breadcrumb
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth < 500
                    ? constraints.maxWidth
                    : constraints.maxWidth - 260,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLATFORM DICTIONARIES & TAXONOMIES',
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
                    'System Data Catalogues',
                    style: PtTheme.font(
                      26,
                      lineHeight: 32,
                      weight: FontWeight.w800,
                      color: PtTheme.ink,
                      tracking: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Segmented switch tabs
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PtTheme.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PtTheme.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton('Global Standard', 0),
                    const SizedBox(width: 4),
                    _buildTabButton('Workshop Overrides', 1),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _activeTab == index;
    return InkWell(
      key: Key('tab-$label'),
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  /// Left Column: List of 5 Catalogue Entities + OEM Sync Banner
  Widget _buildCatalogueListColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Heading
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'Catalogues',
              style: PtTheme.font(
                16,
                lineHeight: 22,
                weight: FontWeight.w700,
                color: PtTheme.ink,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: PtTheme.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PtTheme.border),
              ),
              child: Text(
                '${_catalogues.length} Entities',
                style: PtTheme.font(
                  11,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: PtTheme.muted,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Entity Cards
        for (final cat in _catalogues) ...[
          _buildCatalogueEntityCard(cat),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 12),

        // Bottom OEM Sync Pipeline card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PtTheme.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PtTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  const Icon(
                    Icons.sync_rounded,
                    size: 16,
                    color: PtTheme.deepGreen,
                  ),
                  Text(
                    'OEM Sync Pipeline',
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w700,
                      color: PtTheme.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Catalogue definitions are automatically pushed down to offline mobile workshop pads every 4 hours.',
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
    );
  }

  Widget _buildCatalogueEntityCard(CatalogueEntity cat) {
    final isSelected = _selectedCatalogueId == cat.id;

    return InkWell(
      key: Key('catalogue-entity-${cat.id}'),
      onTap: () => setState(() {
        _selectedCatalogueId = cat.id;
        _addItemController.clear();
      }),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PtTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? PtTheme.deepGreen : PtTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? PtTheme.deepGreen.withValues(alpha: 0.08)
                  : const Color(0x04000000),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? PtTheme.deepGreen.withValues(alpha: 0.1)
                    : PtTheme.canvas,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                cat.icon,
                size: 18,
                color: isSelected ? PtTheme.deepGreen : PtTheme.muted,
              ),
            ),
            const SizedBox(width: 12),
            // Titles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.title,
                    style: PtTheme.font(
                      14,
                      lineHeight: 18,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? PtTheme.deepGreen : PtTheme.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cat.description,
                    style: PtTheme.font(
                      11,
                      lineHeight: 14,
                      weight: FontWeight.w400,
                      color: PtTheme.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: PtTheme.deepGreen,
                  shape: BoxShape.circle,
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: PtTheme.muted,
              ),
          ],
        ),
      ),
    );
  }

  /// Right Card: Selected Catalogue Entries Manager
  Widget _buildCatalogueDetailsCard() {
    final cat = _currentCatalogue;
    final items = _filteredItems;
    final totalCount = _catalogueData[cat.id]?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header with Title, Count Badge, and Add Input
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  // Title + count capsule
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        '${cat.title} (Active)',
                        style: PtTheme.font(
                          18,
                          lineHeight: 24,
                          weight: FontWeight.w700,
                          color: PtTheme.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: PtTheme.deepGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          '$totalCount Catalogued',
                          style: PtTheme.font(
                            11,
                            lineHeight: 14,
                            weight: FontWeight.w700,
                            color: PtTheme.deepGreen,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Add Item form input
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth < 340
                          ? constraints.maxWidth
                          : 340,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              key: const Key('input-add-catalogue-item'),
                              controller: _addItemController,
                              onSubmitted: (_) => _addNewItem(),
                              style: PtTheme.font(
                                13,
                                lineHeight: 18,
                                color: PtTheme.ink,
                              ),
                              decoration: InputDecoration(
                                hintText: cat.addPlaceholder,
                                hintStyle: PtTheme.font(
                                  12,
                                  lineHeight: 16,
                                  color: PtTheme.muted,
                                ),
                                filled: true,
                                fillColor: PtTheme.canvas,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: PtTheme.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: PtTheme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: PtTheme.deepGreen,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          key: const Key('btn-add-catalogue-item'),
                          onPressed: _addNewItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PtTheme.deepGreen,
                            foregroundColor: PtTheme.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              const Icon(Icons.add_rounded, size: 15),
                              Text(
                                cat.addBtnLabel,
                                style: PtTheme.font(
                                  12,
                                  lineHeight: 16,
                                  weight: FontWeight.w700,
                                  color: PtTheme.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // 2. Quick Index alphabet filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: PtTheme.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PtTheme.border),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    const Icon(
                      Icons.sort_by_alpha_rounded,
                      size: 15,
                      color: PtTheme.muted,
                    ),
                    Text(
                      'QUICK INDEX',
                      style: PtTheme.font(
                        11,
                        lineHeight: 14,
                        weight: FontWeight.w700,
                        color: PtTheme.muted,
                        tracking: 0.6,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final range in ['All', 'A-F', 'G-M', 'N-S', 'T-Z'])
                      _buildAlphaFilterPill(range),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Entries List / Cards
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 32,
                    color: PtTheme.muted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No entries match the selected filter.',
                    style: PtTheme.font(
                      13,
                      lineHeight: 18,
                      weight: FontWeight.w500,
                      color: PtTheme.muted,
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in items)
                      _buildEntryChip(item, constraints.maxWidth),
                  ],
                );
              },
            ),

          const SizedBox(height: 32),
          const Divider(color: PtTheme.border, height: 1),
          const SizedBox(height: 20),

          // 4. Bottom Actions Bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  // Sync feedback note
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      const Icon(
                        Icons.sync_alt_rounded,
                        size: 15,
                        color: PtTheme.muted,
                      ),
                      Text(
                        'Changes automatically sync to active work orders',
                        style: PtTheme.font(
                          12,
                          lineHeight: 16,
                          weight: FontWeight.w500,
                          color: PtTheme.muted,
                        ),
                      ),
                    ],
                  ),

                  // Actions: Revert to OEM Preset & Publish Catalogue
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        key: const Key('btn-revert-oem-preset'),
                        onPressed: _revertToOEM,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PtTheme.ink,
                          side: const BorderSide(color: PtTheme.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Revert to OEM Preset',
                          style: PtTheme.font(
                            13,
                            lineHeight: 18,
                            weight: FontWeight.w600,
                            color: PtTheme.ink,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        key: const Key('btn-publish-catalogue'),
                        onPressed: _publishCatalogue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PtTheme.deepGreen,
                          foregroundColor: PtTheme.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Publish Catalogue',
                          style: PtTheme.font(
                            13,
                            lineHeight: 18,
                            weight: FontWeight.w700,
                            color: PtTheme.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlphaFilterPill(String range) {
    final isSelected = _activeAlphabetIndex == range;
    return InkWell(
      key: Key('filter-alpha-$range'),
      onTap: () => setState(() => _activeAlphabetIndex = range),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? PtTheme.deepGreen : PtTheme.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? PtTheme.deepGreen : PtTheme.border,
          ),
        ),
        child: Text(
          range,
          style: PtTheme.font(
            11,
            lineHeight: 14,
            weight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? PtTheme.white : PtTheme.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildEntryChip(CatalogueItem item, double maxWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PtTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PtTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: (item.color ?? PtTheme.deepGreen).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.badge!,
                style: PtTheme.font(
                  10,
                  lineHeight: 14,
                  weight: FontWeight.w700,
                  color: item.color ?? PtTheme.deepGreen,
                ),
              ),
            ),
          ],
          Flexible(
            child: Text(
              item.name,
              style: PtTheme.font(
                13,
                lineHeight: 18,
                weight: FontWeight.w600,
                color: PtTheme.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            key: Key('btn-remove-item-${item.id}'),
            onTap: () => _removeItem(item.id),
            borderRadius: BorderRadius.circular(9999),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: PtTheme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
