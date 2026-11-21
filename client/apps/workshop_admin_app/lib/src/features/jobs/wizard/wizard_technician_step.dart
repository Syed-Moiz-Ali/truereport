import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/reference_status.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_choice_group.dart';

/// Step 4: technician (or assign later), the customer's preferred language,
/// and public-link consent. Consent can be recorded at creation; otherwise it
/// is recorded from the approve/publish surfaces before the server will accept.
class WizardTechnicianStep extends ConsumerWidget {
  const WizardTechnicianStep({
    required this.selectedId,
    required this.onSelected,
    required this.preferredLanguage,
    required this.onPreferredLanguage,
    required this.scheduledAt,
    required this.onPickSchedule,
    required this.onStartImmediately,
    required this.consentGranted,
    required this.onConsentChanged,
    super.key,
  });

  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String preferredLanguage;
  final ValueChanged<String> onPreferredLanguage;
  final DateTime? scheduledAt;
  final VoidCallback onPickSchedule;
  final VoidCallback onStartImmediately;
  final bool consentGranted;
  final ValueChanged<bool> onConsentChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = UiStrings.of(context);
    final spacing = context.spacing;
    final staff = ref.watch(staffProvider);
    final consentStatuses = ref.watch(statusesProvider('consent')).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t(WorkshopAdminKeys.jobsWhenTitle), style: context.ws.bodyStrong),
        SizedBox(height: spacing.sm),
        WorkshopOptionCard<String>(
          key: const Key('jobs-wizard-start-now'),
          value: 'now',
          groupValue: scheduledAt == null ? 'now' : 'later',
          onChanged: (_) => onStartImmediately(),
          title: t(WorkshopAdminKeys.jobsStartNow),
          caption: t(WorkshopAdminKeys.jobsStartNowBody),
          leading: const Icon(Icons.bolt_outlined),
        ),
        SizedBox(height: spacing.sm),
        WorkshopOptionCard<String>(
          key: const Key('jobs-wizard-schedule-later'),
          value: 'later',
          groupValue: scheduledAt == null ? 'now' : 'later',
          onChanged: (_) => onPickSchedule(),
          title: t(WorkshopAdminKeys.jobsScheduleLater),
          caption: scheduledAt == null
              ? t(WorkshopAdminKeys.jobsScheduleLaterBody)
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
              label: Text(t(WorkshopAdminKeys.jobsClearSchedule)),
            ),
          ),
        ],
        SizedBox(height: spacing.lg),
        Text(
          t(WorkshopAdminKeys.jobsSelectTechnician),
          style: context.ws.bodyStrong,
        ),
        SizedBox(height: spacing.sm),
        WorkshopOptionCard<String>(
          key: const Key('jobs-technician-later'),
          value: '',
          groupValue: selectedId ?? '',
          onChanged: (_) => onSelected(null),
          title: t(WorkshopAdminKeys.jobsAssignLater),
          caption: t(WorkshopAdminKeys.scheduleJobSubtitle),
        ),
        SizedBox(height: spacing.sm),
        staff.when(
          loading: () => const WorkshopSkeleton(lines: 2),
          error: (error, _) => WorkshopInlineNote(
            text: t(WorkshopAdminKeys.commonLoadFailed),
            icon: Icons.error_outline,
          ),
          data: (members) {
            final technicians = members
                .where((member) => member.role == 'TECHNICIAN')
                .toList(growable: false);
            if (technicians.isEmpty) {
              return WorkshopInlineNote(
                text: t(WorkshopAdminKeys.jobsSelectTechnician),
              );
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
        _PreferredLanguageChoice(
          label: t(WorkshopAdminKeys.jobsFieldPreferredLanguage),
          selected: preferredLanguage,
          onChanged: onPreferredLanguage,
        ),
        SizedBox(height: spacing.lg),
        Text(
          t(WorkshopAdminKeys.consentPublicLink),
          style: context.ws.bodyStrong,
        ),
        SizedBox(height: spacing.sm),
        WorkshopOptionCard<bool>(
          key: const Key('jobs-wizard-consent'),
          value: true,
          groupValue: consentGranted,
          onChanged: (_) => onConsentChanged(!consentGranted),
          title: t(WorkshopAdminKeys.consentPublicLink),
          caption: referenceStatusText(
            consentStatuses,
            consentStatusCode(consentGranted),
          ),
          leading: const Icon(Icons.verified_user_outlined),
        ),
      ],
    );
  }
}

/// The customer's report language, taken from the languages the backend
/// advertises for this client. Each chip shows the manifest `nativeName`; the
/// operator's current UI language is the default (see `WizardFormState`).
class _PreferredLanguageChoice extends ConsumerWidget {
  const _PreferredLanguageChoice({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(
      languageSelectionProvider(adminUiMessageClient),
    );
    final languages =
        selection.manifest?.languages ?? const <UiMessageLanguage>[];
    final codes = languages.isEmpty
        ? <String>[selected]
        : languages.map((language) => language.code).toList(growable: false);
    String labelFor(String code) {
      for (final language in languages) {
        if (language.code == code && language.displayName.isNotEmpty) {
          return language.displayName;
        }
      }
      return code.toUpperCase();
    }

    return WizardChoiceGroup(
      label: label,
      values: codes,
      selected: selected,
      onChanged: onChanged,
      keyPrefix: 'jobs-wizard-language',
      labelFor: labelFor,
    );
  }
}
