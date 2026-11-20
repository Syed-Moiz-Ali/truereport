import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

/// Screen copy for the certificate layout.
///
/// Every string that already has a shared key reads it from
/// [UiStrings]; the handful of certificate-specific labels that have no
/// key yet live here with their Arabic counterpart so the screen never renders
/// English inside an Arabic page. Moving them into the l10n package is the
/// follow-up (see the build report).
class ReportCopy {
  const ReportCopy(this.t);

  final UiStrings t;

  String get eyebrow => t(WorkshopAdminKeys.reportEyebrow);

  String get title => t(WorkshopAdminKeys.reportTitle);

  String get reportFallback => t(WorkshopAdminKeys.report);

  String get distribution => t(WorkshopAdminKeys.reportDistribution);

  String get delivered => t(WorkshopAdminKeys.reportDelivered);

  String get checks => t(WorkshopAdminKeys.reportChecks);

  String get safety => t(WorkshopAdminKeys.reportSafety);

  String get coverageNote => t(WorkshopAdminKeys.reportCoverageNote);

  String get coverageLabel => t(WorkshopAdminKeys.coverage);

  String get scoreLabel => t(WorkshopAdminKeys.reportScoreLabel);

  String get scoreScale => t(WorkshopAdminKeys.reportScoreScale);

  String get safetyCapLabel => t(WorkshopAdminKeys.reportSafetyCapApplied);

  String get noSafetyCritical => t(WorkshopAdminKeys.reportNoSafetyCritical);

  String get findingsByCategory =>
      t(WorkshopAdminKeys.reportFindingsByCategory);

  String get noKeyFindings => t(WorkshopAdminKeys.reportNoKeyFindings);

  String get noCategoryFindings =>
      t(WorkshopAdminKeys.reportNoCategoryFindings);

  String get noLinkYet => t(WorkshopAdminKeys.reportNoLinkYet);

  String get customer => t(WorkshopAdminKeys.reportCustomer);

  String get inUse => t(WorkshopAdminKeys.reportInUse);

  String get notInUse => t(WorkshopAdminKeys.reportNotInUse);

  String get scope => t(WorkshopAdminKeys.reportScope);

  String get inspectedBy => t(WorkshopAdminKeys.reportInspectedBy);

  String get workshop => t(WorkshopAdminKeys.reportWorkshop);

  String get vin => t(WorkshopAdminKeys.reportVin);

  String get severity => t(WorkshopAdminKeys.severity);
}

extension ReportCopyContext on BuildContext {
  ReportCopy get reportCopy => ReportCopy(UiStrings.of(this));
}

/// Link icon chosen from the state's shape, never from a label table.
IconData linkIcon(String state) => switch (state) {
  'ACTIVE' => Icons.link,
  'REVOKED' => Icons.link_off,
  _ => Icons.schedule,
};

IconData channelIcon(String channel) => switch (channel) {
  'EMAIL' => Icons.mail_outline,
  'SMS' => Icons.sms_outlined,
  _ => Icons.chat_outlined,
};
