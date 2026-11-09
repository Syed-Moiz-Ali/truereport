import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/pages/schedule_job_sheet.dart';
import 'package:admin_app/src/screens/f3a/dashboard_view.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Screen 1 — Workshop Dashboard (Overview).
///
/// Pixel-perfect desktop layout matching Figma spec `02_1._Workshop_Dashboard`.
/// Connects live data from `jobCountsProvider` and `jobsProvider`.
/// The showcase view still carries Figma reference items; the
/// `adminShowcaseProvider` release guard keeps it out of release builds
/// until the Dashboard step wires real data.
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
    // Release guard (Step 2a): the showcase view below still carries
    // fixture copy. Until the Dashboard step wires it, release builds
    // show a neutral empty state instead. This row is removed at that step.
    final showcase = ref.watch(adminShowcaseProvider);
    final countsAsync = ref.watch(jobCountsProvider);
    final jobsAsync = ref.watch(jobsProvider(_search.text));
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;

    final displayName = session?.user.displayName.trim();
    final userRole = session != null
        ? (session.role.name == 'workshopAdmin' ? 'Workshop Lead' : session.role.name)
        : null;

    // Counts come only from the server endpoint. Never render invented
    // numbers: while counts load show a skeleton, on counts failure show a
    // localized error. A jobs-only failure still renders the view, which
    // shows its own inline jobs error next to the real counts.
    final l10n = AppLocalizations.of(context);
    if (!showcase) {
      return Center(
        child: EmptyState(title: l10n.dashboardTab, body: l10n.noResults),
      );
    }
    if (countsAsync.hasError) {
      return Center(
        child: ErrorState(
          title: l10n.error,
          body: l10n.actionFailed,
          retryLabel: l10n.retryAction,
          onRetry: () {
            ref.invalidate(jobCountsProvider);
            ref.invalidate(jobsProvider);
          },
        ),
      );
    }
    final counts = countsAsync.value;
    final recentJobs = jobsAsync.value;
    if (counts == null) {
      return Center(
        child: LoadingSkeleton(semanticLabel: l10n.loading),
      );
    }

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
