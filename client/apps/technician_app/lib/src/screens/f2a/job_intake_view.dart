import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2a/assigned_jobs_view.dart';
import 'package:technician_app/src/ui_helpers.dart';

class JobIntakeView extends StatelessWidget {
  const JobIntakeView({
    required this.job,
    required this.onStart,
    required this.onEditCustomer,
    required this.onEditVehicle,
    required this.onConsent,
    required this.onEquipment,
    required this.onProfile,
    this.pendingSyncCount = 0,
    this.online = true,
    this.starting = false,
    this.figmaText = false,
    this.avatarImage,
    this.vehicleImage,
    super.key,
  });

  final TechnicianJob job;
  final VoidCallback onStart;
  final VoidCallback onEditCustomer;
  final VoidCallback onEditVehicle;
  final VoidCallback onConsent;
  final VoidCallback onEquipment;
  final VoidCallback onProfile;
  final int pendingSyncCount;
  final bool online;
  final bool starting;
  final bool figmaText;
  final ui.Image? avatarImage;
  final ui.Image? vehicleImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final finalized = job.status == 'FINALIZED';
    final cancelled = job.status == 'CANCELLED';
    final startable = job.status == 'ASSIGNED' || job.status == 'SCHEDULED';
    final showActions = !finalized && !cancelled;
    final title = figmaText
        ? 'Vehicle Walkaround Inspection'
        : job.templateName.isEmpty
        ? l10n.technicianJobIntake
        : job.templateName;

    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: title,
        showBack: true,
        titleStyle: Fx.text(18, 24, FontWeight.w700, -0.45),
        horizontalPadding: _M.headerPad,
        actions: [
          const SizedBox(width: _M.g4),
          FxProfileButton(
            initials: fxInitials(job.assignedTechnicianName ?? ''),
            iconId: '1_7530',
            onPressed: onProfile,
            semanticLabel:
                job.assignedTechnicianName ?? l10n.technicianProfileTitle,
          ),
        ],
      ),
      bottomNavigationBar: showActions
          ? _StickyAction(
              label: figmaText
                  ? 'Start Inspection'
                  : startable
                  ? l10n.startInspection
                  : l10n.resumeInspection,
              onPressed: onStart,
              loading: starting,
            )
          : null,
      body: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          context.spacing.gutter,
          0,
          context.spacing.gutter,
          context.spacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.metaBlock),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: _M.metaTop,
                  bottom: _M.metaBottom,
                ),
                child: Wrap(
                  spacing: _M.g8,
                  runSpacing: _M.g2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaPill(
                      label: figmaText
                          ? 'INTAKE PHASE'
                          : technicianStatusLabel(
                              l10n,
                              job.status,
                            ).toUpperCase(),
                      background: Fx.container,
                      width: figmaText ? _M.phaseWidth : null,
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w600,
                        0.275,
                        color: Fx.muted,
                      ),
                    ),
                    _MetaPill(
                      label: figmaText
                          ? 'Ready for Check'
                          : technicianStatusLabel(l10n, job.status),
                      background: Fx.mint33,
                      leading: const FxDot(size: 6),
                      style: Fx.text(
                        11,
                        14,
                        FontWeight.w600,
                        0.44,
                        color: Fx.darkInk,
                      ),
                    ),
                    Text(
                      figmaText
                          ? '10:42 AM · Bay 3'
                          : scheduledTimeUtc4(job.scheduledAt),
                      textDirection: TextDirection.ltr,
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
            ),
            SizedBox(
              height: _M.heroBlock,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: _M.heroBottom,
                ),
                child: _VehicleHero(
                  job: job,
                  figmaText: figmaText,
                  image: vehicleImage,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.vehicleBlock),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: _M.sectionBottom,
                ),
                child: _VehicleCard(job: job, figmaText: figmaText),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _M.customerBlock),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: _M.sectionBottom,
                ),
                child: _CustomerCard(job: job, figmaText: figmaText),
              ),
            ),
            _ReadyCard(job: job, figmaText: figmaText),
            if (showActions) ...[
              const SizedBox(height: _M.g16),
              _Actions(
                onConsent: onConsent,
                onEquipment: onEquipment,
                onEditCustomer: onEditCustomer,
                onEditVehicle: onEditVehicle,
              ),
            ],
            if (finalized) ...[
              const SizedBox(height: _M.g16),
              FxPill(
                label: l10n.finalizedReadOnly,
                background: Fx.container,
                foreground: Fx.deepGreen,
                style: Fx.caption.copyWith(color: Fx.deepGreen),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleHero extends StatelessWidget {
  const _VehicleHero({
    required this.job,
    required this.figmaText,
    this.image,
  });

  final TechnicianJob job;
  final bool figmaText;
  final ui.Image? image;

  @override
  Widget build(BuildContext context) {
    final plate = figmaText
        ? 'REG: LV71 XZP'
        : job.vehiclePlate == null || job.vehiclePlate!.isEmpty
        ? job.reference
        : job.vehiclePlate!;
    final model = figmaText
        ? 'Renault Megane 3'
        : '${job.vehicleMake} ${job.vehicleModel}'.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(_M.heroRadius),
      child: Container(
        height: _M.heroHeight,
        decoration: const BoxDecoration(
          gradient: Fx.heroGradient,
          boxShadow: Fx.cardShadow,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Positioned.fill(
                child: RawImage(image: image, fit: BoxFit.cover),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: _M.g20,
                    start: _M.g20,
                    end: _M.g20,
                  ),
                  child: TechnicianVehicleSilhouette(
                    height: _M.silhouetteHeight,
                    semanticLabel:
                        AppLocalizations.of(
                          context,
                        ).technicianVehicleSilhouette,
                  ),
                ),
              ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _M.heroOverlay,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: Fx.heroOverlayGradient),
              ),
            ),
            Positioned(
              left: _M.g16,
              right: _M.g16,
              bottom: _M.g16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: _M.plateHeight,
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Fx.whiteE5,
                            borderRadius: BorderRadius.circular(_M.pill),
                          ),
                          child: Text(
                            plate,
                            textDirection: TextDirection.ltr,
                            style: Fx.text(
                              11,
                              14,
                              FontWeight.w600,
                              0.44,
                              color: Fx.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: _M.g4),
                        Text(
                          model.isEmpty
                              ? AppLocalizations.of(
                                  context,
                                ).technicianUnknownVehicle
                              : model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Fx.title16.copyWith(color: Fx.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _M.g8),
                  Container(
                    width: _M.heroButton,
                    height: _M.heroButton,
                    decoration: const BoxDecoration(
                      color: Fx.whiteE5,
                      shape: BoxShape.circle,
                      boxShadow: Fx.pillShadow,
                    ),
                    child: const Center(
                      child: FxIcon(id: '1_7513', size: 15, color: Fx.ink),
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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.job, required this.figmaText});

  final TechnicianJob job;
  final bool figmaText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final make = figmaText ? 'Renault' : job.vehicleMake;
    final model = figmaText ? 'Megane 3' : job.vehicleModel;
    final year = figmaText ? '2021' : job.vehicleYear?.toString() ?? '';
    final odometer = figmaText
        ? '34,180 mi'
        : formatOdometer(job.odometerValue, job.odometerUnit);
    final vin = figmaText ? 'VF1KZ040647192831' : job.vehicleVin ?? '';
    return FxCard(
      radius: _M.sectionRadius,
      padding: EdgeInsets.all(context.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _M.sectionHeader,
            child: Row(
              children: [
                const FxIconTile(
                  iconId: '1_7415',
                  size: _M.sectionIcon,
                  iconSize: _M.sectionIconGlyph,
                  color: Fx.emerald,
                ),
                const SizedBox(width: _M.g12),
                Expanded(
                  child: Text(
                    l10n.technicianVehicleInfo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.heading18.copyWith(color: Fx.inkStrong),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.technicianCopyVin,
                  child: InkResponse(
                    onTap: vin.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(ClipboardData(text: vin));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.technicianVinCopied),
                                ),
                              );
                            }
                          },
                    radius: _M.copyHit / 2,
                    child: Container(
                      width: _M.copyButton,
                      height: _M.copyButton,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Fx.container,
                        shape: BoxShape.circle,
                      ),
                      child: const FxIcon(
                        id: '1_7450',
                        size: 15,
                        color: Fx.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _M.sectionGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledValue(
                  label: l10n.technicianMake,
                  value: make,
                  emphasized: true,
                ),
              ),
              const SizedBox(width: _M.gridGap),
              Expanded(
                child: _LabeledValue(
                  label: l10n.technicianModel,
                  value: model,
                  emphasized: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: _M.gridGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledValue(
                  label: l10n.technicianYear,
                  value: year,
                  emphasized: true,
                ),
              ),
              const SizedBox(width: _M.gridGap),
              Expanded(
                child: _LabeledValue(
                  label: l10n.technicianOdometer,
                  value: odometer,
                  emphasized: true,
                  ltr: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: _M.sectionGap),
          Container(
            constraints: const BoxConstraints(minHeight: _M.vinHeight),
            padding: const EdgeInsetsDirectional.fromSTEB(
              _M.g14,
              _M.g16,
              _M.g14,
              _M.g14,
            ),
            decoration: BoxDecoration(
              color: Fx.container,
              borderRadius: BorderRadius.circular(_M.r8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.technicianVinChassis,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Fx.caption.copyWith(
                          color: Fx.muted,
                          letterSpacing: 0.44,
                        ),
                      ),
                      const SizedBox(height: _M.g2),
                      Text(
                        vin,
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Fx.text(
                          13,
                          18,
                          FontWeight.w600,
                          0.65,
                          color: Fx.inkStrong,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: _M.copyButton,
                  height: _M.copyButton,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Fx.white,
                    shape: BoxShape.circle,
                    boxShadow: Fx.pillShadow,
                  ),
                  child: const FxIcon(
                    id: '1_7450',
                    size: 15,
                    color: Fx.muted,
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.job, required this.figmaText});

  final TechnicianJob job;
  final bool figmaText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = figmaText ? 'Arthur Pendelton' : job.customerName;
    final phone = figmaText ? '+44 7700 900077' : job.customerPhone ?? '';
    final service = figmaText
        ? 'Comprehensive Fleet Tier-1 Multi-Point'
        : job.templateName;
    return FxCard(
      radius: _M.sectionRadius,
      padding: EdgeInsets.all(context.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _M.sectionHeader,
            child: Row(
              children: [
                const FxIconTile(
                  iconId: '1_7457',
                  size: _M.sectionIcon,
                  iconSize: _M.sectionIconGlyph,
                  color: Fx.emerald,
                ),
                const SizedBox(width: _M.g12),
                Expanded(
                  child: Text(
                    l10n.technicianCustomerInfo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.heading18.copyWith(color: Fx.inkStrong),
                  ),
                ),
                FxPill(
                  label: figmaText ? 'Primary Owner' : l10n.technicianCustomerChip,
                  height: _M.ownerHeight,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  style: Fx.caption.copyWith(
                    color: Fx.muted,
                    letterSpacing: 0.44,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _M.sectionGap),
          _LabeledValue(
            label: l10n.customerName,
            value: name.isEmpty ? l10n.technicianNotProvided : name,
            emphasized: true,
          ),
          const SizedBox(height: _M.g14),
          Row(
            children: [
              Expanded(
                child: _LabeledValue(
                  label: l10n.technicianPhone,
                  value: phone.isEmpty ? l10n.technicianNotProvided : phone,
                  emphasized: true,
                  ltr: true,
                ),
              ),
              const SizedBox(width: _M.g8),
              _ContactButton(iconId: '1_7477', label: l10n.technicianCall),
              const SizedBox(width: _M.g8),
              _ContactButton(iconId: '1_7480', label: l10n.technicianMessage),
            ],
          ),
          const SizedBox(height: _M.g14),
          _LabeledValue(
            label: l10n.technicianServicePackage,
            value: service.isEmpty ? l10n.technicianNotProvided : service,
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({required this.iconId, required this.label});

  final String iconId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        width: _M.contactButton,
        height: _M.contactButton,
        decoration: const BoxDecoration(
          color: Fx.container,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FxIcon(id: iconId, size: 15.83, color: Fx.inkStrong),
        ),
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.job, required this.figmaText});

  final TechnicianJob job;
  final bool figmaText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = figmaText
        ? 'Pre-Inspection Ready'
        : l10n.technicianJobDetailsReady;
    final subtitle = figmaText
        ? 'Keys received · Fuel at 70%'
        : [
            technicianStatusLabel(l10n, job.status),
            if (job.templateVersionNo != null)
              '${l10n.versions} ${job.templateVersionNo}',
          ].join(' · ');
    final right = figmaText
        ? 'Step 1 of 4'
        : job.templateVersionNo == null
        ? l10n.technicianInspection
        : '${l10n.versions} ${job.templateVersionNo}';
    return FxCard(
      radius: _M.sectionRadius,
      padding: EdgeInsets.all(context.spacing.gutter),
      child: Row(
        children: [
          Container(
            width: _M.readyIcon,
            height: _M.readyIcon,
            decoration: const BoxDecoration(
              color: Fx.tintMint,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: FxIcon(id: '1_7493', size: 15, color: Fx.emerald),
            ),
          ),
          const SizedBox(width: _M.g12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.label14.copyWith(color: Fx.inkStrong),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fx.body13.copyWith(color: Fx.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: _M.g8),
          Flexible(
            child: Text(
              right,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Fx.label12.copyWith(color: Fx.emerald),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onConsent,
    required this.onEquipment,
    required this.onEditCustomer,
    required this.onEditVehicle,
  });

  final VoidCallback onConsent;
  final VoidCallback onEquipment;
  final VoidCallback onEditCustomer;
  final VoidCallback onEditVehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: _M.g8,
      runSpacing: _M.g8,
      children: [
        FxButton(
          label: l10n.customerInformation,
          onPressed: onEditCustomer,
          tone: FxButtonTone.tonal,
          height: _M.actionHeight,
          expand: false,
          trailingIcon: false,
        ),
        FxButton(
          label: l10n.vehicleIdentification,
          onPressed: onEditVehicle,
          tone: FxButtonTone.tonal,
          height: _M.actionHeight,
          expand: false,
          trailingIcon: false,
        ),
        FxButton(
          label: l10n.consent,
          onPressed: onConsent,
          tone: FxButtonTone.tonal,
          height: _M.actionHeight,
          expand: false,
          trailingIcon: false,
        ),
        FxButton(
          label: l10n.equipment,
          onPressed: onEquipment,
          tone: FxButtonTone.text,
          height: _M.actionHeight,
          expand: false,
          trailingIcon: false,
        ),
      ],
    );
  }
}

class _StickyAction extends StatelessWidget {
  const _StickyAction({
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Fx.whiteE5,
        boxShadow: Fx.upShadow,
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        context.spacing.gutter,
        context.spacing.md,
        context.spacing.gutter,
        context.spacing.md,
      ),
      child: SafeArea(
        top: false,
        child: FxButton(
          label: label,
          onPressed: loading ? null : onPressed,
          icon: const FxIcon(id: '1_7519', size: 13.33, color: Fx.white),
          trailingIcon: true,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.background,
    required this.style,
    this.width,
    this.leading,
  });

  final String label;
  final Color background;
  final TextStyle style;
  final double? width;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: width == null ? null : BoxConstraints(minWidth: width!),
      height: _M.metaPillHeight,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(_M.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: _M.g6)],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ],
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.ltr = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Fx.caption.copyWith(color: Fx.muted, letterSpacing: 0.44),
        ),
        const SizedBox(height: _M.g4),
        Text(
          value,
          textDirection: ltr ? TextDirection.ltr : null,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: emphasized
              ? Fx.title16.copyWith(color: Fx.inkStrong)
              : Fx.body14.copyWith(color: Fx.ink),
        ),
      ],
    );
  }
}

abstract final class _M {
  static const double headerPad = 16;
  static const double pill = 999;
  static const double g2 = 2;
  static const double g4 = 4;
  static const double g6 = 6;
  static const double g8 = 8;
  static const double g12 = 12;
  static const double g14 = 14;
  static const double g16 = 16;
  static const double g20 = 20;
  static const double r8 = 8;
  static const double metaBlock = 54;
  static const double metaTop = 8;
  static const double metaBottom = 24;
  static const double metaPillHeight = 22;
  static const double phaseWidth = 103.67;
  static const double heroBlock = 200;
  static const double heroBottom = 24;
  static const double heroHeight = 176;
  static const double heroRadius = 32;
  static const double heroOverlay = 100;
  static const double silhouetteHeight = 90;
  static const double plateHeight = 18;
  static const double heroButton = 36;
  static const double vehicleBlock = 310;
  static const double sectionBottom = 20;
  static const double sectionRadius = 32;
  static const double sectionHeader = 40;
  static const double sectionIcon = 40;
  static const double sectionIconGlyph = 18.33;
  static const double sectionGap = 20;
  static const double gridGap = 16;
  static const double vinHeight = 66;
  static const double copyButton = 36;
  static const double copyHit = 44;
  static const double customerBlock = 296;
  static const double ownerHeight = 22;
  static const double contactButton = 40;
  static const double readyIcon = 32;
  static const double actionHeight = 44;
}
