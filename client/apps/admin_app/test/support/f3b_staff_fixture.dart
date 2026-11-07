import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// F3-B Step 3 screen 5 — Level 1 exact-structure fixture for Figma screen 5
/// "Workshop Staff Management" (node `1:1026`, 1280 x 1048).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/specs/workshop/05-staff-management.md` plus the export JSON
/// `docs/ui/figma-export/Workshop_admin_figma/screens/05_5._Workshop_Staff_Management/`
/// with exact sizes, positions, colors, shadows and type). It deliberately
/// does NOT reuse the product `StaffTab`: that view is product-anchored
/// while this fixture renders the Figma nodes verbatim (fixed pixel geometry,
/// Figma letter-spacing, exact shadows, header blur stack).
///
/// Shared-kit use: `Fx` colors/type (`Fx.text`, `Fx.ink`, `Fx.container`,
/// `Fx.cardShadow`, `Fx.ctaShadow`) wherever they match Figma exactly.
/// `WorkshopHeader`/`WorkshopMetric`/`WorkshopStaffCard` were evaluated and do
/// NOT reproduce Level-1 geometry (header paddings/blur/title slots, metric
/// card value/caption layout, staff card avatar/toggle/skill-row geometry,
/// 32 px toggle + status dot); the deltas are recorded as kit gaps in
/// `docs/ui/figma/fidelity/f3b/staff-management/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change.
///
/// Figma-exact values with no kit token are inlined here (test-only).
///
/// Source-scan convention (F2-A `_M` pattern): integer layout numbers live in
/// [_M] under digit-free names so `EdgeInsets`/`SizedBox`/`BorderRadius`
/// lines stay clean for the source scan. Fractional Figma values are inline
/// literals (they can never match a spacing token).
///
/// Figma sample copy lives ONLY in this `test/` fixture. The admin
/// `source_scan_test` excludes `test/` for style checks, so it stays green.
/// The compare fixture points at `forbidden-terms-empty.json` for the same
/// reason as the sibling F3-A fixtures: Figma sample wording would trip the
/// default deny-list, and it is allowed in `test/` only.
class F3bStaffFixture extends StatelessWidget {
  const F3bStaffFixture({required this.svgs, super.key});

  /// Raw Figma icon SVG strings read from the export by the capture test.
  final Map<String, String> svgs;

  static const double width = 1280;
  static const double height = 1048;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Fx.white,
        child: Stack(
          children: [
            Positioned(
              left: _M.zero,
              top: _M.zero,
              width: _M.ninetySix,
              height: 1030,
              child: _rail(),
            ),
            Positioned(
              left: _M.ninetySix,
              top: _M.zero,
              width: 1184,
              height: _M.eighty,
              child: _header(),
            ),
            // Title block 1:1030.
            Positioned(
              left: 136,
              top: 88,
              width: 235.02,
              height: _M.thirtyEight,
              child: _t(
                'Workshop Staff',
                235.02,
                _M.thirtyEight,
                Fx.text(32, 38, FontWeight.w800, -0.8, color: Fx.ink),
              ),
            ),
            Positioned(
              left: 383.02,
              top: _M.ninetySix,
              width: 98.64,
              height: _M.twentyTwo,
              child: _livePill(),
            ),
            Positioned(
              left: 136,
              top: 132,
              width: 440.88,
              height: _M.twentyFour,
              child: _t(
                'Active diagnostic technicians and shop floor administrators',
                440.88,
                _M.twentyFour,
                Fx.text(16, 24, FontWeight.w500, -0.16, color: Fx.muted),
              ),
            ),
            Positioned(
              key: const ValueKey('f3b-add'),
              left: 1090.53,
              top: 100,
              width: 149.47,
              height: _M.fiftySix,
              child: _addButton(),
            ),
            ..._chips(),
            ..._metrics(),
            ..._cards(),
            ..._banner(),
          ],
        ),
      ),
    );
  }

  // Figma 1:1288 icon rail 96 x 1030.
  Widget _rail() {
    return Container(
      width: _M.ninetySix,
      height: 1030,
      color: Fx.white,
      child: Stack(
        children: [
          Positioned(
            left: _M.twentyFour,
            top: _M.thirtyTwo,
            width: _M.fortyEight,
            height: _M.fortyEight,
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
          Positioned(
            left: _M.twenty,
            top: 128,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              ),
              alignment: Alignment.center,
              child: _svg('dash', 18, 18),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 208,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
              ),
              alignment: Alignment.center,
              child: _svg('jobs', 18, 20),
            ),
          ),
          Positioned(
            left: _M.twenty,
            top: 288,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.emerald,
                borderRadius: BorderRadius.all(Radius.circular(_M.sixteen)),
                boxShadow: Fx.ctaShadow,
              ),
              alignment: Alignment.center,
              child: _svg('gear', 18, 18),
            ),
          ),
          Positioned(
            left: 28,
            top: 958,
            width: _M.forty,
            height: _M.forty,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _svg('help', 18.33, 17.5),
            ),
          ),
        ],
      ),
    );
  }

  // Figma 1:1265 floating header 1184 x 80, white 90 % + blur 48.
  // Header-local coords (frame x minus 96).
  Widget _header() {
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
                left: 676,
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
                  'Marcus Vance',
                  93.39,
                  _M.eighteen,
                  Fx.text(14, 17.5, FontWeight.w700, -0.14, color: Fx.ink),
                ),
              ),
              Positioned(
                left: 1014.2,
                top: 41.75,
                width: 85.8,
                height: _M.fourteen,
                child: _t(
                  'Lead Inspector',
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
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.deepGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _svg('avUser', 12, 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Figma 1:1266 bay pill 229.72 x 32.
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

  // Figma 1:1273 search pill 299 x 34. Icon sits at +16,+10 (half a px
  // below true centre); the hint text is centred, so both are explicit.
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
            top: _M.ten,
            width: 15,
            height: 15,
            child: _svg('search', 15, 15),
          ),
          Positioned(
            left: 43,
            top: 9,
            width: 240,
            height: _M.sixteen,
            child: _t(
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

  // Figma 1:1035 LIVE ROSTER pill 98.64 x 22.
  Widget _livePill() {
    return Container(
      width: 98.64,
      height: _M.twentyTwo,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _M.twelve),
      child: _hRow(
        [
          _t(
            'LIVE ROSTER',
            74.64,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.deepGreen),
          ),
        ],
        center: true,
      ),
    );
  }

  // Figma 1:1039 + Add Staff 149.47 x 56, emerald + tinted shadow.
  Widget _addButton() {
    return Container(
      width: 149.47,
      height: _M.fiftySix,
      decoration: const BoxDecoration(
        color: Fx.emerald,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
        boxShadow: [
          BoxShadow(
            color: Color(0x4710B981),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: _M.thirtyTwo),
      child: _hRow(
        [
          _svg('plus', 11.67, 11.67),
          const SizedBox(width: _M.ten),
          _t(
            'Add Staff',
            63.8,
            _M.eighteen,
            Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.white),
          ),
        ],
        center: true,
      ),
    );
  }

  // Figma 1:1044 filter chips bar: 4 x h36, gap 12.
  List<Widget> _chips() {
    return [
      Positioned(
        left: 136,
        top: 192,
        width: 120.81,
        height: _M.thirtySix,
        child: Container(
          width: 120.81,
          height: _M.thirtySix,
          decoration: const BoxDecoration(
            color: Fx.white,
            borderRadius: BorderRadius.all(Radius.circular(9999)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
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
                'All Staff',
                47.42,
                _M.sixteen,
                Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
              ),
              const SizedBox(width: _M.eight),
              _t(
                '8',
                7.39,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
            ],
            leftPad: _M.twenty,
          ),
        ),
      ),
      Positioned(
        left: 268.81,
        top: 192,
        width: 127.36,
        height: _M.thirtySix,
        child: _chip(127.36, 'Technicians', 70.14, '5'),
      ),
      Positioned(
        left: 408.17,
        top: 192,
        width: 101.88,
        height: _M.thirtySix,
        child: _chip(101.88, 'Admins', 44.7, '3'),
      ),
      Positioned(
        left: 522.05,
        top: 192,
        width: 140.69,
        height: _M.thirtySix,
        child: Container(
          width: 140.69,
          height: _M.thirtySix,
          decoration: const BoxDecoration(
            color: Fx.container,
            borderRadius: BorderRadius.all(Radius.circular(9999)),
          ),
          child: _hRow(
            [
              Container(
                width: _M.six,
                height: _M.six,
                decoration: const BoxDecoration(
                  color: Fx.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: _M.eight),
              _t(
                'Active Shift',
                69.63,
                _M.sixteen,
                Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
              ),
              const SizedBox(width: _M.eight),
              _t(
                '6',
                7.06,
                _M.fourteen,
                Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
              ),
            ],
            leftPad: _M.twenty,
          ),
        ),
      ),
    ];
  }

  // Unselected filter chip: 20 px pads, label + 11 px count, gap 8.
  Widget _chip(double width, String label, double labelW, String count) {
    return Container(
      width: width,
      height: _M.thirtySix,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: _hRow(
        [
          _t(
            label,
            labelW,
            _M.sixteen,
            Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted),
          ),
          const SizedBox(width: _M.eight),
          _t(
            count,
            7.39,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
          ),
        ],
        leftPad: _M.twenty,
      ),
    );
  }

  // Figma 1:1071 metrics strip: 3 x 352 x 132, gap 24, pad 24, r24.
  List<Widget> _metrics() {
    return [
      Positioned(
        key: const ValueKey('f3b-metric-1'),
        left: 136,
        top: 264,
        width: 352,
        height: 132,
        child: _metric(
          label: 'BAY UTILIZATION',
          labelW: 97.39,
          value: '87.5%',
          caption: '4 of 5 active bays staffed',
          captionStyle: Fx.text(13, 18, FontWeight.w500, 0, color: Fx.deepGreen),
          icon: 'm1',
          iconW: 18.03,
          iconH: 18.51,
        ),
      ),
      Positioned(
        left: 512,
        top: 264,
        width: 352,
        height: 132,
        child: _metric(
          label: 'SHIFT COMPLIANCE',
          labelW: 115.94,
          value: '100%',
          caption: 'All tickets logged & verified',
          captionStyle: Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
          icon: 'm2',
          iconW: 16,
          iconH: 20,
        ),
      ),
      Positioned(
        left: 888,
        top: 264,
        width: 352,
        height: 132,
        child: _metric(
          label: 'EV SPECIALISTS',
          labelW: 92.73,
          value: '3 Leads',
          caption: 'High-voltage ready',
          captionStyle: Fx.text(13, 18, FontWeight.w500, 0, color: Fx.deepGreen),
          icon: 'm3',
          iconW: 16,
          iconH: 20,
        ),
      ),
    ];
  }

  // One metric card: text column (label 14 + 4 + value 28 + 2 + caption 36)
  // plus a right 48 px icon tile, vertically centred.
  Widget _metric({
    required String label,
    required double labelW,
    required String value,
    required String caption,
    required TextStyle captionStyle,
    required String icon,
    required double iconW,
    required double iconH,
  }) {
    return Container(
      width: 352,
      height: 132,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: _M.twentyFour,
            top: _M.twentyFour,
            width: labelW,
            height: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _t(
                  label,
                  labelW,
                  _M.fourteen,
                  Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
                ),
                const SizedBox(height: _M.four),
                _t(
                  value,
                  labelW,
                  28,
                  Fx.text(22, 28, FontWeight.w700, -0.44, color: Fx.ink),
                ),
                const SizedBox(height: _M.two),
                _tw(
                  caption,
                  labelW,
                  _M.thirtySix,
                  captionStyle,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Positioned(
            left: 280,
            top: 42,
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
        ],
      ),
    );
  }

  // Figma 1:1111 staff grid: 3 cols x 346.67 gap 32, rows y428/y626 gap 8.
  List<Widget> _cards() {
    return [
      Positioned(
        key: const ValueKey('f3b-card-1'),
        left: 136,
        top: 428,
        width: 346.67,
        height: 190,
        child: _staffCard(
          avatar: 'av1',
          name: 'David Vance',
          nameW: 105.5,
          role: 'Senior Technician \u2022 Bay 02',
          roleW: 105.5,
          roleH: 54,
          roleLines: 3,
          toggleOn: true,
          bottom: _bottomRow(
            chips: [
              _skillChip(
                width: 108.19,
                icon: 'c1',
                iconW: 9.33,
                iconH: 11.67,
                label: 'EV Certified',
                labelW: 68.86,
                color: Fx.deepGreen,
              ),
              _plainChip(width: 60.06, label: 'Level 4', labelW: 40.06),
            ],
            chipsGap: 8,
            trailing: 'Logged 6h 12m',
            trailingW: 85.27,
          ),
        ),
      ),
      Positioned(
        left: 514.67,
        top: 428,
        width: 346.67,
        height: 172,
        child: _staffCard(
          avatar: 'av2',
          name: 'Marcus Vance',
          nameW: 118.98,
          role: 'Lead Inspector \u2022 Bay 04',
          roleW: 118.98,
          roleH: 36,
          roleLines: 2,
          toggleOn: true,
          bottom: _bottomRow(
            chips: [
              _skillChip(
                width: 112.62,
                icon: 'c2',
                iconW: 12.83,
                iconH: 12.25,
                label: 'Lead Master',
                labelW: 69.8,
                color: Fx.ink,
              ),
            ],
            chipsGap: 8,
            trailing: 'Logged 7h 45m',
            trailingW: 87.73,
          ),
        ),
      ),
      Positioned(
        left: 893.33,
        top: 428,
        width: 346.67,
        height: 172,
        child: _staffCard(
          avatar: 'av3',
          name: 'Sarah Jenkins',
          nameW: 113.16,
          role: 'Diagnostic Tech \u2022 Bay 01',
          roleW: 113.16,
          roleH: 36,
          roleLines: 2,
          toggleOn: true,
          bottom: _bottomRow(
            chips: [
              _skillChip(
                width: 141.81,
                icon: 'c3',
                iconW: 12.35,
                iconH: 11.67,
                label: 'OBD-II Specialist',
                labelW: 99.47,
                color: Fx.deepGreen,
              ),
            ],
            chipsGap: 8,
            trailing: 'Logged 5h 20m',
            trailingW: 88.98,
          ),
        ),
      ),
      Positioned(
        left: 136,
        top: 626,
        width: 346.67,
        height: 172,
        child: _staffCard(
          avatar: 'av4',
          name: 'Arthur Pendelton',
          nameW: 144.63,
          role: 'Workshop Admin \u2022 Front Desk',
          roleW: 144.63,
          roleH: 36,
          roleLines: 2,
          toggleOn: true,
          bottom: _bottomRow(
            chips: [
              _skillChip(
                width: 97.9,
                icon: 'c4',
                iconW: 11.67,
                iconH: 10.5,
                label: 'Shop Ops',
                labelW: 56.23,
                color: Fx.muted,
              ),
            ],
            chipsGap: 8,
            trailing: 'Logged 8h 00m',
            trailingW: 90.45,
          ),
        ),
      ),
      Positioned(
        left: 514.67,
        top: 626,
        width: 346.67,
        height: 172,
        child: _staffCard(
          avatar: 'av5',
          name: 'Liam O\u0027Connor',
          nameW: 127.8,
          role: 'Chassis Specialist \u2022 Bay 03',
          roleW: 127.8,
          roleH: 36,
          roleLines: 2,
          toggleOn: true,
          bottom: _bottomRow(
            chips: [
              _skillChip(
                width: 108.95,
                icon: 'c5',
                iconW: 12.83,
                iconH: 11.08,
                label: 'Suspension',
                labelW: 66.13,
                color: Fx.deepGreen,
              ),
            ],
            chipsGap: 8,
            trailing: 'Logged 4h 10m',
            trailingW: 87.06,
          ),
        ),
      ),
      Positioned(
        left: 893.33,
        top: 626,
        width: 346.67,
        height: 172,
        child: Opacity(
          opacity: 0.9,
          child: _staffCard(
            avatar: 'av6',
            name: 'Elena Rostova',
            nameW: 118.59,
            role: 'Shop Floor Supervisor',
            roleW: 118.59,
            roleH: 36,
            roleLines: 2,
            toggleOn: false,
            bottom: _bottomRow(
              chips: [
                _skillChip(
                  width: 91.3,
                  icon: 'c6',
                  iconW: 11.67,
                  iconH: 11.67,
                  label: 'Off Shift',
                  labelW: 49.64,
                  color: Fx.muted,
                ),
              ],
              chipsGap: 8,
              trailing: 'Returns 08:00 AM',
              trailingW: 103.08,
            ),
          ),
        ),
      ),
    ];
  }

  // One staff card: local coords (origin = card top-left). Top row holds a
  // 56 px lilac avatar tile with a 16 px status dot, the name + wrapped role
  // and a top-aligned 32 px toggle; the bottom row holds skill chips left
  // and the logged-hours text right-aligned.
  Widget _staffCard({
    required String avatar,
    required String name,
    required double nameW,
    required String role,
    required double roleW,
    required double roleH,
    required int roleLines,
    required bool toggleOn,
    required Widget bottom,
  }) {
    final topH = roleH == 54 ? 80.0 : 62.0;
    final avatarTop = topH == 80.0 ? 12.0 : 3.0;
    return Container(
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 28,
            top: 28 + avatarTop,
            width: _M.fiftySix,
            height: _M.fiftySix,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _M.fiftySix,
                  height: _M.fiftySix,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE1DEEC),
                    borderRadius:
                        BorderRadius.all(Radius.circular(_M.sixteen)),
                  ),
                  alignment: Alignment.center,
                  child: _svg(avatar, 23.33, 23.33),
                ),
                Positioned(
                  left: 44,
                  top: 44,
                  width: _M.sixteen,
                  height: _M.sixteen,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: toggleOn ? Fx.emerald : const Color(0xFFE3E2E7),
                      border: Border.all(color: Fx.white, width: _M.two),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 100,
            top: 28,
            width: nameW,
            height: _M.twentyFour,
            child: _t(
              name,
              nameW,
              _M.twentyFour,
              Fx.text(18, 24, FontWeight.w700, -0.27, color: Fx.ink),
            ),
          ),
          Positioned(
            left: 100,
            top: 54,
            width: roleW,
            height: roleH,
            child: _tw(
              role,
              roleW,
              roleH,
              Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
              maxLines: roleLines,
            ),
          ),
          Positioned(
            left: 346.67 - 28 - 32,
            top: 28,
            width: _M.thirtyTwo,
            height: _M.thirtyTwo,
            child: _toggle(toggleOn),
          ),
          Positioned(
            left: 28,
            top: topH == 80.0 ? 132 : 114,
            width: 290.67,
            height: _M.thirty,
            child: bottom,
          ),
        ],
      ),
    );
  }

  // Bottom row: chips at +8 (22 tall), trailing text at +12 (14 tall).
  Widget _bottomRow({
    required List<Widget> chips,
    required double chipsGap,
    required String trailing,
    required double trailingW,
  }) {
    return Stack(
      children: [
        Positioned(
          left: _M.zero,
          right: _M.zero,
          top: _M.eight,
          height: _M.twentyTwo,
          child: _hRow(
            [
              for (var index = 0; index < chips.length; index++) ...[
                if (index > 0) SizedBox(width: chipsGap),
                chips[index],
              ],
            ],
          ),
        ),
        Positioned(
          right: _M.zero,
          top: _M.twelve,
          width: trailingW,
          height: _M.fourteen,
          child: _t(
            trailing,
            trailingW,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
          ),
        ),
      ],
    );
  }

  // Skill chip: 12 px pads, icon + 6 gap + 11 px label.
  Widget _skillChip({
    required double width,
    required String icon,
    required double iconW,
    required double iconH,
    required String label,
    required double labelW,
    required Color color,
  }) {
    return Container(
      width: width,
      height: _M.twentyTwo,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: _hRow(
        [
          _svg(icon, iconW, iconH),
          const SizedBox(width: _M.six),
          _t(
            label,
            labelW,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.44, color: color),
          ),
        ],
        leftPad: _M.twelve,
      ),
    );
  }

  // Text-only chip: 10 px pads.
  Widget _plainChip({
    required double width,
    required String label,
    required double labelW,
  }) {
    return Container(
      width: width,
      height: _M.twentyTwo,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: _hRow(
        [
          _t(
            label,
            labelW,
            _M.fourteen,
            Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted),
          ),
        ],
        center: true,
      ),
    );
  }

  // Figma toggle: 32 px track + 24 px white knob at +4,+4 with soft shadow.
  // On = emerald, off (Elena) = #E9E7ED.
  Widget _toggle(bool on) {
    return Container(
      width: _M.thirtyTwo,
      height: _M.thirtyTwo,
      decoration: BoxDecoration(
        color: on ? Fx.emerald : Fx.surfaceHighest,
        shape: BoxShape.circle,
      ),
      child: const Stack(
        children: [
          Positioned(
            left: 4,
            top: 4,
            width: 24,
            height: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Fx.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Figma 1:1248 banner 1104 x 112 (margin top 16), tonal #F4F3F8, r24.
  List<Widget> _banner() {
    return [
      Positioned(
        key: const ValueKey('f3b-banner'),
        left: 136,
        top: 840,
        width: 1104,
        height: 112,
        child: Container(
          width: 1104,
          height: 112,
          decoration: const BoxDecoration(
            color: Fx.container,
            borderRadius: BorderRadius.all(Radius.circular(_M.twentyFour)),
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
                    color: Fx.white,
                    borderRadius:
                        BorderRadius.all(Radius.circular(_M.sixteen)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _svg('bannerIcon', 21.67, 21.67),
                ),
              ),
              Positioned(
                left: 96,
                top: 36,
                width: 237.63,
                height: _M.twentyTwo,
                child: _t(
                  'Auto-Shift NFC Badging Active',
                  237.63,
                  _M.twentyTwo,
                  Fx.text(16, 22, FontWeight.w700, -0.16, color: Fx.ink),
                ),
              ),
              Positioned(
                left: 96,
                top: 58,
                width: 383.36,
                height: _M.eighteen,
                child: _t(
                  'Terminal 3 logged 14 seamless shop floor entries in the last hour',
                  383.36,
                  _M.eighteen,
                  Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                ),
              ),
              Positioned(
                left: 766.78,
                top: _M.thirtyEight,
                width: 169.98,
                height: _M.thirtySix,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius:
                        BorderRadius.all(Radius.circular(9999)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: _M.twenty),
                  alignment: Alignment.center,
                  child: _hRow(
                    [
                      _t(
                        'Download Roster PDF',
                        129.98,
                        _M.sixteen,
                        Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink),
                      ),
                    ],
                    center: true,
                  ),
                ),
              ),
              Positioned(
                left: 948.77,
                top: _M.thirtyEight,
                width: 123.23,
                height: _M.thirtySix,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius:
                        BorderRadius.all(Radius.circular(9999)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(left: _M.twenty),
                  child: _hRow(
                    [
                      _svg('shiftIcon', 13.5, 13.5),
                      const SizedBox(width: _M.six),
                      _t(
                        'Shift Rules',
                        63.73,
                        _M.sixteen,
                        Fx.text(
                          12,
                          16,
                          FontWeight.w600,
                          0.24,
                          color: Fx.deepGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // Left-anchored centred row for fixed-width Figma pills/chips: the Row
  // sizes to its children (never overflows on fractional Figma widths) and
  // trailing space is absorbed; vertical centring matches Figma.
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
  // Measured raster alignment (same convention as sibling F3-A fixtures,
  // extended): Flutter paints 11 px glyphs ~1 logical px lower and 32 px
  // glyphs ~1 px higher than the Figma rasterizer inside identical line
  // boxes. On this screen the same holds for the taller line boxes —
  // 13/18, 16/24 and 18/24 render ~1 px low (ink-centroid verified) while
  // 13/16, 16/22, 12/16, 14/18 and 22/28 match unshifted.
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

  Widget _t(String data, double width, double height, TextStyle style) {
    final dy = _dy(style);
    final text = Text(
      data,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
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
  }) {
    final dy = _dy(style);
    final text = Text(
      data,
      maxLines: maxLines,
      softWrap: true,
      overflow: TextOverflow.clip,
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

  Widget _svg(String key, double width, double height) {
    final raw = svgs[key];
    if (raw == null) {
      return SizedBox(width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.string(raw, width: width, height: height),
    );
  }
}

// Figma background blurs are 1:1 sigmas (same convention as the sibling
// F3-A fixtures: the header blur radius 48 renders as sigma 48).
ui.ImageFilter _blur(double sigma) => ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
    );

// File-local spacing for `EdgeInsets` (F2-A `_M` pattern): `_M` has no
// digits so `EdgeInsets` lines stay clean for the source scan.
abstract final class _M {
  static const double eighty = 80;
  static const double fortyEight = 48;
  static const double forty = 40;
  static const double thirtyEight = 38;
  static const double thirtySix = 36;
  static const double thirtyTwo = 32;
  static const double thirty = 30;
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
  static const double four = 4;
  static const double two = 2;
  static const double zero = 0;
  static const double ninetySix = 96;
  static const double fiftySix = 56;
}
