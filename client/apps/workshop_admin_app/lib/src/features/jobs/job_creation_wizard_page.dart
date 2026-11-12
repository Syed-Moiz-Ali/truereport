import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Four-step job creation wizard: customer, vehicle, template, technician.
class JobCreationWizardPage extends ConsumerStatefulWidget {
  const JobCreationWizardPage({super.key});

  @override
  ConsumerState<JobCreationWizardPage> createState() =>
      _JobCreationWizardPageState();
}

class _JobCreationWizardPageState extends ConsumerState<JobCreationWizardPage> {
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _customerEmail = TextEditingController();
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleYear = TextEditingController();
  final _vehicleVin = TextEditingController();
  final _vehiclePlate = TextEditingController();
  final _odometer = TextEditingController();
  String _odometerUnit = 'KM';
  String _transmission = 'AUTOMATIC';
  String _fuelType = 'PETROL';
  String _preferredLanguage = 'en';
  String? _templateVersionId;
  String? _technicianId;
  int _step = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _customerEmail.dispose();
    _vehicleMake.dispose();
    _vehicleModel.dispose();
    _vehicleYear.dispose();
    _vehicleVin.dispose();
    _vehiclePlate.dispose();
    _odometer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.jobsCreateTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(
                      title: l10n.jobsCreateTitle,
                      subtitle: l10n.scheduleJobSubtitle,
                    ),
                    Wrap(
                      spacing: context.spacing.sm,
                      runSpacing: context.spacing.sm,
                      children: [
                        _stepChip(l10n.jobsCreateStepCustomer, 0),
                        _stepChip(l10n.jobsCreateStepVehicle, 1),
                        _stepChip(l10n.jobsCreateStepTemplate, 2),
                        _stepChip(l10n.jobsCreateStepTechnician, 3),
                      ],
                    ),
                    SizedBox(height: context.spacing.lg),
                    if (_error != null) ...[
                      JobInlineError(message: _error!),
                      SizedBox(height: context.spacing.md),
                    ],
                    _stepBody(context),
                    SizedBox(height: context.spacing.lg),
                    _footer(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _stepChip(String label, int step) {
    final active = _step == step;
    return StatusChip(
      label:
          '${formatNumber(context, step + 1)}. $label',
      tone: active ? StatusTone.info : StatusTone.neutral,
      icon: active ? Icons.radio_button_checked : Icons.circle_outlined,
    );
  }

  Widget _stepBody(BuildContext context) {
    switch (_step) {
      case 0:
        return _customerStep(context);
      case 1:
        return _vehicleStep(context);
      case 2:
        return _templateStep(context);
      default:
        return _technicianStep(context);
    }
  }

  Widget _customerStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return JobPanel(
      title: l10n.jobsCreateStepCustomer,
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: const Key('jobs-wizard-customer-name'),
            controller: _customerName,
            label: l10n.customerName,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            key: const Key('jobs-wizard-customer-phone'),
            controller: _customerPhone,
            label: l10n.customerPhone,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: _customerEmail,
            label: l10n.customerEmail,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ],
      ),
    );
  }

  Widget _vehicleStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return JobPanel(
      title: l10n.jobsCreateStepVehicle,
      icon: Icons.directions_car_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: const Key('jobs-wizard-vehicle-make'),
            controller: _vehicleMake,
            label: l10n.vehicleMake,
            prefixIcon: const Icon(Icons.directions_car_outlined),
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: _vehicleModel,
            label: l10n.vehicleModel,
            prefixIcon: const Icon(Icons.speed_outlined),
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: _vehicleYear,
            label: l10n.vehicleYear,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: _vehicleVin,
            label: l10n.vehicleVin,
            prefixIcon: const Icon(Icons.pin_outlined),
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: _vehiclePlate,
            label: l10n.vehiclePlate,
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: _odometer,
            label: l10n.jobsFieldOdometer,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.straighten_outlined),
          ),
          SizedBox(height: context.spacing.sm),
          _dropdown(
            context,
            label: l10n.jobsFieldOdometerUnit,
            value: _odometerUnit,
            values: const ['KM', 'MI'],
            onChanged: (value) => setState(() => _odometerUnit = value),
          ),
          SizedBox(height: context.spacing.sm),
          _dropdown(
            context,
            label: l10n.jobsFieldTransmission,
            value: _transmission,
            values: const ['AUTOMATIC', 'MANUAL', 'CVT'],
            onChanged: (value) => setState(() => _transmission = value),
          ),
          SizedBox(height: context.spacing.sm),
          _dropdown(
            context,
            label: l10n.jobsFieldFuelType,
            value: _fuelType,
            values: const ['PETROL', 'DIESEL', 'HYBRID', 'ELECTRIC'],
            onChanged: (value) => setState(() => _fuelType = value),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in values)
          DropdownMenuItem(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }

  Widget _templateStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(availableTemplatesProvider);
    return JobPanel(
      title: l10n.jobsTemplatesAvailable,
      icon: Icons.dashboard_customize_outlined,
      child: templates.when(
        loading: () => const LoadingSkeleton(lines: 3),
        error: (error, _) => ErrorState(
          title: l10n.error,
          body: l10n.commonLoadFailed,
          retryLabel: l10n.retryAction,
          onRetry: () => ref.invalidate(availableTemplatesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: l10n.jobsTemplatesEmpty,
              body: '',
              icon: Icons.dashboard_customize_outlined,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final template in items) ...[
                WorkshopOptionCard<String>(
                  key: Key('jobs-template-${template.versionId}'),
                  value: template.versionId,
                  groupValue: _templateVersionId ?? '',
                  onChanged: (value) =>
                      setState(() => _templateVersionId = value),
                  title:
                      '${localizedText(context, en: template.nameEn, ar: template.nameAr)}'
                      ' · v${formatNumber(context, template.versionNo)}',
                  caption: l10n.technicianItemsCount(template.itemCount),
                ),
                SizedBox(height: context.spacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _technicianStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final staff = ref.watch(staffProvider);
    return JobPanel(
      title: l10n.jobsCreateStepTechnician,
      icon: Icons.groups_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          staff.when(
            loading: () => const LoadingSkeleton(lines: 3),
            error: (error, _) => ErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(staffProvider),
            ),
            data: (items) {
              final technicians = items
                  .where((member) => member.role == 'TECHNICIAN')
                  .toList(growable: false);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WorkshopOptionCard<String>(
                    key: const Key('jobs-technician-later'),
                    value: '',
                    groupValue: _technicianId ?? '',
                    onChanged: (_) => setState(() => _technicianId = null),
                    title: l10n.jobsAssignLater,
                    caption: l10n.jobsSelectTechnician,
                  ),
                  SizedBox(height: context.spacing.sm),
                  for (final technician in technicians) ...[
                    WorkshopOptionCard<String>(
                      key: Key('jobs-technician-${technician.userId}'),
                      value: technician.userId,
                      groupValue: _technicianId ?? '',
                      onChanged: (value) =>
                          setState(() => _technicianId = value),
                      title: technician.displayName,
                      caption: technician.emailMasked,
                    ),
                    SizedBox(height: context.spacing.sm),
                  ],
                ],
              );
            },
          ),
          SizedBox(height: context.spacing.md),
          Text(l10n.jobsFieldPreferredLanguage, style: context.texts.bodySmall),
          SizedBox(height: context.spacing.xs),
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              AppSelectableText(
                label: l10n.languageEnglish,
                selected: _preferredLanguage == 'en',
                onTap: () => setState(() => _preferredLanguage = 'en'),
              ),
              AppSelectableText(
                label: l10n.languageArabic,
                selected: _preferredLanguage == 'ar',
                onTap: () => setState(() => _preferredLanguage = 'ar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLast = _step == 3;
    return Wrap(
      spacing: context.spacing.sm,
      runSpacing: context.spacing.sm,
      alignment: WrapAlignment.end,
      children: [
        if (_step > 0)
          AppButton(
            label: l10n.commonBack,
            onPressed: _busy ? null : () => setState(() => _step -= 1),
            variant: AppButtonVariant.text,
            icon: Icons.chevron_left,
          ),
        AppButton(
          key: const Key('jobs-wizard-next'),
          label: isLast ? l10n.jobsCreateCta : l10n.commonNext,
          onPressed: _busy ? null : _next,
          isLoading: _busy,
          icon: isLast ? Icons.check : Icons.chevron_right,
        ),
      ],
    );
  }

  Future<void> _next() async {
    if (!_validateStep()) {
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

  bool _validateStep() {
    final l10n = AppLocalizations.of(context);
    String? error;
    if (_step == 0) {
      if (_customerName.text.trim().isEmpty) {
        error = l10n.requiredField;
      } else if (_customerPhone.text.trim().isEmpty) {
        error = l10n.jobsValidationPhoneRequired;
      } else if (_customerEmail.text.trim().isNotEmpty &&
          !_customerEmail.text.contains('@')) {
        error = l10n.jobsValidationEmailInvalid;
      }
    } else if (_step == 1) {
      if (_vehicleMake.text.trim().isEmpty ||
          _vehicleModel.text.trim().isEmpty) {
        error = l10n.requiredField;
      } else if (_vehicleVin.text.trim().isNotEmpty &&
          _vehicleVin.text.trim().length != 17) {
        error = l10n.jobsValidationVin;
      }
    } else if (_step == 2 && _templateVersionId == null) {
      error = l10n.requiredField;
    }
    if (error != null) {
      setState(() => _error = error);
      return false;
    }
    return true;
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
          .createCleanJob(
            NewCleanJob(
              templateVersionId: _templateVersionId!,
              customerName: _customerName.text.trim(),
              customerPhone: _customerPhone.text.trim(),
              customerEmail: _nullIfEmpty(_customerEmail.text),
              vehicleVin: _nullIfEmpty(_vehicleVin.text),
              vehicleMake: _vehicleMake.text.trim(),
              vehicleModel: _vehicleModel.text.trim(),
              vehicleYear: int.tryParse(_vehicleYear.text.trim()),
              vehiclePlate: _nullIfEmpty(_vehiclePlate.text),
              odometerValue: int.tryParse(_odometer.text.trim()),
              odometerUnit: _odometerUnit,
              transmission: _transmission,
              fuelType: _fuelType,
              preferredLanguage: _preferredLanguage,
              assignedTechnicianId: _technicianId,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error is AppFailure
              ? '${l10n.commonServerRejected} (${error.code})'
              : l10n.commonActionFailed;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
