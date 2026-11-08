import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

enum VehiclePerspective {
  front,
  driver,
  passenger,
  rear,
}

/// Screen 08. 360 Exterior Wireframe.
class ExteriorWireframeView extends StatelessWidget {
  const ExteriorWireframeView({
    this.title,
    this.stepTitle,
    this.stepSubtitle,
    this.detectedCount = 1,
    this.selectedPerspective = VehiclePerspective.driver,
    this.onSelectPerspective,
    this.onReset360,
    this.onEditDamage,
    this.onConfirm,
    this.onNoDamage,
    this.onBack,
    this.onProfile,
    this.avatarImage,
    this.isFigma = false,
    super.key,
  });

  final String? title;
  final String? stepTitle;
  final String? stepSubtitle;
  final int detectedCount;
  final VehiclePerspective selectedPerspective;
  final ValueChanged<VehiclePerspective>? onSelectPerspective;
  final VoidCallback? onReset360;
  final VoidCallback? onEditDamage;
  final VoidCallback? onConfirm;
  final VoidCallback? onNoDamage;
  final VoidCallback? onBack;
  final VoidCallback? onProfile;
  final ui.Image? avatarImage;
  final bool isFigma;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: title ??
            (isFigma
                ? 'Vehicle Walkaround Inspection'
                : l10n.technicianWalkaroundInspection),
        showBack: true,
        titleStyle: Fx.text(18, 24, FontWeight.w700, -0.45, color: Fx.ink),
        horizontalPadding: _M.headerPad,
        titleInset: 4,
        leading: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: InkResponse(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            radius: 24,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: FxIcon(
                  id: '1_8015',
                  width: 11.8,
                  height: 20.0,
                  color: Fx.ink,
                ),
              ),
            ),
          ),
        ),
        actions: [
          const SizedBox(width: _M.g4),
          FxProfileButton(
            initials: '',
            iconId: '1_8020',
            size: 32,
            image: avatarImage,
            onPressed: onProfile,
            semanticLabel: l10n.technicianProfileTitle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          _M.gutter,
          0,
          _M.gutter,
          _M.bodyBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header Context (1:7899: [20, 64, 350, 158])
            Padding(
              padding: const EdgeInsetsDirectional.only(
                top: _M.statusTop,
                bottom: _M.statusBottom,
              ),
              child: SizedBox(
                height: _M.statusRowHeight,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        isFigma
                            ? 'EXTERIOR INSPECTION'
                            : l10n.technicianExteriorInspection,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Fx.text(
                          11,
                          14,
                          FontWeight.w600,
                          0.55,
                          color: Fx.outline,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: _M.statusPillHeight,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        10,
                        4,
                        12,
                        4,
                      ),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.circular(_M.pill),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FxDot(size: 8, color: Fx.emerald),
                          const SizedBox(width: 6),
                          Text(
                            isFigma
                                ? '1 Detected'
                                : l10n.technicianDetectedCount(detectedCount),
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
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.headingHeight),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: _M.headingBottom,
                ),
                child: Text(
                  stepTitle ??
                      (isFigma
                          ? 'Step 2: Tap the area to\ncapture damage'
                          : l10n.technicianExteriorStep2),
                  style: Fx.text(
                    26,
                    32,
                    FontWeight.w800,
                    -0.65,
                    color: Fx.inkStrong,
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.subtitleHeight),
              child: Text(
                stepSubtitle ??
                    (isFigma
                        ? 'Pin scratches, dents, or paint chips directly on the\nwireframe schematic.'
                        : l10n.technicianExteriorHint),
                style: Fx.text(
                  13,
                  18,
                  FontWeight.w400,
                  0,
                  color: Fx.muted,
                ),
              ),
            ),

            // Interactive 360 Wireframe Canvas Card (1:7951: [20, 222, 350, 379.75])
            Padding(
              padding: const EdgeInsetsDirectional.only(top: _M.canvasTop),
              child: FxCard(
                radius: _M.cardRadius,
                padding: const EdgeInsets.all(_M.canvasPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge & Reset Row: [40, 242, 310, 32]
                    SizedBox(
                      height: _M.badgeRowHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: _M.badgeHeight,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              12,
                              4,
                              12,
                              4,
                            ),
                            decoration: BoxDecoration(
                              color: Fx.container,
                              borderRadius: BorderRadius.circular(_M.pill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FxIcon(
                                  id: '1_7956',
                                  width: 12,
                                  height: 10.7,
                                  color: Fx.ink,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isFigma
                                      ? 'DRIVER SIDE VIEW'
                                      : l10n.technicianDriverSideView,
                                  style: Fx.text(
                                    11,
                                    14,
                                    FontWeight.w700,
                                    0.275,
                                    color: Fx.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Semantics(
                            button: true,
                            label: l10n.technicianTapToRotate,
                            child: InkResponse(
                              onTap: onReset360,
                              radius: 16,
                              child: Container(
                                width: _M.resetBtnSize,
                                height: _M.resetBtnSize,
                                decoration: const BoxDecoration(
                                  color: Fx.container,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: FxIcon(
                                    id: '1_7961',
                                    width: 13.5,
                                    height: 13.5,
                                    color: Fx.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _M.schematicTop),

                    // Car Schematic with Overlay Hotspot Pins: [40, 286, 310, 193.8]
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: _M.schematicWidth,
                        height: _M.schematicHeight,
                        child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Base car line-art
                          const Positioned(
                            left: 0,
                            top: 8,
                            width: 310,
                            height: 177.8,
                            child: FxIcon(
                              id: '1_7977',
                              width: 310,
                              height: 177.8,
                            ),
                          ),
                          // Pin Front Fender (1:7996: [91.1, 380.5, 28, 28])
                          const Positioned(
                            left: 51.1,
                            top: 94.5,
                            child: _WireframePin(),
                          ),
                          // Pin Windshield Edge (1:7998: [131.4, 343.7, 28, 28])
                          const Positioned(
                            left: 91.4,
                            top: 57.7,
                            child: _WireframePin(),
                          ),
                          // Selected Damage: Driver Door (1:8000: [168.9, 378.5, 33.6, 32.0])
                          Positioned(
                            left: 121.7,
                            top: 84.5,
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Color(0x4010B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0x4D10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 33.6,
                                  height: 33.6,
                                  decoration: const BoxDecoration(
                                    color: Fx.emerald,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x7310B981),
                                        offset: Offset(0, 8),
                                        blurRadius: 24,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: FxIcon(
                                      id: '1_8005',
                                      width: 12.53,
                                      height: 9.55,
                                      color: Fx.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Pin Roof Edge (1:8006: [205.8, 322.4, 28, 28])
                          const Positioned(
                            left: 165.8,
                            top: 36.4,
                            child: _WireframePin(),
                          ),
                          // Pin Rear Quarter (1:8008: [261.6, 376.6, 28, 28])
                          const Positioned(
                            left: 221.6,
                            top: 90.6,
                            child: _WireframePin(),
                          ),
                        ],
                      ),
                    ),
                  ),
                    const SizedBox(height: _M.calloutTop),

                    // Active Damage Callout Card (1:7963: [40, 495.75, 310, 86])
                    Container(
                      height: _M.calloutHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: _M.calloutPadH,
                      ),
                      decoration: BoxDecoration(
                        color: Fx.container,
                        borderRadius: BorderRadius.circular(_M.calloutRadius),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: _M.calloutIconWidth,
                            height: _M.calloutIconHeight,
                            decoration: const BoxDecoration(
                              color: Color(0x2610B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: FxIcon(
                                id: '1_7967',
                                width: 16.7,
                                height: 15.0,
                                color: Fx.emerald,
                              ),
                            ),
                          ),
                          const SizedBox(width: _M.calloutIconGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: _M.calloutTitleHeight,
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      isFigma
                                          ? 'Front Left Door Dent'
                                          : 'Front Left Door Dent',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Fx.text(
                                        16,
                                        22,
                                        FontWeight.w700,
                                        -0.16,
                                        color: Fx.inkStrong,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: _M.calloutSubtitleHeight,
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      isFigma
                                          ? '2.5 cm Crease • Photo\nAttached'
                                          : '2.5 cm Crease • Photo\nAttached',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Fx.text(
                                        13,
                                        18,
                                        FontWeight.w400,
                                        0,
                                        color: Fx.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: _M.calloutIconGap),
                          Semantics(
                            button: true,
                            label: l10n.edit,
                            child: InkResponse(
                              onTap: onEditDamage,
                              radius: 20,
                              child: Container(
                                width: _M.editBtnWidth,
                                height: _M.editBtnHeight,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Fx.white,
                                  borderRadius: BorderRadius.circular(_M.pill),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x05000000),
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  l10n.edit,
                                  style: Fx.text(
                                    11,
                                    14,
                                    FontWeight.w600,
                                    0.44,
                                    color: Fx.ink,
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
              ),
            ),

            // Perspective Navigation Grid (1:7911: [20, 601.75, 350, 143.83])
            Padding(
              padding: const EdgeInsetsDirectional.only(top: _M.gridTop),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: _M.gridLabelRowHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            isFigma
                                ? 'ANGLE PERSPECTIVE'
                                : l10n.technicianAnglePerspective,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Fx.text(
                              12,
                              16,
                              FontWeight.w600,
                              0.24,
                              color: Fx.muted,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isFigma
                              ? 'Tap to rotate 360°'
                              : l10n.technicianTapToRotate,
                          style: Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.44,
                            color: Fx.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _M.gridButtonsTop),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 350,
                      child: Row(
                        children: [
                          _PerspectiveButton(
                            label: isFigma
                                ? 'Front'
                                : l10n.technicianPerspectiveFront,
                            iconId: '1_7922',
                            isActive: selectedPerspective == VehiclePerspective.front,
                            onTap: () => onSelectPerspective?.call(VehiclePerspective.front),
                            width: _M.perspectiveBtnWidth,
                            height: _M.perspectiveBtnHeight,
                          ),
                          const SizedBox(width: _M.perspectiveBtnGap),
                          _PerspectiveButton(
                            label: isFigma
                                ? 'Driver'
                                : l10n.technicianPerspectiveDriver,
                            iconId: '1_7928',
                            isActive: selectedPerspective == VehiclePerspective.driver,
                            onTap: () => onSelectPerspective?.call(VehiclePerspective.driver),
                            width: _M.perspectiveBtnWidth,
                            height: _M.perspectiveBtnHeight,
                          ),
                          const SizedBox(width: _M.perspectiveBtnGap),
                          _PerspectiveButton(
                            label: isFigma
                                ? 'Passenger'
                                : l10n.technicianPerspectivePassenger,
                            iconId: '1_7934',
                            isActive: selectedPerspective == VehiclePerspective.passenger,
                            onTap: () => onSelectPerspective?.call(VehiclePerspective.passenger),
                            width: _M.perspectiveBtnWidth,
                            height: _M.perspectiveBtnHeight,
                          ),
                          const SizedBox(width: _M.perspectiveBtnGap),
                          _PerspectiveButton(
                            label: isFigma
                                ? 'Rear'
                                : l10n.technicianPerspectiveRear,
                            iconId: '1_7940',
                            isActive: selectedPerspective == VehiclePerspective.rear,
                            onTap: () => onSelectPerspective?.call(VehiclePerspective.rear),
                            width: _M.perspectiveBtnRearWidth,
                            height: _M.perspectiveBtnHeight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Primary Floating Action Controls (1:7943: [20, 754.33, 350, 112])
            Padding(
              padding: const EdgeInsetsDirectional.only(top: _M.ctaGroupTop),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxButton(
                    label: isFigma
                        ? 'Confirm Exterior Markup'
                        : l10n.technicianConfirmExteriorMarkup,
                    onPressed: onConfirm ?? () {},
                    icon: const FxIcon(
                      id: '1_7948',
                      width: 13.33,
                      height: 13.33,
                      color: Fx.white,
                    ),
                    trailingIcon: true,
                  ),
                  const SizedBox(height: _M.secondaryBtnTop),
                  Semantics(
                    button: true,
                    label: l10n.technicianNoDamageOnPanel,
                    child: InkWell(
                      onTap: onNoDamage,
                      borderRadius: BorderRadius.circular(_M.pill),
                      child: SizedBox(
                        height: _M.secondaryBtnHeight,
                        child: Center(
                          child: Text(
                            isFigma
                                ? 'No Damage Found on this Panel'
                                : l10n.technicianNoDamageOnPanel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Fx.text(
                              12,
                              16,
                              FontWeight.w600,
                              0.24,
                              color: Fx.muted,
                            ),
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
      ),
    );
  }
}

class _WireframePin extends StatelessWidget {
  const _WireframePin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Fx.white,
        shape: BoxShape.circle,
        border: Border.all(color: Fx.emerald, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4010B981),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: const Center(
        child: FxDot(size: 8, color: Fx.emerald),
      ),
    );
  }
}

class _PerspectiveButton extends StatelessWidget {
  const _PerspectiveButton({
    required this.label,
    required this.iconId,
    required this.isActive,
    required this.onTap,
    required this.width,
    required this.height,
  });

  final String label;
  final String iconId;
  final bool isActive;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isActive ? Fx.emerald : Fx.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive ? _M.activeShadow : _M.inactiveShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FxIcon(
                id: iconId,
                width: 17.33,
                height: 17.33,
                color: isActive ? Fx.white : Fx.inkStrong,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Fx.text(
                  12,
                  16,
                  isActive ? FontWeight.w700 : FontWeight.w600,
                  -0.3,
                  color: isActive ? Fx.white : Fx.inkStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _M {
  static const double gutter = 20;
  static const double headerPad = 16;
  static const double bodyBottom = 40;
  static const double pill = 9999;
  static const double cardRadius = 32;
  static const double g4 = 4;

  // Status row
  static const double statusRowHeight = 22;
  static const double statusTop = 8;
  static const double statusBottom = 4;
  static const double statusPillHeight = 22;

  // Heading
  static const double headingHeight = 64;
  static const double headingBottom = 4;

  // Subtitle
  static const double subtitleHeight = 36;

  // Canvas card (1:7951: [20, 222, 350, 379.75])
  static const double canvasTop = 20;
  static const double canvasPad = 20;
  static const double badgeRowHeight = 32;
  static const double badgeHeight = 22;
  static const double resetBtnSize = 32;
  static const double schematicTop = 12;
  static const double schematicWidth = 310;
  static const double schematicHeight = 193.75;
  static const double calloutTop = 16;
  static const double calloutHeight = 86;
  static const double calloutPadH = 14;
  static const double calloutRadius = 16;
  static const double calloutIconWidth = 34.55;
  static const double calloutIconHeight = 36;
  static const double calloutIconGap = 12;
  static const double calloutTitleHeight = 22;
  static const double calloutSubtitleHeight = 36;
  static const double editBtnWidth = 46.91;
  static const double editBtnHeight = 26;

  // Perspective grid (1:7911: [20, 601.75, 350, 143.83])
  static const double gridTop = 24;
  static const double gridLabelRowHeight = 16;
  static const double gridButtonsTop = 10;
  static const double perspectiveBtnGap = 12;
  static const double perspectiveBtnWidth = 78.5;
  static const double perspectiveBtnRearWidth = 77.36;
  static const double perspectiveBtnHeight = 69.83;

  // CTA group (1:7943: [20, 754.25, 350, 112])
  static const double ctaGroupTop = 40.67;
  static const double secondaryBtnTop = 12;
  static const double secondaryBtnHeight = 36;

  static const inactiveShadow = <BoxShadow>[
    BoxShadow(color: Color(0x05000000), offset: Offset(0, 2), blurRadius: 6),
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 10), blurRadius: 28),
  ];

  static const activeShadow = <BoxShadow>[
    BoxShadow(color: Color(0x5910B981), offset: Offset(0, 12), blurRadius: 28),
  ];
}
