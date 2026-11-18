import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/jobs/notification_center.dart';

/// Pushed notification page used by the shell bell.
///
/// The page owns the title bar; [NotificationCenterTab] owns the toolbar and
/// list so there is never a duplicate heading.
class WorkshopNotificationsPage extends StatelessWidget {
  const WorkshopNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final spacing = context.spacing;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: ws.surface,
                border: BorderDirectional(bottom: BorderSide(color: ws.border)),
              ),
              child: SizedBox(
                height: ws.topBarHeight,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: ws.pageGutter(MediaQuery.sizeOf(context).width),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: ws.contentMaxWidth),
                      child: Row(
                        children: [
                          WorkshopIconButton(
                            icon: isRtl
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            semanticLabel: l10n.commonBack,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          SizedBox(width: spacing.sm),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                l10n.jobsNotificationsTitle,
                                style: ws.bodyStrong.copyWith(color: ws.ink),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Expanded(child: NotificationCenterTab()),
          ],
        ),
      ),
    );
  }
}
