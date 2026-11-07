import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Entry point for the Figma screen 4 dialog (Assign Technician, 512 layout).
///
/// Dialog content only: this file opens nothing by itself. The queue trigger
/// is wired elsewhere by calling [WorkshopAssignDialog.show], which assigns
/// the job via the existing `assignJob` endpoint and returns the assigned
/// technician id (or null when the dialog is dismissed without assigning).
///
/// Slot mapping (f3 slot sheet screen 4, `04-assign-technician.md`):
/// - Title/subtitle: `assignTechnicianTitle` + `assignTechnicianSubtitle`
///   (neutral "available technician" wording; no certification claims).
/// - Vehicle strip: existing job fields only — `reference`,
///   `vehicleMake`/`vehicleModel`, `scope`/`templateName`. No trim, recall,
///   estimates, stages, or ticket renumbering (all unmodelled; never invent).
/// - Tech rows: [WorkshopOptionCard] per ACTIVE technician of the same
///   workshop (`displayName` + `emailMasked` from `staff()`, mirroring the
///   existing `_assign` filter). No skills, bays, workload, or levels.
/// - Optional reason input (A06 audit completeness; empty sends null).
/// - Cancel/Confirm: existing `assignJob(jobId, technicianId, reason?)` +
///   `jobAssigned`/`actionFailed` feedback.
/// - Finalized/cancelled jobs are rejected: the dialog reports the failure
///   state and Confirm stays disabled (never calls `assignJob`).
abstract final class WorkshopAssignDialog {
  const WorkshopAssignDialog._();

  /// Opens the centred [WorkshopDialog] and returns the assigned technician
  /// id, or null when dismissed without assigning.
  ///
  /// [WorkshopDialog] already centres the 512 dialog on wide layouts with
  /// inset padding (derived narrow fit, verified at 390), traps focus, closes
  /// on Esc, and returns focus to the invoker.
  static Future<String?> show(BuildContext context, WorkshopJob job) async {
    final l10n = AppLocalizations.of(context);
    // Owned and disposed by [_AssignTechnicianBodyState]: disposing here
    // would kill the reason controller while the dialog route is still
    // animating out after Confirm.
    final scope = _AssignScope(
      rejected: job.status == 'FINALIZED' || job.status == 'CANCELLED',
    );
    final assigned = await WorkshopDialog.show<String>(
      context,
      title: l10n.assignTechnicianTitle,
      subtitle: l10n.assignTechnicianSubtitle,
      closeSemanticLabel: l10n.close,
      content: _AssignTechnicianBody(scope: scope, job: job),
      actions: <Widget>[
        _AssignCancelButton(scope: scope),
        _AssignConfirmButton(scope: scope, job: job),
      ],
    );
    if (assigned != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).jobAssigned)),
      );
    }
    return assigned;
  }
}

/// Shared mutable state between the dialog body (tech list + reason field)
/// and the fixed actions (Cancel/Confirm), both built by
/// [WorkshopDialog.show].
class _AssignScope {
  _AssignScope({required this.rejected});

  /// True for finalized/cancelled jobs: assignment is rejected.
  final bool rejected;

  final ValueNotifier<String?> selected = ValueNotifier<String?>(null);
  final ValueNotifier<bool> busy = ValueNotifier<bool>(false);
  final TextEditingController reason = TextEditingController();

  Future<void> Function()? submit;

  void dispose() {
    selected.dispose();
    busy.dispose();
    reason.dispose();
  }
}

/// Text Cancel action: dismisses without assigning.
class _AssignCancelButton extends StatelessWidget {
  const _AssignCancelButton({required this.scope});

  final _AssignScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: scope.busy,
      builder: (context, busy, _) => AppButton(
        key: const Key('assign-cancel'),
        label: l10n.cancel,
        onPressed: busy ? null : () => Navigator.of(context).pop(),
        variant: AppButtonVariant.text,
      ),
    );
  }
}

/// Primary Confirm action: enabled only with a selection, never for rejected
/// jobs or while submitting.
class _AssignConfirmButton extends StatelessWidget {
  const _AssignConfirmButton({required this.scope, required this.job});

  final _AssignScope scope;
  final WorkshopJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: scope.selected,
      builder: (context, selected, _) => ValueListenableBuilder<bool>(
        valueListenable: scope.busy,
        builder: (context, busy, _) => AppButton(
          key: const Key('assign-confirm'),
          label: l10n.confirm,
          onPressed: selected == null || busy || scope.rejected
              ? null
              : () => scope.submit?.call(),
          isLoading: busy,
        ),
      ),
    );
  }
}

/// Scrollable dialog body: vehicle strip, technician radio cards (or the
/// loading/error/empty states), and the optional reason field.
class _AssignTechnicianBody extends ConsumerStatefulWidget {
  const _AssignTechnicianBody({required this.scope, required this.job});

  final _AssignScope scope;
  final WorkshopJob job;

  @override
  ConsumerState<_AssignTechnicianBody> createState() =>
      _AssignTechnicianBodyState();
}

class _AssignTechnicianBodyState
    extends ConsumerState<_AssignTechnicianBody> {
  @override
  void initState() {
    super.initState();
    widget.scope.submit = _submit;
  }

  @override
  void dispose() {
    if (widget.scope.submit == _submit) {
      widget.scope.submit = null;
    }
    // The dialog route stays mounted through the pop exit animation, so
    // the scope (reason controller, selection/busy notifiers) is disposed
    // here rather than when `show` returns.
    widget.scope.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final selected = widget.scope.selected.value;
    if (selected == null ||
        widget.scope.busy.value ||
        widget.scope.rejected) {
      return;
    }
    widget.scope.busy.value = true;
    try {
      final reason = widget.scope.reason.text.trim();
      await ref
          .read(adminApiProvider)
          .assignJob(widget.job.id, selected, reason.isEmpty ? null : reason);
      if (mounted) {
        Navigator.of(context).pop(selected);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final job = widget.job;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _VehicleStrip(key: const Key('assign-vehicle-strip'), job: job),
        SizedBox(height: context.spacing.md),
        if (widget.scope.rejected)
          ErrorState(title: l10n.error, body: l10n.actionFailed)
        else
          Consumer(
            builder: (context, ref, _) {
              final staff = ref.watch(staffProvider);
              return staff.when(
                loading: () => const LoadingSkeleton(lines: 3),
                error: (error, _) => ErrorState(
                  title: l10n.error,
                  body: l10n.genericError,
                  onRetry: () => ref.invalidate(staffProvider),
                  retryLabel: l10n.retryAction,
                ),
                data: (members) {
                  // Same semantics as the existing `_assign` bottom sheet:
                  // ACTIVE technicians of this workshop only. Disabled or
                  // transferred staff never render, so they stay
                  // unselectable.
                  final technicians = members
                      .where(
                        (member) =>
                            member.role == 'TECHNICIAN' &&
                            member.status == 'ACTIVE',
                      )
                      .toList();
                  if (technicians.isEmpty) {
                    return EmptyState(
                      title: l10n.noTechnicians,
                      body: l10n.staffReadOnlyBody,
                      icon: Icons.groups_outlined,
                    );
                  }
                  return ValueListenableBuilder<String?>(
                    valueListenable: widget.scope.selected,
                    builder: (context, selected, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final member in technicians) ...[
                          WorkshopOptionCard<String>(
                            key: Key('assign-tech-${member.userId}'),
                            value: member.userId,
                            groupValue: selected ?? '',
                            onChanged: (value) =>
                                widget.scope.selected.value = value,
                            title: member.displayName,
                            caption: member.emailMasked,
                            leading: CircleAvatar(
                              backgroundColor:
                                  context.colors.surfaceContainerHighest,
                              child: Icon(
                                Icons.person_outline,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          SizedBox(height: context.spacing.sm),
                        ],
                        SizedBox(height: context.spacing.xs),
                        AppTextField(
                          key: const Key('assign-reason'),
                          controller: widget.scope.reason,
                          label: l10n.assignReasonOptional,
                          hint: l10n.reason,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

/// Vehicle snapshot strip built from existing job fields only: `reference`,
/// `vehicleMake`/`vehicleModel`, and `templateName`/`scope`. No trim, recall,
/// estimates, stages, or ticket renumbering (all unmodelled; never invented).
class _VehicleStrip extends StatelessWidget {
  const _VehicleStrip({required this.job, super.key});

  final WorkshopJob job;

  @override
  Widget build(BuildContext context) {
    final vehicle = '${job.vehicleMake} ${job.vehicleModel}'.trim();
    final title = vehicle.isEmpty ? job.reference : vehicle;
    final templateScope = [job.templateName, job.scope]
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' · ');
    final detail = [
      if (vehicle.isNotEmpty) job.reference,
      if (templateScope.isNotEmpty) templateScope,
    ].join(' · ');
    return Container(
      padding: EdgeInsetsDirectional.all(context.spacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(context.radii.lg),
      ),
      child: Row(
        children: [
          Container(
            width: context.sizing.iconXl,
            height: context.sizing.iconXl,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.surfaceContainerHighest,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.directions_car_outlined,
              size: context.sizing.iconMd,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(width: context.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: context.texts.titleMedium),
                if (detail.isNotEmpty) ...[
                  SizedBox(height: context.spacing.xs),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
