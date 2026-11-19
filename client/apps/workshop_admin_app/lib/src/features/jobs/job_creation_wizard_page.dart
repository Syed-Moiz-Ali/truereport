import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_customer_step.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_footer.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_form_state.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_layout.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_technician_step.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_template_step.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_vehicle_step.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Four-step clean create: customer, vehicle, template, technician.
///
/// Composition only: each step is a region file, [WizardFormState] owns the
/// fields and the request body, and this page owns the step, busy/error flags
/// and the single `createCleanJob` call. No scheduled-time input exists
/// (G-J11); consent is sent `false` (CR-5).
class JobCreationWizardPage extends ConsumerStatefulWidget {
  const JobCreationWizardPage({super.key});

  @override
  ConsumerState<JobCreationWizardPage> createState() =>
      _JobCreationWizardPageState();
}

class _JobCreationWizardPageState extends ConsumerState<JobCreationWizardPage> {
  final _form = WizardFormState();
  int _step = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.jobsCreateStepCustomer,
      l10n.jobsCreateStepVehicle,
      l10n.jobsCreateStepTemplate,
      l10n.jobsCreateStepTechnician,
    ];
    return Scaffold(
      backgroundColor: context.ws.canvas,
      body: SafeArea(
        child: Column(
          children: [
            JobPageTopBar(title: l10n.jobsCreateTitle),
            Expanded(
              child: WizardLayout(
                current: _step,
                labels: labels,
                error: _error,
                stepBody: _stepBody(),
                footer: WizardFooter(
                  isLast: _step == 3,
                  busy: _busy,
                  canGoBack: _step > 0,
                  onBack: _back,
                  onNext: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return WizardCustomerStep(
          name: _form.customerName,
          phone: _form.customerPhone,
          email: _form.customerEmail,
        );
      case 1:
        return WizardVehicleStep(
          make: _form.vehicleMake,
          model: _form.vehicleModel,
          year: _form.vehicleYear,
          vin: _form.vehicleVin,
          plate: _form.vehiclePlate,
          odometer: _form.odometer,
          odometerUnit: _form.odometerUnit,
          transmission: _form.transmission,
          fuelType: _form.fuelType,
          onOdometerUnit: (value) => setState(() => _form.odometerUnit = value),
          onTransmission: (value) => setState(() => _form.transmission = value),
          onFuelType: (value) => setState(() => _form.fuelType = value),
        );
      case 2:
        return WizardTemplateStep(
          selectedId: _form.templateVersionId,
          onSelected: (value) =>
              setState(() => _form.templateVersionId = value),
        );
      default:
        return WizardTechnicianStep(
          selectedId: _form.technicianId,
          onSelected: (value) => setState(() => _form.technicianId = value),
          preferredLanguage: _form.preferredLanguage,
          onPreferredLanguage: (value) =>
              setState(() => _form.preferredLanguage = value),
        );
    }
  }

  void _back() => setState(() {
    _step -= 1;
    _error = null;
  });

  Future<void> _next() async {
    final error = _form.validateStep(_step, AppLocalizations.of(context));
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_step < 3) {
      setState(() {
        _step += 1;
        _error = null;
      });
      return;
    }
    await _create();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(adminApiProvider)
          .createCleanJob(_form.toRequest());
      ref.invalidate(cleanJobsProvider);
      ref.invalidate(cleanJobCountsProvider);
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = jobErrorCopy(l10n, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
