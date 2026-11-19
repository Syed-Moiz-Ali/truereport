import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_error_copy.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// The single assign flow for a clean job. Versioned, status-guarded and
/// shared by detail (and any future board action).
///
/// Returns `true` when the assignment was accepted. Never calls the legacy
/// `assignJob`; refuses to submit when [CleanJob.version] is null (M5).
Future<bool?> showAssignSheet(BuildContext context, {required CleanJob job}) {
  return showAppBottomSheet<bool>(context, child: _AssignSheet(job: job));
}

class _AssignSheet extends ConsumerStatefulWidget {
  const _AssignSheet({required this.job});

  final CleanJob job;

  @override
  ConsumerState<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends ConsumerState<_AssignSheet> {
  final _reason = TextEditingController();
  String? _selectedTechnicianId;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedTechnicianId = widget.job.assignedTechnicianId;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit(String technicianId) async {
    final version = widget.job.version;
    if (version == null || _busy) {
      return;
    }
    final reason = _reason.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .assignCleanJob(
            widget.job.id,
            technicianId,
            reason.isEmpty ? null : reason,
            version: version,
          );
      ref.invalidate(cleanJobProvider(widget.job.id));
      ref.invalidate(jobAssignmentsProvider(widget.job.id));
      ref.invalidate(cleanJobCountsProvider);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = jobErrorCopy(AppLocalizations.of(context), error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final staff = ref.watch(staffProvider);
    final technicians = staff.value
        ?.where((member) => member.role == 'TECHNICIAN')
        .toList(growable: false);
    final defaultTechnicianId = technicians == null || technicians.isEmpty
        ? null
        : technicians.first.userId;
    final selectedTechnicianId = _selectedTechnicianId ?? defaultTechnicianId;
    final version = widget.job.version;
    final canSubmit =
        version != null &&
        !_busy &&
        technicians != null &&
        technicians.isNotEmpty &&
        selectedTechnicianId != null;

    return SingleChildScrollView(
      child: Column(
        key: const Key('job-assign-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkshopSectionHeader(
            title: l10n.assignTechnicianTitle,
            subtitle: l10n.assignTechnicianSubtitle,
          ),
          SizedBox(height: spacing.md),
          staff.when(
            loading: () => const WorkshopSkeleton(lines: 3),
            error: (error, _) =>
                WorkshopInlineNote(text: l10n.commonLoadFailed),
            data: (members) {
              final list = members
                  .where((member) => member.role == 'TECHNICIAN')
                  .toList(growable: false);
              if (list.isEmpty) {
                return WorkshopInlineNote(text: l10n.noTechnicians);
              }
              return WorkshopCard(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < list.length; index++) ...[
                      if (index > 0) const WorkshopDivider(),
                      _TechnicianRow(
                        member: list[index],
                        selected: selectedTechnicianId == list[index].userId,
                        onTap: _busy
                            ? null
                            : () => setState(
                                () =>
                                    _selectedTechnicianId = list[index].userId,
                              ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          SizedBox(height: spacing.md),
          WorkshopTextField(
            key: const Key('assign-reason'),
            controller: _reason,
            label: l10n.jobsAssignmentReason,
            enabled: !_busy,
          ),
          if (version == null) ...[
            SizedBox(height: spacing.sm),
            WorkshopInlineNote(text: l10n.jobsNoVersion),
          ],
          if (_error != null) ...[
            SizedBox(height: spacing.sm),
            WorkshopInlineNote(text: _error!, icon: Icons.error_outline),
          ],
          SizedBox(height: spacing.lg),
          Row(
            children: [
              Expanded(
                child: WorkshopButton(
                  key: const Key('assign-cancel'),
                  label: l10n.cancel,
                  variant: WorkshopButtonVariant.secondary,
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: WorkshopButton(
                  key: const Key('assign-confirm'),
                  label: widget.job.assignedTechnicianId == null
                      ? l10n.assign
                      : l10n.reassign,
                  isLoading: _busy,
                  onPressed: canSubmit
                      ? () => _submit(selectedTechnicianId)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TechnicianRow extends StatelessWidget {
  const _TechnicianRow({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final StaffMember member;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    return Semantics(
      button: true,
      selected: selected,
      label: member.displayName,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('assign-tech-${member.userId}'),
          onTap: onTap,
          child: SizedBox(
            height: ws.touchTarget + spacing.xs,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.md),
              child: Row(
                children: [
                  WorkshopAvatar(
                    initials: _initials(member.displayName),
                    semanticLabel: member.displayName,
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Text(
                      member.displayName,
                      maxLines: 2,
                      style: ws.bodyStrong.copyWith(color: ws.ink),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, size: 20, color: ws.accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final first = parts.first.isEmpty ? '' : parts.first[0];
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  final value = (first + last).toUpperCase();
  return value.isEmpty ? '?' : value;
}
