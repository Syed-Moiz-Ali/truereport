import 'package:api_client/api_client.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_admin_app/src/shared/translation_issue_dialog.dart';

import 'support/ui_strings_harness.dart';

/// A publish 409 must list the backend issues, never "action failed".
void main() {
  testWidgets('lists entity, field, language and reason', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: testLocalizationsDelegates,
        builder: (context, child) =>
            uiStringsScope(child: child ?? const SizedBox.shrink()),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open-issues'),
                onPressed: () => showTranslationIssuesDialog(context, _failure),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-issues')));
    await tester.pumpAndSettle();

    expect(find.textContaining('ITEM · item-1 · labelEn · es'), findsOneWidget);
    expect(find.text('Machine translation needs review'), findsOneWidget);
    expect(find.text('Translation review required'), findsOneWidget);

    await tester.tap(find.byKey(const Key('translation-issues-close')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ITEM · item-1'), findsNothing);
  });
}

const ApiFailure _failure = ApiFailure(
  code: 'TRANSLATION_REVIEW_REQUIRED',
  messageKey: 'error.translation.reviewRequired',
  statusCode: 409,
  errors: <Map<String, dynamic>>[
    <String, dynamic>{
      'entityType': 'ITEM',
      'entityId': 'item-1',
      'field': 'labelEn',
      'lang': 'es',
      'reason': 'Machine translation needs review',
    },
  ],
);
