import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final jobs = operations.map((operation) => operation.jobId).toSet().length;
    return Scaffold(
      backgroundColor: Fx.white,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(_M.gutter, 72, _M.gutter, 120),
            children: [
              Row(
                children: [
                  F2bIconButton(
                    iconId: '1_8640',
                    semanticLabel: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: onBack,
                    size: 48,
                    iconSize: 13.33,
                  ),
                  const SizedBox(width: _M.gapMid),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.technicianSyncTitle,
                          style: Fx.display26.copyWith(color: Fx.ink),
                        ),
                        Text(
                          online
                              ? l10n.technicianAllSynced
                              : l10n.offlineBanner,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.caption.copyWith(color: Fx.muted),
                        ),
                      ],
                    ),
                  ),
                  F2bStatusPill(
                    label: online
                        ? l10n.technicianOnlineSync.replaceAll('\\n', ' ')
                        : l10n.technicianOfflineSync.replaceAll('\\n', ' '),
                    background: Fx.container,
                    foreground: Fx.muted,
                    dot: online ? Fx.emerald : F2b.amber,
                    style: Fx.caption.copyWith(color: Fx.muted),
                  ),
                ],
              ),
              const SizedBox(height: _M.padLarge),
              Container(
                padding: const EdgeInsets.all(_M.gutter),
                decoration: BoxDecoration(
                  color: online
                      ? F2b.mintWash
                      : F2b.peachWash,
                  borderRadius: BorderRadius.circular(Fx.cardRadius),
                  boxShadow: Fx.cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsetsDirectional.only(top: _M.tick),
                      decoration: BoxDecoration(
                        color: online ? Fx.emerald : F2b.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: _M.padMid),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  online
                                      ? l10n.technicianAllSynced
                                      : l10n.offlineBanner,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Fx.title16.copyWith(color: Fx.ink),
                                ),
                              ),
                              const SizedBox(width: _M.gapSmall),
                              F2bStatusPill(
                                label: online
                                    ? l10n.technicianOnlineSync.replaceAll(
                                        '\\n',
                                        ' ',
                                      )
                                    : l10n.technicianOfflineSync.replaceAll(
                                        '\\n',
                                        ' ',
                                      ),
                                background: online
                                    ? Fx.mint33
                                    : F2b.mintSoft,
                                foreground: online
                                    ? Fx.darkInk
                                    : F2b.amberDeep,
                                style: Fx.caption.copyWith(
                                  color: online
                                      ? Fx.darkInk
                                      : F2b.amberDeep,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: _M.gapSmall),
                          Text(
                            online
                                ? l10n.syncComplete
                                : l10n.technicianPendingSync,
                            style: Fx.body13.copyWith(color: Fx.secondaryInk),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _M.padLarge),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: l10n.technicianPendingSync,
                        iconId: '1_8672',
                        value: '$pendingCount',
                        suffix: l10n.items,
                      ),
                    ),
                    const SizedBox(width: _M.gapMid),
                    Expanded(
                      child: _StatCard(
                        label: l10n.syncQueue,
                        iconId: '1_8682',
                        value: '$jobs',
                        suffix: l10n.technicianInspectionQueue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _M.padLarge),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.syncQueue,
                      style: Fx.heading18.copyWith(color: Fx.ink),
                    ),
                  ),
                  Text(
                    online
                        ? l10n.technicianOnlineSync.replaceAll('\\n', ' ')
                        : l10n.technicianPendingSync,
                    style: Fx.caption.copyWith(color: Fx.muted),
                  ),
                ],
              ),
              const SizedBox(height: _M.gapMid),
              if (operations.isEmpty)
                FxCard(
                  radius: 32,
                  padding: const EdgeInsets.all(_M.gutter),
                  child: Text(
                    l10n.noPendingSync,
                    style: Fx.body14.copyWith(color: Fx.muted),
                  ),
                )
              else
                for (final operation in operations)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: _M.gapMid),
                    child: FxCard(
                      radius: 32,
                      padding: const EdgeInsets.all(_M.gutter),
                      shadows: Fx.cardShadow,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Fx.container,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: FxIcon(
                                id: operation.type == 'evidence'
                                    ? '1_8700'
                                    : '1_8740',
                                size: 15,
                                color: Fx.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: _M.gapMid),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  operation.type == 'evidence'
                                      ? l10n.attachments
                                      : l10n.saveAnswer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Fx.title16.copyWith(color: Fx.ink),
                                ),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    '${l10n.jobsTab} • ${operation.jobId}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.ltr,
                                    style: Fx.body13.copyWith(color: Fx.muted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: _M.gapSmall),
                          F2bStatusPill(
                            label: operation.isConflict
                                ? l10n.reportFailed
                                : l10n.technicianQueued,
                            background: operation.isConflict
                                ? F2b.rosePale
                                : Fx.container,
                            foreground: operation.isConflict
                                ? Fx.dangerRed
                                : Fx.muted,
                            dot: operation.isConflict ? null : Fx.emerald,
                            style: Fx.caption.copyWith(
                              color: operation.isConflict
                                  ? Fx.dangerRed
                                  : Fx.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: _M.gapMid),
              F2bFocusFrame(
                child: FxButton(
                  label: l10n.syncNow,
                  onPressed: operations.isEmpty || busy ? null : onRetry,
                  icon:
                      const FxIcon(id: '1_8770', size: 13.33, color: Fx.white),
                  trailingIcon: false,
                ),
              ),
              const SizedBox(height: _M.gapMid),
              Text(
                l10n.technicianPendingSync,
                textAlign: TextAlign.center,
                style: Fx.body13.copyWith(color: Fx.muted),
              ),
            ],
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            // Header-level focus frame for the FxHeader back button; borderless
            // when unfocused so the 1.0x geometry is unchanged.
            child: F2bFocusFrame(
              borderRadius: BorderRadius.zero,
              child: FxHeader(
                title: l10n.technicianSyncTitle,
                showBack: onBack != null,
                titleInset: 4,
                actions: [
                  // 48 dp invisible hit area; the visible disc stays Figma-exact.
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: F2bFocusFrame(
                        borderRadius: BorderRadius.circular(Fx.pillRadius),
                        child: FxProfileButton(
                          initials: 'TR',
                          iconId: '1_8786',
                          onPressed: onProfile,
                          semanticLabel: l10n.technicianProfileTitle,
                        ),
                      ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.iconId,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String iconId;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 144),
      padding: const EdgeInsets.all(_M.padMid),
      decoration: BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.circular(Fx.cardRadius),
        boxShadow: Fx.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: Fx.caption.copyWith(color: Fx.muted),
                ),
              ),
              FxIcon(id: iconId, size: 14, color: Fx.deepGreen),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Fx.text(22, 28, FontWeight.w700, -0.44, color: Fx.ink),
          ),
          Text(
            suffix,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Fx.caption.copyWith(color: Fx.muted),
          ),
        ],
      ),
    );
  }
}

/// Figma-exact spacing for this screen (F2-A `_M` pattern).
abstract final class _M {
  static const double tick = 2;
  static const double gapSmall = 8;
  static const double gapMid = 12;
  static const double padMid = 16;
  static const double gutter = 20;
  static const double padLarge = 24;
}
