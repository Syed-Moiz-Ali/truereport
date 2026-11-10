import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/templates/template_builder_page.dart';
import 'package:workshop_admin_app/src/features/templates/template_version_page.dart';
import 'package:workshop_admin_app/src/features/home/workshop_admin_home.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fake_admin_api.dart';

class _MatrixApp extends ConsumerStatefulWidget {
  const _MatrixApp({
    required this.home,
    required this.locale,
    required this.brightness,
    this.textScale = 1,
  });

  final Widget home;
  final Locale locale;
  final Brightness brightness;
  final double textScale;

  @override
  ConsumerState<_MatrixApp> createState() => _MatrixAppState();
}

class _MatrixAppState extends ConsumerState<_MatrixApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(widget.locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(widget.textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: widget.home,
    );
  }
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpWorkshop(
  WidgetTester tester, {
  required Locale locale,
  required Brightness brightness,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(FakeAdminApi())],
      child: _MatrixApp(
        home: const WorkshopAdminHomePage(),
        locale: locale,
        brightness: brightness,
        textScale: textScale,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _exerciseWorkshop(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  // The overview tab lists recent jobs in lazily-built slivers, so narrow
  // layouts start with the list below the fold — scroll it into view first.
  await tester.dragUntilVisible(
    find.textContaining('JOB-TEST0001'),
    find.byType(CustomScrollView),
    const Offset(0, -500),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.textContaining('JOB-TEST0001'), findsOneWidget);

  final staffTab = find.byKey(const Key('workshop-tab-staff')).first;
  await tester.ensureVisible(staffTab);
  await tester.tap(staffTab);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.text('Technician A'), findsOneWidget);

  final templatesTab = find.byKey(const Key('workshop-tab-templates')).first;
  await tester.ensureVisible(templatesTab);
  await tester.tap(templatesTab);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  final template = find.byKey(const Key('template-template-1'));
  await tester.ensureVisible(template);
  await tester.tap(template);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.byType(TemplateBuilderPage), findsOneWidget);
  final version = find.byKey(const Key('template-version-version-1'));
  await tester.scrollUntilVisible(
    version,
    400,
    scrollable: find
        .descendant(
          of: find.byKey(const Key('template-builder-list')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(version);
  await tester.pumpAndSettle();
  await tester.tap(version);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(find.byType(TemplateVersionPage), findsOneWidget);
}

void main() {
  final sizes = <String, Size>{
    'phone': const Size(390, 844),
    'tablet': const Size(1024, 900),
    'wide': const Size(1440, 900),
  };

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final brightness in Brightness.values) {
      for (final entry in sizes.entries) {
        testWidgets(
          'sign-in ${locale.languageCode} ${brightness.name} ${entry.key} has no overflow',
          (tester) async {
            _setSize(tester, entry.value);
            await tester.pumpWidget(
              ProviderScope(
                child: _MatrixApp(
                  home: const SignInPage(),
                  locale: locale,
                  brightness: brightness,
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (locale.languageCode == 'ar') {
              expect(
                Directionality.of(
                  tester.element(find.byKey(const Key('sign-in-submit'))),
                ),
                TextDirection.rtl,
              );
            }
          },
        );
      }
    }
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final entry in <String, Size>{
      'phone': sizes['phone']!,
      'wide': sizes['wide']!,
    }.entries) {
      testWidgets(
        'sign-in ${locale.languageCode} text scale 2.0 ${entry.key} has no overflow',
        (tester) async {
          _setSize(tester, entry.value);
          await tester.pumpWidget(
            ProviderScope(
              child: _MatrixApp(
                home: const SignInPage(),
                locale: locale,
                brightness: Brightness.light,
                textScale: 2,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final brightness in Brightness.values) {
      for (final entry in sizes.entries) {
        testWidgets(
          'workshop ${locale.languageCode} ${brightness.name} ${entry.key} has no overflow',
          (tester) async {
            _setSize(tester, entry.value);
            await _pumpWorkshop(tester, locale: locale, brightness: brightness);
            await _exerciseWorkshop(tester);
          },
        );
      }
    }
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final scale in const [1.5, 2.0]) {
      for (final entry in <String, Size>{
        'phone': sizes['phone']!,
        'wide': sizes['wide']!,
      }.entries) {
        testWidgets(
          'workshop ${locale.languageCode} text scale $scale ${entry.key} has no overflow',
          (tester) async {
            _setSize(tester, entry.value);
            await _pumpWorkshop(
              tester,
              locale: locale,
              brightness: Brightness.light,
              textScale: scale,
            );
            await _exerciseWorkshop(tester);
          },
        );
      }
    }
  }

  testWidgets('reduce motion helper returns zero duration', (tester) async {
    late Duration normal;
    late Duration reduced;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              normal = ReduceMotion.duration(
                context,
                const Duration(milliseconds: 200),
              );
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: Builder(
                  builder: (context) {
                    reduced = ReduceMotion.duration(
                      context,
                      const Duration(milliseconds: 200),
                    );
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(normal, const Duration(milliseconds: 200));
    expect(reduced, Duration.zero);
  });
}
