import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';

/// English copy is not shipped in Flutter; it is served by the backend bundle.
/// Tests load that same bundle from the backend catalog so screens render the
/// real strings.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  _loadBackendRemoteEnglish('technician');
  await testMain();
}

void _loadBackendRemoteEnglish(String client) {
  final root = _repoRoot();
  final i18n = Directory(
    '${root.path}${Platform.pathSeparator}server'
    '${Platform.pathSeparator}src${Platform.pathSeparator}main'
    '${Platform.pathSeparator}resources${Platform.pathSeparator}i18n',
  );
  final merged = <String, String>{};
  for (final name in <String>['common', client]) {
    final file = File(
      '${i18n.path}${Platform.pathSeparator}$name'
      '${Platform.pathSeparator}en.json',
    );
    if (!file.existsSync()) continue;
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) continue;
    decoded.forEach((key, value) {
      if (key is String && value is String) merged[key] = value;
    });
  }
  setRemoteEnglish(merged);
}

Directory _repoRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final marker = Directory(
      '${directory.path}${Platform.pathSeparator}server'
      '${Platform.pathSeparator}src${Platform.pathSeparator}main'
      '${Platform.pathSeparator}resources${Platform.pathSeparator}i18n',
    );
    if (marker.existsSync()) return directory;
    if (directory.parent.path == directory.path) break;
    directory = directory.parent;
  }
  throw StateError('Could not locate the backend i18n catalog');
}
