import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

class NotificationCenterTab extends ConsumerStatefulWidget {
  const NotificationCenterTab({super.key});

  @override
  ConsumerState<NotificationCenterTab> createState() =>
      _NotificationCenterTabState();
}

class _NotificationCenterTabState
    extends ConsumerState<NotificationCenterTab> {
  bool _unreadOnly = false;
  final Set<String> _marking = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifications = ref.watch(notificationsProvider(_unreadOnly));
    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(notificationsProvider(_unreadOnly)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.all(context.spacing.lg),
        children: [
          WorkshopHeader(
            title: l10n.jobsNotificationsTitle,
            semanticLabel: l10n.jobsNotificationsTitle,
            actions: [
              AppButton(
                label: l10n.refresh,
                onPressed: () =>
                    ref.invalidate(notificationsProvider(_unreadOnly)),
                icon: Icons.refresh,
                variant: AppButtonVariant.text,
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),
          Wrap(
            spacing: context.spacing.sm,
            runSpacing: context.spacing.sm,
            children: [
              AppSelectableText(
                label: l10n.filterAll,
                selected: !_unreadOnly,
                onTap: () => setState(() => _unreadOnly = false),
              ),
              AppSelectableText(
                key: const Key('jobs-unread-only'),
                label: l10n.jobsNotificationsUnreadOnly,
                selected: _unreadOnly,
                onTap: () => setState(() => _unreadOnly = true),
              ),
            ],
          ),
          SizedBox(height: context.spacing.md),
          notifications.when(
            loading: () => const LoadingSkeleton(lines: 4),
            error: (error, _) => ErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () =>
                  ref.invalidate(notificationsProvider(_unreadOnly)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  title: l10n.jobsNotificationsEmpty,
                  body: '',
                  icon: Icons.notifications_none_outlined,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items)
                    _notificationCard(context, item),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(BuildContext context, WorkshopNotification item) {
    final l10n = AppLocalizations.of(context);
    final marking = _marking.contains(item.id);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: context.spacing.sm),
      child: JobPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: [
                StatusChip(
                  label: item.type,
                  tone: item.isRead ? StatusTone.neutral : StatusTone.info,
                  icon: item.isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                ),
                StatusChip(
                  label: item.isRead ? l10n.jobsNotificationsRead : l10n.jobsNotificationsUnread,
                  tone: item.isRead
                      ? StatusTone.neutral
                      : StatusTone.warning,
                  icon: item.isRead
                      ? Icons.done_all
                      : Icons.fiber_new_outlined,
                ),
              ],
            ),
            SizedBox(height: context.spacing.sm),
            JobKeyValue(
              label: l10n.commonCreatedAt,
              value: formatInstant(context, item.createdAt),
            ),
            JobKeyValue(
              label: l10n.jobsNotificationPayload,
              value: item.payloadJson ?? l10n.jobsNotificationNoPayload,
              valueDirection: TextDirection.ltr,
            ),
            if (!item.isRead) ...[
              SizedBox(height: context.spacing.sm),
              AppButton(
                key: Key('jobs-mark-read-${item.id}'),
                label: l10n.jobsNotificationsMarkRead,
                onPressed: marking ? null : () => _markRead(item),
                isLoading: marking,
                icon: Icons.done_all,
                variant: AppButtonVariant.tonal,
              ),
            ],
          ],
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonActionFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _marking.remove(item.id));
      }
    }
  }
}
