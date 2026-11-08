import 'dart:ui' as ui;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// Presentational sign-in screen. Business state stays in [SignInPage].
///
/// All user-visible copy comes from [AppLocalizations]. The Figma-text
/// fidelity fixture renders this same widget under a test-only
/// localization override (see `figma_l10n_override.dart` in the
/// technician_app tests); no Figma sample strings ship in this package.
class SignInView extends StatefulWidget {
  const SignInView({
    required this.emailController,
    required this.passwordController,
    required this.codeController,
    required this.formKey,
    required this.isArabic,
    required this.onLocaleChanged,
    required this.onSubmit,
    required this.onValidateEmail,
    required this.onValidateRequired,
    this.challenge = false,
    this.submitting = false,
    this.errorText,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController codeController;
  final GlobalKey<FormState> formKey;
  final bool isArabic;
  final ValueChanged<bool> onLocaleChanged;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> onValidateEmail;
  final FormFieldValidator<String> onValidateRequired;
  final bool challenge;
  final bool submitting;
  final String? errorText;

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      backgroundColor: Fx.white,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SingleChildScrollView(
              padding: const EdgeInsetsDirectional.only(
                start: _M.gutter,
                end: _M.gutter,
                bottom: _M.bottomPad,
              ),
              child: Center(
                child: SizedBox(
                  width: width >= AppBreakpoints.tablet
                      ? _M.contentWidth
                      : null,
                  child: Form(
                    key: widget.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: _M.headerHeight,
                          child: Align(
                            alignment: AlignmentDirectional.topEnd,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                top: _M.languageTop,
                              ),
                              child: FxLanguageSwitch(
                                isArabic: widget.isArabic,
                                onChanged: widget.onLocaleChanged,
                                englishLabel: l10n.languageEnglish,
                                arabicLabel: l10n.languageArabic,
                                englishKey: const Key('sign-in-language-en'),
                                arabicKey: const Key('sign-in-language-ar'),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: _M.heroHeight,
                          child: Stack(
                            children: [
                              Positioned(
                                top: _M.logoTop,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _BrandMark(
                                    label: l10n.appTitle,
                                    semanticsLabel: l10n.appTitle,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: _M.brandTop,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      l10n.appTitle,
                                      textAlign: TextAlign.center,
                                      style: Fx.display26.copyWith(
                                        color: Fx.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: _M.taglineTop,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    l10n.technicianSignInTagline,
                                    textAlign: TextAlign.center,
                                    style: Fx.text(
                                      13,
                                      18,
                                      FontWeight.w400,
                                      0.325,
                                      color: Fx.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: _M.fieldsInset,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FxTextField(
                                key: const Key('sign-in-email'),
                                controller: widget.emailController,
                                semanticLabel: l10n.emailLabel,
                                iconId: '1_7094',
                                iconWidth: 16.67,
                                iconHeight: 13.33,
                                iconGap: 12,
                                hint: l10n.emailLabel,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                ltr: true,
                                validator: widget.onValidateEmail,
                              ),
                              const SizedBox(height: _M.fieldGap),
                              FxTextField(
                                key: const Key('sign-in-password'),
                                controller: widget.passwordController,
                                semanticLabel: l10n.passwordLabel,
                                iconId: '1_7101',
                                iconWidth: 13.33,
                                iconHeight: 17.5,
                                iconGap: 12,
                                hint: l10n.passwordLabel,
                                obscure: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                ltr: true,
                                onFieldSubmitted: (_) => widget.onSubmit(),
                                validator: widget.onValidateRequired,
                                suffix: _Reveal(
                                  obscured: _obscurePassword,
                                  semanticLabel: l10n.passwordLabel,
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              if (widget.challenge) ...[
                                const SizedBox(height: _M.fieldGap),
                                FxTextField(
                                  key: const Key('sign-in-code'),
                                  controller: widget.codeController,
                                  semanticLabel: l10n.twoFactorLabel,
                                  iconId: '1_7101',
                                  hint: l10n.twoFactorLabel,
                                  keyboardType: TextInputType.number,
                                  ltr: true,
                                  validator: (value) =>
                                      (value ?? '').length == 6
                                      ? null
                                      : l10n.requiredField,
                                ),
                              ],
                              SizedBox(
                                height: _M.forgotBlock,
                                child: Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Text(
                                    l10n.technicianPasswordHelp,
                                    style: Fx.caption.copyWith(
                                      color: Fx.muted,
                                      letterSpacing: 0.44,
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: context.motionDuration(
                                  context.motion.normal,
                                ),
                                child: widget.errorText == null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              top: 8,
                                            ),
                                        child: Semantics(
                                          liveRegion: true,
                                          child: Text(
                                            widget.errorText!,
                                            key: ValueKey(widget.errorText),
                                            textAlign: TextAlign.center,
                                            style: Fx.body13.copyWith(
                                              color: Fx.error,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: _M.buttonTop),
                              FxButton(
                                key: const Key('sign-in-submit'),
                                label: widget.challenge
                                    ? l10n.verifyButton
                                    : l10n.signInButton,
                                onPressed: widget.submitting
                                    ? null
                                    : widget.onSubmit,
                                shadows: Fx.buttonSubtleShadow,
                                icon: const FxIcon(
                                  id: '1_7118',
                                  width: 10.67,
                                  height: 10.67,
                                  color: Fx.white,
                                ),
                                trailingIcon: true,
                              ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _M.footerHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: _M.footerTop,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        key: const Key('sign-in-access-prompt'),
                                        width: _M.accessPromptWidth,
                                        child: Text(
                                          l10n.technicianNeedTechnicianAccess,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Fx.body13.copyWith(
                                            color: Fx.muted,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: _M.gapSm),
                                      SizedBox(
                                        width: _M.accessActionWidth,
                                        child: Text(
                                          l10n.technicianContactAdmin,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Fx.label12.copyWith(
                                            color: Fx.deepGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: _M.securityTop),
                                Row(
                                  key: const Key('sign-in-security-line'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const FxIcon(
                                      id: '1_7128',
                                      width: 8,
                                      height: 10,
                                      color: Fx.outline,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        l10n.technicianSecurityLine,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Fx.caption.copyWith(
                                          color: Fx.outline,
                                          letterSpacing: 0.44,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.obscured,
    required this.semanticLabel,
    required this.onPressed,
  });

  final bool obscured;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox(
          width: 24.5,
          height: 19.25,
          child: Center(
            child: FxIcon(
              id: '1_7107',
              width: 16.5,
              height: 11.25,
              color: Fx.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.label, required this.semanticsLabel});

  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: _M.logoBox,
          height: _M.logoBox,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: _M.glowInset,
                left: _M.glowInset,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: _M.glowBlur,
                    sigmaY: _M.glowBlur,
                  ),
                  child: Container(
                    width: _M.glowSize,
                    height: _M.glowSize,
                    decoration: BoxDecoration(
                      color: Fx.glow,
                      borderRadius: BorderRadius.circular(Fx.pillRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _M {
  static const double gutter = 20;
  static const double contentWidth = 350;
  static const double headerHeight = 64;
  static const double languageTop = 8;
  static const double heroHeight = 222;
  static const double logoTop = 32;
  static const double logoBox = 80;

  static const double glowInset = 10;
  static const double glowSize = 60;
  static const double glowBlur = 24;
  static const double brandTop = 128;
  static const double taglineTop = 164;
  static const double fieldsInset = 4;
  static const double fieldGap = 16;
  static const double forgotBlock = 34;
  static const double buttonTop = 40;
  static const double footerHeight = 128;
  static const double footerTop = 64;
  static const double securityTop = 16;
  static const double accessPromptWidth = 153.53;
  static const double accessActionWidth = 64.94;
  static const double bottomPad = 202;
  static const double gapSm = 8;
}
