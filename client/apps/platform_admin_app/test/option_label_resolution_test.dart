import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:platform_admin_app/src/features/master_library/option_label.dart';
import 'package:platform_admin_app/src/features/master_library/option_sets_screen.dart';
import 'package:platform_admin_app/src/platform_config_models.dart';
import 'package:platform_admin_app/src/platform_providers.dart';
import 'package:reference_data/reference_data.dart';

import 'reference_test_support.dart';

/// Option-set values use the backend key first, the served label second.
void main() {
  group('OptionValue parsing', () {
    test('labelKey is optional and tolerated', () {
      final withKey = OptionValue.fromJson(<String, dynamic>{
        'id': 'v-1',
        'code': 'WORN',
        'label': 'Worn',
        'status': 'ACTIVE',
        'sortOrder': 0,
        'labelKey': 'option.issueType.worn',
      });
      expect(withKey.labelKey, 'option.issueType.worn');

      final withoutKey = OptionValue.fromJson(<String, dynamic>{
        'id': 'v-2',
        'code': 'LOOSE',
        'label': 'Loose',
        'status': 'ACTIVE',
        'sortOrder': 1,
      });
      expect(withoutKey.labelKey, isNull);
    });
  });

  group('optionValueLabel', () {
    test('prefers the bundle translation', () {
      final t = UiStrings.fromMessages(const <String, String>{
        'option.issueType.worn': 'Desgastado',
      });
      expect(
        optionValueLabel(
          t,
          _value('WORN', 'Worn', key: 'option.issueType.worn'),
        ),
        'Desgastado',
      );
    });

    test('falls back to labelEn when the key has no entry', () {
      final t = UiStrings.fromMessages(const <String, String>{});
      expect(
        optionValueLabel(
          t,
          _value('CRACKED', 'Cracked', key: 'option.issueType.cracked'),
        ),
        'Cracked',
      );
    });

    test('falls back to labelEn when labelKey is absent', () {
      final t = UiStrings.fromMessages(const <String, String>{});
      expect(optionValueLabel(t, _value('LOOSE', 'Loose')), 'Loose');
    });
  });

  testWidgets('option-set read pane renders translated and served values', (
    tester,
  ) async {
    final bundle = <String, String>{
      ...loadReferenceStrings().catalogs['en']!['common']!,
      'option.issueType.worn': 'Desgastado',
    }..remove('option.issueType.cracked');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uiStringsProvider.overrideWithValue(loadReferenceStrings()),
          statusesProvider('checklist')
              .overrideWith((ref) async => <ReferenceRecord>[]),
        ],
        child: MaterialApp(
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (context, child) => UiStringsScope(
            strings: UiStrings.fromMessages(bundle),
            child: Scaffold(
              body: SingleChildScrollView(child: child ?? const SizedBox()),
            ),
          ),
          home: OptionSetValuesPane(
            strings: loadReferenceStrings(),
            set: const OptionSet(
              id: 'set-1',
              code: 'ISSUE_TYPE',
              name: 'Issue type',
              status: 'ACTIVE',
              sortOrder: 0,
              values: [
                OptionValue(
                  id: 'v-1',
                  code: 'WORN',
                  label: 'Worn',
                  labelKey: 'option.issueType.worn',
                  status: 'ACTIVE',
                  sortOrder: 0,
                  metadataJson: '{}',
                ),
                OptionValue(
                  id: 'v-2',
                  code: 'CRACKED',
                  label: 'Cracked',
                  labelKey: 'option.issueType.cracked',
                  status: 'ACTIVE',
                  sortOrder: 1,
                  metadataJson: '{}',
                ),
                OptionValue(
                  id: 'v-3',
                  code: 'LOOSE',
                  label: 'Loose',
                  status: 'ACTIVE',
                  sortOrder: 2,
                  metadataJson: '{}',
                ),
              ],
            ),
            busy: false,
            onAdd: () {},
            onEdit: (_) {},
            onRetire: (_) {},
            onActivate: (_) {},
            onMove: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Desgastado'), findsOneWidget);
    expect(find.text('Cracked'), findsOneWidget);
    expect(find.text('Loose'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

OptionValue _value(String code, String label, {String? key}) => OptionValue(
  id: 'id-$code',
  code: code,
  label: label,
  labelKey: key,
  status: 'ACTIVE',
  sortOrder: 0,
  metadataJson: '{}',
);
