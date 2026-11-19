import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_presentation.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_technician.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Current technician plus the assignment history. `JobAssignment` carries ids
/// only, so names are resolved through the staff directory; an unresolved id
/// renders an em dash, never the id itself.
class JobDetailAssignment extends ConsumerWidget {
  const JobDetailAssignment({required this.job, super.key});

  final CleanJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final assignments = ref.watch(jobAssignmentsProvider(job.id));
    final staff = ref.watch(staffProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WorkshopSectionHeader(title: l10n.jobDetailAssignment),
        SizedBox(height: spacing.sm),
        WorkshopCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              JobFact(
                label: l10n.jobsAssignedTechnician,
                value: jobTechnicianName(l10n, job, staff),
              ),
              SizedBox(height: spacing.md),
              assignments.when(
                loading: () => const WorkshopSkeleton(lines: 2),
                error: (error, _) =>
                    WorkshopInlineNote(text: l10n.commonLoadFailed),
                data: (items) {
                  if (items.isEmpty) {
                    return Text(
                      l10n.jobsAssignmentsEmpty,
                      style: ws.meta.copyWith(color: ws.muted),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const WorkshopDivider(),
                      for (var index = 0; index < items.length; index++) ...[
                        if (index > 0) const WorkshopDivider(),
                        _AssignmentRow(assignment: items[index], staff: staff),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rendered when an id cannot be resolved to a person. Never the id itself.
const String _unknownPerson = '—';

String _staffName(List<StaffMember>? staff, String userId) {
  final id = userId.trim();
  if (id.isEmpty) {
    return _unknownPerson;
  }
  for (final member in staff ?? const <StaffMember>[]) {
    if (member.userId == id) {
      final name = member.displayName.trim();
      return name.isEmpty ? _unknownPerson : name;
    }
  }
  return _unknownPerson;
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.assignment, required this.staff});

  final JobAssignment assignment;
  final List<StaffMember>? staff;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _staffName(staff, assignment.technicianId),
            style: context.ws.bodyStrong.copyWith(color: context.ws.ink),
          ),
          if (assignment.reason != null) ...[
            SizedBox(height: spacing.xxs),
            Text(
              assignment.reason!,
              style: context.ws.meta.copyWith(color: context.ws.muted),
            ),
          ],
        ],
      ),
    );
  }
}
