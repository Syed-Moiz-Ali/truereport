import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/pages/schedule_job_sheet.dart';
import 'package:admin_app/src/screens/f3a/dashboard_view.dart';
import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Screen 1 — Workshop Dashboard (Overview).
///
/// Pixel-perfect desktop layout matching Figma spec `02_1._Workshop_Dashboard`.
/// Connects live data from `jobCountsProvider` and `jobsProvider`, while
/// gracefully displaying Figma reference items when live data is empty.
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key, this.onNavSelected});

  final ValueChanged<int>? onNavSelected;

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
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

  void _onDispatchBay() {
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
    final countsAsync = ref.watch(jobCountsProvider);
    final jobsAsync = ref.watch(jobsProvider(_search.text));
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;

    final displayName = session?.user.displayName.trim();
    final userRole = session != null
        ? (session.role.name == 'workshopAdmin' ? 'Workshop Lead' : session.role.name)
        : null;

    final counts = countsAsync.value;
    final recentJobs = jobsAsync.value;

    return WorkshopDashboardView(
      selectedNavIndex: 0,
      onNavSelected: _onNavSelected,
      onDispatchBay: _onDispatchBay,
      onSearch: (_) => setState(() {}),
      searchController: _search,
      onSignOut: _onSignOut,
      onToggleLocale: _onToggleLocale,
      counts: counts,
      recentJobs: recentJobs,
      userName: displayName,
      userRole: userRole,
    );
  }
}
