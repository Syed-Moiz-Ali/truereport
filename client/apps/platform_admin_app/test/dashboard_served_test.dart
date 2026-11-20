import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/dashboard/dashboard_feed.dart';
import 'package:platform_admin_app/src/features/dashboard/trellis/trellis_modules.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';

import 'reference_test_support.dart';

Map<String, dynamic> _summaryJson({
  List<Map<String, dynamic>> metricCards = const <Map<String, dynamic>>[],
  List<Map<String, dynamic>> localizedAlerts = const <Map<String, dynamic>>[],
  int pendingReview = 0,
  List<Map<String, dynamic>> alerts = const <Map<String, dynamic>>[],
}) {
  return <String, dynamic>{
    'workshops': <String, dynamic>{'total': 3, 'active': 2},
    'staff': <String, dynamic>{'technicians': 4, 'admins': 1},
    'jobs': <String, dynamic>{'active': 1, 'pendingReview': pendingReview},
    'reports': <String, dynamic>{'published': 2},
    'checklist': <String, dynamic>{
      'categories': 2,
      'items': 10,
      'templates': 1,
      'healthy': true,
      'issues': 0,
    },
    'languages': <String, dynamic>{'live': 1, 'translating': 0},
    'recentActivity': <dynamic>[],
    'alerts': alerts,
    'metricCards': metricCards,
    'localizedAlerts': localizedAlerts,
  };
}

void main() {
  test('overview parses server metric cards and localized alerts', () {
    final summary = OverviewSummary.fromJson(
      _summaryJson(
        metricCards: <Map<String, dynamic>>[
          <String, dynamic>{
            'code': 'activeWorkshops',
            'labelKey': 'dashActiveWorkshops',
            'value': '1,234',
            'captionKey': 'dashActiveWorkshopsCaption',
            'tone': 'success',
            'order': 10,
          },
        ],
        localizedAlerts: <Map<String, dynamic>>[
          <String, dynamic>{
            'code': 'reportFailures',
            'severity': 'danger',
            'order': 30,
            'titleKey': 'dashboard.alert.reportsFailed.title',
            'bodyKey': 'dashboard.alert.reportsFailed.body',
            'args': <String, String>{'count': '3'},
            'action': <String, String>{
              'labelKey': 'dashboard.alert.reportsFailed.action',
              'route': '/reports',
            },
          },
        ],
      ),
    );

    final card = summary.metricCards.single;
    expect(card.labelKey, 'dashActiveWorkshops');
    expect(card.value, '1,234');
    expect(card.captionKey, 'dashActiveWorkshopsCaption');
    expect(card.tone, 'success');
    expect(card.order, 10);

    final alert = summary.localizedAlerts.single;
    expect(alert.severity, 'danger');
    expect(alert.titleKey, 'dashboard.alert.reportsFailed.title');
    expect(alert.args['count'], '3');
    expect(alert.actionLabelKey, 'dashboard.alert.reportsFailed.action');
    expect(alert.actionRoute, '/reports');
  });

  test('attention uses localized alerts with served args and action', () {
    final strings = loadReferenceStrings();
    final summary = OverviewSummary.fromJson(
      _summaryJson(
        pendingReview: 2,
        alerts: <Map<String, dynamic>>[
          <String, dynamic>{
            'severity': 'ERROR',
            'title': 'Legacy alert title',
            'body': 'Legacy alert body',
          },
        ],
        localizedAlerts: <Map<String, dynamic>>[
          <String, dynamic>{
            'code': 'reportFailures',
            'severity': 'danger',
            'order': 30,
            'titleKey': 'dashboard.alert.reportsFailed.title',
            'bodyKey': 'dashboard.alert.reportsFailed.body',
            'args': <String, String>{'count': '3'},
            'action': <String, String>{
              'labelKey': 'dashboard.alert.reportsFailed.action',
              'route': '/reports',
            },
          },
        ],
      ),
    );

    final entries = buildDashboardAttention(summary: summary, strings: strings);

    expect(entries, hasLength(2));
    expect(entries.first.title, contains('2'));
    final alert = entries.last;
    expect(alert.title, 'Report generation failures');
    expect(alert.meta, contains('3 report document(s)'));
    expect(alert.actionLabel, 'Open reports');
    expect(alert.route, '/reports');
    expect(alert.severity, DashboardSeverity.critical);
    expect(alert.canOpen, isTrue);
    // The legacy `alerts` list is not rendered any more.
    expect(
      entries.any((entry) => entry.title == 'Legacy alert title'),
      isFalse,
    );
  });

  testWidgets('the dashboard grid renders served values and omits unknowns', (
    tester,
  ) async {
    final strings = loadReferenceStrings();
    final cards = <OverviewMetricCard>[
      const OverviewMetricCard(
        code: 'late',
        labelKey: 'dashActiveJobs',
        value: '7',
        captionKey: 'dashActiveJobsCaption',
        tone: 'warning',
        order: 20,
      ),
      const OverviewMetricCard(
        code: 'first',
        labelKey: 'dashActiveWorkshops',
        value: '1,234',
        captionKey: 'dashActiveWorkshopsCaption',
        tone: 'success',
        order: 10,
      ),
      const OverviewMetricCard(
        code: 'missing',
        labelKey: 'not.in.the.catalog',
        value: '99',
        captionKey: '',
        tone: 'neutral',
        order: 30,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: SingleChildScrollView(
              child: TrellisBento(strings: strings, cards: cards),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1,234'), findsOneWidget);
    expect(find.text('Active workshops'), findsOneWidget);
    expect(
      find.text('Workshop organisations currently active'),
      findsOneWidget,
    );
    // A card whose label key is absent is omitted, never invented.
    expect(find.text('99'), findsNothing);
    // Order 10 is laid out before order 20.
    expect(
      tester.getTopLeft(find.text('1,234')).dx,
      lessThan(tester.getTopLeft(find.text('7')).dx),
    );
  });

  for (final width in const <double>[360, 768, 1440]) {
    testWidgets('the served metric grid does not overflow at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final strings = loadReferenceStrings();
      final cards = <OverviewMetricCard>[
        for (final entry in <(String, String, String, String)>[
          (
            'dashActiveWorkshops',
            '1,234',
            'dashActiveWorkshopsCaption',
            'success',
          ),
          ('dashTechnicians', '87', 'dashTechniciansCaption', 'info'),
          ('dashActiveJobs', '42', 'dashActiveJobsCaption', 'info'),
          ('dashPendingReviews', '9', 'dashPendingReviewsCaption', 'warning'),
          (
            'dashPublishedReports',
            '318',
            'dashPublishedReportsCaption',
            'success',
          ),
          ('dashChecklistHealth', '0', 'dashChecklistHealthCaption', 'success'),
          ('dashLanguagesLive', '4', 'dashLanguagesLiveCaption', 'info'),
        ].indexed)
          OverviewMetricCard(
            code: entry.$2.$1,
            labelKey: entry.$2.$1,
            value: entry.$2.$2,
            captionKey: entry.$2.$3,
            tone: entry.$2.$4,
            order: entry.$1 * 10,
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrellisBento(strings: strings, cards: cards),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('318'), findsOneWidget);
    });
  }
}
