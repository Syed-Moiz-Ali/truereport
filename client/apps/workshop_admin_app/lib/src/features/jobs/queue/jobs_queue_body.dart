import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_cards.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_states.dart';
import 'package:workshop_admin_app/src/features/jobs/queue/jobs_queue_table.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_actions.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// The sheet region: loading, load error, empty (no data vs filtered), table or
/// phone cards. The page owns state; this widget owns the state branch.
class JobsQueueBody extends StatelessWidget {
  const JobsQueueBody({
    required this.jobs,
    required this.items,
    required this.staff,
    required this.filtered,
    required this.wide,
    required this.cards,
    required this.selectedId,
    required this.sort,
    required this.ascending,
    required this.onSort,
    required this.onSelect,
    required this.onOpen,
    required this.onAction,
    required this.onRetry,
    required this.onClear,
    required this.onCreate,
    super.key,
  });

  final AsyncValue<JobPage> jobs;
  final List<CleanJob> items;
  final List<StaffMember>? staff;
  final bool filtered;
  final bool wide;

  /// True when the layout must be the card list at any width (large text).
  final bool cards;
  final String? selectedId;
  final JobsSort sort;
  final bool ascending;
  final ValueChanged<JobsSort> onSort;
  final ValueChanged<String> onSelect;
  final ValueChanged<CleanJob> onOpen;
  final void Function(CleanJob, JobPrimaryAction) onAction;
  final VoidCallback onRetry;
  final VoidCallback onClear;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final page = jobs.value;
    if (jobs.isLoading && page == null) {
      return const JobsQueueLoading();
    }
    if (jobs.hasError && page == null) {
      return _bounded(
        JobsQueueListError(copy: loadCopy(l10n, jobs.error!), onRetry: onRetry),
      );
    }
    if (items.isEmpty) {
      return _bounded(
        JobsQueueEmpty(
          filtered: filtered,
          onClear: onClear,
          onCreate: onCreate,
        ),
      );
    }
    if (!cards && MediaQuery.sizeOf(context).width >= 680) {
      return JobsQueueTable(
        items: items,
        staff: staff,
        selectedId: selectedId,
        sort: sort,
        ascending: ascending,
        onSort: onSort,
        onSelect: onSelect,
        scrollable: wide,
      );
    }
    return JobsQueueCards(
      items: items,
      staff: staff,
      onOpen: onOpen,
      onAction: onAction,
    );
  }

  Widget _bounded(Widget child) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 360),
      child: child,
    ),
  );
}

/// Distinct list errors: 403 is a permission state, 404 is a gone record.
String loadCopy(AppLocalizations l10n, Object error) {
  if (error is AppFailure) {
    if (error.statusCode == 403 || error.code == 'FORBIDDEN') {
      return l10n.jobsForbidden;
    }
    if (error.statusCode == 404 || error.code == 'JOB_NOT_FOUND') {
      return l10n.jobsNotFound;
    }
  }
  return l10n.commonLoadFailed;
}
