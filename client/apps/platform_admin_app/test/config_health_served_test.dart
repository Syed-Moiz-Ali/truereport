import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/governance/config_health_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

void main() {
  test('health checks parse served label, description and tone', () {
    final check = HealthCheck.fromJson(<String, dynamic>{
      'code': 'TRANSLATIONS',
      'severity': 'ERROR',
      'status': 'ERROR',
      'messageEn': '3 translation(s) missing',
      'affected': 3,
      'references': <String>['a', 'b', 'c'],
      'labelKey': 'health.check.translations.label',
      'descriptionKey': 'health.check.translations.description',
      'tone': 'danger',
    });

    expect(check.labelKey, 'health.check.translations.label');
    expect(check.descriptionKey, 'health.check.translations.description');
    expect(check.tone, 'danger');
    expect(check.status, 'ERROR');
  });

  testWidgets('config health renders the served keys and health taxonomy', (
    tester,
  ) async {
    const health = ConfigHealth(
      healthy: false,
      checks: <HealthCheck>[
        HealthCheck(
          code: 'TRANSLATIONS',
          severity: 'ERROR',
          messageEn: '3 translation(s) missing',
          messageAr: '',
          affected: 3,
          references: <String>['items.name', 'items.code', 'templates.name'],
          labelKey: 'health.check.translations.label',
          descriptionKey: 'health.check.translations.description',
          tone: 'danger',
          status: 'ERROR',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          uiStringsProvider.overrideWithValue(loadReferenceStrings()),
          statusesProvider('health').overrideWith(
            (ref) async => <ReferenceRecord>[
              record(
                'ERROR',
                labelKey: 'checklist.health.severityBadgeError',
                tone: 'danger',
              ),
              record(
                'HEALTHY',
                labelKey: 'checklist.health.severityBadgeHealthy',
                tone: 'success',
              ),
              record(
                'UNHEALTHY',
                labelKey: 'checklist.health.severityBadgeError',
                tone: 'danger',
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ConfigHealthContent(health: health),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Translations'), findsOneWidget);
    expect(
      find.text('Required content translations are present'),
      findsOneWidget,
    );
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('3 translation(s) missing'), findsOneWidget);
  });
}
