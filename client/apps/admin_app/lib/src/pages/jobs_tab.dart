import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/pages/schedule_job_sheet.dart';
import 'package:admin_app/src/screens/f3a/queue_view.dart';
import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Screen 2 — Workshop Live Job Queue (Jobs tab).
///
/// Pixel-perfect desktop layout matching Figma spec `03_2._Live_Job_Queue`.
/// Connects live data from `jobsProvider`, while gracefully displaying
/// Figma reference vehicle cards and metrics when live data is empty.
class JobsTab extends ConsumerStatefulWidget {
  const JobsTab({super.key, this.onNavSelected});

  final ValueChanged<int>? onNavSelected;

  @override
  ConsumerState<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends ConsumerState<JobsTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onNavSelected(int index) {
    if (widget.onNavSelected != null) {
      widget.onNavSelected!(index);
      return;
    }
    final controller = DefaultTabController.maybeOf(context);
    if (controller != null) {
      controller.animateTo(index);
    }
  }

  void _onNewJob() {
    ScheduleJobSheet.showScheduleJobSheet(context);
  }

  void _onToggleLocale() {
    final current = ref.read(localeProvider);
    final next = current.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    ref.read(localeProvider.notifier).setLocale(next);
  }

  void _onSignOut() {
    ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider(_search.text));
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;

    final displayName = session?.user.displayName.trim();
    final userRole = session != null
        ? (session.role.name == 'workshopAdmin' ? 'Workshop Lead' : session.role.name)
        : null;

    final jobs = jobsAsync.value;

    return WorkshopQueueView(
      selectedNavIndex: 1,
      onNavSelected: _onNavSelected,
      onNewJob: _onNewJob,
      onSearch: (_) => setState(() {}),
      searchController: _search,
      onSignOut: _onSignOut,
      onToggleLocale: _onToggleLocale,
      jobs: jobs,
      userName: displayName,
      userRole: userRole,
    );
  }
}
