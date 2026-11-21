import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:l10n/ui_strings.dart';
import 'package:platform_admin_app/src/features/master_library/option_sets_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/platform_theme.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

/// Real-font visual evidence for the merged option-sets screen.
///
/// Writes PNGs to test/screenshots/option_sets/. No pixel assertions: the
/// point is a human/agent review of the actual rendered layout at each
/// breakpoint, including a right-to-left pass.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadRealFonts);

  testWidgets('capture merged option sets at desktop, tablet, phone and RTL', (
    tester,
  ) async {
    final key = GlobalKey();
    final sets = _fixtureSets();

    await _shot(
      tester,
      key,
      name: 'checklist_1440',
      size: const Size(1440, 900),
      tab: OptionSetTab.checklist,
      sets: sets,
    );
    await _shot(
      tester,
      key,
      name: 'checklist_1024',
      size: const Size(1024, 768),
      tab: OptionSetTab.checklist,
      sets: sets,
    );
    await _shot(
      tester,
      key,
      name: 'checklist_768',
      size: const Size(768, 1024),
      tab: OptionSetTab.checklist,
      sets: sets,
    );
    await _shot(
      tester,
      key,
      name: 'checklist_390',
      size: const Size(390, 844),
      tab: OptionSetTab.checklist,
      sets: sets,
    );
    await _shot(
      tester,
      key,
      name: 'statuses_1440',
      size: const Size(1440, 900),
      tab: OptionSetTab.statuses,
      sets: sets,
    );
    await _shot(
      tester,
      key,
      name: 'enums_1440',
      size: const Size(1440, 900),
      tab: OptionSetTab.enums,
      sets: sets,
    );
    await _shot(
      tester,
      key,
      name: 'statuses_1280_rtl',
      size: const Size(1280, 800),
      tab: OptionSetTab.statuses,
      sets: sets,
      direction: TextDirection.rtl,
    );
    await _shot(
      tester,
      key,
      name: 'enums_390',
      size: const Size(390, 844),
      tab: OptionSetTab.enums,
      sets: sets,
    );
    await _shot(
      tester,
      key,
      name: 'empty_1440',
      size: const Size(1440, 900),
      tab: OptionSetTab.checklist,
      sets: const <OptionSet>[],
    );
    await _shot(
      tester,
      key,
      name: 'error_1440',
      size: const Size(1440, 900),
      tab: OptionSetTab.checklist,
      sets: sets,
      error: true,
    );
    await _shot(
      tester,
      key,
      name: 'loading_1440',
      size: const Size(1440, 900),
      tab: OptionSetTab.checklist,
      sets: sets,
      pending: true,
    );

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _shot(
  WidgetTester tester,
  GlobalKey key, {
  required String name,
  required Size size,
  required OptionSetTab tab,
  required List<OptionSet> sets,
  TextDirection direction = TextDirection.ltr,
  bool error = false,
  bool pending = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.binding.setSurfaceSize(size);

  final catalogs = loadReferenceStrings().catalogs['en']!;
  final bundle = <String, String>{
    ...catalogs['common']!,
    ...catalogs['platform_admin']!,
  };

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        uiStringsProvider.overrideWithValue(loadReferenceStrings()),
        optionSetsProvider.overrideWith((ref) {
          if (pending) return Completer<List<OptionSet>>().future;
          if (error) {
            return Future<List<OptionSet>>.error(StateError('offline'));
          }
          return Future<List<OptionSet>>.value(sets);
        }),
        optionSetValuesProvider.overrideWith(
          (ref, id) async => const <OptionValue>[],
        ),
        statusesProvider('checklist')
            .overrideWith((ref) async => const <ReferenceRecord>[]),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          fontFamily: TrFonts.latin,
          scaffoldBackgroundColor: PtTheme.canvas,
        ),
        home: UiStringsScope(
          strings: UiStrings.fromMessages(bundle),
          child: Directionality(
            textDirection: direction,
            child: RepaintBoundary(
              key: key,
              child: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: OptionSetsScreen(embedded: true, initialTab: tab.slug),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (pending) {
    await tester.pump(const Duration(milliseconds: 50));
  } else {
    await tester.pumpAndSettle();
  }
  await _capture(tester, key, '$name.png');
  await tester.binding.setSurfaceSize(null);
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
    final image = await boundary.toImage(pixelRatio: 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final dir = Directory('test/screenshots/option_sets');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    File('${dir.path}/$filename')
        .writeAsBytesSync(byteData.buffer.asUint8List(), flush: true);
  });
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

    final bareFamily = family.replaceFirst('packages/design_system/', '');
    final bareLoader = families.putIfAbsent(
      bareFamily,
      () => FontLoader(bareFamily),
    );
    bareLoader.addFont(Future.value(ByteData.sublistView(bytes)));
  }

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

List<OptionSet> _fixtureSets() => <OptionSet>[
  _set(
    code: 'ISSUE_TYPE',
    name: 'Issue type',
    kind: OptionSetKind.checklist,
    sortOrder: 1,
    values: <OptionValue>[
      _value('WORN', 'Worn', 0),
      _value('CRACKED', 'Cracked', 1),
      _value('LOOSE', 'Loose', 2),
      _value('MISSING', 'Missing', 3),
      _value('CORRODED', 'Corroded', 4),
      _value('DAMAGED', 'Damaged', 5),
    ],
  ),
  _set(
    code: 'COMPONENT',
    name: 'Component',
    kind: OptionSetKind.checklist,
    sortOrder: 2,
    values: <OptionValue>[_value('BRAKE_PAD', 'Brake pad', 0)],
  ),
  _set(
    code: 'LOCATION',
    name: 'Location',
    kind: OptionSetKind.checklist,
    sortOrder: 3,
    values: <OptionValue>[_value('FRONT_AXLE', 'Front axle', 0)],
  ),
  _set(
    code: 'CONDITION',
    name: 'Condition',
    kind: OptionSetKind.checklist,
    sortOrder: 4,
    values: <OptionValue>[_value('WORN', 'Worn', 0)],
  ),
  _set(
    code: 'CAUSE',
    name: 'Cause',
    kind: OptionSetKind.checklist,
    sortOrder: 5,
    values: <OptionValue>[_value('WEAR', 'Wear', 0)],
  ),
  _set(
    code: 'ACTION',
    name: 'Action',
    kind: OptionSetKind.checklist,
    sortOrder: 6,
    values: <OptionValue>[_value('REPLACE', 'Replace', 0)],
  ),
  _set(
    code: 'URGENCY',
    name: 'Urgency',
    kind: OptionSetKind.checklist,
    sortOrder: 7,
    values: <OptionValue>[_value('HIGH', 'High', 0)],
  ),
  _set(
    code: 'JOB_STATUS',
    name: 'Job Status',
    kind: OptionSetKind.status,
    domainKey: 'job-status',
    codeLocked: true,
    sortOrder: 1,
    valuesCount: 9,
    values: <OptionValue>[
      _value('DRAFT', 'Draft', 0, tone: 'neutral', icon: 'circle'),
      _value('SCHEDULED', 'Scheduled', 1, tone: 'info', icon: 'clock'),
      _value('IN_PROGRESS', 'In progress', 2, tone: 'info', icon: 'clock'),
      _value(
        'AWAITING_REVIEW',
        'Awaiting review',
        3,
        tone: 'warning',
        icon: 'alert',
      ),
      _value('APPROVED', 'Approved', 4, tone: 'success', icon: 'check'),
      _value('COMPLETED', 'Completed', 5, tone: 'success', icon: 'check'),
      _value('CANCELLED', 'Cancelled', 6, tone: 'danger', icon: 'block'),
    ],
  ),
  _set(
    code: 'REVIEW_STATUS',
    name: 'Review Status',
    kind: OptionSetKind.status,
    domainKey: 'review-status',
    codeLocked: true,
    sortOrder: 2,
    valuesCount: 4,
  ),
  _set(
    code: 'PUBLICATION_STATUS',
    name: 'Publication Status',
    kind: OptionSetKind.status,
    domainKey: 'publication-status',
    codeLocked: true,
    sortOrder: 3,
    valuesCount: 3,
  ),
  _set(
    code: 'EVIDENCE_STATUS',
    name: 'Evidence Status',
    kind: OptionSetKind.status,
    domainKey: 'evidence-status',
    codeLocked: true,
    sortOrder: 4,
    valuesCount: 3,
  ),
  _set(
    code: 'ROLE',
    name: 'Role',
    kind: OptionSetKind.enumeration,
    codeLocked: true,
    sortOrder: 1,
    values: <OptionValue>[
      _value('PLATFORM_ADMIN', 'Platform admin', 0),
      _value('WORKSHOP_ADMIN', 'Workshop admin', 1),
      _value('TECHNICIAN', 'Technician', 2),
    ],
  ),
  _set(
    code: 'RESULT',
    name: 'Result',
    kind: OptionSetKind.enumeration,
    codeLocked: true,
    sortOrder: 2,
    values: <OptionValue>[
      _value('PASS', 'Pass', 0, tone: 'success', icon: 'check'),
      _value('FAIL', 'Fail', 1, tone: 'danger', icon: 'block'),
    ],
  ),
  _set(
    code: 'SEVERITY',
    name: 'Severity',
    kind: OptionSetKind.enumeration,
    codeLocked: true,
    sortOrder: 3,
    values: <OptionValue>[
      _value('LOW', 'Low', 0, tone: 'neutral'),
      _value('MEDIUM', 'Medium', 1, tone: 'warning'),
      _value('HIGH', 'High', 2, tone: 'danger'),
    ],
  ),
  _set(
    code: 'UNIT',
    name: 'Unit',
    kind: OptionSetKind.checklist,
    codeLocked: true,
    sortOrder: 4,
    values: <OptionValue>[_value('MM', 'Millimetre', 0)],
  ),
  _set(
    code: 'YES_NO',
    name: 'Yes / No',
    kind: OptionSetKind.checklist,
    codeLocked: true,
    sortOrder: 5,
    values: <OptionValue>[_value('YES', 'Yes', 0), _value('NO', 'No', 1)],
  ),
];

OptionSet _set({
  required String code,
  required String name,
  required OptionSetKind kind,
  String domainKey = '',
  bool codeLocked = false,
  int sortOrder = 0,
  int valuesCount = 0,
  List<OptionValue> values = const <OptionValue>[],
}) => OptionSet(
  id: 'id-$code',
  code: code,
  name: name,
  status: 'ACTIVE',
  sortOrder: sortOrder,
  values: values,
  kind: kind,
  domainKey: domainKey,
  codeLocked: codeLocked,
  valuesCount: valuesCount,
);

OptionValue _value(
  String code,
  String label,
  int order, {
  String tone = '',
  String icon = '',
}) => OptionValue(
  id: 'value-$code',
  code: code,
  label: label,
  status: 'ACTIVE',
  sortOrder: order,
  metadataJson: '{}',
  tone: tone,
  icon: icon,
);
