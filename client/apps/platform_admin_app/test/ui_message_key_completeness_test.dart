import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _catalogDir =
    '../../../server/src/main/resources/i18n/platform_admin';
const String _catalogPath = '$_catalogDir/en.json';
const String _arCatalogPath = '$_catalogDir/ar.json';
const String _keysDir = '../../packages/l10n/lib/src/ui_messages/keys';

Set<String> _catalogKeys(Map<String, dynamic> catalog) => catalog.keys.toSet();

Map<String, dynamic> _readCatalog(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<File> _libFiles(Directory lib) {
  return lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);
}

/// Parses generated `*_keys.dart` files into qualified `namespace.key` sets.
/// Also builds per-class camelName -> qualified lookups for tKey resolution.
class _GeneratedKeys {
  _GeneratedKeys(this.byClass, this.qualified);

  final Map<String, Map<String, String>> byClass;
  final Set<String> qualified;
}

_GeneratedKeys _loadGeneratedKeys(Directory dir) {
  final byClass = <String, Map<String, String>>{};
  final qualified = <String>{};
  String? nsForClass(String className) {
    switch (className) {
      case 'CommonKeys':
        return 'common';
      case 'PlatformAdminKeys':
        return 'platform_admin';
    }
    return null;
  }

  for (final file in dir.listSync().whereType<File>().where(
    (f) => f.path.endsWith('_keys.dart'),
  )) {
    final text = file.readAsStringSync();
    final classMatch = RegExp(r'class (\w+Keys)').firstMatch(text);
    expect(
      classMatch,
      isNotNull,
      reason: 'cannot find keys class in ${file.path}',
    );
    final namespace = nsForClass(classMatch!.group(1)!);
    expect(namespace, isNotNull, reason: 'unknown keys class in ${file.path}');
    final fieldPattern = RegExp(
      r"static const (\w+) = UiMessageKey\.\w+\(\s*'([^']+)'\s*,?\s*\)",
    );
    final entries = <String, String>{};
    for (final match in fieldPattern.allMatches(text)) {
      entries[match.group(1)!] = '$namespace.${match.group(2)!}';
      qualified.add('$namespace.${match.group(2)!}');
    }
    expect(entries, isNotEmpty, reason: 'no parsed keys in ${file.path}');
    byClass[classMatch.group(1)!] = entries;
  }
  return _GeneratedKeys(byClass, qualified);
}

/// Technical tokens that are intentionally never translated.
/// Mirrors `technicalTokenAllowlist` in
/// `client/packages/l10n/tool/generate_ui_keys.dart`.
const Set<String> _technicalTokenAllowlist = {
  'CoreOS',
  'GRID V4.2 ONLINE',
  'Production Cluster EU-West',
  'ED25519-SHA512',
  '{}',
  '/',
  '-',
  '—',
  'LTR',
  'RTL',
  'support@truereport.test',
};

bool _looksUserFacing(String literal) {
  if (literal.contains(r'$') || literal.contains('{')) return false;
  if (_technicalTokenAllowlist.contains(literal)) return false;
  return RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(literal);
}

void main() {
  late Map<String, dynamic> mapping;
  late Set<String> catalog;
  late List<File> files;
  late _GeneratedKeys generated;

  setUpAll(() {
    final catalogFile = File(_catalogPath);
    expect(
      catalogFile.existsSync(),
      isTrue,
      reason: 'backend catalog resource missing: $_catalogPath',
    );
    mapping = _readCatalog(_catalogPath);
    catalog = _catalogKeys(mapping);
    files = _libFiles(Directory('lib'));
    expect(files, isNotEmpty, reason: 'platform_admin lib has no dart files');
    final keysDir = Directory(_keysDir);
    expect(
      keysDir.existsSync(),
      isTrue,
      reason: 'generated keys dir missing: $_keysDir',
    );
    generated = _loadGeneratedKeys(keysDir);
  });

  test('no AppLocalizations usage in platform_admin lib including main.dart', () {
    final violations = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('AppLocalizations')) {
          violations.add('${file.path}:${i + 1}: ${lines[i]}');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'AppLocalizations references must be zero (typed tKey/tArgsKey API only):\n${violations.join('\n')}',
    );
  });

  test('no l10n. usage in platform_admin lib', () {
    final pattern = RegExp(r'(?<![\w/])l10n\.');
    final violations = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('import ') || line.startsWith('export ')) continue;
        if (pattern.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1}: ${lines[i]}');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'l10n. usages must be zero:\n${violations.join('\n')}',
    );
  });

  test('no raw .t()/.tArgs()/resolveByString calls in lib', () {
    final rawCallPattern = RegExp(r'\.t\(|\.tArgs\(');
    final internalPattern = RegExp(r'resolveByString|resolveArgsByString');
    final violations = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (rawCallPattern.hasMatch(lines[i]) ||
            internalPattern.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1}: ${lines[i]}');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'raw .t()/.tArgs() and test-only resolveByString calls are banned in lib '
          '(use typed tKey/tArgsKey with generated keys):\n${violations.join('\n')}',
    );
  });

  test('no raw qualified key literals or UiMessageKey constructors in lib', () {
    final qualifiedPattern = RegExp(
      "'(common|platform_admin)\\.[\\w.]+'|\"(common|platform_admin)\\.[\\w.]+\"",
    );
    final ctorPattern = RegExp(r'UiMessageKey\s*\(');
    final violations = <String>[];
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final match in qualifiedPattern.allMatches(text)) {
        var key = match.group(0)!;
        key = key.substring(1, key.length - 1);
        if (key.contains(r'$') || key.contains('{') || key.contains(' ')) {
          continue;
        }
        violations.add('${file.path} :: qualified literal $key');
      }
      final lines = text.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (ctorPattern.hasMatch(lines[i])) {
          violations.add('${file.path}:${i + 1}: ${lines[i]}');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'raw qualified key literals and direct UiMessageKey(...) constructor calls '
          'are banned in app lib (use generated CommonKeys/PlatformAdminKeys constants):\n${violations.join('\n')}',
    );
  });

  test('every tKey/tArgsKey target exists in the backend catalog', () {
    final refPattern = RegExp(
      r'(?:^|[^A-Za-z0-9_])t(?:Args)?Key\(\s*([A-Za-z_][\w]*)\.([\w]+)',
    );
    final literalPattern = RegExp(
      "t(?:Args)?Key\\(\\s*'([^']+)'|\\.t\\(\\s*'([^']+)'|labelKey:\\s*'([^']+)'",
    );
    final qualifiedLiteralPattern = RegExp(
      "'(common|platform_admin)\\.[\\w.]+'|\"(common|platform_admin)\\.[\\w.]+\"",
    );
    final missing = <String>[];
    final unknown = <String>[];
    final used = <String>{};
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final match in refPattern.allMatches(text)) {
        final className = match.group(1)!;
        final field = match.group(2)!;
        if (!className.endsWith('Keys')) {
          if (field == 'labelKey') continue;
          unknown.add('${file.path} :: $className.$field');
          continue;
        }
        final table = generated.byClass[className];
        if (table == null || !table.containsKey(field)) {
          unknown.add('${file.path} :: $className.$field');
          continue;
        }
        final qualified = table[field]!;
        used.add(qualified);
        if (!catalog.contains(qualified)) {
          missing.add('${file.path} :: $qualified');
        }
      }
      for (final match in literalPattern.allMatches(text)) {
        for (var i = 1; i <= match.groupCount; i++) {
          final key = match.group(i);
          if (key == null) continue;
          if (key.contains(r'$') ||
              key.contains('{') ||
              key.contains(' ') ||
              !key.contains('.')) {
            continue;
          }
          used.add(key);
          if (!catalog.contains(key)) missing.add('${file.path} :: $key');
        }
      }
      for (final match in qualifiedLiteralPattern.allMatches(text)) {
        var key = match.group(0)!;
        key = key.substring(1, key.length - 1);
        if (key.contains(r'$') || key.contains('{') || key.contains(' ')) {
          continue;
        }
        used.add(key);
        if (!catalog.contains(key)) missing.add('${file.path} :: $key');
      }
    }
    expect(used, isNotEmpty, reason: 'no catalog keys found in lib');
    expect(
      unknown,
      isEmpty,
      reason:
          'tKey/tArgsKey references with no generated-key entry:\n${unknown.join('\n')}',
    );
    expect(
      missing,
      isEmpty,
      reason:
          'keys used in lib but missing from backend catalog:\n${missing.join('\n')}',
    );
  });

  test('no hardcoded language selection in platform_admin lib', () {
    final violations = <String>[];
    final isArabicPattern = RegExp(r'isArabic');
    final togglePattern = RegExp(r'\.toggle\(\)');
    final arabicCheckPattern = RegExp(r"languageCode\s*==\s*'ar'");
    final ternaryChoicePattern = RegExp(
      r"""\?\s*'(?:ar|en)'\s*:\s*'(?:en|ar)'""",
    );
    final localeBooleanPattern = RegExp(r'Locale\(\s*isArabic');
    final switchKeyPattern = RegExp(r'headerSwitchTo');
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (isArabicPattern.hasMatch(line) ||
            togglePattern.hasMatch(line) ||
            arabicCheckPattern.hasMatch(line) ||
            ternaryChoicePattern.hasMatch(line) ||
            localeBooleanPattern.hasMatch(line) ||
            switchKeyPattern.hasMatch(line)) {
          violations.add('${file.path}:${i + 1}: $line');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'hardcoded en/ar language selection is banned in platform_admin lib '
          '(source languages from the backend manifest and switch with '
          'UiMessageSwitcher.switchTo):\n${violations.join('\n')}',
    );
  });

  test('no hardcoded user-facing strings in display positions', () {
    final displayPattern = RegExp(
      "Text\\s*\\(\\s*'([^']+)'|Text\\s*\\(\\s*\"([^\"]+)\"|"
      "label\\s*:\\s*'([^']+)'|label\\s*:\\s*\"([^\"]+)\"|"
      "title\\s*:\\s*'([^']+)'|title\\s*:\\s*\"([^\"]+)\"|"
      "subtitle\\s*:\\s*'([^']+)'|subtitle\\s*:\\s*\"([^\"]+)\"|"
      "hintText\\s*:\\s*'([^']+)'|hintText\\s*:\\s*\"([^\"]+)\"|"
      "tooltip\\s*:\\s*'([^']+)'|tooltip\\s*:\\s*\"([^\"]+)\"",
    );
    final violations = <String>[];
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final match in displayPattern.allMatches(text)) {
        for (var i = 1; i <= match.groupCount; i++) {
          final literal = match.group(i);
          if (literal == null) continue;
          if (_looksUserFacing(literal)) {
            violations.add('${file.path} :: "$literal"');
          }
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'hardcoded user-facing strings must go through the backend catalog '
          '(allowlisted technical tokens: ${_technicalTokenAllowlist.join(', ')}; '
          'dynamic/interpolated strings are exempt):\n${violations.join('\n')}',
    );
  });

  test('generated keys are up-to-date with the canonical catalog', () {
    expect(
      generated.qualified,
      equals(catalog),
      reason:
          'generated keys drifted from backend catalog: '
          'missing=${catalog.difference(generated.qualified).take(10)} '
          'extra=${generated.qualified.difference(catalog).take(10)}',
    );
    expect(generated.qualified.length, equals(catalog.length));
  });

  test('catalog namespaces and key counts are sane', () {
    final namespaces = <String>{};
    for (final key in catalog) {
      namespaces.add(key.substring(0, key.indexOf('.')));
    }
    expect(namespaces, containsAll(['common', 'platform_admin']));
    final common = catalog.where((key) => key.startsWith('common.')).length;
    final platformAdmin = catalog
        .where((key) => key.startsWith('platform_admin.'))
        .length;
    expect(common, greaterThan(0));
    expect(platformAdmin, greaterThan(200));
  });

  test('backend EN/AR JSON catalogs have identical key sets', () {
    final enKeys = _readCatalog(_catalogPath).keys.toSet();
    final arKeys = _readCatalog(_arCatalogPath).keys.toSet();
    expect(enKeys, isNotEmpty);
    expect(arKeys, equals(enKeys));
  });
}
