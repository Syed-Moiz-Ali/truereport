import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_pills.dart';
import 'package:workshop_admin_app/src/features/jobs/job_widgets.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

/// Notification list used by the shell bell and the pushed notifications page.
///
/// Presentation only: the same provider, unread filter and mark-read API as
/// before. The page title lives in the host page, so this surface is a filter
/// row plus one list of hairline rows rather than a second header.
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              JobPillChip(
                label: l10n.filterAll,
                selected: !_unreadOnly,
                onTap: () => setState(() => _unreadOnly = false),
              ),
              JobPillChip(
                key: const Key('jobs-unread-only'),
                label: l10n.jobsNotificationsUnreadOnly,
                selected: _unreadOnly,
                onTap: () => setState(() => _unreadOnly = true),
              ),
              JobPillButton(
                label: l10n.refresh,
                icon: Icons.refresh,
                variant: JobPillVariant.outline,
                compact: true,
                onPressed: () =>
                    ref.invalidate(notificationsProvider(_unreadOnly)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          notifications.when(
            loading: () => const WorkshopSkeleton(card: true, lines: 5),
            error: (error, _) => WorkshopErrorState(
              title: l10n.error,
              body: l10n.commonLoadFailed,
              retryLabel: l10n.retryAction,
              onRetry: () => ref.invalidate(notificationsProvider(_unreadOnly)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _EmptySurface(title: l10n.jobsNotificationsEmpty);
              }
              return _NotificationSurface(
                items: items,
                marking: _marking,
                onMarkRead: _markRead,
              );
            },
          ),
          const SizedBox(height: 28),
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

/// One bordered surface, one hairline row per notification.
class _NotificationSurface extends StatelessWidget {
  const _NotificationSurface({
    required this.items,
    required this.marking,
    required this.onMarkRead,
  });

  final List<WorkshopNotification> items;
  final Set<String> marking;
  final ValueChanged<WorkshopNotification> onMarkRead;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) Container(height: 1, color: ws.border),
            _NotificationRow(
              item: items[index],
              marking: marking.contains(items[index].id),
              onMarkRead: () => onMarkRead(items[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
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
    final unread = !item.isRead;
    final payload = item.payloadJson ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final action = unread
            ? JobPillButton(
                key: Key('jobs-mark-read-${item.id}'),
                label: l10n.jobsNotificationsMarkRead,
                icon: Icons.done_all,
                variant: JobPillVariant.outline,
                compact: true,
                loading: marking,
                onPressed: marking ? null : onMarkRead,
              )
            : null;
        return Container(
          color: unread
              ? ws.accentSoft.withValues(alpha: 0.4)
              : Colors.transparent,
          padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 6),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: unread ? ws.accent : ws.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.type,
                          textDirection: TextDirection.ltr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ws.bodyStrong.copyWith(color: ws.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatInstant(context, item.createdAt),
                          style: ws.meta.copyWith(color: ws.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  WorkshopStatusBadge(
                    label: unread
                        ? l10n.jobsNotificationsUnread
                        : l10n.jobsNotificationsRead,
                    tone: unread
                        ? WorkshopStatusTone.warning
                        : WorkshopStatusTone.neutral,
                  ),
                  if (wide && action != null) ...[
                    const SizedBox(width: 10),
                    action,
                  ],
                ],
              ),
              if (payload.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 17),
                  child: SelectionArea(
                    child: Text(
                      payload,
                      textDirection: TextDirection.ltr,
                      style: ws.meta.copyWith(color: ws.muted, height: 1.45),
                    ),
                  ),
                ),
              ],
              if (!wide && action != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: action,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Designed empty state: a quiet icon plate, one sentence, no dead action.
class _EmptySurface extends StatelessWidget {
  const _EmptySurface({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 40, 24, 40),
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ws.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: ws.canvas, shape: BoxShape.circle),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 24,
              color: ws.muted,
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: ws.bodyStrong.copyWith(color: ws.ink),
            ),
          ),
        ],
      ),
    );
  }
}
