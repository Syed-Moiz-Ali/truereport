import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_chrome.dart';
import 'package:workshop_admin_app/src/features/jobs/notification_center.dart';

/// Pushed notification page used by the shell bell.
///
/// The page owns the 60 px bar; [NotificationCenterTab] owns the filters and
/// the list so there is never a duplicate heading.
class WorkshopNotificationsPage extends StatelessWidget {
  const WorkshopNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = UiStrings.of(context);
    return Scaffold(
      backgroundColor: context.ws.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JobTitleBar(title: t(WorkshopAdminKeys.jobsNotificationsTitle)),
            const Expanded(child: NotificationCenterTab()),
          ],
        ),
      ),
    );
  }
}
