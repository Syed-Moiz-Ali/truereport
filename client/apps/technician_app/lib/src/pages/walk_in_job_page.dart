import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/technician_providers.dart';

class WalkInJobPage extends ConsumerStatefulWidget {
  const WalkInJobPage({super.key});

  @override
  ConsumerState<WalkInJobPage> createState() => _WalkInJobPageState();
}

class _WalkInJobPageState extends ConsumerState<WalkInJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _customerEmail = TextEditingController();
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleYear = TextEditingController();
  final _vehicleVin = TextEditingController();
  final _vehiclePlate = TextEditingController();
  final _scope = TextEditingController();
  String? _templateVersionId;
  bool _busy = false;

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
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final versions = ref.watch(technicianTemplateVersionsProvider);
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.walkInJob)),
      body: versions.when(
        loading: () => Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: const LoadingSkeleton(lines: 6),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(technicianTemplateVersionsProvider),
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
        data: (options) => Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsetsDirectional.all(context.spacing.lg),
            children: [
              SectionHeader(title: l10n.customerInformation),
              AppTextField(
                controller: _customerName,
                label: l10n.customerName,
                validator: _required,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _customerPhone,
                label: l10n.customerPhone,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _customerEmail,
                label: l10n.customerEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: context.spacing.lg),
              SectionHeader(title: l10n.vehicleIdentification),
              AppTextField(
                controller: _vehicleMake,
                label: l10n.vehicleMake,
                validator: _required,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _vehicleModel,
                label: l10n.vehicleModel,
                validator: _required,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _vehicleYear,
                label: l10n.vehicleYear,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _vehicleVin,
                label: l10n.vehicleVin,
                textDirection: TextDirection.ltr,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: _vehiclePlate, label: l10n.vehiclePlate),
              SizedBox(height: context.spacing.lg),
              AppTextField(
                controller: _scope,
                label: l10n.inspectionScope,
                maxLines: 2,
                validator: _required,
              ),
              SizedBox(height: context.spacing.lg),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _templateVersionId,
                decoration: InputDecoration(labelText: l10n.selectTemplate),
                items: options
                    .map(
                      (version) => DropdownMenuItem(
                        value: version.versionId,
                        child: Text(
                          '${version.templateName} · v${version.versionNo}',
                        ),
                      ),
                    )
                    .toList(),
                validator: (value) => value == null ? l10n.requiredField : null,
                onChanged: (value) =>
                    setState(() => _templateVersionId = value),
              ),
              SizedBox(height: context.spacing.xl),
              AppButton(
                label: l10n.walkInJob,
                onPressed: _busy ? null : _submit,
                isLoading: _busy,
                icon: Icons.add,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    return null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false) ||
        _templateVersionId == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final job = await ref
          .read(technicianApiProvider)
          .createWalkIn(
            templateVersionId: _templateVersionId!,
            customerName: _customerName.text.trim(),
            customerPhone: _emptyToNull(_customerPhone.text),
            customerEmail: _emptyToNull(_customerEmail.text),
            vehicleMake: _vehicleMake.text.trim(),
            vehicleModel: _vehicleModel.text.trim(),
            vehicleYear: int.tryParse(_vehicleYear.text.trim()),
            vehicleVin: _emptyToNull(_vehicleVin.text),
            vehiclePlate: _emptyToNull(_vehiclePlate.text),
            scope: _scope.text.trim(),
          );
      ref.invalidate(technicianJobsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.walkInCreated)));
        context.go('/jobs/${job.id}');
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
