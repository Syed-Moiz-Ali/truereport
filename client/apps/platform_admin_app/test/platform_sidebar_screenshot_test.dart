import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_shell.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';

class _MockLocaleController extends LocaleController {
  _MockLocaleController(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

Widget _screenshotWrapper({
  required Widget child,
  required GlobalKey boundaryKey,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 900),
}) {
  return ProviderScope(
    overrides: [
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        scaffoldBackgroundColor: PtTheme.canvas,
      ),
      home: RepaintBoundary(
        key: boundaryKey,
        child: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: child,
        ),
      ),
    ),
  );
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();

    final outDirs = [
      Directory('test/screenshots'),
      Directory(
          r'C:\Users\sanja\.gemini\antigravity\brain\2d875325-be2d-48c7-a5f1-8c4fcb7a4fb1\screenshots'),
    ];

    for (final dir in outDirs) {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      File('${dir.path}/$filename').writeAsBytesSync(bytes);
    }
  });
}

void main() {
  testWidgets('Capture platform sidebar screenshots at multiple viewports and RTL',
      (tester) async {
    final key = GlobalKey();

    // 1. Desktop 1280 (Figma baseline)
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      _screenshotWrapper(
        boundaryKey: key,
        surfaceSize: const Size(1280, 900),
        child: const PlatformShell(
          currentRoute: '/workshops',
          child: Center(
            child: Text(
              'Active Workshops — Fleet Infrastructure',
              style: TextStyle(fontSize: 18, color: PtTheme.ink),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, 'desktop_1280.png');

    // 2. Desktop 1440
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(
      _screenshotWrapper(
        boundaryKey: key,
        surfaceSize: const Size(1440, 900),
        child: const PlatformShell(
          currentRoute: '/master-library',
          child: Center(
            child: Text(
              'Master Library — Global Inspection Catalogues',
              style: TextStyle(fontSize: 18, color: PtTheme.ink),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, 'desktop_1440.png');

    // 3. Compact 768 (Tablet with drawer trigger)
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    await tester.pumpWidget(
      _screenshotWrapper(
        boundaryKey: key,
        surfaceSize: const Size(768, 1024),
        child: const PlatformShell(
          currentRoute: '/workshops',
          child: Center(
            child: Text(
              'Tablet Viewport (768px)',
              style: TextStyle(fontSize: 16, color: PtTheme.ink),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, 'compact_768.png');

    // 4. Compact 360 (Mobile viewport)
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(
      _screenshotWrapper(
        boundaryKey: key,
        surfaceSize: const Size(360, 800),
        child: const PlatformShell(
          currentRoute: '/workshops',
          child: Center(
            child: Text(
              'Mobile Viewport (360px)',
              style: TextStyle(fontSize: 14, color: PtTheme.ink),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, 'compact_360.png');

    // 5. Arabic RTL 1280
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      _screenshotWrapper(
        boundaryKey: key,
        locale: const Locale('ar'),
        surfaceSize: const Size(1280, 900),
        child: const PlatformShell(
          currentRoute: '/workshops',
          child: Center(
            child: Text(
              'لوحة تحكم المنصة — الورش',
              style: TextStyle(fontSize: 18, color: PtTheme.ink),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, 'arabic_rtl_1280.png');

    // 6. Arabic RTL 360
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(
      _screenshotWrapper(
        boundaryKey: key,
        locale: const Locale('ar'),
        surfaceSize: const Size(360, 800),
        child: const PlatformShell(
          currentRoute: '/workshops',
          child: Center(
            child: Text(
              'عرض الجوال باللغة العربية',
              style: TextStyle(fontSize: 14, color: PtTheme.ink),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(tester, key, 'arabic_rtl_360.png');

    tester.binding.setSurfaceSize(null);
  });
}
