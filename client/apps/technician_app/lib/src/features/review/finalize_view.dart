import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/shared/technician_intl.dart';
import 'package:technician_app/src/shared/technician_kit.dart';
import 'package:technician_app/src/ui_helpers.dart';

/// Figma screen 14: Finalize & Approval (Swipe).
///
/// Implements exact 390x1231.25 Figma specifications (node 1:8809):
/// - Fixed header (0, 0, 390, 64) with back button, title, and profile button
/// - Intro container (0, 64, 390, 126) with step pill, display title, and subtitle
/// - Summary card (20, 206, 350, 558) with vehicle header, photo block, stat tiles, and technician info
/// - Flagged items card (20, 780, 350, 198) with items summary and required follow-up badge
/// - Legal disclaimer block (28, 997.25, 334, 106)
/// - Slide to finalize dock (0, 1126.63, 390, 104) with animated/draggable slide-to-confirm
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
    this.vehicleImage,
    this.avatarImage,
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
  final ui.Image? vehicleImage;
  final ui.Image? avatarImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 1200;
          final content = SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 64),
                const _Intro(),
                _SummaryMargin(
                  job: job,
                  review: review,
                  vehicle: vehicle,
                  odometer: odometer,
                  defects: defects,
                  avatar: avatarImage,
                  vehicleImage: vehicleImage,
                ),
                _FlaggedMargin(
                  flagged: flagged,
                  isAr: isAr,
                ),
                const _DisclaimerMargin(),
                const SizedBox(height: 128),
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
                start: 0,
                end: 0,
                top: isCompact ? null : 1126.63,
                bottom: isCompact ? 0 : null,
                height: 104,
                child: _Dock(
                  enabled: review.ready && !busy,
                  finalized: finalized,
                  onFinalize: onFinalize,
                ),
              ),
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                height: 64,
                child: _Header(
                  onBack: onBack,
                  onProfile: onProfile,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 390,
      height: 126,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1:8813 step pill 180.38x22 r9999 #F4F3F8 pad 4,12,4,12 gap 6.
            Container(
              width: 180.38,
              height: 22,
              padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
              decoration: const BoxDecoration(
                color: Fx.container,
                borderRadius: BorderRadius.all(Radius.circular(9999)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 12.5,
                    height: 12.5,
                    child: Center(
                      child: FxIcon(
                        id: '1_8815',
                        size: 12.5,
                        color: Fx.deepGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6, height: 14),
                  SizedBox(
                    width: 137.88,
                    height: 14,
                    child: Text(
                      l10n.reviewAndFinalize.toUpperCase(),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.275,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 350, height: 4),
            // 1:8818 heading 350x36 pad top 4; 1:8819 text 350x32.
            SizedBox(
              width: 350,
              height: 36,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: SizedBox(
                  width: 350,
                  height: 32,
                  child: Text(
                    l10n.reviewAndFinalize,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
                      fontSize: 26,
                      height: 32 / 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.65,
                      color: Fx.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 350, height: 4),
            // 1:8820 body 350x40; 1:8821 text 14/500 lh 20 ls -0.07.
            SizedBox(
              width: 350,
              height: 40,
              child: Text(
                l10n.finalizeIrreversible,
                maxLines: 2,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  fontFamily: Fx.fontFamily,
                  fontFamilyFallback: Fx.fontFallback,
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.07,
                  color: Fx.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMargin extends StatelessWidget {
  const _SummaryMargin({
    required this.job,
    required this.review,
    required this.vehicle,
    required this.odometer,
    required this.defects,
    this.avatar,
    this.vehicleImage,
  });

  final TechnicianJob job;
  final ReviewResult review;
  final String vehicle;
  final String odometer;
  final int defects;
  final ui.Image? avatar;
  final ui.Image? vehicleImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: 574,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
        child: _SummaryCard(
          job: job,
          review: review,
          vehicle: vehicle,
          odometer: odometer,
          defects: defects,
          avatar: avatar,
          vehicleImage: vehicleImage,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.job,
    required this.review,
    required this.vehicle,
    required this.odometer,
    required this.defects,
    this.avatar,
    this.vehicleImage,
  });

  final TechnicianJob job;
  final ReviewResult review;
  final String vehicle;
  final String odometer;
  final int defects;
  final ui.Image? avatar;
  final ui.Image? vehicleImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('summary'),
      width: 350,
      height: 558,
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            spreadRadius: -6,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 25,
            spreadRadius: -5,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VehicleHeader(
              job: job,
              vehicle: vehicle,
            ),
            const SizedBox(width: 302, height: 20),
            _PhotoBlock(
              odometer: odometer,
              image: vehicleImage,
            ),
            const SizedBox(width: 302, height: 24),
            _StatsRow(
              completed: review.completed,
              defects: defects,
            ),
            const SizedBox(width: 302, height: 24),
            _TechnicianRow(
              job: job,
              avatar: avatar,
            ),
            const SizedBox(width: 302, height: 24),
          ],
        ),
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  const _VehicleHeader({
    required this.job,
    required this.vehicle,
  });

  final TechnicianJob job;
  final String vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayVehicle =
        vehicle.isEmpty ? l10n.technicianUnknownVehicle : vehicle;
    final displayVin = job.vehicleVin == null || job.vehicleVin!.isEmpty
        ? job.reference
        : '${l10n.vehicleVin} \u2022 ${job.vehicleVin}';
    final chipLabel = job.vehiclePlate != null && job.vehiclePlate!.isNotEmpty
        ? job.vehiclePlate!
        : (job.reference.isNotEmpty ? job.reference : l10n.jobsTab);

    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Fx.container,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 19.5,
                    height: 17.33,
                    child: Center(
                      child: FxIcon(
                        id: '1_8828',
                        size: 19.5,
                        color: Fx.deepGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12, height: 48),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 22,
                        child: Text(
                          displayVehicle,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            fontFamily: Fx.fontFamily,
                            fontFamilyFallback: Fx.fontFallback,
                            fontSize: 16,
                            height: 22 / 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.16,
                            color: Fx.ink,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 18,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            displayVin,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(
                              fontFamily: Fx.fontFamily,
                              fontFamilyFallback: Fx.fontFallback,
                              fontSize: 13,
                              height: 18 / 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                              color: Fx.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 3.62, height: 48),
          Container(
            width: 73.83,
            height: 22,
            padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
            decoration: const BoxDecoration(
              color: F2b.plateBackground,
              borderRadius: BorderRadius.all(Radius.circular(9999)),
            ),
            child: SizedBox(
              width: 49.83,
              height: 14,
              child: Text(
                chipLabel,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  fontFamily: Fx.fontFamily,
                  fontFamilyFallback: Fx.fontFallback,
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.44,
                  color: Fx.iconGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoBlock extends StatelessWidget {
  const _PhotoBlock({
    required this.odometer,
    this.image,
  });

  final String odometer;
  final ui.Image? image;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final odometerLabel = '${l10n.technicianOdometer}: $odometer';

    return SizedBox(
      width: 302,
      height: 144,
      child: Stack(
        children: [
          if (image != null)
            RawImage(image: image, scale: 2)
          else
            Container(
              width: 302,
              height: 144,
              color: Fx.surfaceLow,
              alignment: Alignment.center,
              child: TechnicianVehicleSilhouette(
                height: 110,
                semanticLabel: l10n.technicianVehicleSilhouette,
              ),
            ),
          PositionedDirectional(
            start: 8,
            top: 114,
            child: Container(
              width: 155.39,
              height: 22,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(9999)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(9999)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: Fx.whiteE5,
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 8,
                          height: 14,
                          child: Center(
                            child: SizedBox(
                              width: 8,
                              height: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Fx.emerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6, height: 14),
                        SizedBox(
                          width: 121.39,
                          height: 14,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              odometerLabel,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                fontFamily: Fx.fontFamily,
                                fontFamilyFallback: Fx.fontFallback,
                                fontSize: 11,
                                height: 14 / 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.44,
                                color: Fx.ink,
                              ),
                            ),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.completed,
    required this.defects,
  });

  final int completed;
  final int defects;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countLeft = '$completed';
    final countRight = '$defects';

    return SizedBox(
      height: 152,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _StatTile(
              iconId: '1_8841',
              iconSize: 15,
              iconBoxWidth: 15,
              iconBoxHeight: 15,
              iconBackground: Fx.selectedTint,
              iconColor: F2b.pineDeep,
              count: countLeft,
              countWidth: 37.19,
              lines: [l10n.completedItems],
              lineWidths: const [47.14, 71.44],
            ),
          ),
          const SizedBox(width: 12, height: 152),
          Expanded(
            child: _StatTile(
              iconId: '1_8851',
              iconSize: 12.75,
              iconBoxWidth: 11.25,
              iconBoxHeight: 12.75,
              iconBackground: F2b.rosePale,
              iconColor: F2b.redDeep,
              count: countRight,
              countWidth: 113,
              tileGap: 24,
              countBottomPad: 4,
              lines: [l10n.defectFound],
              lineWidths: const [91.41],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.iconId,
    required this.iconSize,
    required this.iconBoxWidth,
    required this.iconBoxHeight,
    required this.iconBackground,
    required this.iconColor,
    required this.count,
    required this.countWidth,
    required this.lines,
    required this.lineWidths,
    this.tileGap = 0,
    this.countBottomPad = 0,
  });

  final String iconId;
  final double iconSize;
  final double iconBoxWidth;
  final double iconBoxHeight;
  final Color iconBackground;
  final Color iconColor;
  final String count;
  final double countWidth;
  final List<String> lines;
  final List<double> lineWidths;
  final double tileGap;
  final double countBottomPad;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      SizedBox(
        width: 113,
        height: 44,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: iconBoxWidth,
                height: iconBoxHeight,
                child: Center(
                  child: FxIcon(id: iconId, size: iconSize, color: iconColor),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
    if (tileGap > 0) {
      children.add(SizedBox(width: 113, height: tileGap));
    }
    children.add(
      SizedBox(
        width: 113,
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
            letterSpacing: -0.55,
            color: Fx.ink,
          ),
        ),
      ),
    );
    for (var i = 0; i < lines.length; i++) {
      children.add(SizedBox(width: 113, height: i == 0 ? 2 : 6));
      children.add(
        SizedBox(
          width: i < lineWidths.length ? lineWidths[i] : 113,
          height: 18,
          child: Text(
            lines[i],
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              fontFamily: Fx.fontFamily,
              fontFamilyFallback: Fx.fontFallback,
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              color: Fx.muted,
            ),
          ),
        ),
      );
    }
    children.add(
      SizedBox(
        width: 113,
        height: countBottomPad == 0 ? 4 : countBottomPad,
      ),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 152),
      color: Fx.container,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TechnicianRow extends StatelessWidget {
  const _TechnicianRow({
    required this.job,
    this.avatar,
  });

  final TechnicianJob job;
  final ui.Image? avatar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final techName = job.assignedTechnicianName ?? l10n.roleTechnician;
    final role1 = l10n.technicianHomeTitle;
    final role2 = job.reference;

    return Container(
      constraints: const BoxConstraints(minHeight: 98),
      color: Fx.container,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 66,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 34.94,
                    height: 40,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(9999),
                      ),
                      child: Center(
                        child: avatar != null
                            ? RawImage(image: avatar, scale: 2)
                            : Container(
                                decoration: const BoxDecoration(
                                  color: Fx.selectedTint,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _initials(techName),
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 12, height: 66),
                  Expanded(
                    child: SizedBox(
                      height: 66,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 18,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    techName,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                    style: const TextStyle(
                                      fontFamily: Fx.fontFamily,
                                      fontFamilyFallback: Fx.fontFallback,
                                      fontSize: 14,
                                      height: 18 / 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.14,
                                      color: Fx.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6, height: 18),
                                const SizedBox(
                                  width: 14.67,
                                  height: 14,
                                  child: Center(
                                    child: FxIcon(
                                      id: '1_8865',
                                      size: 14.67,
                                      color: Fx.deepGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 18,
                            child: Text(
                              role1,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                fontFamily: Fx.fontFamily,
                                fontFamilyFallback: Fx.fontFallback,
                                fontSize: 13,
                                height: 18 / 13,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                                color: Fx.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 18,
                            child: Text(
                              role2,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                fontFamily: Fx.fontFamily,
                                fontFamilyFallback: Fx.fontFallback,
                                fontSize: 13,
                                height: 18 / 13,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                                color: Fx.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 51.09,
            height: 62,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 51.09,
                  height: 14,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      'Today',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.44,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 51.09, height: 3.5),
                SizedBox(
                  width: 51.09,
                  height: 16,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      '14:48',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.24,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 51.09, height: 8),
                SizedBox(
                  width: 51.09,
                  height: 16,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      'PST',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.24,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 51.09, height: 4.5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlaggedMargin extends StatelessWidget {
  const _FlaggedMargin({
    required this.flagged,
    required this.isAr,
  });

  final List<InspectionItem> flagged;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 214),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
        child: _FlaggedCard(
          flagged: flagged,
          isAr: isAr,
        ),
      ),
    );
  }
}

class _FlaggedCard extends StatelessWidget {
  const _FlaggedCard({
    required this.flagged,
    required this.isAr,
  });

  final List<InspectionItem> flagged;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.missingItems;
    final badge = l10n.technicianAttentionCount(flagged.length);

    return Container(
      width: 350,
      constraints: const BoxConstraints(minHeight: 198),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Fx.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.16,
                      color: Fx.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
                      fontSize: 11,
                      height: 14 / 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.44,
                      color: Fx.dangerRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 310, height: 12),
          if (flagged.isEmpty) ...[
            Text(
              l10n.noResults,
              style: Fx.body13.copyWith(color: Fx.muted),
            ),
          ] else ...[
            for (var i = 0; i < flagged.length; i++) ...[
              if (i > 0) const SizedBox(width: 310, height: 12),
              _FlagRow(
                iconId: '1_8891',
                title: isAr ? flagged[i].labelAr : flagged[i].labelEn,
                body: flagged[i].assessment?.note?.isNotEmpty == true
                    ? flagged[i].assessment!.note!
                    : resultLabel(
                        l10n,
                        flagged[i].assessment?.resultCode ?? '',
                      ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({
    required this.iconId,
    required this.title,
    required this.body,
  });

  final String iconId;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 26,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: F2b.rosePale,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 12.83,
                    height: 11.08,
                    child: Center(
                      child: FxIcon(
                        id: iconId,
                        size: 12.83,
                        color: F2b.redDeep,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12, height: 56),
          Expanded(
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.07,
                        color: Fx.ink,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: Text(
                      body,
                      maxLines: 2,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        fontFamily: Fx.fontFamily,
                        fontFamilyFallback: Fx.fontFallback,
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                        color: Fx.muted,
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

class _DisclaimerMargin extends StatelessWidget {
  const _DisclaimerMargin();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final disclaimer = l10n.finalizeIrreversible;

    return SizedBox(
      width: 390,
      height: 125.25,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 19.25, 28, 0),
        child: SizedBox(
          width: 334,
          height: 106,
          child: Text(
            disclaimer,
            maxLines: 5,
            softWrap: false,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: Fx.fontFamily,
              fontFamilyFallback: Fx.fontFallback,
              fontSize: 13,
              height: 21.13 / 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              color: Fx.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.enabled,
    required this.finalized,
    required this.onFinalize,
  });

  final bool enabled;
  final bool finalized;
  final Future<void> Function() onFinalize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.finalize;

    return Container(
      width: 390,
      height: 104,
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 50,
            spreadRadius: -12,
            offset: Offset(0, 25),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                : Container(
                    key: const ValueKey('slide'),
                    child: F2bSlideToConfirm(
                      label: label,
                      enabled: enabled,
                      semanticActionLabel: l10n.finalizeConfirm,
                      onConfirmed: () {
                        onFinalize();
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveSlide extends StatefulWidget {
  const _InteractiveSlide({
    required this.label,
    required this.enabled,
    required this.onConfirmed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onConfirmed;

  @override
  State<_InteractiveSlide> createState() => _InteractiveSlideState();
}

class _InteractiveSlideState extends State<_InteractiveSlide> {
  double _progress = 0;
  bool _busy = false;

  void _complete() {
    if (!widget.enabled || _busy) return;
    setState(() {
      _progress = 1;
      _busy = true;
    });
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 64,
      decoration: const BoxDecoration(
        color: Fx.surfaceHighest,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = math.max(0.0, constraints.maxWidth - 52 - 12);
          final rtl = Directionality.of(context) == TextDirection.rtl;

          return Stack(
            children: [
              PositionedDirectional(
                start: 100.32,
                top: 23,
                child: SizedBox(
                  width: 189.36,
                  height: 18,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(
                      fontFamily: Fx.fontFamily,
                      fontFamilyFallback: Fx.fontFallback,
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
                      color: Fx.muted,
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: 6 + travel * _progress,
                top: 6,
                child: Semantics(
                  button: true,
                  enabled: widget.enabled,
                  label: widget.label,
                  onTap: widget.enabled ? _complete : null,
                  child: GestureDetector(
                    onHorizontalDragUpdate: widget.enabled
                        ? (details) {
                            setState(() {
                              final delta = rtl
                                  ? -details.primaryDelta!
                                  : details.primaryDelta!;
                              _progress =
                                  (_progress + (delta / math.max(1, travel)))
                                      .clamp(0.0, 1.0);
                            });
                          }
                        : null,
                    onHorizontalDragEnd: widget.enabled
                        ? (_) {
                            if (_progress >= 0.92) {
                              _complete();
                            } else {
                              setState(() => _progress = 0);
                            }
                          }
                        : null,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Fx.emerald,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 6,
                            spreadRadius: -4,
                            offset: Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 15,
                            spreadRadius: -3,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 16.33,
                        height: 14,
                        child: Center(
                          child: FxIcon(
                            id: '1_8919',
                            size: 16.33,
                            color: Fx.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    this.onBack,
    this.onProfile,
  });

  final VoidCallback? onBack;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('header'),
      width: 390,
      height: 64,
      decoration: const BoxDecoration(
        color: Fx.whiteCC,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Semantics(
                        button: true,
                        label: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        child: InkResponse(
                          onTap: onBack,
                          radius: 24,
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: SizedBox(
                                width: 11.77,
                                height: 20,
                                child: Center(
                                  child: FxIcon(
                                    id: '1_8925',
                                    size: 20,
                                    color: Fx.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4, height: 44),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            AppLocalizations.of(context).reviewAndFinalize,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: Fx.fontFamily,
                              fontFamilyFallback: Fx.fontFallback,
                              fontSize: 18,
                              height: 24 / 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.45,
                              color: Fx.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: F2bFocusFrame(
                    borderRadius: BorderRadius.circular(Fx.pillRadius),
                    child: InkResponse(
                      onTap: onProfile,
                      radius: 16,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Fx.deepGreen,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const FxIcon(
                          id: '1_8930',
                          size: 12,
                          color: Fx.white,
                        ),
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
