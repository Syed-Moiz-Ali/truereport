import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_choice_group.dart';

/// Step 4: technician (or assign later), the customer's preferred language,
/// and the honest consent state. Consent cannot be recorded in this version,
/// so the note states the consequence instead of promising a publish path.
class WizardTechnicianStep extends ConsumerWidget {
  const WizardTechnicianStep({
    required this.selectedId,
    required this.onSelected,
    required this.preferredLanguage,
    required this.onPreferredLanguage,
    super.key,
  });

  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String preferredLanguage;
  final ValueChanged<String> onPreferredLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final staff = ref.watch(staffProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.jobsSelectTechnician, style: context.ws.bodyStrong),
        SizedBox(height: spacing.sm),
        WorkshopOptionCard<String>(
          key: const Key('jobs-technician-later'),
          value: '',
          groupValue: selectedId ?? '',
          onChanged: (_) => onSelected(null),
          title: l10n.jobsAssignLater,
          caption: l10n.scheduleJobSubtitle,
        ),
        SizedBox(height: spacing.sm),
        staff.when(
          loading: () => const WorkshopSkeleton(lines: 2),
          error: (error, _) => WorkshopInlineNote(
            text: l10n.commonLoadFailed,
            icon: Icons.error_outline,
          ),
          data: (members) {
            final technicians = members
                .where((member) => member.role == 'TECHNICIAN')
                .toList(growable: false);
            if (technicians.isEmpty) {
              return WorkshopInlineNote(text: l10n.jobsSelectTechnician);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final technician in technicians) ...[
                  WorkshopOptionCard<String>(
                    key: Key('jobs-technician-${technician.userId}'),
                    value: technician.userId,
                    groupValue: selectedId ?? '',
                    onChanged: onSelected,
                    title: technician.displayName,
                    caption: technician.emailMasked,
                  ),
                  SizedBox(height: spacing.sm),
                ],
              ],
            );
          },
        ),
        SizedBox(height: spacing.md),
        WizardChoiceGroup(
          label: l10n.jobsFieldPreferredLanguage,
          values: const ['en', 'ar'],
          selected: preferredLanguage,
          onChanged: onPreferredLanguage,
          keyPrefix: 'jobs-wizard-language',
          labelFor: (value) =>
              value == 'ar' ? l10n.languageArabic : l10n.languageEnglish,
        ),
        SizedBox(height: spacing.lg),
        WorkshopInlineNote(
          key: const Key('jobs-consent-note'),
          text: l10n.jobsConsentUnavailableNote,
          icon: Icons.verified_user_outlined,
        ),
      ],
    );
  }
}
