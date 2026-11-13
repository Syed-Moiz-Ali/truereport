import 'dart:convert';
import 'dart:io';

const Map<String, String> technicalTokenAllowlist = {
  'CoreOS': 'product brand name, never translated',
  'GRID V4.2 ONLINE': 'versioned system status capsule, ops identifier',
  'Production Cluster EU-West': 'environment identifier, ops-owned',
  'ED25519-SHA512': 'crypto algorithm token, must stay verbatim',
  '{}': 'JSON object placeholder in metadata hint',
  '/': 'breadcrumb separator punctuation',
  '-': 'empty-value dash placeholder',
  '\u2014': 'empty-option em-dash placeholder',
  'LTR': 'direction code value identifier (display kept as code)',
  'RTL': 'direction code value identifier (display kept as code)',
  'support@truereport.test': 'contact identifier, identical across languages',
};

String toCamel(String dotted) {
  final parts = dotted.split('.');
  final buffer = StringBuffer(_lowerFirst(parts.first));
  for (var i = 1; i < parts.length; i++) {
    buffer.write(_upperFirst(parts[i]));
  }
  return buffer.toString();
}

String _lowerFirst(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

String _upperFirst(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _ctorForNamespace(String namespace) {
  switch (namespace) {
    case 'common':
      return 'UiMessageKey.common';
    case 'platform_admin':
      return 'UiMessageKey.platformAdmin';
    default:
      throw StateError('Unsupported namespace "$namespace".');
  }
}

String _entry(String camel, String namespace, String key) {
  final single =
      "  static const $camel = ${_ctorForNamespace(namespace)}('$key');";
  if (single.length <= 80) return single;
  return "  static const $camel = ${_ctorForNamespace(namespace)}(\n    '$key',\n  );";
}

void main() {
  final toolDir = File(Platform.script.toFilePath()).parent;
  final catalogFile = File(
    '${toolDir.path}${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}server${Platform.pathSeparator}src${Platform.pathSeparator}main${Platform.pathSeparator}resources${Platform.pathSeparator}i18n${Platform.pathSeparator}platform_admin${Platform.pathSeparator}en.json',
  ).absolute;
  final outDir = Directory(
    '${toolDir.path}${Platform.pathSeparator}..${Platform.pathSeparator}lib${Platform.pathSeparator}src${Platform.pathSeparator}ui_messages${Platform.pathSeparator}keys',
  ).absolute;
  final raw =
      jsonDecode(catalogFile.readAsStringSync()) as Map<String, dynamic>;
  final mappings = <Map<String, String>>[];
  for (final qualified in raw.keys) {
    final dot = qualified.indexOf('.');
    if (dot <= 0 || dot == qualified.length - 1) {
      throw StateError('Catalog key "$qualified" must be namespace-qualified.');
    }
    final namespace = qualified.substring(0, dot);
    if (!const {'common', 'platform_admin'}.contains(namespace)) {
      throw StateError('Unsupported namespace "$namespace" for "$qualified".');
    }
    mappings.add(<String, String>{
      'namespace': namespace,
      'key': qualified.substring(dot + 1),
    });
  }
  mappings.sort((a, b) {
    final ns = a['namespace']!.compareTo(b['namespace']!);
    if (ns != 0) return ns;
    return a['key']!.compareTo(b['key']!);
  });
  final byNamespace = <String, List<Map<String, String>>>{};
  for (final m in mappings) {
    byNamespace.putIfAbsent(m['namespace']!, () => []).add(m);
  }
  const classNames = {
    'common': 'CommonKeys',
    'platform_admin': 'PlatformAdminKeys',
  };
  final seen = <String, String>{};
  for (final entry in byNamespace.entries) {
    final className = classNames[entry.key];
    if (className == null) {
      throw StateError('No key class defined for namespace "${entry.key}".');
    }
    final buffer = StringBuffer()
      ..writeln("import '../ui_message_key.dart';")
      ..writeln()
      ..writeln('abstract final class $className {');
    for (final m in entry.value) {
      final camel = toCamel(m['key']!);
      final qualified = '${m['namespace']}.${m['key']}';
      final prev = seen[camel];
      if (prev != null && prev != qualified) {
        throw StateError(
          'Key name collision: "$camel" for "$qualified" and "$prev".',
        );
      }
      seen[camel] = qualified;
      buffer.writeln(_entry(camel, m['namespace']!, m['key']!));
    }
    buffer.writeln('}');
    final outFile = File(
      '${outDir.path}${Platform.pathSeparator}${entry.key}_keys.dart',
    );
    outFile.createSync(recursive: true);
    outFile.writeAsStringSync(buffer.toString());
    stdout.writeln('wrote ${outFile.path} (${entry.value.length} keys)');
  }
}
