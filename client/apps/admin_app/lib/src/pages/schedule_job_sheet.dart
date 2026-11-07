import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:l10n/l10n.dart';

/// Entry point for the Figma screen 3 drawer (Create/Schedule, 420 layout).
///
/// Drawer content only: this file opens nothing by itself. The queue trigger
/// is wired elsewhere by calling [showScheduleJobSheet], which returns the
/// created job (or null when the sheet is dismissed without creating).
abstract final class ScheduleJobSheet {
  const ScheduleJobSheet._();

  /// Opens the schedule drawer and returns the created job, or null.
  ///
  /// On wide layouts this is a right-hand [WorkshopSideSheet]; below
  /// [AppBreakpoints.phone] it falls back to the bottom sheet automatically.
  static Future<WorkshopJob?> showScheduleJobSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final scope = _ScheduleScope();
    try {
      final created = await WorkshopSideSheet.show<WorkshopJob>(
        context,
        title: l10n.scheduleJobTitle,
        subtitle: l10n.scheduleJobSubtitle,
        closeSemanticLabel: l10n.close,
        body: _ScheduleJobBody(scope: scope),
        footer: _ScheduleJobFooter(scope: scope),
      );
      if (created != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).jobCreated)),
        );
      }
      return created;
    } finally {
      scope.dispose();
    }
  }
}

/// Shared mutable state between the sheet body (the form) and the fixed
/// footer (the Create action), both built by [WorkshopSideSheet.show].
class _ScheduleScope {
  Future<void> Function()? submit;
  final ValueNotifier<bool> busy = ValueNotifier<bool>(false);

  void dispose() => busy.dispose();
}

/// Fixed footer: Create action plus a neutral helper line.
///
/// The helper reuses the sheet subtitle (create here, technician picked
/// afterwards via the existing assign flow).
class _ScheduleJobFooter extends StatelessWidget {
  const _ScheduleJobFooter({required this.scope});

  final _ScheduleScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The helper duplicates the sheet subtitle (shown uncapped in the
    // header). Above 1.5x it would push header + footer past the sheet
    // height, so it is omitted there; at 1.0x/1.5x the footer is unchanged.
    final showHelper = MediaQuery.textScalerOf(context).scale(1) <= 1.5;
    return ValueListenableBuilder<bool>(
      valueListenable: scope.busy,
      builder: (context, busy, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: l10n.create,
              onPressed: busy
                  ? null
                  : () {
                      scope.submit?.call();
                    },
              isLoading: busy,
              icon: Icons.save_outlined,
              expand: true,
            ),
            if (showHelper) ...[
              SizedBox(height: context.spacing.xs),
              Text(
                l10n.scheduleJobSubtitle,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Scrollable drawer body: the same fields as the full job form.
///
/// Customer name/phone/email, vehicle make/model/year/VIN/plate, scope,
/// scheduled date/time, and the published-template choice offered both as
/// tier cards (real published templates with their item counts) and as the
/// template dropdown. Required `templateVersionId` + `scope` are enforced
/// before [AdminApi.createJob] runs; everything else mirrors the full form.
class _ScheduleJobBody extends ConsumerStatefulWidget {
  const _ScheduleJobBody({required this.scope});

  final _ScheduleScope scope;

  @override
  ConsumerState<_ScheduleJobBody> createState() => _ScheduleJobBodyState();
}

class _ScheduleJobBodyState extends ConsumerState<_ScheduleJobBody> {
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
  final _scheduledAt = TextEditingController();
  final _scheduledAtFocus = FocusNode();
  String? _templateVersionId;
  // The user-picked instant. The visible field shows the locale-formatted
  // date+time; the ISO submit payload is derived from this value via
  // [_formatLocal] so the field text itself is never submitted.
  DateTime? _scheduledAtValue;

  @override
  void initState() {
    super.initState();
    widget.scope.submit = _submit;
    _scheduledAtFocus.addListener(_onScheduledAtFocus);
  }

  @override
  void dispose() {
    if (widget.scope.submit == _submit) {
      widget.scope.submit = null;
    }
    _scheduledAtFocus.removeListener(_onScheduledAtFocus);
    _customerName.dispose();
    _customerPhone.dispose();
    _customerEmail.dispose();
    _vehicleMake.dispose();
    _vehicleModel.dispose();
    _vehicleYear.dispose();
    _vehicleVin.dispose();
    _vehiclePlate.dispose();
    _scope.dispose();
    _scheduledAt.dispose();
    _scheduledAtFocus.dispose();
    super.dispose();
  }

  void _onScheduledAtFocus() {
    if (!_scheduledAtFocus.hasFocus) {
      return;
    }
    _scheduledAtFocus.unfocus();
    _pickScheduledAt();
  }

  Future<void> _pickScheduledAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (!mounted) {
      return;
    }
    if (time == null) {
      return;
    }
    final at = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    _scheduledAtValue = at;
    _scheduledAt.text = _formatDisplay(at);
  }

  /// Locale-aware date+time shown to the user (`DateFormat.yMd + add_Hm`
  /// under the active locale). The picked wall-clock time is displayed
  /// as-is; only the submit payload uses the ISO form.
  String _formatDisplay(DateTime value) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).add_Hm().format(value);
  }

  /// ISO submit payload for [AdminApi.createJob]. Unchanged: the server
  /// contract still receives `yyyy-MM-ddTHH:mm:00`.
  String _formatLocal(DateTime value) {
    String two(int part) => part.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}'
        'T${two(value.hour)}:${two(value.minute)}:00';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = ref.watch(templateVersionOptionsProvider);
    final templates = ref.watch(templatesProvider);
    return options.when(
      loading: () => const LoadingSkeleton(lines: 6),
      error: (error, _) => ErrorState(
        title: l10n.error,
        body: l10n.genericError,
        onRetry: () => ref.invalidate(templateVersionOptionsProvider),
        retryLabel: l10n.retryAction,
      ),
      data: (versions) {
        if (versions.isEmpty) {
          return EmptyState(
            title: l10n.noResults,
            body: l10n.selectTemplate,
            icon: Icons.dashboard_customize_outlined,
          );
        }
        final itemCounts = templates.maybeWhen(
          data: (list) => <String, int>{
            for (final template in list) template.id: template.itemCount,
          },
          orElse: () => const <String, int>{},
        );
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionHeader(title: l10n.jobDetails),
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
              AppTextField(controller: _vehicleVin, label: l10n.vehicleVin),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _vehiclePlate,
                label: l10n.vehiclePlate,
              ),
              SizedBox(height: context.spacing.lg),
              AppTextField(
                controller: _scope,
                label: l10n.scope,
                maxLines: 2,
                validator: _required,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: _scheduledAt,
                label: l10n.scheduledAt,
                readOnly: true,
                focusNode: _scheduledAtFocus,
                suffixIcon: const Icon(Icons.calendar_month_outlined),
              ),
              SizedBox(height: context.spacing.lg),
              for (final version in versions) ...[
                WorkshopOptionCard<String>(
                  value: version.versionId,
                  groupValue: _templateVersionId ?? '',
                  onChanged: (value) =>
                      setState(() => _templateVersionId = value),
                  title: '${version.templateName} · v${version.versionNo}',
                  caption: itemCounts.containsKey(version.templateId)
                      ? l10n.technicianItemsCount(
                          itemCounts[version.templateId]!,
                        )
                      : version.serviceType,
                ),
                SizedBox(height: context.spacing.sm),
              ],
              SizedBox(height: context.spacing.sm),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _templateVersionId,
                decoration: InputDecoration(labelText: l10n.selectTemplate),
                items: versions
                    .map(
                      (version) => DropdownMenuItem(
                        value: version.versionId,
                        child: Text(
                          '${version.templateName} · v${version.versionNo}',
                        ),
                      ),
                    )
                    .toList(),
                validator: (value) =>
                    value == null ? l10n.requiredField : null,
                onChanged: (value) =>
                    setState(() => _templateVersionId = value),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _templateVersionId == null) {
      return;
    }
    widget.scope.busy.value = true;
    try {
      final created = await ref
          .read(adminApiProvider)
          .createJob(
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
            scheduledAt: _scheduledAtValue == null
                ? null
                : _formatLocal(_scheduledAtValue!),
          );
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
        );
      }
    } finally {
      widget.scope.busy.value = false;
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
