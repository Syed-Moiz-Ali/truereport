import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    required this.scheduledAt,
    required this.onPickSchedule,
    required this.onStartImmediately,
    super.key,
  });

  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String preferredLanguage;
  final ValueChanged<String> onPreferredLanguage;
  final DateTime? scheduledAt;
  final VoidCallback onPickSchedule;
  final VoidCallback onStartImmediately;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final staff = ref.watch(staffProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.jobsWhenTitle, style: context.ws.bodyStrong),
        SizedBox(height: spacing.sm),
        WorkshopOptionCard<String>(
          key: const Key('jobs-wizard-start-now'),
          value: 'now',
          groupValue: scheduledAt == null ? 'now' : 'later',
          onChanged: (_) => onStartImmediately(),
          title: l10n.jobsStartNow,
          caption: l10n.jobsStartNowBody,
          leading: const Icon(Icons.bolt_outlined),
        ),
        SizedBox(height: spacing.sm),
        WorkshopOptionCard<String>(
          key: const Key('jobs-wizard-schedule-later'),
          value: 'later',
          groupValue: scheduledAt == null ? 'now' : 'later',
          onChanged: (_) => onPickSchedule(),
          title: l10n.jobsScheduleLater,
          caption: scheduledAt == null
              ? l10n.jobsScheduleLaterBody
              : DateFormat.yMd(Localizations.localeOf(context).toString())
                    .add_Hm()
                    .format(scheduledAt!),
          leading: const Icon(Icons.event_outlined),
        ),
        if (scheduledAt != null) ...[
          SizedBox(height: spacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('jobs-wizard-clear-schedule'),
              onPressed: onStartImmediately,
              icon: const Icon(Icons.close, size: 16),
              label: Text(l10n.jobsClearSchedule),
            ),
          ),
        ],
        SizedBox(height: spacing.lg),
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
          values: const ['en'],
          selected: preferredLanguage,
          onChanged: onPreferredLanguage,
          keyPrefix: 'jobs-wizard-language',
          labelFor: (value) => l10n.languageEnglish,
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
