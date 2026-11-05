import 'dart:io';

import 'package:api_client/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

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

List<Directory> _featureDirectories(Directory root) {
  final separator = Platform.pathSeparator;
  return <Directory>[
    Directory('${root.path}${separator}apps'),
    Directory('${root.path}${separator}packages${separator}auth'),
    Directory('${root.path}${separator}packages${separator}api_client'),
    Directory('${root.path}${separator}packages${separator}core'),
    Directory('${root.path}${separator}packages${separator}domain'),
    Directory('${root.path}${separator}packages${separator}offline_sync'),
  ];
}

Iterable<File> _dartFiles(Directory root, {bool includeTests = false}) sync* {
  final separator = Platform.pathSeparator;
  final pending = <Directory>[root];
  while (pending.isNotEmpty) {
    final directory = pending.removeLast();
    for (final entity in directory.listSync(followLinks: false)) {
      final path = entity.path;
      if (entity is Directory) {
        if (path.contains('${separator}build$separator') ||
            path.contains('$separator.dart_tool$separator')) {
          continue;
        }
        if (!includeTests && path.contains('${separator}test$separator')) {
          continue;
        }
        pending.add(entity);
        continue;
      }
      if (entity is! File || !path.endsWith('.dart')) {
        continue;
      }
      if (!includeTests && path.contains('${separator}test$separator')) {
        continue;
      }
      yield entity;
    }
  }
}

void main() {
  test('raw API paths exist only in ApiEndpoints', () {
    final root = _clientRoot();
    final pattern = RegExp(
      '/api/'
      'v1',
    );
    final offenders = <String>[];

    for (final directory in [
      Directory('${root.path}${Platform.pathSeparator}apps'),
      Directory('${root.path}${Platform.pathSeparator}packages'),
    ]) {
      for (final file in _dartFiles(directory, includeTests: true)) {
        if (file.path.endsWith('api_endpoints.dart')) {
          continue;
        }
        final lines = file.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          if (pattern.hasMatch(lines[index])) {
            offenders.add('${file.path}:${index + 1}');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test(
    'widgets outside design_system do not hardcode colours or font sizes',
    () {
      final root = _clientRoot();
      final separator = Platform.pathSeparator;
      final patterns = <RegExp>[
        RegExp(r'\bColors\.'),
        RegExp(r'Color\('),
        RegExp(r'fontSize\s*:'),
        RegExp(r'\bAppColors\b'),
        RegExp(r'\bAppSpacing\b'),
        RegExp(r'\bAppRadii\b'),
      ];
      final offenders = <String>[];

      for (final directory in [
        Directory('${root.path}${separator}apps'),
        Directory('${root.path}${separator}packages${separator}auth'),
        Directory('${root.path}${separator}packages${separator}api_client'),
        Directory('${root.path}${separator}packages${separator}core'),
        Directory('${root.path}${separator}packages${separator}domain'),
        Directory('${root.path}${separator}packages${separator}offline_sync'),
      ]) {
        if (!directory.existsSync()) {
          continue;
        }
        for (final file in _dartFiles(directory)) {
          final lines = file.readAsLinesSync();
          for (var index = 0; index < lines.length; index++) {
            if (patterns.any((pattern) => pattern.hasMatch(lines[index]))) {
              offenders.add('${file.path}:${index + 1}');
            }
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    },
  );

  test(
    'widgets outside design_system do not hardcode radii, shadows or gradients',
    () {
      final root = _clientRoot();
      final radiusPattern = RegExp(
        r'BorderRadius\.(?:circular|all\s*\(\s*Radius\.circular)'
        r'\s*\(\s*(-?\d+(?:\.\d+)?)',
      );
      final shadowPattern = RegExp(r'\bBoxShadow\s*\(');
      final gradientPattern = RegExp(r'\bLinearGradient\s*\(');
      final offenders = <String>[];

      for (final directory in _featureDirectories(root)) {
        if (!directory.existsSync()) {
          continue;
        }
        for (final file in _dartFiles(directory)) {
          final lines = file.readAsLinesSync();
          for (var index = 0; index < lines.length; index++) {
            final line = lines[index];
            final radiusMatch = radiusPattern.firstMatch(line);
            if (radiusMatch != null) {
              final value = double.parse(radiusMatch.group(1)!);
              if (value.abs() > 1) {
                offenders.add('${file.path}:${index + 1}');
                continue;
              }
            }
            if (shadowPattern.hasMatch(line) ||
                gradientPattern.hasMatch(line)) {
              offenders.add('${file.path}:${index + 1}');
            }
          }
        }
      }

      expect(offenders, isEmpty, reason: offenders.join('\n'));
    },
  );

  test('widgets outside design_system do not hardcode spacing tokens', () {
    final root = _clientRoot();
    const spacingValues = <double>[2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64];
    final edgeInsetsPattern = RegExp(
      r'EdgeInsets(?:Directional)?\.'
      r'(?:all|symmetric|only|fromLTRB|fromSTEB)\s*\(([^)]*)\)',
    );
    final sizedBoxPattern = RegExp(
      r'SizedBox\s*\(\s*(?:width|height)\s*:\s*(-?\d+(?:\.\d+)?)',
    );
    final numberPattern = RegExp(r'-?\d+(?:\.\d+)?');
    final offenders = <String>[];

    for (final directory in _featureDirectories(root)) {
      if (!directory.existsSync()) {
        continue;
      }
      for (final file in _dartFiles(directory)) {
        final lines = file.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          final line = lines[index];
          var flagged = false;

          final edgeInsetsMatch = edgeInsetsPattern.firstMatch(line);
          if (edgeInsetsMatch != null) {
            for (final match in numberPattern.allMatches(
              edgeInsetsMatch.group(1)!,
            )) {
              if (spacingValues.contains(double.parse(match.group(0)!))) {
                flagged = true;
                break;
              }
            }
          }

          if (!flagged) {
            final sizedBoxMatch = sizedBoxPattern.firstMatch(line);
            if (sizedBoxMatch != null &&
                spacingValues.contains(double.parse(sizedBoxMatch.group(1)!))) {
              flagged = true;
            }
          }

          if (flagged) {
            offenders.add('${file.path}:${index + 1}');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('widgets outside design_system do not hardcode font families', () {
    final root = _clientRoot();
    final pattern = RegExp(r'fontFamily\s*:');
    final offenders = <String>[];

    for (final directory in _featureDirectories(root)) {
      if (!directory.existsSync()) {
        continue;
      }
      for (final file in _dartFiles(directory)) {
        final lines = file.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          if (pattern.hasMatch(lines[index])) {
            offenders.add('${file.path}:${index + 1}');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('admin app has no TOTP challenge UI', () {
    final root = _clientRoot();
    final separator = Platform.pathSeparator;
    final offenders = <String>[];
    for (final file in _dartFiles(
      Directory(
        '${root.path}${separator}apps${separator}admin_app${separator}lib',
      ),
      includeTests: true,
    )) {
      final text = file.readAsStringSync().toLowerCase();
      if (text.contains('totp') || text.contains('2fa')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('ApiEndpoints centralises parameterised paths', () {
    const endpoints = ApiEndpoints(baseUrl: 'http://localhost:8080');
    expect(
      endpoints.authLogin,
      '/api/'
      'v1/auth/login',
    );
    expect(endpoints.workshopHierarchy('w1'), contains('/workshops/w1/'));
    expect(
      endpoints.itemVersionTranslation('i1', 'v1', 'ar'),
      contains('/translations/ar'),
    );
    expect(
      endpoints.guideImageContent('g1'),
      contains('/guide-images/g1/content'),
    );
    expect(endpoints.absolute('/health'), 'http://localhost:8080/health');
  });
}
