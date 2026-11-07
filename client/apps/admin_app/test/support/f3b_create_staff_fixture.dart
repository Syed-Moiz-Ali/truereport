import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// F3-B Step 3 screen 6 — Level 1 exact-structure fixture for Figma screen 6
/// "Add Staff / Create Account" (node `1:1642`, 1280 x 1024).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/specs/workshop/06-add-staff-create-account.md` plus the
/// export JSON
/// `docs/ui/figma-export/Workshop_admin_figma/screens/07_6._Add_Staff_-_Create_Account/`
/// with exact sizes, positions, colours, shadows and type). It deliberately
/// does NOT reuse the product sheet: that view is product-anchored while this
/// fixture renders the Figma nodes verbatim (fixed pixel geometry, Figma
/// letter-spacing, exact shadows, Figma blur/scrim stack).
///
/// Shared-kit use: `Fx` colours/type (`Fx.text`, `Fx.ink`, `Fx.container`,
/// `Fx.cardShadow`, `Fx.ctaShadow`) wherever they match Figma exactly.
/// `WorkshopSideSheet`/`WorkshopHeader`/nav kits were evaluated and do NOT
/// reproduce Level-1 geometry (right-sheet radii/shadows/paddings, header
/// paddings, rail tiles); the deltas are recorded as kit gaps in
/// `docs/ui/figma/fidelity/f3b/create-staff/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change.
///
/// Figma-exact values with no kit token are inlined here (test-only).
/// Figma sample copy lives ONLY in this `test/` fixture. The admin
/// `source_scan_test` excludes `test/` for style checks, so it stays green.
/// The compare fixture points at `forbidden-terms-empty.json` for the same
/// reason as the sibling F3-A fixtures: Figma sample wording (sample emails,
/// sample password, stations, magic-link) would trip the default deny-list,
/// and it is allowed in `test/` only.
class F3bCreateStaffFixture extends StatelessWidget {
  const F3bCreateStaffFixture({required this.svgs, super.key});

  /// Raw Figma icon SVG strings read from the export by the capture test.
  final Map<String, String> svgs;

  static const double width = 1280;
  static const double height = 1024;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Fx.white,
        child: Stack(
          children: [
            // Blurred roster backdrop 1:1646 — 1104x526 at absolute (136, 80),
            // layer blur 12.
            Positioned(
              left: 136,
              top: 80,
              width: 1104,
              height: 526,
              child: Opacity(
                opacity: 1,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: _base(),
                ),
              ),
            ),
            // Frost tint overlay 1:1731 — full-frame white 50% + blur 24.
            Positioned(
              left: 0,
              top: 0,
              width: width,
              height: height,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: width,
                    height: height,
                    color: const Color(0x80FFFFFF),
                  ),
                ),
              ),
            ),
            // Header 1:1732 — 1184x80 at (96, 0), white 90% + blur 48.
            Positioned(
              left: 96,
              top: 0,
              width: 1184,
              height: 80,
              child: _header(),
            ),
            // Aside 1:1755 — 96x1024 rail.
            Positioned(
              left: 0,
              top: 0,
              width: 96,
              height: 1024,
              child: _rail(),
            ),
            // Right slide-out panel 1:1774 — 480x1024 at x800.
            Positioned(
              left: 800,
              top: 0,
              width: 480,
              height: 1024,
              child: _sheet(),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- base --
  // Blurred roster 1:1646 1104x526: top bar 1104x56, metric cards 1104x104
  // at y88, roster card 1104x302 at y224.
  Widget _base() {
    return SizedBox(
      width: 1104,
      height: 526,
      child: ColoredBox(
        color: Fx.white,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, width: 1104, height: 56, child: _topBar()),
            Positioned(left: 0, top: 88, width: 1104, height: 104, child: _metrics()),
            Positioned(left: 0, top: 224, width: 1104, height: 302, child: _roster()),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return SizedBox(
      width: 1104,
      height: 56,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 362.44,
            height: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 362.44,
                  height: 14,
                  child: Row(
                    children: [
                      _t('ADMINISTRATION', 108.75, 14,
                          Fx.text(11, 14, FontWeight.w600, 1.1, color: Fx.muted)),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, color: Fx.muted),
                      const SizedBox(width: 8),
                      _t('Personnel Roster', 97.23, 14,
                          Fx.text(11, 14, FontWeight.w700, 0.44, color: Fx.deepGreen)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 362.44,
                  height: 38,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _t(
                        'Staff Directory & Access',
                        362.44,
                        34,
                        Fx.text(32, 38, FontWeight.w800, -0.96, color: Fx.ink)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 700.98,
            top: 4,
            width: 403.02,
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 198,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    boxShadow: Fx.cardShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      _svg('pillDot', 20, 10),
                      const SizedBox(width: 12),
                      _t('18 Active Technicians', 126, 16,
                          Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 189.02,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Fx.emerald,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    boxShadow: Fx.ctaShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 24),
                      _svg('plus', 10.5, 10.5),
                      const SizedBox(width: 8),
                      _t('Add Staff Member', 122.52, 18,
                          Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.white)),
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

  Widget _metrics() {
    return SizedBox(
      width: 1104,
      height: 104,
      child: Row(
        children: [
          _metricCard('m1', 45.55, '4 / 4', 'Operational Diagnostic Bays', 175.7),
          const SizedBox(width: 24),
          _metricCard('m2', 69.23, '99.4%', 'Inspection Protocol Accuracy', 181.86),
          const SizedBox(width: 24),
          _metricCard('m3', 94.08, '3 Admins', 'Master Security Privileges', 157.17),
        ],
      ),
    );
  }

  Widget _metricCard(String icon, double valueW, String value, String label, double labelW) {
    return Container(
      width: 352,
      height: 104,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 24,
            width: 56,
            height: 56,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: _svg(icon, 22, 22),
            ),
          ),
          Positioned(
            left: 96,
            top: 26.25,
            width: 232,
            height: 51.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _t(value, valueW, 28,
                    Fx.text(22, 27.5, FontWeight.w700, -0.44, color: Fx.ink)),
                const SizedBox(height: 3.5),
                _t(label, labelW, 18,
                    Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Roster card 1:1693 1104x302, pad 24, three 1056x74 rows.
  Widget _roster() {
    return Container(
      width: 1104,
      height: 302,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: Fx.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
              left: 24, top: 24, width: 1056, height: 74, child: _staffRow('MV', 'Marcus Vance', 'm.vance@techinspect.io', 'Bay 04 (Lead)', 102.86)),
          Positioned(
              left: 24, top: 114, width: 1056, height: 74, child: _staffRow('AL', 'Alicia Lindqvist', 'a.lindqvist@techinspect.io', 'Bay 01', 60.98)),
          Positioned(
              left: 24, top: 204, width: 1056, height: 74, child: _staffRow('RK', 'Rohan Kapoor', 'r.kapoor@techinspect.io', 'Bay 02', 63.25)),
        ],
      ),
    );
  }

  Widget _staffRow(String initials, String name, String email, String bay, double bayW) {
    return SizedBox(
      width: 1056,
      height: 74,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            width: 260,
            height: 42,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEDF3),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _t(initials, 20, 16,
                      Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.ink)),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 204,
                  height: 42,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _t(name, 110, 18,
                          Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.ink)),
                      const SizedBox(height: 4),
                      _t(email, 180, 18,
                          Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 26,
            width: 131,
            height: 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: bayW,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEDF3),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  alignment: Alignment.center,
                  child: _t(bay, bayW - 24, 14,
                      Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.ink)),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Fx.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- header --
  // Floating header 1:1732, white 90% + blur 48, pad h40.
  Widget _header() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          width: 1184,
          height: 80,
          color: Fx.whiteE5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 229.72,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _t('BAY ACTIVE', 67.8, 14,
                          Fx.text(11, 14, FontWeight.w600, 0.55, color: const Color(0xFF3C4A42))),
                      const SizedBox(width: 12),
                      _t('Shop Floor #04', 95.92, 16,
                          Fx.text(12, 16, FontWeight.w700, 0.24, color: Fx.ink)),
                    ],
                  ),
                ),
                const SizedBox(width: 405.89),
                Container(
                  width: 299,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16),
                      _svg('search', 15, 15),
                      const SizedBox(width: 12),
                      _t('Search VIN, tech, job ticket...', 240, 16,
                          Fx.text(13, 16, FontWeight.w400, 0, color: Fx.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 145.39,
                  height: 32,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 93.39,
                        height: 31.5,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              width: 93.39,
                              height: 18,
                              child: _t('Marcus Vance', 93.39, 18,
                                  Fx.text(14, 17.5, FontWeight.w700, -0.14, color: Fx.ink)),
                            ),
                            Positioned(
                              left: 7.59,
                              top: 17.5,
                              width: 85.8,
                              height: 14,
                              child: _t('Lead Inspector', 85.8, 14,
                                  Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Fx.deepGreen,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: _svg('avatarUser', 12, 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- rail --
  Widget _rail() {
    return Container(
      width: 96,
      height: 1024,
      color: Fx.white,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 32,
            width: 48,
            height: 48,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: Fx.cardShadow,
              ),
              alignment: Alignment.center,
              child: _svg('logo', 21.67, 21.67),
            ),
          ),
          Positioned(
            left: 20,
            top: 128,
            width: 56,
            height: 56,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: _svg('dash', 18, 18),
            ),
          ),
          Positioned(
            left: 20,
            top: 208,
            width: 56,
            height: 56,
            child: Container(
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: _svg('jobs', 18, 20),
            ),
          ),
          Positioned(
            left: 20,
            top: 288,
            width: 56,
            height: 56,
            child: Container(
              key: const ValueKey('f3b-nav-active'),
              decoration: const BoxDecoration(
                color: Fx.emerald,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: Fx.ctaShadow,
              ),
              alignment: Alignment.center,
              child: _svg('gear', 18, 18),
            ),
          ),
          Positioned(
            left: 28,
            top: 952,
            width: 40,
            height: 40,
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

  // ---------------------------------------------------------------- sheet --
  // Right slide-out 1:1774 480x1024, white, TL/BL 40, dual shadow.
  Widget _sheet() {
    return Container(
      key: const ValueKey('f3b-sheet'),
      width: 480,
      height: 1024,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          bottomLeft: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 60,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          bottomLeft: Radius.circular(40),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 480,
              height: 865,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHead(),
                    const SizedBox(height: 0),
                    _titleBlock(),
                    const SizedBox(height: 0),
                    _form(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 480, height: 23),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _sheetHead() {
    return SizedBox(
      key: const ValueKey('f3b-sheet-head'),
      width: 400,
      height: 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 400,
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 123.59,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Fx.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _t('ONBOARDING', 83.59, 14,
                          Fx.text(11, 14, FontWeight.w700, 0.55, color: Fx.ink)),
                    ],
                  ),
                ),
                const SizedBox(width: 232.41),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _svg('close', 11.67, 11.67),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return SizedBox(
      width: 400,
      height: 124,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 400,
            height: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _t('Create Staff Account', 400, 40,
                    Fx.text(32, 40, FontWeight.w800, -0.8, color: Fx.ink)),
                const SizedBox(height: 8),
                SizedBox(
                  width: 400,
                  height: 36,
                  child: Text(
                    'Set up permissions, station assignments, and onboarding\ncredentials.',
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.clip,
                    style: Fx.text(13, 18, FontWeight.w400, 0, color: Fx.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _form() {
    return SizedBox(
      width: 400,
      height: 585,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(
            label: 'FULL NAME',
            hint: 'e.g. David Vance',
            hintW: 360,
            icon: 'user',
            iconW: 16.67,
            iconH: 16.67,
            hintColor: Fx.muted,
          ),
          const SizedBox(height: 24),
          _field(
            label: 'EMAIL ADDRESS',
            hint: 'e.g. d.vance@techinspect.io',
            hintW: 360,
            icon: 'mail',
            iconW: 16.67,
            iconH: 13.33,
            hintColor: Fx.muted,
          ),
          const SizedBox(height: 24),
          _passwordField(),
          const SizedBox(height: 24),
          _roleSelector(),
          const SizedBox(height: 24),
          _stations(),
          const SizedBox(height: 24),
          _magicRow(),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required double hintW,
    required String icon,
    required double iconW,
    required double iconH,
    required Color hintColor,
  }) {
    return SizedBox(
      width: 400,
      height: 74,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 400,
            height: 14,
            child: _t(label, 400, 14,
                Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted)),
          ),
          const SizedBox(height: 8),
          Container(
            width: 400,
            height: 52,
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: Fx.cardShadow,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 17,
                  width: hintW,
                  height: 18,
                  child: _t(hint, hintW, 18,
                      Fx.text(14, 18, FontWeight.w500, -0.07, color: hintColor)),
                ),
                Positioned(
                  right: 16,
                  top: 13,
                  width: iconW,
                  height: 26,
                  child: _svg(icon, iconW, iconH),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField() {
    return SizedBox(
      width: 400,
      height: 74,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 400,
            height: 14,
            child: _t('TEMPORARY PASSWORD', 400, 14,
                Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted)),
          ),
          const SizedBox(height: 8),
          Container(
            width: 400,
            height: 52,
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: Fx.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                _t('InspectGuard99!', 332, 20,
                    Fx.text(14, 20, FontWeight.w500, 1.4, color: Fx.ink)),
                const Spacer(),
                _svg('eye', 18.33, 12.5),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleSelector() {
    return SizedBox(
      width: 400,
      height: 78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 400,
            height: 14,
            child: _t('ASSIGN ROLE (TECHNICIAN / ADMIN)', 400, 14,
                Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted)),
          ),
          const SizedBox(height: 8),
          Container(
            width: 400,
            height: 56,
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              boxShadow: Fx.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 183.5,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Fx.emerald,
                      borderRadius: BorderRadius.all(Radius.circular(48)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x4010B981),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 49.11),
                        _svg('roleTech', 13.5, 13.5),
                        const SizedBox(width: 8),
                        _t('Technician', 63.77, 16,
                            Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.white)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 183.5,
                    height: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 61.84),
                        _svg('roleAdmin', 13.5, 15),
                        const SizedBox(width: 8),
                        _t('Admin', 38.31, 16,
                            Fx.text(12, 16, FontWeight.w600, 0.24, color: Fx.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stations() {
    return SizedBox(
      width: 400,
      height: 94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 400,
            height: 14,
            child: Row(
              children: [
                _t('STATION ALLOCATION', 129.09, 14,
                    Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted)),
                const SizedBox(width: 211.52),
                _t('1 Required', 59.39, 14,
                    Fx.text(11, 14, FontWeight.w700, 0.44, color: Fx.deepGreen)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 400,
            height: 64,
            child: Row(
              children: [
                _station('STN', '01', false),
                const SizedBox(width: 10),
                _station('STN', '02', false),
                const SizedBox(width: 10),
                _station('STN', '03', false),
                const SizedBox(width: 10),
                _station('STN', '04', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _station(String top, String num, bool selected) {
    return Container(
      width: 92.5,
      height: 64,
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Color(0x3310B981),
                  blurRadius: 40,
                  offset: Offset(0, 14),
                ),
              ]
            : Fx.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 14),
          _t(top, 23, 14,
              Fx.text(11, 14, FontWeight.w600, 0.44,
                  color: selected ? Fx.deepGreen : Fx.muted)),
          _t(num, 22, 22,
              Fx.text(16, 22, FontWeight.w700, -0.16,
                  color: selected ? Fx.deepGreen : Fx.ink)),
        ],
      ),
    );
  }

  Widget _magicRow() {
    return Container(
      width: 400,
      height: 71,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _svg('shield', 16.67, 17.08),
            const SizedBox(width: 12),
            SizedBox(
              width: 222.38,
              height: 39,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _t('Send welcome magic link', 151.7, 15,
                      Fx.text(12, 15, FontWeight.w600, 0.24, color: Fx.ink)),
                  const SizedBox(height: 6.5),
                  _t('Bypasses initial manual password reset', 222.38, 14,
                      Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.muted)),
                ],
              ),
            ),
            const SizedBox(width: 65.62),
            Container(
              width: 48,
              height: 28,
              decoration: const BoxDecoration(
                color: Fx.emerald,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 22,
                    top: 2,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Fx.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 480,
          height: 136,
          color: Fx.whiteE5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
            child: SizedBox(
              width: 400,
              height: 56,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 94.89,
                    height: 50,
                    child: Center(
                      child: _t('Cancel', 46.89, 18,
                          Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.muted)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    key: const ValueKey('f3b-sheet-cta'),
                    width: 289.11,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Fx.emerald,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      boxShadow: Fx.ctaShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 81.08),
                        _t('Create Account', 105.63, 18,
                            Fx.text(14, 18, FontWeight.w700, -0.14, color: Fx.white)),
                        const SizedBox(width: 7.99),
                        _svg('ctaArrow', 13.33, 13.33),
                        const SizedBox(width: 81.08),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- helpers --
  Widget _t(String data, double w, double h, TextStyle style) {
    return SizedBox(
      width: w,
      height: h,
      child: Text(
        data,
        maxLines: 4,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: style,
      ),
    );
  }

  Widget _svg(String id, double w, double h) {
    final raw = svgs[id];
    if (raw == null) return SizedBox(width: w, height: h);
    return SizedBox(
      width: w,
      height: h,
      child: SvgPicture.string(raw, width: w, height: h, fit: BoxFit.contain),
    );
  }
}
