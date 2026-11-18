import 'dart:async';

import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/staff/staff_tab.dart';
import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fake_admin_api.dart';

/// Screen 5 — Workshop Staff roster (Figma 1280 drawn, EN+AR).
///
/// Roster core only: page header (title + subtitle + Create), one toolbar
/// (search + counted role chips) and one roster surface from the existing
/// `GET /staff` payload — a table from 900 px, stacked rows below. No
/// invitations/pending (C0), no shifts/bays/metrics/NFC, masked emails only,
/// neutral roles only.
const _roster = <StaffMember>[
  StaffMember(
    userId: 'tech-1',
    displayName: 'Technician A',
    emailMasked: 't***@test.local',
    role: 'TECHNICIAN',
    status: 'ACTIVE',
  ),
  StaffMember(
    userId: 'tech-2',
    displayName: 'Technician B',
    emailMasked: 'tb***@test.local',
    role: 'TECHNICIAN',
    status: 'DISABLED',
  ),
  StaffMember(
    userId: 'admin-1',
    displayName: 'Admin A',
    emailMasked: 'a***@test.local',
    role: 'WORKSHOP_ADMIN',
    status: 'ACTIVE',
  ),
  StaffMember(
    userId: 'admin-2',
    displayName: 'Admin B',
    emailMasked: 'ab***@test.local',
    role: 'WORKSHOP_ADMIN',
    status: 'ACTIVE',
  ),
];

const _rowIds = ['tech-1', 'tech-2', 'admin-1', 'admin-2'];

class _RosterApi extends FakeAdminApi {
  _RosterApi({this.staffError = false, this.hang = false});

  final bool staffError;
  final bool hang;
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
    return _roster;
  }
}

const _session = Session(
  accessToken: 'token',
  refreshToken: 'refresh',
  user: User(
    id: 'user-1',
    email: 'layla@test.local',
    displayName: 'Layla Haddad',
    platformAdmin: false,
    totpEnabled: false,
  ),
  memberships: [
    Membership(
      workshopId: 'workshop-1',
      workshopName: 'Marina Workshop',
      role: Role.workshopAdmin,
    ),
  ],
);

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
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(widget.textScale)),
        child: child ?? const SizedBox.shrink(),
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

Future<_RosterApi> _pumpStaff(
  WidgetTester tester, {
  required Locale locale,
  double textScale = 1,
  _RosterApi? api,
  Session? session,
}) async {
  final effective = api ?? _RosterApi();
  final container = ProviderContainer(
    overrides: [adminApiProvider.overrideWithValue(effective)],
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
  if (session != null) {
    container.read(authControllerProvider.notifier).state = AsyncData<Session?>(
      session,
    );
  }
  // Re-apply the locale after the pump: a second pumpWidget in the same
  // test reuses the mounted harness state (no re-initState), so a fresh
  // container would otherwise fall back to its default locale.
  container.read(localeProvider.notifier).setLocale(locale);
  await tester.pumpAndSettle();
  return effective;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(StaffTab)));

List<WorkshopFilterChip> _chips(WidgetTester tester) => tester
    .widgetList<WorkshopFilterChip>(find.byType(WorkshopFilterChip))
    .toList(growable: false);

Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.byWidgetPredicate(
    (widget) => widget is WorkshopFilterChip && widget.label == label,
  );
  expect(chip, findsOneWidget);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

int _rowCount(WidgetTester tester) =>
    find.byKey(const Key('staff-tech-1')).evaluate().length +
    find.byKey(const Key('staff-tech-2')).evaluate().length +
    find.byKey(const Key('staff-admin-1')).evaluate().length +
    find.byKey(const Key('staff-admin-2')).evaluate().length;

List<Offset> _rowCenters(WidgetTester tester) => [
  for (final id in _rowIds) tester.getCenter(find.byKey(Key('staff-$id'))),
];

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'roster renders header, counted chips and rows at 1280 (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(1280, 800));
        await _pumpStaff(tester, locale: locale);
        expect(tester.takeException(), isNull);

        final l10n = _l10n(tester);
        expect(find.text(l10n.workshopStaffTitle), findsOneWidget);
        expect(find.text(l10n.staffSubtitle), findsOneWidget);
        expect(find.byKey(const Key('staff-search')), findsOneWidget);

        // Filter chips carry client-side counts from GET /staff.
        final chips = _chips(tester);
        expect(chips, hasLength(3));
        expect(chips[0].label, l10n.filterAll);
        expect(chips[0].count, 4);
        expect(chips[1].label, l10n.staffFilterTechnicians);
        expect(chips[1].count, 2);
        expect(chips[2].label, l10n.staffFilterAdmins);
        expect(chips[2].count, 2);

        // Table header columns (existing ARB labels only).
        expect(find.text(l10n.displayName), findsOneWidget);
        expect(find.text(l10n.role), findsOneWidget);
        expect(find.text(l10n.status), findsOneWidget);
        expect(find.text(l10n.emailLabel), findsOneWidget);

        // Rows show display names in full (no ellipsis), masked emails (LTR)
        // and neutral role text.
        expect(_rowCount(tester), 4);
        for (final name in const [
          'Technician A',
          'Technician B',
          'Admin A',
          'Admin B',
        ]) {
          final finder = find.text(name);
          expect(finder, findsOneWidget);
          final label = tester.widget<Text>(finder);
          expect(label.maxLines, isNull);
          expect(label.overflow, isNot(TextOverflow.ellipsis));
        }
        expect(find.text(l10n.roleTechnician), findsNWidgets(2));
        expect(find.text(l10n.roleWorkshopAdmin), findsNWidgets(2));
        expect(find.text(l10n.filterActive), findsNWidgets(3));
        expect(find.text(l10n.disabled), findsOneWidget);
        for (final masked in const [
          't***@test.local',
          'tb***@test.local',
          'a***@test.local',
          'ab***@test.local',
        ]) {
          final finder = find.text(masked);
          expect(finder, findsOneWidget);
          final label = tester.widget<Text>(finder);
          expect(label.textDirection, TextDirection.ltr);
        }

        // 1280 table: rows stack top-to-bottom, aligned on one column.
        final centers = _rowCenters(tester);
        for (var index = 1; index < centers.length; index++) {
          expect(centers[index].dy, greaterThan(centers[index - 1].dy));
          expect(
            centers[index].dx,
            moreOrLessEquals(centers[0].dx, epsilon: 1),
          );
        }

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
      'phone layout stacks the same rows and survives 2.0x (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(390, 844));
        await _pumpStaff(tester, locale: locale, textScale: 2);
        expect(tester.takeException(), isNull);

        expect(_rowCount(tester), 4);
        final centers = _rowCenters(tester);
        for (var index = 1; index < centers.length; index++) {
          expect(
            centers[index].dx,
            moreOrLessEquals(centers[0].dx, epsilon: 1),
          );
          expect(centers[index].dy, greaterThan(centers[index - 1].dy));
        }
        // Full names still render (no ellipsis pressure at 2.0x).
        final name = tester.widget<Text>(find.text('Technician A'));
        expect(name.maxLines, isNull);
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
      'chips and search filter the roster client-side (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(1280, 800));
        await _pumpStaff(tester, locale: locale);
        final l10n = _l10n(tester);

        await _tapChip(tester, l10n.staffFilterTechnicians);
        expect(_rowCount(tester), 2);
        expect(find.text('Technician A'), findsOneWidget);
        expect(find.text('Admin A'), findsNothing);

        await _tapChip(tester, l10n.staffFilterAdmins);
        expect(_rowCount(tester), 2);
        expect(find.text('Admin A'), findsOneWidget);
        expect(find.text('Technician A'), findsNothing);

        await _tapChip(tester, l10n.filterAll);
        expect(_rowCount(tester), 4);

        // Search matches display names (case-insensitive).
        await tester.enterText(
          find.byKey(const Key('staff-search')),
          'admin b',
        );
        await tester.pumpAndSettle();
        expect(_rowCount(tester), 1);
        expect(find.byKey(const Key('staff-admin-2')), findsOneWidget);

        // Search matches masked emails; chip counts stay roster-wide.
        await tester.enterText(find.byKey(const Key('staff-search')), 'tb***');
        await tester.pumpAndSettle();
        expect(_rowCount(tester), 1);
        expect(find.byKey(const Key('staff-tech-2')), findsOneWidget);
        expect(_chips(tester)[0].count, 4);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'roster carries no bay/shift/certification wording (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(1280, 800));
        await _pumpStaff(tester, locale: locale);
        final l10n = _l10n(tester);

        // Open a reset menu so its items are scanned too.
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        expect(find.text(l10n.temporaryPassword), findsWidgets);

        final text = tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data ?? '')
            .join('\n')
            .toLowerCase();
        for (final banned in const [
          'bay',
          'shift',
          'certif',
          'lead',
          'supervisor',
          'accuracy',
          'nfc',
          'live roster',
          'roster pdf',
          'terminal',
          'utilization',
          'compliance',
          'ev certified',
          'logged',
        ]) {
          expect(
            text.contains(banned),
            isFalse,
            reason: 'banned wording "$banned" is rendered',
          );
        }

        // Omitted Figma extras leave no widgets behind.
        expect(find.byType(Switch), findsNothing);
        expect(find.byType(WorkshopMetric), findsNothing);
        expect(find.byType(WorkshopStatCard), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'reset menu is preserved and controls are keyboard-reachable (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(1280, 800));
        await _pumpStaff(tester, locale: locale);
        final l10n = _l10n(tester);

        // Pointer path: the per-row menu still opens the reset dialog.
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.temporaryPassword).last);
        await tester.pumpAndSettle();
        expect(find.text(l10n.confirm), findsOneWidget);
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();
        expect(find.text(l10n.confirm), findsNothing);

        // Keyboard path: Tab-walk from the search field moves focus
        // across the search, chips, create button and row menus.
        await tester.tap(find.byKey(const Key('staff-search')));
        await tester.pump();
        final seen = <FocusNode?>[FocusManager.instance.primaryFocus];
        for (var index = 0; index < 12; index++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          seen.add(FocusManager.instance.primaryFocus);
        }
        expect(FocusManager.instance.primaryFocus, isNotNull);
        expect(seen.toSet().length, greaterThan(1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'add trigger still creates a technician (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(390, 844));
        final api = await _pumpStaff(tester, locale: locale);
        final l10n = _l10n(tester);

        await tester.tap(find.text(l10n.create));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Fixed technician role, no workshop picker (own workshop).
        expect(find.text(l10n.roleTechnician), findsWidgets);
        expect(find.text(l10n.workshop), findsNothing);

        await tester.enterText(
          find.widgetWithText(AppTextField, l10n.email).first,
          'tech@test.local',
        );
        await tester.enterText(
          find.widgetWithText(AppTextField, l10n.displayName).first,
          'Technician C',
        );
        await tester.enterText(
          find.widgetWithText(AppTextField, l10n.temporaryPassword).first,
          'temporary-pass-123',
        );
        await tester.tap(find.text(l10n.create).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(api.createdTechnicians, contains('tech@test.local'));
        expect(find.text(l10n.accountCreated), findsOneWidget);
      },
    );

    testWidgets(
      'loading skeleton and empty state are preserved (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(390, 844));

        // Loading skeleton while GET /staff is in flight.
        final hanging = _RosterApi(hang: true);
        final container = ProviderContainer(
          overrides: [adminApiProvider.overrideWithValue(hanging)],
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
        await tester.pump();
        expect(find.byType(WorkshopSkeleton), findsOneWidget);

        // An empty roster resolves to the empty state with its Create action.
        hanging.gate!.complete(<StaffMember>[]);
        await tester.pumpAndSettle();
        final l10n = _l10n(tester);
        expect(find.text(l10n.noTechnicians), findsOneWidget);
        expect(find.text(l10n.staffSubtitle), findsWidgets);
        expect(find.text(l10n.create), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'staff error state with retry is preserved (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(390, 844));
        await _pumpStaff(
          tester,
          locale: locale,
          api: _RosterApi(staffError: true),
        );
        final l10n = _l10n(tester);

        // A failed GET /staff resolves to the preserved error state.
        expect(find.byType(WorkshopErrorState), findsOneWidget);
        expect(find.text(l10n.genericError), findsOneWidget);
        expect(find.text(l10n.retryAction), findsOneWidget);
        await tester.tap(find.text(l10n.retryAction));
        await tester.pumpAndSettle();
        expect(find.text(l10n.genericError), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'page header owns identity copy, not the signed-in account (${locale.languageCode})',
      (tester) async {
        _setSize(tester, const Size(1280, 800));
        await _pumpStaff(tester, locale: locale, session: _session);
        expect(tester.takeException(), isNull);

        // The shell owns the account menu; the staff page never duplicates it.
        expect(find.byType(WorkshopUserChip), findsNothing);
        expect(find.text('Layla Haddad'), findsNothing);
        expect(find.text('Marina Workshop'), findsNothing);
        final l10n = _l10n(tester);
        expect(find.text(l10n.workshopStaffTitle), findsOneWidget);
        expect(find.text(l10n.staffSubtitle), findsOneWidget);
        // One primary create action in the header.
        expect(find.text(l10n.create), findsOneWidget);
      },
    );
  }
}
