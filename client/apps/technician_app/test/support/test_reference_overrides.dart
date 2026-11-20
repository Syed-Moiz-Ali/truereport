import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:reference_data/reference_data.dart';

/// Served status records for widget tests.
///
/// Production never owns these lists: they come from
/// `/api/v1/reference/statuses/{type}`. Tests pin a small served set so a
/// widget can resolve labels/tones without a network or a local map.
const List<ReferenceRecord> testJobStatuses = <ReferenceRecord>[
  ReferenceRecord(code: 'SCHEDULED', labelKey: 'statusScheduled', tone: 'info'),
  ReferenceRecord(code: 'ASSIGNED', labelKey: 'statusAssigned', tone: 'info'),
  ReferenceRecord(
    code: 'IN_PROGRESS',
    labelKey: 'statusInProgress',
    tone: 'warning',
  ),
  ReferenceRecord(
    code: 'PENDING_REVIEW',
    labelKey: 'jobsStatusPendingReview',
    tone: 'warning',
  ),
  ReferenceRecord(
    code: 'APPROVED',
    labelKey: 'jobsStatusApproved',
    tone: 'success',
  ),
  ReferenceRecord(
    code: 'PUBLISHED',
    labelKey: 'jobsStatusPublished',
    tone: 'success',
  ),
  ReferenceRecord(
    code: 'CANCELLED',
    labelKey: 'statusCancelled',
    tone: 'neutral',
  ),
];

const List<ReferenceRecord> testSyncStatuses = <ReferenceRecord>[
  ReferenceRecord(
    code: 'ONLINE',
    labelKey: 'technicianSyncOnline',
    tone: 'success',
  ),
  ReferenceRecord(
    code: 'OFFLINE',
    labelKey: 'technicianSyncOffline',
    tone: 'neutral',
  ),
  ReferenceRecord(
    code: 'PENDING',
    labelKey: 'technicianSyncPending',
    tone: 'warning',
  ),
  ReferenceRecord(
    code: 'SYNCING',
    labelKey: 'technicianSyncStateSyncing',
    tone: 'info',
  ),
  ReferenceRecord(
    code: 'CONFLICT',
    labelKey: 'technicianSyncStateConflict',
    tone: 'danger',
  ),
  ReferenceRecord(
    code: 'FAILED',
    labelKey: 'technicianSyncStateFailed',
    tone: 'danger',
  ),
];

const List<ReferenceRecord> testEvidenceStatuses = <ReferenceRecord>[
  ReferenceRecord(
    code: 'PENDING',
    labelKey: 'evidenceStatusPending',
    tone: 'warning',
  ),
  ReferenceRecord(
    code: 'UPLOADED',
    labelKey: 'evidenceStatusUploaded',
    tone: 'info',
  ),
  ReferenceRecord(
    code: 'VERIFIED',
    labelKey: 'evidenceStatusVerified',
    tone: 'success',
  ),
  ReferenceRecord(
    code: 'DELETED',
    labelKey: 'evidenceStatusDeleted',
    tone: 'neutral',
  ),
];

const List<ReferenceRecord> testResultEnums = <ReferenceRecord>[
  ReferenceRecord(
    code: 'NO_ISSUE_OBSERVED',
    labelKey: 'noIssueObserved',
    tone: 'success',
  ),
  ReferenceRecord(
    code: 'ATTENTION_RECOMMENDED',
    labelKey: 'attentionRecommended',
    tone: 'warning',
  ),
  ReferenceRecord(
    code: 'DEFECT_FOUND',
    labelKey: 'defectFound',
    tone: 'danger',
  ),
  ReferenceRecord(code: 'NOT_CHECKED', labelKey: 'notChecked', tone: 'warning'),
  ReferenceRecord(
    code: 'NOT_APPLICABLE',
    labelKey: 'notApplicable',
    tone: 'neutral',
  ),
  ReferenceRecord(
    code: 'COULD_NOT_VERIFY',
    labelKey: 'couldNotVerify',
    tone: 'warning',
  ),
];

const List<ReferenceRecord> testSeverityEnums = <ReferenceRecord>[
  ReferenceRecord(code: 'MINOR', labelKey: 'minor', tone: 'neutral'),
  ReferenceRecord(code: 'MODERATE', labelKey: 'moderate', tone: 'warning'),
  ReferenceRecord(code: 'MAJOR', labelKey: 'major', tone: 'danger'),
  ReferenceRecord(
    code: 'SAFETY_CRITICAL',
    labelKey: 'safetyCritical',
    tone: 'critical',
  ),
];

const List<ReferenceRecord> testEvidenceTypeEnums = <ReferenceRecord>[
  ReferenceRecord(code: 'PHOTO', labelKey: 'technicianPhoto', tone: 'info'),
  ReferenceRecord(code: 'VIDEO', labelKey: 'technicianVideo', tone: 'info'),
  ReferenceRecord(
    code: 'DOCUMENT',
    labelKey: 'technicianDocument',
    tone: 'info',
  ),
];

List<Override> testReferenceStatusOverrides() => <Override>[
  statusesProvider('job').overrideWith((ref) async => testJobStatuses),
  statusesProvider('sync').overrideWith((ref) async => testSyncStatuses),
  statusesProvider('evidence')
      .overrideWith((ref) async => testEvidenceStatuses),
  enumsProvider('result').overrideWith((ref) async => testResultEnums),
  enumsProvider('severity').overrideWith((ref) async => testSeverityEnums),
  enumsProvider('evidence-type')
      .overrideWith((ref) async => testEvidenceTypeEnums),
];
