import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_choice_group.dart';

/// Step 2: the vehicle. There is deliberately no scheduled-time field here
/// (G-J11): the clean create path cannot reach `SCHEDULED`.
class WizardVehicleStep extends StatelessWidget {
  const WizardVehicleStep({
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    required this.plate,
    required this.odometer,
    required this.odometerUnit,
    required this.transmission,
    required this.fuelType,
    required this.onOdometerUnit,
    required this.onTransmission,
    required this.onFuelType,
    super.key,
  });

  final TextEditingController make;
  final TextEditingController model;
  final TextEditingController year;
  final TextEditingController vin;
  final TextEditingController plate;
  final TextEditingController odometer;
  final String odometerUnit;
  final String transmission;
  final String fuelType;
  final ValueChanged<String> onOdometerUnit;
  final ValueChanged<String> onTransmission;
  final ValueChanged<String> onFuelType;

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopTextField(
          key: const Key('jobs-wizard-vehicle-make'),
          controller: make,
          label: t(WorkshopAdminKeys.vehicleMake),
          hint: t(WorkshopAdminKeys.vehicleMake),
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.directions_car_outlined),
        ),
        SizedBox(height: spacing.md),
        WorkshopTextField(
          key: const Key('jobs-wizard-vehicle-model'),
          controller: model,
          label: t(WorkshopAdminKeys.vehicleModel),
          hint: t(WorkshopAdminKeys.vehicleModel),
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.speed_outlined),
        ),
        SizedBox(height: spacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            final yearField = WorkshopTextField(
              key: const Key('jobs-wizard-vehicle-year'),
              controller: year,
              label: t(WorkshopAdminKeys.vehicleYear),
              hint: t(WorkshopAdminKeys.vehicleYear),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.calendar_today_outlined),
            );
            final odometerField = WorkshopTextField(
              key: const Key('jobs-wizard-odometer'),
              controller: odometer,
              label: t(WorkshopAdminKeys.jobsFieldOdometer),
              hint: t(WorkshopAdminKeys.jobsFieldOdometer),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.straighten_outlined),
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  yearField,
                  SizedBox(height: spacing.md),
                  odometerField,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: yearField),
                SizedBox(width: spacing.md),
                Expanded(child: odometerField),
              ],
            );
          },
        ),
        SizedBox(height: spacing.md),
        WorkshopTextField(
          key: const Key('jobs-wizard-vehicle-vin'),
          controller: vin,
          label: t(WorkshopAdminKeys.vehicleVin),
          hint: t(WorkshopAdminKeys.vehicleVin),
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.pin_outlined),
        ),
        SizedBox(height: spacing.md),
        WorkshopTextField(
          key: const Key('jobs-wizard-vehicle-plate'),
          controller: plate,
          label: t(WorkshopAdminKeys.vehiclePlate),
          hint: t(WorkshopAdminKeys.vehiclePlate),
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(Icons.badge_outlined),
        ),
        SizedBox(height: spacing.lg),
        WizardChoiceGroup(
          label: t(WorkshopAdminKeys.jobsFieldOdometerUnit),
          values: const ['KM', 'MI'],
          selected: odometerUnit,
          onChanged: onOdometerUnit,
          keyPrefix: 'jobs-wizard-odometer-unit',
        ),
        SizedBox(height: spacing.md),
        WizardChoiceGroup(
          label: t(WorkshopAdminKeys.jobsFieldTransmission),
          values: const ['AUTOMATIC', 'MANUAL', 'CVT'],
          selected: transmission,
          onChanged: onTransmission,
          keyPrefix: 'jobs-wizard-transmission',
        ),
        SizedBox(height: spacing.md),
        WizardChoiceGroup(
          label: t(WorkshopAdminKeys.jobsFieldFuelType),
          values: const ['PETROL', 'DIESEL', 'HYBRID', 'ELECTRIC'],
          selected: fuelType,
          onChanged: onFuelType,
          keyPrefix: 'jobs-wizard-fuel',
        ),
      ],
    );
  }
}
