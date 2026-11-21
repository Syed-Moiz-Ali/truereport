import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_form_state.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_technician_step.dart';

import 'support/ui_strings_harness.dart';

/// The wizard's preferred-language choice comes from the backend manifest.
void main() {
  testWidgets('lists the backend languages and reports the chosen code', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          languageSelectionProvider(adminUiMessageClient)
              .overrideWith(_ManifestSelection.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: testLocalizationsDelegates,
          builder: (context, child) => uiStringsScope(
            child: Scaffold(
              body: SingleChildScrollView(
                child: WizardTechnicianStep(
                  selectedId: null,
                  onSelected: (_) {},
                  preferredLanguage: 'en',
                  onPreferredLanguage: (value) => chosen = value,
                  scheduledAt: null,
                  onPickSchedule: () {},
                  onStartImmediately: () {},
                  consentGranted: false,
                  onConsentChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('jobs-wizard-language-en')), findsOneWidget);
    expect(find.byKey(const Key('jobs-wizard-language-es')), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);

    await tester.tap(find.byKey(const Key('jobs-wizard-language-es')));
    await tester.pump();
    expect(chosen, 'es');
  });

  test('the request carries the chosen language code', () {
    final form = WizardFormState()..templateVersionId = 'tpl-v1';
    form.preferredLanguage = 'es';
    addTearDown(form.dispose);

    expect(form.toRequest().preferredLanguage, 'es');
  });
}

/// Serves a two-language manifest without touching the network.
class _ManifestSelection extends UiMessageController {
  _ManifestSelection() : super(adminUiMessageClient);

  @override
  UiMessageState build() => const UiMessageState(
    manifest: UiMessageManifest(
      defaultLanguage: 'en',
      namespaceVersions: <String, int>{'common': 1, 'workshop_admin': 1},
      languages: <UiMessageLanguage>[
        UiMessageLanguage(code: 'en', direction: 'ltr', nativeName: 'English'),
        UiMessageLanguage(code: 'es', direction: 'ltr', nativeName: 'Español'),
      ],
    ),
    activeLanguage: 'en',
    defaultLanguage: 'en',
    ready: true,
  );

  @override
  Future<void> bootstrap() async {}
}
