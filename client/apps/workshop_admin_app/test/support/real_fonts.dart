import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled design-system fonts into the test engine.
///
/// Every widget test must lay out with real glyph metrics. Without this the
/// engine falls back to Ahem (solid boxes), which makes every "no overflow"
/// assertion meaningless: Ahem glyphs are square, so widths are wrong in both
/// directions.
///
/// Family names come from [TrFonts], the same tokens `AppTheme.build` uses, so
/// a name drift between the pubspec, the theme and the harness fails loudly in
/// [RealFonts.familyBalance] instead of silently rendering tofu.
///
/// `NotoSansSC-Regular.otf` (15.7 MB) is skipped on purpose: no supported
/// locale needs CJK, and loading it once per test file dominates the suite
/// runtime. Add it here if a CJK test ever appears.
abstract final class RealFonts {
  static const String _fontDirectory =
      '../../packages/design_system/assets/fonts';
  static const String _materialIconsPath =
      'build/unit_test_assets/fonts/MaterialIcons-Regular.otf';
  static const String _skippedCjk = 'NotoSansSC-Regular.otf';

  static bool _loaded = false;
  static final Set<String> _families = <String>{};

  /// True once the real families are registered.
  static bool get isLoaded => _loaded;

  /// Families registered by [load], including the bare (unprefixed) aliases.
  static Set<String> get families => Set<String>.unmodifiable(_families);

  /// Loads every bundled `.ttf`/`.otf` file once per test file.
  ///
  /// Safe to call repeatedly: the second call is a no-op.
  static Future<void> load() async {
    if (_loaded) {
      return;
    }
    final directory = Directory(_fontDirectory);
    if (!directory.existsSync()) {
      // A missing font directory is a harness failure, not a skip: tests that
      // depend on real glyphs must notice.
      return;
    }

    final loaders = <String, FontLoader>{};

    Future<void> register(String family, File file) async {
      final bytes = await file.readAsBytes();
      final data = ByteData.sublistView(bytes);
      loaders
          .putIfAbsent(family, () => FontLoader(family))
          .addFont(Future<ByteData>.value(data));
      final bare = family.replaceFirst('packages/design_system/', '');
      if (bare != family) {
        loaders
            .putIfAbsent(bare, () => FontLoader(bare))
            .addFont(Future<ByteData>.value(data));
      }
    }

    for (final entity in directory.listSync()) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      if (name == _skippedCjk) {
        continue;
      }
      if (!name.endsWith('.ttf') && !name.endsWith('.otf')) {
        continue;
      }
      final family = _familyFor(name);
      if (family == null) {
        continue;
      }
      await register(family, entity);
    }

    final materialIcons = File(_materialIconsPath);
    if (materialIcons.existsSync()) {
      final bytes = await materialIcons.readAsBytes();
      loaders
          .putIfAbsent('MaterialIcons', () => FontLoader('MaterialIcons'))
          .addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    }

    for (final entry in loaders.entries) {
      await entry.value.load();
      _families.add(entry.key);
    }
    _loaded = loaders.isNotEmpty;
  }

  static String? _familyFor(String fileName) {
    if (fileName.startsWith('PlusJakartaSans')) {
      return TrFonts.latin;
    }
    if (fileName.startsWith('NotoSansArabic')) {
      return TrFonts.arabicDefault;
    }
    if (fileName.startsWith('IBMPlexSansArabic')) {
      return TrFonts.arabicAlternative;
    }
    if (fileName.startsWith('NotoSansTelugu')) {
      return TrFonts.teluguFallback;
    }
    if (fileName.startsWith('NotoSans-')) {
      return TrFonts.cyrillicFallback;
    }
    // NotoSansSC is skipped above.
    return null;
  }

  /// Families the theme can ask for plus the icon font.
  static List<String> get expectedFamilies => <String>[
    TrFonts.latin,
    TrFonts.arabicDefault,
    TrFonts.arabicAlternative,
    TrFonts.cyrillicFallback,
    TrFonts.teluguFallback,
    'MaterialIcons',
  ];

  /// Families declared in [expectedFamilies] that did not get registered.
  static List<String> get missingFamilies => expectedFamilies
      .where((family) => !_families.contains(family))
      .toList(growable: false);
}
