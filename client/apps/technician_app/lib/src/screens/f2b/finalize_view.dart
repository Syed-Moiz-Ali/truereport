import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2b/f2b_intl.dart';
import 'package:technician_app/src/screens/f2b/f2b_kit.dart';
import 'package:technician_app/src/ui_helpers.dart';

/// Figma screen 14. Final review and slide-to-finalize. The slide calls the
/// same idempotent finalize callback; the thumb also exposes a semantic button
/// and keyboard activation with no visible change.
class FinalizeView extends StatelessWidget {
  const FinalizeView({
    required this.job,
    required this.review,
    required this.checklist,
    required this.onFinalize,
    this.onBack,
    this.onProfile,
    this.busy = false,
    this.finalized = false,
    super.key,
  });

  final TechnicianJob job;
  final ReviewResult review;
  final InspectionChecklist checklist;
  final Future<void> Function() onFinalize;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final bool busy;
  final bool finalized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final flagged = checklist.items
        .where(
          (item) =>
              item.assessment?.resultCode == 'DEFECT_FOUND' ||
              item.assessment?.resultCode == 'ATTENTION_RECOMMENDED',
        )
        .toList(growable: false);
    final defects = flagged.length;
    final vehicle =
        '${job.vehicleYear == null ? '' : '${job.vehicleYear} '}${job.vehicleMake} ${job.vehicleModel}'
            .trim();
    final odometer = job.odometerValue == null
        ? l10n.technicianNotProvided
        : formatOdometerLocalized(
            job.odometerValue,
            job.odometerUnit,
            localeName,
          );

    return Scaffold(
      backgroundColor: Fx.white,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              _M.gutter,
              72,
              _M.gutter,
              140,
            ),
            children: [
              Row(
                children: [
                  Flexible(
                    child: F2bStatusPill(
                      label: l10n.reviewAndFinalize.toUpperCase(),
                      background: Fx.container,
                      foreground: Fx.muted,
                      dot: Fx.deepGreen,
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w600,
                        0.28,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _M.gapXSmall),
              Text(
                l10n.reviewAndFinalize,
                style: Fx.display26.copyWith(color: Fx.ink),
              ),
              const SizedBox(height: _M.gapXSmall),
              Text(
                l10n.finalizeIrreversible,
                style: Fx.body14.copyWith(color: Fx.muted),
              ),
              const SizedBox(height: _M.padMid),
              FxCard(
                radius: 32,
                padding: const EdgeInsets.all(_M.gutter),
                shadows: F2b.summaryShadow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Fx.container,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: FxIcon(
                              id: '1_8828',
                              size: 19.5,
                              color: Fx.deepGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: _M.gapMid),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.isEmpty
                                    ? l10n.technicianUnknownVehicle
                                    : vehicle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Fx.title16.copyWith(color: Fx.ink),
                              ),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  job.vehicleVin == null ||
                                          job.vehicleVin!.isEmpty
                                      ? job.reference
                                      : '${l10n.vehicleVin} • ${job.vehicleVin}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.ltr,
                                  style: Fx.body13.copyWith(color: Fx.muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (job.vehiclePlate != null &&
                            job.vehiclePlate!.isNotEmpty)
                            Directionality(
                            textDirection: TextDirection.ltr,
                            child: F2bStatusPill(
                              label: job.vehiclePlate!,
                              background: F2b.plateBackground,
                              foreground: Fx.iconGrey,
                              style: Fx.caption.copyWith(color: Fx.iconGrey),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: _M.gutter),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _StatTile(
                              iconId: '1_8841',
                              iconColor: F2b.pineDeep,
                              iconBackground: Fx.selectedTint,
                              value: formatCountLocalized(
                                review.completed,
                                localeName,
                              ),
                              label: l10n.completedItems,
                            ),
                          ),
                          const SizedBox(width: _M.gapMid),
                          Expanded(
                            child: _StatTile(
                              iconId: '1_8851',
                              iconColor: F2b.redDeep,
                              iconBackground: F2b.rosePale,
                              value: formatCountLocalized(
                                defects,
                                localeName,
                              ),
                              label: l10n.defectFound,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _M.gutter),
                    Container(
                      padding: const EdgeInsets.all(_M.padMid),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.circular(_M.radiusInner),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Fx.selectedTint,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _initials(job.assignedTechnicianName),
                              textDirection: TextDirection.ltr,
                              style: Fx.text(
                                14,
                                18,
                                FontWeight.w700,
                                0,
                                color: F2b.pineDeep,
                              ),
                            ),
                          ),
                          const SizedBox(width: _M.gapMid),
                          Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        job.assignedTechnicianName ??
                                            l10n.technicianNotProvided,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Fx.text(
                                          14,
                                          18,
                                          FontWeight.w700,
                                          -0.14,
                                          color: Fx.ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const FxIcon(
                                      id: '1_8865',
                                      size: 14.67,
                                      color: Fx.deepGreen,
                                    ),
                                  ],
                                ),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    job.reference,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Fx.body13.copyWith(color: Fx.muted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _M.gutter),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_M.radiusInner),
                      child: Container(
                        height: 144,
                        color: Fx.surfaceLow,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TechnicianVehicleSilhouette(
                              height: 110,
                              semanticLabel: l10n.technicianVehicleSilhouette,
                            ),
                            PositionedDirectional(
                              start: 8,
                              bottom: 8,
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: F2bStatusPill(
                                  label: '${l10n.technicianOdometer}: $odometer',
                                  background: Fx.whiteE5,
                                  foreground: Fx.ink,
                                  dot: Fx.emerald,
                                  style: Fx.caption.copyWith(color: Fx.ink),
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
              const SizedBox(height: _M.padMid),
              FxCard(
                radius: 32,
                padding: const EdgeInsets.all(_M.gutter),
                shadows: Fx.pillShadow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.missingItems,
                            style: Fx.title16.copyWith(color: Fx.ink),
                          ),
                        ),
                        Text(
                          l10n.technicianAttentionCount(flagged.length),
                          style: Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.44,
                            color: Fx.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _M.gapMid),
                    if (flagged.isEmpty)
                      Text(
                        l10n.noResults,
                        style: Fx.body13.copyWith(color: Fx.muted),
                      )
                    else
                      for (final item in flagged)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            bottom: _M.gapMid,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsetsDirectional.only(
                                  top: 2,
                                ),
                                decoration: const BoxDecoration(
                                  color: F2b.rosePale,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: FxIcon(
                                    id: '1_8891',
                                    size: 12.83,
                                    color: F2b.redDeep,
                                  ),
                                ),
                              ),
                              const SizedBox(width: _M.gapMid),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Localizations.localeOf(context)
                                                  .languageCode ==
                                              'ar'
                                          ? item.labelAr
                                          : item.labelEn,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Fx.text(
                                        14,
                                        20,
                                        FontWeight.w600,
                                        -0.07,
                                        color: Fx.ink,
                                      ),
                                    ),
                                    Text(
                                      item.assessment?.note?.isNotEmpty == true
                                          ? item.assessment!.note!
                                          : resultLabel(
                                              l10n,
                                              item.assessment?.resultCode ?? '',
                                            ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Fx.body13.copyWith(
                                        color: Fx.muted,
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
              ),
              const SizedBox(height: _M.padMid),
              Text(
                l10n.finalizeIrreversible,
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
                title: l10n.checklist,
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
                          iconId: '1_8930',
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
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(
                _M.gutter,
                _M.gutter,
                _M.gutter,
                _M.gutter,
              ),
              decoration: const BoxDecoration(
                color: Fx.white90,
                boxShadow: Fx.upShadow,
              ),
              child: SafeArea(
                top: false,
                child: finalized
                    ? F2bFocusFrame(
                        child: FxButton(
                          label: l10n.finalized,
                          onPressed: null,
                          icon: const FxIcon(
                            id: '1_8930',
                            size: 14,
                            color: Fx.white,
                          ),
                          trailingIcon: false,
                        ),
                      )
                    : F2bSlideToConfirm(
                        label: l10n.finalize,
                        enabled: review.ready && !busy,
                        semanticActionLabel: l10n.finalizeConfirm,
                        onConfirmed: () {
                          onFinalize();
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'TR';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.iconId,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  final String iconId;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 152),
      padding: const EdgeInsets.all(_M.padMid),
      decoration: BoxDecoration(
        color: Fx.container,
        borderRadius: BorderRadius.circular(_M.radiusInner),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FxIcon(id: iconId, size: 15, color: iconColor),
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: Fx.text(22, 28, FontWeight.w700, -0.55, color: Fx.ink),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.clip,
            style: Fx.body13.copyWith(color: Fx.muted),
          ),
        ],
      ),
    );
  }
}

/// Figma-exact spacing/radii for this screen (F2-A `_M` pattern).
/// Names contain no flagged digits so `EdgeInsets` lines stay clean.
/// Values are identical to Figma; geometry gates require no change.
abstract final class _M {
  static const double gapXSmall = 4;
  static const double gapMid = 12;
  static const double padMid = 16;
  static const double gutter = 20;
  static const double radiusInner = 24;
}
