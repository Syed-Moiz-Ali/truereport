import 'package:admin_app/src/admin_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';

class AuditTab extends ConsumerWidget {
  const AuditTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final audit = ref.watch(auditProvider);
    return audit.when(
      loading: () => Padding(
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        child: const LoadingSkeleton(lines: 5),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(context.spacing.lg),
          child: ErrorState(
            title: l10n.error,
            body: l10n.genericError,
            onRetry: () => ref.invalidate(auditProvider),
            retryLabel: l10n.retryAction,
          ),
        ),
      ),
      data: (events) => events.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: EmptyState(
                  title: l10n.noResults,
                  body: l10n.auditHistory,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(auditProvider),
              child: ListView.separated(
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                itemCount: events.length,
                separatorBuilder: (_, _) =>
                    SizedBox(height: context.spacing.sm),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    child: AppListTile(
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: event.action,
                      subtitle:
                          '${event.occurredAt} · ${event.actorRole ?? ''} · ${event.entityType ?? ''}'
                          '${event.reasonCode == null ? '' : ' · ${event.reasonCode}'}',
                      trailing: event.metadataJson == null
                          ? null
                          : Tooltip(
                              message: event.metadataJson!,
                              child: const Icon(Icons.info_outline),
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
