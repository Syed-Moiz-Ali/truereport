import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_customer_step.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_form_state.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_technician_step.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_template_step.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_vehicle_step.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Create a job in four steps: Customer → Vehicle → Template → Technician.
///
/// Same fields, validation and request body as before ([WizardFormState] owns
/// them, the four step regions render them, `createCleanJob` is the only call).
/// The chrome is new: a pill stepper, one step per screen, and a pill footer.
class DispatchCreateJob extends ConsumerStatefulWidget {
  const DispatchCreateJob({super.key});

  @override
  ConsumerState<DispatchCreateJob> createState() => _DispatchCreateJobState();
}

class _DispatchCreateJobState extends ConsumerState<DispatchCreateJob> {
  static const _steps = 4;

  final _form = WizardFormState();
  int _step = 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The report language defaults to the workshop's current UI language.
    final active = ref
        .read(languageSelectionProvider(adminUiMessageClient))
        .activeLanguage;
    if (active.isNotEmpty) {
      _form.preferredLanguage = active;
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  List<String> _labels(UiStrings t) => [
    t(WorkshopAdminKeys.jobsCreateStepCustomer),
    t(WorkshopAdminKeys.jobsCreateStepVehicle),
    t(WorkshopAdminKeys.jobsCreateStepTemplate),
    t(WorkshopAdminKeys.jobsCreateStepTechnician),
  ];

  /// Validates every step up to [target] so a jump cannot skip a required field.
  bool _validateUpTo(int target, UiStrings t) {
    for (var step = 0; step < target; step++) {
      final error = _form.validateStep(step, t);
      if (error != null) {
        setState(() {
          _step = step;
          _error = error;
        });
        return false;
      }
    }
    return true;
  }

  void _back() {
    setState(() {
      _step = (_step - 1).clamp(0, _steps - 1);
      _error = null;
    });
  }

  Future<void> _next() async {
    final t = UiStrings.of(context);
    if (!_validateUpTo(_step + 1, t)) {
      return;
    }
    if (_step < _steps - 1) {
      setState(() {
        _step += 1;
        _error = null;
      });
      return;
    }
    await _create(t);
  }

  void _jump(int step) {
    final t = UiStrings.of(context);
    if (step <= _step) {
      setState(() {
        _step = step;
        _error = null;
      });
      return;
    }
    if (!_validateUpTo(step, t)) {
      return;
    }
    setState(() {
      _step = step;
      _error = null;
    });
  }

  Future<void> _create(UiStrings t) async {
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
        setState(() => _error = jobErrorCopy(t, error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final labels = _labels(t);

    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: ws.topBarHeight,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ws.pageGutter(width),
              ),
              decoration: BoxDecoration(
                color: ws.surface,
                border: BorderDirectional(bottom: BorderSide(color: ws.border)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                  child: Row(
                    children: [
                      WorkshopIconButton(
                        icon: Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        semanticLabel: t(WorkshopAdminKeys.commonBack),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t(WorkshopAdminKeys.jobsCreateTitle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ws.bodyStrong.copyWith(color: ws.ink),
                        ),
                      ),
                      Text(
                        '${_step + 1}/$_steps',
                        style: ws.meta.copyWith(
                          color: ws.muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _stepper(context, labels),
            Expanded(
              child: SingleChildScrollView(
                padding: ws.pagePadding(width),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 18),
                        Text(
                          labels[_step],
                          style: ws.pageTitle.copyWith(
                            fontSize: width < 520 ? 26 : 30,
                            letterSpacing: -0.6,
                            color: ws.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t(WorkshopAdminKeys.scheduleJobSubtitle),
                          style: ws.meta.copyWith(color: ws.muted),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: ws.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: ws.border),
                          ),
                          child: _body(),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_error != null) _errorBanner(context),
            _footer(context, t),
          ],
        ),
      ),
    );
  }

  Widget _body() {
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
          scheduledAt: _form.scheduledAt,
          onPickSchedule: _pickSchedule,
          onStartImmediately: () => setState(_form.startImmediately),
          consentGranted: _form.consentGranted,
          onConsentChanged: (value) =>
              setState(() => _form.consentGranted = value),
        );
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initial = _form.scheduledAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(
      () => _form.scheduleAt(
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      ),
    );
  }

  Widget _stepper(BuildContext context, List<String> labels) {
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      color: ws.surface,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(width),
        vertical: 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  _stepPill(context, i, labels[i]),
                  if (i < labels.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepPill(BuildContext context, int index, String label) {
    final ws = context.ws;
    final active = _step == index;
    final done = index < _step;
    final bg = active
        ? ws.ink
        : done
        ? ws.accentSoft
        : ws.canvas;
    final fg = active
        ? ws.canvas
        : done
        ? ws.accent
        : ws.muted;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: () => _jump(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 32,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? ws.ink : ws.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: ws.meta.copyWith(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: ws.meta.copyWith(color: fg, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(BuildContext context) {
    final ws = context.ws;
    return Container(
      width: double.infinity,
      color: ws.dangerSoft,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high_rounded, size: 16, color: ws.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!, style: ws.meta.copyWith(color: ws.danger)),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, UiStrings t) {
    final ws = context.ws;
    final width = MediaQuery.sizeOf(context).width;
    final last = _step == _steps - 1;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        border: BorderDirectional(top: BorderSide(color: ws.border)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ws.pageGutter(width),
        vertical: 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Row(
            children: [
              if (_step == 0)
                JobPillButton(
                  label: t(WorkshopAdminKeys.cancel),
                  variant: JobPillVariant.ghost,
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).maybePop(),
                )
              else
                JobPillButton(
                  label: t(WorkshopAdminKeys.commonBack),
                  icon: Icons.arrow_back,
                  variant: JobPillVariant.ghost,
                  onPressed: _busy ? null : _back,
                ),
              const Spacer(),
              JobPillButton(
                label: last
                    ? t(WorkshopAdminKeys.create)
                    : t(WorkshopAdminKeys.commonNext),
                icon: last ? Icons.check : null,
                loading: _busy,
                onPressed: _busy ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
