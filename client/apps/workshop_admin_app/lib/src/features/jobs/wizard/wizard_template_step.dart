import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Step 3: pick a published template version. Only real, available templates
/// from `availableTemplatesProvider` are offered.
class WizardTemplateStep extends ConsumerWidget {
  const WizardTemplateStep({
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    final templates = ref.watch(availableTemplatesProvider);
    return templates.when(
      loading: () => const WorkshopSkeleton(lines: 3),
      error: (error, _) => WorkshopErrorState(
        title: t(WorkshopAdminKeys.error),
        body: t(WorkshopAdminKeys.commonLoadFailed),
        retryLabel: t(WorkshopAdminKeys.retryAction),
        onRetry: () => ref.invalidate(availableTemplatesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return WorkshopEmptyState(
            title: t(WorkshopAdminKeys.jobsTemplatesEmpty),
            icon: Icons.dashboard_customize_outlined,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t(WorkshopAdminKeys.jobsTemplatesAvailable),
              style: context.ws.bodyStrong,
            ),
            SizedBox(height: spacing.sm),
            for (final template in items) ...[
              WorkshopOptionCard<String>(
                key: Key('jobs-template-${template.versionId}'),
                value: template.versionId,
                groupValue: selectedId ?? '',
                onChanged: onSelected,
                title:
                    '${localizedText(context, en: template.nameEn, ar: template.nameAr)}'
                    ' · v${formatNumber(context, template.versionNo)}',
                caption: t(WorkshopAdminKeys.technicianItemsCount, {
                  'count': template.itemCount,
                }),
              ),
              SizedBox(height: spacing.sm),
            ],
          ],
        );
      },
    );
  }
}
