import 'dart:io';

import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/features/reference/reference_admin_screens.dart';
import 'package:platform_admin_app/src/features/reference/reference_failures.dart';
import 'package:platform_admin_app/src/features/reference/reference_transitions_screen.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

const _inUseDetail =
    'Reference is still in use: 2 items, 0 jobs, 3 templates, 0 documents';

ProviderContainer _container(
  FakeReferenceAdmin admin, {
  required List<Override> overrides,
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      uiStringsProvider.overrideWithValue(loadReferenceStrings()),
      referenceAdminProvider.overrideWithValue(admin),
      ...overrides,
    ],
  );
  return container;
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget body,
) async {
  // The design-token pass grew controls to 48/56px. A 800x600 surface clips
  // the row actions the tests tap, so give the body a real desktop viewport.
  await tester.binding.setSurfaceSize(const Size(1200, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: Scaffold(body: body)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'draft rows come from the admin read and are marked client-hidden',
    (tester) async {
      final draft = record('DRAFTED', labelKey: 'status.draft', order: 0);
      final active = record('ACTIVE', order: 1);
      final admin = FakeReferenceAdmin();
      final container = _container(
        admin,
        overrides: <Override>[
          adminStatusesProvider('job')
              .overrideWith((ref) async => <ReferenceRecord>[draft, active]),
          statusesProvider('job')
              .overrideWith((ref) async => <ReferenceRecord>[active]),
        ],
      );
      addTearDown(container.dispose);

      await _pump(tester, container, const ReferenceStatusesBody());

      expect(find.byKey(const Key('reference-record-DRAFTED')), findsOneWidget);
      expect(find.byKey(const Key('reference-record-ACTIVE')), findsOneWidget);
      expect(find.text('Draft — not visible to clients'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      // Only the draft exposes publish; only the published row exposes retire.
      expect(
        find.byKey(const Key('reference-publish-DRAFTED')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reference-retire-ACTIVE')), findsOneWidget);
      expect(find.byKey(const Key('reference-publish-ACTIVE')), findsNothing);
      expect(find.byKey(const Key('reference-retire-DRAFTED')), findsNothing);
      // The list is draft-aware, not a fake lifecycle.
      expect(find.byKey(const Key('reference-managed-note')), findsOneWidget);
    },
  );

  testWidgets('publish moves the row from the draft set to the visible list', (
    tester,
  ) async {
    var published = false;
    final draft = record('DRAFTED', labelKey: 'status.draft');
    final admin = FakeReferenceAdmin();
    final container = _container(
      admin,
      overrides: <Override>[
        adminStatusesProvider('job')
            .overrideWith((ref) async => <ReferenceRecord>[draft]),
        statusesProvider('job').overrideWith(
          (ref) async =>
              published ? <ReferenceRecord>[draft] : const <ReferenceRecord>[],
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container, const ReferenceStatusesBody());
    expect(find.text('Draft — not visible to clients'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reference-publish-DRAFTED')));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('publishStatus:job:DRAFTED'));

    // The writer made it public; the next reads now agree.
    published = true;
    container.invalidate(statusesProvider('job'));
    await tester.pumpAndSettle();

    expect(find.text('Draft — not visible to clients'), findsNothing);
    expect(find.text('Published'), findsOneWidget);
    expect(find.byKey(const Key('reference-publish-DRAFTED')), findsNothing);
    expect(find.byKey(const Key('reference-retire-DRAFTED')), findsOneWidget);
  });

  testWidgets('retire opens impact and a 409 keeps the record published', (
    tester,
  ) async {
    final active = record('ACTIVE');
    final admin = FakeReferenceAdmin(
      impactResult: const ReferenceImpact(items: 2, templates: 3),
      failRetire: const ApiFailure(
        code: 'REFERENCE_IN_USE',
        messageKey: 'error.conflict',
        statusCode: 409,
        detail: _inUseDetail,
      ),
    );
    final container = _container(
      admin,
      overrides: <Override>[
        adminStatusesProvider('job')
            .overrideWith((ref) async => <ReferenceRecord>[active]),
        statusesProvider('job')
            .overrideWith((ref) async => <ReferenceRecord>[active]),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container, const ReferenceStatusesBody());

    await tester.tap(find.byKey(const Key('reference-retire-ACTIVE')));
    await tester.pumpAndSettle();

    expect(admin.calls, contains('impact:job:ACTIVE'));
    expect(find.byKey(const Key('reference-impact-dialog')), findsOneWidget);
    expect(find.textContaining('2 items'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reference-impact-retire')));
    await tester.pumpAndSettle();

    expect(admin.calls, contains('retireStatus:job:ACTIVE'));
    expect(find.byKey(const Key('reference-in-use-dialog')), findsOneWidget);
    expect(find.textContaining('3 templates'), findsOneWidget);
    // The row is still published: no optimistic retire.
    expect(find.text('Published'), findsOneWidget);
    expect(find.byKey(const Key('reference-retire-ACTIVE')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reference-in-use-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reference-in-use-dialog')), findsNothing);
  });

  testWidgets('create keeps the dialog open and shows the 422 catalog error', (
    tester,
  ) async {
    final admin = FakeReferenceAdmin(
      failCreateStatus: const ApiFailure(
        code: 'LABEL_KEY_UNKNOWN',
        messageKey: 'error.validation.failed',
        statusCode: 422,
        detail: 'labelKey is not present in the UI catalogs: missing.key',
      ),
    );
    final container = _container(
      admin,
      overrides: <Override>[
        adminStatusesProvider('job')
            .overrideWith((ref) async => const <ReferenceRecord>[]),
        statusesProvider('job')
            .overrideWith((ref) async => const <ReferenceRecord>[]),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container, const ReferenceStatusesBody());

    await tester.tap(find.byKey(const Key('reference-create')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reference-form-code')),
      'NEW_STATUS',
    );
    await tester.enterText(
      find.byKey(const Key('reference-form-label-key')),
      'missing.key',
    );
    await tester.ensureVisible(find.byKey(const Key('reference-form-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reference-form-save')));
    await tester.pumpAndSettle();

    expect(admin.calls, contains('createStatus:job'));
    expect(find.byKey(const Key('reference-form-error')), findsOneWidget);
    expect(
      find.text('That label key is not present in the UI catalogs.'),
      findsOneWidget,
    );
  });

  testWidgets('enum lifecycle calls the enum endpoints', (tester) async {
    var published = false;
    final draft = record('NEW_ROLE', labelKey: 'role.technician');
    final admin = FakeReferenceAdmin(
      impactResult: const ReferenceImpact(items: 1),
    );
    final container = _container(
      admin,
      overrides: <Override>[
        adminEnumsProvider('role')
            .overrideWith((ref) async => <ReferenceRecord>[draft]),
        enumsProvider('role').overrideWith(
          (ref) async =>
              published ? <ReferenceRecord>[draft] : const <ReferenceRecord>[],
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container, const ReferenceEnumsBody());
    expect(find.text('Draft — not visible to clients'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reference-publish-NEW_ROLE')));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('publishEnum:role:NEW_ROLE'));

    published = true;
    container.invalidate(enumsProvider('role'));
    await tester.pumpAndSettle();
    expect(find.text('Published'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reference-retire-NEW_ROLE')));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('impact:role:NEW_ROLE'));
    await tester.tap(find.byKey(const Key('reference-impact-retire')));
    await tester.pumpAndSettle();
    expect(admin.calls, contains('retireEnum:role:NEW_ROLE'));
    // 409 was not raised here, so the confirm path closed without an in-use dialog.
    expect(find.byKey(const Key('reference-in-use-dialog')), findsNothing);
  });

  testWidgets('enum reorder calls the enum reorder route', (tester) async {
    final alpha = record('ALPHA', order: 0);
    final beta = record('BETA', order: 1);
    final admin = FakeReferenceAdmin();
    final container = _container(
      admin,
      overrides: <Override>[
        adminEnumsProvider('role')
            .overrideWith((ref) async => <ReferenceRecord>[alpha, beta]),
        enumsProvider('role')
            .overrideWith((ref) async => <ReferenceRecord>[alpha, beta]),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container, const ReferenceEnumsBody());
    await tester.tap(find.byKey(const Key('reference-move-down-ALPHA')));
    await tester.pumpAndSettle();

    expect(admin.calls, contains('reorderEnums:role'));
    expect(admin.lastReorder!.map((entry) => entry.code), <String>[
      'BETA',
      'ALPHA',
    ]);
  });

  testWidgets('transitions editor replaces the whole edge set', (tester) async {
    final admin = FakeReferenceAdmin();
    final container = _container(
      admin,
      overrides: <Override>[
        transitionRulesProvider('job').overrideWith(
          (ref) async => const <ReferenceTransition>[
            ReferenceTransition(
              fromCode: 'DRAFT',
              toCode: 'SCHEDULED',
              role: 'WORKSHOP_ADMIN',
              guard: <String, Object?>{'reason': 'required'},
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container, const ReferenceTransitionsBody());
    expect(find.text('Edges: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reference-transition-add')));
    await tester.pumpAndSettle();
    expect(find.text('Edges: 2'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('reference-edge-from-1')),
      'SCHEDULED',
    );
    await tester.enterText(
      find.byKey(const Key('reference-edge-to-1')),
      'ASSIGNED',
    );
    await tester.tap(find.byKey(const Key('reference-transition-save')));
    await tester.pumpAndSettle();

    expect(admin.calls, contains('replaceTransitions:job'));
    final edges = admin.lastTransitions!;
    expect(edges.length, 2);
    expect(edges.first.fromCode, 'DRAFT');
    expect(edges.first.toCode, 'SCHEDULED');
    expect(edges.first.role, 'WORKSHOP_ADMIN');
    // Untouched guards survive the atomic replace.
    expect(edges.first.guard, <String, Object?>{'reason': 'required'});
    expect(edges.last.fromCode, 'SCHEDULED');
    expect(edges.last.toCode, 'ASSIGNED');
    expect(find.text('Transitions saved.'), findsOneWidget);
  });

  testWidgets('an empty edge is rejected before the replace call', (
    tester,
  ) async {
    final admin = FakeReferenceAdmin();
    final container = _container(
      admin,
      overrides: <Override>[
        transitionRulesProvider('job')
            .overrideWith((ref) async => const <ReferenceTransition>[]),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container, const ReferenceTransitionsBody());
    await tester.tap(find.byKey(const Key('reference-transition-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reference-transition-save')));
    await tester.pumpAndSettle();

    expect(
      admin.calls.where((call) => call.startsWith('replace')).isEmpty,
      isTrue,
    );
    expect(find.byKey(const Key('reference-transition-error')), findsOneWidget);
  });

  test('write failures map to backend-catalog messages', () {
    final strings = loadReferenceStrings();
    expect(
      referenceErrorText(
        strings,
        const ApiFailure(
          code: 'FORBIDDEN',
          messageKey: 'error.forbidden',
          statusCode: 403,
        ),
      ),
      'Only Platform Admin can change reference data.',
    );
    expect(
      referenceErrorText(
        strings,
        const ApiFailure(
          code: 'LABEL_KEY_UNKNOWN',
          messageKey: 'error.validation.failed',
          statusCode: 422,
        ),
      ),
      'That label key is not present in the UI catalogs.',
    );
    expect(
      referenceErrorText(
        strings,
        const ApiFailure(
          code: 'REFERENCE_EXISTS',
          messageKey: 'error.conflict',
          statusCode: 409,
        ),
      ),
      'That code already exists.',
    );
    expect(
      referenceErrorText(strings, StateError('boom')),
      'The reference change failed.',
    );
    // The real server detail shape parses as a fallback.
    final parsed = impactFromDetail(_inUseDetail);
    expect(parsed?.items, 2);
    expect(parsed?.templates, 3);
    expect(impactFromDetail('nonsense'), isNull);
  });

  test('platform models carry no Arabic accessors', () {
    for (final path in const <String>[
      'lib/src/platform_catalogue_models.dart',
      'lib/src/platform_config_models.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        RegExp(r'\b(labelAr|nameAr|instructionAr|categoryLabelAr)\b')
            .hasMatch(source),
        isFalse,
        reason: '$path still has a legacy Arabic accessor',
      );
    }
  });
}
