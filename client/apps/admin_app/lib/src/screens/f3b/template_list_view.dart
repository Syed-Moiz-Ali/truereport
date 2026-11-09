import 'dart:ui' as ui;

import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/screens/f3b/template_list_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Screen 7 — Workshop Template List (Templates tab).
///
/// Pixel-perfect 1280 desktop layout matching Figma spec
/// `06_7._Workshop_Template_List` (node `1:1307`, 1280 x 1586).
class WorkshopTemplateListView extends StatefulWidget {
  const WorkshopTemplateListView({
    super.key,
    this.selectedNavIndex = 3,
    this.onNavSelected,
    this.onNewTemplate,
    this.onEditTemplate,
    this.onSearch,
    this.searchController,
    this.onSignOut,
    this.onToggleLocale,
    this.userName,
    this.userRole,
    this.templates,
  });

  final int selectedNavIndex;
  final ValueChanged<int>? onNavSelected;
  final VoidCallback? onNewTemplate;
  final ValueChanged<String>? onEditTemplate;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;
  final VoidCallback? onSignOut;
  final VoidCallback? onToggleLocale;
  final String? userName;
  final String? userRole;
  final List<TemplateSummary>? templates;

  static const double width = 1280;
  static const double height = 1586;

  @override
  State<WorkshopTemplateListView> createState() => _WorkshopTemplateListViewState();
}

class _WorkshopTemplateListViewState extends State<WorkshopTemplateListView> {
  int _filterIndex = 0;
  int _layoutMode = 0; // 0 = grid, 1 = list

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: WorkshopTemplateListView.width,
          height: WorkshopTemplateListView.height,
          child: ColoredBox(
            color: Fx.white,
            child: Stack(
              children: [
                Positioned(
                  left: _M.zero,
                  top: _M.zero,
                  width: _M.ninetySix,
                  height: 800,
                  child: _rail(),
                ),
                ..._titleRow(),
                ..._metrics(),
                ..._filters(),
                ..._grid(),
                ..._footnote(),
                Positioned(
                  key: const ValueKey('f3b-header'),
                  left: _M.ninetySix,
                  top: _M.zero,
                  width: 1184,
                  height: _M.eighty,
                  child: _header(),
                ),
              ],
            ),
          ),
        ),
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

  // Figma 1:1623 rail 96 x 800.
  Widget _rail() {
    return Container(
      width: _M.ninetySix,
      height: 800,
      color: Fx.white,
      child: Stack(
        children: [
          Positioned(
            left: _M.twentyFour,
            top: _M.thirtyTwo,
            width: _M.fortyEight,
            height: _M.fortyEight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onNavSelected?.call(0),
                borderRadius: const BorderRadius.all(Radius.circular(_M.sixteen)),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                    boxShadow: Fx.cardShadow,
                  ),
                  alignment: Alignment.center,
                  child: _svg('logo', 21.67, 21.67),
                ),
              ),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 112,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 0,
              icon: 'dash',
              iconWidth: 18,
              iconHeight: 18,
              isActive: widget.selectedNavIndex == 0,
              tooltip: 'Overview Dashboard',
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 176,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 1,
              icon: 'jobs',
              iconWidth: 18,
              iconHeight: 20,
              isActive: widget.selectedNavIndex == 1,
              tooltip: 'Live Job Queue',
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 240,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 2,
              icon: 'staff',
              iconWidth: 18,
              iconHeight: 18,
              isActive: widget.selectedNavIndex == 2,
              tooltip: 'Staff Management',
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 304,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 3,
              icon: 'templates',
              iconWidth: 18,
              iconHeight: 18,
              isActive: widget.selectedNavIndex == 3,
              tooltip: 'Inspection Templates',
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 368,
            width: _M.fiftySix,
            height: 52,
            child: _navButton(
              index: 4,
              icon: 'gear',
              iconWidth: 18,
              iconHeight: 18,
              isActive: widget.selectedNavIndex == 4,
              tooltip: 'Workshop Settings & Profile',
            ),
          ),
          Positioned(
            left: 28,
            top: 728,
            width: _M.forty,
            height: _M.forty,
            child: Material(
              color: Colors.transparent,
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
                    child: _svg('help', 18.33, 17.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required int index,
    required String icon,
    required double iconWidth,
    required double iconHeight,
    required bool isActive,
    String? tooltip,
  }) {
    Widget iconWidget;
    if (icon == 'staff') {
      iconWidget = Icon(
        Icons.groups_outlined,
        size: 20,
        color: isActive ? Colors.white : Fx.muted,
      );
    } else if (icon == 'templates') {
      iconWidget = Icon(
        Icons.dashboard_customize_outlined,
        size: 20,
        color: isActive ? Colors.white : Fx.muted,
      );
    } else {
      iconWidget = _svg(icon, iconWidth, iconHeight);
    }

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: () => widget.onNavSelected?.call(index),
          borderRadius: const BorderRadius.all(Radius.circular(_M.sixteen)),
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? Fx.emerald : Fx.container,
              borderRadius: const BorderRadius.all(Radius.circular(_M.sixteen)),
              boxShadow: isActive ? Fx.ctaShadow : null,
            ),
            alignment: Alignment.center,
            child: iconWidget,
          ),
        ),
      ),
    );
  }

  // Figma 1:1600 floating header 1184 x 80, white 90 % + blur 48.
  Widget _header() {
    final name = widget.userName ?? 'Marcus Vance';
    final role = widget.userRole ?? 'Lead Inspector';
    return ClipRect(
      child: BackdropFilter(
        filter: _blur(48),
        child: Container(
          width: 1184,
          height: _M.eighty,
          color: Fx.whiteE5,
          child: Stack(
            children: [
              Positioned(
                left: _M.forty,
                top: _M.twentyFour,
                width: 229.72,
                height: _M.thirtyTwo,
                child: _bayPill(),
              ),
              Positioned(
                left: 675.61,
                top: 23,
                width: 299,
                height: 34,
                child: _searchPill(),
              ),
              Positioned(
                left: 1006.61,
                top: 23.25,
                width: 93.39,
                height: _M.eighteen,
                child: _t(
                  name,
                  93.39,
                  _M.eighteen,
                  Fx.text(14, 17.5, FontWeight.w700, -0.14, color: Fx.ink),
                  align: TextAlign.right,
                ),
              ),
              Positioned(
                left: 1006.61,
                top: 41.75,
                width: 93.39,
                height: _M.fourteen,
                child: _tr(
                  role,
                  85.8,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                ),
              ),
              Positioned(
                left: 1112,
                top: _M.twentyFour,
                width: _M.thirtyTwo,
                height: _M.thirtyTwo,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showUserMenu(context),
                    borderRadius: const BorderRadius.all(Radius.circular(Fx.pillRadius)),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Fx.deepGreen,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: _svg('avatar', 12, 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bayPill() {
    return Container(
      width: 229.72,
      height: _M.thirtyTwo,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: _hRow(
        [
          Container(
            width: _M.ten,
            height: _M.ten,
            decoration: const BoxDecoration(
              color: Fx.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: _M.twelve),
          _t(
            'BAY ACTIVE',
            67.8,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.secondaryInk),
          ),
          const SizedBox(width: _M.twelve),
          _t(
            'Shop Floor #04',
            95.92,
            _M.sixteen,
            Fx.text(12, 16, FontWeight.w700, 0.24, color: Fx.ink),
          ),
        ],
        leftPad: _M.sixteen,
      ),
    );
  }

  Widget _searchPill() {
    return Container(
      width: 299,
      height: 34,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.sixteen,
            top: 9.5,
            width: 15,
            height: 15,
            child: _svg('search', 15, 15),
          ),
          Positioned(
            left: 43,
            top: 2,
            width: 240,
            height: 30,
            child: widget.searchController != null
                ? TextField(
                    controller: widget.searchController,
                    onChanged: widget.onSearch,
                    style: Fx.text(13, 16, FontWeight.w400, 0, color: Fx.ink),
                    decoration: const InputDecoration(
                      hintText: 'Search VIN, tech, job ticket...',
                      hintStyle: TextStyle(
                        fontFamily: TrFonts.latin,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Fx.muted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(top: 6),
                    ),
                  )
                : _t(
                    'Search VIN, tech, job ticket...',
                    240,
                    _M.sixteen,
                    Fx.text(13, 16, FontWeight.w400, 0, color: Fx.muted),
                  ),
          ),
        ],
      ),
    );
  }

  // Title row 1:1311-1:1331.
  List<Widget> _titleRow() {
    return [
      Positioned(
        left: 136,
        top: _M.eighty,
        width: 234.27,
        height: _M.fourteen,
        child: _t(
          'STANDARD OPERATING PROCEDURES',
          234.27,
          _M.fourteen,
          Fx.text(11, 14, FontWeight.w600, 1.1, color: Fx.muted),
        ),
      ),
      Positioned(
        left: 136,
        top: 98,
        width: 319.44,
        height: _M.thirtyEight,
        child: _t(
          'Inspection Templates',
          319.44,
          _M.thirtyEight,
          Fx.text(32, 38, FontWeight.w800, -0.8, color: Fx.ink),
        ),
      ),
      Positioned(
        left: 136,
        top: 140,
        width: 399.83,
        height: _M.twentyFour,
        child: _t(
          'Standardized vehicle diagnostic and safety checklists',
          399.83,
          _M.twentyFour,
          Fx.text(16, 24, FontWeight.w500, -0.16, color: Fx.muted),
        ),
      ),
      Positioned(
        left: 773.05,
        top: 106,
        width: 260.39,
        height: _M.thirtyTwo,
        child: _blueprintsPill(),
      ),
      Positioned(
        key: const ValueKey('f3b-add'),
        left: 1049.44,
        top: 94,
        width: 190.56,
        height: _M.fiftySix,
        child: _newButton(),
      ),
    ];
  }

  Widget _blueprintsPill() {
    final count = widget.templates?.length ?? 5;
    return Container(
      width: 260.39,
      height: _M.thirtyTwo,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: _hRow(
        [
          Container(
            width: _M.eight,
            height: _M.eight,
            decoration: const BoxDecoration(
              color: Fx.emerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: _M.eight),
          _t(
            '$count Active Blueprints',
            112.11,
            _M.sixteen,
            Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
          ),
          const SizedBox(width: _M.eight),
          _t(
            '/ 42 Bays Bound',
            92.28,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
          ),
        ],
        leftPad: _M.sixteen,
      ),
    );
  }

  Widget _newButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onNewTemplate,
        borderRadius: const BorderRadius.all(Radius.circular(9999)),
        child: Container(
          width: 190.56,
          height: _M.fiftySix,
          decoration: const BoxDecoration(
            color: Fx.emerald,
            borderRadius: BorderRadius.all(Radius.circular(9999)),
            boxShadow: Fx.ctaShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: _M.thirtyTwo),
          child: _hRow(
            [
              _svg('plus', 11.67, 11.67),
              const SizedBox(width: _M.eight),
              _t(
                '+ New Template',
                106.89,
                _M.eighteen,
                Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.white),
                align: TextAlign.center,
              ),
            ],
            center: true,
          ),
        ),
      ),
    );
  }

  // KPI strip 1:1332-1:1377: 4 x 258, gap 24, pad 24, r16.
  List<Widget> _metrics() {
    return [
      Positioned(
        key: const ValueKey('f3b-metric-1'),
        left: 136,
        top: 212,
        width: 258,
        height: 130,
        child: _metric(
          label: 'TOTAL CHECKPOINTS',
          labelW: 124.98,
          value: '294 Items',
          caption: 'Across active catalog',
          captionW: 131.86,
          icon: 'm1',
          iconW: 18.33,
          iconH: 13.82,
          cardH: 130,
          rowGap: 63.02,
          labelTop: 24,
          iconTop: 24.09,
          valueTop: 54,
          captionTop: 86,
        ),
      ),
      Positioned(
        left: 418,
        top: 212,
        width: 258,
        height: 135.25,
        child: _metric(
          label: 'AVG. COMPLETION',
          labelW: 111.38,
          value: '14.2 min',
          caption: '-1.8 min vs last cycle',
          captionW: 123.08,
          icon: 'm2',
          iconW: 16.5,
          iconH: 19.25,
          cardH: 135.25,
          rowGap: 76.62,
          labelDy: 2.63,
          labelTop: 26.63,
          iconTop: 24,
          valueTop: 59.25,
          captionTop: 91.25,
        ),
      ),
      Positioned(
        left: 700,
        top: 212,
        width: 258,
        height: 134.33,
        child: _metric(
          label: 'COMPLIANCE RATE',
          labelW: 111.64,
          value: '99.4%',
          caption: 'OEM ISO-9001 sync',
          captionW: 124.59,
          icon: 'm3',
          iconW: 14.67,
          iconH: 18.33,
          cardH: 134.33,
          rowGap: 76.36,
          labelDy: 2.17,
          labelTop: 26.17,
          iconTop: 24,
          valueTop: 58.33,
          captionTop: 90.33,
        ),
      ),
      Positioned(
        left: 982,
        top: 212,
        width: 258,
        height: 134.24,
        child: _metric(
          label: 'PROTOCOL AUDIT',
          labelW: 104.8,
          value: 'Up to date',
          caption: 'Next review in 12 days',
          captionW: 130.7,
          icon: 'm4',
          iconW: 18.33,
          iconH: 18.24,
          cardH: 134.24,
          rowGap: 83.2,
          labelDy: 2.12,
          labelTop: 26.12,
          iconTop: 24,
          valueTop: 58.24,
          captionTop: 90.24,
        ),
      ),
    ];
  }

  Widget _metric({
    required String label,
    required double labelW,
    required String value,
    required String caption,
    required double captionW,
    required String icon,
    required double iconW,
    required double iconH,
    required double cardH,
    required double rowGap,
    double labelDy = 0,
    double labelTop = 24,
    double iconTop = 24,
    double valueTop = 54,
    double captionTop = 86,
  }) {
    return Container(
      width: 258,
      height: cardH,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.twentyFour,
            top: labelTop,
            width: labelW,
            height: _M.fourteen,
            child: _o(
              _t(
                label,
                labelW,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
              ),
              dy: labelDy,
            ),
          ),
          Positioned(
            left: 258 - _M.twentyFour - iconW,
            top: iconTop,
            width: iconW,
            height: iconH,
            child: _svg(icon, iconW, iconH),
          ),
          Positioned(
            left: _M.twentyFour,
            top: valueTop,
            width: 210,
            height: 28,
            child: _t(
              value,
              210,
              28,
              Fx.text(22, 28, FontWeight.w700, -0.44, color: Fx.ink),
            ),
          ),
          Positioned(
            left: _M.twentyFour,
            top: captionTop,
            width: captionW,
            height: _M.eighteen,
            child: _t(
              caption,
              captionW,
              _M.eighteen,
              Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
            ),
          ),
        ],
      ),
    );
  }

  // Filter row 1:1378-1:1397.
  List<Widget> _filters() {
    final isAll = _filterIndex == 0;
    final isFleet = _filterIndex == 1;
    final isEv = _filterIndex == 2;
    final isQuick = _filterIndex == 3;

    return [
      Positioned(
        left: 136,
        top: 395.25,
        width: 531.87,
        height: 44,
        child: Container(
          width: 531.87,
          height: 44,
          decoration: const BoxDecoration(
            color: Fx.container,
            borderRadius: BorderRadius.all(Radius.circular(9999)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: _M.six,
                top: _M.six,
                width: 134.86,
                height: _M.thirtyTwo,
                child: GestureDetector(
                  onTap: () => setState(() => _filterIndex = 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isAll ? Fx.white : Colors.transparent,
                      borderRadius: const BorderRadius.all(Radius.circular(9999)),
                      boxShadow: isAll
                          ? const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: _t(
                      'All Protocols (5)',
                      94.86,
                      _M.sixteen,
                      Fx.text(12, 16, FontWeight.w600, 0.24, color: isAll ? Fx.ink : Fx.muted),
                      align: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 140.86,
                top: _M.six,
                width: 138.28,
                height: _M.thirtyTwo,
                child: GestureDetector(
                  onTap: () => setState(() => _filterIndex = 1),
                  child: _fChip('Fleet Mandatory', 98.28, isFleet),
                ),
              ),
              Positioned(
                left: 279.14,
                top: _M.six,
                width: 139.84,
                height: _M.thirtyTwo,
                child: GestureDetector(
                  onTap: () => setState(() => _filterIndex = 2),
                  child: _fChip('High-Voltage EV', 99.84, isEv),
                ),
              ),
              Positioned(
                left: 418.98,
                top: _M.six,
                width: 106.89,
                height: _M.thirtyTwo,
                child: GestureDetector(
                  onTap: () => setState(() => _filterIndex = 3),
                  child: _fChip('Quick Lane', 66.89, isQuick),
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 1108.58,
        top: 410.25,
        width: 43.42,
        height: _M.fourteen,
        child: _t(
          'Layout:',
          43.42,
          _M.fourteen,
          Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
        ),
      ),
      Positioned(
        left: 1164,
        top: 401.25,
        width: _M.thirtyTwo,
        height: _M.thirtyTwo,
        child: GestureDetector(
          onTap: () => setState(() => _layoutMode = 0),
          child: Container(
            decoration: BoxDecoration(
              color: _layoutMode == 0 ? Fx.container : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(9999)),
            ),
            alignment: Alignment.center,
            child: _svg('grid', 13.5, 13.5),
          ),
        ),
      ),
      Positioned(
        left: 1208,
        top: 401.25,
        width: _M.thirtyTwo,
        height: _M.thirtyTwo,
        child: GestureDetector(
          onTap: () => setState(() => _layoutMode = 1),
          child: Container(
            decoration: BoxDecoration(
              color: _layoutMode == 1 ? Fx.container : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(9999)),
            ),
            alignment: Alignment.center,
            child: _svg('list', 15, 12),
          ),
        ),
      ),
    ];
  }

  Widget _fChip(String label, double labelW, bool active) {
    return Container(
      decoration: BoxDecoration(
        color: active ? Fx.white : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(9999)),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: _t(
        label,
        labelW,
        _M.sixteen,
        Fx.text(12, 16, FontWeight.w600, 0.24, color: active ? Fx.ink : Fx.muted),
        align: TextAlign.center,
      ),
    );
  }

  // Template grid 1:1398-1:1584.
  List<Widget> _grid() {
    return [
      Positioned(
        key: const ValueKey('f3b-card-1'),
        left: 136,
        top: 471.25,
        width: 346.67,
        height: 437.13,
        child: _templateCard(
          templateId: 't1',
          icon: 'c1',
          iconW: 21.67,
          iconH: 19.5,
          tagLabel: 'Fleet Default',
          tagW: 97.81,
          tagLabelW: 73.81,
          tagFill: const Color(0x2610B981),
          tagColor: Fx.deepGreen,
          title: '100-Point Standard Check',
          version: 'Version 2.0 • 110 checkpoints',
          desc:
              'Comprehensive bumper-to-bumper\nevaluation covering engine systems,\nsuspension geometry, and road-worthiness.',
          reqIcon: 'r1',
          reqIconW: 15,
          reqIconH: 15,
          reqLabel: 'Mandatory Photo Gates',
          reqLabelW: 134.97,
          reqValue: '8 points',
          reqValueW: 48.45,
          reqValueColor: Fx.ink,
          reqGap: 35.23,
          updated: 'Updated 2d ago',
          updatedW: 91.98,
          clock: 'u1',
          editIcon: 'e1',
          cardH: 437.13,
          overlayH: 56,
          overlayTop: 253.13,
          descTop: 165.13,
          reqIconTop: 24.5,
          reqLabelTop: 25,
          reqValueTop: 24,
        ),
      ),
      Positioned(
        left: 514.67,
        top: 471.25,
        width: 346.67,
        height: 437.13,
        child: _templateCard(
          templateId: 't2',
          icon: 'c2',
          iconW: 19.5,
          iconH: 19.5,
          tagLabel: 'Rapid Intake',
          tagW: 95.27,
          tagLabelW: 71.27,
          tagFill: Fx.surfaceHighest,
          tagColor: Fx.inkStrong,
          title: 'Quick Oil Service',
          version: 'Version 1.4 • 24 checkpoints',
          desc:
              'High-throughput express bay checklist\ntargeting fluid levels, pan torque specs, filter\nvalidation, and wiper wear.',
          reqIcon: 'r2',
          reqIconW: 16.67,
          reqIconH: 13.33,
          reqLabel: 'Target Cycle Time',
          reqLabelW: 101.47,
          reqValue: '12 mins',
          reqValueW: 42.81,
          reqValueColor: Fx.ink,
          reqGap: 74.39,
          updated: 'Updated 1w ago',
          updatedW: 91.77,
          clock: 'u2',
          editIcon: 'e2',
          cardH: 437.13,
          overlayH: 56,
          overlayTop: 253.13,
          descTop: 165.13,
          reqIconTop: 25.33,
          reqLabelTop: 25,
          reqValueTop: 24,
        ),
      ),
      Positioned(
        left: 893.33,
        top: 471.25,
        width: 346.67,
        height: 437.79,
        child: _templateCard(
          templateId: 't3',
          icon: 'c3',
          iconW: 19.5,
          iconH: 21.67,
          tagLabel: 'Specialized',
          tagW: 90.48,
          tagLabelW: 66.48,
          tagFill: Fx.baseline,
          tagColor: Fx.inkStrong,
          title: 'EV High-Voltage Battery Audit',
          version: 'Version 3.1 • 45 checkpoints',
          desc:
              'Class-4 technician protocol: cell impedance\nbalancing, busbar torque verification, cooling\nloop integrity, and isolation metrics.',
          reqIcon: 'r3',
          reqIconW: 13.33,
          reqIconH: 16.67,
          reqLabel: 'Hazmat PPE Mandatory',
          reqLabelW: 131.7,
          reqValue: 'Class 00',
          reqValueW: 52.7,
          reqValueColor: Fx.deepGreen,
          reqGap: 34.25,
          updated: 'Updated 4h ago',
          updatedW: 91.59,
          clock: 'u3',
          editIcon: 'e3',
          cardH: 437.79,
          overlayH: 56.67,
          overlayTop: 253.13,
          descTop: 165.13,
          reqIconTop: 24,
          reqLabelTop: 25.33,
          reqValueTop: 24.33,
        ),
      ),
      Positioned(
        left: 136,
        top: 944.63,
        width: 346.67,
        height: 437.78,
        child: _templateCard(
          templateId: 't4',
          icon: 'c4',
          iconW: 23.83,
          iconH: 17.33,
          tagLabel: 'DOT Compliant',
          tagW: 110.73,
          tagLabelW: 86.73,
          tagFill: Fx.container,
          tagColor: Fx.muted,
          title: 'Commercial Fleet Pre-Delivery',
          version: 'Version 1.8 • 80 checkpoints',
          desc:
              'Federal DOT baseline alignment, lift-gate\nhydraulics, cargo tie-down certification, and\ntelematics hardware handshake.',
          reqIcon: 'r4',
          reqIconW: 16.67,
          reqIconH: 16.67,
          reqLabel: 'Asset Tagging Req.',
          reqLabelW: 108.95,
          reqValue: 'Active',
          reqValueW: 38.42,
          reqValueColor: Fx.ink,
          reqGap: 71.28,
          updated: 'Updated 3d ago',
          updatedW: 92.13,
          clock: 'u4',
          editIcon: 'e4',
          cardH: 437.78,
          overlayH: 56.67,
          overlayTop: 253.11,
          descTop: 165.12,
          reqIconTop: 24,
          reqLabelTop: 25.33,
          reqValueTop: 24.33,
        ),
      ),
      Positioned(
        left: 514.67,
        top: 944.63,
        width: 346.67,
        height: 437.11,
        child: _templateCard(
          templateId: 't5',
          icon: 'c5',
          iconW: 23.83,
          iconH: 20.58,
          tagLabel: 'Chassis Safety',
          tagW: 108,
          tagLabelW: 84,
          tagFill: Fx.container,
          tagColor: Fx.muted,
          title: 'Brake & Chassis Certification',
          version: 'Version 2.2 • 35 checkpoints',
          desc:
              'Digital micrometer rotor depth checks, pad\nthickness logging, caliper slide pin friction\ntesting, and tie rod lash measurement.',
          reqIcon: 'r5',
          reqIconW: 16.67,
          reqIconH: 10,
          reqLabel: 'Digital Caliper Sync',
          reqLabelW: 111.63,
          reqValue: 'BLE Ready',
          reqValueW: 62.84,
          reqValueColor: Fx.ink,
          reqGap: 44.19,
          updated: 'Updated 5d ago',
          updatedW: 92.17,
          clock: 'u5',
          editIcon: 'e5',
          cardH: 437.11,
          overlayH: 56,
          overlayTop: 253.11,
          descTop: 165.12,
          reqIconTop: 27,
          reqLabelTop: 25,
          reqValueTop: 24,
        ),
      ),
      Positioned(
        left: 893.33,
        top: 944.63,
        width: 346.67,
        height: 439.14,
        child: _createCard(),
      ),
    ];
  }

  Widget _templateCard({
    required String templateId,
    required String icon,
    required double iconW,
    required double iconH,
    required String tagLabel,
    required double tagW,
    required double tagLabelW,
    required Color tagFill,
    required Color tagColor,
    required String title,
    required String version,
    required String desc,
    required String reqIcon,
    required double reqIconW,
    required double reqIconH,
    required String reqLabel,
    required double reqLabelW,
    required String reqValue,
    required double reqValueW,
    required Color reqValueColor,
    required double reqGap,
    required String updated,
    required double updatedW,
    required String clock,
    required String editIcon,
    required double cardH,
    required double overlayH,
    double overlayTop = 253.13,
    double descTop = 165.13,
    double reqIconTop = 24.5,
    double reqLabelTop = 25,
    double reqValueTop = 24,
  }) {
    final footerTop = cardH - 96;
    return Container(
      width: 346.67,
      height: cardH,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.thirtyTwo,
            top: _M.thirtyTwo,
            width: _M.fortyEight,
            height: _M.fortyEight,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              ),
              alignment: Alignment.center,
              child: _svg(icon, iconW, iconH),
            ),
          ),
          Positioned(
            left: 346.67 - _M.thirtyTwo - tagW,
            top: _M.thirtyTwo,
            width: tagW,
            height: _M.twentyTwo,
            child: Container(
              decoration: BoxDecoration(
                color: tagFill,
                borderRadius: const BorderRadius.all(Radius.circular(9999)),
              ),
              alignment: Alignment.center,
              child: _t(
                tagLabel,
                tagLabelW,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: tagColor),
              ),
            ),
          ),
          Positioned(
            left: _M.thirtyTwo,
            top: 104,
            width: 282.67,
            height: _M.twentyFour,
            child: _t(
              title,
              282.67,
              _M.twentyFour,
              Fx.text(18, 24, FontWeight.w700, -0.27, color: Fx.ink),
            ),
          ),
          Positioned(
            left: _M.thirtyTwo,
            top: 132,
            width: 282.67,
            height: _M.eighteen,
            child: _t(
              version,
              282.67,
              _M.eighteen,
              Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
            ),
          ),
          Positioned(
            left: _M.thirtyTwo,
            top: descTop,
            width: 282.67,
            height: 64,
            child: _tw(
              desc,
              282.67,
              64,
              Fx.text(13, 21.13, FontWeight.w400, 0, color: Fx.secondaryInk),
              maxLines: 3,
            ),
          ),
          Positioned(
            left: _M.thirtyTwo,
            top: overlayTop,
            width: 282.67,
            height: overlayH,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0x66F4F3F8),
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: _M.sixteen,
                    top: reqIconTop,
                    width: reqIconW,
                    height: reqIconH,
                    child: _svg(reqIcon, reqIconW, reqIconH),
                  ),
                  Positioned(
                    left: 28 + reqIconW,
                    top: reqLabelTop,
                    width: reqLabelW,
                    height: _M.fourteen,
                    child: _t(
                      reqLabel,
                      reqLabelW,
                      _M.fourteen,
                      Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.ink),
                    ),
                  ),
                  Positioned(
                    right: _M.sixteen,
                    top: reqValueTop,
                    width: reqValueW,
                    height: _M.sixteen,
                    child: _t(
                      reqValue,
                      reqValueW,
                      _M.sixteen,
                      Fx.text(
                        12,
                        16,
                        FontWeight.w600,
                        0.24,
                        color: reqValueColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: _M.thirtyTwo,
            top: footerTop,
            width: 282.67,
            height: 64,
            child: Stack(
              children: [
                Positioned(
                  left: _M.zero,
                  top: 34,
                  width: 12,
                  height: 12,
                  child: _svg(clock, 12, 12),
                ),
                Positioned(
                  left: _M.eighteen,
                  top: 33,
                  width: updatedW,
                  height: _M.fourteen,
                  child: _t(
                    updated,
                    updatedW,
                    _M.fourteen,
                    Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
                  ),
                ),
                Positioned(
                  left: 282.67 - 99.52,
                  top: _M.sixteen,
                  width: 99.52,
                  height: _M.fortyEight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onEditTemplate?.call(templateId),
                      borderRadius: const BorderRadius.all(Radius.circular(_M.sixteen)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x4010B981),
                              blurRadius: 18,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _hRow(
                          [
                            _svg(editIcon, 13.5, 13.5),
                            const SizedBox(width: _M.six),
                            _t(
                              'Edit',
                              24.02,
                              _M.sixteen,
                              Fx.text(
                                12,
                                16,
                                FontWeight.w600,
                                0.24,
                                color: Fx.white,
                              ),
                              align: TextAlign.center,
                            ),
                          ],
                          leftPad: 28,
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

  // Card 6: clean dashed-style create card.
  Widget _createCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onNewTemplate,
        borderRadius: const BorderRadius.all(Radius.circular(_M.twentyFour)),
        child: Container(
          width: 346.67,
          height: 439.14,
          decoration: const BoxDecoration(
            color: Fx.white,
            borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
            boxShadow: Fx.cardShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 141.34,
                top: 104,
                width: 64,
                height: 64,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(9999)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _svg('cplus', 18.67, 18.67),
                ),
              ),
              Positioned(
                left: 62.79,
                top: 192,
                width: 221.09,
                height: _M.twentyFour,
                child: _t(
                  '+ Create Custom Protocol',
                  221.09,
                  _M.twentyFour,
                  Fx.text(18, 24, FontWeight.w700, -0.27, color: Fx.ink),
                  align: TextAlign.center,
                ),
              ),
              Positioned(
                left: _M.thirtyTwo,
                top: 223.12,
                width: 282.66,
                height: 64,
                child: _tw(
                  'Assemble a bespoke diagnostic flow with\ncustom thresholds, required imagery, and\ninstant technician triggers.',
                  254.33,
                  64,
                  Fx.text(13, 21.13, FontWeight.w400, 0, color: Fx.muted),
                  maxLines: 3,
                  align: TextAlign.center,
                  centerBox: true,
                ),
              ),
              Positioned(
                left: 87.3,
                top: 319.12,
                width: 172.08,
                height: _M.sixteen,
                child: Stack(
                  children: [
                    Positioned(
                      left: _M.zero,
                      top: _M.zero,
                      width: 152.08,
                      height: _M.sixteen,
                      child: _t(
                        'Open Template Architect',
                        152.08,
                        _M.sixteen,
                        Fx.text(12, 16, FontWeight.w700, 0.24, color: Fx.deepGreen),
                        align: TextAlign.center,
                      ),
                    ),
                    Positioned(
                      left: 160.08,
                      top: _M.two,
                      width: 12,
                      height: 12,
                      child: _svg('carrow', 12, 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _footnote() {
    return [
      Positioned(
        key: const ValueKey('f3b-banner'),
        left: 136,
        top: 1450,
        width: 1104,
        height: 88,
        child: Container(
          width: 1104,
          height: 88,
          decoration: const BoxDecoration(
            color: Fx.container,
            borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: _M.twentyFour,
                top: 28,
                width: _M.thirtyTwo,
                height: _M.thirtyTwo,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.surfaceHigh,
                    borderRadius: BorderRadius.all(Radius.circular(9999)),
                  ),
                  alignment: Alignment.center,
                  child: _svg('shield', 16.5, 15.75),
                ),
              ),
              Positioned(
                left: 68,
                top: _M.twentyFour,
                width: 179.53,
                height: _M.sixteen,
                child: _t(
                  'Strict Validation Lock Enabled',
                  179.53,
                  _M.sixteen,
                  Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                ),
              ),
              Positioned(
                left: 68,
                top: 44,
                width: 474.34,
                height: _M.eighteen,
                child: _t(
                  'Checklist changes require Master Inspector sign-off before field deployment.',
                  474.34,
                  _M.eighteen,
                  Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                ),
              ),
              Positioned(
                left: 741.36,
                top: 26,
                width: 181.89,
                height: _M.thirtySix,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius: BorderRadius.all(Radius.circular(9999)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _t(
                    'Export Schemas (JSON)',
                    141.89,
                    _M.sixteen,
                    Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                    align: TextAlign.center,
                  ),
                ),
              ),
              Positioned(
                left: 935.25,
                top: 26,
                width: 144.75,
                height: _M.thirtySix,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius: BorderRadius.all(Radius.circular(9999)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _t(
                    'Version Audit Log',
                    104.75,
                    _M.sixteen,
                    Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                    align: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _hRow(
    List<Widget> children, {
    double leftPad = 0,
    bool center = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: leftPad),
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _tr(String data, double runW, double height, TextStyle style) {
    final dy = _dy(style);
    final text = Text(
      data,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      textAlign: TextAlign.right,
      style: style,
    );
    return SizedBox(
      width: 93.39,
      height: height,
      child: dy == 0
          ? text
          : Transform.translate(offset: Offset(0, dy), child: text),
    );
  }

  double _dy(TextStyle style) {
    final size = style.fontSize ?? 14;
    if (size == 11) return -1.0;
    if (size == 32) return 1.0;
    final ratio = style.height ?? 1.0;
    if (size == 13 && ratio > 1.3) return -1.0;
    if (size == 16 && ratio > 1.4) return -1.0;
    if (size == 18) return -1.0;
    return 0.0;
  }

  Widget _t(
    String data,
    double width,
    double height,
    TextStyle style, {
    TextAlign align = TextAlign.left,
  }) {
    final dy = _dy(style);
    final text = Text(
      data,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      textAlign: align,
      style: style,
    );
    return SizedBox(
      width: width,
      height: height,
      child: dy == 0
          ? text
          : Transform.translate(offset: Offset(0, dy), child: text),
    );
  }

  Widget _tw(
    String data,
    double width,
    double height,
    TextStyle style, {
    required int maxLines,
    TextAlign align = TextAlign.left,
    bool centerBox = false,
  }) {
    final dy = _dy(style);
    final text = Text(
      data,
      maxLines: maxLines,
      softWrap: true,
      overflow: TextOverflow.clip,
      textAlign: align,
      style: style,
    );
    if (!centerBox) {
      return SizedBox(
        width: width,
        height: height,
        child: dy == 0
            ? text
            : Transform.translate(offset: Offset(0, dy), child: text),
      );
    }
    return SizedBox(
      width: 282.66,
      height: height,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          height: height,
          child: dy == 0
              ? text
              : Transform.translate(offset: Offset(0, dy), child: text),
        ),
      ),
    );
  }

  Widget _o(Widget child, {required double dy}) {
    if (dy == 0) return child;
    return Transform.translate(offset: Offset(0, dy), child: child);
  }

  Widget _svg(String key, double width, double height) {
    final raw = TemplateListAssets.svgs[key];
    if (raw == null || raw.isEmpty) {
      return SizedBox(width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.string(raw, width: width, height: height),
    );
  }
}

ui.ImageFilter _blur(double sigma) => ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
    );

abstract final class _M {
  static const double eighty = 80;
  static const double fortyEight = 48;
  static const double forty = 40;
  static const double thirtyEight = 38;
  static const double thirtySix = 36;
  static const double thirtyTwo = 32;
  static const double twentyFour = 24;
  static const double twentyTwo = 22;
  static const double twenty = 20;
  static const double eighteen = 18;
  static const double sixteen = 16;
  static const double fourteen = 14;
  static const double twelve = 12;
  static const double ten = 10;
  static const double eight = 8;
  static const double six = 6;
  static const double two = 2;
  static const double zero = 0;
  static const double ninetySix = 96;
  static const double fiftySix = 56;
}
