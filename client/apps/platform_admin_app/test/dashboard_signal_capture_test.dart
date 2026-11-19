// Visual evidence for the Signal Room dashboard. Throwaway harness.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:platform_admin_app/src/features/dashboard/dashboard_screen.dart';
import 'package:platform_admin_app/src/platform_catalogue_models.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

import 'support/ui_message_fixtures.dart';

const _outDir = 'docs/evidence/dashboard_signal_room';

Future<void> _loadRealFonts() async {
  final fontDir = Directory('../../packages/design_system/assets/fonts');
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

const _summary = OverviewSummary(
  workshops: OverviewWorkshops(total: 12, active: 9),
  staff: OverviewStaff(technicians: 34, admins: 5),
  jobs: OverviewJobs(
    active: 21,
    pendingReview: 4,
    byStatus: {'ASSIGNED': 8, 'IN_PROGRESS': 9, 'PENDING_REVIEW': 4},
  ),
  reports: OverviewReports(published: 38, byMonth: {'2026-11': 14}),
  checklist: OverviewChecklist(
    categories: 6,
    items: 42,
    templates: 3,
    healthy: false,
    issues: 2,
  ),
  languages: OverviewLanguages(live: 2, translating: 1),
  recentActivity: [
    OverviewActivityEntry(
      id: 'evt-1',
      action: 'MASTER_ITEM_PUBLISHED',
      entityType: 'MASTER_ITEM',
      entityId: 'BRK-PAD-01',
      actor: 'a.rahman@truereport.app',
      occurredAt: '2026-11-19T10:04:00Z',
    ),
    OverviewActivityEntry(
      id: 'evt-2',
      action: 'WORKSHOP_REGISTERED',
      entityType: 'WORKSHOP',
      entityId: 'Al Noor Auto Care',
      actor: 's.haddad@truereport.app',
      occurredAt: '2026-11-18T14:30:00Z',
    ),
    OverviewActivityEntry(
      id: 'evt-3',
      action: 'DOCUMENT_TYPE_RETIRED',
      entityType: 'DOCUMENT_TYPE',
      entityId: 'WHEEL_ALIGNMENT',
      actor: 'n.farouk@truereport.app',
      occurredAt: '2026-11-14T09:12:00Z',
    ),
    OverviewActivityEntry(
      id: 'evt-4',
      action: 'LANGUAGE_PUBLISHED',
      entityType: 'LANGUAGE',
      entityId: 'en',
      actor: 'Platform Admin',
      occurredAt: '2026-11-13T16:45:00Z',
    ),
  ],
  alerts: [
    OverviewAlert(
      severity: 'WARNING',
      title: 'Published jobs without a public link',
      body: '6 published jobs have no active public link.',
      route: '/audit-log',
      titleKey: 'dashboard.alert.reportsUnpublished.title',
      bodyKey: 'dashboard.alert.reportsUnpublished.body',
      args: {'count': 6},
    ),
  ],
);

const _health = ConfigHealth(
  healthy: false,
  checks: [
    HealthCheck(
      code: 'TEMPLATE_REFERENCE',
      severity: 'ERROR',
      messageEn: 'Template references a missing item',
      messageAr: 'يشير القالب إلى بند مفقود',
      affected: 2,
      references: [],
    ),
    HealthCheck(
      code: 'TRANSLATION_GAP',
      severity: 'WARN',
      messageEn: 'Arabic labels missing',
      messageAr: 'تسميات عربية مفقودة',
      affected: 4,
      references: [],
    ),
    HealthCheck(
      code: 'OPTIONS_OK',
      severity: 'OK',
      messageEn: 'Options valid',
      messageAr: 'الخيارات صالحة',
      affected: 0,
      references: [],
    ),
  ],
);

const _languages = [
  PlatformLanguage(
    code: 'en',
    nativeName: 'English',
    direction: 'ltr',
    active: true,
    isDefault: true,
    sortOrder: 0,
    status: 'LIVE',
  ),
  PlatformLanguage(
    code: 'ar',
    nativeName: 'العربية',
    direction: 'rtl',
    active: true,
    isDefault: false,
    sortOrder: 1,
    status: 'TRANSLATING',
  ),
];

const _readinessEn = LanguageReadiness(
  language: 'en',
  nativeName: 'English',
  direction: 'ltr',
  isDefault: true,
  status: 'LIVE',
  readinessPercent: 100,
  uiMessagesPath: 'en.json',
  uiMessages: UiMessageCoverage(
    total: 450,
    approved: 450,
    missing: 0,
    changed: 0,
    path: 'en.json',
    generationStatus: 'NONE',
  ),
  content: {},
  blockers: [],
);

const _readinessAr = LanguageReadiness(
  language: 'ar',
  nativeName: 'العربية',
  direction: 'rtl',
  isDefault: false,
  status: 'TRANSLATING',
  readinessPercent: 68,
  uiMessagesPath: 'ar.json',
  uiMessages: UiMessageCoverage(
    total: 320,
    approved: 218,
    missing: 102,
    changed: 0,
    path: 'ar.json',
    generationStatus: 'NONE',
  ),
  content: {},
  blockers: [],
);

Widget _harness({
  required Locale locale,
  required bool dark,
  required bool withShell,
  required Size size,
  required GlobalKey boundaryKey,
}) {
  final strings = locale.languageCode == 'ar'
      ? fakeArUiStrings()
      : fakeEnUiStrings();
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(strings),
      overviewProvider.overrideWith((ref) async => _summary),
      configHealthProvider.overrideWith((ref) async => _health),
      platformLanguagesProvider.overrideWith((ref) async => _languages),
      auditEventsProvider.overrideWith(
        (ref) async => const <PlatformAuditEvent>[],
      ),
      readinessProvider('en').overrideWith((ref) async => _readinessEn),
      readinessProvider('ar').overrideWith((ref) async => _readinessAr),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: dark
          ? ThemeData(
              brightness: Brightness.dark,
              fontFamily: TrFonts.latin,
              scaffoldBackgroundColor: const Color(0xFF0E1210),
            )
          : ThemeData(
              fontFamily: TrFonts.latin,
              scaffoldBackgroundColor: const Color(0xFFF4F3F8),
            ),
      home: RepaintBoundary(
        key: boundaryKey,
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: Directionality(
            textDirection: locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: withShell
                ? const DashboardScreen()
                : const Scaffold(body: DashboardBody()),
          ),
        ),
      ),
    ),
  );
}

Future<void> _capture(
  WidgetTester tester,
  String filename,
  Size size, {
  required Locale locale,
  bool dark = false,
  bool withShell = true,
}) async {
  await tester.binding.setSurfaceSize(size);
  final key = GlobalKey();
  await tester.pumpWidget(
    _harness(
      locale: locale,
      dark: dark,
      withShell: withShell,
      size: size,
      boundaryKey: key,
    ),
  );
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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

  setUpAll(() async {
    await initializeDateFormatting();
    await _loadRealFonts();
  });

  testWidgets('capture signal room dashboard', (tester) async {
    await _capture(
      tester,
      'dashboard_1440.png',
      const Size(1440, 900),
      locale: const Locale('en'),
    );
    await _capture(
      tester,
      'dashboard_1024.png',
      const Size(1024, 1400),
      locale: const Locale('en'),
    );
    await _capture(
      tester,
      'dashboard_390.png',
      const Size(390, 1560),
      locale: const Locale('en'),
    );
    await _capture(
      tester,
      'dashboard_390_rtl.png',
      const Size(390, 1560),
      locale: const Locale('ar'),
    );
    await _capture(
      tester,
      'dashboard_dark_1440.png',
      const Size(1440, 900),
      locale: const Locale('en'),
      dark: true,
      withShell: false,
    );
    tester.binding.setSurfaceSize(null);
  });
}
