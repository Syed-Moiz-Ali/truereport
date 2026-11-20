import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/features/jobs/approve/approve_score.dart';
import 'package:workshop_admin_app/src/features/reports/report_data.dart';
import 'package:workshop_admin_app/src/features/reports/report_distribution.dart';
import 'package:workshop_admin_app/src/features/reports/report_sheet.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';
import 'package:workshop_admin_app/src/workshop_job_providers.dart';

import 'support/ui_strings_harness.dart';

Widget _harness(List<Override> overrides, Widget child) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.build(),
      locale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: testLocalizationsDelegates,
      builder: (context, child) =>
          uiStringsScope(child: child ?? const SizedBox.shrink()),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

class _RoleProbe extends ConsumerWidget {
  const _RoleProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(staffRoleLabel(ref, 'TECHNICIAN'));
  }
}

void main() {
  testWidgets('review numbers render from GET /jobs/{id}/review', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(<Override>[
        jobReviewProvider('job-1').overrideWith(
          (ref) async => const JobReview(
            jobId: 'job-1',
            status: 'PENDING_REVIEW',
            itemsAssessed: 3,
            itemsTotal: 5,
            scorePreview: 87.5,
            gradePreview: 'B',
            safetyCapPreview: 'Capped by safety',
            findings: <ReviewFinding>[],
          ),
        ),
      ], const ApproveScore(jobId: 'job-1')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('3 / 5'), findsOneWidget);
    expect(find.textContaining('87.5'), findsOneWidget);
    expect(find.textContaining(': B'), findsOneWidget);
    expect(find.textContaining('Capped by safety'), findsOneWidget);
  });

  testWidgets('template status pill resolves the served template record', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(<Override>[
        statusesProvider('template').overrideWith(
          (ref) async => const <ReferenceRecord>[
            ReferenceRecord(
              code: 'PUBLISHED',
              labelKey: 'published',
              tone: 'success',
            ),
          ],
        ),
      ], const TemplateStatusPill(status: 'PUBLISHED')),
    );
    await tester.pumpAndSettle();

    expect(find.text(remoteEnglish('published')), findsOneWidget);
  });

  testWidgets('staff role and status resolve from the served taxonomies', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        <Override>[
          enumsProvider('role').overrideWith(
            (ref) async => const <ReferenceRecord>[
              ReferenceRecord(
                code: 'TECHNICIAN',
                labelKey: 'jobsStatusApproved',
                tone: 'neutral',
              ),
            ],
          ),
          statusesProvider('workshop').overrideWith(
            (ref) async => const <ReferenceRecord>[
              ReferenceRecord(
                code: 'ACTIVE',
                labelKey: 'statusCancelled',
                tone: 'success',
              ),
            ],
          ),
        ],
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _RoleProbe(),
            StaffStatusDot(status: 'ACTIVE', pill: true),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(remoteEnglish('jobsStatusApproved')), findsOneWidget);
    expect(find.text(remoteEnglish('statusCancelled')), findsOneWidget);
  });

  test('report metrics come from the served summary, never recomputed', () {
    final withSummary = ReportData.summarize(
      ReportAdmin.fromJson(<String, dynamic>{
        'reportId': 'report-1',
        'content': <String, dynamic>{
          'summary': <String, dynamic>{
            'findingsCount': 7,
            'safetyCriticalCount': 2,
            'passedCount': 9,
            'coveragePercent': 80,
          },
          'coverage': <String, dynamic>{
            'completed': 8,
            'applicable': 10,
            'total': 10,
          },
          'keyFindings': <dynamic>[
            <String, dynamic>{'resultCode': 'DEFECT_FOUND'},
            <String, dynamic>{'resultCode': 'DEFECT_FOUND'},
            <String, dynamic>{'resultCode': 'DEFECT_FOUND'},
          ],
          'categories': <dynamic>[
            <String, dynamic>{
              'items': <dynamic>[
                <String, dynamic>{'resultCode': 'NO_ISSUE_OBSERVED'},
                <String, dynamic>{'resultCode': 'DEFECT_FOUND'},
              ],
            },
          ],
        },
      }),
    );

    expect(withSummary.findingsCount, 7);
    expect(withSummary.safetyCriticalCount, 2);
    expect(withSummary.passedCount, 9);
    expect(withSummary.coveragePercent, 80);
    expect(withSummary.coverageText, '8 / 10');

    // Without the served summary the same arrays must NOT produce numbers.
    final withoutSummary = ReportData.summarize(
      ReportAdmin.fromJson(<String, dynamic>{
        'reportId': 'report-2',
        'content': <String, dynamic>{
          'keyFindings': <dynamic>[
            <String, dynamic>{'resultCode': 'DEFECT_FOUND'},
          ],
          'categories': <dynamic>[
            <String, dynamic>{
              'items': <dynamic>[
                <String, dynamic>{'resultCode': 'NO_ISSUE_OBSERVED'},
              ],
            },
          ],
        },
      }),
    );

    expect(withoutSummary.findingsCount, isNull);
    expect(withoutSummary.safetyCriticalCount, isNull);
    expect(withoutSummary.passedCount, isNull);
    expect(withoutSummary.coveragePercent, isNull);
  });

  testWidgets('report sheet renders the served summary and 100% coverage', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final report = ReportAdmin.fromJson(<String, dynamic>{
      'reportId': 'report-1',
      'jobId': 'job-1',
      'reportNumber': 'JOB-02F2ED6E',
      'version': 1,
      'generationStatus': 'READY',
      'reportReady': true,
      'linkState': 'ACTIVE',
      'consentState': 'GRANTED',
      'publicUrl': 'https://reports.example/r/token',
      'finalizedAt': '2026-11-20T10:00',
      'snapshotHash': 'abc123',
      'content': <String, dynamic>{
        'summary': <String, dynamic>{
          'findingsCount': 5,
          'safetyCriticalCount': 1,
          'passedCount': 30,
          'coveragePercent': 100,
        },
        'coverage': <String, dynamic>{
          'total': 30,
          'applicable': 30,
          'completed': 30,
          'notApplicable': 0,
          'notChecked': 0,
          'couldNotVerify': 0,
        },
        'vehicle': <String, dynamic>{
          'make': 'Toyota',
          'model': 'Land Cruiser',
          'year': 2022,
          'plate': 'ABC-123',
          'odometerValue': 45000,
          'odometerUnit': 'km',
        },
        'inspection': <String, dynamic>{
          'scope': 'Inspection',
          'dateTime': '2026-11-20T10:00',
        },
        'workshop': <String, dynamic>{
          'name': 'TrueReport Workshop',
          'branch': 'Main',
        },
        'technician': <String, dynamic>{'displayName': 'Ahmed'},
        'customerName': 'Customer',
        'keyFindings': <dynamic>[
          <String, dynamic>{
            'labelEn': 'Brake pad wear',
            'resultCode': 'DEFECT_FOUND',
            'severityCode': 'MAJOR',
            'note': 'Replace front pads',
          },
        ],
        'categories': <dynamic>[
          <String, dynamic>{
            'labelEn': 'Brakes',
            'items': <dynamic>[
              <String, dynamic>{
                'labelEn': 'Front pads',
                'resultCode': 'DEFECT_FOUND',
              },
            ],
          },
        ],
        'verificationHash': 'abc123',
      },
    });

    await tester.pumpWidget(
      _harness(
        <Override>[
          statusesProvider('document').overrideWith(
            (ref) async => const <ReferenceRecord>[
              ReferenceRecord(
                code: 'READY',
                labelKey: 'documentStatusReady',
                tone: 'success',
              ),
            ],
          ),
        ],
        SizedBox(width: 760, child: ReportSheet(report: report, canPop: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('JOB-02F2ED6E'), findsOneWidget);
    expect(find.text('30 / 30'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('100%')), findsOneWidget);
    // Checks and passed both read 30 from the payload.
    expect(find.text('30'), findsNWidgets(2));
    expect(find.text('5'), findsNWidgets(2));
    semantics.dispose();
  });

  testWidgets('distribution rows use delivery, consent and publication', (
    tester,
  ) async {
    final report = ReportAdmin.fromJson(<String, dynamic>{
      'reportId': 'report-1',
      'linkState': 'ACTIVE',
      'consentState': 'GRANTED',
      'publicUrl': 'https://reports.example/r/token',
    });
    final delivery = ReportDelivery.fromJson(<String, dynamic>{
      'id': 'delivery-1',
      'channel': 'EMAIL',
      'recipientMasked': 'c***@example.com',
      'language': 'en',
      'status': 'DELIVERED',
      'attempts': 1,
      'maxAttempts': 3,
    });

    await tester.pumpWidget(
      _harness(
        <Override>[
          statusesProvider('publication').overrideWith(
            (ref) async => const <ReferenceRecord>[
              ReferenceRecord(
                code: 'ACTIVE',
                labelKey: 'active',
                tone: 'success',
              ),
            ],
          ),
          statusesProvider('consent').overrideWith(
            (ref) async => const <ReferenceRecord>[
              ReferenceRecord(
                code: 'GRANTED',
                labelKey: 'consentGranted',
                tone: 'success',
              ),
              ReferenceRecord(
                code: 'NOT_GRANTED',
                labelKey: 'consentNotGranted',
                tone: 'warning',
              ),
            ],
          ),
          statusesProvider('delivery').overrideWith(
            (ref) async => const <ReferenceRecord>[
              ReferenceRecord(
                code: 'DELIVERED',
                labelKey: 'deliveryStatusDelivered',
                tone: 'success',
              ),
            ],
          ),
        ],
        SizedBox(
          width: 360,
          child: ReportDistribution(
            report: report,
            deliveries: AsyncData<List<ReportDelivery>>(<ReportDelivery>[
              delivery,
            ]),
            publicUrl: report.publicUrl,
            isBusy: false,
            onCopy: _noop,
            onCreateLink: _noop,
            onRevoke: _noop,
            onSend: _noop,
            onRetryDelivery: (_) {},
            onTogglePdf: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Granted'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
  });
}

void _noop() {}
