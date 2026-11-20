import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/generate_localizations.dart';

/// Proves the checked-in generated accessors are exactly what the generator
/// emits today, and that the generator is deterministic.
void main() {
  test('generated localizations match a fresh generator run', () {
    final first = buildLocalizationFiles();
    final second = buildLocalizationFiles();
    expect(second, first, reason: 'generator output is not deterministic');

    for (final entry in first.entries) {
      final file = File(entry.key);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'run `dart run tool/generate_localizations.dart`',
      );
      expect(
        file.readAsStringSync(),
        entry.value,
        reason:
            '${entry.key} is stale. Re-run '
            '`dart run tool/generate_localizations.dart`.',
      );
    }
  });
}
