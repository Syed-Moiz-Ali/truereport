import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/features/inspection/clean_shared.dart';
import 'package:technician_app/src/reference_ui.dart';
import 'package:technician_app/src/ui_helpers.dart';

void main() {
  const records = <ReferenceRecord>[
    ReferenceRecord(
      code: 'IN_PROGRESS',
      labelKey: 'statusInProgress',
      tone: 'warning',
    ),
    ReferenceRecord(
      code: 'SYNCING',
      labelKey: 'technicianSyncStateSyncing',
      tone: 'info',
    ),
    ReferenceRecord(
      code: 'VERIFIED',
      labelKey: 'evidenceStatusVerified',
      tone: 'success',
    ),
  ];

  test('labels and tones come from the served record', () {
    expect(
      referenceStatusCodeLabel(records, 'IN_PROGRESS'),
      remoteEnglish('statusInProgress'),
    );
    expect(referenceStatusCodeTone(records, 'IN_PROGRESS'), StatusTone.warning);
    expect(referenceStatusCodeTone(records, 'SYNCING'), StatusTone.info);
    expect(referenceStatusCodeTone(records, 'VERIFIED'), StatusTone.success);
  });

  test('codes match across case, spaces, dashes and underscores', () {
    expect(
      referenceRecordForStatus(records, 'in progress')?.code,
      'IN_PROGRESS',
    );
    expect(normalizeStatusCode('in-progress'), 'IN_PROGRESS');
  });

  test('an unknown or unloaded code is humanized, never mapped locally', () {
    expect(
      referenceStatusCodeLabel(const [], 'PENDING_REVIEW'),
      'Pending Review',
    );
    expect(referenceStatusCodeLabel(records, 'SOMETHING_NEW'), 'Something New');
    expect(referenceStatusCodeTone(const [], 'VERIFIED'), StatusTone.neutral);
  });

  test('tone tokens map only through the design-system vocabulary', () {
    expect(statusToneFromToken('danger'), StatusTone.danger);
    expect(statusToneFromToken('critical'), StatusTone.critical);
    expect(statusToneFromToken('unknown'), StatusTone.neutral);
  });

  test('result, severity and evidence labels come from served enums', () {
    const resultRecords = <ReferenceRecord>[
      ReferenceRecord(
        code: 'DEFECT_FOUND',
        labelKey: 'defectFound',
        tone: 'danger',
      ),
    ];
    const severityRecords = <ReferenceRecord>[
      ReferenceRecord(code: 'MAJOR', labelKey: 'major', tone: 'danger'),
    ];
    const evidenceRecords = <ReferenceRecord>[
      ReferenceRecord(code: 'PHOTO', labelKey: 'technicianPhoto', tone: 'info'),
    ];

    expect(
      resultLabel(resultRecords, 'DEFECT_FOUND'),
      remoteEnglish('defectFound'),
    );
    expect(resultTone(resultRecords, 'DEFECT_FOUND'), StatusTone.danger);
    expect(severityLabel(severityRecords, 'MAJOR'), remoteEnglish('major'));
    expect(
      evidenceTypeLabel(evidenceRecords, 'PHOTO'),
      remoteEnglish('technicianPhoto'),
    );
    // Unknown codes are humanized, not mapped.
    expect(resultLabel(const [], 'NEW_RESULT'), 'New Result');
  });
}
