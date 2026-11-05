import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadBundledFonts();
  });

  testWidgets('Figma primary button matches the node box and type', (
    tester,
  ) async {
    await _pump(
      tester,
      FigmaPrimaryButton(
        key: const ValueKey('button'),
        label: 'Sign In',
        onPressed: () {},
      ),
    );
    final size = tester.getSize(find.byKey(const ValueKey('button')));
    expect(size, const Size(342, 56));

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('button')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, FigmaColors.emerald);
    expect(decoration.border, isNull);
    expect(decoration.borderRadius, BorderRadius.circular(999));

    final label = tester.widget<Text>(find.text('Sign In'));
    expect(label.style!.color, FigmaColors.white);
    expect(label.style!.fontSize, 14);
    expect(label.style!.fontWeight, FontWeight.w700);
    expect(label.style!.letterSpacing, -0.14);
  });

  testWidgets('Figma delivery card matches the node box and radius', (
    tester,
  ) async {
    await _pump(
      tester,
      FigmaDeliveryStatusCard(
        key: const ValueKey('card'),
        items: const [
          FigmaDeliveryItem(
            icon: AppIconName.deliveryReportLink,
            label: 'WhatsApp',
            status: 'Sent',
          ),
          FigmaDeliveryItem(
            icon: AppIconName.deliveryWorkshopCopy,
            label: 'Fleet Portal',
            status: 'Synced',
          ),
        ],
      ),
    );
    final size = tester.getSize(find.byKey(const ValueKey('card')));
    expect(size, const Size(350, 145));

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('card')),
        matching: find.byType(Container),
      ).first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, FigmaColors.surface);
    expect(decoration.border, isNull);
    expect(decoration.borderRadius, BorderRadius.circular(32));
    expect(decoration.boxShadow, FigmaShadows.card);
  });

  testWidgets('Figma toggle matches the 350 x 70 node and 40 px options', (
    tester,
  ) async {
    await _pump(
      tester,
      FigmaThreeWaySelector<String>(
        key: const ValueKey('selector'),
        label: 'Inspection status',
        options: const [
          FigmaResultOption(value: 'pass', label: 'Pass'),
          FigmaResultOption(value: 'minor', label: 'Minor'),
          FigmaResultOption(value: 'major', label: 'Major'),
        ],
        selected: 'minor',
        onChanged: (_) {},
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('selector'))),
      const Size(350, 70),
    );
    expect(find.text('INSPECTION STATUS'), findsOneWidget);
    for (final label in const ['Pass', 'Minor', 'Major']) {
      final rect = tester.getRect(find.text(label));
      expect(rect.height, lessThanOrEqualTo(16));
    }
  });

  testWidgets('Figma type carries the Arabic fallback for product copy', (
    tester,
  ) async {
    await _pump(
      tester,
      const AppDeliveryStatusCard(
        reportLinkLabel: 'رابط التقرير',
        reportLinkStatus: 'أُرسل',
        workshopCopyLabel: 'نسخة الورشة',
        workshopCopyStatus: 'تمت المزامنة',
      ),
    );
    final text = tester.widget<Text>(find.text('رابط التقرير'));
    expect(
      text.style?.fontFamilyFallback,
      contains('Noto Sans Arabic'),
    );
  });

  testWidgets('product selector keeps the three-way toggle and secondary chips', (
    tester,
  ) async {
    await _pump(
      tester,
      InspectionResultSelector(
        groupLabel: 'Inspection status',
        selected: InspectionResult.noIssueObserved,
        onChanged: (_) {},
        labelBuilder: _label,
      ),
    );
    expect(find.text('No issue observed'), findsOneWidget);
    expect(find.text('Attention recommended'), findsOneWidget);
    expect(find.text('Defect found'), findsOneWidget);
    expect(find.text('Not checked'), findsOneWidget);
    expect(find.text('Not applicable'), findsOneWidget);
    expect(find.text('Could not verify'), findsOneWidget);
    for (final label in const [
      'No issue observed',
      'Attention recommended',
      'Defect found',
    ]) {
      final rect = tester.getRect(find.text(label));
      expect(rect.height, lessThanOrEqualTo(16));
    }
  });
}

String _label(InspectionResult result) => switch (result) {
  InspectionResult.noIssueObserved => 'No issue observed',
  InspectionResult.attentionRecommended => 'Attention recommended',
  InspectionResult.defectFound => 'Defect found',
  InspectionResult.notChecked => 'Not checked',
  InspectionResult.notApplicable => 'Not applicable',
  InspectionResult.couldNotVerify => 'Could not verify',
};

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

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
