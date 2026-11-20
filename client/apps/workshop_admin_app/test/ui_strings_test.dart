import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';

import 'support/ui_strings_harness.dart';

void main() {
  group('UiStrings', () {
    test('resolves workshop keys from the served English bundle', () {
      final t = baseStrings();

      expect(t(WorkshopAdminKeys.jobsTab), 'Jobs');
      expect(t(WorkshopAdminKeys.appTitleAdmin), 'TrueReport Admin');
    });

    test('formats dashboard counts with the catalog placeholders', () {
      final t = baseStrings();

      expect(
        t(WorkshopAdminKeys.dashGroupCountPending, {'count': 4}),
        '4 pending review',
      );
      expect(t(WorkshopAdminKeys.dashFooterSum, {'total': 24}), contains('24'));
    });

    testWidgets('scope serves the bundle to the pumped tree', (tester) async {
      late UiStrings resolved;
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: testLocalizationsDelegates,
          builder: (context, child) =>
              uiStringsScope(child: child ?? const SizedBox.shrink()),
          home: Builder(
            builder: (context) {
              resolved = UiStrings.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved(WorkshopAdminKeys.jobsTab), 'Jobs');
    });
  });
}
