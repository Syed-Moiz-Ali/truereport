import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/pages/template_builder_page.dart';
import 'package:admin_app/src/screens/f3b/new_template_dialog.dart';
import 'package:admin_app/src/screens/f3b/template_list_view.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Screen 7 — Workshop Template List (Templates tab).
///
/// Pixel-perfect desktop layout matching Figma spec `06_7._Workshop_Template_List`.
/// Connects live data from `templatesProvider`. The showcase view still
/// carries Figma reference templates; the `adminShowcaseProvider` release
/// guard keeps it out of release builds until the Template List step wires
/// real data.
class TemplatesTab extends ConsumerStatefulWidget {
  const TemplatesTab({super.key, this.onNavSelected});

  final ValueChanged<int>? onNavSelected;

  @override
  ConsumerState<TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends ConsumerState<TemplatesTab> {
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

  Future<void> _onNewTemplate() async {
    final l10n = AppLocalizations.of(context);
    await NewTemplateDialog.show(
      context,
      onCreate: ({
        required String name,
        required String description,
        required String serviceType,
        required String vehicleType,
      }) async {
        try {
          final template = await ref.read(adminApiProvider).createTemplate(
                name: name,
                description: description,
                serviceType: serviceType,
                vehicleType: vehicleType,
              );
          ref.invalidate(templatesProvider);
          if (mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TemplateBuilderPage(templateId: template.id),
              ),
            );
            ref.invalidate(templatesProvider);
          }
        } on Object {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.actionFailed)),
            );
          }
        }
      },
    );
  }

  void _onEditTemplate(String templateId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateBuilderPage(templateId: templateId),
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
    // Release guard (Step 2a): the showcase view below still carries
    // fixture copy. Until the Template List step wires it, release builds
    // show a neutral empty state instead. This row is removed at that step.
    final showcase = ref.watch(adminShowcaseProvider);
    final templatesAsync = ref.watch(templatesProvider);
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;

    final displayName = session?.user.displayName.trim();
    final userRole = session != null
        ? (session.role.name == 'workshopAdmin' ? 'Lead Inspector' : session.role.name)
        : null;

    final templates = templatesAsync.value;

    final l10n = AppLocalizations.of(context);
    if (!showcase) {
      return Center(
        child: EmptyState(title: l10n.templatesTab, body: l10n.noResults),
      );
    }

    return WorkshopTemplateListView(
      selectedNavIndex: 3,
      onNavSelected: _onNavSelected,
      onNewTemplate: _onNewTemplate,
      onEditTemplate: _onEditTemplate,
      onSearch: (_) => setState(() {}),
      searchController: _search,
      onSignOut: _onSignOut,
      onToggleLocale: _onToggleLocale,
      userName: displayName,
      userRole: userRole,
      templates: templates,
    );
  }
}
