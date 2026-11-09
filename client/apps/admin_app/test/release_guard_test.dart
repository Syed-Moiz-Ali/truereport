import 'package:admin_app/src/admin_providers.dart';
import 'package:admin_app/src/pages/workshop_admin_home.dart';
import 'package:admin_app/src/screens/f3a/dashboard_view.dart';
import 'package:admin_app/src/screens/f3a/queue_view.dart';
import 'package:admin_app/src/screens/f3b/staff_view.dart';
import 'package:admin_app/src/screens/f3b/template_list_view.dart';
import 'support/fake_admin_api.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

/// Step 2a release guard proof.
///
/// The F3 showcase views still carry Figma sample copy
/// (people/vehicles/bays/telemetry) and unwired actions. They must not be
/// reachable in a release build: `adminShowcaseProvider` is false there
/// unless `--dart-define=ADMIN_FIGMA_SHOWCASE=true` is passed (fidelity
/// captures). These tests force the gate off (release default) and on,
/// pump the real route table (`WorkshopAdminHomePage` + all four tabs),
/// and assert the guarded screens are absent/present respectively.
class _Harness extends ConsumerStatefulWidget {
  const _Harness({required this.home, required this.locale});

  final Widget home;
  final Locale locale;

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
      home: widget.home,
    );
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required bool showcase,
}) async {
  final container = ProviderContainer(
    overrides: [
      adminApiProvider.overrideWithValue(FakeAdminApi()),
      adminShowcaseProvider.overrideWithValue(showcase),
    ],
  );
  addTearDown(container.dispose);
  // Narrow width renders the AppBar TabBar (tab keys exist only there;
  // the 1280px rail navigates via DefaultTabController instead).
  tester.view.physicalSize = const Size(500, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const _Harness(
        home: WorkshopAdminHomePage(),
        locale: Locale('en'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _visitAllTabs(WidgetTester tester) async {
  for (final key in [
    'workshop-tab-overview',
    'workshop-tab-jobs',
    'workshop-tab-staff',
    'workshop-tab-templates',
  ]) {
    await tester.ensureVisible(find.byKey(Key(key)).first);
    await tester.tap(find.byKey(Key(key)).first);
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('release default hides every showcase screen', (tester) async {
    await _pumpHome(tester, showcase: false);
    await _visitAllTabs(tester);

    // None of the sample-data showcase views is in the route table.
    expect(find.byType(WorkshopDashboardView), findsNothing);
    expect(find.byType(WorkshopQueueView), findsNothing);
    expect(find.byType(WorkshopStaffView), findsNothing);
    expect(find.byType(WorkshopTemplateListView), findsNothing);

    // No Figma sample text leaks into the release tree.
    for (final marker in [
      'Porsche Taycan',
      'Ford Transit Custom',
      'David Vance',
      'Floor Telemetry',
      '100-Point',
      'EV Certified',
      'BAY 04',
    ]) {
      expect(find.textContaining(marker), findsNothing, reason: marker);
    }

    // Each guarded tab shows a neutral localized empty state instead.
    expect(find.byType(EmptyState), findsWidgets);
    expect(find.text('No results'), findsWidgets);
  });

  testWidgets('showcase override restores the capture views', (tester) async {
    await _pumpHome(tester, showcase: true);

    // Jobs tab renders the showcase queue view (capture path intact).
    await tester.ensureVisible(find.byKey(const Key('workshop-tab-jobs')));
    await tester.tap(find.byKey(const Key('workshop-tab-jobs')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkshopQueueView), findsOneWidget);

    // Staff tab renders the showcase staff view.
    await tester.ensureVisible(find.byKey(const Key('workshop-tab-staff')));
    await tester.tap(find.byKey(const Key('workshop-tab-staff')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkshopStaffView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
