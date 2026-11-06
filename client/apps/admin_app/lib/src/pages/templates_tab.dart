import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/pages/template_builder_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class TemplatesTab extends ConsumerWidget {
  const TemplatesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(templatesProvider);
    return templates.when(
      loading: () => Padding(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        child: const LoadingSkeleton(lines: 4),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: ErrorState(
            title: l10n.error,
            body: l10n.genericError,
            onRetry: () => ref.invalidate(templatesProvider),
            retryLabel: l10n.retryAction,
          ),
        ),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(templatesProvider),
        child: ListView(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          children: [
            SectionHeader(
              title: l10n.templates,
              action: AppButton(
                label: l10n.newTemplate,
                onPressed: () => _create(context, ref),
                icon: Icons.add,
              ),
            ),
            if (items.isEmpty)
              EmptyState(
                title: l10n.noResults,
                body: l10n.newTemplate,
                icon: Icons.dashboard_customize_outlined,
                action: AppButton(
                  label: l10n.newTemplate,
                  onPressed: () => _create(context, ref),
                  variant: AppButtonVariant.tonal,
                ),
              )
            else
              ...items.map(
                (template) => Padding(
                  padding: EdgeInsetsDirectional.only(
                    bottom: context.spacing.sm,
                  ),
                  child: Card(
                    child: AppListTile(
                      key: Key('template-${template.id}'),
                      leading: const Icon(Icons.dashboard_customize_outlined),
                      title: template.name,
                      subtitle:
                          '${template.serviceType} · v${template.currentVersion ?? '-'} · ${template.itemCount} ${l10n.itemsSelected}',
                      trailing: StatusChip(
                        label: template.status,
                        tone: template.status == 'PUBLISHED'
                            ? StatusTone.success
                            : template.status == 'RETIRED'
                            ? StatusTone.neutral
                            : StatusTone.warning,
                      ),
                      onTap: () => _open(context, ref, template.id),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    final description = TextEditingController();
    final serviceType = TextEditingController(text: 'FULL');
    final vehicleType = TextEditingController(text: 'CAR');
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newTemplate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: name, label: l10n.templateName),
              SizedBox(height: context.spacing.sm),
              AppTextField(
                controller: description,
                label: l10n.templateDescription,
                maxLines: 2,
              ),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: serviceType, label: l10n.serviceType),
              SizedBox(height: context.spacing.sm),
              AppTextField(controller: vehicleType, label: l10n.vehicleType),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: l10n.cancel,
            onPressed: () => Navigator.of(context).pop(false),
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
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                  ref.invalidate(templatesProvider);
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TemplateBuilderPage(templateId: template.id),
                    ),
                  );
                  ref.invalidate(templatesProvider);
                }
              } on Object {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
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
    if (created != true) {
      return;
    }
  }

  void _open(BuildContext context, WidgetRef ref, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateBuilderPage(templateId: id),
      ),
    );
  }
}
