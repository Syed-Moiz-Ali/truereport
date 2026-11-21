import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/ui_strings.dart';
import 'package:reference_data/reference_data.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/jobs/dispatch/dispatch_create.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_form_state.dart';
import 'package:workshop_admin_app/src/features/jobs/wizard/wizard_technician_step.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/workshop_job_models.dart';

import 'support/fake_admin_api.dart';
import 'support/ui_strings_harness.dart';

List<WorkshopLanguage> _registry() => const <WorkshopLanguage>[
  WorkshopLanguage(
    code: 'en',
    nativeName: 'English',
    direction: 'ltr',
    status: 'LIVE',
    active: true,
  ),
  WorkshopLanguage(
    code: 'es',
    nativeName: 'Español',
    direction: 'ltr',
    status: 'LIVE',
    active: true,
  ),
  WorkshopLanguage(
    code: 'de',
    nativeName: 'Deutsch',
    direction: 'ltr',
    status: 'LIVE',
    active: true,
  ),
];

class _CapturingApi extends FakeAdminApi {
  NewCleanJob? created;

  @override
  Future<CleanJob> createCleanJob(NewCleanJob job) async {
    created = job;
    return super.createCleanJob(job);
  }
}

Widget _app({required Widget home, required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.light,
      supportedLocales: const <Locale>[Locale('en')],
      localizationsDelegates: testLocalizationsDelegates,
      builder: (context, child) =>
          uiStringsScope(child: child ?? const SizedBox.shrink()),
      home: home,
    ),
  );
}

void main() {
  testWidgets('lists registry languages including one without a catalog', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      _app(
        overrides: [
          adminApiProvider.overrideWithValue(FakeAdminApi()),
          languageSelectionProvider(adminUiMessageClient)
              .overrideWith(_ManifestSelection.new),
          workshopLanguagesProvider.overrideWith((ref) async => _registry()),
        ],
        home: Scaffold(
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
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('jobs-wizard-language-en')), findsOneWidget);
    expect(find.byKey(const Key('jobs-wizard-language-es')), findsOneWidget);
    expect(find.byKey(const Key('jobs-wizard-language-de')), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);

    await tester.tap(find.byKey(const Key('jobs-wizard-language-de')));
    await tester.pump();
    expect(chosen, 'de');
  });

  testWidgets('registry failure falls back to the manifest without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        overrides: [
          adminApiProvider.overrideWithValue(FakeAdminApi()),
          languageSelectionProvider(adminUiMessageClient)
              .overrideWith(_ManifestSelection.new),
          workshopLanguagesProvider.overrideWith(
            (ref) => Future<List<WorkshopLanguage>>.error(
              StateError('registry offline'),
            ),
          ),
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: WizardTechnicianStep(
              selectedId: null,
              onSelected: (_) {},
              preferredLanguage: 'en',
              onPreferredLanguage: (_) {},
              scheduledAt: null,
              onPickSchedule: () {},
              onStartImmediately: () {},
              consentGranted: false,
              onConsentChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('jobs-wizard-language-en')), findsOneWidget);
    expect(find.byKey(const Key('jobs-wizard-language-es')), findsOneWidget);
    expect(find.byKey(const Key('jobs-wizard-language-de')), findsNothing);
  });

  testWidgets('completing the wizard posts the registry language', (
    tester,
  ) async {
    final api = _CapturingApi();
    await tester.pumpWidget(
      _app(
        overrides: [
          adminApiProvider.overrideWithValue(api),
          languageSelectionProvider(adminUiMessageClient)
              .overrideWith(_ManifestSelection.new),
          workshopLanguagesProvider.overrideWith((ref) async => _registry()),
          statusesProvider('consent')
              .overrideWith((ref) async => const <ReferenceRecord>[]),
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DispatchCreateJob(),
                  ),
                ),
                child: const Text('open wizard'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open wizard'));
    await tester.pumpAndSettle();
    final t = UiStrings.of(tester.element(find.byType(DispatchCreateJob)));

    await tester.enterText(
      find.byKey(const Key('jobs-wizard-customer-name')),
      'Wizard Customer',
    );
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-customer-phone')),
      '+971500000000',
    );
    await tester.tap(find.text(t(WorkshopAdminKeys.commonNext)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('jobs-wizard-vehicle-make')),
      'Toyota',
    );
    await tester.enterText(
      find.byKey(const Key('jobs-wizard-vehicle-model')),
      'Camry',
    );
    await tester.tap(find.text(t(WorkshopAdminKeys.commonNext)));
    await tester.pumpAndSettle();

    final template = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('jobs-template-');
    });
    expect(template, findsOneWidget);
    await tester.ensureVisible(template);
    await tester.pumpAndSettle();
    await tester.tap(template);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t(WorkshopAdminKeys.commonNext)));
    await tester.pumpAndSettle();

    final deutsch = find.byKey(const Key('jobs-wizard-language-de'));
    expect(deutsch, findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    await tester.ensureVisible(deutsch);
    await tester.pumpAndSettle();
    await tester.tap(deutsch);
    await tester.pump();

    await tester.tap(find.text(t(WorkshopAdminKeys.create)));
    await tester.pumpAndSettle();

    expect(api.created?.preferredLanguage, 'de');
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
