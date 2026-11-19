import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/approve_job_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_creation_wizard_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_documents_page.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_status_badge.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

import 'support/fake_admin_api.dart';

/// Real-font evidence for the J2 write path.
///
/// Writes to `docs/evidence/jobs_j2/`. Fonts come from
/// `flutter_test_config.dart`; every capture asserts no exception, so an
/// overflow fails the run instead of producing a misleading screenshot.
const String _outDir = 'docs/evidence/jobs_j2';

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    expect(boundary, isNotNull, reason: name);
    final image = await boundary!.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull, reason: name);
    final dir = Directory(_outDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('${dir.path}/$name.png')
        .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  });
}

Future<GlobalKey> _pump(
  WidgetTester tester, {
  required Widget home,
  AdminApi? api,
  required Size size,
  required double height,
  Locale locale = const Locale('en'),
}) async {
  final key = GlobalKey();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(api ?? FakeAdminApi())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: RepaintBoundary(
          key: key,
          child: Material(
            color: AppTheme.light.scaffoldBackgroundColor,
            child: SizedBox(width: size.width, height: height, child: home),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return key;
}

Future<void> _tapNext(WidgetTester tester) async {
  final next = find.byKey(const Key('jobs-wizard-next'));
  await tester.ensureVisible(next);
  await tester.tap(next);
  await tester.pumpAndSettle();
}

Future<void> _advanceToTechnician(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-customer-name')),
    'Rashid Al Mansoori',
  );
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-customer-phone')),
    '+971500000000',
  );
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-customer-email')),
    'customer@example.test',
  );
  await _tapNext(tester);
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-vehicle-make')),
    'Porsche',
  );
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-vehicle-model')),
    '911 GT3',
  );
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-vehicle-vin')),
    'WP0ZZZ99ZPS000000',
  );
  await _tapNext(tester);
  await tester.tap(find.byKey(const Key('jobs-template-version-1')));
  await tester.pumpAndSettle();
  await _tapNext(tester);
}

PublishChecklist _checklist({required bool ready, required bool consent}) =>
    PublishChecklist(
      jobId: 'job-1',
      ready: ready,
      items: [
        const ChecklistEntry(
          code: 'ALL_ITEMS_ASSESSED',
          passed: true,
          messageEn: 'All configured items are assessed',
          messageAr: 'تم تقييم جميع العناصر المهيأة',
        ),
        const ChecklistEntry(
          code: 'EVIDENCE_RULES_MET',
          passed: true,
          messageEn: 'Every finding meets the photo/video evidence rules',
          messageAr: 'كل نتيجة تحقق قواعد أدلة الصور والفيديو',
        ),
        const ChecklistEntry(
          code: 'SIGNATURE_PRESENT',
          passed: true,
          messageEn: 'Technician signature is present',
          messageAr: 'توقيع الفني موجود',
        ),
        ChecklistEntry(
          code: 'SAFETY_CAP_EXPLAINED',
          passed: ready,
          messageEn: 'Safety cap explanation is provided when required',
          messageAr: 'تم تقديم تفسير حد السلامة عند الحاجة',
        ),
        ChecklistEntry(
          code: 'CONSENT_GRANTED',
          passed: consent,
          messageEn: 'Public-link consent is granted',
          messageAr: 'تم منح الموافقة على الرابط العام',
        ),
      ],
      itemsAssessed: 3,
      itemsTotal: 3,
      score: 82,
      gradeCode: 'B',
      safetyCapApplied: false,
      safetyCapReason: null,
      consentGranted: consent,
      signaturePresent: true,
      // Constant on the wire; the rebuilt UI must not render it as a fact.
      documentsReady: true,
    );

class _ChecklistApi extends FakeAdminApi {
  _ChecklistApi(this.checklist);

  final PublishChecklist checklist;

  @override
  Future<PublishChecklist> publishChecklist(String jobId) async => checklist;
}

class _SuccessHost extends ConsumerStatefulWidget {
  const _SuccessHost();

  @override
  ConsumerState<_SuccessHost> createState() => _SuccessHostState();
}

class _SuccessHostState extends ConsumerState<_SuccessHost> {
  CleanJob? _created;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = context.ws;
    final page = ref.watch(cleanJobsProvider(cleanJobsKey())).value;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.jobsCreated, style: ws.pageTitle),
              const SizedBox(height: 16),
              if (_created != null)
                WorkshopCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _created!.reference,
                              textDirection: TextDirection.ltr,
                              style: ws.cardTitle.copyWith(color: ws.ink),
                            ),
                          ),
                          JobStatusBadge(status: _created!.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_created!.customerName, style: ws.body),
                      const SizedBox(height: 8),
                      Text(
                        page == null
                            ? 'clean list loading'
                            : 'clean list: '
                                  '${page.items.map((job) => job.customerName).join(' · ')}',
                        style: ws.meta.copyWith(color: ws.muted),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              WorkshopButton(
                key: const Key('jobs-capture-open-wizard'),
                label: l10n.newJob,
                icon: Icons.add,
                onPressed: () async {
                  final result = await Navigator.of(context).push<CleanJob>(
                    MaterialPageRoute<CleanJob>(
                      builder: (_) => const JobCreationWizardPage(),
                    ),
                  );
                  if (mounted) {
                    setState(() => _created = result);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('wizard_1440', (tester) async {
    final key = await _pump(
      tester,
      home: const JobCreationWizardPage(),
      size: const Size(1440, 1100),
      height: 1100,
    );
    await _capture(tester, key, 'wizard_1440');
  });

  testWidgets('wizard_1024', (tester) async {
    final key = await _pump(
      tester,
      home: const JobCreationWizardPage(),
      size: const Size(1024, 1100),
      height: 1100,
    );
    await _capture(tester, key, 'wizard_1024');
  });

  testWidgets('wizard_390', (tester) async {
    final key = await _pump(
      tester,
      home: const JobCreationWizardPage(),
      size: const Size(390, 1400),
      height: 1400,
    );
    await _capture(tester, key, 'wizard_390');
  });

  testWidgets('wizard_1280_ar', (tester) async {
    final key = await _pump(
      tester,
      home: const JobCreationWizardPage(),
      size: const Size(1280, 1100),
      height: 1100,
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining(RegExp('[٠-٩۰-۹]')), findsNothing);
    await _capture(tester, key, 'wizard_1280_ar');
  });

  testWidgets('wizard_technician_1280', (tester) async {
    final key = await _pump(
      tester,
      home: const JobCreationWizardPage(),
      size: const Size(1280, 1200),
      height: 1200,
    );
    await _advanceToTechnician(tester);
    expect(find.byKey(const Key('jobs-consent-note')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'wizard_technician_1280');
  });

  for (final entry in const <String, (Size, double)>{
    'approve_1440': (Size(1440, 1200), 1200),
    'approve_1280': (Size(1280, 1200), 1200),
    'approve_390': (Size(390, 1600), 1600),
  }.entries) {
    testWidgets(entry.key, (tester) async {
      final key = await _pump(
        tester,
        home: const ApproveIssuePage(jobId: 'job-1'),
        size: entry.value.$1,
        height: entry.value.$2,
      );
      await _capture(tester, key, entry.key);
    });
  }

  testWidgets('approve_1280_ar', (tester) async {
    final key = await _pump(
      tester,
      home: const ApproveIssuePage(jobId: 'job-1'),
      size: const Size(1280, 1200),
      height: 1200,
      locale: const Locale('ar'),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining(RegExp('[٠-٩۰-۹]')), findsNothing);
    expect(
      tester.widget<Text>(find.text('JOB-0001').first).textDirection,
      TextDirection.ltr,
    );
    await _capture(tester, key, 'approve_1280_ar');
  });

  for (final entry in const <String, bool>{
    'checklist_blocked_1280': false,
    'checklist_ready_1280': true,
  }.entries) {
    testWidgets(entry.key, (tester) async {
      final ready = entry.value;
      final key = await _pump(
        tester,
        home: const PublishChecklistPage(jobId: 'job-1'),
        api: _ChecklistApi(_checklist(ready: ready, consent: ready)),
        size: const Size(1280, 1100),
        height: 1100,
      );
      expect(
        find.byKey(const Key('jobs-checklist-ready-chip')),
        findsOneWidget,
      );
      expect(
        find.text(
          AppLocalizations.of(tester.element(find.byType(PublishChecklistPage)))
              .jobsDocumentsReady,
        ),
        findsNothing,
      );
      await _capture(tester, key, entry.key);
    });

    testWidgets('${entry.key}_ar', (tester) async {
      final ready = entry.value;
      final key = await _pump(
        tester,
        home: const PublishChecklistPage(jobId: 'job-1'),
        api: _ChecklistApi(_checklist(ready: ready, consent: ready)),
        size: const Size(1280, 1100),
        height: 1100,
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
      await _capture(tester, key, '${entry.key}_ar');
    });
  }

  testWidgets('documents_1280', (tester) async {
    final key = await _pump(
      tester,
      home: const DocumentsPage(jobId: 'job-3'),
      size: const Size(1280, 1000),
      height: 1000,
    );
    await _capture(tester, key, 'documents_1280');
  });

  testWidgets('documents_390', (tester) async {
    final key = await _pump(
      tester,
      home: const DocumentsPage(jobId: 'job-3'),
      size: const Size(390, 1400),
      height: 1400,
    );
    await _capture(tester, key, 'documents_390');
  });

  testWidgets('create_success_1280', (tester) async {
    final key = await _pump(
      tester,
      home: const _SuccessHost(),
      size: const Size(1280, 900),
      height: 900,
    );
    await tester.tap(find.byKey(const Key('jobs-capture-open-wizard')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('jobs-wizard-customer-name')),
      'Rashid Al Mansoori',
    );
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-customer-phone')),
      '+971500000000',
    );
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-customer-email')),
      'customer@example.test',
    );
    await _tapNext(tester);
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-vehicle-make')),
      'Porsche',
    );
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-vehicle-model')),
      '911 GT3',
    );
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-vehicle-vin')),
      'WP0ZZZ99ZPS000000',
    );
    await _tapNext(tester);
    await tester.tap(find.byKey(const Key('jobs-template-version-1')));
    await tester.pumpAndSettle();
    await _tapNext(tester);
    await tester.tap(find.byKey(const Key('jobs-technician-tech-1')));
    await tester.pumpAndSettle();
    await _tapNext(tester);

    expect(find.byType(JobCreationWizardPage), findsNothing);
    expect(find.text('JOB-0004'), findsOneWidget);
    expect(find.text('Rashid Al Mansoori'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _capture(tester, key, 'create_success_1280');
  });
}
