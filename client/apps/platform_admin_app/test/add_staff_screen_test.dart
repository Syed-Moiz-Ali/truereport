import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:platform_admin_app/src/features/hierarchy/add_staff_panel.dart';
import 'package:platform_admin_app/src/features/hierarchy/hierarchy_screen.dart';
import 'support/fake_platform_api.dart';

Widget _buildScreenApp({
  Locale locale = const Locale('en'),
  FakePlatformAdminApi? api,
}) {
  final fakeApi = api ?? FakePlatformAdminApi();
  return ProviderScope(
    overrides: [
      platformApiProvider.overrideWithValue(fakeApi),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: const HierarchyScreen(),
    ),
  );
}

void _setViewport(WidgetTester tester, {double width = 1280, double height = 1024}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('Screen 2: Add Staff button opens slide-out creation panel matching Figma spec', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    await tester.pumpWidget(_buildScreenApp());
    await tester.pumpAndSettle();

    // 1. Initial state: slide-out panel is not visible
    expect(find.byType(AddStaffSlideOutPanel), findsNothing);

    // 2. Click "Add Staff" button on the staff board
    final addStaffBtn = find.byKey(const Key('btn-add-staff'));
    expect(addStaffBtn, findsOneWidget);
    await tester.tap(addStaffBtn);
    await tester.pumpAndSettle();

    // 3. Panel is now open with exact Figma header and subtitle
    expect(find.byType(AddStaffSlideOutPanel), findsOneWidget);
    expect(find.text('Create Staff Account'), findsOneWidget);
    expect(find.text('Provision platform and workshop credentials'), findsOneWidget);

    // 4. Form inputs exist
    expect(find.byKey(const Key('input-staff-name')), findsOneWidget);
    expect(find.byKey(const Key('input-staff-email')), findsOneWidget);
    expect(find.byKey(const Key('input-staff-password')), findsOneWidget);
    expect(find.byKey(const Key('dropdown-staff-role')), findsOneWidget);
    expect(find.byKey(const Key('dropdown-staff-workshop')), findsOneWidget);
    expect(find.byKey(const Key('btn-create-staff-submit')), findsOneWidget);
    expect(find.byKey(const Key('btn-close-add-staff')), findsOneWidget);
    expect(find.byKey(const Key('btn-fill-staff-demo')), findsOneWidget);

    // 5. Verification notice is displayed
    expect(
      find.text('Credentials and activation token will be dispatched instantly via secure push.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 2: Quick-fill demo button populates Marcus Vance credentials', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    await tester.pumpWidget(_buildScreenApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-add-staff')));
    await tester.pumpAndSettle();

    // Tap Quick-fill
    await tester.tap(find.byKey(const Key('btn-fill-staff-demo')));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(find.byKey(const Key('input-staff-name')));
    final emailField = tester.widget<TextFormField>(find.byKey(const Key('input-staff-email')));
    final passField = tester.widget<TextFormField>(find.byKey(const Key('input-staff-password')));

    expect(nameField.controller?.text, 'Marcus Vance');
    expect(emailField.controller?.text, 'm.vance@coreos-grid.internal');
    expect(passField.controller?.text, 'Precision-Auth-2024');
  });

  testWidgets('Screen 2: Submitting valid staff form creates account and closes panel', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    final fakeApi = FakePlatformAdminApi();
    await tester.pumpWidget(_buildScreenApp(api: fakeApi));
    await tester.pumpAndSettle();

    // Open panel
    await tester.tap(find.byKey(const Key('btn-add-staff')));
    await tester.pumpAndSettle();

    // Fill demo credentials
    await tester.tap(find.byKey(const Key('btn-fill-staff-demo')));
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.byKey(const Key('btn-create-staff-submit')));
    await tester.pumpAndSettle();

    // Panel should now be closed
    expect(find.byType(AddStaffSlideOutPanel), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 2: Close button dismisses slide-out panel', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    await tester.pumpWidget(_buildScreenApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-add-staff')));
    await tester.pumpAndSettle();
    expect(find.byType(AddStaffSlideOutPanel), findsOneWidget);

    // Tap Close Button
    await tester.tap(find.byKey(const Key('btn-close-add-staff')));
    await tester.pumpAndSettle();

    expect(find.byType(AddStaffSlideOutPanel), findsNothing);
  });

  testWidgets('Screen 2: Backdrop tap dismisses slide-out panel', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    await tester.pumpWidget(_buildScreenApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-add-staff')));
    await tester.pumpAndSettle();
    expect(find.byType(AddStaffSlideOutPanel), findsOneWidget);

    // Tap outside backdrop
    await tester.tap(find.byKey(const Key('add-staff-backdrop')));
    await tester.pumpAndSettle();

    expect(find.byType(AddStaffSlideOutPanel), findsNothing);
  });

  testWidgets('Screen 2: Slide-out panel renders in RTL Arabic without overflow', (tester) async {
    _setViewport(tester, width: 1280, height: 1024);
    await tester.pumpWidget(_buildScreenApp(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn-add-staff')));
    await tester.pumpAndSettle();

    expect(find.byType(AddStaffSlideOutPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Screen 2: Slide-out panel renders responsive on compact mobile without overflow', (tester) async {
    _setViewport(tester, width: 400, height: 840);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AddStaffSlideOutPanel(
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddStaffSlideOutPanel), findsOneWidget);
    expect(find.byKey(const Key('btn-create-staff-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
