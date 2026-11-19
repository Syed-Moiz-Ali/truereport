import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

/// One surface, hairline rows. Items are server-evaluated; the client never
/// upgrades a failed item or invents a missing one.
class ChecklistItems extends StatelessWidget {
  const ChecklistItems({required this.items, super.key});

  final List<ChecklistEntry> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final header = WorkshopSectionHeader(title: l10n.checklist);
    final body = items.isEmpty
        ? WorkshopCard(
            child: Text(
              l10n.jobsChecklistNotReady,
              style: ws.body.copyWith(color: ws.muted),
            ),
          )
        : WorkshopCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const WorkshopDivider(),
                  _ChecklistRow(item: items[index]),
                ],
              ],
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        SizedBox(height: spacing.sm),
        body,
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item});

  final ChecklistEntry item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkshopStatusBadge(
            key: Key('jobs-checklist-${item.code}'),
            label: item.passed
                ? l10n.jobsChecklistPassed
                : l10n.jobsChecklistFailed,
            tone: item.passed
                ? WorkshopStatusTone.success
                : WorkshopStatusTone.danger,
            icon: item.passed
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              localizedText(context, en: item.messageEn, ar: item.messageAr),
              style: ws.body.copyWith(color: ws.ink),
            ),
          ),
        ],
      ),
    );
  }
}
