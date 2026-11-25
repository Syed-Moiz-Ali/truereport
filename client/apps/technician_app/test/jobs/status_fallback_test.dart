/// Characterization tests for status label fallbacks.
///
/// The taxonomy endpoint is the only source of labels; when it has not loaded
/// (or has no record for a code) the UI must still say something readable
/// instead of showing a raw enum like `IN_PROGRESS`.
///
/// Note: the current humanizer title-cases every word, so `IN_PROGRESS`
/// renders as `In Progress` (not `In progress`).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:technician_app/src/reference_ui.dart';

void main() {
  setUp(clearRemoteEnglish);

  group('humanizeStatusCode', () {
    test('title-cases a screaming-snake code', () {
      expect(humanizeStatusCode('IN_PROGRESS'), 'In Progress');
    });

    test('treats spaces, dashes and underscores as word breaks', () {
      expect(humanizeStatusCode('in-progress'), 'In Progress');
      expect(humanizeStatusCode('in progress'), 'In Progress');
      expect(humanizeStatusCode('  IN_PROGRESS  '), 'In Progress');
    });

    test('keeps multi-word codes readable', () {
      expect(humanizeStatusCode('PENDING_REVIEW'), 'Pending Review');
      expect(
        humanizeStatusCode('WAITING_FOR_CUSTOMER'),
        'Waiting For Customer',
      );
    });

    test('returns an empty string for an empty code', () {
      expect(humanizeStatusCode(''), isEmpty);
      expect(humanizeStatusCode('   '), isEmpty);
    });
  });

  group('referenceStatusCodeLabel', () {
    test('falls back to the humanized code with no taxonomy', () {
      expect(referenceStatusCodeLabel(null, 'IN_PROGRESS'), 'In Progress');
    });

    test(
      'falls back to the humanized code when there is no matching record',
      () {
        const records = <ReferenceRecord>[
          ReferenceRecord(code: 'SCHEDULED', labelKey: 'job.status.scheduled'),
        ];

        expect(referenceStatusCodeLabel(records, 'IN_PROGRESS'), 'In Progress');
      },
    );

    test('falls back when the record carries no labelKey', () {
      const records = <ReferenceRecord>[
        ReferenceRecord(code: 'IN_PROGRESS', labelKey: ''),
      ];

      expect(referenceStatusCodeLabel(records, 'IN_PROGRESS'), 'In Progress');
    });

    test('falls back when the labelKey is missing from the bundle', () {
      const records = <ReferenceRecord>[
        ReferenceRecord(code: 'IN_PROGRESS', labelKey: 'job.status.inProgress'),
      ];

      expect(referenceStatusCodeLabel(records, 'IN_PROGRESS'), 'In Progress');
    });

    test('uses the served label when the bundle resolves it', () {
      setRemoteEnglish(<String, String>{
        'job.status.inProgress': 'Work in progress',
      });
      const records = <ReferenceRecord>[
        ReferenceRecord(code: 'IN_PROGRESS', labelKey: 'job.status.inProgress'),
      ];

      expect(
        referenceStatusCodeLabel(records, 'IN_PROGRESS'),
        'Work in progress',
      );
    });
  });
}
