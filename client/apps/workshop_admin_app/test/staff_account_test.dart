import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/admin_providers.dart';
import 'package:workshop_admin_app/src/features/staff/staff_create_page.dart';
import 'package:workshop_admin_app/src/features/staff/staff_member_page.dart';
import 'package:workshop_admin_app/src/features/templates/template_pills.dart';
import 'package:workshop_admin_app/src/models.dart';

import 'support/fake_admin_api.dart';

/// Member record and create page — the write paths the staff module owns:
/// `resetTechnicianPassword`, `disableUser`, `reactivateUser`,
/// `createTechnician` with `EMAIL_EXISTS`, and the field hints.
const _active = StaffMember(
  userId: 'tech-1',
  displayName: 'Mariam Abdulrahman Al Suwaidi',
  emailMasked: 'm***@test.local',
  role: 'TECHNICIAN',
  status: 'ACTIVE',
);
const _disabled = StaffMember(
  userId: 'tech-2',
  displayName: 'Khalid Ibrahim Al Hashimi',
  emailMasked: 'k***@test.local',
  role: 'TECHNICIAN',
  status: 'DISABLED',
);

PlatformAccount _account(String userId, {String status = 'ACTIVE'}) =>
    PlatformAccount(
      userId: userId,
      displayName: 'Mariam Abdulrahman Al Suwaidi',
      email: 'm@test.local',
      emailMasked: 'm***@test.local',
      role: 'TECHNICIAN',
      status: status,
      workshopId: 'workshop-1',
      primary: false,
      invitationExpiresAt: null,
    );

class _AccountApi extends FakeAdminApi {
  _AccountApi({required this.members, this.emailExists = false});

  final List<StaffMember> members;
  final bool emailExists;

  final disabled = <(String, String)>[];
  final reactivated = <(String, String)>[];
  final resetPasswords = <(String, String)>[];

  @override
  Future<List<StaffMember>> staff() async => members;

  @override
  Future<PlatformAccount> disableUser(String userId, String reason) async {
    disabled.add((userId, reason));
    return _account(userId, status: 'DISABLED');
  }

  @override
  Future<PlatformAccount> reactivateUser(String userId, String reason) async {
    reactivated.add((userId, reason));
    return _account(userId);
  }

  @override
  Future<PlatformAccount> resetTechnicianPassword(
    String userId,
    String newPassword,
  ) async {
    resetPasswords.add((userId, newPassword));
    return _account(userId);
  }

  @override
  Future<PlatformAccount> createTechnician({
    required String email,
    required String displayName,
    required String initialPassword,
  }) async {
    if (emailExists) {
      throw const AppFailure(
        code: 'EMAIL_EXISTS',
        messageKey: 'emailAlreadyInUse',
      );
    }
    return super.createTechnician(
      email: email,
      displayName: displayName,
      initialPassword: initialPassword,
    );
  }
}

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

Future<_AccountApi> _pump(
  WidgetTester tester, {
  required Widget home,
  required Locale locale,
  Size size = const Size(1440, 900),
  double textScale = 1,
  _AccountApi? api,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final effective = api ?? _AccountApi(members: const [_active, _disabled]);
  final container = ProviderContainer(
    overrides: [adminApiProvider.overrideWithValue(effective)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _Harness(home: home, locale: locale, textScale: textScale),
    ),
  );
  container.read(localeProvider.notifier).setLocale(locale);
  await tester.pumpAndSettle();
  return effective;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(StaffMemberPage)));

Finder _pill(String label) => find.byWidgetPredicate(
  (widget) => widget is TemplatePillButton && widget.label == label,
);

TemplatePillButton _pillWidget(WidgetTester tester, String label) =>
    tester.widget<TemplatePillButton>(_pill(label));

String? _hint(WidgetTester tester, Key key) {
  final field = tester.widget<TextField>(
    find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
  );
  return field.decoration?.hintText;
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'member record renders status, credentials and details in pills (${locale.languageCode})',
      (tester) async {
        await _pump(
          tester,
          home: const StaffMemberPage(memberId: 'tech-1'),
          locale: locale,
        );
        expect(tester.takeException(), isNull);
        final l10n = _l10n(tester);

        // The bar carries the member's name and state; the identity block
        // repeats the name as the page headline, and Details lists it as a fact.
        expect(find.text(l10n.workshopStaffTitle), findsNothing);
        expect(find.text('Mariam Abdulrahman Al Suwaidi'), findsNWidgets(3));
        expect(find.text('m***@test.local'), findsOneWidget);
        expect(find.text(l10n.status.toUpperCase()), findsWidgets);
        // The state strip shows all three real account states.
        expect(find.text(l10n.pending), findsOneWidget);
        expect(find.text(l10n.disabled), findsOneWidget);
        // Section headings use the jobs detail pattern, not numbered heads.
        expect(find.text(l10n.details), findsOneWidget);
        expect(find.text(l10n.passwordLabel), findsOneWidget);

        // Actions are the shared pills; no square workshop buttons remain.
        expect(find.byType(TemplatePillButton), findsWidgets);
        expect(find.byType(WorkshopButton), findsNothing);
        expect(_pill(l10n.save), findsOneWidget);
        expect(_pill(l10n.deactivate), findsOneWidget);

        // Both credential fields carry hints as well as labels.
        expect(
          _hint(tester, const Key('staff-reset-password')),
          l10n.temporaryPassword,
        );
        expect(
          _hint(tester, const Key('staff-confirm-password')),
          l10n.confirmPasswordHint,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'reset password validates, then calls resetTechnicianPassword (${locale.languageCode})',
      (tester) async {
        final api = await _pump(
          tester,
          home: const StaffMemberPage(memberId: 'tech-1'),
          locale: locale,
        );
        final l10n = _l10n(tester);

        expect(_pillWidget(tester, l10n.save).onPressed, isNull);
        await tester.enterText(
          find.byKey(const Key('staff-reset-password')),
          'temporary-pass-123',
        );
        await tester.enterText(
          find.byKey(const Key('staff-confirm-password')),
          'temporary-pass-999',
        );
        await tester.pump();
        expect(_pillWidget(tester, l10n.save).onPressed, isNull);

        // Submitting the mismatch surfaces the message and does not call out.
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text(l10n.passwordMismatch), findsOneWidget);
        expect(api.resetPasswords, isEmpty);

        await tester.enterText(
          find.byKey(const Key('staff-confirm-password')),
          'temporary-pass-123',
        );
        await tester.pump();
        await tester.tap(_pill(l10n.save));
        await tester.pumpAndSettle();
        expect(api.resetPasswords, [('tech-1', 'temporary-pass-123')]);
        expect(find.text(l10n.contentSaved), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'deactivate requires a reason and calls disableUser (${locale.languageCode})',
      (tester) async {
        final api = await _pump(
          tester,
          home: const StaffMemberPage(memberId: 'tech-1'),
          locale: locale,
        );
        final l10n = _l10n(tester);

        await tester.tap(_pill(l10n.deactivate));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('staff-lifecycle-confirm')),
          findsOneWidget,
        );
        expect(_hint(tester, const Key('staff-lifecycle-reason')), l10n.reason);

        // Empty reason is rejected.
        await tester.tap(_pill(l10n.deactivate));
        await tester.pumpAndSettle();
        expect(find.text(l10n.requiredField), findsOneWidget);
        expect(api.disabled, isEmpty);

        await tester.enterText(
          find.byKey(const Key('staff-lifecycle-reason')),
          'Left the workshop',
        );
        await tester.tap(_pill(l10n.deactivate));
        await tester.pumpAndSettle();
        expect(api.disabled, [('tech-1', 'Left the workshop')]);
        expect(find.text(l10n.contentSaved), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'disabled account reactivates with a reason (${locale.languageCode})',
      (tester) async {
        final api = await _pump(
          tester,
          home: const StaffMemberPage(memberId: 'tech-2'),
          locale: locale,
        );
        final l10n = _l10n(tester);
        expect(_pill(l10n.reactivate), findsOneWidget);
        expect(_pill(l10n.deactivate), findsNothing);

        await tester.tap(_pill(l10n.reactivate));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('staff-lifecycle-reason')),
          'Back from leave',
        );
        await tester.tap(_pill(l10n.reactivate));
        await tester.pumpAndSettle();
        expect(api.reactivated, [('tech-2', 'Back from leave')]);
        expect(find.text(l10n.contentSaved), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'member page survives 2.0x text on a phone (${locale.languageCode})',
      (tester) async {
        await _pump(
          tester,
          home: const StaffMemberPage(memberId: 'tech-1'),
          locale: locale,
          size: const Size(390, 844),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('EMAIL_EXISTS lands on the email field', (tester) async {
    final api = _AccountApi(members: const [_active], emailExists: true);
    await _pump(
      tester,
      home: const StaffCreatePage(),
      locale: const Locale('en'),
      size: const Size(390, 844),
      api: api,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(StaffCreatePage)),
    );

    await tester.enterText(
      find.byKey(const Key('staff-create-name')),
      'Technician C',
    );
    await tester.enterText(
      find.byKey(const Key('staff-create-email')),
      'tech.c@test.local',
    );
    await tester.enterText(
      find.byKey(const Key('staff-create-password')),
      'temporary-pass-123',
    );
    await tester.enterText(
      find.byKey(const Key('staff-create-confirm')),
      'temporary-pass-123',
    );
    await tester.pump();
    await tester.tap(find.text(l10n.create).last);
    await tester.pumpAndSettle();

    expect(find.byType(StaffCreatePage), findsOneWidget);
    expect(find.text(l10n.emailAlreadyInUse), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
