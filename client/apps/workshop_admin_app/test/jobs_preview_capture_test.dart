import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_admin_app/preview/jobs_preview_app.dart';

/// Throwaway capture test for the three jobs surfaces. Writes real-font PNGs
/// into `docs/design-preview/jobs/`, then is deleted with `lib/preview/`.
const String _outDir = 'docs/design-preview/jobs';

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

Future<void> _shoot(
  WidgetTester tester,
  PreviewSurface surface,
  String name,
  Size size,
) async {
  final key = GlobalKey();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    RepaintBoundary(key: key, child: buildPreview(surface)),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: name);
  await _capture(tester, key, name);
}

void main() {
  testWidgets('capture public link 1440', (tester) async {
    await _shoot(
      tester,
      PreviewSurface.publicLink,
      'jobs_public_link_1440',
      const Size(1440, 1000),
    );
  });

  testWidgets('capture public link 390', (tester) async {
    await _shoot(
      tester,
      PreviewSurface.publicLink,
      'jobs_public_link_390',
      const Size(390, 844),
    );
  });

  testWidgets('capture notifications 1440', (tester) async {
    await _shoot(
      tester,
      PreviewSurface.notifications,
      'jobs_notifications_1440',
      const Size(1440, 1000),
    );
  });

  testWidgets('capture notifications 390', (tester) async {
    await _shoot(
      tester,
      PreviewSurface.notifications,
      'jobs_notifications_390',
      const Size(390, 844),
    );
  });

  testWidgets('capture archive 1440', (tester) async {
    await _shoot(
      tester,
      PreviewSurface.archive,
      'jobs_archive_1440',
      const Size(1440, 1000),
    );
  });

  testWidgets('capture archive 390', (tester) async {
    await _shoot(
      tester,
      PreviewSurface.archive,
      'jobs_archive_390',
      const Size(390, 844),
    );
  });
}
