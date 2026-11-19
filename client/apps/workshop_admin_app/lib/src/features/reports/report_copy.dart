import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Screen copy for the certificate layout.
///
/// Every string that already has a shared key reads it from
/// [AppLocalizations]; the handful of certificate-specific labels that have no
/// key yet live here with their Arabic counterpart so the screen never renders
/// English inside an Arabic page. Moving them into the l10n package is the
/// follow-up (see the build report).
class ReportCopy {
  const ReportCopy(this.l10n, {required this.isArabic});

  final AppLocalizations l10n;
  final bool isArabic;

  String _pick(String en, String ar) => isArabic ? ar : en;

  String get eyebrow => _pick('TRUEREPORT · INSPECTION', 'ترو ريبورت · فحص');

  String get title => _pick('Vehicle inspection report', 'تقرير فحص المركبة');

  String get reportFallback => l10n.report;

  String get distribution => _pick('Distribution', 'التوزيع');

  String get delivered => _pick('delivered', 'تم التسليم');

  String get checks => _pick('Checks', 'الفحوصات');

  String get safety => _pick('Safety', 'السلامة');

  String get coverageNote =>
      _pick('completed of applicable', 'مكتملة من أصل قابل للفحص');

  String get coverageLabel => l10n.coverage;

  String get scoreLabel => _pick('Score', 'الدرجة');

  String get scoreScale => _pick('out of 100', 'من 100');

  String get safetyCapLabel =>
      _pick('Safety cap applied', 'تم تطبيق حد السلامة');

  String get noSafetyCritical =>
      _pick('No safety-critical finding', 'لا توجد ملاحظات حرجة للسلامة');

  String get findingsByCategory =>
      _pick('Findings by category', 'الملاحظات حسب الفئة');

  String get noKeyFindings => _pick(
    'No key findings were recorded for this inspection.',
    'لم تُسجّل ملاحظات رئيسية لهذا الفحص.',
  );

  String get noCategoryFindings =>
      _pick('No category findings were recorded.', 'لم تُسجّل ملاحظات فئوية.');

  String get noLinkYet => _pick('No link created yet', 'لم يُنشأ رابط بعد');

  String get customer => _pick('Customer', 'العميل');

  String get inUse => _pick('On', 'مفعّل');

  String get notInUse => _pick('Off', 'معطّل');

  String get scope => _pick('Scope', 'النطاق');

  String get inspectedBy => _pick('Inspected by', 'فحص بواسطة');

  String get workshop => _pick('Workshop', 'الورشة');

  String get vin => _pick('VIN', 'رقم الهيكل');

  String get severity => l10n.severity;
}

extension ReportCopyContext on BuildContext {
  ReportCopy get reportCopy =>
      ReportCopy(AppLocalizations.of(this), isArabic: isArabic);
}

/// READY / FAILED / PENDING badge copy. Preserved from the previous screen.
String generationLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'READY' => l10n.reportReady,
      'FAILED' => l10n.reportFailed,
      'PENDING' || 'GENERATING' => l10n.generating,
      _ => status,
    };

WorkshopStatusTone generationTone(String status) => switch (status) {
  'READY' => WorkshopStatusTone.success,
  'FAILED' => WorkshopStatusTone.danger,
  _ => WorkshopStatusTone.warning,
};

/// ACTIVE / REVOKED / PENDING_CONSENT link pill.
String linkLabel(AppLocalizations l10n, String state) => switch (state) {
  'ACTIVE' => l10n.linkActive,
  'REVOKED' => l10n.linkRevoked,
  'PENDING_CONSENT' => l10n.linkPendingConsent,
  _ => state,
};

WorkshopStatusTone linkTone(String state) => switch (state) {
  'ACTIVE' => WorkshopStatusTone.success,
  'REVOKED' => WorkshopStatusTone.danger,
  'PENDING_CONSENT' => WorkshopStatusTone.warning,
  _ => WorkshopStatusTone.neutral,
};

IconData linkIcon(String state) => switch (state) {
  'ACTIVE' => Icons.link,
  'REVOKED' => Icons.link_off,
  _ => Icons.schedule,
};

WorkshopStatusTone deliveryTone(String status) {
  if (status == 'SENT' || status == 'DELIVERED') {
    return WorkshopStatusTone.success;
  }
  if (status == 'FAILED' || status == 'DEAD_LETTER') {
    return WorkshopStatusTone.danger;
  }
  return WorkshopStatusTone.warning;
}

IconData channelIcon(String channel) => switch (channel) {
  'EMAIL' => Icons.mail_outline,
  'SMS' => Icons.sms_outlined,
  _ => Icons.chat_outlined,
};

String consentLabel(AppLocalizations l10n, String state) => switch (state) {
  'GRANTED' => l10n.consentGranted,
  'REFUSED' => l10n.consentRefused,
  'WITHDRAWN' => l10n.consentWithdrawn,
  _ => state,
};

/// Inspection result labels read from the shared keys when the result code is
/// one the app knows; anything else falls through as the raw code so no data is
/// invented or dropped.
String resultLabel(AppLocalizations l10n, String code) => switch (code) {
  'NO_ISSUE_OBSERVED' => l10n.noIssueObserved,
  'ATTENTION_RECOMMENDED' => l10n.attentionRecommended,
  'DEFECT_FOUND' => l10n.defectFound,
  'NOT_CHECKED' => l10n.notChecked,
  'NOT_APPLICABLE' => l10n.notApplicable,
  'COULD_NOT_VERIFY' => l10n.couldNotVerify,
  _ => code,
};

String severityLabel(AppLocalizations l10n, String code) => switch (code) {
  'MINOR' => l10n.minor,
  'MODERATE' => l10n.moderate,
  'MAJOR' => l10n.major,
  'SAFETY_CRITICAL' => l10n.safetyCritical,
  _ => code,
};

WorkshopStatusTone severityTone(String code) => switch (code) {
  'SAFETY_CRITICAL' => WorkshopStatusTone.danger,
  'MAJOR' => WorkshopStatusTone.danger,
  'MODERATE' => WorkshopStatusTone.warning,
  'MINOR' => WorkshopStatusTone.warning,
  _ => WorkshopStatusTone.neutral,
};
