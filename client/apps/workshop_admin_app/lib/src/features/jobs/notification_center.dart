import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Notification list used by the shell bell and the pushed notifications page.
///
/// Presentation only: the same provider, unread filter and mark-read API as
/// before. The page title lives in the host page, so this widget stays a
/// toolbar + list rather than a second header.
class NotificationCenterTab extends ConsumerStatefulWidget {
  const NotificationCenterTab({super.key});

  @override
  ConsumerState<NotificationCenterTab> createState() =>
      _NotificationCenterTabState();
}

class _NotificationCenterTabState extends ConsumerState<NotificationCenterTab> {
  bool _unreadOnly = false;
  final Set<String> _marking = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifications = ref.watch(notificationsProvider(_unreadOnly));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(notificationsProvider(_unreadOnly)),
      child: WorkshopPageScroll(
        children: [
          WorkshopToolbar(
            filters: [
              WorkshopFilterChip(
                label: l10n.filterAll,
                selected: !_unreadOnly,
                onTap: () => setState(() => _unreadOnly = false),
              ),
              WorkshopFilterChip(
                key: const Key('jobs-unread-only'),
                label: l10n.jobsNotificationsUnreadOnly,
                selected: _unreadOnly,
                onTap: () => setState(() => _unreadOnly = true),
              ),
            ],
            trailing: WorkshopIconButton(
              icon: Icons.refresh,
              semanticLabel: l10n.refresh,
              onPressed: () =>
                  ref.invalidate(notificationsProvider(_unreadOnly)),
            ),
          ),
          SizedBox(height: context.spacing.lg),
          notifications.when(
            loading: () => const WorkshopSkeleton(card: true, lines: 4),
            error: (error, _) => WorkshopErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(notificationsProvider(_unreadOnly)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return WorkshopEmptyState(
                  title: l10n.jobsNotificationsEmpty,
                  icon: Icons.notifications_none_outlined,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) SizedBox(height: context.spacing.md),
                    _NotificationCard(
                      item: items[index],
                      marking: _marking.contains(items[index].id),
                      onMarkRead: () => _markRead(items[index]),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _markRead(WorkshopNotification item) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _marking.add(item.id));
    try {
      await ref.read(adminApiProvider).readNotification(item.id);
      ref.invalidate(notificationsProvider(false));
      ref.invalidate(notificationsProvider(true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.jobsNotificationsMarkedRead)),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.commonActionFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _marking.remove(item.id));
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.marking,
    required this.onMarkRead,
  });

  final WorkshopNotification item;
  final bool marking;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    return WorkshopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.type,
                      textDirection: TextDirection.ltr,
                      style: ws.bodyStrong.copyWith(color: ws.ink),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      formatInstant(context, item.createdAt),
                      style: ws.meta.copyWith(color: ws.muted),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              WorkshopStatusBadge(
                label: item.isRead
                    ? l10n.jobsNotificationsRead
                    : l10n.jobsNotificationsUnread,
                tone: item.isRead
                    ? WorkshopStatusTone.neutral
                    : WorkshopStatusTone.warning,
              ),
            ],
          ),
          if ((item.payloadJson ?? '').isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            SelectableText(
              item.payloadJson!,
              textDirection: TextDirection.ltr,
              style: ws.meta.copyWith(color: ws.muted),
            ),
          ],
          if (!item.isRead) ...[
            SizedBox(height: spacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: WorkshopButton(
                key: Key('jobs-mark-read-${item.id}'),
                label: l10n.jobsNotificationsMarkRead,
                icon: Icons.done_all,
                variant: WorkshopButtonVariant.secondary,
                isLoading: marking,
                onPressed: marking ? null : onMarkRead,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
