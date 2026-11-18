import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_rows.dart';
import 'package:workshop_admin_app/src/features/dashboard/widgets/dashboard_states.dart';

/// A row after the page has translated it (labels, tone, verbs, callbacks).
///
/// Keeping this dumb is deliberate: the group widget never sees a model, a
/// provider or an `AppLocalizations`, so it can be gallery-tested in isolation.
@immutable
class DashboardRowData {
  const DashboardRowData({
    required this.id,
    required this.title,
    required this.meta,
    required this.statusLabel,
    required this.tone,
    required this.onOpen,
    this.verbLabel,
    this.onVerb,
  });

  final String id;
  final String title;
  final String meta;
  final String statusLabel;
  final WorkshopStatusTone tone;
  final VoidCallback onOpen;
  final String? verbLabel;
  final VoidCallback? onVerb;
}

/// One of the dashboard's three action groups. No card, no container: a header,
/// a rule per row, and honest loading/error/empty states.
class DashboardGroup extends StatelessWidget {
  const DashboardGroup({
    required this.swatch,
    required this.title,
    this.meta,
    required this.rows,
    required this.emptyText,
    required this.loadFailed,
    required this.retryLabel,
    required this.onRetry,
    required this.verbInline,
    required this.rowKeyPrefix,
    super.key,
  });

  final Color swatch;
  final String title;
  final String? meta;
  final AsyncValue<List<DashboardRowData>> rows;
  final String emptyText;
  final String loadFailed;
  final String retryLabel;
  final VoidCallback onRetry;
  final bool verbInline;
  final String rowKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    // A group whose list is empty must not print a count above "Nothing here
    // right now": the count comes from the workshop-wide counts endpoint, the
    // empty line comes from the filtered list, and together they contradict
    // each other on screen even when both are true.
    final listsNothing = rows.value?.isEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardGroupHeader(
          swatch: swatch,
          title: title,
          meta: listsNothing ? null : meta,
        ),
        SizedBox(height: spacing.xs),
        rows.when(
          loading: () => const DashboardRowsSkeleton(rows: 2),
          error: (error, _) => Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.sm),
            child: DashboardErrorLine(
              message: loadFailed,
              retryLabel: retryLabel,
              onRetry: onRetry,
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return DashboardGroupEmpty(text: emptyText);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in items)
                  DashboardJobRow(
                    rowKey: Key('$rowKeyPrefix-${item.id}'),
                    title: item.title,
                    meta: item.meta,
                    statusLabel: item.statusLabel,
                    statusTone: item.tone,
                    verbLabel: item.verbLabel,
                    onVerb: item.onVerb,
                    verbInline: verbInline,
                    onTap: item.onOpen,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
