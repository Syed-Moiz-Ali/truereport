// Real-font evidence for the API-driven item editor pickers.
//
// No pixel assertions: this writes screenshots under test/screenshots/data/
// and fails on a render exception (overflow, assert) so the evidence cannot be
// produced from a broken frame.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/master_library/master_item_editor_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

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
    }
    final resolved = family;
    if (resolved == null) continue;
    final bytes = await entity.readAsBytes();
    final loader = families.putIfAbsent(resolved, () => FontLoader(resolved));
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    final bare = resolved.replaceFirst('packages/design_system/', '');
    families
        .putIfAbsent(bare, () => FontLoader(bare))
        .addFont(Future.value(ByteData.sublistView(bytes)));
  }
  const materialPath = 'build/unit_test_assets/fonts/MaterialIcons-Regular.otf';
  final material = File(materialPath);
  if (material.existsSync()) {
    final bytes = await material.readAsBytes();
    families
        .putIfAbsent('MaterialIcons', () => FontLoader('MaterialIcons'))
        .addFont(Future.value(ByteData.sublistView(bytes)));
  }
  for (final loader in families.values) {
    await loader.load();
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    final dir = Directory('test/screenshots/data');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('${dir.path}/$name.png')
        .writeAsBytesSync(data.buffer.asUint8List(), flush: true);
  });
}

List<Override> _overrides() => <Override>[
  uiStringsProvider.overrideWithValue(loadReferenceStrings()),
  itemDetailProvider.overrideWith((ref, id) async => _detail),
  itemConfigProvider.overrideWith((ref, key) async => _config),
  optionSetsProvider.overrideWith((ref) async => const <OptionSet>[]),
  platformLanguagesProvider.overrideWith(
    (ref) async => const <PlatformLanguage>[],
  ),
  enumsProvider('result').overrideWith((ref) async => _results),
  enumsProvider('evidence-type').overrideWith(
    (ref) async => <ReferenceRecord>[
      record('PHOTO', labelKey: 'attachments', order: 1),
      record('VIDEO', labelKey: 'technicianVideo', order: 2),
      record('DOCUMENT', labelKey: 'technicianDocument', order: 3),
    ],
  ),
  statusesProvider('translation-status')
      .overrideWith((ref) async => const <ReferenceRecord>[]),
  statusesProvider('checklist')
      .overrideWith((ref) async => const <ReferenceRecord>[]),
];

final List<ReferenceRecord> _results = <ReferenceRecord>[
  record('NO_ISSUE_OBSERVED', labelKey: 'noIssueObserved', order: 1),
  record('ATTENTION_RECOMMENDED', labelKey: 'attentionRecommended', order: 2),
  record('DEFECT_FOUND', labelKey: 'defectFound', order: 3),
  record('NOT_CHECKED', labelKey: 'notChecked', order: 4, selectable: false),
  record(
    'NOT_APPLICABLE',
    labelKey: 'notApplicable',
    order: 5,
    selectable: false,
  ),
  record(
    'COULD_NOT_VERIFY',
    labelKey: 'couldNotVerify',
    order: 6,
    selectable: false,
  ),
  record('TIRE_CRACK_DETECTED', labelKey: 'tyreCrackDetected', order: 7),
];

const PlatformItemDetail _detail = PlatformItemDetail(
  item: PlatformItem(
    id: 'item-1',
    code: 'BRAKE_PAD',
    categoryId: 'cat-1',
    categoryLabelEn: 'Brakes',
    status: 'PUBLISHED',
    currentVersion: 1,
    sampleData: false,
    updatedAt: '2026-01-01T00:00:00Z',
    measurementUnit: 'mm',
    sensorTool: '',
    safetyCritical: true,
    multiPoint: false,
    maxTyreAgeYears: null,
    allowFreeTextNote: false,
    sortOrder: 0,
    guideImageId: '',
    label: 'Brake pad',
  ),
  versions: <PlatformItemVersion>[
    PlatformItemVersion(
      id: 'version-2',
      versionNo: 2,
      status: 'DRAFT',
      resultOptions: <String>[],
      noteRequirement: 'OPTIONAL',
      evidenceRequirement: 'REQUIRED_MIN_N',
      minPhotos: 1,
      publishedAt: '',
      label: 'Brake pad',
    ),
  ],
);

const ItemConfig _config = ItemConfig(
  metadata: ItemMetadata(
    itemId: 'item-1',
    measurementUnit: 'mm',
    sensorTool: '',
    safetyCritical: true,
    multiPoint: false,
    maxTyreAgeYears: null,
    allowFreeTextNote: false,
    sortOrder: 0,
    guideImageId: '',
  ),
  evidenceRules: <EvidenceRule>[
    EvidenceRule(
      resultCode: 'COULD_NOT_VERIFY',
      minPhotos: 0,
      minVideos: 0,
      minNotesChars: 0,
      requiredEvidenceType: 'PHOTO',
    ),
  ],
  issueFields: <IssueField>[],
  measurementBands: <MeasurementBand>[],
);

void main() {
  setUpAll(_loadRealFonts);

  testWidgets('capture the API-driven item editor evidence step', (
    tester,
  ) async {
    for (final size in const <Size>[Size(1280, 1000), Size(390, 1100)]) {
      await tester.binding.setSurfaceSize(size);
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: TrFonts.latin,
              scaffoldBackgroundColor: PtTheme.canvas,
            ),
            home: RepaintBoundary(
              key: key,
              child: const MasterItemEditorScreen(
                itemId: 'item-1',
                initialStep: 3,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'no overflow/assert at ${size.width.toInt()}',
      );
      await _capture(
        tester,
        key,
        'item_editor_evidence_${size.width.toInt()}x${size.height.toInt()}',
      );
    }
    await tester.binding.setSurfaceSize(null);
  });
}
