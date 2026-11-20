import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_action_buttons.dart';
import 'package:workshop_admin_app/src/features/jobs/shared/job_action_set.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/ui_strings_harness.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.build(),
    locale: const Locale('en'),
    supportedLocales: const <Locale>[Locale('en')],
    localizationsDelegates: testLocalizationsDelegates,
    builder: (context, child) =>
        uiStringsScope(child: child ?? const SizedBox.shrink()),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders exactly the served actions and nothing else', (
    tester,
  ) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      _app(
        JobActionButtons(
          actions: const <JobAction>[
            JobAction(
              code: 'approve',
              labelKey: 'jobsApprove',
              tone: 'success',
            ),
            JobAction(
              code: 'reject',
              labelKey: 'jobsReject',
              tone: 'danger',
              dangerous: true,
            ),
          ],
          consentGranted: true,
          onAction: (action) => tapped.add(action.code),
        ),
      ),
    );

    expect(find.byKey(const Key('job-action-approve')), findsOneWidget);
    expect(find.byKey(const Key('job-action-reject')), findsOneWidget);
    expect(find.byKey(const Key('job-action-cancel')), findsNothing);
    expect(find.byKey(const Key('job-action-publishChecklist')), findsNothing);

    await tester.tap(find.byKey(const Key('job-action-approve')));
    await tester.tap(find.byKey(const Key('job-action-reject')));
    expect(tapped, <String>['approve', 'reject']);
  });

  testWidgets('requiresConsent surfaces the consent control and disables it', (
    tester,
  ) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      _app(
        JobActionButtons(
          actions: const <JobAction>[
            JobAction(
              code: 'publishChecklist',
              labelKey: 'jobsPublishNow',
              tone: 'success',
              requiresConsent: true,
            ),
          ],
          consentGranted: false,
          onGrantConsent: () {},
          onAction: (action) => tapped.add(action.code),
        ),
      ),
    );

    expect(find.byKey(const Key('job-action-consent')), findsOneWidget);
    final publish = tester.widget<TemplatePillButton>(
      find.byKey(const Key('job-action-publishChecklist')),
    );
    expect(publish.onPressed, isNull);
    expect(tapped, isEmpty);
  });

  test('the model parses allowedActions on every payload', () {
    final actions = <Map<String, dynamic>>[
      <String, dynamic>{
        'code': 'approve',
        'labelKey': 'jobsApprove',
        'tone': 'success',
        'dangerous': false,
        'requiresConsent': true,
      },
    ];

    final job = CleanJob.fromJson(<String, dynamic>{
      'id': 'job-1',
      'allowedActions': actions,
    });
    final review = JobReview.fromJson(<String, dynamic>{
      'jobId': 'job-1',
      'allowedActions': actions,
    });
    final checklist = PublishChecklist.fromJson(<String, dynamic>{
      'jobId': 'job-1',
      'allowedActions': actions,
    });

    for (final list in <List<JobAction>>[
      job.allowedActions,
      review.allowedActions,
      checklist.allowedActions,
    ]) {
      expect(list.single.code, 'approve');
      expect(list.single.labelKey, 'jobsApprove');
      expect(list.single.tone, 'success');
      expect(list.single.requiresConsent, isTrue);
    }
  });

  test('served actions win; the fallback uses codes only', () {
    final served = CleanJob.fromJson(<String, dynamic>{
      'id': 'job-1',
      'status': 'PENDING_REVIEW',
      'allowedActions': <dynamic>[
        <String, dynamic>{'code': 'assign'},
      ],
    });
    expect(
      effectiveDetailActions(served).map((action) => action.code),
      <String>['assign'],
    );

    final fallback = CleanJob.fromJson(<String, dynamic>{
      'id': 'job-2',
      'status': 'PENDING_REVIEW',
      'consentGranted': false,
    });
    expect(
      effectiveDetailActions(fallback).map((action) => action.code),
      <String>['CONSENT', 'REVIEW', 'CANCEL'],
    );
    expect(
      effectiveReviewActions(fallback).map((action) => action.code),
      <String>['APPROVE', 'REJECT'],
    );
    expect(
      effectivePublishActions(
        fallback,
        PublishChecklist.fromJson(<String, dynamic>{
          'jobId': 'job-2',
          'ready': true,
          'consentGranted': false,
        }),
      ).map((action) => action.code),
      <String>['PUBLISH'],
    );
  });

  testWidgets('served labels resolve through the catalog', (tester) async {
    await tester.pumpWidget(
      _app(
        const JobActionButtons(
          actions: <JobAction>[
            JobAction(code: 'approve', labelKey: 'jobsApprove'),
          ],
          consentGranted: true,
          onAction: _noop,
        ),
      ),
    );

    expect(find.text(remoteEnglish('jobsApprove')), findsOneWidget);
  });

  testWidgets('renders the backend uppercase codes and hides granted consent', (
    tester,
  ) async {
    const actions = <JobAction>[
      JobAction(code: 'ASSIGN', labelKey: 'jobsAssignTechnician', tone: 'info'),
      JobAction(code: 'CONSENT', labelKey: 'consentPublicLink', tone: 'info'),
      JobAction(code: 'APPROVE', labelKey: 'jobsApprove', tone: 'success'),
      JobAction(
        code: 'REJECT',
        labelKey: 'jobsReject',
        tone: 'danger',
        dangerous: true,
      ),
      JobAction(
        code: 'CANCEL',
        labelKey: 'cancelJob',
        tone: 'danger',
        dangerous: true,
      ),
    ];
    final tapped = <String>[];
    await tester.pumpWidget(
      _app(
        JobActionButtons(
          actions: actions,
          consentGranted: false,
          onAction: (action) => tapped.add(action.code),
        ),
      ),
    );

    for (final code in const <String>[
      'ASSIGN',
      'CONSENT',
      'APPROVE',
      'REJECT',
      'CANCEL',
    ]) {
      expect(find.byKey(Key('job-action-$code')), findsOneWidget);
    }
    // The served CONSENT action is the control; no duplicate safety pill.
    expect(find.byKey(const Key('job-action-consent')), findsNothing);

    await tester.tap(find.byKey(const Key('job-action-ASSIGN')));
    expect(tapped, <String>['ASSIGN']);

    await tester.pumpWidget(
      _app(
        JobActionButtons(
          actions: actions,
          consentGranted: true,
          onAction: (action) => tapped.add(action.code),
        ),
      ),
    );
    expect(find.byKey(const Key('job-action-CONSENT')), findsNothing);
  });
}

void _noop(JobAction action) {}
