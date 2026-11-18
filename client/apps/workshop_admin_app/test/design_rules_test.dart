import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the consumer-grade rebuild rules that are cheap to enforce at the
/// source level and expensive to notice in screenshots.
Directory _appLib() {
  final separator = Platform.pathSeparator;
  var directory = Directory.current;
  while (true) {
    final marker = File(
      '${directory.path}${separator}lib${separator}main.dart',
    );
    final pubspec = File('${directory.path}${separator}pubspec.yaml');
    if (marker.existsSync() &&
        pubspec.existsSync() &&
        pubspec.readAsStringSync().contains('workshop_admin_app')) {
      return Directory('${directory.path}${separator}lib');
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Could not find workshop_admin_app lib directory.');
    }
    directory = parent;
  }
}

Iterable<File> _dartFiles(Directory directory) sync* {
  for (final entity in directory.listSync(followLinks: false)) {
    if (entity is Directory) {
      yield* _dartFiles(entity);
    } else if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

void main() {
  test('no unverified security, certification or telemetry claims', () {
    final banned = <String>[
      'SOC-2',
      'SOC 2',
      '256-bit',
      'TLS 1.3',
      'blockchain',
      'GRID V4.2',
      'Latency 14ms',
      'Live Bay Telemetry',
      'Cryptographic Audit',
      'HIGH-THROUGHPUT',
    ];
    final offenders = <String>[];
    for (final file in _dartFiles(_appLib())) {
      final source = file.readAsStringSync();
      for (final claim in banned) {
        if (source.contains(claim)) {
          offenders.add('${file.path}: $claim');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('workshop screens never render a bare full-page generic error', () {
    // The only owned recovery pattern is WorkshopErrorState with a retry.
    final offenders = <String>[];
    for (final file in _dartFiles(_appLib())) {
      final source = file.readAsStringSync();
      if (!source.contains('WorkshopErrorState') &&
          source.contains('Something went wrong')) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
