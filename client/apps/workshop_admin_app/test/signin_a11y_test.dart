import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:workshop_admin_app/src/features/auth/workshop_login_page.dart';

/// Closes the two accessibility findings from the independent Gate 6 review:
/// the eye toggle had no accessible name, and an invalid submit was silent.
class _NeverCalledRepository implements AuthRepository {
  @override
  Future<Session?> restore() async => null;

  @override
  Future<AuthResult> signIn(String email, String password) async {
    throw StateError('must not be called by an invalid form');
  }

  @override
  Future<AuthResult> verifyTwoFactor(
    String challengeToken,
    String code,
  ) async => throw UnimplementedError();

  @override
  Future<Session?> refresh(String refreshToken) async => null;

  @override
  Future<void> signOut() async {}
}

Widget _harness({Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_NeverCalledRepository()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light,
      home: const WorkshopLoginPage(),
    ),
  );
}

void main() {
  testWidgets('the password reveal control has an accessible name', (
    tester,
  ) async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    IconButton reveal() => tester.widget<IconButton>(find.byType(IconButton));

    expect(reveal().tooltip, en.showPassword);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(reveal().tooltip, en.hidePassword);
  });

  testWidgets('an invalid submit announces the problem', (tester) async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    Map<Object?, Object?>? announcement;
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      SystemChannels.accessibility.name,
      (ByteData? message) async {
        final decoded = SystemChannels.accessibility.codec.decodeMessage(
          message,
        );
        if (decoded is Map && decoded['type'] == 'announce') {
          announcement = decoded.cast<Object?, Object?>();
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        SystemChannels.accessibility.name,
        null,
      ),
    );

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(
      announcement,
      isNotNull,
      reason: 'an empty submit must announce, not fail silently',
    );
    expect(
      announcement.toString(),
      contains(en.signinCheckFields),
      reason: 'the announcement must use the localized message',
    );
    // Both fields still show their own specific message.
    expect(find.text(en.requiredField), findsNWidgets(2));
  });

  testWidgets('the announcement is localized in Arabic', (tester) async {
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));

    Map<Object?, Object?>? announcement;
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      SystemChannels.accessibility.name,
      (ByteData? message) async {
        final decoded = SystemChannels.accessibility.codec.decodeMessage(
          message,
        );
        if (decoded is Map && decoded['type'] == 'announce') {
          announcement = decoded.cast<Object?, Object?>();
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        SystemChannels.accessibility.name,
        null,
      ),
    );

    await tester.pumpWidget(_harness(locale: const Locale('ar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-in-submit')));
    await tester.pumpAndSettle();

    expect(announcement.toString(), contains(ar.signinCheckFields));
  });
}
