import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// F2-B.3 Part 2 — Level 1 exact-structure fixture for Figma screen 15
/// "Offline Sync Queue" (node `1:8633`, 390 x 1361.94, export folder
/// `14_15._Offline_Sync_Queue`).
///
/// Test-only widget tree that mirrors the Figma node structure
/// (`docs/ui/figma/f2b-nodes/15-offline-sync.txt`) using only the shared
/// kits (`Fx*` + `F2b*` tokens/primitives). It deliberately does NOT reuse
/// the production `OfflineSyncView` (product-anchored IIUWWIFJO QRSIIHYESA).
/// copy, real counts, no Fleet nav) while this fixture renders the Figma
/// nodes verbatim (invented versions, metrics, Fleet nav).
///
/// Figma-exact values that have no kit token are inlined here (test-only)
/// and listed as kit gaps in `docs/ui/figma/fidelity/f2b3/offline-sync/METHOD.md`.
/// Nothing here ships: no `lib/` change, no pubspec change, no raster decode
/// (this screen has no photo raster per spec §5 — icons only via `FxIcon`).
class F2b3OfflineSyncFixture extends StatelessWidget {
  const F2b3OfflineSyncFixture({super.key});

  static const double width = 390;
  static const double height = 1362;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: Fx.white,
        child: Stack(
          children: [
            // Main 1:8634: top pad 64 (header space), container, bottom 112.
            Column(
              children: [
                SizedBox(height: 64),
                _Container(),
                SizedBox(height: 112),
              ],
            ),
            // Header 1:8776 overlay @0,0 390x64.
            Positioned(left: 0, top: 0, child: _Header()),
            // Nav 1:8787 @0,1281.5 390x80.
            Positioned(left: 0, top: 1281.5, child: _Nav()),
          ],
        ),
      ),
    );
  }
}

/// 1:8635 Container 390x1185.94 pad 8,20,8,20 → content 350x1169.94.
class _Container extends StatelessWidget {
  const _Container();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: 1185.94,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: const Column(
        children: [
          _SubNav(), // 1:8636 350x64
          _OfflineMargin(), // 1:8651 350x196.19
          _StatsMargin(), // 1:8665 350x169.75
          _UploadMargin(), // 1:8688 350x510
          _RetryMargin(), // 1:8766 350x126
          SizedBox(width: 350, height: 104), // 1:8775 spacer
        ],
      ),
    );
  }
}

/// 1:8636 sub-nav 350x64 HORIZONTAL pad top 4.
class _SubNav extends StatelessWidget {
  const _SubNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 64,
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1:8637 left 235.38x60 gap 12.
          SizedBox(
            width: 235.38,
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1:8638 back 41.81x44 r9999 white + double shadow.
                Container(
                  width: 41.81,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                    boxShadow: Fx.cardShadow,
                  ),
                  alignment: Alignment.center,
                  child: const FxIcon(
                    id: '1_8640',
                    size: 13.33,
                    color: Fx.ink,
                  ),
                ),
                const SizedBox(width: 12),
                // 1:8641 titles 181.57x60.
                SizedBox(
                  width: 181.57,
                  height: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 181.57,
                        height: 32,
                        child: Text(
                          'Sync Status',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.display26,
                        ),
                      ),
                      SizedBox(
                        width: 181.57,
                        height: 28,
                        child: Text(
                          'Local Engine v4.2 \u2022 Background\nsync',
                          maxLines: 2,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 1:8646 No-Signal chip 94.78x40 r9999 #EEEDF3 + shadow, pad 6,12,6,12 gap 6.
          // Kit F2bStatusPill is fixed 22 tall — exact 40 pill built here.
          Container(
            key: const ValueKey('f2b3-nosignal'),
            width: 94.78,
            height: 40,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            decoration: const BoxDecoration(
              color: Fx.surfaceHigh,
              borderRadius: BorderRadius.all(
                Radius.circular(Fx.pillRadius),
              ),
              boxShadow: Fx.pillShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14.67,
                  height: 13.2,
                  child: Center(
                    child: FxIcon(
                      id: '1_8648',
                      size: 14.67,
                      color: Fx.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 50.11,
                  height: 28,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14.95),
                    child: Text(
                      'No\nSignal',
                      maxLines: 2,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: Fx.caption,
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

/// 1:8651 margin 350x196.19 pad top 24.
class _OfflineMargin extends StatelessWidget {
  const _OfflineMargin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 196.19,
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: 350,
        height: 172.19,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: F2b.peachWash,
          borderRadius: BorderRadius.all(Radius.circular(Fx.cardRadius)),
          boxShadow: Fx.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1:8653 margin 12x14 pad top 2 → dot 12x12.
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 12,
                height: 12,
                child: _OfflineDot(),
              ),
            ),
            const SizedBox(width: 16),
            // 1:8657 content 282x132.19 gap 3.19.
            SizedBox(
              width: 282,
              height: 132.19,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    SizedBox(
                      width: 282,
                      height: 44,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200.66,
                            height: 44,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.16),
                            child: Text(
                              'Working Offline \u2014 Saving\nLocally',
                              maxLines: 2,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: Fx.title16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 1:8661 Store Active 73.34x32 #FDE68A80 pad 2,28.23,2,8.
                        // Kit pill is 22 tall — exact chip built here.
                        const _StoreChip(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3.19),
                  const SizedBox(
                    width: 282,
                    height: 85,
                    child: Text(
                      'All high-res vehicle capture tags and\ninspection checkpoints are safely cached to\ndevice storage. Sync will automatically\nresume when network restores.',
                      maxLines: 4,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontSize: 13,
                        height: 21.13 / 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                        color: Fx.secondaryInk,
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
}

class _OfflineDot extends StatelessWidget {
  const _OfflineDot();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: F2b.amber,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0x66F59E0B),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 73.34,
      height: 32,
      padding: const EdgeInsets.fromLTRB(8, 2, 28.23, 2),
      decoration: const BoxDecoration(
        color: Color(0x80FDE68A),
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        'Store\nActive',
        maxLines: 2,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: Fx.text(11, 14, FontWeight.w700, 0.44, color: F2b.amberDeep),
      ),
    );
  }
}

/// 1:8665 margin 350x169.75 pad top 24 → row 350x145.75 gap 12.
class _StatsMargin extends StatelessWidget {
  const _StatsMargin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 169.75,
      padding: const EdgeInsets.only(top: 24),
      child: const SizedBox(
        width: 350,
        height: 145.75,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatCardOne(),
            SizedBox(width: 12),
            _StatCardTwo(),
          ],
        ),
      ),
    );
  }
}

/// 1:8667 card 169x144 r32 white pad 16 gap 55.
class _StatCardOne extends StatelessWidget {
  const _StatCardOne();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 169,
      height: 144,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(Fx.cardRadius)),
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 105.55,
                  height: 14,
                  child: Text(
                    'BUFFERED CACHE',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.55,
                      color: Fx.muted,
                    ),
                  ),
                ),
                SizedBox(width: 13.45),
                SizedBox(
                  width: 13.5,
                  height: 12,
                  child: Center(
                    child: FxIcon(
                      id: '1_8672',
                      size: 13.5,
                      color: Fx.deepGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 55),
          // 1:8673 margin pad top 12 → paragraph 137x31.
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: 137,
              height: 31,
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    top: 0,
                    width: 56.53,
                    height: 28,
                    child: Text(
                      '148.6',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontSize: 22,
                        height: 28 / 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.44,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 60.98,
                    top: 11.5,
                    width: 51.45,
                    height: 14,
                    child: Text(
                      'MB Local',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: Fx.caption,
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
}

/// 1:8677 card 169x145.75 r32 white pad 16 gap 0.
class _StatCardTwo extends StatelessWidget {
  const _StatCardTwo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 169,
      height: 145.75,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(Fx.cardRadius)),
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 15.75,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 95.95,
                  height: 14,
                  child: Padding(
                    padding: EdgeInsets.only(top: 0.87),
                    child: Text(
                      'PENDING BATCH',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.55,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 23.05),
                SizedBox(
                  width: 14.25,
                  height: 15.75,
                  child: Center(
                    child: FxIcon(
                      id: '1_8682',
                      size: 15.75,
                      color: Fx.deepGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 1:8683 margin pad top 12 → paragraph 137x86.
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: 137,
              height: 86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 13.02,
                    height: 28,
                    child: Text(
                      '3',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontSize: 22,
                        height: 28 / 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.44,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const SizedBox(
                    width: 120.61,
                    height: 28,
                    child: Text(
                      'Inspections',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontSize: 22,
                        height: 28 / 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.44,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7.5),
                  SizedBox(
                    width: 72.05,
                    height: 14,
                    child: Text(
                      'Awaiting link',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: Fx.caption,
                    ),
                  ),
                  const SizedBox(height: 5.5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1:8688 margin 350x510 pad top 24 → section 350x486 gap 12 pad top 8.
class _UploadMargin extends StatelessWidget {
  const _UploadMargin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 510,
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: 350,
        height: 486,
        padding: const EdgeInsets.only(top: 8),
        child: const Column(
          children: [
            _QueueHeader(), // 350x24
            SizedBox(height: 12),
            _ActiveCard(), // 1:8695 350x222
            SizedBox(height: 12),
            _QueuedRowTwo(), // 1:8736 350x98
            SizedBox(height: 12),
            _QueuedRowThree(), // 1:8751 350x98
          ],
        ),
      ),
    );
  }
}

/// 1:8690 header 350x24 HORIZONTAL gap 112.57 pad left/right 4.
class _QueueHeader extends StatelessWidget {
  const _QueueHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 122.98,
            height: 24,
            child: Text(
              'Upload Queue',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: Fx.heading18,
            ),
          ),
          const SizedBox(width: 112.57),
          SizedBox(
            width: 106.45,
            height: 14,
            child: Text(
              'Auto-retry paused',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: Fx.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// 1:8695 active card 350x222 r32 white pad 20 gap 16.
class _ActiveCard extends StatelessWidget {
  const _ActiveCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('f2b3-active'),
      width: 350,
      height: 222,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(Fx.cardRadius)),
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 310,
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 224.78,
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1:8698 icon pill 30.16x40 #F4F3F8.
                      const _ActiveIcon(),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 182.62,
                        height: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 182.62,
                              height: 44,
                              child: Text(
                                'Uploading Evidence\nPhotos (4/12)',
                                maxLines: 2,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: Fx.title16,
                              ),
                            ),
                            SizedBox(
                              width: 182.62,
                              height: 36,
                              child: Text(
                                'Job #IN-88912 \u2022 2024 Ford F-\n150 Lightning',
                                maxLines: 2,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: Fx.body13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 1:8706 Standby 68.3x22 #EEEDF3 pad 4,10,4,10.
                const _StandbyChip(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 1:8708 progress 310x26 gap 6.
          SizedBox(
            width: 310,
            height: 26,
            child: Column(
              children: [
                const SizedBox(
                  width: 310,
                  height: 6,
                  child: Stack(
                    children: [
                      _Track(),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: _Fill(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 310,
                  height: 14,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 91.56,
                        height: 14,
                        child: Text(
                          '33% completed',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.caption,
                        ),
                      ),
                      const SizedBox(width: 118.81),
                      const SizedBox(
                        width: 99.63,
                        height: 14,
                        child: Text(
                          '8 items remaining',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: Fx.fontFamily,
                            fontSize: 11,
                            height: 14 / 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.44,
                            color: Fx.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 1:8716 metrics 310x44 pad top 8.
          const _Metrics(),
        ],
      ),
    );
  }
}

class _ActiveIcon extends StatelessWidget {
  const _ActiveIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.16,
      height: 40,
      decoration: const BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
      alignment: Alignment.center,
      child: const FxIcon(id: '1_8700', size: 13.33, color: Fx.deepGreen),
    );
  }
}

class _StandbyChip extends StatelessWidget {
  const _StandbyChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68.3,
      height: 22,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: const BoxDecoration(
        color: Fx.surfaceHigh,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
      alignment: Alignment.center,
      child: Text(
        'Standby',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: Fx.text(11, 14, FontWeight.w600, 0.44, color: Fx.ink),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      height: 6,
      decoration: const BoxDecoration(
        color: Fx.surfaceHigh,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 103.22,
      height: 6,
      decoration: const BoxDecoration(
        color: Fx.emerald,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      height: 44,
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 121.97,
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _MetricIcon(id: '1_8720', w: 12.5, h: 10),
                const SizedBox(width: 8),
                SizedBox(
                  width: 85.97,
                  height: 36,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 85.97,
                        height: 14,
                        child: Text(
                          'Transfer Speed',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.caption,
                        ),
                      ),
                      SizedBox(
                        width: 85.97,
                        height: 22,
                        child: Text(
                          '0.0 KB/s',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.title16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 37.78),
          Container(width: 1, height: 32, color: Fx.surfaceHigh),
          const SizedBox(width: 37.77),
          SizedBox(
            width: 111.48,
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _MetricIcon(id: '1_8730', w: 11.88, h: 9.38),
                const SizedBox(width: 8),
                SizedBox(
                  width: 75.48,
                  height: 36,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 75.48,
                        height: 14,
                        child: Text(
                          'Pending Jobs',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.caption,
                        ),
                      ),
                      SizedBox(
                        width: 75.48,
                        height: 22,
                        child: Text(
                          '2 in Line',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.title16,
                        ),
                      ),
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
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({required this.id, required this.w, required this.h});

  final String id;
  final double w;
  final double h;

  @override
  Widget build(BuildContext context) {
    final s = w > h ? w : h;
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Fx.surfaceHigh,
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
      alignment: Alignment.center,
      child: FxIcon(id: id, size: s, color: Fx.muted),
    );
  }
}

/// 1:8736 queued row 350x98 r32 pad 20.
class _QueuedRowTwo extends StatelessWidget {
  const _QueuedRowTwo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 98,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(Fx.cardRadius)),
        boxShadow: Fx.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 246,
            height: 58,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30.39,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const FxIcon(
                    id: '1_8740',
                    size: 16.67,
                    color: Fx.muted,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 203.61,
                  height: 58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 203.61,
                        height: 22,
                        child: Text(
                          'Telemetry Telematics & Checkpoints',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.title16,
                        ),
                      ),
                      SizedBox(
                        width: 203.61,
                        height: 36,
                        child: Text(
                          'Job #IN-88909 \u2022 6 Diagnostic\nCodes',
                          maxLines: 2,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.body13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Right cluster 56.84x32 right-aligned.
          SizedBox(
            width: 56.84,
            height: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 46.05,
                  height: 14,
                  child: Text(
                    'Queued',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.end,
                    style: Fx.caption,
                  ),
                ),
                const SizedBox(
                  width: 48.84,
                  height: 18,
                  child: Text(
                    '18.4 MB',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: Fx.ink,
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

/// 1:8751 queued row 350x98 r32 pad 20.
class _QueuedRowThree extends StatelessWidget {
  const _QueuedRowThree();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 98,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(Fx.cardRadius)),
        boxShadow: Fx.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 252.53,
            height: 58,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36.3,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    borderRadius: BorderRadius.all(
                      Radius.circular(Fx.pillRadius),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const FxIcon(
                    id: '1_8755',
                    size: 15.83,
                    color: Fx.muted,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 204.23,
                  height: 58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 204.23,
                        height: 22,
                        child: Text(
                          'Body Schematics Pin Markups',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.title16,
                        ),
                      ),
                      SizedBox(
                        width: 204.23,
                        height: 36,
                        child: Text(
                          'Job #IN-88904 \u2022 4 Dent\nAnnotations',
                          maxLines: 2,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.body13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 54.05,
            height: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 46.05,
                  height: 14,
                  child: Text(
                    'Queued',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.end,
                    style: Fx.caption,
                  ),
                ),
                const SizedBox(
                  width: 42.73,
                  height: 18,
                  child: Text(
                    '6.2 MB',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: Fx.ink,
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

/// 1:8766 margin 350x126 pad top 24 → zone 350x102 gap 12 pad top 16.
class _RetryMargin extends StatelessWidget {
  const _RetryMargin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 126,
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: 350,
        height: 102,
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            // 1:8768 CTA 350x56 emerald + shadow, gap 8, label 14/700 ls-0.14.
            FxButton(
              key: const ValueKey('f2b3-retry'),
              label: 'Retry Sync Now',
              onPressed: () {},
              icon: const FxIcon(
                id: '1_8770',
                size: 13.33,
                color: Fx.white,
              ),
              trailingIcon: false,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 350,
              height: 18,
              child: Center(
                child: Text(
                  'Device will ping master servers every 60 seconds',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.center,
                  style: Fx.body13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1:8776 header 390x64 #FFFFFFCC + shadow + blur 48.
/// Built from primitives: FxHeader uses a Material glyph and -0.27
/// tracking; Figma needs vector 1_8781 and -0.55 tracking.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('f2b3-header'),
      width: 390,
      height: 64,
      decoration: const BoxDecoration(
        color: Fx.whiteCC,
        boxShadow: Fx.headerShadow,
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 172.31,
                  height: 36,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Fx.container,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const FxIcon(
                          id: '1_8781',
                          size: 18.33,
                          color: Fx.deepGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 124.31,
                        height: 28,
                        child: Text(
                          'Sync Queue',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.text(
                            22,
                            28,
                            FontWeight.w700,
                            -0.55,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 145.69),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Fx.deepGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const FxIcon(
                    id: '1_8786',
                    size: 12,
                    color: Fx.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 1:8787 nav 390x80 pad bottom 16 → pill 350x64 r9999 white + double shadow.
/// Built from primitives: FxDock slot/gap geometry differs (44/39.5 vs 56/23.5).
class _Nav extends StatelessWidget {
  const _Nav();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: 80,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: 350,
        height: 64,
        decoration: const BoxDecoration(
          color: Fx.white,
          borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
          boxShadow: Fx.navShadow,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavLink(
              iconId: '1_8791',
              iconW: 18.33,
              iconH: 20.17,
              label: 'Intake',
              selected: false,
            ),
            SizedBox(width: 23.5),
            _NavLink(
              iconId: '1_8796',
              iconW: 16.5,
              iconH: 14.67,
              label: 'Fleet',
              selected: false,
            ),
            SizedBox(width: 23.5),
            _NavLink(
              iconId: '1_8801',
              iconW: 14.67,
              iconH: 14.67,
              label: 'Sync',
              selected: true,
            ),
            SizedBox(width: 23.5),
            _NavLink(
              iconId: '1_8806',
              iconW: 18.2,
              iconH: 15.58,
              label: 'Profile',
              selected: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.iconId,
    required this.iconW,
    required this.iconH,
    required this.label,
    required this.selected,
  });

  final String iconId;
  final double iconW;
  final double iconH;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Fx.ink : Fx.muted;
    return SizedBox(
      width: 56,
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: iconW,
            height: iconH,
            child: Center(
              child: FxIcon(
                id: iconId,
                size: iconW > iconH ? iconW : iconH,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 14,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: Fx.fontFamily,
                fontSize: 11,
                height: 14 / 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.44,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
