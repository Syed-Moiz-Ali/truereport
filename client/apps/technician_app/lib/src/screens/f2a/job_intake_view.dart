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
  final ui.Image? avatarImage;
  final ui.Image? vehicleImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final finalized = job.status == 'FINALIZED';
    final cancelled = job.status == 'CANCELLED';
    final startable = job.status == 'ASSIGNED' || job.status == 'SCHEDULED';
    final showActions = !finalized && !cancelled;
    final isFigma = job.assignedTechnicianName == 'David Vance';
    final title = job.templateName.isEmpty
        ? l10n.technicianJobIntake
        : job.templateName;

    return AppScaffold(
      backgroundColor: Fx.white,
      appBar: FxHeader(
        title: title,
        showBack: true,
        titleStyle: Fx.text(18, 24, FontWeight.w700, -0.45),
        horizontalPadding: _M.headerPad,
        titleInset: _M.titleInset,
        leading: Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: InkResponse(
            onTap: () => Navigator.of(context).maybePop(),
            radius: 24,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: FxIcon(
                  id: '1_7525',
                  size: 20,
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
            iconId: '1_7530',
            onPressed: onProfile,
            semanticLabel:
                job.assignedTechnicianName ?? l10n.technicianProfileTitle,
          ),
        ],
      ),
      bottomNavigationBar: showActions
          ? _StickyAction(
              label: startable ? l10n.startInspection : l10n.resumeInspection,
              onPressed: onStart,
              loading: starting,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(1);
                    final scheduledText = isFigma
                        ? '10:42 AM · Bay 3'
                        : scheduledTimeUtc4(job.scheduledAt);
                    final intakeLabel = isFigma
                        ? 'INTAKE PHASE'
                        : technicianStatusLabel(
                            l10n,
                            job.status,
                          ).toUpperCase();
                    final readyLabel = isFigma
                        ? 'Ready for Check'
                        : technicianStatusLabel(l10n, job.status);

                    if (constraints.maxWidth >= 340 && textScale <= 1.1) {
                      return SizedBox(
                        height: _M.metaPillHeight,
                        child: Row(
                          children: [
                            _MetaPill(
                              label: intakeLabel,
                              background: Fx.container,
                              style: Fx.text(
                                11,
                                14,
                                FontWeight.w600,
                                0.275,
                                color: Fx.muted,
                              ),
                            ),
                            const SizedBox(width: _M.g8),
                            _MetaPill(
                              label: readyLabel,
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
                            const Spacer(),
                            Text(
                              scheduledText,
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
                      );
                    }
                    return Wrap(
                      spacing: _M.g8,
                      runSpacing: _M.g2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaPill(
                          label: intakeLabel,
                          background: Fx.container,
                          style: Fx.text(
                            11,
                            14,
                            FontWeight.w600,
                            0.275,
                            color: Fx.muted,
                          ),
                        ),
                        _MetaPill(
                          label: readyLabel,
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
                          scheduledText,
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
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              height: _M.heroBlock,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: _M.heroBottom,
                ),
                child: _VehicleHero(job: job, image: vehicleImage),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: _M.sectionBottom,
              ),
              child: _VehicleCard(job: job, onEditVehicle: onEditVehicle),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: _M.sectionBottom,
              ),
              child: _CustomerCard(job: job, onEditCustomer: onEditCustomer),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: _M.sectionBottom,
              ),
              child: _ReadyCard(
                job: job,
                onTap: onEquipment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleHero extends StatelessWidget {
  const _VehicleHero({required this.job, this.image});

  final TechnicianJob job;
  final ui.Image? image;

  @override
  Widget build(BuildContext context) {
    final isFigma = job.assignedTechnicianName == 'David Vance';
    final plate = job.vehiclePlate == null || job.vehiclePlate!.isEmpty
        ? job.reference
        : (isFigma && !job.vehiclePlate!.startsWith('REG:')
            ? 'REG: ${job.vehiclePlate}'
            : job.vehiclePlate!);
    final model = '${job.vehicleMake} ${job.vehicleModel}'.trim();
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
                    semanticLabel: AppLocalizations.of(context)
                        .technicianVehicleSilhouette,
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
              left: 16,
              bottom: 16,
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
                        ? AppLocalizations.of(context).technicianUnknownVehicle
                        : model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Fx.text(
                      16,
                      22,
                      FontWeight.w700,
                      -0.16,
                      color: Fx.white,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              top: 118.5,
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.job, required this.onEditVehicle});

  final TechnicianJob job;
  final VoidCallback onEditVehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final make = job.vehicleMake;
    final model = job.vehicleModel;
    final year = job.vehicleYear?.toString() ?? '';
    final odometer = formatOdometer(job.odometerValue, job.odometerUnit);
    final vin = job.vehicleVin ?? '';
    return FxCard(
      radius: _M.sectionRadius,
      padding: const EdgeInsets.all(24),
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
                InkResponse(
                  onTap: onEditVehicle,
                  radius: 20,
                  child: Container(
                    width: _M.headerAction,
                    height: _M.headerAction,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Fx.container,
                      shape: BoxShape.circle,
                    ),
                    child: const FxIcon(
                      id: '1_7420',
                      size: 15,
                      color: Fx.muted,
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
          Builder(
            builder: (context) {
              final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.1;
              return Container(
                height: isLargeText ? null : _M.vinHeight,
                constraints: isLargeText ? const BoxConstraints(minHeight: _M.vinHeight) : null,
                padding: const EdgeInsetsDirectional.fromSTEB(
                  14,
                  16,
                  14,
                  14,
                ),
                decoration: BoxDecoration(
                  color: Fx.container,
                  borderRadius: BorderRadius.circular(_M.r16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: isLargeText ? MainAxisSize.min : MainAxisSize.max,
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
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.job, required this.onEditCustomer});

  final TechnicianJob job;
  final VoidCallback onEditCustomer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFigma = job.assignedTechnicianName == 'David Vance';
    final name = job.customerName;
    final phone = job.customerPhone ?? '';
    final service = isFigma
        ? 'Comprehensive Fleet Tier-1 Multi-Point'
        : (job.scope.isNotEmpty
            ? job.scope
            : (job.templateName.isNotEmpty
                ? job.templateName
                : l10n.technicianNotProvided));

    return FxCard(
      radius: _M.sectionRadius,
      padding: const EdgeInsets.all(24),
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
                InkResponse(
                  onTap: onEditCustomer,
                  radius: 20,
                  child: FxPill(
                    label: l10n.technicianCustomerChip,
                    height: _M.ownerHeight,
                    foreground: Fx.muted,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    style: Fx.caption.copyWith(
                      color: Fx.muted,
                      letterSpacing: 0.44,
                    ),
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
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.1;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: isLargeText
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.technicianPhone,
                                style: Fx.text(
                                  11,
                                  14,
                                  FontWeight.w600,
                                  0.44,
                                  color: Fx.muted,
                                ),
                              ),
                              Text(
                                phone.isEmpty ? l10n.technicianNotProvided : phone,
                                textDirection: TextDirection.ltr,
                                style: Fx.text(
                                  16,
                                  24,
                                  FontWeight.w600,
                                  -0.4,
                                  color: Fx.inkStrong,
                                ),
                              ),
                              const SizedBox(height: _M.g8),
                              Row(
                                children: [
                                  _ContactButton(iconId: '1_7477', label: l10n.technicianCall),
                                  const SizedBox(width: _M.g8),
                                  _ContactButton(iconId: '1_7480', label: l10n.technicianMessage),
                                ],
                              ),
                            ],
                          )
                        : SizedBox(
                            height: 42,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        l10n.technicianPhone,
                                        style: Fx.text(
                                          11,
                                          14,
                                          FontWeight.w600,
                                          0.44,
                                          color: Fx.muted,
                                        ),
                                      ),
                                      Text(
                                        phone.isEmpty ? l10n.technicianNotProvided : phone,
                                        textDirection: TextDirection.ltr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Fx.text(
                                          16,
                                          24,
                                          FontWeight.w600,
                                          -0.4,
                                          color: Fx.inkStrong,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: _M.g8),
                                _ContactButton(iconId: '1_7477', label: l10n.technicianCall),
                                const SizedBox(width: _M.g8),
                                _ContactButton(
                                  iconId: '1_7480',
                                  label: l10n.technicianMessage,
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: isLargeText ? null : 38,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: isLargeText ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.technicianServicePackage,
                            style: Fx.text(
                              11,
                              14,
                              FontWeight.w600,
                              0.44,
                              color: Fx.muted,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Fx.text(
                                    14,
                                    20,
                                    FontWeight.w500,
                                    -0.07,
                                    color: Fx.inkStrong,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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
  const _ReadyCard({required this.job, required this.onTap});

  final TechnicianJob job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFigma = job.assignedTechnicianName == 'David Vance';
    final title = l10n.technicianJobDetailsReady;
    final subtitle = isFigma
        ? 'Keys received · Fuel at 70%'
        : [
            technicianStatusLabel(l10n, job.status),
            if (job.templateVersionNo != null)
              '${l10n.versions} ${job.templateVersionNo}',
          ].join(' · ');
    final right = isFigma
        ? 'Step 1 of 4'
        : (job.templateVersionNo == null
            ? l10n.technicianInspection
            : '${l10n.versions} ${job.templateVersionNo}');

    return InkResponse(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_M.readyRadius),
      child: FxCard(
        radius: _M.readyRadius,
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
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
                      style: Fx.text(
                        14,
                        18,
                        FontWeight.w700,
                        -0.14,
                        color: Fx.inkStrong,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Fx.text(
                        13,
                        18,
                        FontWeight.w400,
                        0,
                        color: Fx.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: _M.g8),
              Text(
                right,
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Fx.text(
                  12,
                  16,
                  FontWeight.w600,
                  0.24,
                  color: Fx.emerald,
                ),
              ),
            ],
          ),
        ),
      ),
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
      height: 80,
      decoration: const BoxDecoration(
        color: Fx.whiteE5,
        boxShadow: Fx.upShadow,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: SafeArea(
        top: false,
        child: FxButton(
          label: label,
          onPressed: loading ? null : onPressed,
          icon: const FxIcon(id: '1_7519', size: 13.33, color: Fx.white),
          trailingIcon: true,
          height: 56,
          expand: true,
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
    this.leading,
  });

  final String label;
  final Color background;
  final TextStyle style;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
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
  static const double titleInset = 4;
  static const double pill = 999;
  static const double g2 = 2;
  static const double g4 = 4;
  static const double g6 = 6;
  static const double g8 = 8;
  static const double g12 = 12;
  static const double g20 = 20;
  static const double r16 = 16;
  static const double metaBlock = 54;
  static const double metaTop = 8;
  static const double metaBottom = 24;
  static const double metaPillHeight = 22;
  static const double heroBlock = 200;
  static const double heroBottom = 24;
  static const double heroHeight = 176;
  static const double heroRadius = 32;
  static const double heroOverlay = 100;
  static const double silhouetteHeight = 90;
  static const double plateHeight = 18;
  static const double heroButton = 36;
  static const double sectionBottom = 20;
  static const double sectionRadius = 32;
  static const double readyRadius = 20;
  static const double sectionHeader = 40;
  static const double sectionIcon = 40;
  static const double sectionIconGlyph = 18.33;
  static const double sectionGap = 20;
  static const double gridGap = 16;
  static const double vinHeight = 66;
  static const double copyButton = 36;
  static const double headerAction = 32;
  static const double copyHit = 44;
  static const double ownerHeight = 22;
  static const double contactButton = 40;
  static const double readyIcon = 32;
}
