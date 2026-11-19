import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_api.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/job_creation_wizard_page.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

import 'support/fake_admin_api.dart';

class _CreateApi extends FakeAdminApi {
  final createRequests = <NewCleanJob>[];

  @override
  Future<CleanJob> createCleanJob(NewCleanJob job) async {
    createRequests.add(job);
    return super.createCleanJob(job);
  }
}

class _QueueHost extends ConsumerStatefulWidget {
  const _QueueHost();

  @override
  ConsumerState<_QueueHost> createState() => _QueueHostState();
}

class _QueueHostState extends ConsumerState<_QueueHost> {
  CleanJob? _created;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(cleanJobsProvider(cleanJobsKey()));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('QUEUE'),
              Text(
                _created == null
                    ? 'created:none'
                    : 'created:${_created!.reference}',
              ),
              TextButton(
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
                child: const Text('Open wizard'),
              ),
              Expanded(
                child: jobs.when(
                  loading: () => const Text('loading'),
                  error: (error, _) => Text('error:$error'),
                  data: (page) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final job in page.items) Text(job.customerName),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  AdminApi? api,
  Size size = const Size(768, 1000),
  Locale locale = const Locale('en'),
}) async {
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
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _tapNext(WidgetTester tester) async {
  final next = find.byKey(const Key('jobs-wizard-next'));
  await tester.ensureVisible(next);
  await tester.tap(next);
  await tester.pumpAndSettle();
}

Future<void> _fillCustomer(
  WidgetTester tester, {
  String name = 'New Customer',
  String phone = '+971500000999',
  String email = 'new@example.test',
}) async {
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-customer-name')),
    name,
  );
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-customer-phone')),
    phone,
  );
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-customer-email')),
    email,
  );
}

Future<void> _advanceToTechnician(WidgetTester tester) async {
  await _fillCustomer(tester);
  await _tapNext(tester);
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-vehicle-make')),
    'Toyota',
  );
  await tester.enterText(
    find.byKey(const Key('jobs-wizard-vehicle-model')),
    'Camry',
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

void main() {
  testWidgets('wizard validates phone, email and VIN before advancing', (
    tester,
  ) async {
    await _pump(tester, const JobCreationWizardPage());
    final l10n = AppLocalizations.of(
      tester.element(find.byType(JobCreationWizardPage)),
    );

    await _tapNext(tester);
    expect(find.text(l10n.requiredField), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('jobs-wizard-customer-name')),
      'New Customer',
    );
    await _tapNext(tester);
    expect(find.text(l10n.jobsValidationPhoneRequired), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('jobs-wizard-customer-phone')),
      '+971500000999',
    );
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-customer-email')),
      'not-an-email',
    );
    await _tapNext(tester);
    expect(find.text(l10n.jobsValidationEmailInvalid), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('jobs-wizard-customer-email')),
      'new@example.test',
    );
    await _tapNext(tester);
    expect(find.byKey(const Key('jobs-wizard-vehicle-make')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('jobs-wizard-vehicle-make')),
      'Toyota',
    );
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-vehicle-model')),
      'Camry',
    );
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-vehicle-vin')),
      'SHORT',
    );
    await _tapNext(tester);
    expect(find.text(l10n.jobsValidationVin), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('jobs-wizard-vehicle-vin')),
      'WP0ZZZ99ZPS000000',
    );
    await _tapNext(tester);
    expect(find.text(l10n.jobsTemplatesAvailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('last step states consent cannot be recorded', (tester) async {
    await _pump(tester, const JobCreationWizardPage());
    await _advanceToTechnician(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(JobCreationWizardPage)),
    );

    expect(find.byKey(const Key('jobs-consent-note')), findsOneWidget);
    expect(find.text(l10n.jobsConsentUnavailableNote), findsOneWidget);
    expect(find.byKey(const Key('jobs-technician-tech-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'create sends the clean request, invalidates the queue providers and pops',
    (tester) async {
      final api = _CreateApi();
      await _pump(
        tester,
        const _QueueHost(),
        api: api,
        size: const Size(1440, 1100),
      );

      await tester.tap(find.text('Open wizard'));
      await tester.pumpAndSettle();
      expect(find.byType(JobCreationWizardPage), findsOneWidget);

      await _fillCustomer(tester);
      await _tapNext(tester);
      await tester.enterText(
        find.byKey(const Key('jobs-wizard-vehicle-make')),
        'Toyota',
      );
      await tester.enterText(
        find.byKey(const Key('jobs-wizard-vehicle-model')),
        'Camry',
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

      expect(api.createRequests, hasLength(1));
      final request = api.createRequests.single;
      expect(request.customerName, 'New Customer');
      expect(request.customerPhone, '+971500000999');
      expect(request.templateVersionId, 'version-1');
      expect(request.assignedTechnicianId, 'tech-1');
      expect(request.scheduledAt, isNull, reason: 'G-J11: no scheduled input');
      expect(request.consentGranted, isFalse);

      // The route popped back to the host, and the watched clean list was
      // invalidated, so the new job is visible without a manual refresh.
      expect(find.byType(JobCreationWizardPage), findsNothing);
      expect(find.text('QUEUE'), findsOneWidget);
      expect(find.text('created:JOB-0004'), findsOneWidget);
      expect(find.text('New Customer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wizard renders in Arabic without overflow', (tester) async {
    await _pump(
      tester,
      const JobCreationWizardPage(),
      size: const Size(390, 1000),
      locale: const Locale('ar'),
    );
    expect(find.byKey(const Key('jobs-wizard-customer-name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
