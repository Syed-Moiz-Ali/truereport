import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';

String technicianStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'DRAFT' => l10n.draft,
      'SCHEDULED' || 'Scheduled' => l10n.statusScheduled,
      'ASSIGNED' => l10n.statusAssigned,
      'IN_PROGRESS' => l10n.statusInProgress,
      'READY_TO_FINALIZE' => l10n.statusReadyToFinalize,
      'FINALIZED' => l10n.statusFinalized,
      'CANCELLED' => l10n.statusCancelled,
      'READY' || 'Ready' => 'Ready',
      'HIGH_PRIORITY' || 'High Priority' => 'High Priority',
      _ => l10n.notAvailable,
    };

StatusTone technicianStatusTone(String status) => switch (status) {
  'FINALIZED' => StatusTone.success,
  'CANCELLED' => StatusTone.danger,
  'ASSIGNED' || 'IN_PROGRESS' || 'READY_TO_FINALIZE' => StatusTone.info,
  'SCHEDULED' => StatusTone.warning,
  _ => StatusTone.neutral,
};

String resultLabel(AppLocalizations l10n, String result) => switch (result) {
  'NO_ISSUE_OBSERVED' => l10n.noIssueObserved,
  'ATTENTION_RECOMMENDED' => l10n.attentionRecommended,
  'DEFECT_FOUND' => l10n.defectFound,
  'NOT_CHECKED' => l10n.notChecked,
  'NOT_APPLICABLE' => l10n.notApplicable,
  'COULD_NOT_VERIFY' => l10n.couldNotVerify,
  _ => l10n.notAvailable,
};

String severityLabel(AppLocalizations l10n, String severity) =>
    switch (severity) {
      'MINOR' => l10n.minor,
      'MODERATE' => l10n.moderate,
      'MAJOR' => l10n.major,
      'SAFETY_CRITICAL' => l10n.safetyCritical,
      _ => l10n.notAvailable,
    };

StatusTone resultTone(String? result) => switch (result) {
  'NO_ISSUE_OBSERVED' => StatusTone.success,
  'ATTENTION_RECOMMENDED' => StatusTone.warning,
  'DEFECT_FOUND' => StatusTone.danger,
  'NOT_CHECKED' || 'COULD_NOT_VERIFY' => StatusTone.warning,
  'NOT_APPLICABLE' => StatusTone.neutral,
  _ => StatusTone.neutral,
};
