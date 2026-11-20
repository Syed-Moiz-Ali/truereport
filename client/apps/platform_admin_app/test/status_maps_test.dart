import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/components/platform_chips.dart';
import 'package:platform_admin_app/src/features/checklist/checklist_health_labels.dart';
import 'package:platform_admin_app/src/features/checklist/checklist_status.dart';
import 'package:platform_admin_app/src/features/workshops/workshop_status.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/reference_status_lookup.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

class _LabelProbe extends ConsumerWidget {
  const _LabelProbe(this.resolve);

  final String Function(WidgetRef ref) resolve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(resolve(ref)),
    );
  }
}

Future<void> _pumpProbe(
  WidgetTester tester,
  String Function(WidgetRef ref) resolve, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        uiStringsProvider.overrideWithValue(loadReferenceStrings()),
        ...overrides,
      ],
      child: MaterialApp(home: Scaffold(body: _LabelProbe(resolve))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('workshop status resolves from the served workshop domain', (
    tester,
  ) async {
    await _pumpProbe(
      tester,
      (ref) => workshopStatusLabel(ref, 'DEPOT HUB'),
      overrides: <Override>[
        statusesProvider('workshop').overrideWith(
          (ref) async => <ReferenceRecord>[
            record(
              'DEPOT_HUB',
              labelKey: 'status.workshop.depotHub',
              tone: 'info',
            ),
            record('DISABLED', labelKey: 'status.disabled', tone: 'danger'),
          ],
        ),
      ],
    );

    expect(find.text('Depot hub'), findsOneWidget);
  });

  testWidgets('workshop member status uses the same served domain', (
    tester,
  ) async {
    await _pumpProbe(
      tester,
      (ref) => workshopMemberStatusLabel(ref, 'DISABLED'),
      overrides: <Override>[
        statusesProvider('workshop').overrideWith(
          (ref) async => <ReferenceRecord>[
            record('DISABLED', labelKey: 'status.disabled', tone: 'danger'),
          ],
        ),
      ],
    );

    expect(find.text('Disabled'), findsOneWidget);
  });

  testWidgets('checklist status resolves from the served checklist domain', (
    tester,
  ) async {
    await _pumpProbe(
      tester,
      (ref) => checklistStatusLabel(ref, 'REVIEW'),
      overrides: <Override>[
        statusesProvider('checklist').overrideWith(
          (ref) async => <ReferenceRecord>[
            record(
              'REVIEW',
              labelKey: 'checklist.status.review',
              tone: 'warning',
            ),
            record(
              'IN_REVIEW',
              labelKey: 'checklist.status.review',
              tone: 'warning',
            ),
          ],
        ),
      ],
    );

    expect(find.text('In review'), findsOneWidget);
  });

  testWidgets('health severity resolves from the served health domain', (
    tester,
  ) async {
    await _pumpProbe(
      tester,
      (ref) => healthSeverityLabel(ref, 'WARNING'),
      overrides: <Override>[
        statusesProvider('health').overrideWith(
          (ref) async => <ReferenceRecord>[
            record(
              'WARNING',
              labelKey: 'checklist.health.severityBadgeWarning',
              tone: 'warning',
            ),
          ],
        ),
      ],
    );

    expect(find.text('Warning'), findsOneWidget);
  });

  testWidgets('an unknown code is humanized, never mapped locally', (
    tester,
  ) async {
    await _pumpProbe(
      tester,
      (ref) => workshopStatusLabel(ref, 'awaiting_parts'),
      overrides: <Override>[
        statusesProvider('workshop')
            .overrideWith((ref) async => const <ReferenceRecord>[]),
      ],
    );

    expect(find.text('Awaiting Parts'), findsOneWidget);
  });

  test('status tone tokens come from the served domains', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        statusesProvider('document').overrideWith(
          (ref) async => <ReferenceRecord>[
            record('PENDING', tone: 'warning'),
            record('FAILED', tone: 'danger'),
          ],
        ),
        statusesProvider('chip').overrideWith(
          (ref) async => <ReferenceRecord>[record('DISABLED', tone: 'danger')],
        ),
        statusesProvider('workshop').overrideWith(
          (ref) async => <ReferenceRecord>[
            record('ACTIVE', tone: 'success'),
            record('DRAFT', tone: 'warning'),
            record('RETIRED', tone: 'danger'),
          ],
        ),
        statusesProvider('checklist').overrideWith(
          (ref) async => <ReferenceRecord>[
            record('PUBLISHED', tone: 'success'),
          ],
        ),
        statusesProvider('health')
            .overrideWith((ref) async => <ReferenceRecord>[]),
      ],
    );
    addTearDown(container.dispose);

    for (final domain in const <String>[
      'document',
      'chip',
      'workshop',
      'checklist',
      'health',
    ]) {
      await container.read(statusesProvider(domain).future);
    }

    expect(container.read(statusToneTokenProvider('PENDING')), 'warning');
    expect(container.read(statusToneTokenProvider('FAILED')), 'danger');
    expect(container.read(statusToneTokenProvider('DISABLED')), 'danger');
    expect(container.read(statusToneTokenProvider('ACTIVE')), 'success');
    expect(container.read(statusToneTokenProvider('DRAFT')), 'warning');
    expect(container.read(statusToneTokenProvider('RETIRED')), 'danger');
    expect(container.read(statusToneTokenProvider('PUBLISHED')), 'success');
    expect(container.read(statusToneTokenProvider('SOMETHING_ELSE')), isNull);
  });

  testWidgets('the status chip colours from the served document tone', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          uiStringsProvider.overrideWithValue(loadReferenceStrings()),
          statusesProvider('document').overrideWith(
            (ref) async => <ReferenceRecord>[
              record('PENDING', tone: 'warning'),
            ],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PlatformStatusChip(status: 'PENDING', label: 'Pending'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(PlatformStatusChip),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFFFFBEB));
  });
}
