/// Test bootstrap for the technician app.
///
/// Every test under `test/` runs behind this config, so the real Plus Jakarta
/// Sans faces that ship with `design_system` are registered before any test
/// body executes, and `intl` date symbols are initialized so the queue
/// formatters can be exercised without a widget tree. The default test font
/// (Ahem) draws solid boxes and is not evidence of anything: if a face cannot
/// be read this throws instead of letting typography silently degrade to Ahem.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The Latin family declared by `design_system/pubspec.yaml`.
const String plusJakartaSans = 'Plus Jakarta Sans';

/// Families Flutter will look at for a design-system style.
///
/// Flutter registers fonts declared by a package under the
/// `packages/<package>/` prefix, so both spellings must resolve to the real
/// faces in tests.
const List<String> _plusJakartaSansFamilies = <String>[
  plusJakartaSans,
  'packages/design_system/Plus Jakarta Sans',
];

/// The five weights `design_system` declares (Regular → ExtraBold).
const List<String> _faceWeights = <String>[
  'Regular',
  'Medium',
  'SemiBold',
  'Bold',
  'ExtraBold',
];

/// Font assets live in the `design_system` package and are bundled under
/// `packages/design_system/` in every target, including the test bundle.
const String _assetDirectory = 'packages/design_system/assets/fonts';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await loadPlusJakartaSans();
  await loadMaterialIcons();
  await testMain();
}

/// Registers the Material icon font so goldens and design previews show real
/// glyphs instead of empty boxes.
///
/// The SDK ships the font under `bin/cache/artifacts/material_fonts`; when the
/// runner does not expose `FLUTTER_ROOT` this is a no-op and icons fall back to
/// the test bundle's behaviour.
Future<void> loadMaterialIcons() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null || root.isEmpty) {
    return;
  }
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) {
    return;
  }
  final bytes = await file.readAsBytes();
  for (final family in const <String>['MaterialIcons', 'Material Icons']) {
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

/// Registers the real Plus Jakarta Sans faces for [plusJakartaSans] and for
/// the package-prefixed family name.
Future<void> loadPlusJakartaSans() async {
  final faces = <String, ByteData>{};
  for (final weight in _faceWeights) {
    faces[weight] = await _loadFace(weight);
  }
  for (final family in _plusJakartaSansFamilies) {
    final loader = FontLoader(family);
    for (final weight in _faceWeights) {
      loader.addFont(Future<ByteData>.value(faces[weight]));
    }
    await loader.load();
  }
}

Future<ByteData> _loadFace(String weight) async {
  final fileName = 'PlusJakartaSans-$weight.ttf';
  final assetKey = '$_assetDirectory/$fileName';
  try {
    return await rootBundle.load(assetKey);
  } catch (_) {
    // The bundle is not always available (e.g. running a test file through a
    // tool that skips asset assembly), so fall back to the source tree.
  }
  final file = _findSourceFont(fileName);
  if (file == null) {
    throw StateError(
      'Could not load Plus Jakarta Sans ($fileName) from "$assetKey" or from '
      'the design_system source tree. Refusing to fall back to Ahem glyphs.',
    );
  }
  return ByteData.sublistView(await file.readAsBytes());
}

/// Walks up from the current directory looking for the package font folder.
///
/// Works whether the runner starts in `technician_app` or in the `client`
/// workspace root.
File? _findSourceFont(String fileName) {
  var directory = Directory.current.absolute;
  for (var depth = 0; depth < 5; depth += 1) {
    for (final prefix in const <String>['', 'client/']) {
      final candidate = File(
        '${directory.path}/$prefix$_assetDirectory/$fileName',
      );
      if (candidate.existsSync()) {
        return candidate;
      }
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      return null;
    }
    directory = parent;
  }
  return null;
}
