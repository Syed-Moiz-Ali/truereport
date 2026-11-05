import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden baselines for the Figma-exact shared components.
///
/// English and Arabic, light and dark. The components themselves are light
/// Figma structures; the dark variant checks that the surrounding theme and
/// Arabic fallback do not break them. Regenerate with:
///   flutter test --update-goldens test/figma_goldens_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadBundledFonts();
  });

  for (final variant in _variants) {
    testWidgets('Figma primary button ${variant.name}', (tester) async {
      await _pump(
        tester,
        variant,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: FigmaPrimaryButton(
            label: variant.arabic ? 'تسجيل الدخول' : 'Sign In',
            onPressed: () {},
          ),
        ),
      );
      await expectLater(
        find.byKey(_boundaryKey),
        matchesGoldenFile(
          'goldens/figma_primary_button_${variant.name}.png',
        ),
      );
    });

    testWidgets('Figma delivery card ${variant.name}', (tester) async {
      await _pump(
        tester,
        variant,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: FigmaDeliveryStatusCard(
            items: [
              FigmaDeliveryItem(
                icon: AppIconName.deliveryReportLink,
                label: variant.arabic ? 'رابط التقرير' : 'WhatsApp',
                status: variant.arabic ? 'أُرسل' : 'Sent',
              ),
              FigmaDeliveryItem(
                icon: AppIconName.deliveryWorkshopCopy,
                label: variant.arabic ? 'نسخة الورشة' : 'Fleet Portal',
                status: variant.arabic ? 'تمت المزامنة' : 'Synced',
                iconWidth: 18.33,
                iconHeight: 13.33,
              ),
            ],
          ),
        ),
      );
      await expectLater(
        find.byKey(_boundaryKey),
        matchesGoldenFile(
          'goldens/figma_delivery_card_${variant.name}.png',
        ),
      );
    });

    testWidgets('Figma result selector ${variant.name}', (tester) async {
      await _pump(
        tester,
        variant,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: FigmaThreeWaySelector<String>(
            label: variant.arabic ? 'حالة الفحص' : 'Inspection status',
            options: [
              FigmaResultOption(
                value: 'pass',
                label: variant.arabic ? 'لا مشكلة' : 'Pass',
              ),
              FigmaResultOption(
                value: 'minor',
                label: variant.arabic ? 'انتباه' : 'Minor',
              ),
              FigmaResultOption(
                value: 'major',
                label: variant.arabic ? 'خلل' : 'Major',
              ),
            ],
            selected: 'minor',
            onChanged: (_) {},
          ),
        ),
      );
      await expectLater(
        find.byKey(_boundaryKey),
        matchesGoldenFile(
          'goldens/figma_result_selector_${variant.name}.png',
        ),
      );
    });
  }
}

const _boundaryKey = ValueKey('figma-golden-boundary');

class _Variant {
  const _Variant({
    required this.name,
    required this.arabic,
    required this.brightness,
  });

  final String name;
  final bool arabic;
  final Brightness brightness;
}

const _variants = <_Variant>[
  _Variant(name: 'en_light', arabic: false, brightness: Brightness.light),
  _Variant(name: 'en_dark', arabic: false, brightness: Brightness.dark),
  _Variant(name: 'ar_light', arabic: true, brightness: Brightness.light),
  _Variant(name: 'ar_dark', arabic: true, brightness: Brightness.dark),
];

Future<void> _pump(
  WidgetTester tester,
  _Variant variant,
  Widget child,
) async {
  tester.view.physicalSize = const Size(400, 220);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final theme = AppTheme.build(
    brightness: variant.brightness,
    isArabic: variant.arabic,
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Directionality(
        textDirection: variant.arabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 220),
            devicePixelRatio: 1,
            textScaler: TextScaler.noScaling,
          ),
          child: RepaintBoundary(
            key: _boundaryKey,
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(_goldenPadding),
                child: Material(
                  type: MaterialType.transparency,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

const double _goldenPadding = 8;

Future<void> _loadBundledFonts() async {
  final fontDir = Directory(
    '${_repoRoot().path}/client/packages/design_system/assets/fonts',
  );
  final families = <String, FontLoader>{};
  await for (final entity in fontDir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('.ttf') && !name.endsWith('.otf')) continue;
    final family = _familyFor(name);
    if (family == null) continue;
    final bytes = await entity.readAsBytes();
    families
        .putIfAbsent(family, () => FontLoader(family))
        .addFont(Future.value(ByteData.sublistView(bytes)));
  }
  for (final entry in families.entries) {
    await entry.value.load();
  }
}

String? _familyFor(String fileName) {
  if (fileName.startsWith('PlusJakartaSans')) return 'Plus Jakarta Sans';
  if (fileName.startsWith('NotoSansArabic')) return 'Noto Sans Arabic';
  if (fileName.startsWith('IBMPlexSansArabic')) return 'IBM Plex Sans Arabic';
  if (fileName.startsWith('NotoSansSC')) return 'Noto Sans SC';
  if (fileName.startsWith('NotoSans-')) return 'Noto Sans';
  return null;
}

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 12; i += 1) {
    if (Directory('${dir.path}/docs/ui/figma').existsSync() &&
        Directory('${dir.path}/client').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('Could not find repository root from ${Directory.current}');
}
