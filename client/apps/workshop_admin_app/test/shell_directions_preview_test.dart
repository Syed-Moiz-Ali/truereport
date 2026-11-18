import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/real_fonts.dart';
import 'support/shell_direction_previews.dart';

/// Gate 3 evidence for the app-shell rebuild: one rendered, real-font artefact
/// per direction at 1440 and 390 plus a style tile.
///
/// Writes to `docs/evidence/shell_directions/`. Nothing in `lib/` is touched.
const String _outDir = 'docs/evidence/shell_directions';

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    expect(boundary, isNotNull, reason: name);
    final image = await boundary!.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull, reason: name);
    final dir = Directory(_outDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('${dir.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  Size size,
  GlobalKey key,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: RepaintBoundary(
        key: key,
        // Material ancestor: without it Flutter paints the "unstyled text"
        // yellow underline, which would invalidate the evidence.
        child: Material(
          color: AppTheme.light.scaffoldBackgroundColor,
          child: SizedBox.fromSize(
            size: size,
            child: MediaQuery(
              data: MediaQueryData(size: size),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('real fonts are loaded for shell evidence', () {
    expect(RealFonts.isLoaded, isTrue);
    expect(RealFonts.missingFamilies, isEmpty);
  });

  final directions = <String, Widget>{
    'a-spine': const ShellDirectionASpine(),
    'b-ledger': const ShellDirectionBLedger(),
    'c-dock': const ShellDirectionCDock(),
  };

  for (final entry in directions.entries) {
    testWidgets('${entry.key} 1440', (tester) async {
      final key = GlobalKey();
      await _pump(tester, entry.value, const Size(1440, 900), key);
      expect(tester.takeException(), isNull);
      await _capture(tester, key, '${entry.key}-1440');
    });

    testWidgets('${entry.key} 390', (tester) async {
      final key = GlobalKey();
      await _pump(tester, entry.value, const Size(390, 844), key);
      expect(tester.takeException(), isNull);
      await _capture(tester, key, '${entry.key}-390');
    });
  }

  final tiles = <String, (String, String)>{
    'a': (
      'The spine',
      'Icon rail + command bar. Navigation never takes text width; search and language live where they are used.',
    ),
    'b': (
      'The ledger',
      'Horizontal section tabs in a 64 px band. No sidebar: the content gets the full width.',
    ),
    'c': (
      'The dock',
      'Content-first. Navigation floats at the bottom and only the active item shows its name.',
    ),
  };

  for (final entry in tiles.entries) {
    testWidgets('tile ${entry.key}', (tester) async {
      final key = GlobalKey();
      await _pump(
        tester,
        ShellDirectionTile(
          letter: entry.key.toUpperCase(),
          name: entry.value.$1,
          note: entry.value.$2,
        ),
        const Size(900, 380),
        key,
      );
      expect(tester.takeException(), isNull);
      await _capture(tester, key, '${entry.key}-style-tile');
    });
  }
}
