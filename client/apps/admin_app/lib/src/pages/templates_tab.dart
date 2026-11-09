import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/pages/template_builder_page.dart';
import 'package:admin_app/src/screens/f3b/template_list_view.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

/// Screen 7 — Workshop Template List (Templates tab).
///
/// Pixel-perfect desktop layout matching Figma spec `06_7._Workshop_Template_List`.
/// Connects live data from `templatesProvider`, while gracefully displaying
/// Figma reference templates and metrics when live data is empty.
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
    final name = TextEditingController();
    final description = TextEditingController();
    final serviceType = TextEditingController(text: 'FULL');
    final vehicleType = TextEditingController(text: 'CAR');
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newTemplate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: name, label: l10n.templateName),
              SizedBox(height: ctx.spacing.sm),
              AppTextField(
                controller: description,
                label: l10n.templateDescription,
                maxLines: 2,
              ),
              SizedBox(height: ctx.spacing.sm),
              AppTextField(controller: serviceType, label: l10n.serviceType),
              SizedBox(height: ctx.spacing.sm),
              AppTextField(controller: vehicleType, label: l10n.vehicleType),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: AppButtonVariant.text,
          ),
          AppButton(
            label: l10n.create,
            onPressed: () async {
              try {
                final template = await ref
                    .read(adminApiProvider)
                    .createTemplate(
                      name: name.text.trim(),
                      description: description.text.trim(),
                      serviceType: serviceType.text.trim(),
                      vehicleType: vehicleType.text.trim(),
                    );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(true);
                  ref.invalidate(templatesProvider);
                }
                if (mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TemplateBuilderPage(templateId: template.id),
                    ),
                  );
                  ref.invalidate(templatesProvider);
                }
              } on Object {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text(l10n.actionFailed)));
                }
              }
            },
          ),
        ],
      ),
    );
    name.dispose();
    description.dispose();
    serviceType.dispose();
    vehicleType.dispose();
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
    final templatesAsync = ref.watch(templatesProvider);
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;

    final displayName = session?.user.displayName.trim();
    final userRole = session != null
        ? (session.role.name == 'workshopAdmin' ? 'Lead Inspector' : session.role.name)
        : null;

    final templates = templatesAsync.value;

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
