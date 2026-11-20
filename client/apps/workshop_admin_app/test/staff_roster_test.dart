import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/staff/staff_atoms.dart';
import 'package:workshop_admin_app/src/features/staff/staff_create_page.dart';
import 'package:workshop_admin_app/src/features/staff/staff_member_page.dart';
import 'package:workshop_admin_app/src/features/staff/staff_role_filters.dart';
import 'package:workshop_admin_app/src/features/staff/staff_tab.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

import 'support/fake_admin_api.dart';

import 'support/ui_strings_harness.dart';

/// Staff roster — the queue-shaped table, its counted pill filters and the
/// routes it owns (member record, create page).
///
/// The control language is the templates/jobs pill kit: [TemplatePillChip] for
/// filters and [TemplatePillButton] for actions. No square chips, no underline
/// tabs, no per-row menu: the row is the entry point to the member page.
const _roster = <StaffMember>[
  StaffMember(
    userId: 'tech-1',
    displayName: 'Mariam Abdulrahman Al Suwaidi',
    emailMasked: 'm***@test.local',
    role: 'TECHNICIAN',
    status: 'ACTIVE',
  ),
  StaffMember(
    userId: 'tech-2',
    displayName: 'Khalid Ibrahim Al Hashimi',
    emailMasked: 'k***@test.local',
    role: 'TECHNICIAN',
    status: 'DISABLED',
  ),
  StaffMember(
    userId: 'admin-1',
    displayName: 'Omar Saeed Al Marri',
    emailMasked: 'o***@test.local',
    role: 'WORKSHOP_ADMIN',
    status: 'ACTIVE',
  ),
  StaffMember(
    userId: 'admin-2',
    displayName: 'Hessa Al Mansoori',
    emailMasked: 'h***@test.local',
    role: 'WORKSHOP_ADMIN',
    status: 'PENDING',
  ),
];

class _StaffApi extends FakeAdminApi {
  _StaffApi({
    this.staffError = false,
    this.hang = false,
    this.members = _roster,
  });

  final bool staffError;
  final bool hang;
  final List<StaffMember> members;
  Completer<List<StaffMember>>? gate;

  @override
  Future<List<StaffMember>> staff() async {
    if (staffError) {
      throw StateError('staff failed');
    }
    if (hang) {
      gate ??= Completer<List<StaffMember>>();
      return gate!.future;
    }
    return members;
  }
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({
    required this.home,
    required this.locale,
    this.textScale = 1,
  });

  final Widget home;
  final Locale locale;
  final double textScale;

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
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: testLocalizationsDelegates,
      theme: AppTheme.light,
      builder: (context, child) => uiStringsScope(
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(widget.textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: widget.home,
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

Future<_StaffApi> _pumpStaff(
  WidgetTester tester, {
  required Locale locale,
  double textScale = 1,
  _StaffApi? api,
}) async {
  final effective = api ?? _StaffApi();
  final container = ProviderContainer(
    overrides: [
      adminApiProvider.overrideWithValue(effective),
      ..._referenceOverrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _Harness(
        home: const Scaffold(body: StaffTab()),
        locale: locale,
        textScale: textScale,
      ),
    ),
  );
  container.read(localeProvider.notifier).setLocale(locale);
  await tester.pumpAndSettle();
  return effective;
}

UiStrings _l10n(WidgetTester tester) =>
    UiStrings.of(tester.element(find.byType(StaffTab)));

List<TemplatePillChip> _chips(WidgetTester tester) => tester
    .widgetList<TemplatePillChip>(find.byType(TemplatePillChip))
    .toList(growable: false);

Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.byWidgetPredicate(
    (widget) => widget is TemplatePillChip && widget.label == label,
  );
  expect(chip, findsOneWidget);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

String? _hint(WidgetTester tester, Key key) {
  final field = tester.widget<TextField>(
    find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
  );
  return field.decoration?.hintText;
}

int _rowCount(WidgetTester tester) => const [
  'tech-1',
  'tech-2',
  'admin-1',
  'admin-2',
].where((id) => find.byKey(Key('staff-$id')).evaluate().isNotEmpty).length;

final List<Override> _referenceOverrides = <Override>[
  enumsProvider('role').overrideWith(
    (ref) async => const <ReferenceRecord>[
      ReferenceRecord(
        code: 'WORKSHOP_ADMIN',
        labelKey: 'role.workshopAdmin',
        tone: 'info',
      ),
      ReferenceRecord(
        code: 'TECHNICIAN',
        labelKey: 'role.technician',
        tone: 'neutral',
      ),
    ],
  ),
  statusesProvider('workshop').overrideWith(
    (ref) async => const <ReferenceRecord>[
      ReferenceRecord(
        code: 'ACTIVE',
        labelKey: 'status.workshop.active',
        tone: 'success',
      ),
      ReferenceRecord(
        code: 'DISABLED',
        labelKey: 'status.disabled',
        tone: 'danger',
      ),
    ],
  ),
];

void main() {
  for (final locale in const [Locale('en')]) {
    testWidgets(
      'roster renders counted pill filters and full-name rows (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(1440, 900));
        await _pumpStaff(tester, locale: locale);
        expect(tester.takeException(), isNull);

        final t = _l10n(tester);
        expect(
          find.text(t(WorkshopAdminKeys.workshopStaffTitle)),
          findsOneWidget,
        );
        expect(find.byKey(const Key('staff-search')), findsOneWidget);

        // Filters are the shared pill chips, with roster-wide counts.
        final chips = _chips(tester);
        expect(chips, hasLength(3));
        expect(chips[0].label, t(WorkshopAdminKeys.filterAll));
        expect(chips[0].count, 4);
        expect(chips[1].label, 'Workshop Admin');
        expect(chips[1].count, 2);
        expect(chips[2].label, 'Technician');
        expect(chips[2].count, 2);
        expect(find.byType(WorkshopFilterChip), findsNothing);
        expect(find.byType(TabBar), findsNothing);
        expect(find.byType(StaffRoleFilters), findsOneWidget);

        // Every row is present and names are never ellipsized.
        expect(_rowCount(tester), 4);
        for (final name in const [
          'Mariam Abdulrahman Al Suwaidi',
          'Khalid Ibrahim Al Hashimi',
          'Omar Saeed Al Marri',
          'Hessa Al Mansoori',
        ]) {
          final finder = find.text(name);
          expect(finder, findsOneWidget);
          final label = tester.widget<Text>(finder);
          expect(label.maxLines, isNull);
          expect(label.overflow, isNot(TextOverflow.ellipsis));
        }
        expect(
          find.text(t(WorkshopAdminKeys.roleTechnician)),
          findsNWidgets(3),
        );
        expect(
          find.text(t(WorkshopAdminKeys.roleWorkshopAdmin)),
          findsNWidgets(3),
        );
        expect(find.text(t(WorkshopAdminKeys.filterActive)), findsNWidgets(2));
        expect(find.text(t(WorkshopAdminKeys.disabled)), findsOneWidget);

        // The table has a real header row at this width.
        expect(
          find.text(t(WorkshopAdminKeys.staffTab).toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(t(WorkshopAdminKeys.role).toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(t(WorkshopAdminKeys.status).toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(t(WorkshopAdminKeys.emailLabel).toUpperCase()),
          findsOneWidget,
        );

        // The create action is a pill, not a Material button.
        expect(find.byType(TemplatePillButton), findsWidgets);
        expect(find.byType(WorkshopButton), findsNothing);

        if (locale.languageCode == 'ar') {
          expect(
            Directionality.of(tester.element(find.byType(StaffTab))),
            TextDirection.rtl,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'phone layout and 2.0x text keep the same rows (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(390, 844));
        await _pumpStaff(tester, locale: locale, textScale: 2);
        expect(tester.takeException(), isNull);
        expect(_rowCount(tester), 4);
        expect(find.text('Mariam Abdulrahman Al Suwaidi'), findsOneWidget);
        // Below 1000 the table header disappears and role/email stack under
        // the name, so the identity is never squeezed by fixed columns.
        final t = _l10n(tester);
        expect(
          find.text(t(WorkshopAdminKeys.role).toUpperCase()),
          findsNothing,
        );
        expect(
          find.text(t(WorkshopAdminKeys.emailLabel).toUpperCase()),
          findsNothing,
        );
        expect(find.text('m***@test.local'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'pill filters and search narrow the roster; clear restores it (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(1440, 900));
        await _pumpStaff(tester, locale: locale);
        final t = _l10n(tester);

        await _tapChip(tester, 'Technician');
        expect(_rowCount(tester), 2);
        expect(find.text('Omar Saeed Al Marri'), findsNothing);

        await _tapChip(tester, 'Workshop Admin');
        expect(_rowCount(tester), 2);
        expect(find.text('Mariam Abdulrahman Al Suwaidi'), findsNothing);

        await _tapChip(tester, t(WorkshopAdminKeys.filterAll));
        expect(_rowCount(tester), 4);

        await tester.enterText(find.byKey(const Key('staff-search')), 'hessa');
        await tester.pumpAndSettle();
        expect(_rowCount(tester), 1);
        expect(find.byKey(const Key('staff-admin-2')), findsOneWidget);

        // No results offers a one-click clear that resets both query and role.
        await tester.enterText(find.byKey(const Key('staff-search')), 'zzz');
        await tester.pumpAndSettle();
        expect(_rowCount(tester), 0);
        expect(find.text(t(WorkshopAdminKeys.noResults)), findsOneWidget);
        expect(_chips(tester)[0].count, 4);
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is TemplatePillButton &&
                widget.label == t(WorkshopAdminKeys.jobsClearFilters),
          ),
        );
        await tester.pumpAndSettle();
        expect(_rowCount(tester), 4);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'empty, loading and error states stay designed (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(390, 844));

        final hanging = _StaffApi(hang: true);
        final container = ProviderContainer(
          overrides: [
            adminApiProvider.overrideWithValue(hanging),
            ..._referenceOverrides,
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _Harness(
              home: const Scaffold(body: StaffTab()),
              locale: locale,
            ),
          ),
        );
        container.read(localeProvider.notifier).setLocale(locale);
        await tester.pump();
        expect(find.byType(StaffRosterSkeleton), findsOneWidget);

        hanging.gate!.complete(<StaffMember>[]);
        await tester.pumpAndSettle();
        final t = _l10n(tester);
        expect(find.text(t(WorkshopAdminKeys.noTechnicians)), findsOneWidget);
        expect(find.text(t(WorkshopAdminKeys.staffSubtitle)), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is TemplatePillButton &&
                widget.label == t(WorkshopAdminKeys.createTechnicianTitle),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'staff load failure keeps title, body and retry (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(390, 844));
        await _pumpStaff(
          tester,
          locale: locale,
          api: _StaffApi(staffError: true),
        );
        final t = _l10n(tester);
        expect(find.text(t(WorkshopAdminKeys.error)), findsOneWidget);
        expect(
          find.text(t(WorkshopAdminKeys.commonLoadFailed)),
          findsOneWidget,
        );
        expect(find.text(t(WorkshopAdminKeys.retryAction)), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'row opens the member page with the name in its bar (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(1440, 900));
        await _pumpStaff(tester, locale: locale);
        await tester.tap(find.byKey(const Key('staff-tech-1')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(find.byType(StaffMemberPage), findsOneWidget);
        // Bar, identity headline and the Details fact all name the member.
        expect(find.text('Mariam Abdulrahman Al Suwaidi'), findsNWidgets(3));
        // The masked email is LTR in the identity meta and again as a fact.
        expect(find.textContaining('m***@test.local'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'create page labels every field and carries a hint (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(390, 844));
        final api = await _pumpStaff(tester, locale: locale);
        final t = _l10n(tester);

        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is TemplatePillButton &&
                widget.label == t(WorkshopAdminKeys.create),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(StaffCreatePage), findsOneWidget);
        expect(tester.takeException(), isNull);

        expect(
          _hint(tester, const Key('staff-create-name')),
          t(WorkshopAdminKeys.fullNameHint),
        );
        expect(
          _hint(tester, const Key('staff-create-email')),
          t(WorkshopAdminKeys.technicianEmailHint),
        );
        expect(
          _hint(tester, const Key('staff-create-password')),
          t(WorkshopAdminKeys.temporaryPassword),
        );
        expect(
          _hint(tester, const Key('staff-create-confirm')),
          t(WorkshopAdminKeys.confirmPasswordHint),
        );

        await tester.enterText(
          find.byKey(const Key('staff-create-name')),
          'Technician C',
        );
        await tester.enterText(
          find.byKey(const Key('staff-create-email')),
          'tech.c@test.local',
        );
        await tester.enterText(
          find.byKey(const Key('staff-create-password')),
          'temporary-pass-123',
        );
        await tester.enterText(
          find.byKey(const Key('staff-create-confirm')),
          'temporary-pass-123',
        );
        await tester.pump();
        await tester.tap(find.text(t(WorkshopAdminKeys.create)).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(api.createdTechnicians, contains('tech.c@test.local'));
        expect(find.text(t(WorkshopAdminKeys.accountCreated)), findsOneWidget);
      },
    );
  }

  testWidgets('360 single-member roster has no overflow', (tester) async {
    _setSize(tester, const Size(360, 800));
    await _pumpStaff(
      tester,
      locale: const Locale('en'),
      api: _StaffApi(members: [_roster.first]),
    );
    expect(find.text(_roster.first.displayName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tab keeps moving focus through search, pills and rows', (
    tester,
  ) async {
    _setSize(tester, const Size(1280, 800));
    await _pumpStaff(tester, locale: const Locale('en'));
    await tester.tap(find.byKey(const Key('staff-search')));
    await tester.pump();
    final seen = <FocusNode?>{FocusManager.instance.primaryFocus};
    for (var index = 0; index < 12; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      seen.add(FocusManager.instance.primaryFocus);
    }
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(seen.length, greaterThan(1));
    expect(tester.takeException(), isNull);
  });
}
