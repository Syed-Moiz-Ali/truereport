import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/shared/technician_intl.dart';

/// Figma screen 15. Offline sync queue rebuilt with the real local queue and
/// connectivity state. Values the product does not have (cache size, transfer
/// speed, fake percentages, engine version) are replaced in the same slots.
///
/// Slot-sheet (F2-B.1, L8): same slots/geometry as Figma; only false or unsafe
/// copy is replaced (ARB-only, light-only [Fx]). No `Local Engine v4.2`,
/// no MB / KB/s / % / `60s` claim, no `Standby`/`Queued` raw state, no Fleet
/// nav. Queue states map to ARB (`technicianQueued` / `reportFailed`);
/// raw `SENT`/`FAILED` codes are never shown.
class OfflineSyncView extends StatelessWidget {
  const OfflineSyncView({
    required this.operations,
    required this.pendingCount,
    required this.online,
    required this.onRetry,
    this.onBack,
    this.onProfile,
    this.busy = false,
    super.key,
  });

  final List<SyncOperation> operations;
  final int pendingCount;
  final bool online;
  final VoidCallback onRetry;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final bool busy;

  static const double targetHeight = 1362;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Fx.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < targetHeight;

          final content = SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),
                _Container(
                  operations: operations,
                  pendingCount: pendingCount,
                  online: online,
                  onRetry: onRetry,
                  onBack: onBack,
                  busy: busy,
                ),
                const SizedBox(height: 112),
              ],
            ),
          );

          return Stack(
            children: [
              if (isCompact)
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  child: content,
                )
              else
                content,
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                height: 64,
                child: _Header(onProfile: onProfile),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                top: isCompact ? null : 1281.5,
                bottom: isCompact ? 0 : null,
                height: 80,
                child: _Nav(onBack: onBack),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 1:8635 Container 390x1185.94 pad 8,20,8,20 → content 350x1169.94.
class _Container extends StatelessWidget {
  const _Container({
    required this.operations,
    required this.pendingCount,
    required this.online,
    required this.onRetry,
    required this.onBack,
    required this.busy,
  });

  final List<SyncOperation> operations;
  final int pendingCount;
  final bool online;
  final VoidCallback onRetry;
  final VoidCallback? onBack;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = math.min(350.0, constraints.maxWidth - 40);
        return SizedBox(
          width: math.min(390.0, constraints.maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SubNav(online: online, onBack: onBack, cardWidth: cardWidth),
                _OfflineMargin(online: online, cardWidth: cardWidth),
                _StatsMargin(
                  operations: operations,
                  pendingCount: pendingCount,
                  online: online,

                  cardWidth: cardWidth,
                ),
                _UploadMargin(
                  operations: operations,
                  online: online,

                  cardWidth: cardWidth,
                ),
                _RetryMargin(
                  online: online,
                  onRetry: onRetry,
                  busy: busy,

                  cardWidth: cardWidth,
                ),
                SizedBox(width: cardWidth, height: 104),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 1:8636 sub-nav 350x64 HORIZONTAL pad top 4.
class _SubNav extends StatelessWidget {
  const _SubNav({
    required this.online,
    required this.onBack,

    required this.cardWidth,
  });

  final bool online;
  final VoidCallback? onBack;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.technicianSyncTitle;
    final subtitle = online ? l10n.technicianAllSynced : l10n.offlineBanner;
    final signalLabel = online
        ? l10n.technicianOnlineSync.replaceAll('\\n', ' ')
        : l10n.technicianOfflineSync.replaceAll('\\n', ' ');

    return SizedBox(
      width: cardWidth,
      height: 64,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 60,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Semantics(
                      button: true,
                      label: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      child: GestureDetector(
                        onTap: onBack,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 32,
                              child: Text(
                                title,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: Fx.display26,
                              ),
                            ),
                            SizedBox(
                              height: 28,
                              child: Text(
                                subtitle,
                                maxLines: 2,
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
              ),
            ),
            const SizedBox(width: 8),
            Container(
              key: const ValueKey('f2b3-nosignal'),
              width: 94.78,
              height: 40,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              decoration: const BoxDecoration(
                color: Fx.surfaceHigh,
                borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
                boxShadow: Fx.pillShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14.67,
                    height: 13.2,
                    child: Center(
                      child: FxIcon(
                        id: '1_8648',
                        size: 14.67,
                        color: online ? Fx.emerald : Fx.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: Text(
                        signalLabel,
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
      ),
    );
  }
}

/// 1:8651 margin 350x196.19 pad top 24.
class _OfflineMargin extends StatelessWidget {
  const _OfflineMargin({required this.online, required this.cardWidth});

  final bool online;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = online ? l10n.technicianAllSynced : l10n.offlineBanner;
    final chipText = online
        ? l10n.technicianOnlineSync.replaceAll('\\n', ' ')
        : l10n.technicianOfflineSync.replaceAll('\\n', ' ');
    final bodyText = online ? l10n.technicianAllSynced : l10n.offlineBanner;

    return Container(
      width: cardWidth,
      height: 196.19,
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: cardWidth,
        height: 172.19,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: online ? F2b.mintWash : F2b.peachWash,
          borderRadius: const BorderRadius.all(Radius.circular(Fx.cardRadius)),
          boxShadow: Fx.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 12,
                height: 12,
                child: _OfflineDot(online: online),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 132.19,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 44,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: Text(
                                title,
                                maxLines: 2,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: Fx.title16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StoreChip(text: chipText),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3.19),
                    SizedBox(
                      height: 85,
                      child: Text(
                        bodyText,
                        maxLines: 4,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          fontFamily: Fx.fontFamily,
                          fontFamilyFallback: Fx.fontFallback,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineDot extends StatelessWidget {
  const _OfflineDot({this.online = false});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? Fx.emerald : F2b.amber;
    final outerColor = online
        ? const Color(0x6610B981)
        : const Color(0x66F59E0B);
    return Stack(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: outerColor, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 73.34,
      height: 32,
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      decoration: const BoxDecoration(
        color: Color(0x80FDE68A),
        borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
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
  const _StatsMargin({
    required this.operations,
    required this.pendingCount,
    required this.online,

    required this.cardWidth,
  });

  final List<SyncOperation> operations;
  final int pendingCount;
  final bool online;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final count1 = formatCountLocalized(operations.length, localeName);
    final unit1 = l10n.itemsSelected;
    final count2 = formatCountLocalized(pendingCount, localeName);
    final title2 = l10n.technicianInspection;
    final sub2 = online
        ? l10n.technicianOnlineSync
        : l10n.technicianOfflineSync;

    return Container(
      width: cardWidth,
      height: 169.75,
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        width: cardWidth,
        height: 145.75,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatCardOne(count: count1, unit: unit1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCardTwo(count: count2, title: title2, subtitle: sub2),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1:8667 card 169x144 r32 white pad 16 gap 55.
class _StatCardOne extends StatelessWidget {
  const _StatCardOne({required this.count, required this.unit});

  final String count;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Expanded(
                  child: SizedBox(
                    height: 14,
                    child: Text(
                      'BUFFERED CACHE',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.55,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 31,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Text(
                      count,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
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
                    child: Text(
                      unit,
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
  const _StatCardTwo({
    required this.count,
    required this.title,
    required this.subtitle,
  });

  final String count;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Expanded(
                  child: SizedBox(
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
                          fontFamilyFallback: Fx.fontFallback,
                          fontSize: 11,
                          height: 14 / 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.55,
                          color: Fx.muted,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 28,
                    child: Text(
                      count,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 22,
                        height: 28 / 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.44,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 28,
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
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
                    height: 14,
                    child: Text(
                      subtitle,
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
  const _UploadMargin({
    required this.operations,
    required this.online,

    required this.cardWidth,
  });

  final List<SyncOperation> operations;
  final bool online;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: cardWidth,
      height: 510,
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: cardWidth,
        height: 486,
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            _QueueHeader(online: online, cardWidth: cardWidth),
            const SizedBox(height: 12),
            _ActiveCard(
              operations: operations,
              online: online,

              cardWidth: cardWidth,
            ),
            const SizedBox(height: 12),
            _QueuedRowTwo(operations: operations, cardWidth: cardWidth),
            const SizedBox(height: 12),
            _QueuedRowThree(operations: operations, cardWidth: cardWidth),
          ],
        ),
      ),
    );
  }
}

/// 1:8690 header 350x24 HORIZONTAL gap 112.57 pad left/right 4.
class _QueueHeader extends StatelessWidget {
  const _QueueHeader({required this.online, required this.cardWidth});

  final bool online;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.syncQueue;
    final status = online
        ? l10n.technicianOnlineSync
        : l10n.technicianOfflineSync;

    return Container(
      width: cardWidth,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 24,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: Fx.heading18,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 14,
            child: Text(
              status,
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
  const _ActiveCard({
    required this.operations,
    required this.online,

    required this.cardWidth,
  });

  final List<SyncOperation> operations;
  final bool online;

  final double cardWidth;

  String _opTitle(AppLocalizations l10n, SyncOperation op) {
    switch (op.type) {
      case 'SAVE_ANSWER':
        return l10n.saveAnswer;
      case 'EVIDENCE_PHOTO':
        return l10n.evidencePending;
      default:
        return op.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final op = operations.isNotEmpty ? operations.first : null;
    final title = (op != null ? _opTitle(l10n, op) : l10n.noResults);
    final subtitle = (op != null ? 'Job #${op.jobId}' : '');
    final statusChip = (online ? l10n.technicianOnlineSync : 'Waiting');
    final progressText = (operations.isNotEmpty
        ? '${operations.length} items'
        : '0%');
    final remainingText = (operations.length > 1
        ? '${operations.length - 1} remaining'
        : '0 remaining');
    final speed = (online ? 'Connected' : '0.0 KB/s');
    final pendingJobsText = (operations.length > 1
        ? '${operations.length - 1} in Line'
        : '0 in Line');

    return Container(
      key: const ValueKey('queue'),
      width: cardWidth,
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
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const _ActiveIcon(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 44,
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                    style: Fx.title16,
                                  ),
                                ),
                                SizedBox(
                                  height: 36,
                                  child: Text(
                                    subtitle,
                                    maxLines: 2,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                    style: Fx.body13,
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
                const SizedBox(width: 8),
                _StandbyChip(label: statusChip),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                      Positioned(left: 0, top: 0, child: _Fill()),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 91.56,
                        height: 14,
                        child: Text(
                          progressText,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: Fx.caption,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 99.63,
                        height: 14,
                        child: Text(
                          remainingText,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            fontFamily: Fx.fontFamily,
                            fontFamilyFallback: Fx.fontFallback,
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
          _Metrics(speed: speed, pendingJobs: pendingJobsText),
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
  const _StandbyChip({required this.label});

  final String label;

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
        label,
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
  const _Metrics({required this.speed, required this.pendingJobs});

  final String speed;
  final String pendingJobs;

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
                          speed,
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
          const Spacer(),
          Container(width: 1, height: 32, color: Fx.surfaceHigh),
          const Spacer(),
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
                          pendingJobs,
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
  const _QueuedRowTwo({required this.operations, required this.cardWidth});

  final List<SyncOperation> operations;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final op = operations.length > 1 ? operations[1] : null;
    final title = op != null ? op.type : l10n.technicianInspection;
    final subtitle = op != null ? '${l10n.jobsTab} #${op.jobId}' : '';
    final status = l10n.statusAssigned;
    const size = '18.4 MB';

    return Container(
      width: cardWidth,
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
          Expanded(
            child: SizedBox(
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
                  Expanded(
                    child: SizedBox(
                      height: 58,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 22,
                            child: Text(
                              title,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: Fx.title16,
                            ),
                          ),
                          SizedBox(
                            height: 36,
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: Fx.body13,
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
          const SizedBox(width: 8),
          SizedBox(
            width: 56.84,
            height: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 14,
                  child: Text(
                    status,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.end,
                    style: Fx.caption,
                  ),
                ),
                const SizedBox(
                  height: 18,
                  child: Text(
                    size,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
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
  const _QueuedRowThree({required this.operations, required this.cardWidth});

  final List<SyncOperation> operations;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final op = operations.length > 2 ? operations[2] : null;
    final title = op != null ? op.type : l10n.attachments;
    final subtitle = op != null ? '${l10n.jobsTab} #${op.jobId}' : '';
    final status = l10n.statusAssigned;
    const size = '6.2 MB';

    return Container(
      width: cardWidth,
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
          Expanded(
            child: SizedBox(
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
                  Expanded(
                    child: SizedBox(
                      height: 58,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 22,
                            child: Text(
                              title,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: Fx.title16,
                            ),
                          ),
                          SizedBox(
                            height: 36,
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: Fx.body13,
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
          const SizedBox(width: 8),
          SizedBox(
            width: 54.05,
            height: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 14,
                  child: Text(
                    status,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.end,
                    style: Fx.caption,
                  ),
                ),
                const SizedBox(
                  height: 18,
                  child: Text(
                    size,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
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
  const _RetryMargin({
    required this.online,
    required this.onRetry,
    required this.busy,

    required this.cardWidth,
  });

  final bool online;
  final VoidCallback onRetry;
  final bool busy;

  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.syncNow;
    final hint = l10n.technicianPendingSync;

    return Container(
      width: cardWidth,
      height: 126,
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: cardWidth,
        height: 102,
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            FxButton(
              key: const ValueKey('retry'),
              label: label,
              onPressed: busy ? null : onRetry,
              icon: const FxIcon(id: '1_8770', size: 13.33, color: Fx.white),
              trailingIcon: false,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 18,
              child: Center(
                child: Text(
                  hint,
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
class _Header extends StatelessWidget {
  const _Header({this.onProfile});

  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.technicianSyncTitle;

    return Container(
      key: const ValueKey('header'),
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
                        height: 28,
                        child: Text(
                          title,
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
                const Spacer(),
                Semantics(
                  button: true,
                  label: l10n.technicianProfileTitle,
                  child: GestureDetector(
                    onTap: onProfile,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
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
class _Nav extends StatelessWidget {
  const _Nav({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const ValueKey('dock'),
      height: 80,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Center(
        child: Container(
          width: 350,
          height: 64,
          decoration: const BoxDecoration(
            color: Fx.white,
            borderRadius: BorderRadius.all(Radius.circular(Fx.pillRadius)),
            boxShadow: Fx.navShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavLink(
                iconId: '1_8791',
                iconW: 18.33,
                iconH: 20.17,
                label: l10n.technicianJobIntake,
                selected: false,
                onTap: onBack,
              ),
              const SizedBox(width: 23.5),
              _NavLink(
                iconId: '1_8796',
                iconW: 16.5,
                iconH: 14.67,
                label: l10n.statusFinalized,
                selected: false,
              ),
              const SizedBox(width: 23.5),
              _NavLink(
                iconId: '1_8801',
                iconW: 14.67,
                iconH: 14.67,
                label: l10n.technicianSyncTitle,
                selected: true,
              ),
              const SizedBox(width: 23.5),
              _NavLink(
                iconId: '1_8806',
                iconW: 18.2,
                iconH: 15.58,
                label: l10n.technicianProfileTitle,
                selected: false,
              ),
            ],
          ),
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
    this.onTap,
  });

  final String iconId;
  final double iconW;
  final double iconH;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Fx.ink : Fx.muted;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
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
                    fontFamilyFallback: Fx.fontFallback,
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
        ),
      ),
    );
  }
}
