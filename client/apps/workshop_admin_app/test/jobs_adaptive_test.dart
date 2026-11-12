import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/approve_job_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_documents_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_creation_wizard_page.dart';
import 'package:workshop_admin_app/src/features/jobs/job_detail_page.dart';
import 'package:workshop_admin_app/src/features/jobs/jobs_board_tab.dart';
import 'package:workshop_admin_app/src/features/jobs/notification_center.dart';
import 'package:workshop_admin_app/src/features/jobs/public_link_page.dart';
import 'package:workshop_admin_app/src/features/jobs/publish_checklist_page.dart';

import 'support/fake_admin_api.dart';

class _JobsApp extends StatelessWidget {
  const _JobsApp({
    required this.home,
    required this.locale,
  });

  final Widget home;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.build(isArabic: locale.languageCode == 'ar'),
      home: home,
    );
  }
}

const _sizes = <Size>[
  Size(360, 800),
  Size(600, 800),
  Size(768, 900),
  Size(1024, 900),
  Size(1440, 900),
];

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required Locale locale,
  required Size size,
  FakeAdminApi? api,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminApiProvider.overrideWithValue(api ?? FakeAdminApi()),
      ],
      child: _JobsApp(home: screen, locale: locale),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  final screens = <String, Widget Function()>{
    'job creation wizard': () => const JobCreationWizardPage(),
    'jobs board': () => const Scaffold(body: JobsBoardTab()),
    'job detail': () => const JobDetailPage(jobId: 'job-1'),
    'approve & issue': () => const ApproveIssuePage(jobId: 'job-1'),
    'publish checklist': () => const PublishChecklistPage(jobId: 'job-1'),
    'public link': () => const PublicLinkPage(jobId: 'job-3'),
    'documents': () => const DocumentsPage(jobId: 'job-3'),
    'notification center': () =>
        const Scaffold(body: NotificationCenterTab()),
  };

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final entry in screens.entries) {
      for (final size in _sizes) {
        testWidgets(
          '${entry.key} ${locale.languageCode} '
          '${size.width.toInt()} has no overflow',
          (tester) async {
            await _pump(
              tester,
              entry.value(),
              locale: locale,
              size: size,
            );
          },
        );
      }
    }
  }

  testWidgets('job board renders counts, filters and API jobs', (tester) async {
    await _pump(
      tester,
      const Scaffold(body: JobsBoardTab()),
      locale: const Locale('en'),
      size: const Size(1024, 900),
    );

    expect(find.text('JOB-0001'), findsOneWidget);
    expect(
      find.byKey(const Key('jobs-filter-PENDING_REVIEW')),
      findsOneWidget,
    );
    expect(find.text('Pending review (1)'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('JOB-0002'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(find.text('JOB-0002'), findsOneWidget);
  });

  testWidgets('wizard validates required customer fields inline', (
    tester,
  ) async {
    await _pump(
      tester,
      const JobCreationWizardPage(),
      locale: const Locale('en'),
      size: const Size(768, 900),
    );

    await tester.tap(find.byKey(const Key('jobs-wizard-next')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('This field is required.'), findsOneWidget);
  });

  testWidgets('publish checklist ready state enables publish', (tester) async {
    await _pump(
      tester,
      const PublishChecklistPage(jobId: 'job-1'),
      locale: const Locale('en'),
      size: const Size(1024, 900),
      api: FakeAdminApi(checklistReady: true),
    );

    expect(find.text('Ready to publish'), findsOneWidget);
    expect(
      find.byKey(const Key('jobs-checklist-ITEMS_ASSESSED')),
      findsOneWidget,
    );
    final publish = tester.widget<AppButton>(
      find.byKey(const Key('jobs-publish-button')),
    );
    expect(publish.onPressed, isNotNull);
  });

  testWidgets('publish checklist blocked state disables publish', (
    tester,
  ) async {
    await _pump(
      tester,
      const PublishChecklistPage(jobId: 'job-1'),
      locale: const Locale('en'),
      size: const Size(1024, 900),
      api: FakeAdminApi(checklistReady: false),
    );

    expect(find.text('Not ready to publish'), findsWidgets);
    final publish = tester.widget<AppButton>(
      find.byKey(const Key('jobs-publish-button')),
    );
    expect(publish.onPressed, isNull);
  });

  testWidgets('approve workflow updates the job status', (tester) async {
    final api = FakeAdminApi();
    await _pump(
      tester,
      const ApproveIssuePage(jobId: 'job-1'),
      locale: const Locale('en'),
      size: const Size(1024, 900),
      api: api,
    );

    expect(api.statusOf('job-1'), 'PENDING_REVIEW');
    await tester.tap(find.byKey(const Key('jobs-approve-button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(api.statusOf('job-1'), 'APPROVED');
    expect(find.text('Job approved'), findsOneWidget);
  });

  testWidgets('notification center marks a notification read', (
    tester,
  ) async {
    await _pump(
      tester,
      const Scaffold(body: NotificationCenterTab()),
      locale: const Locale('en'),
      size: const Size(768, 900),
    );

    expect(find.text('JOB_PENDING_REVIEW'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('jobs-mark-read-notification-1')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Notification marked as read'), findsOneWidget);
  });
}
