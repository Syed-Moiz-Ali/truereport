import 'package:admin_app/src/screens/f3b/settings_view.dart';
import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Screen 11 — Workshop Settings (Settings tab).
///
/// Pixel-perfect desktop layout matching Figma spec `11_11._Workshop_Settings`.
class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key, this.onNavSelected});

  final ValueChanged<int>? onNavSelected;

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  final TextEditingController _search = TextEditingController();

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

  void _onSaveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;

    final displayName = session?.user.displayName.trim();
    final userRole = session != null
        ? (session.role.name == 'workshopAdmin'
            ? 'Lead Inspector'
            : session.role.name)
        : null;

    return SingleChildScrollView(
      child: Center(
        child: WorkshopSettingsView(
          selectedNavIndex: 4,
          onNavSelected: _onNavSelected,
          onSaveSettings: _onSaveSettings,
          onSearch: (_) => setState(() {}),
          searchController: _search,
          onSignOut: _onSignOut,
          onToggleLocale: _onToggleLocale,
          userName: displayName,
          userRole: userRole,
        ),
      ),
    );
  }
}
