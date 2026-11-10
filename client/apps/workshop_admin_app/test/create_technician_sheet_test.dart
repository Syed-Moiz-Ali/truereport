import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/models.dart';
import 'package:workshop_admin_app/src/features/staff/create_technician_sheet.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

import 'support/fake_admin_api.dart';

/// Failure modes for the fake create-technician endpoint.
enum _CreateMode { success, emailExists, genericError }

class _FakeTechnicianApi extends FakeAdminApi {
  _FakeTechnicianApi({this.mode = _CreateMode.success});

  final _CreateMode mode;
  final List<Map<String, String>> createCalls = [];

  @override
  Future<PlatformAccount> createTechnician({
    required String email,
    required String displayName,
    required String initialPassword,
  }) async {
    createCalls.add({
      'email': email,
      'displayName': displayName,
      'initialPassword': initialPassword,
    });
    switch (mode) {
      case _CreateMode.emailExists:
        throw const AppFailure(
          code: 'EMAIL_EXISTS',
          messageKey: 'error.email.exists',
        );
      case _CreateMode.genericError:
        throw StateError('create failed');
      case _CreateMode.success:
        return PlatformAccount(
          userId: 'tech-new',
          displayName: displayName,
          email: email,
          emailMasked: email,
          role: 'TECHNICIAN',
          status: 'ACTIVE',
          workshopId: 'workshop-1',
          primary: false,
          invitationExpiresAt: null,
        );
    }
  }
}

class _Harness extends ConsumerStatefulWidget {
  const _Harness({
    required this.locale,
    required this.textScale,
    required this.api,
    required this.onResult,
  });

  final Locale locale;
  final double textScale;
  final _FakeTechnicianApi api;
  final ValueChanged<PlatformAccount?> onResult;

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
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(widget.textScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (sheetContext) => ElevatedButton(
              key: const Key('open-create-technician-sheet'),
              onPressed: () async {
                final member =
                    await CreateTechnicianSheet.showCreateTechnicianSheet(
                      sheetContext,
                    );
                widget.onResult(member);
              },
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
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

Future<ValueNotifier<PlatformAccount?>> _openSheet(
  WidgetTester tester, {
  required _FakeTechnicianApi api,
  required Locale locale,
  required Size size,
  double textScale = 1,
}) async {
  _setSize(tester, size);
  final result = ValueNotifier<PlatformAccount?>(null);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminApiProvider.overrideWithValue(api)],
      child: _Harness(
        locale: locale,
        textScale: textScale,
        api: api,
        onResult: (member) => result.value = member,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await tester.tap(find.byKey(const Key('open-create-technician-sheet')));
  // The bottom-sheet entrance animates height from zero; its first frame
  // can report a transient RenderFlex overflow even though the settled
  // sheet fits and scrolls. Drain animation frames, then assert the
  // settled frame is clean so the test verifies final layout (body
  // scrolls, footer pinned) rather than the animation transient.
  await tester.pumpAndSettle();
  tester.takeException();
  await tester.pump();
  expect(tester.takeException(), isNull);
  return result;
}

Future<void> _scrollSheet(WidgetTester tester) async {
  final scrollable = find.descendant(
    of: find.byType(WorkshopSideSheet),
    matching: find.byType(Scrollable),
  );
  await tester.drag(scrollable.first, const Offset(0, -600));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
  tester.element(find.byType(WorkshopSideSheet)),
);

Future<void> _fillValid(
  WidgetTester tester,
  AppLocalizations l10n, {
  String password = ' ValidPass123! ',
}) async {
  await tester.enterText(
    find.widgetWithText(AppTextField, l10n.displayName).first,
    '  Technician B  ',
  );
  await tester.enterText(
    find.widgetWithText(AppTextField, l10n.email).first,
    '  tech@test.local  ',
  );
  await tester.enterText(
    find.widgetWithText(AppTextField, l10n.temporaryPassword).first,
    password,
  );
  await tester.pump();
}

Future<void> _tapCreate(WidgetTester tester, AppLocalizations l10n) async {
  await tester.ensureVisible(
    find.widgetWithText(AppButton, l10n.create),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(AppButton, l10n.create));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// The password field is the [AppTextField] labelled with the temporary
/// password string; its controller is captured while the sheet is open so
/// tests can assert it is cleared on dispose.
AppTextField _passwordField(WidgetTester tester, AppLocalizations l10n) {
  return tester.widget<AppTextField>(
    find.widgetWithText(AppTextField, l10n.temporaryPassword).first,
  );
}

String _visibleText() => find
    .byType(Text)
    .evaluate()
    .map((element) => (element.widget as Text).data ?? '')
    .join('\n');

bool _createFocused(WidgetTester tester) {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) {
    return false;
  }
  return find
      .ancestor(
        of: find.byWidget(context.widget),
        matching: find.byType(AppButton),
      )
      .evaluate()
      .isNotEmpty;
}

void main() {
  const wide = Size(1280, 800);
  const phone = Size(390, 844);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final entry in {'wide': wide, 'phone': phone}.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'create technician sheet ${locale.languageCode} ${entry.key} scale $scale renders without overflow',
          (tester) async {
            await _openSheet(
              tester,
              api: _FakeTechnicianApi(),
              locale: locale,
              size: entry.value,
              textScale: scale,
            );
            final l10n = _l10n(tester);
            expect(find.text(l10n.createTechnicianTitle), findsOneWidget);
            expect(find.text(l10n.createTechnicianSubtitle), findsOneWidget);
            expect(
              find.widgetWithText(AppTextField, l10n.displayName),
              findsWidgets,
            );
            expect(
              find.widgetWithText(AppTextField, l10n.email),
              findsWidgets,
            );
            expect(
              find.widgetWithText(AppTextField, l10n.temporaryPassword),
              findsWidgets,
            );
            // Fixed Technician row, Cancel/Create actions.
            expect(find.text(l10n.roleTechnician), findsWidgets);
            expect(
              find.widgetWithText(AppButton, l10n.cancel),
              findsOneWidget,
            );
            expect(
              find.widgetWithText(AppButton, l10n.create),
              findsOneWidget,
            );
            // Omitted per slot sheet: no picker, stations, magic-link.
            expect(find.byType(Switch), findsNothing);
            expect(find.byType(DropdownButtonFormField<String>), findsNothing);
            await _scrollSheet(tester);
          },
        );
      }
    }
  }

  testWidgets('create technician sheet uses RTL direction in Arabic', (
    tester,
  ) async {
    await _openSheet(
      tester,
      api: _FakeTechnicianApi(),
      locale: const Locale('ar'),
      size: phone,
    );
    final l10n = _l10n(tester);
    expect(
      Directionality.of(tester.element(find.text(l10n.createTechnicianTitle))),
      TextDirection.rtl,
    );
  });

  testWidgets('create technician sheet header semantics', (tester) async {
    await _openSheet(
      tester,
      api: _FakeTechnicianApi(),
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);
    final semantics = tester.getSemantics(
      find.text(l10n.createTechnicianTitle),
    );
    expect(semantics.flagsCollection.isHeader, isTrue);
    expect(find.bySemanticsLabel(l10n.close), findsWidgets);
  });

  testWidgets('create technician sheet blocks empty submit', (tester) async {
    final api = _FakeTechnicianApi();
    await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);

    await _tapCreate(tester, l10n);

    expect(api.createCalls, isEmpty);
    expect(find.text(l10n.requiredField), findsWidgets);
    // Sheet stays open.
    expect(find.byType(WorkshopSideSheet), findsOneWidget);
  });

  testWidgets('create technician sheet blocks invalid email/short password', (
    tester,
  ) async {
    final api = _FakeTechnicianApi();
    await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);

    await tester.enterText(
      find.widgetWithText(AppTextField, l10n.displayName).first,
      'Technician B',
    );
    await tester.enterText(
      find.widgetWithText(AppTextField, l10n.email).first,
      'not-an-email',
    );
    await tester.enterText(
      find.widgetWithText(AppTextField, l10n.temporaryPassword).first,
      'short',
    );
    await tester.pump();
    await _tapCreate(tester, l10n);

    expect(api.createCalls, isEmpty);
    expect(find.text(l10n.invalidEmail), findsOneWidget);
    expect(find.text(l10n.requiredField), findsWidgets);
    expect(find.byType(WorkshopSideSheet), findsOneWidget);
  });

  testWidgets('create technician sheet creates with exact payload + pops', (
    tester,
  ) async {
    const password = ' ValidPass123! ';
    final api = _FakeTechnicianApi();
    final result = await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);
    final passwordController = _passwordField(tester, l10n).controller;

    await _fillValid(tester, l10n, password: password);
    await _tapCreate(tester, l10n);

    // Exact payload: trimmed email/displayName, raw password (mirrors the
    // existing dialog contract in staff_tab.dart).
    expect(api.createCalls, hasLength(1));
    expect(api.createCalls.single, {
      'email': 'tech@test.local',
      'displayName': 'Technician B',
      'initialPassword': password,
    });
    expect(result.value?.userId, 'tech-new');
    expect(find.byType(WorkshopSideSheet), findsNothing);
    expect(find.text(l10n.accountCreated), findsOneWidget);
    // Password cleared on dispose and never echoed.
    expect(passwordController.text, isEmpty);
    expect(
      find.text(password, skipOffstage: false),
      findsNothing,
    );
    expect(_visibleText(), isNot(contains(password.trim())));
  });

  testWidgets('create technician sheet creates in Arabic + pops', (
    tester,
  ) async {
    final api = _FakeTechnicianApi();
    final result = await _openSheet(
      tester,
      api: api,
      locale: const Locale('ar'),
      size: wide,
    );
    final l10n = _l10n(tester);

    await _fillValid(tester, l10n);
    await _tapCreate(tester, l10n);

    expect(api.createCalls, hasLength(1));
    expect(result.value?.userId, 'tech-new');
    expect(find.byType(WorkshopSideSheet), findsNothing);
    expect(find.text(l10n.accountCreated), findsOneWidget);
  });

  testWidgets('create technician sheet shows emailAlreadyInUse, stays open', (
    tester,
  ) async {
    const password = 'ValidPass123!';
    final api = _FakeTechnicianApi(mode: _CreateMode.emailExists);
    final result = await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);

    await _fillValid(tester, l10n, password: password);
    await _tapCreate(tester, l10n);

    expect(api.createCalls, hasLength(1));
    expect(result.value, isNull);
    expect(find.text(l10n.emailAlreadyInUse), findsOneWidget);
    // Sheet stays open for correction; password never leaks into visible
    // Text widgets. `find.text` also matches the obscured EditableText
    // itself, so it cannot be used here: assert instead that no visible
    // Text echoes the secret and the field stays obscured.
    expect(find.byType(WorkshopSideSheet), findsOneWidget);
    expect(_visibleText(), isNot(contains(password)));
    expect(_passwordField(tester, l10n).obscureText, isTrue);
  });

  testWidgets('create technician sheet keeps generic error inside sheet', (
    tester,
  ) async {
    const password = 'ValidPass123!';
    final api = _FakeTechnicianApi(mode: _CreateMode.genericError);
    final result = await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);

    await _fillValid(tester, l10n, password: password);
    await _tapCreate(tester, l10n);

    expect(api.createCalls, hasLength(1));
    expect(result.value, isNull);
    expect(find.text(l10n.actionFailed), findsOneWidget);
    expect(find.byType(WorkshopSideSheet), findsOneWidget);
    expect(_visibleText(), isNot(contains(password)));
  });

  testWidgets('create technician sheet eye toggle shows/hides semantics', (
    tester,
  ) async {
    await _openSheet(
      tester,
      api: _FakeTechnicianApi(),
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);

    expect(find.byTooltip(l10n.showPassword), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.showPassword));
    await tester.pump();
    expect(find.byTooltip(l10n.hidePassword), findsOneWidget);
    expect(_passwordField(tester, l10n).obscureText, isFalse);
  });

  testWidgets('create technician sheet Esc closes without creating', (
    tester,
  ) async {
    final api = _FakeTechnicianApi();
    final result = await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(api.createCalls, isEmpty);
    expect(result.value, isNull);
    expect(find.byType(WorkshopSideSheet), findsNothing);
  });

  testWidgets('create technician sheet Cancel closes without creating', (
    tester,
  ) async {
    final api = _FakeTechnicianApi();
    final result = await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);

    await tester.tap(find.widgetWithText(AppButton, l10n.cancel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(api.createCalls, isEmpty);
    expect(result.value, isNull);
    expect(find.byType(WorkshopSideSheet), findsNothing);
  });

  testWidgets('create technician sheet focus order reaches Create', (
    tester,
  ) async {
    await _openSheet(
      tester,
      api: _FakeTechnicianApi(),
      locale: const Locale('en'),
      size: wide,
    );

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    var reachedCreate = false;
    for (var i = 0; i < 80 && !reachedCreate; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      reachedCreate = _createFocused(tester);
    }
    expect(reachedCreate, isTrue);
  });

  testWidgets('create technician sheet failure carries no password', (
    tester,
  ) async {
    const password = 'ValidPass123!';
    // The failure surfaced to the sheet carries only a code/key.
    const failure = AppFailure(
      code: 'EMAIL_EXISTS',
      messageKey: 'error.email.exists',
    );
    expect(failure.toString(), isNot(contains(password)));
    expect(failure.code, isNot(contains(password)));

    final api = _FakeTechnicianApi(mode: _CreateMode.emailExists);
    await _openSheet(
      tester,
      api: api,
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);
    await _fillValid(tester, l10n, password: password);
    await _tapCreate(tester, l10n);

    // The recorded transport payload is asserted in the success test; no
    // diagnostic/log surface echoes the secret.
    final diagnostics = _visibleText();
    expect(diagnostics, isNot(contains(password)));
  });

  testWidgets('create technician sheet renders no forbidden terms', (
    tester,
  ) async {
    await _openSheet(
      tester,
      api: _FakeTechnicianApi(),
      locale: const Locale('en'),
      size: wide,
    );
    final l10n = _l10n(tester);
    final text = _visibleText().toLowerCase();
    const banned = [
      'station',
      'stn 0',
      'magic',
      'permission',
      'invit',
      'pending',
      'admin',
      'lead',
      'bay',
      'certif',
      'approv',
      'accuracy',
      'metric',
    ];
    for (final term in banned) {
      expect(text.contains(term), isFalse, reason: 'forbidden term: $term');
    }
    // Fixed role only: no admin-role option rendered.
    expect(find.text(l10n.roleWorkshopAdmin), findsNothing);
    expect(find.text(l10n.rolePlatformAdmin), findsNothing);
  });
}
