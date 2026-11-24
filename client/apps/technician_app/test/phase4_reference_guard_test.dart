import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('no local job/sync/evidence status label or tone map remains', () {
    const files = <String>[
      'lib/src/ui_helpers.dart',
      'lib/src/features/sync/sync_screen.dart',
      'lib/src/features/sync/widgets/sync_operation_row.dart',
      'lib/src/features/sync/widgets/sync_conflict_strip.dart',
      'lib/src/features/jobs/queue/jobs_queue_agenda.dart',
      'lib/src/features/review/signoff_screen.dart',
    ];
    for (final path in files) {
      final source = _read(path);
      expect(
        source.contains('technicianStatusLabel'),
        isFalse,
        reason: '$path must resolve labels from the reference taxonomy',
      );
      expect(
        source.contains('technicianStatusTone'),
        isFalse,
        reason: '$path must resolve tones from the reference taxonomy',
      );
      expect(
        source.contains('_stateLabel('),
        isFalse,
        reason: '$path must resolve sync states from /reference/statuses/sync',
      );
    }
  });

  test('queue filters are built from the served job statuses', () {
    final clean = _read(
      'lib/src/features/jobs/technician_jobs_clean_page.dart',
    );
    final agenda = _read('lib/src/features/jobs/queue/jobs_queue_agenda.dart');
    expect(clean.contains("statusesProvider('job')"), isTrue);
    expect(agenda.contains("statusesProvider('job')"), isFalse);
    expect(clean.contains("_setStatus('ASSIGNED')"), isFalse);
    expect(agenda.contains("onStatus('ASSIGNED')"), isFalse);
  });

  test('the evidence UI reads canonical server statuses', () {
    final item = _read(
      'lib/src/features/inspection/assessment_screen.dart',
    );
    expect(item.contains('evidenceStatusLabel(ref'), isTrue);
    expect(item.contains('evidenceStatusTone(ref'), isTrue);
  });
}
