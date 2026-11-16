import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/components/platform_buttons.dart';
import 'package:platform_admin_app/src/components/platform_chips.dart';
import 'package:platform_admin_app/src/components/platform_context_bar.dart';
import 'package:platform_admin_app/src/components/platform_shell.dart';
import 'package:platform_admin_app/src/components/platform_toolbar.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';

import 'support/ui_message_fixtures.dart';

class _MockLocaleController extends LocaleController {
  _MockLocaleController(this._initial);
  final Locale _initial;

  @override
  Locale build() => _initial;
}

Future<void> _loadRealFonts() async {
  final fontDir = Directory('../../packages/design_system/assets/fonts');
  if (!fontDir.existsSync()) return;

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
    } else if (name.startsWith('NotoSans-')) {
      family = TrFonts.cyrillicFallback;
    }

    if (family == null) continue;
    final bytes = await entity.readAsBytes();
    final loader = families.putIfAbsent(family, () => FontLoader(family!));
    loader.addFont(Future.value(ByteData.sublistView(bytes)));

    // Also register unprefixed family name for theme lookups
    final bareFamily = family.replaceFirst('packages/design_system/', '');
    final bareLoader = families.putIfAbsent(
      bareFamily,
      () => FontLoader(bareFamily),
    );
    bareLoader.addFont(Future.value(ByteData.sublistView(bytes)));
  }

  // Load MaterialIcons font
  const materialPath = 'build/unit_test_assets/fonts/MaterialIcons-Regular.otf';
  final materialFile = File(materialPath);
  if (materialFile.existsSync()) {
    final bytes = await materialFile.readAsBytes();
    final loader = families.putIfAbsent(
      'MaterialIcons',
      () => FontLoader('MaterialIcons'),
    );
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }

  for (final entry in families.entries) {
    await entry.value.load();
  }
}

final _testLanguages = [
  const PlatformLanguage(
    code: 'en',
    nativeName: 'English',
    direction: 'ltr',
    status: 'LIVE',
    isDefault: true,
    active: true,
    sortOrder: 0,
  ),
];
Widget _buildSamplePageContent() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      final titleBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workshop Fleet Management', style: PtTheme.pageTitle),
          const SizedBox(height: 4),
          Text(
            'Manage verified workshop facilities, diagnostic hardware, and operational coverage.',
            style: PtTheme.body.copyWith(color: PtTheme.muted),
          ),
        ],
      );

      final actionButtons = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PlatformSecondaryButton(
            label: 'Export Audit',
            icon: Icons.download_rounded,
            onPressed: () {},
          ),
          PlatformPrimaryButton(
            label: 'Register Workshop',
            icon: Icons.add_rounded,
            onPressed: () {},
          ),
        ],
      );

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMobile) ...[
              titleBlock,
              const SizedBox(height: 12),
              actionButtons,
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  actionButtons,
                ],
              ),
            ],
            const SizedBox(height: 20),
            PlatformToolbar(
              searchHint: 'Search workshops by code or name...',
              countLabel: '12 workshops active',
              filters: [
                PlatformFilterChip(
                  label: 'Region: Central',
                  selected: true,
                  onTap: () {},
                ),
                const SizedBox(width: 6),
                PlatformFilterChip(
                  label: 'Status: Active',
                  selected: false,
                  onTap: () {},
                ),
              ],
              trailing: PlatformGhostButton(
                label: 'Reset filters',
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 360,
              decoration: BoxDecoration(
                color: PtTheme.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PtTheme.border),
              ),
              child: Center(
                child: Text(
                  'Active Workshop Fleet & Inspection Roster',
                  style: PtTheme.sectionTitle.copyWith(color: PtTheme.muted),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
Widget _screenshotHarness({
  required Widget child,
  required GlobalKey boundaryKey,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(1280, 900),
}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(fakeEnUiStrings()),
      platformLocaleProvider.overrideWith(() => _MockLocaleController(locale)),
      platformLanguagesProvider.overrideWith((ref) async => _testLanguages),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: TrFonts.latin,
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
  _expectActionableSidebarIfVisible(tester);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();

    final outDirs = [
      Directory('test/screenshots/shell_real'),
      Directory('test/screenshots'),
      Directory(
        r'C:\Users\sanja\.gemini\antigravity\brain\cca80726-f50d-4167-b93e-5a699c602442\screenshots',
      ),
    ];

    for (final dir in outDirs) {
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('${dir.path}/$filename');
      for (var attempt = 0; attempt < 6; attempt++) {
        try {
          file.writeAsBytesSync(bytes, flush: true);
          break;
        } on FileSystemException {
          if (attempt == 5) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealFonts();
  });

  group('Phase 1C Real Font Shell Verification', () {
    testWidgets('Capture real font shell screenshots across viewports', (
      tester,
    ) async {
      final key = GlobalKey();

      // 1. 1440 Desktop
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(
        _screenshotHarness(
          boundaryKey: key,
          surfaceSize: const Size(1440, 900),
          child: PlatformShell(
            currentRoute: '/workshops',
            contextBar: PlatformContextBar(
              breadcrumbs: [
                ContextBreadcrumbItem(label: 'Platform Admin', onTap: () {}),
                const ContextBreadcrumbItem(label: 'Workshops'),
              ],
            ),
            child: _buildSamplePageContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'desktop_1440.png');

      // 2. 1280 Desktop
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        _screenshotHarness(
          boundaryKey: key,
          surfaceSize: const Size(1280, 900),
          child: PlatformShell(
            currentRoute: '/workshops',
            contextBar: PlatformContextBar(
              breadcrumbs: [
                ContextBreadcrumbItem(label: 'Platform Admin', onTap: () {}),
                const ContextBreadcrumbItem(label: 'Workshops'),
              ],
            ),
            child: _buildSamplePageContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'desktop_1280.png');

      // 3. 768 Tablet
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        _screenshotHarness(
          boundaryKey: key,
          surfaceSize: const Size(768, 1024),
          child: PlatformShell(
            currentRoute: '/workshops',
            contextBar: PlatformContextBar(
              breadcrumbs: [
                ContextBreadcrumbItem(label: 'Platform Admin', onTap: () {}),
                const ContextBreadcrumbItem(label: 'Workshops'),
              ],
            ),
            child: _buildSamplePageContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'compact_768.png');

      // 4. 360 Mobile
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(
        _screenshotHarness(
          boundaryKey: key,
          surfaceSize: const Size(360, 800),
          child: PlatformShell(
            currentRoute: '/workshops',
            contextBar: PlatformContextBar(
              breadcrumbs: [
                ContextBreadcrumbItem(label: 'Platform Admin', onTap: () {}),
                const ContextBreadcrumbItem(label: 'Workshops'),
              ],
            ),
            child: _buildSamplePageContent(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _capture(tester, key, 'compact_360.png');

      tester.binding.setSurfaceSize(null);
    });
  });
}

void _expectActionableSidebarIfVisible(WidgetTester tester) {
  if (find
      .byKey(const Key('sidebar-language-status-card'))
      .evaluate()
      .isEmpty) {
    return;
  }
  expect(find.byKey(const Key('sidebar-language-loading')), findsNothing);
  // English-only baseline: the sidebar is quiet and may expose no action.
  expect(find.byKey(const Key('btn-sidebar-language-action')), findsNothing);
}
