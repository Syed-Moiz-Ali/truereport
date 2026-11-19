import 'dart:io';
import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:auth/auth.dart';

import 'support/real_fonts.dart';

/// Gate 5 gallery proof: every primitive and state the sign-in rebuild will
/// compose, in light LTR and light RTL.
///
/// Dark is absent under waiver W-LIGHT (the app is light-only by decision).
/// Output: `docs/evidence/gallery/gallery_{ltr,rtl}_light.png`.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.locale});

  final Locale locale;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController(text: 'workshop-password');
  final _error = TextEditingController();
  final _disabled = TextEditingController(text: 'disabled@truereport.test');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.validate();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _error.dispose();
    _disabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final l10n = AppLocalizations.of(context);

    Widget section(String title, Widget child) {
      return SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: ws.eyebrow.copyWith(color: ws.muted)),
            SizedBox(height: context.spacing.sm),
            child,
          ],
        ),
      );
    }

    return Container(
      color: ws.canvas,
      padding: const EdgeInsets.all(40),
      child: Form(
        key: _formKey,
        child: Wrap(
          spacing: 40,
          runSpacing: 32,
          children: [
            section(
              'TextField / default',
              WorkshopTextField(
                controller: _email,
                label: l10n.emailLabel,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            section(
              'TextField / focused',
              WorkshopTextField(
                controller: _email,
                label: l10n.emailLabel,
                autofocus: true,
              ),
            ),
            section(
              'TextField / error',
              WorkshopTextField(
                controller: _error,
                label: l10n.emailLabel,
                validator: (_) => l10n.invalidEmail,
              ),
            ),
            section(
              'TextField / disabled',
              WorkshopTextField(
                controller: _disabled,
                label: l10n.emailLabel,
                enabled: false,
              ),
            ),
            section(
              'TextField / obscured + eye',
              WorkshopTextField(
                controller: _password,
                label: l10n.passwordLabel,
                obscureText: true,
                suffixIcon: Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: ws.muted,
                ),
              ),
            ),
            section(
              'Button / primary',
              WorkshopButton(
                label: l10n.signInButton,
                expand: true,
                onPressed: () {},
              ),
            ),
            section(
              'Submit / idle',
              SigninSubmitButton(
                label: l10n.signInButton,
                loadingLabel: l10n.signingIn,
                isLoading: false,
                onPressed: () {},
              ),
            ),
            section(
              'Submit / focused',
              SigninSubmitButton(
                label: l10n.signInButton,
                loadingLabel: l10n.signingIn,
                isLoading: false,
                autofocus: true,
                onPressed: () {},
              ),
            ),
            section(
              'Submit / in flight',
              SigninSubmitButton(
                label: l10n.signInButton,
                loadingLabel: l10n.signingIn,
                isLoading: true,
                onPressed: () {},
              ),
            ),
            section(
              'Button / ghost',
              WorkshopButton(
                label: l10n.languageArabic,
                icon: Icons.language,
                variant: WorkshopButtonVariant.ghost,
                onPressed: () {},
              ),
            ),
            section(
              'Button / disabled',
              WorkshopButton(
                label: l10n.signInButton,
                expand: true,
                onPressed: null,
              ),
            ),
            section(
              'Status badge / warning',
              WorkshopStatusBadge(
                label: l10n.statusInProgress,
                tone: WorkshopStatusTone.warning,
              ),
            ),
            section(
              'Avatar / initials',
              Row(
                children: [
                  const WorkshopAvatar(
                    initials: 'KA',
                    semanticLabel: 'Karim Ahmed',
                    size: 24,
                  ),
                  SizedBox(width: context.spacing.sm),
                  Text('Karim Ahmed', style: ws.meta.copyWith(color: ws.ink)),
                ],
              ),
            ),
            section(
              'Chassis mark / 26 % on ink',
              Container(
                color: ws.ink,
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: WorkshopChassisMark(
                  width: 180,
                  color: ws.onAccent.withValues(alpha: 0.26),
                ),
              ),
            ),
            section(
              'Tick spine / 0 of 24',
              Container(
                color: ws.ink,
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: WorkshopTickSpine(
                  done: 0,
                  total: 24,
                  animate: false,
                  fillColor: ws.onAccent.withValues(alpha: 0.85),
                  trackColor: ws.onAccent.withValues(alpha: 0.16),
                ),
              ),
            ),
            section(
              'Tick spine / 18 of 24',
              Container(
                color: ws.ink,
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: WorkshopTickSpine(
                  done: 18,
                  total: 24,
                  animate: false,
                  fillColor: ws.onAccent.withValues(alpha: 0.85),
                  trackColor: ws.onAccent.withValues(alpha: 0.16),
                ),
              ),
            ),
            section(
              'Tick spine / 24 of 24',
              Container(
                color: ws.ink,
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: WorkshopTickSpine(
                  done: 24,
                  total: 24,
                  animate: false,
                  fillColor: ws.onAccent.withValues(alpha: 0.85),
                  trackColor: ws.onAccent.withValues(alpha: 0.16),
                ),
              ),
            ),
            section(
              'Example job / on ink',
              Container(
                color: ws.ink,
                padding: EdgeInsetsDirectional.all(context.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.signInExampleLabel.toUpperCase(),
                      style: ws.eyebrow.copyWith(
                        color: ws.onAccent.withValues(alpha: 0.62),
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: context.spacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '2023 Porsche 911 GT3',
                          style: ws.pageTitle.copyWith(color: ws.onAccent),
                        ),
                      ),
                    ),
                    SizedBox(height: context.spacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          'DXB 48291 · Rashid Al Mansoori',
                          style: ws.meta.copyWith(
                            color: ws.onAccent.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.spacing.md),
                    WorkshopTickSpine(
                      done: 18,
                      total: 24,
                      animate: false,
                      fillColor: ws.onAccent.withValues(alpha: 0.85),
                      trackColor: ws.onAccent.withValues(alpha: 0.16),
                      semanticLabel: l10n.signInExampleProgress(18, 24, 75),
                    ),
                  ],
                ),
              ),
            ),
            section(
              'Grid texture / 5 % white on ink',
              ClipRRect(
                borderRadius: BorderRadius.circular(ws.cardRadius),
                child: CustomPaint(
                  painter: WorkshopGridPainter(
                    color: ws.onAccent.withValues(alpha: 0.05),
                  ),
                  child: Container(
                    height: 120,
                    color: ws.ink,
                    padding: const EdgeInsets.all(16),
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.signInExampleLabel,
                      style: ws.body.copyWith(color: ws.onAccent),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _capture(
  WidgetTester tester,
  String fileName,
  Locale locale,
) async {
  final key = GlobalKey();
  tester.view.physicalSize = const Size(1280, 1240);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: RepaintBoundary(
          key: key,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(1280, 820)),
            child: Scaffold(
              backgroundColor: AppTheme.light
                  .extension<WorkshopTokens>()
                  ?.canvas,
              body: _Gallery(locale: locale),
            ),
          ),
        ),
      ),
    ),
  );
  // The loading button spins forever, so settle-until-quiet would time out.
  // Two pumps is enough: one to lay out, one to let the validate callback run.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  expect(boundary, isNotNull);

  await tester.runAsync(() async {
    final image = await boundary!.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull);
    final directory = Directory('docs/evidence/gallery');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    File('${directory.path}/$fileName')
        .writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
  });
}

void main() {
  testWidgets('gallery LTR light', (tester) async {
    expect(RealFonts.isLoaded, isTrue);
    await _capture(tester, 'gallery_ltr_light.png', const Locale('en'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery RTL light', (tester) async {
    await _capture(tester, 'gallery_rtl_light.png', const Locale('ar'));
    expect(tester.takeException(), isNull);
  });
}
