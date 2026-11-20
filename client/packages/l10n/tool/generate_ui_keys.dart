import 'dart:convert';
import 'dart:io';

/// Generates the typed UI-message key files from the backend catalogs.
///
/// Run from anywhere: `dart run tool/generate_ui_keys.dart`.
///
/// Each catalog directory maps to one namespace:
///   common/en.json         -> CommonKeys
///   platform_admin/en.json -> PlatformAdminKeys
///   workshop_admin/en.json -> WorkshopAdminKeys
///   technician/en.json     -> TechnicianKeys
///
/// A parity test re-derives the same names from the catalogs and fails when a
/// generated file drifts.
const List<UiKeyCatalog> uiKeyCatalogs = <UiKeyCatalog>[
  UiKeyCatalog(
    directory: 'common',
    namespace: 'common',
    className: 'CommonKeys',
    constructor: 'common',
  ),
  UiKeyCatalog(
    directory: 'platform_admin',
    namespace: 'platform_admin',
    className: 'PlatformAdminKeys',
    constructor: 'platformAdmin',
  ),
  UiKeyCatalog(
    directory: 'workshop_admin',
    namespace: 'workshop_admin',
    className: 'WorkshopAdminKeys',
    constructor: 'workshopAdmin',
  ),
  UiKeyCatalog(
    directory: 'technician',
    namespace: 'technician',
    className: 'TechnicianKeys',
    constructor: 'technician',
  ),
];

const Set<String> _dartKeywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'type',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

/// `addStaff.helper.temporaryPassword` -> `addStaffHelperTemporaryPassword`
String toCamel(String key) {
  final parts = key
      .split(RegExp(r'[^A-Za-z0-9]+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'kEmpty';
  final buffer = StringBuffer(_lowerFirst(parts.first));
  for (var i = 1; i < parts.length; i++) {
    buffer.write(_upperFirst(parts[i]));
  }
  var name = buffer.toString();
  if (name.isEmpty) name = 'kEmpty';
  final first = name.codeUnitAt(0);
  final startsDigit = first >= 0x30 && first <= 0x39;
  if (startsDigit || _dartKeywords.contains(name)) {
    name = 'k${_upperFirst(name)}';
  }
  return name;
}

String _lowerFirst(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

String _upperFirst(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _snake(String key) {
  final raw = key
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  var name = raw.isEmpty ? 'kEmpty' : raw;
  final first = name.codeUnitAt(0);
  final startsDigit = first >= 0x30 && first <= 0x39;
  if (startsDigit || _dartKeywords.contains(name)) {
    name = 'k${_upperFirst(name)}';
  }
  return name;
}

/// Deterministic, collision-free constant name for [key].
String uniqueKeyConstant(String key, Map<String, String> seen) {
  final base = toCamel(key);
  if (!seen.containsKey(base) || seen[base] == key) return base;
  final snake = _snake(key);
  if (!seen.containsKey(snake) || seen[snake] == key) return snake;
  var suffix = 2;
  while (true) {
    final candidate = '${snake}_$suffix';
    if (!seen.containsKey(candidate) || seen[candidate] == key) {
      return candidate;
    }
    suffix += 1;
  }
}

String _entry(String camel, String constructor, String key) {
  final single = "  static const $camel = UiMessageKey.$constructor('$key');";
  if (single.length <= 80) return single;
  return "  static const $camel = UiMessageKey.$constructor(\n    '$key',\n  );";
}

void main() {
  final toolDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = toolDir.parent.parent.parent.parent;
  final catalogRoot = Directory(
    '${repoRoot.path}${Platform.pathSeparator}server'
    '${Platform.pathSeparator}src${Platform.pathSeparator}main'
    '${Platform.pathSeparator}resources${Platform.pathSeparator}i18n',
  );
  final outDir = Directory(
    '${toolDir.path}${Platform.pathSeparator}..${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}src${Platform.pathSeparator}ui_messages'
    '${Platform.pathSeparator}keys',
  ).absolute;

  for (final catalog in uiKeyCatalogs) {
    final file = File(
      '${catalogRoot.path}${Platform.pathSeparator}${catalog.directory}'
      '${Platform.pathSeparator}en.json',
    );
    final keys = <String>[];
    if (file.existsSync()) {
      final raw = jsonDecode(file.readAsStringSync());
      if (raw is Map) {
        keys.addAll(raw.keys.whereType<String>());
      }
    }
    keys.sort();

    final buffer = StringBuffer()
      ..writeln(
        '// GENERATED by tool/generate_ui_keys.dart - do not edit by hand.',
      )
      ..writeln(
        '// Source: server/src/main/resources/i18n/'
        '${catalog.directory}/en.json',
      )
      ..writeln()
      ..writeln();
    if (keys.isNotEmpty) {
      buffer
        ..writeln("import '../ui_message_key.dart';")
        ..writeln();
    }
    buffer.writeln('abstract final class ${catalog.className} {');
    final seen = <String, String>{};
    for (final key in keys) {
      final camel = uniqueKeyConstant(key, seen);
      seen[camel] = key;
      buffer.writeln(_entry(camel, catalog.constructor, key));
    }
    buffer.writeln('}');

    final outFile = File(
      '${outDir.path}${Platform.pathSeparator}${catalog.directory}_keys.dart',
    );
    outFile.createSync(recursive: true);
    outFile.writeAsStringSync(buffer.toString());
    stdout.writeln('wrote ${outFile.path} (${keys.length} keys)');
  }
}

class UiKeyCatalog {
  const UiKeyCatalog({
    required this.directory,
    required this.namespace,
    required this.className,
    required this.constructor,
  });

  final String directory;
  final String namespace;
  final String className;
  final String constructor;
}
