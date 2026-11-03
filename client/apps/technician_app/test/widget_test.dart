import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

Widget _wrap(Widget child, Locale locale) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildAppTheme(),
    home: child,
  );
}

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _TestApp extends ConsumerStatefulWidget {
  const _TestApp({
    required this.home,
    this.initialLocale = const Locale('en'),
  });

  final Widget home;
  final Locale initialLocale;

  @override
  ConsumerState<_TestApp> createState() => _TestAppState();
}

class _TestAppState extends ConsumerState<_TestApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localeProvider.notifier).setLocale(widget.initialLocale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(),
      home: widget.home,
    );
  }
}

void main() {
  testWidgets('English sign-in shell renders without overflow', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: _TestApp(home: SignInPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('sign-in-submit')), findsOneWidget);
    expect(find.byKey(const Key('sign-in-email')), findsOneWidget);
  });

  testWidgets('Arabic sign-in shell renders RTL without overflow', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: _TestApp(
          home: SignInPage(),
          initialLocale: Locale('ar'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('sign-in-submit')))),
      TextDirection.rtl,
    );
    expect(find.text('تسجيل الدخول'), findsWidgets);
  });

  testWidgets('Language toggle switches the shell to Arabic', (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      const ProviderScope(
        child: _TestApp(home: SignInPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-in-language-ar')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('sign-in-submit')))),
      TextDirection.rtl,
    );
  });

  testWidgets('Technician role home renders in Arabic without overflow',
      (tester) async {
    _phoneSize(tester);
    await tester.pumpWidget(
      _wrap(
        RoleHomeScaffold(
          role: Role.technician,
          locale: const Locale('ar'),
          onLanguageChanged: (_) {},
          onSignOut: () {},
        ),
        const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('فني'), findsOneWidget);
  });
}
