import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase C0 Workstream C i18n gate.
///
/// Fails on:
///   1. Figma sample strings / `figmaText`-style switches in shipped `lib/`.
///   2. User-visible raw literals in shipped `lib/` (anything rendered via
///      `Text`, `hint:`, `label:`, `title:`, …
///      must come from `AppLocalizations`).
///   3. Forbidden wording / mojibake / key-placeholder drift in the ARBs.
///
/// Pure `dart:io`: intentionally imports no app code so this gate keeps
/// running even when unrelated workstreams break app compilation.
Directory _clientRoot() {
  var directory = Directory.current;
  while (true) {
    final marker = File(
      '${directory.path}${Platform.pathSeparator}packages'
      '${Platform.pathSeparator}api_client${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}api_client.dart',
    );
    if (marker.existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Could not find the Flutter client root.');
    }
    directory = parent;
  }
}

List<Directory> _libDirs(Directory root) {
  final separator = Platform.pathSeparator;
  return <Directory>[
    Directory(
      '${root.path}${separator}apps${separator}technician_app${separator}lib',
    ),
    // This gate is scoped to the technician app and shared packages. The
    // Platform/Workshop apps have their own localization checks.
    Directory(
      '${root.path}${separator}packages${separator}auth${separator}lib',
    ),
    Directory(
      '${root.path}${separator}packages${separator}design_system${separator}lib',
    ),
    Directory(
      '${root.path}${separator}packages${separator}l10n${separator}lib',
    ),
    Directory(
      '${root.path}${separator}packages${separator}core${separator}lib',
    ),
    Directory(
      '${root.path}${separator}packages${separator}domain${separator}lib',
    ),
    Directory(
      '${root.path}${separator}packages${separator}api_client${separator}lib',
    ),
    Directory(
      '${root.path}${separator}packages${separator}offline_sync${separator}lib',
    ),
  ];
}

/// `ui_gallery` is dev-only tooling and is intentionally not scanned.
Iterable<File> _libFiles(Directory root) sync* {
  final separator = Platform.pathSeparator;
  bool isGenerated(String path) =>
      path.split(separator).contains('gen') ||
      path.contains('${separator}build$separator') ||
      path.contains('$separator.dart_tool$separator');
  for (final dir in _libDirs(root)) {
    if (!dir.existsSync()) {
      continue;
    }
    final pending = <Directory>[dir];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final entity in current.listSync(followLinks: false)) {
        final path = entity.path;
        if (isGenerated(path)) {
          continue;
        }
        if (entity is Directory) {
          pending.add(entity);
          continue;
        }
        if (entity is File && path.endsWith('.dart')) {
          yield entity;
        }
      }
    }
  }
}

/// Figma sample wording and switch names. Must live only under `test/`.
final _figmaPatterns = <RegExp>[
  RegExp(r'figmaText'),
  RegExp(r'figmaPreview'),
  RegExp(r'SignInCopy'),
  RegExp(r'TechInspect'),
  RegExp(r'Renault'),
  RegExp(r'Megan[e]? 3'),
  RegExp(r'Arthur Pendelton'),
  RegExp(r'David Vance'),
  RegExp(r'Alex Lindqvist'),
  RegExp(r'VF1KZ040647192831'),
  RegExp(r'LV71 XZP'),
  RegExp(r'Porsche Taycan'),
  RegExp(r'WA1-VAA'),
  RegExp(r'Bay 3\b'),
  RegExp(r'Bay 4\b'),
  RegExp(r'Bay #04'),
  RegExp(r'Bay 04'),
  RegExp(r'Scan New VIN Tag'),
  RegExp(r'Avg\. turnover'),
  RegExp(r'100% Pass Rate'),
  RegExp(r'42 Passed'),
  RegExp(r'3 Action Items'),
  RegExp(r'Primary Owner'),
  RegExp(r'Step 1 of 4'),
  RegExp(r'Pre-Inspection Ready'),
  RegExp(r'Keys received'),
  RegExp(r'Digital Signature'),
  RegExp(r'Sign Above'),
  RegExp(r'Sign with finger'),
  RegExp(r'Authorizations'),
  RegExp(r'Allow PDF sharing'),
  RegExp(r'Authorize certified'),
  RegExp(r'Encrypt telemetry'),
  RegExp(r'Send detailed diagnostic'),
  RegExp(r'Diagnostic Checklist'),
  RegExp(r'Vehicle Walkaround'),
  RegExp(r'Tire Depth Gauge'),
  RegExp(r'OBD Scanner'),
  RegExp(r'Torque Wrench'),
  RegExp(r'Paint Depth Gauge'),
  RegExp(r'Digital laser'),
  RegExp(r'Bluetooth module'),
  RegExp(r'Preset 120'),
  RegExp(r'Fe / NFe'),
  RegExp(r'Fleet Station'),
  RegExp(r'ISO-9001'),
  RegExp(r'Request ID'),
  RegExp(r'Forgot password\?'),
  RegExp(r"'Sign In'"),
  RegExp(r'1 of 4 Verified'),
  RegExp(r'Vehicle Condition & Fleet Diagnostics'),
  RegExp(r'INTAKE PHASE'),
  RegExp(r'Ready for Check'),
  RegExp(r'INSPECTION IN PROGRESS'),
  RegExp(r"'Queued'"),
  RegExp(r'SHIFT ACTIVE'),
  RegExp(r'SHIFT 1'),
  RegExp(r'You are all caught up!'),
  RegExp(r'No pending vehicle inspections'),
  RegExp(r"'Refresh Queue'"),
  RegExp(r"'Save Consent'"),
  RegExp(r"'Vehicle Info'"),
  RegExp(r"'Intake Hub'"),
  RegExp(r"'Inspection Modules'"),
  RegExp(r"'Required Equipment'"),
  RegExp(r'PRE-INSPECTION SETUP'),
];

/// `param: 'literal'` sites that are intentionally not localized.
/// Documented in `docs/ui/i18n-inventory.md` §3.
const _allowedLiterals = <String>{
  'TrueReport',
  'TrueReport Technician',
  'TrueReport Admin',
  '2026-11-05T09:00:00',
  'error.unknown',
  'error.network',
  'AppTreeView',
  'AppTreeView.search',
  'TR',
  '?',
};

bool _looksUserVisible(String literal) {
  // Only the static prefix before the first interpolation can be a hardcoded
  // word; everything from `$` on is data/l10n (separators like `·`, `:`, `.`
  // and newlines may follow and are not user prose).
  var text = literal.split(r'$').first;
  if (_allowedLiterals.contains(text)) {
    return false;
  }
  if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
    return true;
  }
  return RegExp(r'[A-Za-z]{2,}').hasMatch(text);
}

final _copySitePattern = RegExp(
  r'''(?:^|[\s,(:])(?:Text|hint|label|title|message|tooltip|semanticLabel|subtitle|body|content|placeholder)\s*\(\s*'((?:[^'\\]|\\.)*)'|(?:^|[\s,(:])(?:hint|label|title|message|tooltip|semanticLabel|subtitle|body|content|placeholder)\s*:\s*'((?:[^'\\]|\\.)*)'|(?:^|[\s,(:])(?:Text|hint|label|title|message|tooltip|semanticLabel|subtitle|body|content|placeholder)\s*\(\s*"((?:[^"\\]|\\.)*)"|(?:^|[\s,(:])(?:hint|label|title|message|tooltip|semanticLabel|subtitle|body|content|placeholder)\s*:\s*"((?:[^"\\]|\\.)*)"''',
);

/// Terms that must never appear in shipped ARB copy (Figma-only wording).
/// NOTE: `forgotPassword` ("Forgot password?") is legitimate product copy for
/// the forgot-password link and is therefore NOT in this list; the Figma leak
/// was the sign-in screen rendering it via `SignInCopy` instead of
/// `technicianPasswordHelp` (fixed).
final _arbForbidden = <String>[
  'TechInspect',
  'Renault',
  'Megane',
  'Arthur Pendelton',
  'David Vance',
  'Alex Lindqvist',
  'Bay 04',
  'Bay 3',
  'Bay 4',
  'Allow PDF sharing',
  'Authorize certified',
  'Encrypt telemetry',
  'Send detailed diagnostic',
  'Scan New VIN',
  'Request ID',
  'Vehicle Condition & Fleet Diagnostics',
  'INTAKE PHASE',
  'Ready for Check',
  'INSPECTION IN PROGRESS',
  'Avg. turnover',
  '100% Pass Rate',
  'Fleet Station',
  'ISO-9001',
  'Authorizations',
  'STEP 4 OF 4',
];

void main() {
  test('lib has no Figma sample strings or copy switches', () {
    final root = _clientRoot();
    final offenders = <String>[];
    for (final file in _libFiles(root)) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        for (final pattern in _figmaPatterns) {
          if (pattern.hasMatch(line)) {
            offenders.add(
              '${file.path}:${index + 1}: ${pattern.pattern} :: $line',
            );
            break;
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('lib has no user-visible raw literals', () {
    final root = _clientRoot();
    final offenders = <String>[];
    for (final file in _libFiles(root)) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        var line = lines[index].trim();
        if (line.startsWith('//')) {
          continue;
        }
        // Debug-only labels never render.
        if (line.contains('debugLabel:')) {
          continue;
        }
        for (final match in _copySitePattern.allMatches(lines[index])) {
          for (var group = 1; group <= match.groupCount; group++) {
            final literal = match.group(group);
            if (literal == null) {
              continue;
            }
            if (_looksUserVisible(literal)) {
              offenders.add(
                '${file.path}:${index + 1}: "$literal" :: ${lines[index].trim()}',
              );
              break;
            }
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('ARBs have no mojibake, gaps, or forbidden wording', () {
    final root = _clientRoot();
    final separator = Platform.pathSeparator;
    final enFile = File(
      '${root.path}${separator}packages${separator}l10n${separator}lib'
      '${separator}l10n${separator}app_en.arb',
    );
    final arFile = File(
      '${root.path}${separator}packages${separator}l10n${separator}lib'
      '${separator}l10n${separator}app_ar.arb',
    );
    final en = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
    final ar = jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>;
    final problems = <String>[];

    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final arKeys = ar.keys.where((key) => !key.startsWith('@')).toSet();
    for (final key in enKeys.difference(arKeys)) {
      problems.add('missing in app_ar.arb: $key');
    }
    for (final key in arKeys.difference(enKeys)) {
      problems.add('missing in app_en.arb: $key');
    }

    for (final entry in ar.entries) {
      if (entry.key.startsWith('@')) {
        continue;
      }
      final value = entry.value;
      if (value is! String) {
        continue;
      }
      if (RegExp(r'\?{3,}').hasMatch(value)) {
        problems.add('mojibake ?-run in app_ar.arb:${entry.key}');
      }
      if (value.trim().isEmpty) {
        problems.add('empty value in app_ar.arb:${entry.key}');
      }
    }
    for (final entry in en.entries) {
      if (entry.key.startsWith('@')) {
        continue;
      }
      if (entry.value is String && (entry.value as String).trim().isEmpty) {
        problems.add('empty value in app_en.arb:${entry.key}');
      }
    }

    for (final key in enKeys) {
      final meta = en['@$key'];
      if (meta is Map && meta['placeholders'] is Map) {
        final expected = ((meta['placeholders']) as Map).keys.toSet();
        final actualMeta = ar['@$key'];
        if (actualMeta is! Map || actualMeta['placeholders'] is! Map) {
          problems.add('missing placeholder block app_ar.arb:@$key');
        } else {
          final actual = ((actualMeta['placeholders']) as Map).keys.toSet();
          if (expected.difference(actual).isNotEmpty ||
              actual.difference(expected).isNotEmpty) {
            problems.add('placeholder mismatch @$key');
          }
        }
      }
      for (final locale in const ['en', 'ar']) {
        final table = locale == 'en' ? en : ar;
        final value = table[key];
        if (value is! String) {
          continue;
        }
        for (final placeholder in RegExp(
          r'\{([A-Za-z_][A-Za-z0-9_]*)\}',
        ).allMatches(value).map((match) => match.group(1))) {
          final block = table['@$key'];
          final declared =
              block is Map &&
              block['placeholders'] is Map &&
              ((block['placeholders']) as Map).containsKey(placeholder);
          if (!declared) {
            problems.add('undeclared {$placeholder} in $locale:$key');
          }
        }
      }
    }

    for (final entry in en.entries.where((e) => !e.key.startsWith('@'))) {
      final value = entry.value;
      if (value is! String) {
        continue;
      }
      for (final term in _arbForbidden) {
        if (value.contains(term)) {
          problems.add('forbidden "$term" in app_en.arb:${entry.key}');
        }
      }
    }
    for (final entry in ar.entries.where((e) => !e.key.startsWith('@'))) {
      final value = entry.value;
      if (value is! String) {
        continue;
      }
      for (final term in _arbForbidden) {
        if (value.contains(term)) {
          problems.add('forbidden "$term" in app_ar.arb:${entry.key}');
        }
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
