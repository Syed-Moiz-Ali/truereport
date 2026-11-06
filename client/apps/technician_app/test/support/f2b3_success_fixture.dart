import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'f2b_views.dart';

void _noop() {}

// File-local spacing for `EdgeInsets` (F2-A `_M` pattern): `_M` has no
// digits so `EdgeInsets` lines stay clean for the source scan.
abstract final class _M {
  static const double quad = 4;
  static const double halfDozen = 6;
  static const double gapMid = 12;
  static const double padMid = 16;
  static const double gutter = 20;
  static const double gapLarge = 32;
  static const double corePad = 69.5;
}

/// F2-B.3 Part 2 — Level 1 exact-structure fixture for Figma screen 16
/// "Post-Finalization Success" (node `1:8931`, 390 x 884).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/f2b-nodes/16-success.txt`) using only the shared kits
/// (`Fx*` + `F2b*` primitives/tokens). It deliberately does NOT reuse the
/// production `SuccessView`: that view is product-anchored (job reference,
/// generation-status copy, masked-recipient delivery cards) while this fixture
/// renders the Figma nodes verbatim (absolute-positioned core, exact chip
/// paddings, Figma letter-spacing, exact shadows).
///
/// Figma-exact values that have no kit token are inlined here (test-only) and
/// listed as kit gaps in `docs/ui/figma/fidelity/f2b3/success/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change.
class F2b3SuccessFixture extends StatelessWidget {
  const F2b3SuccessFixture({super.key});

  static const double width = 390;
  static const double height = 884;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Fx.white,
        child: Column(
          children: [
            _Container(),
            SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

/// Figma `1:8932` — 390 x 820, pad top 16 / sides 20 / bottom 32.
class _Container extends StatelessWidget {
  const _Container();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: 820,
      padding: const EdgeInsets.fromLTRB(
        _M.gutter,
        _M.padMid,
        _M.gutter,
        _M.gapLarge,
      ),
      child: const Column(
        children: [
          _ContextRow(),
          _CoreMargin(),
          _CtaMargin(),
        ],
      ),
    );
  }
}

/// Figma `1:8933` — 350 x 22 context row, fixed 55.8 gap.
class _ContextRow extends StatelessWidget {
  const _ContextRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1:8934 left group 173.64 x 14: 8 dot + 8 pad + 157.64 label.
          SizedBox(
            width: 173.64,
            height: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Fx.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 157.64,
                  height: 14,
                  child: Text(
                    'SERVICE SESSION #1042',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Fx.text(
                      11,
                      14,
                      FontWeight.w600,
                      1.1,
                      color: Fx.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 55.8),
          // 1:8938 right chip 120.56 x 22, pad 4/12 — exact, not
          // F2bStatusPill (kit is 22 h … same height here, but kit pads
          // 10 horizontal vs Figma 12 and kits center differently).
          Container(
            width: 120.56,
            height: 22,
            padding: const EdgeInsets.fromLTRB(
              _M.gapMid,
              _M.quad,
              _M.gapMid,
              _M.quad,
            ),
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius:
                  BorderRadius.all(Radius.circular(Fx.pillRadius)),
            ),
            child: Text(
              'Locked & Signed',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: Fx.text(
                11,
                14,
                FontWeight.w600,
                0.44,
                color: Fx.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8940` — 350 x 678, pad top/bottom 69.5 around the core.
class _CoreMargin extends StatelessWidget {
  const _CoreMargin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 678,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _M.corePad),
        // 1:8941 core is layout NONE: children are absolutely positioned.
        // Stack paints beyond its box (badge shadow) so clipping is off.
        child: SizedBox(
          width: 350,
          height: 539,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                left: 103,
                top: 24,
                width: 144,
                height: 176,
                child: _BadgeMargin(),
              ),
              const Positioned(
                left: 23.89,
                top: 200,
                width: 302.2,
                height: 92,
                child: _TypographyMargin(),
              ),
              Positioned(
                left: 0,
                top: 292,
                width: 350,
                height: 145,
                child: _DeliveryCard(),
              ),
              const Positioned(
                left: 0,
                top: 437,
                width: 350,
                height: 78,
                child: _MetadataMargin(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma `1:8991` — 144 x 176 badge margin (circle 144 + bottom pad 32)
/// with the ripple highlight overflowing at rel (132, -4).
class _BadgeMargin extends StatelessWidget {
  const _BadgeMargin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          key: const ValueKey('f2b3-badge'),
          width: 144,
          height: 144,
          decoration: const BoxDecoration(
            color: Fx.white,
            shape: BoxShape.circle,
            // Figma-exact: DROP_SHADOW(16 0,4 @2%) + DROP_SHADOW(50 0,20
            // @6%). No kit equivalent (kit soft black is 8% blur-16).
            boxShadow: [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 50,
                offset: Offset(0, 20),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const FxIcon(
              id: '1_8995',
              size: 54.25,
              color: Fx.emerald,
            ),
          ),
        ),
        // 1:8996 ripple: two stacked 16 emerald rects == one circle.
        Positioned(
          left: 132,
          top: -4,
          width: 16,
          height: 16,
          child: Container(
            decoration: const BoxDecoration(
              color: Fx.emerald,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma `1:8942` — 302.2 x 92 typography margin (group 60 + pad 32).
class _TypographyMargin extends StatelessWidget {
  const _TypographyMargin();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 302.2,
          height: 60,
          child: Column(
            children: [
              SizedBox(
                width: 302.2,
                height: 32,
                child: Text(
                  F2bFigmaStrings.inspectionFinalizedTitle,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: Fx.display26.copyWith(color: Fx.inkStrong),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 302.2,
                height: 20,
                child: Text(
                  'Report #1042 has been locked and uploaded.',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: Fx.body14.copyWith(color: Fx.muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 302.2, height: 32),
      ],
    );
  }
}

/// Figma `1:8948` — 350 x 145 delivery card, r32, pad 20, gap 16.
/// Shadows are exactly `Fx.cardShadow` (8-blur 1.6% + 40-blur 4.3%).
class _DeliveryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FxCard(
      key: const ValueKey('f2b3-delivery'),
      padding: const EdgeInsets.all(_M.gutter),
      child: SizedBox(
        width: 310,
        height: 105,
        child: Column(
          children: [
            const _ChannelRow(
              iconId: '1_8953',
              iconSize: 16.67,
              channel: 'WhatsApp',
              channelWidth: 81.39,
              leftWidth: 129.39,
              gap: 112.63,
              chipWidth: 67.98,
              status: 'Sent',
            ),
            const SizedBox(height: 16),
            Container(width: 310, height: 1, color: Fx.divider),
            const SizedBox(height: 16),
            const _ChannelRow(
              iconId: '1_8965',
              iconSize: 18.33,
              channel: 'Fleet Portal',
              channelWidth: 87.13,
              leftWidth: 135.13,
              gap: 89.14,
              chipWidth: 85.73,
              status: 'Synced',
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `1:8949` / `1:8961` — 310 x 36 channel rows with fixed gaps
/// (112.63 / 89.14) and 28-tall status chips (pad 6/12).
/// The kit `F2bStatusPill` is fixed 22 tall with 10/4 padding, so the
/// chips are built exact from `Fx` primitives (kit gap, lead-owned).
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.iconId,
    required this.iconSize,
    required this.channel,
    required this.channelWidth,
    required this.leftWidth,
    required this.gap,
    required this.chipWidth,
    required this.status,
  });

  final String iconId;
  final double iconSize;
  final String channel;
  final double channelWidth;
  final double leftWidth;
  final double gap;
  final double chipWidth;
  final String status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: leftWidth,
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FxIconTile(
                  iconId: iconId,
                  size: 36,
                  iconSize: iconSize,
                  background: Fx.container,
                  color: Fx.muted,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: channelWidth,
                  height: 22,
                  child: Text(
                    channel,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Fx.title16.copyWith(color: Fx.inkStrong),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: gap),
          Container(
            width: chipWidth,
            height: 28,
            padding: const EdgeInsets.fromLTRB(
              _M.gapMid,
              _M.halfDozen,
              _M.gapMid,
              _M.halfDozen,
            ),
            decoration: const BoxDecoration(
              color: Fx.container,
              borderRadius:
                  BorderRadius.all(Radius.circular(Fx.pillRadius)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Fx.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Flexible absorbs sub-pixel float dust in the exact Figma
                // chip width (children sum is 0.002px over the available
                // space); laid-out pixels are unchanged, no overflow bands.
                Flexible(
                  child: Text(
                    status,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: Fx.text(
                      12,
                      16,
                      FontWeight.w600,
                      0.24,
                      color: Fx.inkStrong,
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
}

/// Figma `1:8972` — 350 x 78 metadata margin (top pad 16).
class _MetadataMargin extends StatelessWidget {
  const _MetadataMargin();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: _M.padMid),
      // 1:8973 strip 350 x 62, r48, pad 12/16, HORIZONTAL gap 21.2,
      // content centered (10.6 leading/trailing).
      child: Container(
        width: 350,
        height: 62,
        padding: const EdgeInsets.fromLTRB(
          _M.padMid,
          _M.gapMid,
          _M.padMid,
          _M.gapMid,
        ),
        decoration: BoxDecoration(
          color: Fx.container,
          borderRadius: BorderRadius.circular(F2b.radiusLarge),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _MetaCell(
              width: 67.91,
              label: 'VIN ENDING',
              labelWidth: 67.91,
              value: '·8492',
              valueWidth: 45.02,
            ),
            const SizedBox(width: 21.2),
            Container(width: 1, height: 24, color: Fx.surfaceHighest),
            const SizedBox(width: 21.2),
            const _MetaCell(
              width: 88.75,
              label: 'ITEMS VERIFIED',
              labelWidth: 88.75,
              value: '38 / 38',
              valueWidth: 52.45,
            ),
            const SizedBox(width: 21.2),
            Container(width: 1, height: 24, color: Fx.surfaceHighest),
            const SizedBox(width: 21.2),
            const _MetaCell(
              width: 53.3,
              label: 'PDF SIZE',
              labelWidth: 50.19,
              value: '2.4 MB',
              valueWidth: 53.3,
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `1:8974` / `1:8980` / `1:8986` — label 14 + 2 pad + value 22.
/// Labels hug their boxes (LEFT per Figma); values are centered in cells.
class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.width,
    required this.label,
    required this.labelWidth,
    required this.value,
    required this.valueWidth,
  });

  final double width;
  final String label;
  final double labelWidth;
  final String value;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            height: 14,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: Fx.text(
                11,
                14,
                FontWeight.w600,
                0.44,
                color: Fx.muted,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: valueWidth,
            height: 22,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: Fx.text(
                16,
                22,
                FontWeight.w700,
                -0.16,
                color: Fx.inkStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8999` — 350 x 72 CTA margin (top pad 16). The button is the
/// shared `FxButton` primary: 56 pill, emerald fill + `Fx.ctaShadow`
/// (25-blur emerald 30%), label 14/700 ls -0.14, trailing 13.33 arrow
/// after an 8 gap — exactly the Figma content geometry.
class _CtaMargin extends StatelessWidget {
  const _CtaMargin();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 350,
      height: 72,
      child: Padding(
        padding: EdgeInsets.only(top: _M.padMid),
        child: FxButton(
          key: ValueKey('f2b3-cta'),
          label: F2bFigmaStrings.backToJobs,
          onPressed: _noop,
          icon: FxIcon(
            id: '1_9005',
            size: 13.33,
            color: Fx.white,
          ),
        ),
      ),
    );
  }
}
