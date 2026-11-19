// Throwaway capture harness for the three dashboard directions.
//
// Real fonts, real tokens, sample data. Deleted with lib/preview/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/preview/dashboard_directions_preview.dart';

const _outDir = 'docs/evidence/dashboard_directions';
const _canvas = Color(0xFFF4F3F8);

Future<void> _loadRealFonts() async {
  final fontDir = Directory('../../packages/design_system/assets/fonts');
  if (!fontDir.existsSync()) {
    throw StateError('Font directory missing: ${fontDir.path}');
  }

  final families = <String, FontLoader>{};
  await for (final entity in fontDir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;

    String? family;
    if (name.startsWith('PlusJakartaSans')) {
      family = TrFonts.latin;
    } else if (name.startsWith('NotoSansArabic')) {
      family = TrFonts.arabicDefault;
    } else if (name.startsWith('IBMPlexSansArabic')) {
      family = TrFonts.arabicAlternative;
    } else if (name.startsWith('NotoSansSC')) {
      family = TrFonts.cjkFallback;
    } else if (name.startsWith('NotoSansTelugu')) {
      family = TrFonts.teluguFallback;
    }
    if (family == null) continue;

    final bytes = await entity.readAsBytes();
    final loader = families.putIfAbsent(family, () => FontLoader(family!));
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  for (final loader in families.values) {
    await loader.load();
  }

  final iconFile = File(
    'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
  );
  if (iconFile.existsSync()) {
    final iconBytes = await iconFile.readAsBytes();
    final iconLoader = FontLoader('MaterialIcons');
    iconLoader.addFont(Future.value(ByteData.sublistView(iconBytes)));
    await iconLoader.load();
  }
}

final _contentKey = GlobalKey();

Widget _measureApp(Widget child, double width) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: TrFonts.latin, useMaterial3: false),
    home: ColoredBox(
      color: _canvas,
      child: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: width,
            child: KeyedSubtree(key: _contentKey, child: child),
          ),
        ),
      ),
    ),
  );
}

Widget _captureApp(Widget child, Size size, GlobalKey boundaryKey) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: TrFonts.latin, useMaterial3: false),
    home: RepaintBoundary(
      key: boundaryKey,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: ColoredBox(color: _canvas, child: child),
      ),
    ),
  );
}

Future<void> _capture(
  WidgetTester tester,
  Widget child,
  double width,
  String filename,
) async {
  await tester.binding.setSurfaceSize(Size(width, 800));
  await tester.pumpWidget(_measureApp(child, width));
  await tester.pumpAndSettle();

  final measured = tester.getSize(find.byKey(_contentKey)).height;
  final height = measured.ceilToDouble() + 1;

  await tester.binding.setSurfaceSize(Size(width, height));
  final boundaryKey = GlobalKey();
  await tester.pumpWidget(_captureApp(child, Size(width, height), boundaryKey));
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final dir = Directory(_outDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('${dir.path}/$filename')
        .writeAsBytesSync(byteData.buffer.asUint8List(), flush: true);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadRealFonts);

  const directions = [
    (DirectionPreview.signalRoom, 'A'),
    (DirectionPreview.oneNumber, 'B'),
    (DirectionPreview.dossier, 'C'),
  ];

  testWidgets('capture direction style tiles and sections', (tester) async {
    for (final entry in directions) {
      final direction = entry.$1;
      final slug = entry.$2;

      await _capture(
        tester,
        directionStyleTile(direction),
        1440,
        'direction-${slug}_style-tile_1440.png',
      );

      await _capture(
        tester,
        directionSection(direction),
        1440,
        'direction-${slug}_section_1440.png',
      );

      await _capture(
        tester,
        directionSection(direction),
        390,
        'direction-${slug}_section_390.png',
      );

      await _capture(
        tester,
        directionSection(direction, rtl: true),
        390,
        'direction-${slug}_section_390-rtl.png',
      );
    }

    tester.binding.setSurfaceSize(null);
  });
}
