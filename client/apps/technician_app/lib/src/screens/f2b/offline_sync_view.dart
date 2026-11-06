import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/offline/offline_models.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';

/// Figma screen 15. Offline sync queue rebuilt with the real local queue and
/// connectivity state. Values the product does not have (cache size, transfer
/// speed, fake percentages, engine version) are replaced in the same slots.
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
            padding: const EdgeInsetsDirectional.fromSTEB(20, 72, 20, 120),
            children: [
              Row(
                children: [
                  F2bIconButton(
                    iconId: '1_8640',
                    semanticLabel: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: onBack,
                    size: 42,
                    iconSize: 13.33,
                  ),
                  const SizedBox(width: 12),
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
                          overflow: TextOverflow.clip,
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
                    dot: online ? Fx.emerald : const Color(0xFFF59E0B),
                    style: Fx.caption.copyWith(color: Fx.muted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: online
                      ? const Color(0xFFE9F9F1)
                      : const Color(0xFFFFF5EB),
                  borderRadius: BorderRadius.circular(Fx.cardRadius),
                  boxShadow: Fx.cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsetsDirectional.only(top: 2),
                      decoration: BoxDecoration(
                        color: online ? Fx.emerald : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                                  overflow: TextOverflow.clip,
                                  style: Fx.title16.copyWith(color: Fx.ink),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                    ? const Color(0x336FFBBE)
                                    : const Color(0x80FDE68A),
                                foreground: online
                                    ? Fx.darkInk
                                    : const Color(0xFFB45309),
                                style: Fx.caption.copyWith(
                                  color: online
                                      ? Fx.darkInk
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: l10n.technicianPendingSync,
                      iconId: '1_8672',
                      value: '$pendingCount',
                      suffix: l10n.items,
                    ),
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 24),
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
              const SizedBox(height: 12),
              if (operations.isEmpty)
                FxCard(
                  radius: 32,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l10n.noPendingSync,
                    style: Fx.body14.copyWith(color: Fx.muted),
                  ),
                )
              else
                for (final operation in operations)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 12),
                    child: FxCard(
                      radius: 32,
                      padding: const EdgeInsets.all(20),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  operation.type == 'evidence'
                                      ? l10n.attachments
                                      : l10n.saveAnswer,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: Fx.title16.copyWith(color: Fx.ink),
                                ),
                                Text(
                                  '${l10n.jobsTab} • ${operation.jobId}',
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  textDirection: TextDirection.ltr,
                                  style: Fx.body13.copyWith(color: Fx.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          F2bStatusPill(
                            label: operation.state,
                            background: operation.isConflict
                                ? const Color(0xFFFFDAD6)
                                : Fx.container,
                            foreground: operation.isConflict
                                ? const Color(0xFFB91A24)
                                : Fx.muted,
                            style: Fx.caption.copyWith(
                              color: operation.isConflict
                                  ? const Color(0xFFB91A24)
                                  : Fx.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 12),
              FxButton(
                label: l10n.syncNow,
                onPressed: operations.isEmpty || busy ? null : onRetry,
                icon: const FxIcon(id: '1_8770', size: 13.33, color: Fx.white),
                trailingIcon: false,
              ),
              const SizedBox(height: 12),
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
            child: FxHeader(
              title: l10n.technicianSyncTitle,
              showBack: onBack != null,
              titleInset: 4,
              actions: [
                FxProfileButton(
                  initials: 'TR',
                  iconId: '1_8786',
                  onPressed: onProfile,
                  semanticLabel: l10n.technicianProfileTitle,
                ),
              ],
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
      height: 144,
      padding: const EdgeInsets.all(16),
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
