// Baseline gate: "new failures only".
//
// Reads `docs/baseline_allowlist.json` (the failures that already existed before
// the rebuild) and runs the analyzer + the test suite. It fails when:
//
//   1. a test fails that is not allowlisted;
//   2. an analyzer issue appears that is not allowlisted;
//   3. an allowlisted failure now passes — the list must stay truthful, so the
//      entry has to be deleted in the same change that fixes it.
//
// Usage (from client/apps/workshop_admin_app):
//   dart run tool/baseline_check.dart
//   dart run tool/baseline_check.dart --skip-analyze
//   dart run tool/baseline_check.dart --skip-tests
//
// Exit codes: 0 = clean, 1 = new failure or stale allowlist entry, 2 = usage/setup.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String _allowlistPath = 'docs/baseline_allowlist.json';

Future<void> main(List<String> args) async {
  final skipAnalyze = args.contains('--skip-analyze');
  final skipTests = args.contains('--skip-tests');
  final skipFormat = args.contains('--skip-format');

  final allowlistFile = File(_allowlistPath);
  if (!allowlistFile.existsSync()) {
    stderr.writeln('baseline_check: missing $_allowlistPath');
    exit(2);
  }
  final allowlist =
      jsonDecode(allowlistFile.readAsStringSync()) as Map<String, dynamic>;

  final allowedFailures = <String>{
    for (final entry in (allowlist['failures'] as List<dynamic>? ?? const []))
      (entry as Map<String, dynamic>)['name'] as String,
  };
  final allowedAnalyzer = <String>{
    for (final entry in (allowlist['analyzer'] as List<dynamic>? ?? const []))
      _analyzerKey(entry as Map<String, dynamic>),
  };

  var failed = false;

  if (!skipTests) {
    final failing = await _runTests();

    final newFailures = failing.difference(allowedFailures);
    // Allowlisted but no longer failing = fixed (or deleted). Either way the
    // list is now lying and must be corrected in the same change.
    final staleEntries = allowedFailures.difference(failing);

    if (newFailures.isNotEmpty) {
      failed = true;
      stderr.writeln('\nNEW TEST FAILURES (not in $_allowlistPath):');
      for (final name in newFailures.toList()..sort()) {
        stderr.writeln('  x $name');
      }
    }
    if (staleEntries.isNotEmpty) {
      failed = true;
      stderr.writeln(
        '\nSTALE ALLOWLIST ENTRIES (now passing — delete them from '
        '$_allowlistPath):',
      );
      for (final name in staleEntries.toList()..sort()) {
        stderr.writeln('  ~ $name');
      }
    }
    if (failing.isEmpty && allowedFailures.isEmpty) {
      stdout.writeln('tests: green (0 failures)');
    } else if (newFailures.isEmpty && staleEntries.isEmpty) {
      stdout.writeln('tests: ${failing.length} allowlisted failure(s), 0 new');
    }
  }

  if (!skipFormat) {
    final allowedFormat = <String>{
      for (final entry in (allowlist['format'] as List<dynamic>? ?? const []))
        (entry as String).replaceAll('\\', '/'),
    };
    final unformatted = await _runFormat();
    final newUnformatted = unformatted.difference(allowedFormat);
    final staleFormat = allowedFormat.difference(unformatted);

    if (newUnformatted.isNotEmpty) {
      failed = true;
      stderr.writeln('\nNEW UNFORMATTED FILES (run dart format on them):');
      for (final file in newUnformatted.toList()..sort()) {
        stderr.writeln('  x $file');
      }
    }
    if (staleFormat.isNotEmpty) {
      failed = true;
      stderr.writeln('\nSTALE FORMAT ALLOWLIST ENTRIES (now formatted):');
      for (final file in staleFormat.toList()..sort()) {
        stderr.writeln('  ~ $file');
      }
    }
    if (unformatted.isEmpty) {
      stdout.writeln('format: clean');
    } else if (newUnformatted.isEmpty) {
      stdout.writeln(
        'format: ${unformatted.length} allowlisted file(s), 0 new',
      );
    }
  }

  if (!skipAnalyze) {
    final issues = await _runAnalyze();
    final newIssues = issues.difference(allowedAnalyzer);
    final staleIssues = allowedAnalyzer.difference(issues.toSet());

    if (newIssues.isNotEmpty) {
      failed = true;
      stderr.writeln('\nNEW ANALYZER ISSUES (not in $_allowlistPath):');
      for (final issue in newIssues.toList()..sort()) {
        stderr.writeln('  x $issue');
      }
    }
    if (staleIssues.isNotEmpty) {
      failed = true;
      stderr.writeln('\nSTALE ANALYZER ALLOWLIST ENTRIES:');
      for (final issue in staleIssues.toList()..sort()) {
        stderr.writeln('  ~ $issue');
      }
    }
    if (issues.isEmpty) {
      stdout.writeln('analyzer: clean');
    } else if (newIssues.isEmpty) {
      stdout.writeln('analyzer: ${issues.length} allowlisted issue(s), 0 new');
    }
  }

  if (failed) {
    stderr.writeln('\nbaseline_check: FAILED');
    exit(1);
  }
  stdout.writeln('baseline_check: OK');
}

String _analyzerKey(Map<String, dynamic> entry) {
  final file = _normalizePath(entry['file'] as String? ?? '');
  return '${entry['code']}|$file|${entry['line']}';
}

String _issueKey(String severity, String code, String file, String line) {
  return '$code|${_normalizePath(file)}|$line';
}

/// The analyzer's machine format escapes separators (`E:\\a\\b.dart`).
String _normalizePath(String path) =>
    path.replaceAll(r'\\', '/').replaceAll('\\', '/');

/// Returns the names of every non-hidden test that failed.
Future<Set<String>> _runTests() async {
  stdout.writeln('running flutter test --reporter json ...');
  final process = await Process.start('flutter', <String>[
    'test',
    '--reporter',
    'json',
  ], runInShell: true);

  final namesById = <int, String>{};
  final failing = <String>{};

  Future<void> consume(Stream<List<int>> stream) async {
    await for (final line
        in stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (!line.startsWith('{')) {
        continue;
      }
      late final Map<String, dynamic> event;
      try {
        event = jsonDecode(line) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final type = event['type'];
      if (type == 'testStart') {
        final test = event['test'] as Map<String, dynamic>;
        final id = test['id'] as int;
        final name = test['name'] as String;
        namesById[id] = name;
      } else if (type == 'testDone') {
        final id = event['testID'] as int;
        final name = namesById[id];
        if (name == null) {
          continue;
        }
        if (event['hidden'] == true || event['skipped'] == true) {
          continue;
        }
        if (event['result'] != 'success') {
          failing.add(name);
        }
      }
    }
  }

  final outDone = consume(process.stdout);
  final errDone = consume(process.stderr);
  await Future.wait(<Future<void>>[outDone, errDone]);
  final exitCode = await process.exitCode;

  // A non-zero exit with no parsed failure means the suite itself broke
  // (compile error, missing device). Surface it as a failure of the gate.
  if (exitCode != 0 && failing.isEmpty) {
    failing.add('<suite failed to run> (flutter test exit $exitCode)');
  }
  return failing;
}

/// Files `dart format` would change, as repo-relative forward-slash paths.
Future<Set<String>> _runFormat() async {
  stdout.writeln('running dart format --output=none lib test tool ...');
  final result = await Process.run('dart', <String>[
    'format',
    '--output=none',
    'lib',
    'test',
    'tool',
  ], runInShell: true);
  final changed = <String>{};
  for (final line in const LineSplitter().convert(
    '${result.stdout}${result.stderr}',
  )) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('Changed ')) {
      continue;
    }
    changed.add(
      trimmed.substring('Changed '.length).trim().replaceAll('\\', '/'),
    );
  }
  return changed;
}

Future<Set<String>> _runAnalyze() async {
  stdout.writeln('running dart analyze --format=machine ...');
  final result = await Process.run('dart', <String>[
    'analyze',
    '--format=machine',
    '.',
  ], runInShell: true);
  final issues = <String>{};
  for (final line in const LineSplitter().convert(
    '${result.stdout}${result.stderr}',
  )) {
    final parts = line.split('|');
    if (parts.length < 5) {
      continue;
    }
    final severity = parts[0];
    if (severity != 'ERROR' && severity != 'WARNING' && severity != 'INFO') {
      continue;
    }
    // SEVERITY|TYPE|CODE|FILE|LINE|COL|LENGTH|MESSAGE
    issues.add(_issueKey(severity, parts[2], parts[3], parts[4]));
  }
  return issues;
}
