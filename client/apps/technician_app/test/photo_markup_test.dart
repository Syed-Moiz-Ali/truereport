import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:technician_app/src/features/inspection/photo_markup_page.dart';

import 'support/f2a_test_fonts.dart';
import 'support/ui_strings_harness.dart';

Future<Uint8List> _sourcePng(WidgetTester tester, int width, int height) async {
  final bytes = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFF2F4A3E),
    );
    canvas.drawRect(
      Rect.fromLTWH(width * 0.3, height * 0.3, width * 0.2, height * 0.2),
      Paint()..color = const Color(0xFFBFB2A0),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

Future<void> _openEditor(WidgetTester tester, Uint8List png) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: testLocalizationsDelegates,
      builder: (context, child) => UiStringsScope(
        strings: baseStrings(),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const _Host(),
    ),
  );
  await tester.tap(find.text('open'));
  await _settleEditor(tester);
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => openMarkup(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

/// Set by tests before pumping, so the page can decode a generated image.
Uint8List? _photo;

Future<void> _settleEditor(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await tester.pump();
}

Future<void> openMarkup(BuildContext context) async {
  await Navigator.of(context).push<MarkedPhoto>(
    MaterialPageRoute(
      builder: (_) =>
          PhotoMarkupPage(photoBytes: _photo!, title: 'Front bumper condition'),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadF2AFonts);

  setUp(() {
    _photo = null;
  });

  group('markup strokes', () {
    test('a circle is bounded by its drag corners', () {
      final stroke = MarkupStroke(
        tool: MarkupTool.circle,
        colour: const Color(0xFFD14B64),
        points: const [Offset(0.2, 0.3), Offset(0.6, 0.7)],
      );
      final bounds = stroke.bounds;
      expect(bounds.left, closeTo(0.2, 1e-9));
      expect(bounds.top, closeTo(0.3, 1e-9));
      expect(bounds.right, closeTo(0.6, 1e-9));
      expect(bounds.bottom, closeTo(0.7, 1e-9));
    });

    test('a pen stroke is bounded by every point', () {
      final stroke = MarkupStroke(
        tool: MarkupTool.pen,
        colour: const Color(0xFFFFFFFF),
        points: const [Offset(0.5, 0.5), Offset(0.1, 0.55), Offset(0.4, 0.9)],
      );
      final bounds = stroke.bounds;
      expect(bounds.left, closeTo(0.1, 1e-9));
      expect(bounds.top, closeTo(0.5, 1e-9));
      expect(bounds.right, closeTo(0.5, 1e-9));
      expect(bounds.bottom, closeTo(0.9, 1e-9));
    });
  });

  testWidgets('the editor refuses to save before anything is drawn', (
    tester,
  ) async {
    _photo = await _sourcePng(tester, 96, 72);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _openEditor(tester, _photo!);

    expect(find.text('Draw on the photo first'), findsOneWidget);
    expect(find.text('Save marked photo'), findsNothing);
    expect(find.text('Front bumper condition'), findsOneWidget);
  });

  testWidgets('drawing enables save, and saving returns a marked JPEG', (
    tester,
  ) async {
    _photo = await _sourcePng(tester, 96, 72);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    MarkedPhoto? marked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) => UiStringsScope(
          strings: baseStrings(),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                marked = await Navigator.of(context).push<MarkedPhoto>(
                  MaterialPageRoute(
                    builder: (_) => PhotoMarkupPage(
                      photoBytes: _photo!,
                      title: 'Front bumper condition',
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await _settleEditor(tester);

    final canvas = tester.getRect(find.byType(PhotoMarkupPage));
    await tester.dragFrom(
      Offset(canvas.center.dx - 60, canvas.center.dy - 40),
      const Offset(120, 80),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save marked photo'), findsOneWidget);
    await tester.tap(find.text('Save marked photo'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 700)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(marked, isNotNull);
    expect(marked!.width, 96);
    expect(marked!.height, 72);
    // JPEG magic bytes: the marked photo is ordinary photo evidence.
    expect(marked!.bytes.length, greaterThan(100));
    expect(marked!.bytes[0], 0xFF);
    expect(marked!.bytes[1], 0xD8);
  });

  testWidgets('clear and undo remove the mark', (tester) async {
    _photo = await _sourcePng(tester, 96, 72);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _openEditor(tester, _photo!);

    final canvas = tester.getRect(find.byType(PhotoMarkupPage));
    await tester.dragFrom(
      Offset(canvas.center.dx - 40, canvas.center.dy - 30),
      const Offset(80, 60),
    );
    await tester.pumpAndSettle();
    expect(find.text('Save marked photo'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.undo_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Draw on the photo first'), findsOneWidget);

    await tester.dragFrom(
      Offset(canvas.center.dx - 40, canvas.center.dy - 30),
      const Offset(80, 60),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.layers_clear_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Draw on the photo first'), findsOneWidget);
  });
}
