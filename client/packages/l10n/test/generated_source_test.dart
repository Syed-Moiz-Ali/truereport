import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The generated accessors must never carry English text.
///
/// Every string literal in `lib/l10n/gen` has to be a message key, a locale
/// code, or an import path. Anything containing prose (whitespace, punctuation
/// used in sentences) fails.
void main() {
  test('generated localization files contain no English sentences', () {
    final dir = Directory('lib/l10n/gen');
    expect(dir.existsSync(), isTrue);
    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList(growable: false);
    expect(files, isNotEmpty);

    final offenders = <String>[];
    final singleQuoted = RegExp(r"'([^'\\]*)'");
    final doubleQuoted = RegExp(r'"([^"\\]*)"');

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('import ') ||
            line.startsWith('export ') ||
            line.startsWith('//') ||
            line.startsWith('part ')) {
          continue;
        }
        for (final regex in <RegExp>[singleQuoted, doubleQuoted]) {
          for (final match in regex.allMatches(lines[i])) {
            final value = match.group(1) ?? '';
            if (_isAllowedLiteral(value)) continue;
            offenders.add(
              '${file.path}:${i + 1}: "$value" :: ${lines[i].trim()}',
            );
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Generated localizations must not ship English. Everything must come '
          'from the backend bundle:\n${offenders.join('\n')}',
    );
  });
}

bool _isAllowedLiteral(String value) {
  if (value.isEmpty) return true;
  // Locale tag.
  if (value == 'en') return true;
  // Message key or identifier (`appTitle`, `button.save`, `unsupportedLocale`).
  if (RegExp(r'^[A-Za-z_][A-Za-z0-9_.]*$').hasMatch(value)) return true;
  // Import path.
  if (value.startsWith('package:') || value.contains('/')) return true;
  return false;
}
