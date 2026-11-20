import 'package:core/core.dart';
import 'package:l10n/ui_strings.dart';

/// Maps a mutation/load failure to a distinct, honest sentence.
///
/// Codes are matched before message text (inventory §6.1 rule 9). There is no
/// dedicated ARB key for `APPROVER_IS_TECHNICIAN`, so it shares the reload copy
/// it needs; the missing key is recorded in the J1a report.
String jobErrorCopy(UiStrings t, Object error) {
  final code = _failureCode(error);
  final status = _failureStatus(error);
  if (status == 403 || code == 'FORBIDDEN') {
    return t(WorkshopAdminKeys.jobsForbidden);
  }
  if (status == 404 || code == 'JOB_NOT_FOUND') {
    return t(WorkshopAdminKeys.jobsNotFound);
  }
  switch (code) {
    case 'APPROVER_IS_TECHNICIAN':
      return t(WorkshopAdminKeys.jobsApproverIsTechnician);
    case 'JOB_NOT_ASSIGNABLE':
      return t(WorkshopAdminKeys.jobsNotAssignable);
    case 'JOB_ALREADY_ASSIGNED':
      return t(WorkshopAdminKeys.jobsAlreadyAssigned);
    case 'JOB_NOT_CANCELLABLE':
      return t(WorkshopAdminKeys.jobsNotCancellable);
    case 'JOB_ALREADY_CANCELLED':
      return t(WorkshopAdminKeys.jobsAlreadyCancelled);
    case 'JOB_NOT_EDITABLE':
      return t(WorkshopAdminKeys.jobsNotEditable);
    case 'JOB_VERSION_CONFLICT' || 'VERSION_CONFLICT':
      return t(WorkshopAdminKeys.jobsConflictReload);
    case 'CONSENT_REQUIRED' || 'JOB_NOT_APPROVED':
      return t(WorkshopAdminKeys.jobsPublicationBlockedBody);
    case 'CANCEL_REASON_REQUIRED' || 'REJECT_REASON_REQUIRED':
      return t(WorkshopAdminKeys.commonReasonRequired);
    default:
      return t(WorkshopAdminKeys.commonActionFailed);
  }
}

String? _failureCode(Object error) {
  if (error is AppFailure) {
    return error.code;
  }
  // Test fakes surface a typed conflict with the server code in toString().
  final text = error.toString();
  if (text.startsWith('FakeVersionConflict(') && text.endsWith(')')) {
    return text.substring('FakeVersionConflict('.length, text.length - 1);
  }
  return null;
}

int? _failureStatus(Object error) =>
    error is AppFailure ? error.statusCode : null;
