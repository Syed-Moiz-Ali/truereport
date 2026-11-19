import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:technician_app/src/features/auth/signin/technician_sign_in_view.dart';
import 'package:technician_app/src/features/auth/signin/widgets/signin_error_row.dart';
import 'package:technician_app/src/features/auth/signin/widgets/signin_field.dart';
import 'package:technician_app/src/features/auth/signin/widgets/signin_language_switch.dart';
import 'package:technician_app/src/features/auth/signin/widgets/signin_meta_row.dart';
import 'package:technician_app/src/features/auth/signin/widgets/signin_primary.dart';

import '../../../support/f2a_test_fonts.dart';

/// Gate 5 gallery — primitives and the assembled screen, real bundled fonts.
///
/// Writes PNGs to `${systemTemp}/truereport-signin-gallery/`. The main session
/// copies the curated set into docs/evidence/gallery and docs/evidence/signin.
void main() {
  setUpAll(loadF2AFonts);

  Widget host({
    required Widget child,
    required Locale locale,
    double textScale = 1,
    bool disableAnimations = false,
  }) {
    final isArabic = locale.languageCode == 'ar';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.build(isArabic: isArabic),
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: appChild ?? const SizedBox.shrink(),
      ),
      home: child,
    );
  }

  Future<void> capture(
    WidgetTester tester, {
    required String name,
    required Size size,
    required Widget child,
    required Locale locale,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const rootKey = ValueKey('signin-gallery-root');
    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: host(child: child, locale: locale, textScale: textScale),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/signin_hero.jpg'),
        tester.element(find.byKey(rootKey)),
      );
    });
    await tester.pump();

    expect(
      tester.takeException(),
      isNull,
      reason: 'no overflow or render exception in $name',
    );

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(rootKey),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    expect(data, isNotNull);
    final dir = Directory(
      '${Directory.systemTemp.path}/truereport-signin-gallery',
    )..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  }

  Widget view({
    required Locale locale,
    bool challenge = false,
    String? errorText,
    double textScale = 1,
  }) {
    final email = TextEditingController();
    final password = TextEditingController();
    final code = TextEditingController();
    final emailFocus = FocusNode();
    final passwordFocus = FocusNode();
    final codeFocus = FocusNode();
    addTearDown(() {
      email.dispose();
      password.dispose();
      code.dispose();
      emailFocus.dispose();
      passwordFocus.dispose();
      codeFocus.dispose();
    });
    return TechnicianSignInView(
      emailController: email,
      passwordController: password,
      codeController: code,
      formKey: GlobalKey<FormState>(),
      isArabic: locale.languageCode == 'ar',
      onLocaleChanged: (_) {},
      onSubmit: () {},
      onValidateEmail: (_) => null,
      onValidateRequired: (_) => null,
      onValidateCode: (_) => null,
      emailFocus: emailFocus,
      passwordFocus: passwordFocus,
      codeFocus: codeFocus,
      challenge: challenge,
      errorText: errorText,
    );
  }

  testWidgets('capture the assembled screen', (tester) async {
    await capture(
      tester,
      name: 'signin_1440_en',
      size: const Size(1440, 900),
      child: view(locale: const Locale('en')),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_390_en',
      size: const Size(390, 844),
      child: view(locale: const Locale('en')),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_390_ar',
      size: const Size(390, 844),
      child: view(locale: const Locale('ar')),
      locale: const Locale('ar'),
    );
    await capture(
      tester,
      name: 'signin_390_error',
      size: const Size(390, 844),
      child: view(
        locale: const Locale('en'),
        errorText: 'Email or password is incorrect.',
      ),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_390_challenge',
      size: const Size(390, 844),
      child: view(locale: const Locale('en'), challenge: true),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_360_15x',
      size: const Size(360, 800),
      child: view(locale: const Locale('ar')),
      locale: const Locale('ar'),
      textScale: 1.5,
    );
    await capture(
      tester,
      name: 'signin_360_20x',
      size: const Size(360, 800),
      child: view(locale: const Locale('en')),
      locale: const Locale('en'),
      textScale: 2,
    );
    await capture(
      tester,
      name: 'signin_1024_en',
      size: const Size(1024, 768),
      child: view(locale: const Locale('en')),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_768_en',
      size: const Size(768, 900),
      child: view(locale: const Locale('en')),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_1280_en',
      size: const Size(1280, 800),
      child: view(locale: const Locale('en')),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_1280_ar',
      size: const Size(1280, 800),
      child: view(locale: const Locale('ar')),
      locale: const Locale('ar'),
    );
    await capture(
      tester,
      name: 'signin_1280_en_15x',
      size: const Size(1280, 800),
      child: view(locale: const Locale('en')),
      locale: const Locale('en'),
      textScale: 1.5,
    );
    await capture(
      tester,
      name: 'signin_600_en',
      size: const Size(600, 900),
      child: view(locale: const Locale('en')),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_390_error_ar',
      size: const Size(390, 844),
      child: Builder(
        builder: (context) => view(
          locale: const Locale('ar'),
          errorText: AppLocalizations.of(context).invalidCredentials,
        ),
      ),
      locale: const Locale('ar'),
    );
    await capture(
      tester,
      name: 'signin_360_en',
      size: const Size(360, 800),
      child: view(locale: const Locale('en')),
      locale: const Locale('en'),
    );
  });

  testWidgets('keyboard-up keeps the primary above the inset', (tester) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        child: host(
          child: view(locale: const Locale('en')),
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final primary = find.byKey(const Key('sign-in-submit'));
    await tester.scrollUntilVisible(
      primary,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    final rect = tester.getRect(primary);
    expect(
      rect.bottom,
      lessThanOrEqualTo(500 - 300),
      reason: 'primary must sit above the keyboard inset',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard-up capture at 390 x 844', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const rootKey = ValueKey('keyboard-capture-root');
    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: host(
          child: view(locale: const Locale('en')),
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final primary = find.byKey(const Key('sign-in-submit'));
    await tester.scrollUntilVisible(
      primary,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(primary).bottom, lessThanOrEqualTo(844 - 300));
    expect(tester.takeException(), isNull);

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(rootKey),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    final dir = Directory(
      '${Directory.systemTemp.path}/truereport-signin-gallery',
    )..createSync(recursive: true);
    File('${dir.path}/signin_390_keyboard.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
  });

  testWidgets('reduce motion removes the rise', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        child: host(
          child: view(locale: const Locale('en')),
          locale: const Locale('en'),
          disableAnimations: true,
        ),
      ),
    );
    await tester.pump();
    final first = tester.getTopLeft(find.byKey(const Key('sign-in-submit')));
    await tester.pump(const Duration(milliseconds: 300));
    final settled = tester.getTopLeft(find.byKey(const Key('sign-in-submit')));
    expect(settled, first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1440 → 360 resize adds no render exception', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        child: host(
          child: view(locale: const Locale('en')),
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(360, 800);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture the primitive sheet LTR and RTL', (tester) async {
    await capture(
      tester,
      name: 'signin_primitives_ltr',
      size: const Size(1200, 760),
      child: const _PrimitiveSheet(),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_primitives_rtl',
      size: const Size(1200, 760),
      child: const _PrimitiveSheet(),
      locale: const Locale('ar'),
    );
  });

  testWidgets('capture the invalid field state LTR and RTL', (tester) async {
    await capture(
      tester,
      name: 'signin_field_invalid_en',
      size: const Size(560, 220),
      child: const _InvalidFieldSample(),
      locale: const Locale('en'),
    );
    await capture(
      tester,
      name: 'signin_field_invalid_ar',
      size: const Size(560, 220),
      child: const _InvalidFieldSample(),
      locale: const Locale('ar'),
    );
  });
}

class _PrimitiveSheet extends StatelessWidget {
  const _PrimitiveSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final email = TextEditingController();
    final password = TextEditingController();
    final focus = FocusNode();
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Primitives — field, primary, language, meta, error',
              style: Fx.heading18,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SignInField(
                    controller: email,
                    label: l10n.emailLabel,
                    validator: (_) => null,
                    fieldKey: const Key('gallery-email'),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SignInField(
                    controller: password,
                    label: l10n.passwordLabel,
                    validator: (_) => null,
                    focusNode: focus,
                    obscure: true,
                    fieldKey: const Key('gallery-password'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SignInPrimary(
                    label: l10n.signInButton,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SignInPrimary(
                    label: l10n.signInButton,
                    onPressed: null,
                    busy: true,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SignInPrimary(
                    label: l10n.signInButton,
                    onPressed: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SignInLanguageSwitch(
                  isArabic:
                      Localizations.localeOf(context).languageCode == 'ar',
                  onChanged: (_) {},
                  englishLabel: l10n.languageEnglish,
                  arabicLabel: l10n.languageArabic,
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: SignInMetaRow(
                    accessPrompt: l10n.technicianNeedTechnicianAccess,
                    helpLabel: l10n.technicianContactAdmin,
                    securityLine: l10n.technicianSecurityLine,
                    compact: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SignInErrorRow(message: l10n.invalidCredentials),
            const SizedBox(height: 8),
            SignInErrorRow(message: l10n.networkError, alignEnd: true),
          ],
        ),
      ),
    );
  }
}

class _InvalidFieldSample extends StatefulWidget {
  const _InvalidFieldSample();

  @override
  State<_InvalidFieldSample> createState() => _InvalidFieldSampleState();
}

class _InvalidFieldSampleState extends State<_InvalidFieldSample> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.validate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SignInField(
            controller: _controller,
            label: l10n.emailLabel,
            validator: (_) => l10n.requiredField,
            fieldKey: const Key('gallery-invalid-field'),
          ),
        ),
      ),
    );
  }
}
