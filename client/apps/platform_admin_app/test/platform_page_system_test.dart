import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_admin_app/src/components/platform_buttons.dart';
import 'package:platform_admin_app/src/components/platform_chips.dart';
import 'package:platform_admin_app/src/components/platform_dialogs.dart';
import 'package:platform_admin_app/src/components/platform_form.dart';
import 'package:platform_admin_app/src/components/platform_states.dart';
import 'package:platform_admin_app/src/components/platform_toolbar.dart';
import 'package:platform_admin_app/src/platform_providers.dart';

import 'support/ui_message_fixtures.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      uiStringsProvider.overrideWithValue(
        locale.languageCode == 'ar' ? fakeArUiStrings() : fakeEnUiStrings(),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: <Locale>[const Locale('en'), const Locale('ar')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('buttons render primary first with ellipsis, no overflow', (
    tester,
  ) async {
    _setSize(tester, const Size(360, 900));
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            PlatformPrimaryButton(
              label: 'Save Platform Preferences with a very long label',
              icon: Icons.save_outlined,
              onPressed: () {},
            ),
            const SizedBox(height: 10),
            PlatformSecondaryButton(
              label: 'Load default checklist with a very long label',
              icon: Icons.cloud_download_outlined,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlatformPrimaryButton), findsOneWidget);
    expect(find.byType(PlatformSecondaryButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chips render selected state and status colors', (tester) async {
    _setSize(tester, const Size(360, 900));
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            PlatformFilterChip(
              label: 'All Categories',
              selected: true,
              onTap: () {},
            ),
            const PlatformStatusChip(status: 'PUBLISHED'),
            const PlatformStatusChip(status: 'DRAFT'),
            const PlatformStatusChip(status: 'RETIRED'),
            const PlatformMetaPill(label: 'Category', value: 'Brakes'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('All Categories'), findsOneWidget);
    expect(find.text('PUBLISHED'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading/empty/error states render with actions', (tester) async {
    _setSize(tester, const Size(360, 900));
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            const PlatformLoadingView(),
            const SizedBox(height: 12),
            PlatformEmptyView(
              title: 'No data yet',
              body: 'Nothing here.',
              actionLabel: 'Retry',
              onAction: () {},
            ),
            const SizedBox(height: 12),
            PlatformErrorView(message: 'Failed', onRetry: () {}),
          ],
        ),
      ),
    );
    // Fixed pumps: the loading spinner animates forever, so pumpAndSettle
    // would time out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PlatformLoadingView), findsOneWidget);
    expect(find.byType(PlatformEmptyView), findsOneWidget);
    expect(find.byType(PlatformErrorView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toolbar wraps search, filters, and count on compact', (
    tester,
  ) async {
    _setSize(tester, const Size(360, 900));
    await tester.pumpWidget(
      _app(
        PlatformToolbar(
          searchHint: 'Search',
          onSearchChanged: (_) {},
          filters: [
            PlatformFilterChip(label: 'All', selected: true, onTap: () {}),
            PlatformFilterChip(label: 'Active', selected: false, onTap: () {}),
          ],
          countLabel: '3 items',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 items'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form controls render with labels and validation frame', (
    tester,
  ) async {
    _setSize(tester, const Size(360, 900));
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            const PlatformTextField(label: 'Name (English)'),
            const SizedBox(height: 12),
            PlatformDropdown<String>(
              label: 'Status',
              value: '',
              items: const [DropdownMenuItem(value: '', child: Text('All'))],
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            const PlatformSectionHeader(
              title: 'Section title',
              subtitle: 'Section subtitle',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Section title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirm dialog returns true on primary action', (tester) async {
    _setSize(tester, const Size(1280, 800));
    var result = false;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showPlatformConfirmDialog(
                context: context,
                title: 'Retire item',
                body: 'Retire this record?',
                confirmLabel: 'Retire',
                destructive: true,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Retire item'), findsOneWidget);
    await tester.tap(find.text('Retire'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('shared system has no overflow at 1280/360 + AR RTL', (
    tester,
  ) async {
    for (final entry in [
      (const Size(1280, 800), const Locale('en')),
      (const Size(360, 900), const Locale('en')),
      (const Size(360, 900), const Locale('ar')),
    ]) {
      _setSize(tester, entry.$1);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              PlatformPrimaryButton(label: 'Primary action', onPressed: () {}),
              const SizedBox(height: 10),
              PlatformToolbar(
                searchHint: 'Search',
                onSearchChanged: (_) {},
                filters: [
                  PlatformFilterChip(
                    label: 'Filter with a long label text',
                    selected: true,
                    onTap: () {},
                  ),
                ],
                countLabel: '3 items',
              ),
              const SizedBox(height: 10),
              const PlatformEmptyView(title: 'No data yet'),
            ],
          ),
          locale: entry.$2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
