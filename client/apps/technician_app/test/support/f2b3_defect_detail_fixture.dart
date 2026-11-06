import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';

/// F2-B.3 Part 2 — Level 1 exact-structure fixture for Figma screen 09
/// "Defect Detail & Evidence" (node `1:8021`, 390 x 1031.67).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/f2b-nodes/09-defect-detail.txt`) using only the shared
/// kits (`Fx*` + `F2b*` primitives/tokens) plus the Figma export rasters
/// (decoded by the capture test via `loadFigmaTestImage`; never in `lib/`).
///
/// It deliberately does NOT reuse the production `DefectDetailView`: that view
/// is product-anchored (secondary result chips, severity wrap, `0 / 4` count,
/// silhouette slot) while this fixture renders the Figma nodes verbatim
/// (absolute chip placement, `1 of 4 Required`, tagged photo tile, square
/// media corners, peach `Minor` option geometry).
///
/// Figma-exact values that have no kit token are inlined here (test-only) and
/// listed as kit gaps in `docs/ui/figma/fidelity/f2b3/defect-detail/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change.
class F2b3DefectDetailFixture extends StatelessWidget {
  const F2b3DefectDetailFixture({
    required this.wireframe,
    required this.evidence,
    super.key,
  });

  /// Decoded `assets/composed/png/Blur-1_8036@2x.png` (712 x 512 px).
  final ui.Image wireframe;

  /// Decoded evidence `rendered_png ...-1_8104@2x.png` (334 x 334 px).
  final ui.Image evidence;

  static const double width = 390;
  static const double height = 1031.67;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Fx.white,
        child: Column(
          children: [
            _TopHalf(wireframe: wireframe),
            _Sheet(evidence: evidence),
          ],
        ),
      ),
    );
  }
}

void _noop() {}

/// Figma `1:8027` status pill: 22 tall, pad 16/4, dot 8, text 11/600 ls 0.55.
/// Exact Figma values (kit `F2bStatusPill` fixes pad 10 / dot 6). The Figma
/// `BACKGROUND_BLUR(24)` is a no-op over the white top half and is omitted.
class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        color: Fx.whiteE5,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(width: 4),
          Text(
            'BAY 04 \u2022 IN PROGRESS',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.ink),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8053` pin halo (48 circle, `#FBBF2433`, untokenized).
class _Halo extends StatelessWidget {
  const _Halo();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x33FBBF24),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Figma `1:8022` — 390 x 320 context half.
class _TopHalf extends StatelessWidget {
  const _TopHalf({required this.wireframe});

  final ui.Image wireframe;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: 320,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // 1:8023 top micro action bar 350 x 56, top pad 8.
            const SizedBox(
              width: 350,
              height: 56,
              child: Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1:8024 close, 48 x 48.
                      F2bIconButton(
                        iconId: '1_8026',
                        semanticLabel: 'Close inspector',
                        onPressed: _noop,
                        size: 48,
                        iconSize: 14,
                      ),
                      // 1:8027 status pill 178.13 x 22: exact Figma pad/dot —
                      // kit `F2bStatusPill` hugs narrower (pad 10, dot 6).
                      _StatusPill(),
                      // 1:8031 help, 48 x 48.
                      F2bIconButton(
                        iconId: '1_8033',
                        semanticLabel: 'Help',
                        onPressed: _noop,
                        size: 48,
                        iconSize: 18.33,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 1:8034 wireframe block 350 x 264, vertical pad 4.
            SizedBox(
              width: 350,
              height: 264,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: 350,
                  height: 256,
                  // 1:8035 blurred visual + 1:8047 pin overlay.
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RawImage(image: wireframe, scale: 2),
                      const Positioned(
                        // Rel. screen (159.86,150) 70.28 x 76;
                        // rel. blur box (20,60): left 139.86, top 90.
                        left: 139.86,
                        top: 90,
                        width: 70.28,
                        height: 76,
                        child: _Pin(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma `1:8047` pin: 40 x 40 white button + 32 amber core + white `!`
/// (1:8052) + 48 halo `#FBBF2433` (no kit token — gap) + `PIN #03` pill.
class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1:8048 container 40 x 40 centered in the 70.28 width.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1:8049 white button + shadow (kit-soft black approx).
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Fx.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    // 1:8050 amber core 32 x 32.
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: F2b.amber,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const FxIcon(
                        id: '1_8052',
                        size: 13.5,
                        color: Fx.white,
                      ),
                    ),
                  ),
                  // 1:8053 halo 48 x 48 (Figma-exact, untokenized) drawn
                  // AFTER (on top of) the white button per node order.
                  // Positioned: a plain 48-child would be clamped to the
                  // tight 40 Stack box (loose 0..40 constraints).
                  const Positioned(
                    left: -4,
                    top: -4,
                    width: 48,
                    height: 48,
                    child: _Halo(),
                  ),
                ],
              ),
            ),
          ],
        ),
        // 1:8054 margin (pad-top 4) + 1:8055 pill 70.28 x 32.
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            height: 32,
            padding: const EdgeInsets.fromLTRB(12, 8.5, 12, 9.5),
            decoration: const BoxDecoration(
              color: Fx.white,
              borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'PIN #03',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Fx.text(11, 14, FontWeight.w600, 0.275, color: Fx.ink),
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma `1:8057` bottom sheet: 390 wide, top radius 48, drop shadows
/// approximated by the kit sheet shadow (gap — kit has a single shadow).
class _Sheet extends StatelessWidget {
  const _Sheet({required this.evidence});

  final ui.Image evidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(F2b.radiusLarge),
        ),
        boxShadow: Fx.upShadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1:8058 grab handle 350 x 10, bottom pad 4.
          const SizedBox(
            height: 10,
            child: Align(
              alignment: Alignment.topCenter,
              child: _GrabBar(),
            ),
          ),
          const SizedBox(height: 24),
          // 1:8060 header 350 x 50.
          const _Header(),
          const SizedBox(height: 24),
          // 1:8071 status toggle 350 x 70.
          const _StatusBlock(),
          const SizedBox(height: 24),
          // 1:8081 classification 350 x 88.
          const _ClassificationBlock(),
          const SizedBox(height: 24),
          // 1:8096 evidence 350 x 185.
          _EvidenceBlock(evidence: evidence),
          const SizedBox(height: 24),
          // 1:8120 note 350 x 56.67.
          const _NoteRow(),
          const SizedBox(height: 24),
          // 1:8129 save 350 x 68 (pad 4 top / 8 bottom).
          const _SaveBlock(),
        ],
      ),
    );
  }
}

class _GrabBar extends StatelessWidget {
  const _GrabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 6,
      decoration: const BoxDecoration(
        color: F2b.grabTrack,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
    );
  }
}

/// Figma `1:8060` — category dot + label, 26 title, 40 car-icon chip.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1:8062 row 14 tall: 10 dot + 8 gap + label.
              SizedBox(
                height: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: F2b.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EXTERIOR BODYWORK',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Fx.text(11, 14, FontWeight.w600, 0.55, color: Fx.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 1:8066 heading 32 tall.
              Text(
                'Front Left Door',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Fx.display26,
              ),
            ],
          ),
          // 1:8068 car chip 40 circle, container fill, no shadow.
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Fx.container,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const FxIcon(id: '1_8070', size: 15, color: Fx.muted),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8071` — section label + exact segmented track 350 x 52.
/// The kit `F2bSegmented` fixes the selected fill to `surfaceHigh`; Figma
/// selects `Minor` with `#FED7AA` peach + `DROP_SHADOW(12 0,4)`, so the track
/// is composed here from kit tokens + the Figma-exact peach (test-only).
class _StatusBlock extends StatelessWidget {
  const _StatusBlock();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 14, child: F2bSectionLabel(l10n.result)),
          const SizedBox(height: 4),
          _SegmentedTrack(
            labels: [
              l10n.noIssueObserved,
              l10n.attentionRecommended,
              l10n.defectFound,
            ],
            selectedIndex: 1,
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8074` track: 350 x 52, pad 6, gap 6, options 108.67 x 40.
class _SegmentedTrack extends StatelessWidget {
  const _SegmentedTrack({required this.labels, required this.selectedIndex});

  final List<String> labels;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('f2b3-segmented-track'),
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
      child: Row(
        children: [
          Expanded(child: _SegmentOption(label: labels[0], selected: selectedIndex == 0)),
          const SizedBox(width: 6),
          Expanded(child: _SegmentOption(label: labels[1], selected: selectedIndex == 1)),
          const SizedBox(width: 6),
          Expanded(child: _SegmentOption(label: labels[2], selected: selectedIndex == 2)),
        ],
      ),
    );
  }
}

/// Figma `1:8075/1:8077/1:8079` options: 40 tall, pad 12/8, text 12 ls 0.24
/// (600 muted / 700 ink when selected). Selected fill is Figma-exact peach.
class _SegmentOption extends StatelessWidget {
  const _SegmentOption({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFED7AA) : Fx.transparent,
          borderRadius:
              const BorderRadius.all(Radius.circular(Fx.pillRadius)),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Fx.text(
            12,
            16,
            selected ? FontWeight.w700 : FontWeight.w600,
            0.24,
            color: selected ? Fx.ink : Fx.muted,
          ),
        ),
      ),
    );
  }
}

/// Figma `1:8081` — header row + absolutely-placed chips (the Figma container
/// `1:8087` itself has no auto-layout; children are at fixed offsets).
class _ClassificationBlock extends StatelessWidget {
  const _ClassificationBlock();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                F2bSectionLabel(l10n.severity),
                Text(
                  '1 Selected',
                  maxLines: 1,
                  style: Fx.text(
                    11,
                    14,
                    FontWeight.w700,
                    0.44,
                    color: Fx.emerald,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 1:8087 350 x 70 absolute chips.
          SizedBox(
            height: 70,
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 0,
                  child: F2bChip(
                    label: 'Dent / Crease',
                    selected: true,
                    leadingDot: F2b.amber,
                    onTap: _noop,
                  ),
                ),
                const Positioned(
                  left: 140.61,
                  top: 0,
                  child: F2bChip(
                    label: 'Surface Scratch',
                    selected: false,
                    onTap: _noop,
                  ),
                ),
                // `Paint Chip` is 30 tall in Figma (kit `F2bChip` fixes 32,
                // which would bleed 2 px into the gap below).
                Positioned(
                  left: 0,
                  top: 40,
                  child: Semantics(
                    button: true,
                    label: 'Paint Chip',
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.all(
                          Radius.circular(Fx.pillRadius),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Paint Chip',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Fx.text(
                          11,
                          14,
                          FontWeight.w600,
                          0.44,
                          color: Fx.muted,
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
}

/// Figma `1:8096` — header row (`1 of 4 Required` is Figma data copy) + two
/// square 167 tiles. The kit evidence tile is product-anchored (rounded,
/// different gaps/overlays), so the tiles are composed here from kit tokens.
class _EvidenceBlock extends StatelessWidget {
  const _EvidenceBlock({required this.evidence});

  final ui.Image evidence;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 185,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                F2bSectionLabel(l10n.attachments),
                Text(
                  '1 of 4 Required',
                  maxLines: 1,
                  style: Fx.text(
                    11,
                    14,
                    FontWeight.w600,
                    0.44,
                    color: Fx.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 167,
            child: Row(
              children: [
                _FilledTile(image: evidence),
                const SizedBox(width: 16),
                const _EmptyTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8103` — square 167 photo tile + pencil + `Tagged` overlays.
class _FilledTile extends StatelessWidget {
  const _FilledTile({required this.image});

  final ui.Image image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 167,
      height: 167,
      decoration: const BoxDecoration(
        color: Fx.container,
        // Tile shadow tuned to the export (Fig. null-color shadow reads
        // ~5% black here; kit soft black at 8% renders too dark).
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: RawImage(image: image, scale: 2)),
          // 1:8105 pencil chip 28 x 28 at rel (131, 8).
          Positioned(
            left: 131,
            top: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: Fx.pillShadow,
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: Fx.whiteE5,
                    alignment: Alignment.center,
                    child: const FxIcon(
                      id: '1_8107',
                      size: 12,
                      color: Fx.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 1:8108 tag pill 68.72 x 18 at rel (8, 141).
          Positioned(
            left: 8,
            top: 141,
            child: Container(
              height: 18,
              decoration: const BoxDecoration(
                borderRadius:
                    BorderRadius.all(Radius.circular(Fx.pillRadius)),
                boxShadow: Fx.pillShadow,
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.all(Radius.circular(Fx.pillRadius)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: Fx.whiteE5,
                    padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: F2b.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tagged',
                          maxLines: 1,
                          style: Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.44,
                            color: Fx.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8112` — square 167 white tile, two shadows, 56 camera circle.
class _EmptyTile extends StatelessWidget {
  const _EmptyTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: 167,
      height: 167,
      padding: const EdgeInsets.fromLTRB(16, 35.5, 16, 35.5),
      decoration: const BoxDecoration(
        color: Fx.white,
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Fx.tintEmerald,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const FxIcon(id: '1_8115', size: 25, color: Fx.emerald),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.addPhoto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Fx.text(14, 18, FontWeight.w700, -0.35, color: Fx.ink),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.photoRequired,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Fx.caption,
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8120` — square container row: mic + hint + plus. The kit note
/// field has no trailing action and a narrower gap, so this composes kit
/// tokens directly (gap recorded in METHOD.md).
class _NoteRow extends StatelessWidget {
  const _NoteRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 56.67,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Fx.container),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1:8121 mic slot is 12.83 x 17.42; the square FxIcon centers the
          // vector, so the tight box keeps the 16-gap geometry exact.
          const SizedBox(
            width: 12.83,
            height: 17.42,
            child: Center(
              child: FxIcon(id: '1_8122', size: 17.42, color: Fx.muted),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.note,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: Fx.body13.copyWith(color: Fx.muted),
            ),
          ),
          const SizedBox(width: 16),
          // 1:8126 plus slot 16.67 x 24.67, icon top + 8 bottom pad.
          Container(
            width: 16.67,
            height: 24.67,
            padding: const EdgeInsets.only(bottom: 8),
            alignment: Alignment.topCenter,
            child: const FxIcon(id: '1_8128', size: 16.67, color: Fx.muted),
          ),
        ],
      ),
    );
  }
}

/// Figma `1:8129` — 68 block (4 top / 8 bottom) + exact 56 save button.
/// The kit `FxButton` fixes label tracking to −0.14; Figma sets the
/// `SAVE DEFECT` copy at ls 0.7 (rendered 100.22 wide vs 90.99), so the
/// button is composed here from kit tokens + the Figma-exact style
/// (test-only). Copy stays sourced from the l10n override, upper-cased.
class _SaveBlock extends StatelessWidget {
  const _SaveBlock();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Semantics(
        button: true,
        label: l10n.saveAnswer.toUpperCase(),
        child: Container(
          key: const ValueKey('f2b3-save-button'),
          height: 56,
          decoration: const BoxDecoration(
            color: Fx.emerald,
            borderRadius:
                BorderRadius.all(Radius.circular(Fx.pillRadius)),
            boxShadow: Fx.ctaShadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _noop,
              borderRadius:
                  const BorderRadius.all(Radius.circular(Fx.pillRadius)),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.saveAnswer.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style:
                          Fx.text(14, 18, FontWeight.w700, 0.7, color: Fx.white),
                    ),
                    const SizedBox(width: 8),
                    const FxIcon(
                      id: '1_8134',
                      size: 13.58,
                      color: Fx.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
