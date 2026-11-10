import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/jobs/schedule_job_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fake_admin_api.dart';

class _FakeScheduleApi extends FakeAdminApi {
  _FakeScheduleApi({this.failCreate = false, this.emptyTemplates = false});

  final bool failCreate;
  final bool emptyTemplates;
  final List<Map<String, Object?>> createCalls = [];

  @override
  Future<List<TemplateVersionOption>> templateVersionOptions() async {
    if (emptyTemplates) {
      return const [];
    }
    return const [
      TemplateVersionOption(
        versionId: 'version-1',
        templateId: 'template-1',
        templateName: 'Full inspection',
        versionNo: 1,
        serviceType: 'FULL',
        vehicleType: 'CAR',
      ),
      TemplateVersionOption(
        versionId: 'version-2',
        templateId: 'template-2',
        templateName: 'Quick check',
        versionNo: 2,
        serviceType: 'QUICK',
        vehicleType: null,
      ),
    ];
  }

  @override
  Future<List<TemplateSummary>> templates() async => const [
    TemplateSummary(
      id: 'template-1',
      name: 'Full inspection',
      serviceType: 'FULL',
      vehicleType: 'CAR',
      status: 'PUBLISHED',
      currentVersion: 1,
      itemCount: 12,
    ),
    TemplateSummary(
      id: 'template-2',
      name: 'Quick check',
      serviceType: 'QUICK',
      vehicleType: null,
      status: 'PUBLISHED',
      currentVersion: 2,
      itemCount: 5,
    ),
  ];

  @override
  Future<WorkshopJob> createJob({
    required String templateVersionId,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    required String vehicleMake,
    required String vehicleModel,
    int? vehicleYear,
    String? vehicleVin,
    String? vehiclePlate,
    required String scope,
    String? scheduledAt,
  }) async {
    createCalls.add({
      'templateVersionId': templateVersionId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'vehicleVin': vehicleVin,
      'vehiclePlate': vehiclePlate,
      'scope': scope,
      'scheduledAt': scheduledAt,
    });
    if (failCreate) {
      throw StateError('create failed');
    }
    return WorkshopJob(
      id: 'job-9',
      reference: 'JOB-TEST0009',
      status: 'SCHEDULED',
      templateVersionId: templateVersionId,
      templateName: 'Full inspection',
      templateVersionNo: 1,
      assignedTechnicianId: null,
      assignedTechnicianName: null,
      scheduledAt: scheduledAt ?? '',
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleYear: vehicleYear,
      vehicleVin: vehicleVin,
      vehiclePlate: vehiclePlate,
      scope: scope,
    );
  }
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({
    required this.locale,
    required this.textScale,
    required this.api,
    required this.onResult,
  });

  final Locale locale;
  final double textScale;
  final _FakeScheduleApi api;
  final ValueChanged<WorkshopJob?> onResult;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
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
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(widget.textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (sheetContext) => ElevatedButton(
              key: const Key('open-schedule-sheet'),
              onPressed: () async {
                final job = await ScheduleJobSheet.showScheduleJobSheet(
                  sheetContext,
                );
                widget.onResult(job);
              },
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
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

Future<ValueNotifier<WorkshopJob?>> _openSheet(
  WidgetTester tester, {
  required _FakeScheduleApi api,
  required Locale locale,
  required Size size,
  double textScale = 1,
}) async {
  _setSize(tester, size);
  final result = ValueNotifier<WorkshopJob?>(null);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(api)],
      child: _Harness(
        locale: locale,
        textScale: textScale,
        api: api,
        onResult: (job) => result.value = job,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open-schedule-sheet')));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return result;
}

Future<void> _scrollSheet(WidgetTester tester) async {
  final scrollable = find.descendant(
    of: find.byType(WorkshopSideSheet),
    matching: find.byType(Scrollable),
  );
  await tester.drag(scrollable.first, const Offset(0, -600));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _fillRequired(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Customer A');
  await tester.enterText(fields.at(3), 'Toyota');
  await tester.enterText(fields.at(4), 'Camry');
  await tester.enterText(fields.at(8), 'Full inspection');
  await tester.pump();
}

bool _createFocused(WidgetTester tester) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) {
    return false;
  }
  return find
      .ancestor(
        of: find.byWidget(context.widget),
        matching: find.byType(AppButton),
      )
      .evaluate()
      .isNotEmpty;
}

void main() {
  const wide = Size(1280, 800);
  const phone = Size(390, 844);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final entry in {'wide': wide, 'phone': phone}.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'schedule sheet ${locale.languageCode} ${entry.key} scale $scale renders without overflow',
          (tester) async {
            await _openSheet(
              tester,
              api: _FakeScheduleApi(),
              locale: locale,
              size: entry.value,
              textScale: scale,
            );
            final title = locale.languageCode == 'ar'
                ? 'جدولة مهمة جديدة'
                : 'Schedule new job';
            expect(find.text(title), findsOneWidget);
            expect(find.byType(AppButton), findsOneWidget);
            await _scrollSheet(tester);
          },
        );
      }
    }
  }

  testWidgets('schedule sheet uses RTL direction in Arabic', (tester) async {
    await _openSheet(
      tester,
      api: _FakeScheduleApi(),
      locale: const Locale('ar'),
      size: phone,
    );
    expect(
      Directionality.of(tester.element(find.text('جدولة مهمة جديدة'))),
      TextDirection.rtl,
    );
  });

  testWidgets('schedule sheet blocks submit without template and scope', (
    tester,
  ) async {
    final api = _FakeScheduleApi();
    await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );

    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(api.createCalls, isEmpty);
    expect(find.byType(AppButton), findsOneWidget);
    expect(find.text('This field is required.'), findsWidgets);

    await _fillRequired(tester);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(api.createCalls, isEmpty);
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('schedule sheet shows empty state without templates', (
    tester,
  ) async {
    final api = _FakeScheduleApi(emptyTemplates: true);
    await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    expect(find.text('No results'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(api.createCalls, isEmpty);
  });

  testWidgets('schedule sheet creates a job with the entered payload', (
    tester,
  ) async {
    final api = _FakeScheduleApi();
    final result = await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );

    await _fillRequired(tester);
    await tester.ensureVisible(find.text('Full inspection · v1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full inspection · v1'));
    await tester.pump();
    await tester.ensureVisible(find.byType(AppButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(api.createCalls, hasLength(1));
    expect(api.createCalls.single, {
      'templateVersionId': 'version-1',
      'customerName': 'Customer A',
      'customerPhone': null,
      'customerEmail': null,
      'vehicleMake': 'Toyota',
      'vehicleModel': 'Camry',
      'vehicleYear': null,
      'vehicleVin': null,
      'vehiclePlate': null,
      'scope': 'Full inspection',
      'scheduledAt': null,
    });
    expect(result.value?.id, 'job-9');
    expect(find.byType(AppButton), findsNothing);
    expect(find.text('Job created'), findsOneWidget);
  });

  testWidgets('schedule sheet keeps error path inside the sheet', (
    tester,
  ) async {
    final api = _FakeScheduleApi(failCreate: true);
    final result = await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );

    await _fillRequired(tester);
    await tester.ensureVisible(find.text('Full inspection · v1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full inspection · v1'));
    await tester.pump();
    await tester.ensureVisible(find.byType(AppButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(api.createCalls, hasLength(1));
    expect(result.value, isNull);
    expect(find.text('Action failed'), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('schedule sheet exposes header semantics and tab order', (
    tester,
  ) async {
    await _openSheet(
      tester,
      api: _FakeScheduleApi(),
      locale: const Locale('en'),
      size: wide,
    );

    expect(find.text('Schedule new job'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.text('Schedule new job'),
    );
    expect(semantics.flagsCollection.isHeader, isTrue);
    expect(find.bySemanticsLabel('Close'), findsWidgets);

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    var reachedCreate = false;
    for (var i = 0; i < 80 && !reachedCreate; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      reachedCreate = _createFocused(tester);
    }
    expect(reachedCreate, isTrue);
  });

  testWidgets('schedule sheet renders no forbidden terms', (tester) async {
    await _openSheet(
      tester,
      api: _FakeScheduleApi(),
      locale: const Locale('en'),
      size: wide,
    );
    final text = find
        .byType(Text)
        .evaluate()
        .map((element) => (element.widget as Text).data ?? '')
        .join('\n')
        .toLowerCase();
    const banned = [
      'bay',
      'dispatch',
      'telematics',
      'telemetry',
      'telemetr',
      '60-point',
      '110-point',
      'marcus',
      'porsche',
      'auto-assign',
      'auto assign',
      'lead tech',
      'certif',
      'approv',
      'review',
      '30m',
      '75m',
    ];
    for (final term in banned) {
      expect(text.contains(term), isFalse, reason: 'forbidden term: $term');
    }
  });
}
