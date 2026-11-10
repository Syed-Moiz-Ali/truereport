import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the C0 "never invent results" rule for the workshop data layer:
/// `admin_api.dart` and `admin_providers.dart` must never construct
/// fabricated `JobCounts` (or any sample-data fallback). Counts come only
/// from the server counts endpoint; failures propagate to the UI.
void main() {
  test('no fabricated sample data in admin_api and admin_providers', () {
    final separator = Platform.pathSeparator;
    Directory? root;
    var directory = Directory.current;
    while (true) {
      final marker = File(
        '${directory.path}${separator}apps${separator}workshop_admin_app'
        '${separator}lib${separator}src${separator}admin_api.dart',
      );
      if (marker.existsSync()) {
        root = directory;
        break;
      }
      final parent = directory.parent;
      if (parent.path == directory.path) {
        break;
      }
      directory = parent;
    }
    if (root == null) {
      throw StateError('Could not find the Flutter client root.');
    }
    final files = <File>[
      File('${root.path}${separator}apps${separator}workshop_admin_app'
          '${separator}lib${separator}src${separator}admin_api.dart'),
      File('${root.path}${separator}apps${separator}workshop_admin_app'
          '${separator}lib${separator}src${separator}admin_providers.dart'),
    ];
    final forbidden = <RegExp>[
      // Any direct JobCounts construction (only JobCounts.fromJson is real).
      RegExp(r'\bJobCounts\s*\('),
      // The removed invented fallbacks, pinned so they cannot return.
      RegExp(r'draft\s*:\s*12\b'),
      RegExp(r'newScheduled\s*:\s*16\b'),
      RegExp(r'inProgress\s*:\s*18\b'),
      RegExp(r'total\s*:\s*24\b'),
      RegExp(r'finalizedToday\s*:\s*finalized\b'),
      // Interpolated counts path bypassing ApiEndpoints.
      RegExp(r"workshopJobs\}/counts"),
      // Figma sample-data vocabulary leaking into the data layer.
      RegExp(r'Porsche Taycan'),
      RegExp(r'Arthur Pendelton'),
      RegExp(r'100-Point Pre-Delivery'),
      RegExp(r'Quick Lube'),
      RegExp(r'Marcus Vance'),
      RegExp(r'Tariq Mansoor'),
      RegExp(r'David Vance'),
    ];
    for (final file in files) {
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Target file must exist: ${file.path}',
      );
      final source = file.readAsStringSync();
      for (final pattern in forbidden) {
        expect(
          pattern.hasMatch(source),
          isFalse,
          reason:
              '${file.path} contains forbidden sample/invented pattern: $pattern',
        );
      }
    }
  });
}
