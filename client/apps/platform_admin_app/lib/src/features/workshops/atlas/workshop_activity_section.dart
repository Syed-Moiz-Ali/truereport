import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

import '../../../platform_catalogue_models.dart';
import '../../../platform_providers.dart';
import '../../../platform_theme.dart';
import '../workshop_activity.dart';
import 'atlas_ui.dart';

/// Activity tab: workshop-scoped audit trail inside a single ruled surface.
class WorkshopActivitySection extends ConsumerWidget {
  const WorkshopActivitySection({super.key, required this.workshopId});

  final String workshopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(uiStringsProvider);
    final events = ref.watch(auditEventsProvider);
    return events.when(
      loading: () => const AtlasSurface(
        padding: EdgeInsets.zero,
        child: AtlasSkeletonRows(rows: 4, height: 64),
      ),
      error: (_, _) => AtlasSurface(
        child: Row(
          children: [
            Expanded(
              child: Text(
                strings.tKey(CommonKeys.stateError),
                style: Atlas.text(12.5, weight: FontWeight.w600),
              ),
            ),
            AtlasButton(
              label: strings.tKey(CommonKeys.buttonRetry),
              variant: AtlasButtonVariant.secondary,
              compact: true,
              onPressed: () => ref.invalidate(auditEventsProvider),
            ),
          ],
        ),
      ),
      data: (all) {
        final filtered = all
            .where(
              (event) =>
                  event.entityId == workshopId ||
                  event.metadataJson.contains(workshopId),
            )
            .toList(growable: false);
        if (filtered.isEmpty) {
          return AtlasSurface(
            child: AtlasEmpty(
              icon: Icons.history_toggle_off_rounded,
              title: strings.tKey(PlatformAdminKeys.emptyActivityTitle),
              actionLabel: strings.tKey(PlatformAdminKeys.buttonAuditViewAll),
              onAction: () => context.go('/audit-log'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.tKey(PlatformAdminKeys.tabWorkshopActivity),
                    style: Atlas.sectionTitle,
                  ),
                ),
                AtlasButton(
                  label: strings.tKey(PlatformAdminKeys.buttonAuditViewAll),
                  icon: Icons.arrow_outward_rounded,
                  variant: AtlasButtonVariant.secondary,
                  compact: true,
                  onPressed: () => context.go('/audit-log'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AtlasSurface(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < filtered.length; i++)
                    _ActivityRow(
                      strings: strings,
                      event: filtered[i],
                      last: i == filtered.length - 1,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.strings,
    required this.event,
    required this.last,
  });

  final UiMessageStrings strings;
  final PlatformAuditEvent event;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final role = event.actorRole.isNotEmpty
        ? auditRoleLabel(strings, event.actorRole)
        : '—';
    final reason = event.reasonCode.isNotEmpty
        ? auditReasonLabel(strings, event.reasonCode)
        : '—';
    final when = event.occurredAt.isNotEmpty
        ? auditTimestampLabel(
            event.occurredAt,
            Localizations.localeOf(context).toString(),
          )
        : strings.tKey(CommonKeys.emptyTitle);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: PtTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Atlas.neutralTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 17,
              color: PtTheme.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  auditActionLabel(strings, event.action),
                  style: Atlas.text(13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(when, style: Atlas.text(11, color: PtTheme.muted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _Meta(
                      label: strings.tKey(CommonKeys.tableRole),
                      value: role,
                    ),
                    _Meta(
                      label: strings.tKey(CommonKeys.fieldReason),
                      value: reason,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: Atlas.text(10.5, color: PtTheme.muted),
          ),
          TextSpan(
            text: value,
            style: Atlas.text(10.5, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
