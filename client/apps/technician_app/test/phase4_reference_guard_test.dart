import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('no local job/sync/evidence status label or tone map remains', () {
    const files = <String>[
      'lib/src/ui_helpers.dart',
      'lib/src/features/sync/technician_sync_page.dart',
      'lib/src/features/jobs/queue/jobs_queue_row.dart',
      'lib/src/features/review/technician_summary_page.dart',
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
    final rail = _read('lib/src/features/jobs/queue/jobs_queue_week.dart');
    expect(clean.contains("statusesProvider('job')"), isTrue);
    expect(rail.contains("statusesProvider('job')"), isTrue);
    expect(clean.contains("_setStatus('ASSIGNED')"), isFalse);
    expect(rail.contains("onStatus('ASSIGNED')"), isFalse);
  });

  test('the evidence UI reads canonical server statuses', () {
    final item = _read(
      'lib/src/features/inspection/technician_dynamic_item_page.dart',
    );
    expect(item.contains('evidenceStatusLabel(ref'), isTrue);
    expect(item.contains('evidenceStatusTone(ref'), isTrue);
  });
}
