import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/ui_strings.dart';

import 'signin_copy.dart';
import 'signin_example.dart';
import 'signin_form.dart';
import 'signin_mark.dart';
import 'signin_primitives.dart';
import 'signin_keys.dart';

/// The shared admin sign-in — a full-bleed workshop photo with the portal copy
/// and example visuals stacked on it, and a credential panel that overlaps and
/// blends into the photo.
///
/// Desktop: photo on the left, rounded credential panel on the right, the panel
/// overlapping the photo by 24 px. Phone: photo on top, rounded credential sheet
/// at the bottom. Below 900 px (or below 1100 px at 1.5× text) the layout
/// stacks; at 2× the whole page scrolls so the form stays reachable.
class SignInBayView extends StatelessWidget {
  const SignInBayView({
    required this.copy,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.codeController,
    required this.obscurePassword,
    required this.submitting,
    required this.errorText,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateCode,
    this.challenge = false,
    this.emailEnabled = true,
    this.autofocusEmail,
    this.languageControl,
    super.key,
  });

  final SignInBayCopy copy;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController codeController;
  final bool obscurePassword;
  final bool submitting;
  final String? errorText;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateCode;
  final bool challenge;
  final bool emailEnabled;
  final bool? autofocusEmail;
  final Widget Function(bool onAccent)? languageControl;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final split = MediaQuery.sizeOf(context).width >= 800 && textScale < 1.4;

    final form = AutofillGroup(
      child: SigninForm(
        formKey: formKey,
        copy: copy,
        emailController: emailController,
        passwordController: passwordController,
        codeController: codeController,
        challenge: challenge,
        emailEnabled: emailEnabled,
        obscurePassword: obscurePassword,
        submitting: submitting,
        errorText: errorText,
        onToggleObscure: onToggleObscure,
        onSubmit: onSubmit,
        validateEmail: validateEmail,
        validatePassword: validatePassword,
        validateCode: validateCode,
        autofocusEmail: autofocusEmail ?? split,
      ),
    );

    if (!split) {
      final pinned =
          MediaQuery.sizeOf(context).height >= 640 && textScale < 1.8;
      final photo = _BayPhoto(
        copy: copy,
        trailing: _language(context, onImage: true),
        horizontalPadding: spacing.lg,
        rightPadding: 0,
        compact: true,
      );
      final sheet = _formSheet(
        context,
        form: form,
        radius: const BorderRadius.vertical(top: Radius.circular(28)),
        shadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
        horizontalPadding: spacing.lg,
        topPadding: spacing.xl,
      );

      return Scaffold(
        backgroundColor: ws.surface,
        body: SafeArea(
          child: pinned
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: photo),
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: sheet,
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: textScale >= 1.8 ? 540 : 400,
                        child: photo,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: sheet,
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    final cardWidth = MediaQuery.sizeOf(context).width >= 1200 ? 480.0 : 420.0;
    return Scaffold(
      backgroundColor: ws.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _BayPhoto(
            copy: copy,
            trailing: _language(context, onImage: true),
            horizontalPadding: spacing.massive,
            rightPadding: cardWidth + 64,
            compact: false,
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 32),
              child: SizedBox(
                width: cardWidth,
                child: _formSheet(
                  context,
                  form: form,
                  radius: BorderRadius.circular(28),
                  shadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                  horizontalPadding: 44,
                  topPadding: 36,
                  centered: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _language(BuildContext context, {required bool onImage}) {
    final control = languageControl?.call(true);
    if (control == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(Fx.pillRadius),
      ),
      child: control,
    );
  }

  Widget _formSheet(
    BuildContext context, {
    required Widget form,
    required BorderRadiusGeometry radius,
    required List<BoxShadow> shadow,
    required double horizontalPadding,
    required double topPadding,
    bool centered = false,
  }) {
    final ws = context.ws;
    final spacing = context.spacing;
    final body = Padding(
      padding: EdgeInsetsDirectional.only(
        top: topPadding,
        bottom: spacing.xl,
        start: horizontalPadding,
        end: horizontalPadding,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: form,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: ws.surface,
        borderRadius: radius,
        boxShadow: shadow,
      ),
      child: centered
          ? Center(child: SingleChildScrollView(child: body))
          : body,
    );
  }
}

/// The photo side: the workshop image, the brand and language on top, the
/// portal copy and the labelled example visuals stacked at the bottom.
class _BayPhoto extends StatelessWidget {
  const _BayPhoto({
    required this.copy,
    required this.trailing,
    required this.horizontalPadding,
    required this.rightPadding,
    required this.compact,
  });

  final SignInBayCopy copy;
  final Widget trailing;
  final double horizontalPadding;
  final double rightPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ws = context.ws;
    final spacing = context.spacing;
    final t = UiStrings.of(context);
    final progress = t(SignInKeys.signInExampleProgress, {'done': exampleDone, 'total': exampleTotal, 'percent': examplePercent});
    final shadow = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 18,
        offset: const Offset(0, 2),
      ),
    ];

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/signin_hero_admin.jpg',
            package: 'auth',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xB3000000),
                ],
                stops: [0, 0.28, 0.52, 1],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              horizontalPadding,
              spacing.lg,
              rightPadding == 0 ? horizontalPadding : rightPadding,
              spacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SigninMark(
                          onAccent: true,
                          portalLabel: copy.portalLabel,
                          appName: copy.appName,
                          showPortalLabel: false,
                        ),
                      ),
                    ),
                    trailing,
                  ],
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 420 : 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        copy.portalLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ws.eyebrow.copyWith(
                          color: ws.onAccent.withValues(alpha: 0.78),
                          letterSpacing: 1.4,
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      Text(
                        copy.title,
                        style: ws.heroNumber.copyWith(
                          color: ws.onAccent,
                          letterSpacing: -1.2,
                          shadows: shadow,
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        copy.subtitle,
                        style: ws.body.copyWith(
                          color: ws.onAccent.withValues(alpha: 0.84),
                          shadows: shadow,
                        ),
                      ),
                      SizedBox(height: spacing.xl),
                      Text(
                        t(SignInKeys.signInExampleLabel).toUpperCase(),
                        style: ws.eyebrow.copyWith(
                          color: ws.onAccent.withValues(alpha: 0.72),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          exampleVehicle,
                          style: ws.cardTitle.copyWith(color: ws.onAccent),
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t(SignInKeys.signInExampleChecklist),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ws.meta.copyWith(
                                color: ws.onAccent.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            progress,
                            maxLines: 1,
                            style: ws.meta.copyWith(
                              color: ws.onAccent,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.sm),
                      WorkshopTickSpine(
                        done: exampleDone,
                        total: exampleTotal,
                        fillColor: ws.onAccent.withValues(alpha: 0.85),
                        trackColor: ws.onAccent.withValues(alpha: 0.18),
                        animate: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
