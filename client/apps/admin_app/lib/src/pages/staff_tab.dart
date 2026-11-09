import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/models.dart';
import 'package:admin_app/src/pages/create_technician_sheet.dart';
import 'package:admin_app/src/screens/f3b/staff_detail_view.dart';
import 'package:admin_app/src/screens/f3b/staff_view.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Screen 5 — Workshop Staff Management (Staff tab).
///
/// Pixel-perfect desktop layout matching Figma spec `05_5._Workshop_Staff_Management`.
/// Connects live data from `staffProvider`. Supports full drill-down to
/// the dedicated [WorkshopStaffDetailView] when any staff card is tapped.
class StaffTab extends ConsumerStatefulWidget {
  const StaffTab({super.key, this.onNavSelected});

  final ValueChanged<int>? onNavSelected;

  @override
  ConsumerState<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends ConsumerState<StaffTab> {
  final _search = TextEditingController();
  StaffMember? _selectedStaff;

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

  Future<void> _onAddStaff() async {
    final created = await CreateTechnicianSheet.showCreateTechnicianSheet(context);
    if (created != null) {
      ref.invalidate(staffProvider);
    }
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
    final showcase = ref.watch(adminShowcaseProvider);
    final staffAsync = ref.watch(staffProvider);
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;

    final displayName = session?.user.displayName.trim();
    final userRole = session != null
        ? (session.role.name == 'workshopAdmin' ? 'Lead Inspector' : session.role.name)
        : null;

    final staff = staffAsync.value;

    final l10n = AppLocalizations.of(context);
    if (!showcase) {
      return Center(
        child: EmptyState(title: l10n.staffTab, body: l10n.noResults),
      );
    }

    if (_selectedStaff != null) {
      return WorkshopStaffDetailView(
        staff: _selectedStaff!,
        onBack: () => setState(() => _selectedStaff = null),
        onNavSelected: (idx) {
          setState(() => _selectedStaff = null);
          _onNavSelected(idx);
        },
        onEditStaff: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Editing profile for ${_selectedStaff!.displayName}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onReassignBay: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reassigning bay for ${_selectedStaff!.displayName}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onSignOut: _onSignOut,
        onToggleLocale: _onToggleLocale,
        userName: displayName,
        userRole: userRole,
      );
    }

    return WorkshopStaffView(
      selectedNavIndex: 2,
      onNavSelected: _onNavSelected,
      onAddStaff: _onAddStaff,
      onSearch: (_) => setState(() {}),
      searchController: _search,
      onSignOut: _onSignOut,
      onToggleLocale: _onToggleLocale,
      onStaffSelected: (staff) => setState(() => _selectedStaff = staff),
      userName: displayName,
      userRole: userRole,
      staffList: staff,
    );
  }
}
