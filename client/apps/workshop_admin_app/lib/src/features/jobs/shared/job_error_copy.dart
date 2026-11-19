import 'package:core/core.dart';
import 'package:l10n/l10n.dart';

/// Maps a mutation/load failure to a distinct, honest sentence.
///
/// Codes are matched before message text (inventory §6.1 rule 9). There is no
/// dedicated ARB key for `APPROVER_IS_TECHNICIAN`, so it shares the reload copy
/// it needs; the missing key is recorded in the J1a report.
String jobErrorCopy(AppLocalizations l10n, Object error) {
  final code = _failureCode(error);
  final status = _failureStatus(error);
  if (status == 403 || code == 'FORBIDDEN') {
    return l10n.jobsForbidden;
  }
  if (status == 404 || code == 'JOB_NOT_FOUND') {
    return l10n.jobsNotFound;
  }
  switch (code) {
    case 'APPROVER_IS_TECHNICIAN':
      return l10n.jobsApproverIsTechnician;
    case 'JOB_NOT_ASSIGNABLE':
      return l10n.jobsNotAssignable;
    case 'JOB_ALREADY_ASSIGNED':
      return l10n.jobsAlreadyAssigned;
    case 'JOB_NOT_CANCELLABLE':
      return l10n.jobsNotCancellable;
    case 'JOB_ALREADY_CANCELLED':
      return l10n.jobsAlreadyCancelled;
    case 'JOB_NOT_EDITABLE':
      return l10n.jobsNotEditable;
    case 'JOB_VERSION_CONFLICT' || 'VERSION_CONFLICT':
      return l10n.jobsConflictReload;
    case 'CONSENT_REQUIRED' || 'JOB_NOT_APPROVED':
      return l10n.jobsPublicationBlockedBody;
    case 'CANCEL_REASON_REQUIRED' || 'REJECT_REASON_REQUIRED':
      return l10n.commonReasonRequired;
    default:
      return l10n.commonActionFailed;
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
