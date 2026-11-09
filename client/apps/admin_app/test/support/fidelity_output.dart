import 'dart:io';

/// Test-only fidelity output routing.
///
/// Normal test runs (no flag) write captures to the system temp directory,
/// so they never modify tracked files under `docs/`. Curated fidelity
/// artifacts are published to `docs/ui/<relative>` only when the suite runs
/// with `--dart-define=UPDATE_FIDELITY=true`.
Directory fidelityOutputDir(Directory repoRoot, String docsUiRelative) {
  return Directory(
    resolveFidelityPath(
      repoRootPath: repoRoot.path,
      docsUiRelative: docsUiRelative,
      update: const bool.fromEnvironment('UPDATE_FIDELITY'),
    ),
  );
}

/// Pure path resolver (unit-tested by `fidelity_write_guard_test.dart`).
String resolveFidelityPath({
  required String repoRootPath,
  required String docsUiRelative,
  required bool update,
}) {
  if (update) {
    return '$repoRootPath/docs/ui/$docsUiRelative';
  }
  return '${Directory.systemTemp.path}/truereport-fidelity/$docsUiRelative';
}
