import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/screens/f2a/consent_view.dart';
import 'package:technician_app/src/screens/f2a/equipment_view.dart';
import 'package:technician_app/src/screens/f2a/job_intake_view.dart';
import 'package:technician_app/src/screens/f2a/profile_sheet.dart';
import 'package:technician_app/src/technician_providers.dart';

class JobDetailPage extends ConsumerWidget {
  const JobDetailPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final job = ref.watch(technicianJobProvider(jobId));
    return job.when(
      loading: () => AppScaffold(
        appBar: TechnicianAppBar(
          title: l10n.technicianJobIntake,
          showBack: true,
        ),
        body: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.gutter),
          child: const LoadingSkeleton(lines: 6),
        ),
      ),
      error: (error, _) => AppScaffold(
        appBar: TechnicianAppBar(
          title: l10n.technicianJobIntake,
          showBack: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.gutter),
            child: ErrorState(
              title: l10n.error,
              body: l10n.genericError,
              onRetry: () => ref.invalidate(technicianJobProvider(jobId)),
              retryLabel: l10n.retryAction,
            ),
          ),
        ),
      ),
      data: (value) => _Body(job: value),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.job});

  final TechnicianJob job;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _starting = false;

  TechnicianJob get job => widget.job;

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(connectivityProvider).value ?? true;
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;
    return JobIntakeView(
      job: job,
      starting: _starting,
      pendingSyncCount: pending,
      online: online,
      onStart: _start,
      onEditCustomer: _editCustomer,
      onEditVehicle: _editVehicle,
      onConsent: _consent,
      onEquipment: _equipment,
      onProfile: () => showTechnicianProfile(context, ref),
    );
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    if (job.status == 'ASSIGNED' || job.status == 'SCHEDULED') {
      setState(() => _starting = true);
      try {
        await ref.read(technicianApiProvider).start(job.id);
        ref.invalidate(technicianJobProvider(job.id));
        ref.invalidate(inspectionChecklistProvider(job.id));
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.inspectionStarted)));
        }
      } on Object {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
        }
        return;
      } finally {
        if (mounted) {
          setState(() => _starting = false);
        }
      }
    }
    if (mounted) {
      context.push('/jobs/${job.id}/hub');
    }
  }

  Future<void> _editCustomer() async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(text: job.customerName);
    final phone = TextEditingController(text: job.customerPhone ?? '');
    final email = TextEditingController(text: job.customerEmail ?? '');
    final saved = await showAppBottomSheet<bool>(
      context,
      child: _FormSheet(
        title: l10n.customerInformation,
        children: [
          AppTextField(
            controller: name,
            label: l10n.customerName,
            labelAbove: true,
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            controller: phone,
            label: l10n.customerPhone,
            labelAbove: true,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            controller: email,
            label: l10n.customerEmail,
            labelAbove: true,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
        onSave: () async {
          final body = <String, dynamic>{
            'customerName': name.text.trim(),
            'customerPhone': _emptyToNull(phone.text),
            'customerEmail': _emptyToNull(email.text),
          };
          try {
            await ref
                .read(technicianApiProvider)
                .updateCustomer(
                  job.id,
                  customerName: body['customerName'] as String,
                  customerPhone: body['customerPhone'] as String?,
                  customerEmail: body['customerEmail'] as String?,
                );
          } on Object {
            await ref
                .read(offlineStoreProvider)
                .saveCustomerLocally(jobId: job.id, body: body);
          }
        },
      ),
    );
    name.dispose();
    phone.dispose();
    email.dispose();
    if (saved == true && mounted) {
      final pending = await ref.read(offlineStoreProvider).pendingCount();
      if (!mounted) {
        return;
      }
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(technicianJobProvider(job.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pending > 0 ? l10n.savedOnPhone : l10n.customerSaved),
        ),
      );
    }
  }

  Future<void> _editVehicle() async {
    final l10n = AppLocalizations.of(context);
    final make = TextEditingController(text: job.vehicleMake);
    final model = TextEditingController(text: job.vehicleModel);
    final year = TextEditingController(text: job.vehicleYear?.toString() ?? '');
    final vin = TextEditingController(text: job.vehicleVin ?? '');
    final plate = TextEditingController(text: job.vehiclePlate ?? '');
    final odometer = TextEditingController(
      text: job.odometerValue?.toString() ?? '',
    );
    final unit = TextEditingController(text: job.odometerUnit ?? 'KM');
    final saved = await showAppBottomSheet<bool>(
      context,
      child: _FormSheet(
        title: l10n.vehicleIdentification,
        children: [
          AppTextField(
            controller: make,
            label: l10n.vehicleMake,
            labelAbove: true,
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            controller: model,
            label: l10n.vehicleModel,
            labelAbove: true,
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            controller: year,
            label: l10n.vehicleYear,
            labelAbove: true,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            controller: vin,
            label: l10n.vehicleVin,
            labelAbove: true,
            textDirection: TextDirection.ltr,
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            controller: plate,
            label: l10n.vehiclePlate,
            labelAbove: true,
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            controller: odometer,
            label: l10n.odometer,
            labelAbove: true,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: context.spacing.md),
          AppTextField(
            controller: unit,
            label: l10n.odometerUnit,
            labelAbove: true,
          ),
        ],
        onSave: () async {
          final body = <String, dynamic>{
            'vehicleMake': make.text.trim(),
            'vehicleModel': model.text.trim(),
            'vehicleYear': int.tryParse(year.text.trim()),
            'vehicleVin': _emptyToNull(vin.text),
            'vehiclePlate': _emptyToNull(plate.text),
            'odometerValue': int.tryParse(odometer.text.trim()),
            'odometerUnit': _emptyToNull(unit.text)?.toUpperCase(),
          };
          try {
            await ref
                .read(technicianApiProvider)
                .updateVehicle(
                  job.id,
                  vehicleMake: body['vehicleMake'] as String,
                  vehicleModel: body['vehicleModel'] as String,
                  vehicleYear: body['vehicleYear'] as int?,
                  vehicleVin: body['vehicleVin'] as String?,
                  vehiclePlate: body['vehiclePlate'] as String?,
                  odometerValue: body['odometerValue'] as int?,
                  odometerUnit: body['odometerUnit'] as String?,
                );
          } on Object {
            await ref
                .read(offlineStoreProvider)
                .saveVehicleLocally(jobId: job.id, body: body);
          }
        },
      ),
    );
    make.dispose();
    model.dispose();
    year.dispose();
    vin.dispose();
    plate.dispose();
    odometer.dispose();
    unit.dispose();
    if (saved == true && mounted) {
      final pending = await ref.read(offlineStoreProvider).pendingCount();
      if (!mounted) {
        return;
      }
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(technicianJobProvider(job.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pending > 0 ? l10n.savedOnPhone : l10n.vehicleSaved),
        ),
      );
    }
  }

  Future<void> _consent() async {
    final l10n = AppLocalizations.of(context);
    String? type;
    bool? granted;
    var saving = false;
    final saved = await showAppBottomSheet<bool>(
      context,
      child: StatefulBuilder(
        builder: (context, setState) => ConsentView(
          selectedType: type,
          selectedStatus: granted,
          saving: saving,
          onTypeChanged: (value) => setState(() => type = value),
          onStatusChanged: (value) => setState(() => granted = value),
          onSave: () async {
            setState(() => saving = true);
            final body = <String, dynamic>{
              'consentType': type!,
              'status': granted! ? 'GRANTED' : 'REFUSED',
              'wordingVersion': 'v1',
              'channel': 'IN_PERSON',
            };
            try {
              await ref
                  .read(technicianApiProvider)
                  .recordConsent(
                    job.id,
                    consentType: type!,
                    status: granted! ? 'GRANTED' : 'REFUSED',
                    wordingVersion: 'v1',
                    channel: 'IN_PERSON',
                  );
            } on Object {
              await ref
                  .read(offlineStoreProvider)
                  .saveConsentLocally(jobId: job.id, body: body);
            }
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
        ),
      ),
    );
    if (saved == true && mounted) {
      final pending = await ref.read(offlineStoreProvider).pendingCount();
      if (!mounted) {
        return;
      }
      ref.invalidate(pendingSyncCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pending > 0 ? l10n.savedOnPhone : l10n.consentRecorded),
        ),
      );
    }
  }

  Future<void> _equipment() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final items = await ref.read(technicianApiProvider).equipment(job.id);
      await navigator.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (dialogContext) => EquipmentView(
            equipment: items,
            title: l10n.equipment,
            onBack: () => Navigator.of(dialogContext).pop(),
            onProceed: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.genericError)));
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _FormSheet extends StatelessWidget {
  const _FormSheet({
    required this.title,
    required this.children,
    required this.onSave,
  });

  final String title;
  final List<Widget> children;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TechnicianSectionTitle(title: title),
          SizedBox(height: context.spacing.md),
          ...children,
          SizedBox(height: context.spacing.lg),
          AppButton(
            label: l10n.save,
            onPressed: () async {
              try {
                await onSave();
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } on Object {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
                }
              }
            },
            icon: Icons.save_outlined,
            large: true,
            expand: true,
          ),
          SizedBox(height: context.spacing.lg),
        ],
      ),
    );
  }
}
