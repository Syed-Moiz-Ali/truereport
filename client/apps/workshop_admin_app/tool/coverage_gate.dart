// Coverage floor for the files wave 2 pinned with new tests.
//
// `tool/baseline_check.dart` answers "did anything regress?". This answers the
// narrower question the brief asks: the files that now have contract/mapper
// tests must keep that coverage, so a later edit cannot quietly delete the
// tests and leave the gate green.
//
// Usage (from client/apps/workshop_admin_app):
//   dart run tool/coverage_gate.dart              # run tests, then enforce
//   dart run tool/coverage_gate.dart --no-run     # reuse coverage/lcov.info
//
// Exit codes: 0 = all floors met, 1 = a floor regressed, 2 = setup/usage.
import 'dart:io';

/// Line coverage floors, deliberately a little under what the suite measures
/// today so an unrelated refactor does not fail the gate, while deleting the
/// tests does.
const Map<String, double> _floors = <String, double>{
  // Phase B: the one time policy (naive vs offset, empty, unparseable).
  'lib/src/workshop_clock.dart': 0.95,
  // Phase A: the DTO mappers (CleanJob, JobPage, CleanJobCounts, assignments,
  // review). The file also holds models this wave does not touch.
  'lib/src/workshop_job_models.dart': 0.45,
  // Shared row/label presentation used by the dashboard and the queue.
  'lib/src/features/jobs/job_presentation.dart': 0.65,
};

Future<void> main(List<String> args) async {
  final runTests = !args.contains('--no-run');
  final lcov = File('coverage/lcov.info');

  if (runTests) {
    stdout.writeln('running flutter test --coverage ...');
    final result = await Process.run('flutter', <String>[
      'test',
      '--coverage',
    ], runInShell: true);
    // Keep the tail of the run visible without dumping every test line.
    final output = '${result.stdout}${result.stderr}';
    final lines = const LineSplitterSafe().split(output);
    for (final line
        in lines.length > 6 ? lines.sublist(lines.length - 6) : lines) {
      stdout.writeln(line);
    }
    if (result.exitCode != 0) {
      stderr.writeln(
        'coverage_gate: flutter test failed (exit ${result.exitCode})',
      );
      exit(1);
    }
  }

  if (!lcov.existsSync()) {
    stderr.writeln(
      'coverage_gate: missing coverage/lcov.info (run without --no-run)',
    );
    exit(2);
  }

  final coverage = _parseLcov(lcov.readAsLinesSync());
  var failed = false;
  stdout.writeln(
    '\nfile                                        lines      floor',
  );
  for (final entry in _floors.entries) {
    final hit = coverage[entry.key];
    if (hit == null) {
      stderr.writeln('  x ${entry.key}: not present in lcov.info');
      failed = true;
      continue;
    }
    final measured = hit.total == 0 ? 0.0 : hit.hit / hit.total;
    final ok = measured + 1e-9 >= entry.value;
    if (!ok) {
      failed = true;
    }
    stdout.writeln(
      '${ok ? '  ok' : '  x '} ${entry.key.padRight(44)} '
      '${'${hit.hit}/${hit.total}'.padLeft(9)}  '
      '${(measured * 100).toStringAsFixed(1)}%  '
      '>= ${(entry.value * 100).toStringAsFixed(0)}%',
    );
  }

  if (failed) {
    stderr.writeln('\ncoverage_gate: FAILED');
    exit(1);
  }
  stdout.writeln('\ncoverage_gate: OK');
}

typedef _Hit = ({int hit, int total});

Map<String, _Hit> _parseLcov(List<String> lines) {
  final result = <String, _Hit>{};
  String? path;
  var hit = 0;
  var total = 0;
  for (final line in lines) {
    if (line.startsWith('SF:')) {
      path = line.substring(3).trim().replaceAll('\\', '/');
      hit = 0;
      total = 0;
    } else if (line.startsWith('LH:')) {
      hit = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LF:')) {
      total = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line == 'end_of_record' && path != null) {
      // Keep the suffix match so absolute paths from the lcov tool still map.
      for (final key in _floors.keys) {
        if (path.endsWith(key.replaceAll('/', Platform.pathSeparator)) ||
            path.endsWith(key)) {
          result[key] = (hit: hit, total: total);
        }
      }
      path = null;
    }
  }
  return result;
}

/// Minimal line splitter so the tool stays dependency-free outside the SDK.
class LineSplitterSafe {
  const LineSplitterSafe();

  List<String> split(String text) => text.split(RegExp(r'\r?\n'));
}
