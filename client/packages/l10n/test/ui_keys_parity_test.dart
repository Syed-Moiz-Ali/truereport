import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import '../tool/generate_ui_keys.dart';

/// Guards the generated key files against drift with the backend catalogs.
///
/// Re-derives the constants exactly the way `tool/generate_ui_keys.dart` does
/// and fails when a key is missing, renamed, or left behind.
void main() {
  const expectedCounts = <String, int>{
    'common': 59,
    'platform_admin': 756,
    'workshop_admin': 1261,
    'technician': 1277,
  };

  test('the backend catalogs keep their approved split', () {
    final root = _repoRoot();
    for (final entry in expectedCounts.entries) {
      final file = File(
        '${root.path}${Platform.pathSeparator}server'
        '${Platform.pathSeparator}src${Platform.pathSeparator}main'
        '${Platform.pathSeparator}resources${Platform.pathSeparator}i18n'
        '${Platform.pathSeparator}${entry.key}'
        '${Platform.pathSeparator}en.json',
      );
      final decoded = jsonDecode(file.readAsStringSync());
      expect(
        (decoded as Map).length,
        entry.value,
        reason: '${entry.key}/en.json changed size',
      );
    }
  });

  test('generated UI key files match the backend en catalogs', () {
    final root = _repoRoot();
    for (final catalog in uiKeyCatalogs) {
      final jsonFile = File(
        '${root.path}${Platform.pathSeparator}server'
        '${Platform.pathSeparator}src${Platform.pathSeparator}main'
        '${Platform.pathSeparator}resources${Platform.pathSeparator}i18n'
        '${Platform.pathSeparator}${catalog.directory}'
        '${Platform.pathSeparator}en.json',
      );
      final keys = <String>[];
      if (jsonFile.existsSync()) {
        final decoded = jsonDecode(jsonFile.readAsStringSync());
        if (decoded is Map) keys.addAll(decoded.keys.whereType<String>());
      }
      keys.sort();

      final seen = <String, String>{};
      final expected = <String>[];
      for (final key in keys) {
        final name = uniqueKeyConstant(key, seen);
        seen[name] = key;
        expected.add(
          "staticconst$name=UiMessageKey.${catalog.constructor}('$key');",
        );
      }

      final dartFile = File(
        '${root.path}${Platform.pathSeparator}client'
        '${Platform.pathSeparator}packages${Platform.pathSeparator}l10n'
        '${Platform.pathSeparator}lib${Platform.pathSeparator}src'
        '${Platform.pathSeparator}ui_messages${Platform.pathSeparator}keys'
        '${Platform.pathSeparator}${catalog.directory}_keys.dart',
      );
      expect(
        dartFile.existsSync(),
        isTrue,
        reason:
            'run `dart run tool/generate_ui_keys.dart` — missing '
            '${dartFile.path}',
      );
      final compact = dartFile.readAsStringSync().replaceAll(
        RegExp(r'[\s,]'),
        '',
      );
      for (final entry in expected) {
        expect(
          compact.contains(entry),
          isTrue,
          reason:
              '${catalog.className} is missing "$entry". '
              'Re-run `dart run tool/generate_ui_keys.dart`.',
        );
      }
      final actualCount = RegExp('staticconst').allMatches(compact).length;
      expect(
        actualCount,
        keys.length,
        reason:
            '${catalog.className} has $actualCount constants but the catalog '
            'has ${keys.length} keys.',
      );
    }
  });

  test('UiMessageKey exposes every client namespace', () {
    expect(
      const UiMessageKey.common('button.save').qualified,
      'common.button.save',
    );
    expect(
      const UiMessageKey.platformAdmin('nav.dashboard').qualified,
      'platform_admin.nav.dashboard',
    );
    expect(
      const UiMessageKey.workshopAdmin('jobsTab').qualified,
      'workshop_admin.jobsTab',
    );
    expect(
      const UiMessageKey.technician('jobsTab').qualified,
      'technician.jobsTab',
    );
  });
}

Directory _repoRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final marker = Directory(
      '${directory.path}${Platform.pathSeparator}server'
      '${Platform.pathSeparator}src',
    );
    if (marker.existsSync()) return directory;
    directory = directory.parent;
  }
  throw StateError(
    'Could not locate the repository root from ${Directory.current.path}',
  );
}
