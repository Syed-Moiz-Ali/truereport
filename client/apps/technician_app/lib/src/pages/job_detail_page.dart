import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/models.dart';
import 'package:technician_app/src/technician_providers.dart';
import 'package:technician_app/src/ui_helpers.dart';

class JobDetailPage extends ConsumerWidget {
  const JobDetailPage({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final job = ref.watch(technicianJobProvider(jobId));
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.jobDetails)),
      body: job.when(
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
              onRetry: () => ref.invalidate(technicianJobProvider(jobId)),
              retryLabel: l10n.search,
            ),
          ),
        ),
        data: (value) => _Body(job: value),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.job});

  final TechnicianJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(connectivityProvider).value ?? true;
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;
    final finalized = job.status == 'FINALIZED';
    final cancelled = job.status == 'CANCELLED';
    return ListView(
      padding: EdgeInsetsDirectional.all(context.spacing.lg),
      children: [
        SectionHeader(
          title: job.reference,
          subtitle: technicianStatusLabel(l10n, job.status),
        ),
        Card(
          child: Padding(
            padding: EdgeInsetsDirectional.all(context.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.customerName, style: context.texts.titleMedium),
                SizedBox(height: context.spacing.xs),
                Text(
                  '${job.vehicleMake} ${job.vehicleModel}'
                  '${job.vehicleYear == null ? '' : ' · ${job.vehicleYear}'}',
                  style: context.texts.bodyMedium,
                ),
                SizedBox(height: context.spacing.xs),
                Text(
                  '${job.templateName} · v${job.templateVersionNo ?? '-'} · ${job.scope}',
                  style: context.texts.bodySmall,
                ),
                if (!online || pending > 0) ...[
                  SizedBox(height: context.spacing.sm),
                  StatusChip(
                    label: online ? l10n.savedOnPhone : l10n.offlineBanner,
                    tone: StatusTone.warning,
                    icon: online
                        ? Icons.phone_iphone
                        : Icons.cloud_off_outlined,
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: context.spacing.lg),
        if (!finalized && !cancelled) ...[
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              AppButton(
                label: l10n.customerInformation,
                onPressed: () => _editCustomer(context, ref),
                icon: Icons.person_outline,
                variant: AppButtonVariant.tonal,
              ),
              AppButton(
                label: l10n.vehicleIdentification,
                onPressed: () => _editVehicle(context, ref),
                icon: Icons.directions_car_outlined,
                variant: AppButtonVariant.tonal,
              ),
              AppButton(
                label: l10n.consent,
                onPressed: () => _consent(context, ref),
                icon: Icons.verified_user_outlined,
                variant: AppButtonVariant.tonal,
              ),
              AppButton(
                label: l10n.equipment,
                onPressed: () => _equipment(context, ref),
                icon: Icons.handyman_outlined,
                variant: AppButtonVariant.text,
              ),
              if (pending > 0)
                AppButton(
                  label: l10n.syncQueue,
                  onPressed: () => context.push('/sync'),
                  icon: Icons.sync,
                  variant: AppButtonVariant.text,
                ),
            ],
          ),
          SizedBox(height: context.spacing.lg),
          if (job.status == 'ASSIGNED')
            AppButton(
              label: l10n.startInspection,
              onPressed: () => _start(context, ref),
              icon: Icons.play_arrow,
              expand: true,
            )
          else
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: [
                AppButton(
                  label: l10n.checklist,
                  onPressed: () => context.push('/jobs/${job.id}/checklist'),
                  icon: Icons.checklist,
                ),
                AppButton(
                  label: l10n.reviewAndFinalize,
                  onPressed: () => context.push('/jobs/${job.id}/review'),
                  icon: Icons.fact_check_outlined,
                  variant: AppButtonVariant.tonal,
                ),
              ],
            ),
        ] else if (finalized)
          AppButton(
            label: l10n.finalizedReadOnly,
            onPressed: () => context.push('/jobs/${job.id}/finalized'),
            icon: Icons.lock_outline,
            variant: AppButtonVariant.tonal,
            expand: true,
          ),
      ],
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(technicianApiProvider).start(job.id);
      ref.invalidate(technicianJobProvider(job.id));
      ref.invalidate(inspectionChecklistProvider(job.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.inspectionStarted)));
        context.push('/jobs/${job.id}/checklist');
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
      }
    }
  }

  Future<void> _editCustomer(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController(text: job.customerName);
    final phone = TextEditingController(text: job.customerPhone ?? '');
    final email = TextEditingController(text: job.customerEmail ?? '');
    final saved = await showAppBottomSheet<bool>(
      context,
      child: _FormSheet(
        title: l10n.customerInformation,
        children: [
          AppTextField(controller: name, label: l10n.customerName),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: phone,
            label: l10n.customerPhone,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: email,
            label: l10n.customerEmail,
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
    if (saved == true && context.mounted) {
      final pending = await ref.read(offlineStoreProvider).pendingCount();
      if (!context.mounted) {
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

  Future<void> _editVehicle(BuildContext context, WidgetRef ref) async {
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
          AppTextField(controller: make, label: l10n.vehicleMake),
          SizedBox(height: context.spacing.sm),
          AppTextField(controller: model, label: l10n.vehicleModel),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: year,
            label: l10n.vehicleYear,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: vin,
            label: l10n.vehicleVin,
            textDirection: TextDirection.ltr,
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(controller: plate, label: l10n.vehiclePlate),
          SizedBox(height: context.spacing.sm),
          AppTextField(
            controller: odometer,
            label: l10n.odometer,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: context.spacing.sm),
          AppTextField(controller: unit, label: l10n.odometerUnit),
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
    if (saved == true && context.mounted) {
      final pending = await ref.read(offlineStoreProvider).pendingCount();
      if (!context.mounted) {
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

  Future<void> _consent(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    String? type;
    bool? granted;
    final saved = await showAppBottomSheet<bool>(
      context,
      child: StatefulBuilder(
        builder: (context, setState) => _FormSheet(
          title: l10n.consent,
          enabled: granted != null && type != null,
          saveKey: const Key('consent-save'),
          children: [
            AppSelectableText(
              key: const Key('consent-type-processing'),
              label: l10n.consentProcessing,
              selected: type == 'PROCESSING',
              onTap: () => setState(() => type = 'PROCESSING'),
            ),
            SizedBox(height: context.spacing.sm),
            AppSelectableText(
              key: const Key('consent-type-public-link'),
              label: l10n.consentPublicLink,
              selected: type == 'PUBLIC_LINK',
              onTap: () => setState(() => type = 'PUBLIC_LINK'),
            ),
            SizedBox(height: context.spacing.md),
            AppSelectableText(
              key: const Key('consent-granted'),
              label: l10n.consentGranted,
              selected: granted == true,
              onTap: () => setState(() => granted = true),
            ),
            SizedBox(height: context.spacing.sm),
            AppSelectableText(
              key: const Key('consent-refused'),
              label: l10n.consentRefused,
              selected: granted == false,
              onTap: () => setState(() => granted = false),
            ),
          ],
          onSave: () async {
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
          },
        ),
      ),
    );
    if (saved == true && context.mounted) {
      final pending = await ref.read(offlineStoreProvider).pendingCount();
      if (!context.mounted) {
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

  Future<void> _equipment(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    await showAppBottomSheet<void>(
      context,
      child: FutureBuilder<List<String>>(
        future: ref.read(technicianApiProvider).equipment(job.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingSkeleton(lines: 3);
          }
          final ids = snapshot.data!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: l10n.equipment),
              if (ids.isEmpty)
                EmptyState(title: l10n.noResults, body: l10n.equipment)
              else
                ...ids.map(
                  (id) => AppListTile(
                    title: id,
                    leading: const Icon(Icons.handyman_outlined),
                  ),
                ),
            ],
          );
        },
      ),
    );
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
    this.enabled = true,
    this.saveKey,
  });

  final String title;
  final List<Widget> children;
  final Future<void> Function() onSave;
  final bool enabled;
  final Key? saveKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title),
          ...children,
          SizedBox(height: context.spacing.lg),
          AppButton(
            key: saveKey,
            label: l10n.save,
            onPressed: enabled
                ? () async {
                    try {
                      await onSave();
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } on Object {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.actionFailed)),
                        );
                      }
                    }
                  }
                : null,
            icon: Icons.save_outlined,
            expand: true,
          ),
          SizedBox(height: context.spacing.lg),
        ],
      ),
    );
  }
}
