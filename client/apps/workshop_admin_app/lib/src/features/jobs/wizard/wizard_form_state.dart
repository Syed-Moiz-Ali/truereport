import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// Field values for the create wizard, plus the two pure transformations the
/// page needs: per-step validation and the request body.
///
/// Kept out of the composition so the page stays a layout/state shell. The
/// request carries the operator's public-link consent choice and an optional
/// `scheduledAt`: null starts immediately, a value creates a SCHEDULED job.
class WizardFormState {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final customerName = TextEditingController();
  final customerPhone = TextEditingController();
  final customerEmail = TextEditingController();
  final vehicleMake = TextEditingController();
  final vehicleModel = TextEditingController();
  final vehicleYear = TextEditingController();
  final vehicleVin = TextEditingController();
  final vehiclePlate = TextEditingController();
  final odometer = TextEditingController();

  String odometerUnit = 'KM';
  String transmission = 'AUTOMATIC';
  String fuelType = 'PETROL';
  String preferredLanguage = 'en';
  String? templateVersionId;
  String? technicianId;
  bool consentGranted = false;

  /// Null means "start immediately"; a value creates a SCHEDULED job.
  DateTime? scheduledAt;

  void scheduleAt(DateTime value) => scheduledAt = value;

  void startImmediately() => scheduledAt = null;

  String? get scheduledAtIso => scheduledAt == null
      ? null
      : DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(scheduledAt!);

  void dispose() {
    for (final controller in [
      customerName,
      customerPhone,
      customerEmail,
      vehicleMake,
      vehicleModel,
      vehicleYear,
      vehicleVin,
      vehiclePlate,
      odometer,
    ]) {
      controller.dispose();
    }
  }

  /// Null when the step may advance, otherwise the specific copy to show.
  String? validateStep(int step, UiStrings t) {
    if (step == 0) {
      if (customerName.text.trim().isEmpty) {
        return t(WorkshopAdminKeys.requiredField);
      }
      if (customerPhone.text.trim().isEmpty) {
        return t(WorkshopAdminKeys.jobsValidationPhoneRequired);
      }
      final email = customerEmail.text.trim();
      if (email.isNotEmpty && !_emailPattern.hasMatch(email)) {
        return t(WorkshopAdminKeys.jobsValidationEmailInvalid);
      }
    } else if (step == 1) {
      if (vehicleMake.text.trim().isEmpty || vehicleModel.text.trim().isEmpty) {
        return t(WorkshopAdminKeys.requiredField);
      }
      final vin = vehicleVin.text.trim();
      if (vin.isNotEmpty && vin.length != 17) {
        return t(WorkshopAdminKeys.jobsValidationVin);
      }
    } else if (step == 2 && templateVersionId == null) {
      return t(WorkshopAdminKeys.requiredField);
    } else if (step == 3 &&
        scheduledAt != null &&
        scheduledAt!.isBefore(DateTime.now())) {
      return t(WorkshopAdminKeys.jobsScheduleRequired);
    }
    return null;
  }

  NewCleanJob toRequest() => NewCleanJob(
    templateVersionId: templateVersionId!,
    customerName: customerName.text.trim(),
    customerPhone: customerPhone.text.trim(),
    customerEmail: _nullIfEmpty(customerEmail.text),
    vehicleVin: _nullIfEmpty(vehicleVin.text),
    vehicleMake: vehicleMake.text.trim(),
    vehicleModel: vehicleModel.text.trim(),
    vehicleYear: int.tryParse(vehicleYear.text.trim()),
    vehiclePlate: _nullIfEmpty(vehiclePlate.text),
    odometerValue: int.tryParse(odometer.text.trim()),
    odometerUnit: odometerUnit,
    transmission: transmission,
    fuelType: fuelType,
    preferredLanguage: preferredLanguage,
    scheduledAt: scheduledAtIso,
    assignedTechnicianId: technicianId,
    consentGranted: consentGranted,
  );

  static String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
